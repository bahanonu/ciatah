function [ostruct] = modelPreprocessMovieFunction(obj,varargin)
	% Controller for pre-processing movies, mainly aimed at miniscope data.
	% Biafra Ahanonu
	% started 2013.11.09 [10:46:23]

	% changelog
		% 2013.11.10 - refactored to make the work-flow more obvious and more easily modifiable by others. Now outputs a structure that contains information about what occurred during the run.
		% 2013.11.11 - allowed increased flexibility in terms of inputting PCs/ICs and loading default options.
		% 2013.11.18
		% 2014.01.07 [11:12:19] adding to changelog again: updated support for tif files.
		% 2014.01.23 [20:23:02] fixed getCurrentMovie bug, wasn't passing options.datasetName to loadMovieList.
		% 2014.06.06 removed sub-function for now to improve memory usage and made it easier for the user to choose what pre-processing to do and save.
		% 2015.01.05 [20:00:26] turboreg options uses uicontrol now instead of pulldown and is more dynamic.
		% 2015.01.19 [20:43:49] - changed how turboreg is passed to function to improve memory usage, also moved dfof and downsample directly into function to reduce memory footprint there as well.
		% 2016.06.22 [13:20:43] small code change to choosing what steps to perform
		% 2019.01.23 [09:15:39] Added support for 2018b due to change in findjobj and uicontrol.
		% 2019.04.17 [11:59:35] Saving turboreg outputs added, in same folder as the log.
		% 2019.07.11 [20:07:29] - Improved GUI display, added support for ISXD dropped frames.
		% 2019.07.22 [16:30:30] - Improved support for multi-iteration turboreg and outputting of turboreg without filtering and with filtering in the same run seamlessly.
		% 2019.07.26 [14:00:00] - Additional improvements in adding movie borders based on turboreg outputs.
		% 2019.08.07 [18:23:05] - Fix for using the _noSpatialFilter_ output where was registering to already registered iterations.
		% 2019.09.06 [23:41:50]/2019.09 - Improved downsampling support.
		% 2019.09.17 [19:14:27] - Improved alternative HDF5 dataset name support and added explicit rejection of non-video files for movieList.
		% 2019.09.24 [11:47:24] - filterBeforeRegister now outputs a tag in the filename.
		% 2019.12.08 [23:20:25] - Allow users to load prior settings.
		% 2019.12.19 [20:00:12] - Make sure that the list to choose saving outputs matches any re-ordering done in the pre-processing selection list. Also make sure if downsampleSpace comes before turboreg that it doesn't throw an error looking for turboRegCoords.
		% 2020.04.02 [17:57:03] - Adding dropped frames explicit user-facing step (fixDropFrames) instead of implicitly done in the background to make more clear to user.
		% 2020.05.10 [02:29:47] - Updated analysis steps to make save names shorter and provide more descriptive options.
		% 2020.06.09 [11:57:59] - Upgrade to save settings out as a json file for easier human reading.
		% 2020.07.07 [00:32:59] - Further upgraded adding json to HDF5 directly for later reading out to get settings.
		% 2020.09.22 [00:11:03] - Updated to add NWB support.
		% 2020.10.24 [18:30:56] - Added support for calculating dropped frames if entire frame of a movie is a set value. Changed order so that dropped frames calculated before dF/F.
		% 2021.02.15 [12:06:59] - _inputMovieF0 now saved to processing subfolder.
		% 2021.04.11 [10:52:10] - Fixed thisFrame issue when displaying area to use for motion correction if treatMoviesAsContinuous=0 and processMoviesSeparately=0, e.g. would load reference frame from each and if there were 3 movies, would assume RGB, causing display to be white. Also update so the display frame takes into account custom frame list range.
		% 2021.06.09 [00:40:35] - Updated checking of options. Also save ordering of options selected.
		% 2021.06.20 [00:22:38] - Added manageMiji('startStop','closeAllWindows'); support.
		% 2021.06.29 [12:09:40] - Added support for dF/F where F0 is calculated using the minimum (or a soft minimum to reduce probability that one outlier throws off the calculation). Also changed turboregCropSelection so dialog box is now part of getRegistrationSettings.
		% 2021.07.13 [17:55:30] - Add support for multiple reference frames, the mean is taken before input to motion correction.
		% 2021.07.22 [12:11:44] - Added support for detrending movies.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.09.10 [10:14:04] - Fix to handle folders with no files.
		% 2021.11.16 [11:52:36] - Add verification that turboreg MEX function is in the path.
		% 2021.12.31 [18:59:24] - Updated suptitle to ciapkg.overloaded.suptitle.
		% 2022.01.19 [16:26:06] - Fix "No movies" dialog box displaying when movies successfully run.
		% 2022.01.25 [16:08:49] - Add `modelPreprocessMovieFunction` settings saved in CIAtah class to saved output file for later retrieval.
		% 2022.01.26 [08:31:06] - For selecting turboreg crop coordinates, switched to ciapkg.io.readFrame when single frame is requested as this is faster and avoids long read times of all frame information as occurs in certain types of TIFF files or hard drives.
		% 2022.02.09 [23:51:18] - Misc code fixes to conform to better Matlab language standards.
		% 2022.03.03 [19:18:54] - Change all nested and local functions to start with "nestedfxn_" or "localfxn_" prefixes for clarity. Added option to fix "broken" frames, e.g. frames in which the camera gives out garbled or improperly formatted data. Fix with mean of the movie to reduce effect on downstream analysis. Disable local function "getMovieFileType" in favor or CIAtah package function.
		% 2022.03.09 [16:50:36] - Added option to place prefix on all output files.
		% 2022.03.12 [19:19:41] - Detrending now does everything within nested function instead of calling normalizeMovie() to reduce memory overhead.
		% 2022.03.13 [23:20:08] - Added support for MAT-file based processing of movies.
		% 2022.06.28 [15:28:13] - Add additional black background support.
		% 2022.07.10 [17:21:21] - Added largeMovieLoad setting support, improve memory allocation for select movies.
		% 2022.07.27 [12:45:08] - Make sure readFrame is compatible with all HDF5 dataset names.
		% 2022.07.18 [10:30:01] - NormCorre integrated into the pipeline for end users.
		% 2022.09.19 [18:14:05] - Updated NormCorre parameter window to estimate window size from the first frame.
		% 2022.10.04 [08:12:19] - Make correlation calculation parallel.
		% 2022.10.04 [16:45:56] - Allow detrend movie to use movie subsets to reduce memory overhead.
		% 2022.12.03 [21:48:51] - Reduce double calling of mean() for calculation and plotting when conducting detrending.
		% 2022.12.05 [14:22:03] - Further eliminate nanmean/nanmin/nanmax usage, use dims instead of (:) [waste memory], and general refactoring.
		% 2023.01.11 [14:05:51] - Fix thisMovieMinMask(row,:) = logical(max(isnan(squeeze(thisMovie(row,:,:))),[],2,'omitnan')); as was 3 instead of row.
		% 2023.08.04 [07:29:02] - Add support for input of prior motion correction coordinates to be user facing.
		% 2023.12.26 [21:23:22] - Empty imagesc() call leading to face appearing. For the curious, see https://blogs.mathworks.com/steve/2006/10/17/the-story-behind-the-matlab-default-image/.
	% TODO
		% Allow users to save out analysis options order and load it back in.
		% Insert NaNs or mean of the movie into dropped frame location, see line 260
		% Allow easy switching between analyzing all files in a folder together and each file in a folder individually
		% FML, make this object oriented...
		% Allow reading in of subset of movie for turboreg analysis, e.g. if we have super large movies

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% remove pre-compiled functions
	% clear FUNCTIONS;
	% load necessary functions and defaults
	% loadBatchFxns();
	%========================
	% Str: path to MAT-file that will be used to temporarily store processed movie, to avoid Out of Memory errors for certain movies.
	options.matfilePath = '';
	% Str: Variable name for movie to store MAT-file in. DO NOT CHANGE for the moment.
	options.matfileVarname = 'thisMovie';
	% INTERNAL | Binary: 1 = running MAT-file based analysis, 0 = run normal analysis load in disk.
	options.runMatfile = 0;
	% Binary: 1 = show figures, 0 = disable showing figures
	options.showFigures = 1;
	% set the options, these can be modified by varargin
	options.folderListPath='manual';
	% whether to skip files being processed by another computer
	options.checkConcurrentAnalysis = 1;
	% whether to skip files being processed by another computer
	options.concurrentAnalysisFilename = obj.concurrentAnalysisFilename;
	% should each movie in a folder be processed separately?
	options.processMoviesSeparately = 0;
	% should the movies be processed or just an ostruct be created?
	options.processMovies=1;
	% set this to an m-file with default options
	options.loadOptionsFromFile = 0;
	% number of frames to subset to reduce turboreg overhead
	options.turboregNumFramesSubset = 3000;
	% how to turboreg, options: 'preselect','coordinates','other'. Only pre-select is implemented currently.
	options.turboregType = 'preselect';
	% 1 = rotation, 0 = no rotation
	options.turboreg.turboregRotation = 1;
	% should the movie be dfof'd?
	options.dfofMovie = 1;
	% method of doing deltaF/F: 'dfof', 'divide', 'minus'
	options.dfofType = 'dfof';
	% factor to downsample by
	options.downsampleFactor = 4;
	% number of pixels to crop around movie
	options.pxToCrop = 14;
	% the regular expression used to find files
	options.fileFilterRegexp = 'concatenated_.*.h5';
	% decide whether to get nICs and nPCs from file list
	options.inputPCAICA = 0;
	% ask for # PC/ICs at the end
	options.askForPCICs = 0;
	% number of frames from input movie to analyze
	options.frameList = [];
	% name for dataset in HDF5 file
	options.datasetName = '/1';
	% name for dataset in HDF5 file
	options.outputDatasetName = '/1';
	% reference frame used for cropping and turboreg
	options.refCropFrame = 1;
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;
	% Char array: list of file types supported.
	options.supportedTypes = {'.h5','.hdf5','.tif','.tiff','.avi','.isxd'};
	% Float: single value, likely 0, 1, or NaN, indicating when a frame should be considered dropped. Leave empty to ignore.
	options.calcDroppedFramesFromMovie = [];
	% String: 'soft' calculates based on percentile (to avoid outliers), 'min' calculates the normal minimum.
	options.minType = 'soft';
	% Float: Calculates the X percentile for minimum F0.
	options.minSoftPct = 0.1/100;
	% Binary: 1 = cmd line waitbar on. 0 = waitbar off.
	options.waitbarOn = 1;
	% ====
	% OLD OPTIONS
	% should the movie be saved?
	options.saveMovies = 0;
	% save the final movie
	options.saveDfofMovie = 0;
	% should the movie be turboreg'd
	options.turboregMovie = 1;
	% normalize the movie (e.g. divisive normalization)
	options.normalizeMovie = 0;
	% should the movie be downsampled?
	options.downsampleMovie = 1;
	% Regexp for log file to fix dropped frames
	options.logFileRegexp = '(recording.*.(txt|xml)|.*_metadata.mat)';
	% Str: daset
	options.nwbSettingsDatasetname = '/general/optophysiology/imaging_plane/description';
	options.h5SettingsDatasetname = '/movie/preprocessingSettingsAll';
	% Str: prefix to add to all saved files.
	options.saveFilePrefix = '';
	% Str: suffix to add to all saved files.
	options.saveFileSuffix = '';
	% Str: suffix to add to all saved files.
	options.videoPlayer = 'matlab';
	% Str: path to MAT-file with prior motion correction coordinates
	options.precomputedRegistrationCooordsFullMovie = '';
	% ====
	% get options
	options = getOptions(options,varargin);
	disp(options)
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	startDir = pwd;
	if options.showFigures==1
		for figNoFake = [9 4242 456 457 9019 1865 1866 1776]
			[~, ~] = openFigure(figNoFake, '');
			clf
		end
		drawnow
	end
	% read in the list of folders
	if ischar(options.folderListPath)&&~strcmp(options.folderListPath,'manual')
		if ~isempty(regexp(options.folderListPath,'.txt', 'once'))
			fid = fopen(options.folderListPath, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			folderList = tmpData{1,1};
			fclose(fid);
		else
			% user just inputs a single directory
			folderList = {options.folderListPath};
		end
		nFiles = length(folderList);
	elseif iscell(options.folderListPath)
		folderList = options.folderListPath;
		nFiles = length(folderList);
	else
		if strcmp(options.folderListPath,'manual')
			disp('Dialog box: select text file that points to analysis folders.')
			[folderListPath,folderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
			% exit if user picks nothing
			if folderListPath==0
				return
			end
			folderListPath = [folderPath folderListPath];
		else
			folderListPath = options.folderListPath;
		end
		fid = fopen(folderListPath, 'r');
		tmpData = textscan(fid,'%s','Delimiter','\n');
		folderList = tmpData{1,1};
		fclose(fid);
		nFiles = length(folderList);
	end
	%========================
	% allow user to choose steps in the processing
	scnsize = get(0,'ScreenSize');
	% USAflagStr = ['Made in USA' 10 ...
	% 		'* * * * * * * * * * =========================' 10 ...
	% 		'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
	% 		'* * * * * * * * * * =========================' 10 ...
	% 		'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
	% 		'* * * * * * * * * * =========================' 10 ...
	% 		':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
	% 		'=============================================' 10 ...
	% 		':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
	% 		'=============================================' 10 ...
	% 		':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
	% 		'=============================================' 10 ...
	% 		':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
	% 		'=============================================' 10];

	tmpFlag = obj.usaflag();
	USAflagStr = ['Made in USA' 10 tmpFlag];

	% List of analysis options
	analysisOptionList = {...
		'medianFilter',...
		'detrend',...
		'downsampleSpace',...
		'spatialFilter',...
		'stripeRemoval',...
		'manualRegister',...
		'turboreg',...
		'fft_highpass',...
		'crop',...
		'fixDropFrames',...
		'dfof',...
		'dfstd',...
		'dfofMin',...
		'medianFilter',...
		'downsampleTime',...
		'downsampleSpace',...
		'fft_lowpass'...
		};

	% List of default analysis options to select
	defaultChoiceList = {'turboreg','crop','fixDropFrames','dfof','downsampleTime'};

	analysisOptionListOrig = analysisOptionList;
	defaultChoiceListOrig = defaultChoiceList;

	analysisOptsInfo = struct(...
		'medianFilter',struct(...
			'save','medFlt',...
			'str','Median filter (reduce high value noise or dead pixels).'),...
		'detrend',struct(...
			'save','detrend',...
			'str','Detrend movie (e.g. to compensate for photobleaching).'),...
		'spatialFilter',struct(...
			'save','spFlt',...
			'str','Spatial filter (ignore if motion correcting).'),...
		'stripeRemoval',struct(...
			'save','strpRm',...
			'str','Remove vertical or horizontal stripes (e.g. camera artifacts).'),...
		'manualRegister',struct(...
			'save','manReg',...
			'str','Manually register movie images. (ignore)'),...
		'turboreg',struct(...
			'save','treg',...
			'str','Motion correction - TurboReg or NoRMCorre (with option to spatially filter)'),...
		'normcorre',struct(...
			'save','normcorre',...
			'str','NoRMCorre (motion correction with option to spatially filter)'),...
		'fft_highpass',struct(...
			'save','fftHp',...
			'str','High-pass FFT (ignore most cases).'),...
		'crop',struct(...
			'save','crop',...
			'str','Border (add NaN border to movie after motion correction)'),...
		'dfof',struct(...
			'save','dfof',...
			'str','Covert to dF/F0, where F0 = mean all frames.'),...
		'dfstd',struct(...
			'save','dfstd',...
			'str','Convert to dF/std.'),...
		'dfofMin',struct(...
			'save','dfofMin',...
			'str','Convert to dF/F0, where F0 = min all frames (actual or soft).'),...
		'fixDropFrames',struct(...
			'save','fxFrms',...
			'str','Fixed dropped frames (for Inscopix movies).'),...
		'downsampleTime',struct(...
			'save','dsTime',...
			'str','Downsample in time.'),...
		'downsampleSpace',struct(...
			'save','dsSpace',...
			'str','Downsample in space'),...
		'fft_lowpass',struct(...
			'save','fftLp',...
			'str','Low-pass FFT and save (ignore most cases, check for neuropil).')...
	);


	defaultChoiceIdx = find(ismember(analysisOptionList,defaultChoiceList));
	defaultSaveIdx = find(ismember(analysisOptionList,defaultChoiceList{end}));
	if isfield(obj.functionSettings,'modelPreprocessMovieFunction')
		if ~isempty(obj.functionSettings.modelPreprocessMovieFunction)
			try
				analysisOptionList = obj.functionSettings.modelPreprocessMovieFunction.analysisOptionList;
				defaultChoiceList = obj.functionSettings.modelPreprocessMovieFunction.defaultChoiceList;
				defaultChoiceIdx = obj.functionSettings.modelPreprocessMovieFunction.defaultChoiceIdx;
				defaultSaveIdx = obj.functionSettings.modelPreprocessMovieFunction.defaultSaveIdx;
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		else
		end
	else
		% Do nothing
	end

	% Load existing settings
	try
		options.videoPlayer = obj.functionSettings.modelPreprocessMovieFunction.options.videoPlayer;
	catch
	end

	analysisOptionListStr = analysisOptionList;
	for optNoS3 = 1:length(analysisOptionListStr)
		analysisOptionListStr{optNoS3} = analysisOptsInfo.(analysisOptionListStr{optNoS3}).str;
	end
		% analysisOptionListStr(strcmp(analysisOptionListStr,'crop')) = {'crop (add NaN border after motion correction)'};
		% analysisOptionListStr(strcmp(analysisOptionListStr,'turboreg')) = {'turboreg (motion correction, can include spatial filtering)'};

	%defaultChoiceIdx = find(cellfun(@(x) sum(strcmp(x,defaultChoiceList)),analysisOptionList));
	try
		ok = 1;
		[~, ~] = openFigure(1776, '');clf;

		set(gcf,'color',[0 0 0]);
		instructTextPos = [1 80 70 20]/100;
		listTextPos = [1 40 98 28]/100;
		listTextPos2 = [1 1 98 28]/100;

		figNoList = struct;
		figNoList.detrend = 102030;

		shortcutMenuHandle = uicontrol('style','pushbutton','Units','normalized','position',[1 75 30 3]/100,'FontSize',9,'string','Reset to default list order','callback',@nestedfxn_resetSetpsMenu);
		shortcutMenuHandle2 = uicontrol('style','pushbutton','Units','normalized','position',[32 75 30 3]/100,'FontSize',9,'string','Select default options (e.g. post-dragging)','callback',@nestedfxn_highlightDefault);
		shortcutMenuHandle3 = uicontrol('style','pushbutton','Units','normalized','position',[63 75 30 3]/100,'FontSize',9,'string','Finished','callback',@nestedfxn_closeOptions);
		% shortcutMenuHandle = uicontrol('style','pushbutton','Units','normalized','position',[32 62 30 3]/100,'FontSize',9,'string','Next screen','callback',@nestedfxn_highlightDefault);


		uicontrol('Style','Text','String','Analysis steps to perform.','Units','normalized','Position',[1 68 90 3]/100,'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Left','FontWeight','bold');
		[hListbox, jListbox, jScrollPane, jDND] = reorderableListbox('String',analysisOptionListStr,'Units','normalized','Position',listTextPos,'Max',Inf,'Min',0,'Value',defaultChoiceIdx,...
			'MousePressedCallback',@nestedfxn_analysisOutputMenuChange,...
			'MouseReleasedCallback',@nestedfxn_analysisOutputMenuChange,...
			'DragOverCallback',@nestedfxn_analysisOutputMenuChange2,...
			'DropCallback',@nestedfxn_analysisOutputMenuChange...
			);

		uicontrol('Style','Text','String',['At which analysis step should files be saved to disk?'],'Units','normalized','Position',[1 30 90 3]/100,'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Left','FontWeight','bold');
		[hListboxS, jListboxS, jScrollPaneS, jDNDS] = reorderableListbox('String',analysisOptionListStr,'Units','normalized','Position',listTextPos2,'Max',Inf,'Min',0,'Value',defaultSaveIdx);

		uicontrol('Style','Text','String',['Analysis step selection and ordering' 10 '======='...
			10 'Gentlemen, you can not fight in here! This is the War Room.' 10 'We can know only that we know nothing.' 10 'And that is the highest degree of human wisdom.'...
			10 10 '1: Click items to select.' 10 '2: Drag to re-order analysis.' 10 '3: Click command window and press ENTER to continue.'],...
			'Units','normalized','Position',instructTextPos,'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Left');


		emptyBox = uicontrol('Style','Text','String','','Units','normalized','Position',[1 1 1 1]/100,'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Left','FontWeight','bold','FontSize',7);

		if ismac
			cmdWinEditorFont = 'Menlo-Regular';
		elseif isunix
			cmdWinEditorFont = 'Consolas';
		elseif ispc
			cmdWinEditorFont = 'Consolas';
		else
			cmdWinEditorFont = 'FixedWidth';
		end

		usaFlagPic = @(x) uicontrol('Style','Text','String',x,'Units','normalized','Position',[0.7 0.85 0.28 0.14],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Right','FontName',cmdWinEditorFont,'FontSize',5);

		usaFlagPic(USAflagStr);
		% exitHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[5 85 50 3]/100,'FontSize',9,'string','Click here to finish','callback',@subfxnCloseFig,'HorizontalAlignment','Left');

		% Wait for user input
		% set(gcf, 'WindowScrollWheelFcn', @nestedfxn_mouseWheelChange);
		% set(gcf,'KeyPressFcn', @(src,event) set(gcf,'Tag','next'));
		set(gcf,'KeyPressFcn', @nestedfxn_closeOptionsKey);
		set(gcf,'color',[0 0 0]);
		ciapkg.view.changeFont('none','fontColor','w')
		% waitfor(gcf,'Tag');
		waitfor(emptyBox);
		% pause
		% hListbox.String(hListbox.Value)
		analysisOptionsIdx = hListbox.Value;
		analysisOptionList = hListbox.String;

		% Correct back to original names before proceeding
		fnTmp = fieldnames(analysisOptsInfo);
		for optNoS4 = 1:length(analysisOptionList)
			for fnNo2 = 1:length(fnTmp)
				if strcmp(analysisOptionList{optNoS4},analysisOptsInfo.(fnTmp{fnNo2}).str)==1
					analysisOptionList{optNoS4} = fnTmp{fnNo2};
				end
			end
		end

		analysisOptionListStr = analysisOptionList;
		for optNoS4 = 1:length(analysisOptionListStr)
			analysisOptionListStr{optNoS4} = analysisOptsInfo.(analysisOptionListStr{optNoS4}).str;
		end

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
		disp('BACKUP DIALOG')
		[analysisOptionsIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultChoiceIdx,...
			'Name','the red pill...',...
			'PromptString','select analysis steps to perform. will be analyzed top to bottom, with top first',...
			'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
		% pause
	end

	if ok~=1
		return
	end

	defaultSaveList = analysisOptionList{analysisOptionsIdx(end)};
	defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	% List of files to save
	saveIdx = hListboxS.Value;
	% saveIdx = hListboxS.Value;

	% Whether to use the old method
	oldMethod = 0;
	if oldMethod==1
		try
			[~, ~] = openFigure(1776, '');clf;
			[hListbox, jListbox, jScrollPane, jDND] = reorderableListbox('String',analysisOptionListStr,'Units','normalized','Position',listTextPos,'Max',Inf,'Min',0,'Value',defaultSaveIdx);
			uicontrol('Style','Text','String',['Analysis steps to save' 10 '=======' 10 'Gentlemen, you can not fight in here! This is the War Room.' 10 10 '1: Click analysis steps to save output' 10 '2: Click command window and press ENTER to continue'],'Units','normalized','Position',instructTextPos,'BackgroundColor','white','HorizontalAlignment','Left');
			usaFlagPic(USAflagStr);
			pause
			saveIdx = hListbox.Value;
			% close(1776);
			[~, ~] = openFigure(1776, '');clf;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
			disp('BACKUP DIALOG')
			[saveIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultSaveIdx,...
				'Name','Gentlemen, you can not fight in here! This is the War Room.',...
				'PromptString','select at which stages to save a file. if option not selected for analysis, will be ignored',...
				'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
		end
	else
		[~, ~] = openFigure(1776, '');clf;
	end

	% Update file filter to the last saved out option
	% obj.fileFilterRegexp

	if ok~=1
		return
	end
	% only keep save if user selected option to analyze...
	defaultSaveIdx = intersect(analysisOptionsIdx,defaultSaveIdx);
	if isempty(defaultSaveIdx)
		defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	end

	if isfield(obj.functionSettings,'modelPreprocessMovieFunction')
		% usrInput = obj.functionSettings.modelEditStimTable.usrInput;
	else
		obj.functionSettings.modelPreprocessMovieFunction = struct;
	end
	obj.functionSettings.modelPreprocessMovieFunction.analysisOptionList = analysisOptionList;
	obj.functionSettings.modelPreprocessMovieFunction.defaultChoiceList = analysisOptionList(analysisOptionsIdx);
	obj.functionSettings.modelPreprocessMovieFunction.defaultChoiceIdx = analysisOptionsIdx;
	obj.functionSettings.modelPreprocessMovieFunction.defaultSaveIdx = saveIdx;

	% ========================
	movieSettings = inputdlg({...
			'Select frames to use during preprocessing (e.g. 1:1000). **Leave blank to use all movie frames**:',...
			'Regular expression for raw files (e.g. if raw files all have "concat" in the name, put "concat"): ',...
			'[optional, if using HDF5] Input HDF5 file dataset name (e.g. "/images" for raw Inscopix or "/1" for example data, sans quotes): ',...
			'[optional, if using HDF5] Output HDF5 file dataset name (see above): ',...
			'[optional] (0) Use default preprocessing settings, (1) Save settings or load previously saved settings: ',...
			'[optional] (1) Save movie to NWB format, (0) Save to HDF5 format: ',...
			'[optional] Prefix to add to all processed movies (e.g. "concat_", "experiment_"): ',...
			'[optional] Suffix to add to all processed movies (e.g. "concat_", "experiment_"): '...
			'[optional] Default video player (imagej or matlab): ',...
			'[optional] Path to MAT-file with Turboreg registration coordinates to use: '...
			'[optional IGNORE] MAT-file path if processing large movie (e.g. getting Out of Memory errors), SSD drive preferred for speed: ',...
		},...
		'Preprocessing settings',[1 100],...
		{...
			num2str(options.frameList),...
			obj.fileFilterRegexpRaw,...
			obj.inputDatasetName,...
			obj.outputDatasetName,...
			num2str(obj.saveLoadPreprocessingSettings),...
			num2str(obj.nwbLoadFiles),...
			'',...
			'',...
			options.videoPlayer,...
			'',...
			options.matfilePath,...
		}...
	);
	disp(movieSettings)
	if isempty(movieSettings)
		disp('User canceled input, exiting...')
		return;
	end
	options.frameList = str2num(movieSettings{1});
	obj.fileFilterRegexpRaw = movieSettings{2};
	obj.inputDatasetName = movieSettings{3};
	obj.outputDatasetName = movieSettings{4};
	obj.saveLoadPreprocessingSettings = str2num(movieSettings{5});
	obj.nwbLoadFiles = str2num(movieSettings{6});
	options.saveFilePrefix = movieSettings{7};
	options.saveFileSuffix = movieSettings{8};
	options.videoPlayer = movieSettings{9};
	options.matfilePath = movieSettings{10};
	options.precomputedRegistrationCooordsFullMovie = movieSettings{11};

	obj.functionSettings.modelPreprocessMovieFunction.options.videoPlayer = options.videoPlayer;

	if obj.saveLoadPreprocessingSettings==1
		currentDateTimeStr = datestr(now,'yyyymmdd_HHMMSS','local');
		settingsSaveStr = [obj.settingsSavePath filesep currentDateTimeStr '_modelPreprocessMovieFunction_settings.mat'];
		% uiwait(ciapkg.overloaded.msgbox(['Settings saved to obj.preprocessSettings and MAT-file: ' settingsSaveStr]))
	end
	% '[options, if motion correcting] Motion correction reference frame: '...
	% num2str(obj.motionCorrectionRefFrame)...
	% obj.motionCorrectionRefFrame = str2num(movieSettings{4});

	% ========================
	% ask user for options if particular analysis selected
	% if sum(ismember({analysisOptionList{analysisOptionsIdx}},'turboreg'))==1

	% Ask user for main preprocessing settings, load previous settings if desired.
	previousPreprocessSettings = [];
	if obj.saveLoadPreprocessingSettings==1
		try
			usrIdxChoiceStr = {'Automatic (saved in class).','Manually load from file.'};
			scnsize = get(0,'ScreenSize');
			[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.25],'Name','How to load previous settings? Press enter if no previous settings.','PromptString',{'Settings saved to "obj.preprocessSettings" and in MAT-file:',settingsSaveStr});
			if ok==0
				return;
			end
			if sel==1
				if isstruct(obj.preprocessSettings)
					previousPreprocessSettings = obj.preprocessSettings;
				end
			else
				% [settingsName,settingsFolderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
				[settingsName,settingsFolderPath,~] = uigetfile('*.*','Select previous preprocessing settings file (e.g. preprocessingOptions) or HDF5 movie containing pre-processing settings.','_modelPreprocessMovieFunction_settings.mat');

				settingsLoadPath = [settingsFolderPath settingsName];
				[~,~,tmpExt] = fileparts(settingsName);

				% Load settings from HDF5 or NWB as needed, else load from MAT file.
				switch tmpExt
					case {'.h5','.hdf5'}
						disp('Loading settings from prior HDF5 file')
						previousPreprocessSettings = ciapkg.io.jsonRead(settingsLoadPath,'inputDatasetName',options.h5SettingsDatasetname);
					case {'.nwb'}
						disp('Loading settings from prior NWB file')
						previousPreprocessSettings = ciapkg.io.jsonRead(settingsLoadPath,'inputDatasetName',options.nwbSettingsDatasetname);
					case {'.json'}

					case '.mat'
						previousPreprocessSettings = load(settingsLoadPath,'preprocessingSettingsAll');
						previousPreprocessSettings = previousPreprocessSettings.preprocessingSettingsAll;
					otherwise
						warning('Incorrect file type chosen to extract settings.');
				end
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	else
	end

	% Get movie processing settings, NOT just for motion correction
	[options.turboreg, preprocessingSettingsAll] = obj.getRegistrationSettings('Processing options','inputSettings',previousPreprocessSettings);
	fn_structdisp(options.turboreg)


	% Get additional NormCorre settings
	switch options.turboreg.mcMethod
		case 'normcorre'
			movieList = getFileList(folderList{1}, options.fileFilterRegexp);
			[movieList] = localfxn_removeUnsupportedFiles(movieList,options);
			thisFrame = ciapkg.io.readFrame(movieList{1},1,'inputDatasetName',options.datasetName);
			optsNoRMCorre = ciapkg.motion_correction.getNoRMCorreParams([size(thisFrame,1) size(thisFrame,2) 1],'guiDisplay',1);
		otherwise
			optsNoRMCorre = [];
	end

	if obj.saveLoadPreprocessingSettings==1
		obj.preprocessSettings = preprocessingSettingsAll;
		try
			fprintf('Saving settings to: %s.\n',settingsSaveStr)
			save(settingsSaveStr,'preprocessingSettingsAll','optsNoRMCorre','-v7.3');
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end

	options.datasetName = options.turboreg.inputDatasetName;
	obj.inputDatasetName = options.turboreg.inputDatasetName;
	options.outputDatasetName = options.turboreg.outputDatasetName;
	obj.outputDatasetName = options.turboreg.outputDatasetName;

	options.fileFilterRegexp = options.turboreg.fileFilterRegexp;
	options.processMoviesSeparately = options.turboreg.processMoviesSeparately;
	options.turboregNumFramesSubset = options.turboreg.turboregNumFramesSubset;
	options.refCropFrame = options.turboreg.refCropFrame;
	options.pxToCrop = options.turboreg.pxToCrop;
	options.checkConcurrentAnalysis = options.turboreg.checkConcurrentAnalysis;
	options.calcDroppedFramesFromMovie = options.turboreg.calcDroppedFramesFromMovie;
	% end
	% ========================
	% get the frame to use
	% usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
	% options.frameList = str2num(usrIdxChoice{1});
	% ========================
	% allow the user to pre-select all the targets
	if sum(strcmp(analysisOptionList(analysisOptionsIdx),'turboreg'))>0
		if options.processMovies==1
			try
				[turboRegCoords] = localfxn_turboregCropSelection(options,folderList);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				warning('User likely did not give calciumImagingAnalysis a proper raw input file regular expression or incorrect HDF5 input dataset name!')
				return;
			end
		end
	end
	ostruct.folderList = {};
	ostruct.savedFilePaths = {};
	ostruct.fileNumList = {};
	% ========================
	manageParallelWorkers('parallel',options.turboreg.useParallel,'setNumCores',options.turboreg.nParallelWorkers);
	% ========================
	disp(folderList)
	startTime = tic;
	frameListDlg = 0;
	%
	folderListMinusComments = find(cellfun(@(x) isempty(x),strfind(folderList,'#')));
	nFilesToRun = length(folderListMinusComments);
	fileNumToRun = 1;
	%
	for fileNum = 1:nFiles
		manageParallelWorkers('parallel',options.turboreg.useParallel,'setNumCores',options.turboreg.nParallelWorkers);
		movieSaved = 0;
		fileStartTime = tic;
		try
			display(repmat('+',1,42))
			display(repmat('+',1,42))
			% decide whether to get PCA-ICA parameters from file
			if options.inputPCAICA==1
				thisDir = folderList{fileNum};
				% should be folderDir,nPCs,nICs
				dirInfo = regexp(thisDir,',','split');
				thisDir = dirInfo{1};
				if(length(dirInfo)>=3)
					ostruct.nPCs{fileNum} = str2num(dirInfo{3});
					ostruct.nICs{fileNum} = str2num(dirInfo{2});
				else
					disp('please add nICs and PCs')
					ostruct.nPCs{fileNum} = 700;
					ostruct.nICs{fileNum} = 500;
				end
			else
				% thisDir = folderList{fileNum};
				dirInfo = regexp(folderList{fileNum},',','split');
				thisDir = dirInfo{1};
			end
			% check if this directory has been commented out, if so, skip
			if strfind(thisDir,'#')==1
				display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
				display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);
				disp('skipping...')
				continue;
			end

			% skip this analysis if files already exist
			if options.checkConcurrentAnalysis==1
				display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
				display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);

				checkSaveString = [thisDir filesep options.concurrentAnalysisFilename];
				if exist(checkSaveString,'file')~=0
					disp('SKIPPING ANALYSIS FOR THIS FOLDER')
					continue
				else
					% put a temporary file in the directory to cause other scripts to skip
					display(['saving temporary analysis file: ' checkSaveString])
					AmericaTheBeautiful = 'Man Will Conquer Space Soon!.';
					analysisState = 'running';
					save(checkSaveString,'AmericaTheBeautiful','analysisState');
				end
			end

			thisDirDispStr = strrep(strrep(thisDir,'\','/'),'_','\_');

			% start logging for this file
			display(['cd to: ' obj.defaultObjDir]);
			cd(obj.defaultObjDir);
			currentDateTimeStr = datestr(now,'yyyymmdd_HHMMSS','local');
			mkdir([thisDir filesep 'processing_info'])
			thisProcessingDir = [thisDir filesep 'processing_info'];
			thisProcessingDirFileStr = [thisProcessingDir filesep currentDateTimeStr];
			diarySaveStr = [thisProcessingDirFileStr '_preprocess.log'];
			diary(diarySaveStr);

			display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
			display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);
			disp(['saving diary: ' diarySaveStr])

			% For debugging, display whole options structure
			fn_structdisp(options)
			% diary([obj.logSavePath filesep currentDateTimeStr '_' obj.folderBaseSaveStr{obj.fileNum} '_preprocessing.log']);

			% Get the list of movies
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			[movieList] = localfxn_removeUnsupportedFiles(movieList,options);

			% If there are no files in this folder to analyze, skip to the next folder.
			if isempty(movieList)
				continue
			end

			% get information from directory
			fileInfo = getFileInfo(movieList{1});
			disp(fileInfo)
			% base string to save as
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
			if isempty(options.saveFilePrefix)
				thisDirSaveStr = [thisDir filesep fileInfoSaveStr];
			else
				thisDirSaveStr = [thisDir filesep options.saveFilePrefix fileInfoSaveStr];
			end

			thisProcessingDirFileInfoStr = [thisProcessingDir filesep currentDateTimeStr '_' fileInfoSaveStr];
			saveStr = '';
			% add the folder to the output structure
			ostruct.folderList{fileNum} = thisDir;

			optionsSaveStr = [thisDir filesep 'processing_info' filesep currentDateTimeStr '_preprocessingOptions' '.mat'];

			if sum(strcmp(analysisOptionList(analysisOptionsIdx),'turboreg'))>0
				turboRegCoordsTmp2 = turboRegCoords{fileNum};
				save(optionsSaveStr, 'options','turboRegCoordsTmp2','analysisOptionList','analysisOptionsIdx','preprocessingSettingsAll','-v7.3');
			else
				save(optionsSaveStr, 'options','preprocessingSettingsAll','-v7.3');
			end

			% get the movie
			% [thisMovie ostruct options] = getCurrentMovie(movieList,options,ostruct);
			if frameListDlg==0
				% usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
				% options.frameList = [1:500];
				% options.frameList = str2num(usrIdxChoice{1});
				frameListDlg = 1;
			end
			if options.processMoviesSeparately==1
				nMovies = length(movieList);
			else
				nMovies = 1;
			end
			for movieNo = 1:nMovies
				disp(['movie ' num2str(movieNo) '/' num2str(nMovies) ': ' ])
				% thisMovieList = movieList{movieNo};
				% 'loadSpecificImgClass','single'
				if options.turboreg.loadMovieInEqualParts~=0&&options.processMoviesSeparately~=1
					movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single','getMovieDims',1);
					thisFrameList = options.frameList;
					if isempty(thisFrameList)
						tmpList = round(linspace(1,sum(movieDims.z)-100,options.turboreg.loadMovieInEqualParts));
						display(['tmpList: ' num2str(tmpList)])
						tmpList = bsxfun(@plus,tmpList,[1:100]');
					else
						tmpList = round(linspace(1,sum(movieDims.z)-length(thisFrameList),options.turboreg.loadMovieInEqualParts));
						display(['tmpList: ' num2str(tmpList)])
						tmpList = bsxfun(@plus,tmpList,thisFrameList(:));
					end
					options.frameList = tmpList(:);
					options.frameList(options.frameList<1) = [];
					% options.frameList
					options.frameList(options.frameList>sum(movieDims.z)) = [];
				end
				if isempty(options.matfilePath)
					if options.processMoviesSeparately==1
						thisMovie = loadMovieList(movieList{movieNo},'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',0,'loadSpecificImgClass','single','largeMovieLoad',options.turboreg.largeMovieLoad);
						% playMovie(thisMovie);
					else
						% options.turboreg.treatMoviesAsContinuousSwitch = 1;
						if isempty(options.frameList)&&options.turboreg.loadMoviesFrameByFrame==1
							movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single','getMovieDims',1,'largeMovieLoad',options.turboreg.largeMovieLoad);
							sum(movieDims.z)
							thisFrameList = 1:sum(movieDims.z);
						else
							thisFrameList = options.frameList;
						end
						thisMovie = loadMovieList(movieList,'convertToDouble',0,'frameList',thisFrameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single','largeMovieLoad',options.turboreg.largeMovieLoad);
					end
				else
					% Write data to MAT-file to allow read-from-disk processing.
					[success] = writeDataToMatfile(movieList{movieNo},options.matfileVarname,options.matfilePath,...
						'chunkSize',options.turboregNumFramesSubset,...
						'saveSpecificImgClass','single');
					matObj = matfile(movieList{movieNo},'Writable',true);

					% Make a dummy thisMovie for use in certain cases.
					thisMovie = [];
					if success==0
						continue;
					end
					options.runMatfile = 1;
				end

				if options.processMoviesSeparately==1
					% Change name if processed separate.
					resaveCropFileName = '';
				else
					resaveCropFileName = '';
					resaveCropFileNameTmp = '';
				end

				[~, ~] = openFigure(4242, '');
					if options.runMatfile==1
						tmpFrameHere = squeeze(matObj.(options.matfileVarname)(:,:,1));
					else
						tmpFrameHere = squeeze(thisMovie(:,:,1));
					end
					imagesc(tmpFrameHere)
					box off;
					dispStr = [num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' 10 thisDirDispStr];
					axis image; colormap gray;
					set(0,'DefaultTextInterpreter','none');
					% ciapkg.overloaded.suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')],'fontSize',12,'plotregion',0.9,'titleypos',0.95);
					uicontrol('Style','Text','String',dispStr,'Units','normalized','Position',[0.1 0.9 0.8 0.10],'BackgroundColor','white','HorizontalAlignment','Center');
					set(0,'DefaultTextInterpreter','latex');

					% title(dispStr);
				% ciapkg.overloaded.suptitle([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')]);

				% nOptions = length(analysisOptionsIdx)
				saveStr = '';
				thisMovieMean = [];
				inputMovieF0 = [];
				% to improve memory usage, edit the movie in loops, at least until this is made object oriented.
				for optionIdx = analysisOptionsIdx
					if options.runMatfile==0
						thisMovie = single(thisMovie);
					end
					optionName = analysisOptionList{optionIdx};

					% Update the save string based on the analysis about to be run.
					if strcmp(optionName,'turboreg')&&~isempty(options.turboreg.filterBeforeRegister)
						saveStr = [saveStr '_' 'spFltBfReg'];
					end
					try
						if strcmp(optionName,'turboreg')
							if strcmp(options.turboreg.mcMethod,'normcorre')
								saveStr = [saveStr '_normcorre'];
							else
								saveStr = [saveStr '_' analysisOptsInfo.(optionName).save];
							end
						else
							saveStr = [saveStr '_' analysisOptsInfo.(optionName).save];			
						end
					catch
						saveStr = [saveStr '_' optionName];
					end

					display(repmat('*',1,7));
					disp([optionName ' movie...']);

					%% ADD BACK DROPPED FRAMES
					% try
					% 	if strcmp(optionName,'downsampleTime')
					% 		nestedfxn_addDroppedFrames();
					% 	end
					% catch err
					% 	% save the location of the downsampled dfof for PCA-ICA identification
					% 	display(repmat('@',1,7))
					% 	disp(getReport(err,'extended','hyperlinks','on'));
					% 	display(repmat('@',1,7))
					% end
					try
						switch optionName
							case 'fixDropFrames'
								nestedfxn_addDroppedFrames();
							case 'turboreg'
								subfxn_plotMotionCorrectionMetric('start');

								pxToCropAll = 0;
								ResultsOutOriginal = {};
								for iterationNo = 1:options.turboreg.numTurboregIterations
									disp(repmat('>',[1 21]))
									fprintf('Turboreg iteration %d/%d\n',iterationNo,options.turboreg.numTurboregIterations)
									if strcmp(options.turboreg.filterBeforeRegister,'imagejFFT')
										% Miji;
										manageMiji('startStop','start');
									end
									subfxn_turboregInputMovie();

									% Save output of translation.
									save([thisProcessingDir filesep currentDateTimeStr '_turboregTranslationOutput.mat'],'ResultsOutOriginal');
									if strcmp(options.turboreg.filterBeforeRegister,'imagejFFT')
										% MIJ.exit;
										manageMiji('startStop','exit');
									end
									% playMovie(thisMovie);
									if options.turboreg.numTurboregIterations>1
										pxToCropTmp = subfxn_getCropValues();
										pxToCropAll = max([pxToCropAll pxToCropTmp]);
										fprintf('pxToCropAll: %d\n',pxToCropAll);
									end
								end

								% Get the amount of motion and hence amount to crop, directly from turboreg output
								try
									% gg = cellfun(@(z) cell2mat(cellfun(@(y) cell2mat(cellfun(@(x) max(abs(x.Translation)),y,'UniformOutput',false)),z,'UniformOutput',false)),ResultsOutOriginal,'UniformOutput',false);
									gg = cellfun(@(z) cell2mat(cellfun(@(y) cell2mat(cellfun(@(x) max(ceil(abs(x.Translation))),y,'UniformOutput',false)),z,'UniformOutput',false)),ResultsOutOriginal,'UniformOutput',false);
									pxToCropAllTmp = ceil(max(sum(abs(cat(1,gg{:})),1),[],'omitnan'));
								catch
									pxToCropAllTmp = 0;
								end
								fprintf('pxToCropAllTmp: %d\n',pxToCropAllTmp);
								if pxToCropAllTmp>pxToCropAll
									disp('Adjusting pxToCropAll')
									pxToCropAll = pxToCropAllTmp;
								end
								if options.pxToCrop<pxToCropAll
									disp('Adjusting pxToCropAll')
									pxToCropAll = options.pxToCrop;
								end
								fprintf('pxToCropAll: %d\n',pxToCropAll);

								if ~isempty(resaveCropFileName)&&pxToCropAll>0
									% MAKE IT LOAD THE MOVIE IN PARTS SIMILAR TO TURBOREG SUBSET!

									% subsetSize = options.turboregNumFramesSubset;
									% movieLength = size(thisMovie,3);
									% numSubsets = ceil(movieLength/subsetSize)+1;
									% subsetList = round(linspace(1,movieLength,numSubsets));
									% nSubsets = (length(subsetList)-1);
									% for thisSet = 1:nSubsets
									% 	subsetStartIdx = subsetList(thisSet);
									% 	subsetEndIdx = subsetList(thisSet+1);
									% end
									fprintf('Loading and adding maximum NaN borders for: %s\n',resaveCropFileName);
									tmpCropMovie = loadMovieList(resaveCropFileName,'inputDatasetName',options.outputDatasetName);
									if pxToCropAll==0
										gmask = sum(tmpCropMovie,3);
										% gmask = isnan(gmask);
										tmpCropMovie = tmpCropMovie.*(gmask*0+1);
									else
										topRowCrop = pxToCropAll; % top row
										leftColCrop = pxToCropAll; % left column
										bottomRowCrop = size(tmpCropMovie,1)-pxToCropAll; % bottom row
										rightColCrop = size(tmpCropMovie,2)-pxToCropAll; % right column
										% set leftmost columns to NaN
										tmpCropMovie(1:end,1:leftColCrop,:) = NaN;
										% set rightmost columns to NaN
										tmpCropMovie(1:end,rightColCrop:end,:) = NaN;
										% set top rows to NaN
										tmpCropMovie(1:topRowCrop,1:end,:) = NaN;
										% set bottom rows to NaN
										tmpCropMovie(bottomRowCrop:end,1:end,:) = NaN;
									end

									jsonSettingStr = ciapkg.io.jsonWrite(preprocessingSettingsAll);
									tmpStruct.preprocessingSettingsAll = jsonSettingStr;
									if isfield(obj.functionSettings,'modelPreprocessMovieFunction')
										if ~isempty(obj.functionSettings.modelPreprocessMovieFunction)
											tmpStruct.settingsAnalysisOperations = ciapkg.io.jsonWrite(obj.functionSettings.modelPreprocessMovieFunction);
										end
									end

									if obj.nwbLoadFiles==1
										movieSaved = saveMatrixToFile(tmpCropMovie,resaveCropFileName,...
											'descriptionImagingPlane',tmpStruct.preprocessingSettingsAll,...
											'deflateLevel',options.deflateLevel);

									else
										movieSaved2 = writeHDF5Data(tmpCropMovie,resaveCropFileName,...
											'datasetname',options.outputDatasetName,...
											'addInfo',{...
												options.turboreg,...
												analysisOptionStruct,...
												optionsCopy,...
												settingsAnalysisOperations,...
												tmpStruct},...
											'addInfoName',{...
												'/movie/processingSettings',...
												'/movie/analysisOperations',...
												'/movie/modelPreprocessMovieFunctionOptions',...
												'/movie/settingsAnalysisOperations',...
												'/movie'},...
												'deflateLevel',options.deflateLevel);
									end

									clear tmpStruct jsonSettingStr;
									ostruct.savedFilePaths{end+1} = resaveCropFileName;
									ostruct.fileNumList{end+1} = fileNum;
									clear tmpCropMovie;
								end

								subfxn_plotMotionCorrectionMetric('end');
							case 'crop'
								if exist('pxToCropAll','var')==1&&pxToCropAll~=0
									if pxToCropAll~=0
										if pxToCropAll<options.pxToCrop
											% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
											subfxn_cropMatrixPreProcess(pxToCropAll);
										else
											% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
											subfxn_cropMatrixPreProcess(options.pxToCrop);
										end
									end
								else
									subfxn_cropInputMovie();
								end
							case 'medianFilter'
								subfxn_medianFilterInputMovie();
							case 'detrend'
								subfxn_detrendInputMovie();
							case 'spatialFilter'
								subfxn_spatialFilterInputMovie();
							case 'stripeRemoval'
								subfxn_stripeRemovalInputMovie();
							case 'movieProjections'
								subfxn_movieProjectionsInputMovie();
							case 'fft_highpass'
								subfxn_fftHighpassInputMovie();
							case 'fft_lowpass'
								subfxn_fftLowpassInputMovie();
							case 'dfof'
								subfxn_dfofInputMovie();
							case 'dfstd'
								options.dfofType = 'dfstd';
								subfxn_dfofInputMovie();
							case 'dfofMin'
								options.dfofType = 'dfofMin';
								subfxn_dfofInputMovie();
							case 'downsampleTime'
								subfxn_downsampleTimeInputMovie();
							case 'downsampleSpace'
								subfxn_downsampleSpaceInputMovie();
							otherwise
								% do nothing
						end
						% save the location of the downsampled dfof for PCA-ICA identification
					catch err
						% save the location of the downsampled dfof for PCA-ICA identification
						% ostruct.savedFilePaths{fileNum} = [];
						ostruct.savedFilePaths{end+1} = [];
						ostruct.fileNumList{end+1} = fileNum;
						display(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
						break;
					end

					% save movie if user selected that option
					% optionIdx
					% saveIdx
					if sum(optionIdx==saveIdx)

						% if isempty(options.saveFilePrefix)
						% else
						% 	savePathStr = [thisDirSaveStr options.saveFilePrefix saveStr '_' num2str(movieNo)];
						% end
						savePathStr = [thisDirSaveStr saveStr '_' num2str(movieNo)];
						if obj.nwbLoadFiles==0
							savePathStr = [savePathStr '.h5'];
						elseif obj.nwbLoadFiles==1
							savePathStr = [savePathStr '.nwb'];
						else
							savePathStr = [savePathStr '.h5'];
						end

						% switch optionName
						% case 'downsampleTime'
						% 	options.downsampleZ = [];
						% 	options.downsampleFactor = options.turboreg.downsampleFactorTime;
						% 	if isempty(options.downsampleZ)
						% 		downZ = floor(size(thisMovie,3)/options.downsampleFactor);
						% 	else
						% 		downZ = options.downsampleZ;
						% 	end
						% 	downZ
						% 	display('saving dataset slab...')
						% 	movieSaved = writeHDF5Data(thisMovie,savePathStr,'hdfStart',[1 1 1],'hdfCount',[size(thisMovie,1)-1 size(thisMovie,2)-1 downZ]);
						% otherwise
						% end
						% movieSaved = writeHDF5Data(thisMovie,savePathStr,'datasetname',options.outputDatasetName)
						analysisOptionListTmp = analysisOptionList(analysisOptionsIdx);
						analysisOptionStruct = struct;
						for optNo5 = 1:length(analysisOptionListTmp)
								analysisOptionStruct.([char(optNo5+'A'-1) '_' analysisOptionListTmp{optNo5}]) = 1;
						end
						optionsCopy = options;
						optionsCopy.turboreg = [];

						jsonSettingStr = ciapkg.io.jsonWrite(preprocessingSettingsAll);
						tmpStruct.preprocessingSettingsAll = jsonSettingStr;
						if isfield(obj.functionSettings,'modelPreprocessMovieFunction')
							if ~isempty(obj.functionSettings.modelPreprocessMovieFunction)
								tmpStruct.settingsAnalysisOperations = ciapkg.io.jsonWrite(obj.functionSettings.modelPreprocessMovieFunction);
							end
						end

						% movieSaved = writeHDF5Data(thisMovie,savePathStr,...
						% 	'datasetname',options.outputDatasetName,...
						% 	'addInfo',{...
						% 		options.turboreg,...
						% 		analysisOptionStruct,...
						% 		optionsCopy,...
						% 		tmpStruct},...
						% 	'addInfoName',{...
						% 		'/movie/processingSettings',...
						% 		'/movie/analysisOperations',...
						% 		'/movie/modelPreprocessMovieFunctionOptions',...
						% 		'/movie'},...
						% 	'deflateLevel',options.deflateLevel)

						addInfoCell = {...
									options.turboreg,...
									analysisOptionStruct,...
									optionsCopy,...
									tmpStruct};
						addInfoNameCell = {...
									'/movie/processingSettings',...
									'/movie/analysisOperations',...
									'/movie/modelPreprocessMovieFunctionOptions',...
									'/movie'};

						if options.runMatfile==1
							ciapkg.hdf5.writeMatfileToHDF5(options.matfilePath,options.matfileVarname,savePathStr,...
								'addInfo',addInfoCell,...
								'addInfoName',addInfoNameCell,...
								'chunkSize',options.turboregNumFramesSubset,...
								'datasetname',options.outputDatasetName,...
								'deflateLevel',options.deflateLevel);
						elseif obj.nwbLoadFiles==1
							% movieSaved = saveMatrixToFile(thisMovie,savePathStr,...
							% 	'inputDatasetName',options.outputDatasetName,...
							% 	'addInfo',{tmpStruct},...
							% 	'addInfoName',{'/movie'},...
							% 	'deflateLevel',options.deflateLevel)
							% movieSaved = saveMatrixToFile(thisMovie,savePathStr,...
							% 	'inputDatasetName',options.outputDatasetName,...
							% 	'addInfo',{tmpStruct},...
							% 	'addInfoName',{'/movie'},...
							% 	'deflateLevel',options.deflateLevel)

							movieSaved = saveMatrixToFile(thisMovie,savePathStr,...
								'descriptionImagingPlane',tmpStruct.preprocessingSettingsAll,...
								'deflateLevel',options.deflateLevel);

							% movieSaved = saveMatrixToFile(thisMovie,savePathStr)
						else
							movieSaved = saveMatrixToFile(thisMovie,savePathStr,...
								'inputDatasetName',options.outputDatasetName,...
								'addInfo',addInfoCell,...
								'addInfoName',addInfoNameCell,...
								'deflateLevel',options.deflateLevel);
						end

						clear tmpStruct jsonSettingStr;
						% ostruct.savedFilePaths{fileNum} = savePathStr;
						ostruct.savedFilePaths{end+1} = savePathStr;
						ostruct.fileNumList{end+1} = fileNum;
						% ostruct.savedFilePaths{end+1} = savePathStr;
					end
					disp(repmat('$',1,7))
					if options.runMatfile==1
						disp(['thisMovie: ' class(matObj.(options.matfileVarname)(1,1,1)) ' | ' num2str(size(matObj,options.matfileVarname))])
					else
						disp(['thisMovie: ' class(thisMovie) ' | ' num2str(size(thisMovie))])
					end
					disp(repmat('$',1,7))
				end
			end
			if options.runMatfile==1
				movieFrames = size(matObj,options.matfileVarname);
				movieFrames = movieFrames(3);
			else
				movieFrames = size(thisMovie,3);
			end
			if movieFrames>500
				ostruct.movieFrames{fileNum} = 500;
			else
				ostruct.movieFrames{fileNum} = movieFrames;
			end

			% save file filter regexp based on saveStr
			ostruct.fileFilterRegexp{fileNum} = saveStr;

			toc(fileStartTime)
			toc(startTime)

			fileNumToRun = fileNumToRun + 1;
		catch err
			display(repmat('@',1,7))
			display(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
			%
			clear thisMovie
			% ostruct.savedFilePaths{fileNum} = [];
			ostruct.savedFilePaths{end+1} = [];
			fileNumToRun = fileNumToRun + 1;
			% try to save the current point in the analysis
			try
				% display(['trying to save: ' savePathStr]);
				% writeHDF5Data(thisMovie,savePathStr);
			catch err2
				display(repmat('@',1,7))
				display(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
				display(getReport(err2,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
		clear thisMovie
		diary OFF;
		if options.turboreg.resetParallelPool==1
			manageParallelWorkers('parallel',options.turboreg.useParallel,'setNumCores',options.turboreg.nParallelWorkers,'openCloseParallelPool','close');
		end
	end
	% ask the user for PCA-ICA parameters if not input in the files
	% if options.inputPCAICA==0
	% 	[ostruct options] = getPcaIcaParams(ostruct,options)
	% end
	[ostruct, options] = localfxn_playOutputMovies(ostruct,options);

	toc(startTime)

	cd(startDir)

	% Change input HDF5 dataset name to the new output dataset name
	disp(['Changing' ciapkg.pkgName 'input HDF5 dataset name "' obj.inputDatasetName '"->"' obj.outputDatasetName '"'])
	obj.inputDatasetName = obj.outputDatasetName;

	function nestedfxn_mouseWheelChange(hObject, callbackdata, handles)
		% Change keyIn to force while loop to exit, need for certain commands.
		keyIn = 0;

		if callbackdata.VerticalScrollCount > 0
			set(gcf,'Tag','next')
		elseif callbackdata.VerticalScrollCount < 0
			set(gcf,'Tag','next')
		end
	end
	function nestedfxn_resetSetpsMenu(src,event)
		% analysisOptionListOrig = analysisOptionList;
		% defaultChoiceListOrig = defaultChoiceList;
		analysisOptionListStr = analysisOptionListOrig;
		for optNoS2 = 1:length(analysisOptionListStr)
			analysisOptionListStr{optNoS2} = analysisOptsInfo.(analysisOptionListStr{optNoS2}).str;
		end
		defaultChoiceIdx = find(ismember(analysisOptionListOrig,defaultChoiceListOrig));
		hListbox.String = analysisOptionListStr;
		hListbox.Value = defaultChoiceIdx;

		hListboxS.String = analysisOptionListStr;
		hListboxS.Value = defaultChoiceIdx(end);
	end
	function nestedfxn_highlightDefault(src,event)
		% analysisOptionListOrig = analysisOptionList;
		% defaultChoiceListOrig = defaultChoiceList;
		% analysisOptionListStr = analysisOptionListOrig;
		% for optNoS = 1:length(analysisOptionListStr)
		% 	analysisOptionListStr{optNoS} = analysisOptsInfo.(analysisOptionListStr{optNoS}).str;
		% end
		% Correct back to original names before proceeding
		tmpList = hListbox.String;
		fnTmp = fieldnames(analysisOptsInfo);
		for optNoS = 1:length(tmpList)
			for fnNo = 1:length(fnTmp)
				if strcmp(tmpList{optNoS},analysisOptsInfo.(fnTmp{fnNo}).str)==1
					tmpList{optNoS} = fnTmp{fnNo};
				end
			end
		end

		defaultChoiceIdx = find(ismember(tmpList,defaultChoiceListOrig));
		% hListbox.String = analysisOptionListStr;
		hListbox.Value = defaultChoiceIdx;
		hListboxS.Value = defaultChoiceIdx(end);
	end
	function nestedfxn_analysisOutputMenuChange(src,event)
		% analysisOptionListOrig = analysisOptionList;
		% defaultChoiceListOrig = defaultChoiceList;
		% analysisOptionListStr = analysisOptionListOrig;
		% for optNoS = 1:length(analysisOptionListStr)
		% 	analysisOptionListStr{optNoS} = analysisOptsInfo.(analysisOptionListStr{optNoS}).str;
		% end
		% Correct back to original names before proceeding
		% return;
		tmpList = hListbox.String;
		hListboxS.String = hListbox.String;

		% fnTmp = fieldnames(analysisOptsInfo);
		% for optNoS = 1:length(tmpList)
		% 	for fnNo = 1:length(fnTmp)
		% 		if strcmp(tmpList{optNoS},analysisOptsInfo.(fnTmp{fnNo}).str)==1
		% 			tmpList{optNoS} = fnTmp{fnNo};
		% 		end
		% 	end
		% end

		% tmpListEnd = tmpList{end};
		% defaultChoiceIdx = find(ismember(tmpListEnd,tmpList));
		% % hListbox.String = analysisOptionListStr;
		% hListboxS.Value = defaultChoiceIdx;

		hListboxS.Value = hListbox.Value(end);

		% defaultSaveList = analysisOptionList{analysisOptionsIdx(end)};
		% defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	end	
	function nestedfxn_analysisOutputMenuChange2(src,event,PERMORDER)
		% analysisOptionListOrig = analysisOptionList;
		% defaultChoiceListOrig = defaultChoiceList;
		% analysisOptionListStr = analysisOptionListOrig;
		% for optNoS = 1:length(analysisOptionListStr)
		% 	analysisOptionListStr{optNoS} = analysisOptsInfo.(analysisOptionListStr{optNoS}).str;
		% end
		% Correct back to original names before proceeding
		hListboxS.String = hListbox.String(PERMORDER);

		% tmpList = hListboxS.String;
		% fnTmp = fieldnames(analysisOptsInfo);
		% for optNoS = 1:length(tmpList)
		% 	for fnNo = 1:length(fnTmp)
		% 		if strcmp(tmpList{optNoS},analysisOptsInfo.(fnTmp{fnNo}).str)==1
		% 			tmpList{optNoS} = fnTmp{fnNo};
		% 		end
		% 	end
		% end

		% tmpList2 = tmpList(hListbox.Value);
		% tmpList2
		% tmpList2 = tmpList2{end};
		% defaultChoiceIdx = find(ismember(tmpList2,tmpList));
		% hListbox.String = analysisOptionListStr;
		hListboxS.Value = hListbox.Value(end);

		% defaultSaveList = analysisOptionList{analysisOptionsIdx(end)};
		% defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	end	
	function nestedfxn_closeOptions(src,event)
		delete(emptyBox);
	end
	function nestedfxn_closeOptionsKey(src,event)
		if event.Key=="return"
			delete(emptyBox)
		end
	end
	function nestedfxn_fixErrorFrames()
		% Fixes frames in which the camera gives out garbled or improperly formatted data.

		nRegions = 4;
		nFramesHere = size(thisMovie,3);
		metrixMatrix = zeros([nRegions nFrames]);

		for subregionNo = 1:nRegions
			% Select sub-regions to use for analysis.


			% Calculate metric (e.g. difference, correlation, etc.) between


			% Z-score metric by normalizing across all frames.
		end


		% Use threshold to determine which


		% Calculate replacement frame, e.g. mean


		% Replace frames.

	end
	function nestedfxn_addDroppedFrames()
		% TODO: to make this proper, need to verify that the log file names match those of movie files
		display(repmat('-',1,7));

		if ~isempty(options.calcDroppedFramesFromMovie)==1
			% Do not need full movie if calculating dropped frames from the movie, continue.
		elseif ~isempty(options.frameList)
			disp('Full movie needs to be loaded to add dropped frames')
			return;
		else

		end

		disp('adding in dropped frames if any')
		listLogFiles = getFileList(thisDir,options.logFileRegexp);

		if isempty(listLogFiles) && isempty(options.calcDroppedFramesFromMovie)
			disp('Add log files to folder in order to add back dropped frames')
			return;
		elseif ~isempty(listLogFiles)
			% get information about number of frames and dropped frames from recording files
			cellfun(@display,listLogFiles);
			folderLogInfoList = cellfun(@(x) {getLogInfo(x)},listLogFiles,'UniformOutput',false);
			folderFrameNumList = {};
			droppedCountList = {};
			dropType = 'add';
			for cellNo = 1:length(folderLogInfoList)
				logInfo = folderLogInfoList{cellNo}{1};
				fileType = logInfo.fileType;
				switch fileType
					case 'inscopix'
						movieFrames = logInfo.FRAMES;
						droppedCount = logInfo.DROPPED;
					case 'inscopixXML'
						movieFrames = logInfo.frames;
						droppedCount = logInfo.dropped;
					case 'inscopixMAT'
						movieFrames = logInfo.num_samples;
						droppedCount = logInfo.dropped;
						dropType = 'replace';
					otherwise
						% do nothing
				end
				% ensure that it is a string so numbers don't get added incorrectly
				if ischar(droppedCount)
					display(['converting droppedCount str2num: ' logInfo.filename])
					droppedCount = str2num(droppedCount);
				end
				if ischar(movieFrames)
					display(['converting movieFrames str2num: ' logInfo.filename])
					movieFrames = str2num(movieFrames);
				end
				folderFrameNumList{cellNo} = movieFrames;
				droppedCountList{cellNo} = droppedCount;
			end

			% Add back in dropped frames as the mean of the movie, NaN would be *correct* but causes issues with some of the downstream downsampling algorithms
			if options.processMoviesSeparately==1
				droppedFrames = droppedCountList{movieNo};
				originalNumMovieFrames = folderFrameNumList{movieNo};
			else
				% make the dropped frames and original num movie frames based on global across all movies, so dropped frames should match the CORRECTED global/concatenated movie's frame values
				originalNumMovieFrames = sum([folderFrameNumList{:}]);
				nMoviesDropped = length(movieList);
				for movieDroppedNo = 1:nMoviesDropped
					folderFrameNumList{movieDroppedNo} = folderFrameNumList{movieDroppedNo}+ length(droppedCountList{movieDroppedNo});
				end
				droppedFramesTotal = droppedCountList{1};
				for movieDroppedNo = 2:nMoviesDropped
					droppedFramesTmp = droppedCountList{movieDroppedNo} + sum([folderFrameNumList{1:(movieDroppedNo-1)}]);
					droppedFramesTotal = [droppedFramesTotal(:); droppedFramesTmp(:)];
				end
				droppedFrames = droppedFramesTotal;
			end
		else
			droppedFrames = [];
		end

		% In the case of Inscopix v3 and similar movies, users can force a final check
		if isempty(droppedFrames) && ~isempty(options.calcDroppedFramesFromMovie)
			perFrameCheck = squeeze(mean(thisMovie,[1 2],'omitnan'));
			figure;plot(perFrameCheck)
			if isnan(options.calcDroppedFramesFromMovie)
				perFrameCheck = isnan(perFrameCheck);
			else
				perFrameCheck = perFrameCheck==options.calcDroppedFramesFromMovie;
			end
			droppedFrames = find(perFrameCheck);
			dropType = 'replace';
		end

		if isempty(droppedFrames)
			disp('No dropped frames!')
			return;
		end

		% framesToAdd = originalNumMovieFrames-size(thisMovie,3);
		% extend the movie, adding in the mean
		inputMovieDroppedF0 = zeros([size(thisMovie,1) size(thisMovie,2)]);
		nRows = size(thisMovie,1);
		reverseStr = '';

		switch dropType
			case 'add'

			case 'replace'
				% Set dropped frames to NaN to ignore in mean calculation
				thisMovie(:,:,droppedFrames) = NaN;

				% Only use non-dropped frames to get mean since by default 0s.
				% framesToUse = setdiff(1:size(thisMovie,3),droppedFrames);
				% for rowNo=
				% 	inputMovieDroppedF0(rowNo,:) = mean(squeeze(thisMovie(rowNo,:,framesToUse)),2,'omitnan');
				% 	if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);end
				% end
			otherwise
				% Do nothing
		end
		for rowNo=1:nRows
			inputMovieDroppedF0(rowNo,:) = mean(squeeze(thisMovie(rowNo,:,:)),2,'omitnan');
			if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);end
		end
		% movieMean = mean(inputMovieTmp,[1 2 3],'omitnan');
		display([num2str(length(droppedFrames)) ' dropped frames: ' num2str(droppedFrames(:)')])

		switch dropType
			case 'add'
				display(['pre-corrected movie size: ' num2str(size(thisMovie))])
				thisMovie(:,:,(end+1):(end+length(droppedFrames))) = 0;
				display(['post-corrected movie size: ' num2str(size(thisMovie))])
				% vectorized way: get the setdiff(dropped,totalFrames), use this corrected frame indexes and map onto the actual frames in raw movie, shift all frames in original matrix to new position then add in mean to dropped frame indexes
				disp('adding in dropped frames to matrix...')
				correctFrameIdx = setdiff(1:size(thisMovie,3),droppedFrames);
				thisMovie(:,:,correctFrameIdx) = thisMovie(:,:,1:originalNumMovieFrames);
			case 'replace'
				% Do nothing, dropped frames already in the movie.
			otherwise
				% Do nothing
		end

		nDroppedFrames = length(droppedFrames);
		reverseStr = '';
		for droppedFrameNo = 1:nDroppedFrames
			thisMovie(:,:,droppedFrames(droppedFrameNo)) = inputMovieDroppedF0;
			if mod(droppedFrameNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','adding in dropped frames...','waitbarOn',1,'displayEvery',5);end
		end

		% loop over each dropped count and shift movie contents
		% nDroppedFrames = length(droppedFrames);
		% reverseStr = '';
		% for droppedFrameNo = 1:nDroppedFrames
		% 	thisMovie(:,:,(droppedFrames(droppedFrameNo)+1):(end)) = thisMovie(:,:,droppedFrames(droppedFrameNo):(end-1));
		% 	thisMovie(:,:,droppedFrames(droppedFrameNo)) = movieMean;
		% 	reverseStr = cmdWaitbar(droppedFrameNo,nDroppedFrames,reverseStr,'inputStr','adding back dropped frames...','waitbarOn',1,'displayEvery',5);
		% end
	end

	function subfxn_downsampleTimeInputMovie()
		options.downsampleZ = [];
		% thisMovie = single(thisMovie);
		options.downsampleFactor = options.turboreg.downsampleFactorTime;
		disp(['Temporal downsample factor: ' num2str(options.downsampleFactor)]);
		% thisMovie = downsampleMovie(thisMovie,'downsampleFactor',options.downsampleFactor);
		% =====================
		% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
		downX = size(thisMovie,1);
		downY = size(thisMovie,2);
		if isempty(options.downsampleZ)
			downZ = floor(size(thisMovie,3)/options.downsampleFactor);
		else
			downZ = options.downsampleZ;
		end
		disp(['# frames after downsampling: ' num2str(downZ)]);
		% pre-allocate movie
		% inputMovieDownsampled = zeros([downX downY downZ]);
		% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
		reverseStr = '';
		for frame=1:downY
		   downsampledFrame = imresize(squeeze(thisMovie(:,frame,:)),[downX downZ],'bilinear');
		   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
		   thisMovie(1:downX,frame,1:downZ) = downsampledFrame;
		   % inputMovie(:,frame,:) = downsampledFrame;
			if mod(frame,20)==0&&options.waitbarOn==1||frame==downY
				reverseStr = cmdWaitbar(frame,downY,reverseStr,'inputStr','temporally downsampling matrix');
			end
		end
		localfxn_dispMovieSize(thisMovie);
		% reverseStr = '';
		% for frame = (downZ+1):size(thisMovie,3)
		%     thisMovie(:,:,1) = [];
		%     reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr','removing elements');
		% end
		%thisMovie = thisMovie(:,:,1:downZ);
		thisMovie(:,:,(downZ+1):end) = 0;
		% thisMovie(:,:,(downZ+1):end) = [];
		thisMovieTmp = thisMovie(:,:,1:downZ);
		clear thisMovie;
		thisMovie = thisMovieTmp;
		clear thisMovieTmp;
		localfxn_dispMovieSize(thisMovie);
		drawnow;
		% =====================
	end

	function subfxn_downsampleSpaceInputMovie()
		% Nested function to downsample input movie in space
		options.downsampleZ = [];
		options.waitbarOn = 1;
		% thisMovie = single(thisMovie);
		options.downsampleFactor = options.turboreg.downsampleFactorSpace;
		disp(['Spatial downsample factor: ' num2str(options.downsampleFactor)])
		secondaryDownsampleType = 'bilinear';
		% exact dimensions to downsample in x (rows)
		options.downsampleX = [];
		% exact dimensions to downsample in y (columns)
		options.downsampleY = [];
		% thisMovie = downsampleMovie(thisMovie,'downsampleFactor',options.downsampleFactor);
		% =====================
		% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
		downX = floor(size(thisMovie,1)/options.downsampleFactor);
		if ~isempty(options.downsampleX);downX = options.downsampleX; end
		downY = floor(size(thisMovie,2)/options.downsampleFactor);
		if ~isempty(options.downsampleY);downY = options.downsampleY; end
		downZ = size(thisMovie,3);
		% pre-allocate movie
		% inputMovieDownsampled = zeros([downX downY downZ]);
		% this is a normal for loop at the moment, if convert thisMovie to cell array, can force it to be parallel
		reverseStr = '';
		for frame=1:downZ
			downsampledFrame = imresize(squeeze(thisMovie(:,:,frame)),[downX downY],secondaryDownsampleType);
			% to reduce memory footprint, place new frame in old movie and cut off the unneeded space after
			if options.downsampleFactor<1
				inputMovieTmp(1:downX,1:downY,frame) = downsampledFrame;
			else
				thisMovie(1:downX,1:downY,frame) = downsampledFrame;
			end
			% inputMovieDownsampled(1:downX,1:downY,frame) = downsampledFrame;
			if mod(frame,20)==0&&options.waitbarOn==1||frame==downZ
				reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr',[secondaryDownsampleType 'spatially downsampling matrix']);
			end
		end
		thisMovie = thisMovie(1:downX,1:downY,:);
		localfxn_dispMovieSize(thisMovie);

		if exist('turboRegCoords','var')
			% Adjust crop coordinates if downsampling in space takes place before turboreg
			disp(['Adjusting motion correction crop coordinates for spatial downsampling: ' num2str(turboRegCoords{fileNum}{movieNo})]);
			orderCheck = find(strcmp(analysisOptionList(analysisOptionsIdx),'downsampleSpace'))<find(strcmp(analysisOptionList(analysisOptionsIdx),'turboreg'));
			if ~isempty(turboRegCoords{fileNum}{movieNo})&&any(orderCheck)
				turboRegCoords{fileNum}{movieNo} = floor(turboRegCoords{fileNum}{movieNo}/options.downsampleFactor);
				% Ensure that the turbo crop coordinates are greater than zero
				turboRegCoords{fileNum}{movieNo} = max(1,turboRegCoords{fileNum}{movieNo});
			end
			disp(['Adjusted motion correction crop coordinates due to spatial downsampling: ' num2str(turboRegCoords{fileNum}{movieNo})]);
		end

		drawnow;
		% =====================
	end

	function subfxn_dfofInputMovie()
		% dfof must have positive values
		% thisMovieMin = min(thisMovie,[1 2 3],'omitnan');
		if strcmp(options.turboreg.filterBeforeRegister,'bandpass')
			thisMovie = thisMovie+1;
		end

		% adjust for problems with movies that have negative pixel values before dfof
		minMovie = min(thisMovie,[],[1 2 3],'omitnan');
		if minMovie<0
			thisMovie = thisMovie + 1.1*abs(minMovie);
		end
		% leave mean at 1, goes to zero when doing pca ica
		% thisMovie = dfofMovie(thisMovie,'dfofType',options.dfofType);
		% figure(1970+fileNum)
		% 	subplot(2,1,1)
			% plot(squeeze(mean(thisMovie,[1 2],'omitnan')))
		% 	% title(['mean | ' ]);
		% 	ylabel('mean');box off;
		% 	subplot(2,1,2)
		% 	plot(squeeze(nanvar(nanvar(thisMovie,[],1),[],2)))
		% 	% title('variance');
		% 	ylabel('variance');xlabel('frame'); box off;
		% 	ciapkg.overloaded.suptitle(thisDirSaveStr)
		% =====================
		% get the movie F0
		% thisMovie = single(thisMovie);
		disp('getting F0...')
		inputMovieF0 = zeros([size(thisMovie,1) size(thisMovie,2)]);
		if strcmp(options.dfofType,'dfstd')
			inputMovieStd = zeros([size(thisMovie,1) size(thisMovie,2)]);
			progressStr = 'calculating mean and std...';
		else
			progressStr = 'calculating mean...';
		end
		nRows = size(thisMovie,1);
		reverseStr = '';

		% Determine the type of F0 calculation to perform.
		switch options.dfofType
			case 'dfof'
				F0fxn = @(x,y) mean(x,y,'omitnan');
			case 'dfofMin'
				switch options.minType
					case 'min'
						F0fxn = @(x,y) min(x,y,'omitnan');
					case 'soft'
						F0fxn = @(x,y) prctile(x,options.minSoftPct,y);
					otherwise
						F0fxn = @(x,y) min(x,y,'omitnan');
				end
			otherwise
				F0fxn = @(x,y) mean(x,y,'omitnan');
		end

		for rowNo=1:nRows
			% inputMovieF0 = mean(inputMovie,3,'omitnan');
			rowFrame = single(squeeze(thisMovie(rowNo,:,:)));
			% inputMovieF0(rowNo,:) = mean(rowFrame,2,'omitnan');
			inputMovieF0(rowNo,:) = F0fxn(rowFrame,2);
			if strcmp(options.dfofType,'dfstd')
				inputMovieStd(rowNo,:) = std(rowFrame,[],2,'omitnan');
			else
			end
			if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr',progressStr,'waitbarOn',1,'displayEvery',5);end
		end

		% Save out F0 in case need later
		% savePathStr = [thisDirSaveStr '_inputMovieF0' '.h5'];
		savePathStr = [thisProcessingDirFileInfoStr '_inputMovieF0' '.h5'];
		movieSaved = writeHDF5Data(inputMovieF0,savePathStr,'deflateLevel',options.deflateLevel,'datasetname',options.outputDatasetName);

		thisMovieMean = mean(inputMovieF0,[1 2],'omitnan');
		% bsxfun for fast matrix divide
		switch options.dfofType
			case 'divide'
				disp('F(t)/F0...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
			case 'dfof'
				disp('F(t)/F0 - 1...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				% thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
				reverseStr = '';
				nFrames = size(thisMovie,3);
				for frameNo = 1:nFrames
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)./inputMovieF0;
					if mod(rowNo,50)==0;reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','DFOF','waitbarOn',1,'displayEvery',50);end
				end
				thisMovie = thisMovie-1;
			case 'dfofMin'
				
				switch options.minType
					case 'min'
						disp('F(t)/F0 - 1, F0 = min...')
					case 'soft'
						disp('F(t)/F0 - 1, F0 = min prctile...')
					otherwise
						disp('F(t)/F0 - 1, F0 = min...')
				end
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				% thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
				reverseStr = '';
				nFrames = size(thisMovie,3);
				for frameNo = 1:nFrames
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)./inputMovieF0;
					if mod(rowNo,50)==0;reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','DFOF','waitbarOn',1,'displayEvery',50);end
				end
				thisMovie = thisMovie-1;
			case 'dfstd'
				disp('(F(t)-F0)/std...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				% dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
				% dfofMatrix = bsxfun(@ldivide,inputMovieStd,dfofMatrix);

				reverseStr = '';
				nFrames = size(thisMovie,3);
				for frameNo = 1:nFrames
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)-inputMovieF0;
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)./inputMovieStd;
					if mod(rowNo,50)==0;reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','DFOF','waitbarOn',1,'displayEvery',50);end
				end
				% thisMovie = thisMovie-1;
			case 'minus'
				disp('F(t)-F0...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				thisMovie = bsxfun(@minus,thisMovie,inputMovieF0);
			otherwise
				% return;
		end
		% =====================
	end
	function subfxn_plotMotionCorrectionMetric(motionState)
		try
			disp('Calculating and plotting correlation metric')
			colorList = hsv(length(obj.inputFolders));

			meanG = mean(thisMovie,3);
			corrMetric = NaN([1 size(thisMovie,3)]);
			corrMetric2 = NaN([1 size(thisMovie,3)]);
			cc = turboRegCoords{fileNum}{movieNo};
			meanG_cc = meanG(cc(2):cc(4),cc(1):cc(3));
			fprintf('Calculating correlation metric: ')
			nFramesThis = size(thisMovie,3);

			thisMovieTmp2 = thisMovie(cc(2):cc(4),cc(1):cc(3),:);
			parfor i = 1:nFramesThis
				if mod(i,500)==0
					fprintf('%d | ',round((i/nFramesThis)*100));
				end
				thisFrame_cc = thisMovieTmp2(:,:,i);
				corrMetric(i) = corr2(meanG_cc,thisFrame_cc);
				corrMetric2(i) = corr(meanG_cc(:),thisFrame_cc(:),'Type','Spearman');
			end

			openFigure(1865);
			% ax1 = [];
			% ax1(end+1) = subplot(1,2,1)
			subplot(1,2,1)
				if strcmp(motionState,'start')
					plot(corrMetric,'Color',colorList(fileNum,:))
				else
					plot(corrMetric,':','Color',colorList(fileNum,:)/1.5)
				end
				hold on;
				box off;xlabel('Frames');ylabel('Correlation')
				title('corr2')
				% legend({'Original','Motion corrected'})
				% box off;xlabel('Frames');ylabel('Correlation')
				% title('corr2')
			% ax1(end+1) = subplot(1,2,2)
				% ciapkg.overloaded.suptitle("Pearson correlation of all frames to movie mean")
				title("Pearson correlation of all frames to movie mean")
				legendStr = cellfun(@(x) {strcat('===',x,sprintf('===\nPre-motion correction corr2')),'Post-motion correction corr2'},obj.folderBaseDisplayStr,'UniformOutput',false);
				legend([legendStr{:}])

			subplot(1,2,2)
			% openFigure(1866);
				if strcmp(motionState,'start')
					plot(corrMetric2,'-','Color',colorList(fileNum,:)/2)
				else
					plot(corrMetric2,':','Color',colorList(fileNum,:)/3)
				end
				hold on;
				box off;xlabel('Frames');ylabel('Correlation')
				title('Spearman''s correlation (corr)')
				% legend({'Original','Motion corrected'}
				legendStr = cellfun(@(x) {strcat('===',x,sprintf('===\nPre-motion correction Spearman')),'Post-motion correction Spearman'},obj.folderBaseDisplayStr,'UniformOutput',false);
				legend([legendStr{:}])
				title("Spearman's correlation of all frames to movie mean.")

			% set(ax1,'Nextplot','add')
			% ciapkg.overloaded.suptitle('Correlation of all frames to movie mean')

			% legendStr = cellfun(@(x) {strcat('===',x,sprintf('===\nPre-motion correction corr2')),'Pre-motion correction Spearman','Post-motion correction corr2','Post-motion correction Spearman'},obj.folderBaseDisplayStr,'UniformOutput',false);
			% legend([legendStr{:}])
			hold on;
			zoom on;
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
	function subfxn_turboregInputMovie()
		disp(['Motion correction method: ' options.turboreg.mcMethod])
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		disp(['registering sublists: ' num2str(subsetList)]);
		disp(options.turboreg.mcMethod)
		% convert movie to single for turboreg
		localfxn_dispMovieSize(thisMovie);
		% thisMovie = single(thisMovie);
		% get reference frame before subsetting, so won't change
		% thisMovieRefFrame = squeeze(thisMovie(:,:,options.refCropFrame));
		% Take the mean of the reference frame or frames (if a single frame will produce the same output)
		thisMovieRefFrame = squeeze(mean(thisMovie(:,:,options.refCropFrame),3,'omitnan'));
		nSubsets = (length(subsetList)-1);
		% turboregThisMovie = single(zeros([size(thisMovie,1) size(thisMovie,2) 1]));

		% whos
		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				% display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				% display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			disp([num2str(movieSubset(1)) '-' num2str(movieSubset(end)) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			disp(repmat('$',1,7))
			%run with altered defaults
			% ioptions.Levels = 2;
			% ioptions.Lastlevels = 1;
			% ioptions.complementMatrix = 0;
			% ioptions.minGain=0.0;
			% ioptions.SmoothX = 80;
			% ioptions.SmoothY = 80;

			% Set the motion correction algorithm
			ioptions.mcMethod = options.turboreg.mcMethod;

			% Load in prior motion correction coordinates if input by the user.
			ioptions.precomputedRegistrationCooordsFullMovie = options.precomputedRegistrationCooordsFullMovie;

			ioptions.turboregRotation = options.turboreg.turboregRotation;
			ioptions.RegisType = options.turboreg.RegisType;
			ioptions.parallel = options.turboreg.parallel;
			ioptions.meanSubtract = options.turboreg.normalizeMeanSubtract;
			ioptions.meanSubtractNormalize = options.turboreg.normalizeMeanSubtractNormalize;
			ioptions.complementMatrix = options.turboreg.normalizeComplementMatrix;
			ioptions.normalizeType = options.turboreg.normalizeType;
			ioptions.registrationFxn = options.turboreg.registrationFxn;
			ioptions.freqLow = options.turboreg.filterBeforeRegFreqLow;
			ioptions.freqHigh = options.turboreg.filterBeforeRegFreqHigh;

			ioptions.SmoothX = options.turboreg.SmoothX;
			ioptions.SmoothY = options.turboreg.SmoothY;
			ioptions.zapMean = options.turboreg.zapMean;

			if iterationNo~=options.turboreg.numTurboregIterations
				ioptions.normalizeBeforeRegister = [];
			elseif iterationNo==options.turboreg.numTurboregIterations
				ioptions.normalizeBeforeRegister = options.turboreg.filterBeforeRegister;
			end
			% ioptions.normalizeBeforeRegister = options.turboreg.filterBeforeRegister;
			ioptions.imagejFFTLarge = options.turboreg.filterBeforeRegImagejFFTLarge;
			ioptions.imagejFFTSmall = options.turboreg.filterBeforeRegImagejFFTSmall;

			if ~isempty(options.turboreg.saveFilterBeforeRegister)
				options.turboreg.saveFilterBeforeRegister = [thisDirSaveStr saveStr '_lowpass'];
				if obj.nwbLoadFiles==0
					options.turboreg.saveFilterBeforeRegister = [options.turboreg.saveFilterBeforeRegister '.h5'];
				elseif obj.nwbLoadFiles==1
					options.turboreg.saveFilterBeforeRegister = [options.turboreg.saveFilterBeforeRegister '.nwb'];
				else
					options.turboreg.saveFilterBeforeRegister = [options.turboreg.saveFilterBeforeRegister '.h5'];
				end
			end
			ioptions.saveNormalizeBeforeRegister = options.turboreg.saveFilterBeforeRegister;
			%
			ioptions.cropCoords = turboRegCoords{fileNum}{movieNo};
			ioptions.closeMatlabPool = 0;
			% If multiple frames requested, only use the 1st
			ioptions.refFrame = options.refCropFrame(1);
			ioptions.refFrameMatrix = thisMovieRefFrame;

			ioptions.optsNoRMCorre = optsNoRMCorre;

			% Displacement fields
			ioptions.df_AccumulatedFieldSmoothing = options.turboreg.df_AccumulatedFieldSmoothing;
			ioptions.df_Niter = options.turboreg.df_Niter;
			ioptions.df_PyramidLevels = options.turboreg.df_PyramidLevels;

			ioptions.displayOptions = 1;
			ioptions
			% for frameDftNo = movieSubset
			% 	refFftFrame = fft2(thisMovieRefFrame);
			% 	regFftFrame = fft2(squeeze(thisMovie(:,:,frameDftNo)));
			% 	[output Greg] = dftregistration(refFftFrame,regFftFrame,100);
			% 	[~, ~] = openFigure(79854, '');
			% 	subplot(1,2,1);
			% 	imagesc(thisMovieRefFrame);
			% 	title(['Reference image: ' num2str(options.refCropFrame)])
			% 	subplot(1,2,2);
			% 	% ifft2(Greg)
			% 	imagesc(real(ifft2(Greg)));
			% 	title(['Registered image: ' num2str(frameDftNo)])
			% 	colormap gray
			% 	drawnow
			% 	% commandwindow
			% 	% pause
			% end
			% playMovie(thisMovie);
			% dt=whos('VARIABLE_YOU_CARE_ABOUT'); MB=dt.bytes*9.53674e-7;
			% thisMovie(:,:,movieSubset) = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);
			% j = whos('turboregThisMovie');j.bytes=j.bytes*9.53674e-7;j
			localfxn_dispMovieSize(thisMovie);
			% [thisMovie(:,:,movieSubset), ResultsOutOriginal{thisSet}] = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);


			% Register without spatial filtering if requested by user
			if options.turboreg.saveBeforeFilterRegister==1&&iterationNo==options.turboreg.numTurboregIterations
				% Motion correct with filtering applied if requested, save for later
				[tmpMovieWithFilter, ResultsOutOriginal{iterationNo}{thisSet}] = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);

				tmpMovieNoFilter = thisMovie(:,:,movieSubset);
				ioptions.precomputedRegistrationCooordsFullMovie = ResultsOutOriginal{iterationNo}{thisSet};

				% Verify that turboreg MEX function is in the path
				if isempty(which('turboreg'))==1
					ciapkg.loadBatchFxns();
				end

				[tmpMovieNoFilter, ~] = turboregMovie(tmpMovieNoFilter,'options',ioptions);

				% for iterationNo2 = 1:options.turboreg.numTurboregIterations
				% 	ioptions.precomputedRegistrationCooordsFullMovie = ResultsOutOriginal{iterationNo2}{thisSet};
				% 	[tmpMovieNoFilter, ~] = turboregMovie(tmpMovieNoFilter,'options',ioptions);
				% end
				% Crop movie
				tmpMovieNoFilter = localfxn_cropInputMovieSlice(tmpMovieNoFilter,options,ResultsOutOriginal);

				% Add filtered movie to overall registered subset
				thisMovie(:,:,movieSubset) = tmpMovieWithFilter;

				savePathStrTmp = [thisDirSaveStr saveStr '_noSpatialFilter_' num2str(movieNo)];
				if obj.nwbLoadFiles==0
					savePathStrTmp = [savePathStrTmp '.h5'];
				elseif obj.nwbLoadFiles==1
					savePathStrTmp = [savePathStrTmp '.nwb'];
				else
					savePathStrTmp = [savePathStrTmp '.h5'];
				end
				resaveCropFileName = savePathStrTmp;
				if thisSet==1
					optionsCopy = options;
					optionsCopy.turboreg = [];

					analysisOptionListTmp = analysisOptionList(analysisOptionsIdx);
					analysisOptionStruct = struct;for optNo=1:length(analysisOptionListTmp);analysisOptionStruct.([char(optNo+'A'-1) '_' analysisOptionListTmp{optNo}])=1;end
					% movieSaved = writeHDF5Data(thisMovie,savePathStr,'datasetname',options.outputDatasetName,'addInfo',{options.turboreg,analysisOptionStruct,optionsCopy},'addInfoName',{'/movie/processingSettings','/movie/analysisOperations','/movie/modelPreprocessMovieFunctionOptions'},'deflateLevel',options.deflateLevel)

					createHdf5File(savePathStrTmp, options.outputDatasetName, tmpMovieNoFilter, 'addInfo',{options.turboreg,analysisOptionStruct,optionsCopy},'addInfoName',{'/movie/processingSettings','/movie/analysisOperations','/movie/modelPreprocessMovieFunctionOptions'},'deflateLevel',options.deflateLevel);
				else
					if exist(savePathStrTmp,'file')==2
						appendDataToHdf5(savePathStrTmp, options.outputDatasetName, tmpMovieNoFilter);
					end
				end
				clear tmpMovieWithFilter tmpMovieNoFilter;
			else
				[thisMovie(:,:,movieSubset), ResultsOutOriginal{iterationNo}{thisSet}] = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);
			end
			clear ioptions;

			% if thisSet==1&thisSet~=nSubsets
			% 	% class(movieSubset)
			% 	% movieSubset
			% 	% thisMovie(:,:,movieSubset) = [];
			% 	% thisMovie = thisMovie(:,:,(subsetEndIdx):end);
			% elseif thisSet==nSubsets
			% 	% movieSubset-subsetStartIdx+1
			% 	thisMovie(:,:,movieSubset-subsetStartIdx+1) = turboregMovie(thisMovie(:,:,movieSubset-subsetStartIdx+1),'options',ioptions);
			% 	% clear thisMovie;
			% 	% thisMovie = turboregThisMovie;
			% 	% clear turboregThisMovie;
			% else
			% 	% movieSubset-subsetStartIdx+1
			% 	thisMovie(:,:,movieSubset-subsetStartIdx+1) = turboregMovie(thisMovie(:,:,movieSubset-subsetStartIdx+1),'options',ioptions);
			% 	% thisMovie(:,:,movieSubset-subsetStartIdx+1) = [];
			% 	% cutoffSubset = length(movieSubset);
			% 	% thisMovie = thisMovie(:,:,(cutoffSubset+1):end);
			% end
			% j = whos('turboregThisMovie');j.bytes=j.bytes*9.53674e-7;j
			% j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j
			% tmpMovieClass = class(tmpMovie);
			% cast(thisMovie,tmpMovieClass);
			% thisMovie(:,:,movieSubset) = tmpMovie;
			toc(subsetStartTime)
		end
		clear ioptions;
	end
	function tmpPxToCrop = subfxn_getCropValues()
		% Get values to use to add border and eliminate edge movement due to motion correction
		thisMovieMinMask = zeros([size(thisMovie,1) size(thisMovie,2)]);
		options.turboreg.registrationFxn
		switch options.turboreg.registrationFxn
			case 'imtransform'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(max(isnan(squeeze(thisMovie(row,:,:))),[],2,'omitnan'));
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			case 'transfturboreg'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(min(squeeze(thisMovie(row,:,:))~=0,[],2,'omitnan')==0);
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			otherwise
				% do nothing
		end
		topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
		bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
		leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
		rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
		tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
		display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])
	end
	function subfxn_cropInputMovie()
		% turboreg outputs 0s where movement goes off the screen
		thisMovieMinMask = zeros([size(thisMovie,1) size(thisMovie,2)]);
		options.turboreg.registrationFxn
		switch options.turboreg.registrationFxn
			case 'imtransform'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					% nanmin(~isnan(squeeze(thisMovie(row,:,:))),[],2)
					% thisMovieMinMask(row,:) = ~logical(nanmin(~isnan(squeeze(thisMovie(row,:,:))),[],2)>0);
					% if row==1
					% 	logical(nanmin(squeeze(thisMovie(row,:,:)),[],2)==0)'
					% end
					% thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:)),[],2)==0);
					thisMovieMinMask(row,:) = logical(max(isnan(squeeze(thisMovie(3,:,:))),[],2,'omitnan'));
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			case 'transfturboreg'
				% thisMovieMinMask = logical(nanmin(thisMovie~=0,[],3)==0);
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(min(squeeze(thisMovie(row,:,:))~=0,[],2,'omitnan')==0);
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			otherwise
				% do nothing
		end
		% [figHandle figNo] = openFigure(79854+fileNum, '');
		% imagesc(thisMovieMinMask); colormap gray;
		% ciapkg.overloaded.suptitle(thisDirSaveStr);
		% thisMovieMinMask(thisMovieMinMask==0) = NaN;
		% thisMovie = bsxfun(@times,thisMovieMinMask,thisMovie);
		topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
		bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
		leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
		rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
		tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
		display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])
		% % crop movie based on how much was turboreg'd
		% display('cropping movie...')
		% varImg = nanvar(thisMovie,[],3);
		% varImg = var(thisMovie,0,3);
		% medianVar = median(varImg(:));
		% stdVar = std(varImg(:));
		% twoSigma = 2*medianVar;
		% varImgX = median(varImg,1);
		% varImgY = median(varImg,2);
		% varThreshold = 1e3;
		% tmpPxToCrop = max([sum(varImgX>varThreshold) sum(varImgY>varThreshold)]);
		% imagesc(nanvar(thisMovie,[],3));
		% title('turboreg var projection');
		% % tmpPxToCrop = 10;
		% tmpPxToCrop
		if tmpPxToCrop~=0
			if tmpPxToCrop<options.pxToCrop
				% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
				subfxn_cropMatrixPreProcess(tmpPxToCrop);
			else
				% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
				subfxn_cropMatrixPreProcess(options.pxToCrop);
			end
		end
		% % convert to single (32-bit floating point)
		% % thisMovie = single(thisMovie);
		% saveStr = [saveStr '_crop'];
	end
	function subfxn_cropMatrixPreProcess(pxToCropPreprocess)
		% if size(thisMovie,2)>=size(thisMovie,1)
		% 	coords(1) = pxToCropPreprocess; %xmin
		% 	coords(2) = pxToCropPreprocess; %ymin
		% 	coords(3) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
		% 	coords(4) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		% else
		% 	coords(1) = pxToCropPreprocess; %xmin
		% 	coords(2) = pxToCropPreprocess; %ymin
		% 	coords(4) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
		% 	coords(3) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		% end
		% % a,b are left/right column values
		% a = coords(1);
		% b = coords(3);
		% % c,d are top/bottom row values
		% c = coords(2);
		% d = coords(4);

		topRowCrop = pxToCropPreprocess; % top row
		leftColCrop = pxToCropPreprocess; % left column
		bottomRowCrop = size(thisMovie,1)-pxToCropPreprocess; % bottom row
		rightColCrop = size(thisMovie,2)-pxToCropPreprocess; % right column

		% rowLen = size(thisMovie,1);
		% colLen = size(thisMovie,2);
		% set leftmost columns to NaN
		thisMovie(1:end,1:leftColCrop,:) = NaN;
		% set rightmost columns to NaN
		thisMovie(1:end,rightColCrop:end,:) = NaN;
		% set top rows to NaN
		thisMovie(1:topRowCrop,1:end,:) = NaN;
		% set bottom rows to NaN
		thisMovie(bottomRowCrop:end,1:end,:) = NaN;
	end
	function subfxn_medianFilterInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['registering sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		localfxn_dispMovieSize(thisMovie);
		% get reference frame before subsetting, so won't change
		nSubsets = (length(subsetList)-1);
		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			display(repmat('$',1,7))
			localfxn_dispMovieSize(thisMovie);
			thisMovie(:,:,movieSubset) = normalizeMovie(thisMovie(:,:,movieSubset),'normalizationType','medianFilter','medianFilterNeighborhoodSize',options.turboreg.medianFilterSize);
			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function subfxn_detrendInputMovie()
		% Plot trend before and after
		localfxn_dispMovieSize(thisMovie);

		disp('Calculating per-frame mean...')
		frameMeanInputMovie = squeeze(mean(thisMovie,[1 2],'omitnan'));

		try
			openFigure(figNoList.detrend);
			subplot(1,nMovies,1)
			plot(frameMeanInputMovie,'r-')
			box off;
			xlabel('Frames'); ylabel('Mean frame pixel intensity');
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end

		nFramesToNormalize = size(thisMovie,3);

		disp('Calculating detrend values...')
		trendVals = frameMeanInputMovie - detrend(frameMeanInputMovie,options.turboreg.detrendDegree);

		subplot(1,nMovies,1)
			hold on
			plot(squeeze(trendVals),'k--')
			drawnow;

		% meanInputMovie = detrend(frameMeanInputMovie,0);
		meanInputMovie = mean(frameMeanInputMovie,'omitnan');

		disp('Detrending movie start...')
		% reverseStr = '';
		% options_waitbarOn = options.waitbarOn;

		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		disp(['Detrending sublists: ' num2str(subsetList)]);
		% get reference frame before subsetting, so won't change
		% thisMovieRefFrame = squeeze(thisMovie(:,:,options.refCropFrame));
		% Take the mean of the reference frame or frames (if a single frame will produce the same output)
		thisMovieRefFrame = squeeze(mean(thisMovie(:,:,options.refCropFrame),3,'omitnan'));
		nSubsets = (length(subsetList)-1);
		% turboregThisMovie = single(zeros([size(thisMovie,1) size(thisMovie,2) 1]));

		frameListAll = 1:nFramesToNormalize;

		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				% display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				% display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			disp([num2str(movieSubset(1)) '-' num2str(movieSubset(end)) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			disp(repmat('$',1,7))

			% Create temporary subset variables.
			frameListTmp = frameListAll(movieSubset);
			trendValsTmp = trendVals(movieSubset);
			thisMovieTmp = thisMovie(:,:,movieSubset);
			nFramesDetrend = length(movieSubset);

			% parfor frame = 1:nFramesToNormalize
			parfor frame = 1:nFramesDetrend
				% thisMovie(:,:,frame) = thisMovie(:,:,frame) - trendVals(frame) + meanInputMovie;
				thisFrame = thisMovieTmp(:,:,frame) - trendValsTmp(frame) + meanInputMovie;
				thisMovieTmp(:,:,frame) = thisFrame;
				% inputMovieDownsampled(1:downX,1:downY,frame) = downsampledFrame;

				% if mod(frame,50)==0&&options_waitbarOn==1||frame==nFramesToNormalize
				% 	reverseStr = cmdWaitbar(frame,nFramesToNormalize,reverseStr,'inputStr',['Detrending movie...']);
				% end
			end
			thisMovie(:,:,movieSubset) = thisMovieTmp;
			toc(subsetStartTime)
		end
		disp('Detrending movie end...')

		localfxn_dispMovieSize(thisMovie);

		% Takes an input movie and removes an underlying change in mean frame fluorescence.
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','detrend','detrendDegree',options.turboreg.detrendDegree);

		openFigure(figNoList.detrend);
			try
				disp('Calculating per-frame mean...')
				frameMeanInputMovie = squeeze(mean(thisMovie,[1 2],'omitnan'));
				disp('Calculating detrend values...')
				trendVals = frameMeanInputMovie - detrend(frameMeanInputMovie,options.turboreg.detrendDegree);

				subplot(1,nMovies,1)
				hold on;
				plot(frameMeanInputMovie,'b-')

				plot(squeeze(trendVals),'m--')
				title(sprintf('%s | %d-degree fit detrend',fileInfoSaveStr,options.turboreg.detrendDegree))

				legend({'Raw movie signal','Trend line','Detrended movie signal','Trend line post-detrended'})
				drawnow
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
	end
	function subfxn_spatialFilterInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['filtering sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		localfxn_dispMovieSize(thisMovie);
		% get reference frame before subsetting, so won't change
		nSubsets = (length(subsetList)-1);
		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			display(repmat('$',1,7))
			localfxn_dispMovieSize(thisMovie);

			% thisMovie(:,:,movieSubset) = normalizeMovie(thisMovie(:,:,movieSubset),'normalizationType','medianFilter','medianFilterNeighborhoodSize',options.turboreg.medianFilterSize);

			% ioptions.normalizeType = options.turboreg.normalizeType;
			% ioptions.registrationFxn = options.turboreg.registrationFxn;
			% ioptions.freqLow = options.turboreg.filterBeforeRegFreqLow;
			% ioptions.freqHigh = options.turboreg.filterBeforeRegFreqHigh;

			switch options.turboreg.filterBeforeRegister
				case 'imagejFFT'
					imagefFftOnInputMovie('inputMovie');
				case 'divideByLowpass'
					disp('dividing movie by lowpass...')
					thisMovie(:,:,movieSubset) = normalizeMovie(single(thisMovie(:,:,movieSubset)),'normalizationType','lowpassFFTDivisive','freqLow',options.turboreg.filterBeforeRegFreqLow,'freqHigh',options.turboreg.filterBeforeRegFreqHigh,'waitbarOn',1,'bandpassMask','gaussian');
				case 'bandpass'
					disp('bandpass filtering...')
					[thisMovie(:,:,movieSubset)] = normalizeMovie(single(thisMovie(:,:,movieSubset)),'normalizationType','fft','freqLow',options.turboreg.filterBeforeRegFreqLow,'freqHigh',options.turboreg.filterBeforeRegFreqHigh,'bandpassType','bandpass','showImages',0,'bandpassMask','gaussian');
				otherwise
					% do nothing
			end

			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function subfxn_stripeRemovalInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['Stripe removal sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		localfxn_dispMovieSize(thisMovie);
		% get reference frame before subsetting, so won't change
		nSubsets = (length(subsetList)-1);
		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			display(repmat('$',1,7))
			localfxn_dispMovieSize(thisMovie);

			thisMovie(:,:,movieSubset) = removeStripsFromMovie(single(thisMovie(:,:,movieSubset)),'stripOrientation',options.turboreg.stripOrientationRemove,'meanFilterSize',options.turboreg.stripSize,'freqLowExclude',options.turboreg.stripfreqLowExclude,'bandpassType',options.turboreg.stripfreqBandpassType,'freqHighExclude',options.turboreg.stripfreqHighExclude,'waitbarOn',1);

			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function subfxn_movieProjectionsInputMovie()

		% get the max projection


		% get the mean projection
	end
	function subfxn_fftHighpassInputMovie()
		% do a highpass filter
		ioptions.normalizationType = 'fft';
		ioptions.freqLow = 7;
		ioptions.freqHigh = 500;
		ioptions.bandpassType = 'highpass';
		ioptions.showImages = 0;
		ioptions.bandpassMask = 'gaussian';
		[thisMovie] = normalizeMovie(thisMovie,'options',ioptions);
		if exist('tmpPxToCrop','var')
			if tmpPxToCrop<options.pxToCrop
				[thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
			else
				[thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
			end
		end
		% remove negative numbers
		[thisMovie] = normalizeVector(thisMovie,'normRange','zeroToOne');
		clear ioptions;
	end
	function subfxn_fftLowpassInputMovie()
		% do a lowpass filter
		ioptions.normalizationType = 'fft';
		ioptions.freqLow = 1;
		ioptions.freqHigh = 7;
		ioptions.bandpassType = 'lowpass';
		ioptions.showImages = 0;
		ioptions.bandpassMask = 'gaussian';
		% save lowpass as separate
		[thisMovieLowpass] = normalizeMovie(thisMovie,'options',ioptions);
		clear ioptions;
		if exist('tmpPxToCrop','var')
			if tmpPxToCrop<options.pxToCrop
				[thisMovieLowpass] = cropMatrix(thisMovieLowpass,'pxToCrop',tmpPxToCrop);
			else
				[thisMovieLowpass] = cropMatrix(thisMovieLowpass,'pxToCrop',options.pxToCrop);
			end
		end
		% save lowpass as separate
		if sum(optionIdx==saveIdx)
			savePathStr = [thisDirSaveStr saveStr];

			if obj.nwbLoadFiles==0
				savePathStr = [savePathStr '.h5'];
			elseif obj.nwbLoadFiles==1
				savePathStr = [savePathStr '.nwb'];
			else
				savePathStr = [savePathStr '.h5'];
			end

			movieSaved = saveMatrixToFile(thisMovieLowpass,savePathStr,'deflateLevel',options.deflateLevel,'inputDatasetName',options.outputDatasetName);
			% movieSaved = writeHDF5Data(thisMovieLowpass,savePathStr,'deflateLevel',options.deflateLevel,'datasetname',options.outputDatasetName);
		end
		% prevent lowpass file saving overwrite
		optionIdx = -1;
		clear thisMovieLowpass;
	end
end

function [turboRegCoords] = localfxn_turboregCropSelection(options,folderList)
	% Biafra Ahanonu
	% 2013.11.10 [19:28:53]

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	useOldGui = 0;
	usrIdxChoiceList = {-1,0,-2,0};
	if useOldGui==1
		usrIdxChoiceStr = {'NO | do not duplicate area coords across multiple folders','YES | duplicate area coords across multiple folders','YES | duplicate area coords if subject (animal) the same','YES | duplicate area coords across ALL folders'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','Motion correction area coordinates (area used to get registration translation coordinates)');
		% : use over multiple folders?
	end

	sel = options.turboreg.regRegionUseBtwnSessions;
	applyPreviousTurboreg = usrIdxChoiceList{sel};

	if sel==4
		runAllFolders = 1;
	else
		runAllFolders = 0;
	end

	folderListMinusComments = find(cellfun(@(x) isempty(x),strfind(folderList,'#')));
	nFilesToRun = length(folderListMinusComments);
	nFiles = length(folderList);
	disp(['folderListMinusComments class: ' class(folderListMinusComments)])

	coordsStructure.test = [];
	for fileNumIdx = 1:nFilesToRun
		fileNum = folderListMinusComments(fileNumIdx);

		movieList = regexp(folderList{fileNum},',','split');
		% movieList = movieList{1};
		movieList = getFileList(movieList, options.fileFilterRegexp);
		[movieList] = localfxn_removeUnsupportedFiles(movieList,options);
		if isempty(movieList)
			continue;
		end
		if options.processMoviesSeparately==1
			nMovies = length(movieList);
		else
			nMovies = 1;
		end
		for movieNo = 1:nMovies
			switch options.turboregType
				case 'preselect'
					if strfind(folderList{fileNum},'#')==1
						% display('skipping...')
						continue;
					end
					% opens frame n in each movie and asks the user to pre-select a region
					% thisDir = folderList{fileNum};
					dirInfo = regexp(folderList{fileNum},',','split');
					thisDir = dirInfo{1};
					display([num2str(fileNumIdx) '/' num2str(nFilesToRun) ': ' thisDir])
					disp(['options.fileFilterRegexp: ' options.fileFilterRegexp])
					movieList = getFileList(thisDir, options.fileFilterRegexp);
					[movieList] = localfxn_removeUnsupportedFiles(movieList,options);
					cellfun(@disp,movieList);
					inputFilePath = movieList{movieNo};
					if nMovies==1
						inputFilePath = movieList;
					else
						inputFilePath = movieList{movieNo};
					end

					frameToGrabHere = options.refCropFrame;
					if isempty(options.frameList)
					else
						frameToGrabHere = frameToGrabHere + options.frameList(1);	
					end

					if length(frameToGrabHere)==1&&options.turboreg.treatMoviesAsContinuousSwitch==0
						thisFrame = ciapkg.io.readFrame(inputFilePath,frameToGrabHere,'inputDatasetName',options.datasetName);
					elseif length(frameToGrabHere)==1&&options.turboreg.treatMoviesAsContinuousSwitch==1&&nMovies==1
						thisFrame = ciapkg.io.readFrame(inputFilePath,frameToGrabHere,'inputDatasetName',options.datasetName);
					else
						% for zFrame = 1:length(frameToGrabHere)

						% end
						thisFrame = ciapkg.io.loadMovieList(inputFilePath,'convertToDouble',0,'frameList',frameToGrabHere,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single');
					end
					
					if size(thisFrame,3)>1
					   % thisFrame = max(thisFrame,[],3);
					   % thisFrame = squeeze(thisFrame(:,:,1)); 
					   thisFrame = squeeze(mean(thisFrame(:,:,1),3,'omitnan')); 
					end

					[~, ~] = openFigure(9, '');
					titleStr = ['Click to drag-n-draw region.' 10 'Double-click region to continue.' 10 'Note: Only cropping for motion correction.' 10 'Original movie dimensions retained after registration.' 10 'Frame: ' num2str(frameToGrabHere)];
					subplot(1,2,1);
						imagesc(thisFrame);
						axis image;
						colormap gray;
						title(titleStr)
						box off;
						set(gcf,'color',[0 0 0]);
						set(gca,'color',[0 0 0]);
						ciapkg.view.changeFont('none','fontColor','w');
					set(0,'DefaultTextInterpreter','none');
					% ciapkg.overloaded.suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')],'fontSize',12,'plotregion',0.9,'titleypos',0.95);
					uicontrol('Style','Text','String',[num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' strrep(thisDir,'\','/')],'Units','normalized','Position',[0.1 0.9 0.8 0.10],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','Center');
					set(0,'DefaultTextInterpreter','latex');
					% subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('Click to drag-n-draw region. Double-click region to continue.')

					% Use ginput to select corner points of a rectangular
					% region by pointing and clicking the subject twice
					fileInfo = getFileInfo(thisDir);
					switch applyPreviousTurboreg
						case -1 %'NO | do not duplicate coords across multiple folders'
							% p = round(getrect);
							h = localfxn_getImRect(titleStr);
							p = round(wait(h));
						case 0 %'YES | duplicate coords across multiple folders'
							% p = round(getrect);
							h = localfxn_getImRect(titleStr);
							p = round(wait(h));
							coordsStructure.(fileInfo.subject) = p;
						case -2 %'YES | duplicate coords if subject the same'
							if ~any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
								% p = round(getrect);
								h = localfxn_getImRect(titleStr);
								p = round(wait(h));
								coordsStructure.(fileInfo.subject) = p;
							else
								p = coordsStructure.(fileInfo.subject);
							end
						otherwise
							% body
					end

					% % check that not outside movie dimensions
					% xMin = 1;
					% xMax = size(thisFrame,1);
					% yMin = 1;
					% yMax = size(thisFrame,2);
					% % adjust for the difference in centroid location if movie is cropped
					% xDiff = 0;
					% yDiff = 0;
					% if p(1)<xMin p(1) = 1; end
					% if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
					% if p(2)<yMin p(2)=1; end
					% if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end

					% Get the x and y corner coordinates as integers
					turboRegCoords{fileNum}{movieNo}(1) = p(1); %xmin
					turboRegCoords{fileNum}{movieNo}(2) = p(2); %ymin
					turboRegCoords{fileNum}{movieNo}(3) = p(1)+p(3); %xmax
					turboRegCoords{fileNum}{movieNo}(4) = p(2)+p(4); %ymax
					% turboRegCoords{fileNum}(1) = min(floor(p(1)), floor(p(2))); %xmin
					% turboRegCoords{fileNum}(2) = min(floor(p(3)), floor(p(4))); %ymin
					% turboRegCoords{fileNum}(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
					% turboRegCoords{fileNum}(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

					% Index into the original image to create the new image
					pts = turboRegCoords{fileNum}{movieNo};
					thisFrameCropped = thisFrame(pts(2):pts(4), pts(1):pts(3));
					% for poly region
					% sp=uint16(turboRegCoords{fileNum});
					% thisFrameCropped = thisFrame.*sp;

					% Display the subsetted image with appropriate axis ratio
					[~, ~] = openFigure(9, '');
					subplot(1,2,2);
						imagesc(thisFrameCropped);
						axis image;
						colormap gray;
						title('cropped region');
						set(gcf,'color',[0 0 0]);
						set(gca,'color',[0 0 0]);
						ciapkg.view.changeFont('none','fontColor','w');
						drawnow;

					if applyPreviousTurboreg==0
						if runAllFolders==1
							% basically go forever
							applyPreviousTurboreg = 42e3;
						else
							answer = inputdlg({'enter number of next folders to re-use coordinates on, click cancel if none'},'',1)
							if isempty(answer)
								applyPreviousTurboreg = 0;
							else
								applyPreviousTurboreg = str2num(answer{1});
							end
						end
					elseif applyPreviousTurboreg>0
						applyPreviousTurboreg = applyPreviousTurboreg - 1;
						pause(0.15)
					end
					if any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
						pause(0.15)
						disp(coordsStructure)
					end
				case 'coordinates'
					% gets the coordinates of the turboreg from the filelist
					disp('not implemented')
				otherwise
					% if no option selected, uses the entire FOV for each image
					disp('not implemented')
					turboRegCoords{fileNum}{movieNo}=[];
			end
		end
	end
end
function h = localfxn_getImRect(titleStr)
	h = imrect(gca);
	addNewPositionCallback(h,@(p) title([titleStr 10 mat2str(p,3)]));
	fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
	setPositionConstraintFcn(h,fcn);
end
% function [ostruct options] = getPcaIcaParams(ostruct,options)
function [ostruct, options] = localfxn_playOutputMovies(ostruct,options)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	nFiles = length(ostruct.savedFilePaths);
	maxFrames = 500;
	movieFrameList = {};
	numFramesPerPart = 50;
	numParts = 10;

	switch options.videoPlayer
		case 'imagej'
			disp('pre-allocating movies to display...')
			thisMovieArray = {};
			for fileNum=1:nFiles
				try
					disp('+++++++')
					if isempty(ostruct.savedFilePaths{fileNum})
						disp('no movie!')
						% display([num2str(fileNum) '/' num2str(nFiles) ' skipping: ' ostruct.savedFilePaths{fileNum}]);
						continue;
					else
						pathInfo = [num2str(fileNum) '/' num2str(nFiles) ': ' ostruct.savedFilePaths{fileNum}];
						% display(pathInfo);
						fprintf('%d/%d:%s\n',fileNum,nFiles,ostruct.savedFilePaths{fileNum})
					end
					movieList = {ostruct.savedFilePaths{fileNum}};

					% movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList,'getMovieDims',1);
					movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'getMovieDims',1,'inputDatasetName',options.outputDatasetName);

					movieFrames = movieDims.three;
					if movieFrames>500
						movieFrames = 500;
					else
						% ostruct.movieFrames{fileNum} = movieFrames;
					end
					movieFrameList{fileNum} = movieFrames;

					% options.frameList = [1:ostruct.movieFrames{fileNum}];
					options.frameList = [1:movieFrames];

					% get the movie
					% thisMovieArray{fileNum} = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList);
					thisMovieArray{fileNum} = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'loadMovieInEqualParts',[numParts numFramesPerPart],'inputDatasetName',options.outputDatasetName,'largeMovieLoad',options.turboreg.largeMovieLoad);
					% thisMovieArray{fileNum} = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList,'loadMovieInEqualParts',[numParts numFramesPerPart]);

				catch err
					thisMovieArray{fileNum} = [];
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
			% inputdlg({'press OK to view a snippet of analyzed movies'},'...',1);
			% Miji;
			% MIJ.start
			manageMiji('startStop','start');
		
			if isempty(thisMovieArray)||all(cellfun(@isempty,thisMovieArray))
				uiwait(ciapkg.overloaded.msgbox('No movies, check that processing ran successfully.','Success','modal'));
			else
				uiwait(ciapkg.overloaded.msgbox('Press OK to view a snippet of analyzed movies','Success','modal'));
			end
		case 'matlab'
			% Do nothing
		otherwise
			% Do nothing
	end

	% ask user for estimate of nPCs and nICs
	for fileNum = 1:nFiles
		try
			disp('+++++++')
			if isempty(ostruct.savedFilePaths{fileNum})
				disp('no movie!')
				% display([num2str(fileNum) '/' num2str(nFiles) ' skipping: ' ostruct.savedFilePaths{fileNum}]);
				continue;
			else
				pathInfo = [num2str(fileNum) '/' num2str(nFiles) ': ' ostruct.savedFilePaths{fileNum}];
				display(pathInfo);
			end

			trueFileNum = ostruct.fileNumList{fileNum};

			switch options.videoPlayer
				case 'matlab'
					thisFilePath = ostruct.savedFilePaths{fileNum};
					[~,thisFileTitle,thisFileTitleExt] = fileparts(thisFilePath);
					thisFileTitle = [thisFileTitle thisFileTitleExt];
					titleStr = sprintf('%d/%d (%d/%d): \n %s \n %s',trueFileNum,length(ostruct.folderList),fileNum,nFiles,ostruct.folderList{trueFileNum},thisFileTitle);

					if fileNum==1
						ciapkg.overloaded.msgbox('Press E in movie GUI to move onto next movie, close this box to continue','Success','modal')
					end
					% playMovie(thisMovie);

					% Play the movie from disk, better preview.
					playMovie(thisFilePath,'extraTitleText',titleStr,'colormapColor','gray');
				case 'imagej'
					% Try with Miji, else use built-in player
					try
						titleStr = sprintf('%d/%d (%d/%d): %s',trueFileNum,length(ostruct.folderList),fileNum,nFiles,ostruct.folderList{trueFileNum});

						% get the list of movies
						movieList = {ostruct.savedFilePaths{fileNum}};

						% options.frameList = [1:ostruct.movieFrames{fileNum}];
						options.frameList = [1:movieFrameList{fileNum}];

						% get the movie
						% thisMovie = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList);
						thisMovie = thisMovieArray{fileNum};

						if isempty(thisMovie)
							continue;
						end

						% playMovie(thisMovie,'fps',120,'extraTitleText',[10 pathInfo]);
						% MIJ.createImage([num2str(fileNum) '/' num2str(length(ostruct.folderList)) ': ' ostruct.folderList{fileNum}],thisMovie, true);
						% [num2str(trueFileNum) '/' num2str(length(ostruct.folderList)) ': ' ostruct.folderList{trueFileNum}]
						
						ciapkg.overloaded.msgbox('Click movie to open next dialog box.','Success','normal')
						MIJ.createImage(titleStr,thisMovie, true);
						if size(thisMovie,1)<300
							% for foobar=1:2; MIJ.run('In [+]'); end
							for foobar=1:1; MIJ.run('In [+]'); end
						end
						for foobar=1:2; MIJ.run('Enhance Contrast','saturated=0.35'); end
						MIJ.run('Start Animation [\]');
						uiwait(ciapkg.overloaded.msgbox('press OK to move onto next movie','Success','modal'));
						% MIJ.run('Close All Without Saving');
						manageMiji('startStop','closeAllWindows');
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
						ciapkg.overloaded.msgbox('Press E in movie GUI to move onto next movie, close this box to continue','Success','modal')
						playMovie(thisMovie);

						% Play the movie from disk, better preview.
						playMovie(ostruct.savedFilePaths{fileNum});
					end
				otherwise
					disp('Wrong video player option, skipping...')
			end

			if options.askForPCICs==1
				% add arbitrary nPCs and nICs to the output
				answer = inputdlg({'nPCs','nICs'},'cell extraction estimates',1);
				if isempty(answer)
					ostruct.nPCs{trueFileNum} = [];
					ostruct.nICs{trueFileNum} = [];
				else
					ostruct.nPCs{trueFileNum} = str2num(answer{1});
					ostruct.nICs{trueFileNum} = str2num(answer{2});
				end
			else
				ostruct.nPCs{trueFileNum} = [];
				ostruct.nICs{trueFileNum} = [];
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	switch options.videoPlayer
		case 'matlab'
			% Do nothing
		case 'imagej'
			% MIJ.exit;
			manageMiji('startStop','exit');
		otherwise
			% Do nothing
	end
end
function inputMovie = localfxn_cropInputMovieSlice(inputMovie,options,ResultsOutOriginal)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% turboreg outputs 0s where movement goes off the screen
	thisMovieMinMask = zeros([size(inputMovie,1) size(inputMovie,2)]);
	options.turboreg.registrationFxn
	switch options.turboreg.registrationFxn
		case 'imtransform'
			reverseStr = '';
			for row=1:size(inputMovie,1)
				thisMovieMinMask(row,:) = logical(max(isnan(squeeze(inputMovie(3,:,:))),[],2,"omitnan"));
				reverseStr = cmdWaitbar(row,size(inputMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
			end
		case 'transfturboreg'
			reverseStr = '';
			for row=1:size(inputMovie,1)
				thisMovieMinMask(row,:) = logical(min(squeeze(inputMovie(row,:,:))~=0,[],2,"omitnan")==0);
				reverseStr = cmdWaitbar(row,size(inputMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
			end
		otherwise
			% do nothing
	end
	topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
	bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
	leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
	rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
	tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
	display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])
	display(['tmpPxToCrop: ' num2str(tmpPxToCrop)])
	if tmpPxToCrop~=0
		if tmpPxToCrop<options.pxToCrop
			pxToCropPreprocess = tmpPxToCrop;
		else
			pxToCropPreprocess = options.pxToCrop;
		end
	else
		% [topVal bottomVal leftVal rightVal]
		% tmpPxToCrop
		disp('Not cropping movie...')
		return
	end

	% gg = cell2mat(cellfun(@(y) cell2mat(cellfun(@(x) max(ceil(abs(x.Translation))),y,'UniformOutput',false)),ResultsOutOriginal{1},'UniformOutput',false));
	% pxToCropAllTmp = ceil(nanmax(sum(abs(cat(1,gg{:})),1)));

	% if pxToCropAllTmp>pxToCropPreprocess
	% 	pxToCropPreprocess = pxToCropAllTmp;
	% end

	topRowCrop = pxToCropPreprocess; % top row
	leftColCrop = pxToCropPreprocess; % left column
	bottomRowCrop = size(inputMovie,1)-pxToCropPreprocess; % bottom row
	rightColCrop = size(inputMovie,2)-pxToCropPreprocess; % right column

	% rowLen = size(inputMovie,1);
	% colLen = size(inputMovie,2);
	% set leftmost columns to NaN
	inputMovie(1:end,1:leftColCrop,:) = NaN;
	% set rightmost columns to NaN
	inputMovie(1:end,rightColCrop:end,:) = NaN;
	% set top rows to NaN
	inputMovie(1:topRowCrop,1:end,:) = NaN;
	% set bottom rows to NaN
	inputMovie(bottomRowCrop:end,1:end,:) = NaN;
end
function [movieList] = localfxn_removeUnsupportedFiles(movieList,options)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% Reject anything not HDF5, TIF, AVI, or ISXD
	movieNo = 1;
	movieTypeList = cell([1 length(movieList)]);
	tmpMovieList = {};
	for iMovie = 1:length(movieList)
		thisMoviePath = movieList{iMovie};
		[options.movieType, supported] = getMovieFileType(thisMoviePath);
		movieTypeList{iMovie} = options.movieType;
		if supported==0
			disp(['+Removing unsupported file from list: ' thisMoviePath]);
		else
			tmpMovieList{movieNo} = movieList{iMovie};
			movieNo = movieNo + 1;
		end
	end
	movieList = tmpMovieList;
end
% function [movieType, supported] = getMovieFileType(thisMoviePath)
% 	% determine how to load movie, don't assume every movie in list is of the same type
% 	supported = 1;
% 	try
% 		[~,~,ext] = fileparts(thisMoviePath);
% 	catch
% 		movieType = '';
% 		supported = 0;
% 		return;
% 	end
% 	% files are assumed to be named correctly (lying does no one any good)
% 	if strcmp(ext,'.h5')||strcmp(ext,'.hdf5')
% 		movieType = 'hdf5';
% 	elseif strcmp(ext,'.tif')||strcmp(ext,'.tiff')
% 		movieType = 'tiff';
% 	elseif strcmp(ext,'.avi')
% 		movieType = 'avi';
% 	elseif strcmp(ext,'.isxd')
% 		movieType = 'isxd';
% 	else
% 		movieType = '';
% 		supported = 0;
% 	end
% end
function localfxn_dispMovieSize(thisMovie)
	j = whos('thisMovie');
	j.bytes=j.bytes*9.53674e-7;
	display(['Movie dims: ' num2str(size(thisMovie)) ' | Movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
end
function localfxn_changeFigName(hFig,titleStr)

	set(hFig,'Name',[ciapkg.pkgName ': start-up GUI'],'NumberTitle','off')
end