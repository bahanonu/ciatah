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
	% TODO
		% Insert NaNs or mean of the movie into dropped frame location, see line 260
		% Allow easy switching between analyzing all files in a folder together and each file in a folder individually
		% FML, make this object oriented...
		% Allow reading in of subset of movie for turboreg analysis, e.g. if we have super large movies

	% remove pre-compiled functions
	% clear FUNCTIONS;
	% load necessary functions and defaults
	% loadBatchFxns();
	%========================
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
	% ====
	% get options
	options = getOptions(options,varargin);
	options
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
	if strcmp(class(options.folderListPath),'char')&~strcmp(options.folderListPath,'manual')
		if ~isempty(regexp(options.folderListPath,'.txt'))
			fid = fopen(options.folderListPath, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			folderList = tmpData{1,1};
			fclose(fid);
		else
			% user just inputs a single directory
			folderList = {options.folderListPath};
		end
		nFiles = length(folderList);
	elseif strcmp(class(options.folderListPath),'cell')
		folderList = options.folderListPath;
		nFiles = length(folderList);
	else
		if strcmp(options.folderListPath,'manual')
			display('Dialog box: select text file that points to analysis folders.')
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
	USAflagStr = ['Made in USA' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10];


	analysisOptionList = {'medianFilter','spatialFilter','stripeRemoval','turboreg','fft_highpass','crop','dfof','dfstd','medianFilter','fixDropFrames','downsampleTime','downsampleSpace','fft_lowpass'};
	analysisOptionListStr = analysisOptionList;
	analysisOptionListStr(strcmp(analysisOptionListStr,'crop')) = {'crop (add NaN border after motion correction)'};
	defaultChoiceList = {'turboreg','crop','dfof','fixDropFrames','downsampleTime'};
	%defaultChoiceIdx = find(cellfun(@(x) sum(strcmp(x,defaultChoiceList)),analysisOptionList));
	defaultChoiceIdx = find(ismember(analysisOptionList,defaultChoiceList));
	try
		ok = 1;
		[figHandle figNo] = openFigure(1776, '');clf;
		[hListbox jListbox jScrollPane jDND] = reorderableListbox('String',analysisOptionListStr,'Units','normalized','Position',[0.5 0 0.5 0.95],'Max',Inf,'Min',0,'Value',defaultChoiceIdx);
		uicontrol('Style','Text','String',['Analysis step selection and ordering' 10 '=======' 10 'We can know only that we know nothing.' 10 'And that is the highest degree of human wisdom.' 10 10 '1: Click items to select.' 10 '2: Drag to re-order analysis.' 10 '3: Click command window and press ENTER to continue.'],'Units','normalized','Position',[0 0.4 0.5 0.60],'BackgroundColor','white','HorizontalAlignment','Left');
		uicontrol('Style','Text','String',USAflagStr,'Units','normalized','Position',[0 0 0.5 0.3],'BackgroundColor','white','HorizontalAlignment','Left','FontName','FixedWidth','FontSize',8,'HorizontalAlignment','left');
		% exitHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[5 85 50 3]/100,'FontSize',9,'string','Click here to finish','callback',@subfxnCloseFig,'HorizontalAlignment','Left');
		pause
		% hListbox.String(hListbox.Value)
		analysisOptionsIdx = hListbox.Value;
		analysisOptionList = hListbox.String;
		analysisOptionList(strcmp(analysisOptionList,'crop (add NaN border after motion correction)')) = {'crop'};

		analysisOptionListStr = analysisOptionList;
		analysisOptionListStr(strcmp(analysisOptionListStr,'crop')) = {'crop (add NaN border after motion correction)'};
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
		display('BACKUP DIALOG')
		[analysisOptionsIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultChoiceIdx,...
			'Name','the red pill...',...
			'PromptString',['select analysis steps to perform. will be analyzed top to bottom, with top first'],...
			'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
		% pause
	end

	if ok~=1
		return
	end
	% defaultSaveList = {'downsampleTime'};
	defaultSaveList = analysisOptionList{analysisOptionsIdx(end)};
	defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));

	try
		[figHandle figNo] = openFigure(1776, '');clf;
		[hListbox jListbox jScrollPane jDND] = reorderableListbox('String',analysisOptionListStr,'Units','normalized','Position',[0.5 0 0.5 0.95],'Max',Inf,'Min',0,'Value',defaultSaveIdx);
		uicontrol('Style','Text','String',['Analysis steps to save' 10 '=======' 10 'Gentlemen, you can not fight in here! This is the War Room.' 10 10 '1: Click analysis steps to save output' 10 '2: Click command window and press ENTER to continue'],'Units','normalized','Position',[0 0.4 0.5 0.60],'BackgroundColor','white','HorizontalAlignment','Left');
		uicontrol('Style','Text','String',USAflagStr,'Units','normalized','Position',[0 0 0.5 0.3],'BackgroundColor','white','HorizontalAlignment','Left','FontName','FixedWidth','FontSize',8,'HorizontalAlignment','left');
		pause
		saveIdx = hListbox.Value;
		% close(1776);
		[figHandle figNo] = openFigure(1776, '');clf;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
		display('BACKUP DIALOG')
		[saveIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultSaveIdx,...
			'Name','Gentlemen, you can not fight in here! This is the War Room.',...
			'PromptString','select at which stages to save a file. if option not selected for analysis, will be ignored',...
			'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
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

	% ========================
	movieSettings = inputdlg({...
			'Select frames to use during preprocessing (e.g. 1:1000). **Leave blank to use all movie frames**:',...
			'Regular expression for raw files (e.g. if raw files all have "concat" in the name, put "concat"): ',...
			'[optional, if using HDF5] Input HDF5 file dataset name (e.g. "/images" for raw Inscopix or "/1" for example data, sans quotes): ',...
			'[optional, if using HDF5] Output HDF5 file dataset name (see above): ',...
			'[optional] (0) Use default preprocessing settings, (1) Save settings or load previously saved settings: '...
		},...
		'Preprocessing settings',[1 100],...
		{...
			num2str(options.frameList),...
			obj.fileFilterRegexpRaw,...
			obj.inputDatasetName,...
			obj.outputDatasetName,...
			num2str(obj.saveLoadPreprocessingSettings)...
		}...
	);
	movieSettings
	options.frameList = str2num(movieSettings{1});
	obj.fileFilterRegexpRaw = movieSettings{2};
	obj.inputDatasetName = movieSettings{3};
	obj.outputDatasetName = movieSettings{4};
	obj.saveLoadPreprocessingSettings = str2num(movieSettings{5});

	if obj.saveLoadPreprocessingSettings==1
		currentDateTimeStr = datestr(now,'yyyymmdd_HHMMSS','local');
		settingsSaveStr = [obj.settingsSavePath filesep currentDateTimeStr '_modelPreprocessMovieFunction_settings.mat'];
		uiwait(msgbox(['Settings saved to obj.preprocessSettings and MAT-file: ' settingsSaveStr]))
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
			[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.25],'Name','How to load previous settings? Press enter if no previous settings.');
			if sel==1
				if isstruct(obj.preprocessSettings)
					previousPreprocessSettings = obj.preprocessSettings;
				end
			else
				% [settingsName,settingsFolderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
				[settingsName,settingsFolderPath,~] = uigetfile('*.*','Select previous preprocessing settings file.','_modelPreprocessMovieFunction_settings.mat');
				previousPreprocessSettings = load([settingsFolderPath settingsName],'preprocessingSettingsAll');
				previousPreprocessSettings = previousPreprocessSettings.preprocessingSettingsAll;
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	else
	end
	[options.turboreg, preprocessingSettingsAll] = obj.getRegistrationSettings('Processing options','inputSettings',previousPreprocessSettings);
	fn_structdisp(options.turboreg)

	if obj.saveLoadPreprocessingSettings==1
		save(settingsSaveStr,'preprocessingSettingsAll','-v7.3');
		obj.preprocessSettings = preprocessingSettingsAll;
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
				[turboRegCoords] = turboregCropSelection(options,folderList);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				warning('User likely did not give calciumImagingAnalysis a proper raw input file regular expression or incorrect HDF5 input dataset name!')
				return;
			end
		end
	end
	ostruct.folderList = {}
	ostruct.savedFilePaths = {};
	ostruct.fileNumList = {};
	% ========================
	manageParallelWorkers('parallel',options.turboreg.useParallel,'setNumCores',options.turboreg.nParallelWorkers);
	% ========================
	folderList
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
					display('please add nICs and PCs')
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
				display('skipping...')
				continue;
			end

			% skip this analysis if files already exist
			if options.checkConcurrentAnalysis==1
				display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
				display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);

				checkSaveString = [thisDir filesep options.concurrentAnalysisFilename];
				if exist(checkSaveString,'file')~=0
					display('SKIPPING ANALYSIS FOR THIS FOLDER')
					continue
				else
					% put a temporary file in the directory to cause other scripts to skip
					display(['saving temporary analysis file: ' checkSaveString])
					AmericaTheBeautiful = 'Man Will Conquer Space Soon!.';
					analysisState = 'running';
					save(checkSaveString,'AmericaTheBeautiful','analysisState');
				end
			end

			% start logging for this file
			display(['cd to: ' obj.defaultObjDir]);
			cd(obj.defaultObjDir);
			currentDateTimeStr = datestr(now,'yyyymmdd_HHMMSS','local');
			mkdir([thisDir filesep 'processing_info'])
			thisProcessingDir = [thisDir filesep 'processing_info'];
			diarySaveStr = [thisDir filesep 'processing_info' filesep currentDateTimeStr '_preprocess.log'];
			diary(diarySaveStr);

			display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
			display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);
			display(['saving diary: ' diarySaveStr])

			% For debugging, display whole options structure
			fn_structdisp(options)
			% diary([obj.logSavePath filesep currentDateTimeStr '_' obj.folderBaseSaveStr{obj.fileNum} '_preprocessing.log']);

			% Get the list of movies
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			[movieList] = removeUnsupportedFiles(movieList,options);

			% get information from directory
			fileInfo = getFileInfo(movieList{1});
			fileInfo
			% base string to save as
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
			thisDirSaveStr = [thisDir filesep fileInfoSaveStr];
			saveStr = '';
			% add the folder to the output structure
			ostruct.folderList{fileNum} = thisDir;

			optionsSaveStr = [thisDir filesep 'processing_info' filesep currentDateTimeStr '_preprocessingOptions' '.mat'];

			if sum(strcmp(analysisOptionList(analysisOptionsIdx),'turboreg'))>0
				turboRegCoordsTmp2 = turboRegCoords{fileNum};
				save(optionsSaveStr, 'options','turboRegCoordsTmp2','analysisOptionList','analysisOptionsIdx');
			else
				save(optionsSaveStr, 'options');
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
				display(['movie ' num2str(movieNo) '/' num2str(nMovies) ': ' ])
				% thisMovieList = movieList{movieNo};
				% 'loadSpecificImgClass','single'
				if options.turboreg.loadMovieInEqualParts~=0&options.processMoviesSeparately~=1
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
				if options.processMoviesSeparately==1
					thisMovie = loadMovieList(movieList{movieNo},'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',0,'loadSpecificImgClass','single');
					% playMovie(thisMovie);
				else
					% options.turboreg.treatMoviesAsContinuousSwitch = 1;
					if isempty(options.frameList)&options.turboreg.loadMoviesFrameByFrame==1
						movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single','getMovieDims',1);
						sum(movieDims.z)
						thisFrameList = 1:sum(movieDims.z);
					else
						thisFrameList = options.frameList;
					end
					thisMovie = loadMovieList(movieList,'convertToDouble',0,'frameList',thisFrameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single');
				end

				if options.processMoviesSeparately==1
					resaveCropFileName = '';
				else
					resaveCropFileName = '';
				end

				[~, ~] = openFigure(4242, '');
					imagesc(squeeze(thisMovie(:,:,1)))
					box off;
					dispStr = [num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' 10 strrep(strrep(thisDir,'\','/'),'_','\_')];
					axis image; colormap gray;
					set(0,'DefaultTextInterpreter','none');
					% suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')],'fontSize',12,'plotregion',0.9,'titleypos',0.95);
					uicontrol('Style','Text','String',dispStr,'Units','normalized','Position',[0.1 0.9 0.8 0.10],'BackgroundColor','white','HorizontalAlignment','Center');
					set(0,'DefaultTextInterpreter','latex');

					% title(dispStr);
				% suptitle([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')]);

				% nOptions = length(analysisOptionsIdx)
				saveStr = '';
				thisMovieMean = [];
				inputMovieF0 = [];
				% to improve memory usage, edit the movie in loops, at least until this is made object oriented.
				for optionIdx = analysisOptionsIdx
					thisMovie = single(thisMovie);
					optionName = analysisOptionList{optionIdx};
					if strcmp(optionName,'turboreg')&~isempty(options.turboreg.filterBeforeRegister)
						saveStr = [saveStr '_' 'spatialFiltBfReg'];
					end
					saveStr = [saveStr '_' optionName];
					display(repmat('*',1,7));
					display([optionName ' movie...']);

					%% ADD BACK DROPPED FRAMES
					% try
					% 	if strcmp(optionName,'downsampleTime')
					% 		subfxnAddDroppedFrames();
					% 	end
					% catch err
					% 	% save the location of the downsampled dfof for PCA-ICA identification
					% 	display(repmat('@',1,7))
					% 	disp(getReport(err,'extended','hyperlinks','on'));
					% 	display(repmat('@',1,7))
					% end
					try
						switch optionName
							case 'fixDropFrames';
								subfxnAddDroppedFrames();
							case 'turboreg'
								subfxnPlotMotionCorrectionMetric('start');

								pxToCropAll = 0;
								ResultsOutOriginal = {};
								for iterationNo = 1:options.turboreg.numTurboregIterations
									disp(repmat('>',[1 21]))
									fprintf('Turboreg iteration %d/%d\n',iterationNo,options.turboreg.numTurboregIterations)
									if strcmp(options.turboreg.filterBeforeRegister,'imagejFFT')
										% Miji;
										manageMiji('startStop','start');
									end
									turboregInputMovie();

									% Save output of translation.
									save([thisProcessingDir filesep currentDateTimeStr '_turboregTranslationOutput.mat'],'ResultsOutOriginal');
									if strcmp(options.turboreg.filterBeforeRegister,'imagejFFT')
										% MIJ.exit;
										manageMiji('startStop','exit');
									end
									% playMovie(thisMovie);
									if options.turboreg.numTurboregIterations>1
										pxToCropTmp = getCropValues();
										pxToCropAll = max([pxToCropAll pxToCropTmp]);
										fprintf('pxToCropAll: %d\n',pxToCropAll);
									end
								end

								% Get the amount of motion and hence amount to crop, directly from turboreg output
								% gg = cellfun(@(z) cell2mat(cellfun(@(y) cell2mat(cellfun(@(x) max(abs(x.Translation)),y,'UniformOutput',false)),z,'UniformOutput',false)),ResultsOutOriginal,'UniformOutput',false);
								gg = cellfun(@(z) cell2mat(cellfun(@(y) cell2mat(cellfun(@(x) max(ceil(abs(x.Translation))),y,'UniformOutput',false)),z,'UniformOutput',false)),ResultsOutOriginal,'UniformOutput',false);
								pxToCropAllTmp = ceil(nanmax(sum(abs(cat(1,gg{:})),1)));
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

									movieSaved2 = writeHDF5Data(tmpCropMovie,resaveCropFileName,'datasetname',options.outputDatasetName,'addInfo',{options.turboreg,analysisOptionStruct,optionsCopy},'addInfoName',{'/movie/processingSettings','/movie/analysisOperations','/movie/modelPreprocessMovieFunctionOptions'},'deflateLevel',options.deflateLevel)
									ostruct.savedFilePaths{end+1} = resaveCropFileName;
									ostruct.fileNumList{end+1} = fileNum;
									clear tmpCropMovie;
								end

								subfxnPlotMotionCorrectionMetric('end');
							case 'crop'
								if exist('pxToCropAll','var')==1&&pxToCropAll~=0
									if pxToCropAll~=0
										if pxToCropAll<options.pxToCrop
											% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
											cropMatrixPreProcess(pxToCropAll);
										else
											% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
											cropMatrixPreProcess(options.pxToCrop);
										end
									end
								else
									cropInputMovie();
								end
							case 'medianFilter'
								medianFilterInputMovie();
							case 'spatialFilter'
								spatialFilterInputMovie();
							case 'stripeRemoval'
								stripeRemovalInputMovie();
							case 'movieProjections'
								movieProjectionsInputMovie();
							case 'fft_highpass'
								fftHighpassInputMovie();
							case 'fft_lowpass'
								fftLowpassInputMovie();
							case 'dfof'
								dfofInputMovie();
							case 'dfstd'
								options.dfofType = 'dfstd';
								dfofInputMovie();
							case 'downsampleTime'
								downsampleTimeInputMovie();
							case 'downsampleSpace'
								downsampleSpaceInputMovie();
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

					% some make single again
					% thisMovie = single(thisMovie);
					% save movie if user selected that option
					% optionIdx
					% saveIdx
					if sum(optionIdx==saveIdx)
						savePathStr = [thisDirSaveStr saveStr '_' num2str(movieNo) '.h5'];
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
						analysisOptionStruct = struct;for optNo=1:length(analysisOptionListTmp);analysisOptionStruct.([char(optNo+'A'-1) '_' analysisOptionListTmp{optNo}])=1;end
						optionsCopy = options;
						optionsCopy.turboreg = [];
						movieSaved = writeHDF5Data(thisMovie,savePathStr,'datasetname',options.outputDatasetName,'addInfo',{options.turboreg,analysisOptionStruct,optionsCopy},'addInfoName',{'/movie/processingSettings','/movie/analysisOperations','/movie/modelPreprocessMovieFunctionOptions'},'deflateLevel',options.deflateLevel)
						% ostruct.savedFilePaths{fileNum} = savePathStr;
						ostruct.savedFilePaths{end+1} = savePathStr;
						ostruct.fileNumList{end+1} = fileNum;
						% ostruct.savedFilePaths{end+1} = savePathStr;
					end
					display(repmat('$',1,7))
					display(['thisMovie: ' class(thisMovie) ' | ' num2str(size(thisMovie))])
					display(repmat('$',1,7))
				end
			end
			movieFrames = size(thisMovie,3);
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
	[ostruct options] = playOutputMovies(ostruct,options)

	toc(startTime)

	cd(startDir)

	% Change input HDF5 dataset name to the new output dataset name
	disp(['Changing calciumImagingAnalysis input HDF5 dataset name "' obj.inputDatasetName '"->"' obj.outputDatasetName '"'])
	obj.inputDatasetName = obj.outputDatasetName;

	function subfxnAddDroppedFrames()
		% TODO: to make this proper, need to verify that the log file names match those of movie files
		display(repmat('-',1,7));

		if ~isempty(options.frameList)
			display('Full movie needs to be loaded to add dropped frames')
			return;
		end

		display('adding in dropped frames if any')
		listLogFiles = getFileList(thisDir,options.logFileRegexp);

		if isempty(listLogFiles)
			display('Add log files to folder in order to add back dropped frames')
			return;
		end

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

		if isempty(droppedFrames)
			display('No dropped frames!')
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
				% 	inputMovieDroppedF0(rowNo,:) = nanmean(squeeze(thisMovie(rowNo,:,framesToUse)),2);
				% 	if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);end
				% end
			otherwise
				% Do nothing
		end
		for rowNo=1:nRows
			inputMovieDroppedF0(rowNo,:) = nanmean(squeeze(thisMovie(rowNo,:,:)),2);
			if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);end
		end
		% movieMean = nanmean(inputMovieTmp(:));
		display([num2str(length(droppedFrames)) ' dropped frames: ' num2str(droppedFrames(:)')])
		display(['pre-corrected movie size: ' num2str(size(thisMovie))])
		thisMovie(:,:,(end+1):(end+length(droppedFrames))) = 0;
		display(['post-corrected movie size: ' num2str(size(thisMovie))])

		switch dropType
			case 'add'
				% vectorized way: get the setdiff(dropped,totalFrames), use this corrected frame indexes and map onto the actual frames in raw movie, shift all frames in original matrix to new position then add in mean to dropped frame indexes
				display('adding in dropped frames to matrix...')
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

	function downsampleTimeInputMovie()
		options.downsampleZ = [];
		options.waitbarOn = 1;
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
			if mod(frame,20)==0&options.waitbarOn==1|frame==downY
				reverseStr = cmdWaitbar(frame,downY,reverseStr,'inputStr','temporally downsampling matrix');
			end
		end
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
		reverseStr = '';
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
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
		drawnow;
		% =====================
	end

	function downsampleSpaceInputMovie()
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
			if mod(frame,20)==0&options.waitbarOn==1|frame==downZ
				reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr',[secondaryDownsampleType 'spatially downsampling matrix']);
			end
		end
		thisMovie = thisMovie(1:downX,1:downY,:);
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);

		if exist('turboRegCoords','var')
			% Adjust crop coordinates if downsampling in space takes place before turboreg
			disp(['Adjusting motion correction crop coordinates for spatial downsampling: ' num2str(turboRegCoords{fileNum}{movieNo})]);
			orderCheck = find(strcmp(analysisOptionList,'downsampleSpace'))<find(strcmp(analysisOptionList,'turboreg'));
			if ~isempty(turboRegCoords{fileNum}{movieNo})&&orderCheck==1
				turboRegCoords{fileNum}{movieNo} = floor(turboRegCoords{fileNum}{movieNo}/options.downsampleFactor);
				% Ensure that the turbo crop coordinates are greater than zero
				turboRegCoords{fileNum}{movieNo} = max(1,turboRegCoords{fileNum}{movieNo});
			end
			disp(['Adjusted motion correction crop coordinates due to spatial downsampling: ' num2str(turboRegCoords{fileNum}{movieNo})]);
		end

		drawnow;
		% =====================
	end

	function dfofInputMovie()
		% dfof must have positive values
		% thisMovieMin = nanmin(thisMovie(:));
		if strcmp(options.turboreg.filterBeforeRegister,'bandpass')
			thisMovie = thisMovie+1;
		end

		% adjust for problems with movies that have negative pixel values before dfof
		minMovie = min(thisMovie(:));
		if minMovie<0
			thisMovie = thisMovie + 1.1*abs(minMovie);
		end
		% leave mean at 1, goes to zero when doing pca ica
		% thisMovie = dfofMovie(thisMovie,'dfofType',options.dfofType);
		% figure(1970+fileNum)
		% 	subplot(2,1,1)
		% 	plot(squeeze(nanmean(nanmean(thisMovie,1),2)))
		% 	% title(['mean | ' ]);
		% 	ylabel('mean');box off;
		% 	subplot(2,1,2)
		% 	plot(squeeze(nanvar(nanvar(thisMovie,[],1),[],2)))
		% 	% title('variance');
		% 	ylabel('variance');xlabel('frame'); box off;
		% 	suptitle(thisDirSaveStr)
		% =====================
		% get the movie F0
		% thisMovie = single(thisMovie);
		display('getting F0...')
		inputMovieF0 = zeros([size(thisMovie,1) size(thisMovie,2)]);
		if strcmp(options.dfofType,'dfstd')
			inputMovieStd = zeros([size(thisMovie,1) size(thisMovie,2)]);
			progressStr = 'calculating mean and std...';
		else
			progressStr = 'calculating mean...';
		end
		nRows = size(thisMovie,1);
		reverseStr = '';
		for rowNo=1:nRows
			% inputMovieF0 = nanmean(inputMovie,3);
			rowFrame = single(squeeze(thisMovie(rowNo,:,:)));
			inputMovieF0(rowNo,:) = nanmean(rowFrame,2);
			if strcmp(options.dfofType,'dfstd')
				inputMovieStd(rowNo,:) = nanstd(rowFrame,[],2);
			else
			end
			if mod(rowNo,5)==0;reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr',progressStr,'waitbarOn',1,'displayEvery',5);end
		end

		% Save out F0 in case need later
		savePathStr = [thisDirSaveStr '_inputMovieF0' '.h5'];
		movieSaved = writeHDF5Data(inputMovieF0,savePathStr,'deflateLevel',options.deflateLevel,'datasetname',options.outputDatasetName);

		thisMovieMean = nanmean(inputMovieF0(:));
		% bsxfun for fast matrix divide
		switch options.dfofType
			case 'divide'
				display('F(t)/F0...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
			case 'dfof'
				display('F(t)/F0 - 1...')
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
				display('(F(t)-F0)/std...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				% dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
				% dfofMatrix = bsxfun(@ldivide,inputMovieStd,dfofMatrix);

				everseStr = '';
				nFrames = size(thisMovie,3);
				for frameNo = 1:nFrames
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)-inputMovieF0;
					thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)./inputMovieStd;
					if mod(rowNo,50)==0;reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','DFOF','waitbarOn',1,'displayEvery',50);end
				end
				% thisMovie = thisMovie-1;
			case 'minus'
				display('F(t)-F0...')
				% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
				thisMovie = bsxfun(@minus,thisMovie,inputMovieF0);
			otherwise
				% return;
		end
		% =====================
	end
	function subfxnPlotMotionCorrectionMetric(motionState)
		try
			colorList = hsv(length(obj.inputFolders));

			meanG = mean(thisMovie,3);
			corrMetric = NaN([1 size(thisMovie,3)]);
			corrMetric2 = NaN([1 size(thisMovie,3)]);
			cc = turboRegCoords{fileNum}{movieNo};
			meanG_cc = meanG(cc(2):cc(4),cc(1):cc(3));
			for i =1:size(thisMovie,3);
				thisFrame_cc = thisMovie(cc(2):cc(4),cc(1):cc(3),i);
				corrMetric(i) = corr2(meanG_cc,thisFrame_cc);
				corrMetric2(i) = corr(meanG_cc(:),thisFrame_cc(:),'Type','Spearman');
			end

			openFigure(1865);
			% ax1 = [];
			% ax1(end+1) = subplot(1,2,1)
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
				suptitle('Correlation of all frames to movie mean')
				legendStr = cellfun(@(x) {strcat('===',x,sprintf('===\nPre-motion correction corr2')),'Post-motion correction corr2'},obj.folderBaseDisplayStr,'UniformOutput',false);
				legend([legendStr{:}])

			openFigure(1866);
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

			% set(ax1,'Nextplot','add')
			suptitle('Correlation of all frames to movie mean')

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
	function turboregInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['registering sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
		% thisMovie = single(thisMovie);
		% get reference frame before subsetting, so won't change
		thisMovieRefFrame = squeeze(thisMovie(:,:,options.refCropFrame));
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
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			display(repmat('$',1,7))
			%run with altered defaults
			% ioptions.Levels = 2;
			% ioptions.Lastlevels = 1;
			% ioptions.complementMatrix = 0;
			% ioptions.minGain=0.0;
			% ioptions.SmoothX = 80;
			% ioptions.SmoothY = 80;
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
				options.turboreg.saveFilterBeforeRegister = [thisDirSaveStr saveStr '_lowpass.h5']
			end
			ioptions.saveNormalizeBeforeRegister = options.turboreg.saveFilterBeforeRegister;
			%
			ioptions.cropCoords = turboRegCoords{fileNum}{movieNo};
			ioptions.closeMatlabPool = 0;
			ioptions.refFrame = options.refCropFrame;
			ioptions.refFrameMatrix = thisMovieRefFrame;
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
			j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
			% [thisMovie(:,:,movieSubset), ResultsOutOriginal{thisSet}] = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);


			% Register without spatial filtering if requested by user
			if options.turboreg.saveBeforeFilterRegister==1&&iterationNo==options.turboreg.numTurboregIterations
				% Motion correct with filtering applied if requested, save for later
				[tmpMovieWithFilter, ResultsOutOriginal{iterationNo}{thisSet}] = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);

				tmpMovieNoFilter = thisMovie(:,:,movieSubset);
				ioptions.precomputedRegistrationCooordsFullMovie = ResultsOutOriginal{iterationNo}{thisSet};
				[tmpMovieNoFilter, ~] = turboregMovie(tmpMovieNoFilter,'options',ioptions);

				% for iterationNo2 = 1:options.turboreg.numTurboregIterations
				% 	ioptions.precomputedRegistrationCooordsFullMovie = ResultsOutOriginal{iterationNo2}{thisSet};
				% 	[tmpMovieNoFilter, ~] = turboregMovie(tmpMovieNoFilter,'options',ioptions);
				% end
				% Crop movie
				tmpMovieNoFilter = cropInputMovieSlice(tmpMovieNoFilter,options,ResultsOutOriginal);

				% Add filtered movie to overall registered subset
				thisMovie(:,:,movieSubset) = tmpMovieWithFilter;

				savePathStrTmp = [thisDirSaveStr saveStr '_noSpatialFilter_' num2str(movieNo) '.h5'];
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
	function tmpPxToCrop = getCropValues()
		% Get values to use to add border and eliminate edge movement due to motion correction
		thisMovieMinMask = zeros([size(thisMovie,1) size(thisMovie,2)]);
		options.turboreg.registrationFxn
		switch options.turboreg.registrationFxn
			case 'imtransform'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(nanmax(isnan(squeeze(thisMovie(3,:,:))),[],2));
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			case 'transfturboreg'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:))~=0,[],2)==0);
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
	function cropInputMovie()
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
					thisMovieMinMask(row,:) = logical(nanmax(isnan(squeeze(thisMovie(3,:,:))),[],2));
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			case 'transfturboreg'
				% thisMovieMinMask = logical(nanmin(thisMovie~=0,[],3)==0);
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:))~=0,[],2)==0);
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			otherwise
				% do nothing
		end
		% [figHandle figNo] = openFigure(79854+fileNum, '');
		% imagesc(thisMovieMinMask); colormap gray;
		% suptitle(thisDirSaveStr);
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
				cropMatrixPreProcess(tmpPxToCrop);
			else
				% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
				cropMatrixPreProcess(options.pxToCrop);
			end
		end
		% % convert to single (32-bit floating point)
		% % thisMovie = single(thisMovie);
		% saveStr = [saveStr '_crop'];
	end
	function cropMatrixPreProcess(pxToCropPreprocess)
  %   	if size(thisMovie,2)>=size(thisMovie,1)
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

		rowLen = size(thisMovie,1);
		colLen = size(thisMovie,2);
		% set leftmost columns to NaN
		thisMovie(1:end,1:leftColCrop,:) = NaN;
		% set rightmost columns to NaN
		thisMovie(1:end,rightColCrop:end,:) = NaN;
		% set top rows to NaN
		thisMovie(1:topRowCrop,1:end,:) = NaN;
		% set bottom rows to NaN
		thisMovie(bottomRowCrop:end,1:end,:) = NaN;
	end
	function medianFilterInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['registering sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
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
			j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
			thisMovie(:,:,movieSubset) = normalizeMovie(thisMovie(:,:,movieSubset),'normalizationType','medianFilter','medianFilterNeighborhoodSize',options.turboreg.medianFilterSize);
			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function spatialFilterInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['filtering sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
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
			j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);

			% thisMovie(:,:,movieSubset) = normalizeMovie(thisMovie(:,:,movieSubset),'normalizationType','medianFilter','medianFilterNeighborhoodSize',options.turboreg.medianFilterSize);

			% ioptions.normalizeType = options.turboreg.normalizeType;
			% ioptions.registrationFxn = options.turboreg.registrationFxn;
			% ioptions.freqLow = options.turboreg.filterBeforeRegFreqLow;
			% ioptions.freqHigh = options.turboreg.filterBeforeRegFreqHigh;

			switch options.turboreg.filterBeforeRegister
				case 'imagejFFT'
					imagefFftOnInputMovie('inputMovie');
				case 'divideByLowpass'
					display('dividing movie by lowpass...')
					thisMovie(:,:,movieSubset) = normalizeMovie(single(thisMovie(:,:,movieSubset)),'normalizationType','lowpassFFTDivisive','freqLow',options.turboreg.filterBeforeRegFreqLow,'freqHigh',options.turboreg.filterBeforeRegFreqHigh,'waitbarOn',1,'bandpassMask','gaussian');
				case 'bandpass'
					display('bandpass filtering...')
					[thisMovie(:,:,movieSubset)] = normalizeMovie(single(thisMovie(:,:,movieSubset)),'normalizationType','fft','freqLow',options.turboreg.filterBeforeRegFreqLow,'freqHigh',options.turboreg.filterBeforeRegFreqHigh,'bandpassType','bandpass','showImages',0,'bandpassMask','gaussian');
				otherwise
					% do nothing
			end

			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function stripeRemovalInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		display(['Stripe removal sublists: ' num2str(subsetList)]);
		% convert movie to single for turboreg
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
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
			j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);

			thisMovie(:,:,movieSubset) = removeStripsFromMovie(single(thisMovie(:,:,movieSubset)),'stripOrientation',options.turboreg.stripOrientationRemove,'meanFilterSize',options.turboreg.stripSize,'freqLowExclude',options.turboreg.stripfreqLowExclude,'bandpassType',stripfreqBandpassType,'freqHighExclude',stripfreqHighExclude,'waitbarOn',1);

			toc(subsetStartTime)
		end
		% thisMovie = normalizeMovie(thisMovie,'normalizationType','medianFilter');
	end
	function movieProjectionsInputMovie()

		% get the max projection


		% get the mean projection
	end
	function fftHighpassInputMovie()
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
	function fftLowpassInputMovie()
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
			savePathStr = [thisDirSaveStr saveStr '.h5'];
			movieSaved = writeHDF5Data(thisMovieLowpass,savePathStr,'deflateLevel',options.deflateLevel,'datasetname',options.outputDatasetName);
		end
		% prevent lowpass file saving overwrite
		optionIdx = -1;
		clear thisMovieLowpass;
	end
end

function [turboRegCoords] = turboregCropSelection(options,folderList)
	% Biafra Ahanonu
	% 2013.11.10 [19:28:53]
	usrIdxChoiceStr = {'NO | do not duplicate area coords across multiple folders','YES | duplicate area coords across multiple folders','YES | duplicate area coords if subject (animal) the same','YES | duplicate area coords across ALL folders'};
	scnsize = get(0,'ScreenSize');
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','Motion correction area coordinates (area used to get registration translation coordinates)');
	% : use over multiple folders?
	usrIdxChoiceList = {-1,0,-2,0};
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
		[movieList] = removeUnsupportedFiles(movieList,options);
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
					[movieList] = removeUnsupportedFiles(movieList,options);
					cellfun(@disp,movieList);
					inputFilePath = movieList{movieNo};
					if nMovies==1
						inputFilePath = movieList;
					else
						inputFilePath = movieList{movieNo};
					end

					thisFrame = loadMovieList(inputFilePath,'convertToDouble',0,'frameList',options.refCropFrame,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',options.turboreg.treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single');

					[figHandle figNo] = openFigure(9, '');
					titleStr = ['Click to drag-n-draw region.' 10 'Double-click region to continue.' 10 'Note: Only cropping for motion correction, original movie dimensions retained after registration.'];
					subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title(titleStr)
					set(0,'DefaultTextInterpreter','none');
					% suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')],'fontSize',12,'plotregion',0.9,'titleypos',0.95);
					uicontrol('Style','Text','String',[num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' strrep(thisDir,'\','/')],'Units','normalized','Position',[0.1 0.9 0.8 0.10],'BackgroundColor','white','HorizontalAlignment','Center');
					set(0,'DefaultTextInterpreter','latex');
					% subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('Click to drag-n-draw region. Double-click region to continue.')

					% Use ginput to select corner points of a rectangular
					% region by pointing and clicking the subject twice
					fileInfo = getFileInfo(thisDir);
					switch applyPreviousTurboreg
						case -1 %'NO | do not duplicate coords across multiple folders'
							% p = round(getrect);
							h = subfxn_getImRect(titleStr);
							p = round(wait(h));
						case 0 %'YES | duplicate coords across multiple folders'
							% p = round(getrect);
							h = subfxn_getImRect(titleStr);
							p = round(wait(h));
							coordsStructure.(fileInfo.subject) = p;
						case -2 %'YES | duplicate coords if subject the same'
							if ~any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
								% p = round(getrect);
								h = subfxn_getImRect(titleStr);
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
					[figHandle figNo] = openFigure(9, '');
					subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;

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
						coordsStructure
					end
				case 'coordinates'
					% gets the coordinates of the turboreg from the filelist
					display('not implemented')
				otherwise
					% if no option selected, uses the entire FOV for each image
					display('not implemented')
					turboRegCoords{fileNum}{movieNo}=[];
			end
		end
	end
end
function h = subfxn_getImRect(titleStr)
	h = imrect(gca);
	addNewPositionCallback(h,@(p) title([titleStr 10 mat2str(p,3)]));
	fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
	setPositionConstraintFcn(h,fcn);
end
% function [ostruct options] = getPcaIcaParams(ostruct,options)
function [ostruct options] = playOutputMovies(ostruct,options)
	nFiles = length(ostruct.savedFilePaths);
	maxFrames = 500;
	movieFrameList = {};
	numFramesPerPart = 50;
	numParts = 10;
	display('pre-allocating movies to display...')
	for fileNum=1:nFiles
		try
			display('+++++++')
			if isempty(ostruct.savedFilePaths{fileNum})
				display('no movie!')
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
			thisMovieArray{fileNum} = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'loadMovieInEqualParts',[numParts numFramesPerPart],'inputDatasetName',options.outputDatasetName);
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
	uiwait(msgbox('press OK to view a snippet of analyzed movies','Success','modal'));
	% ask user for estimate of nPCs and nICs
	for fileNum = 1:nFiles
		try
			display('+++++++')
			if isempty(ostruct.savedFilePaths{fileNum})
				display('no movie!')
				% display([num2str(fileNum) '/' num2str(nFiles) ' skipping: ' ostruct.savedFilePaths{fileNum}]);
				continue;
			else
				pathInfo = [num2str(fileNum) '/' num2str(nFiles) ': ' ostruct.savedFilePaths{fileNum}];
				display(pathInfo);
			end

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

			trueFileNum = ostruct.fileNumList{fileNum};

			% Try with Miji, else use built-in player
			try
				% playMovie(thisMovie,'fps',120,'extraTitleText',[10 pathInfo]);
				% MIJ.createImage([num2str(fileNum) '/' num2str(length(ostruct.folderList)) ': ' ostruct.folderList{fileNum}],thisMovie, true);
				% [num2str(trueFileNum) '/' num2str(length(ostruct.folderList)) ': ' ostruct.folderList{trueFileNum}]
				titleStr = sprintf('%d/%d (%d/%d): %s',trueFileNum,length(ostruct.folderList),fileNum,nFiles,ostruct.folderList{trueFileNum});
				msgbox('Click movie to open next dialog box.','Success','normal')
				MIJ.createImage(titleStr,thisMovie, true);
				if size(thisMovie,1)<300
					% for foobar=1:2; MIJ.run('In [+]'); end
					for foobar=1:1; MIJ.run('In [+]'); end
				end
				for foobar=1:2; MIJ.run('Enhance Contrast','saturated=0.35'); end
				MIJ.run('Start Animation [\]');
				uiwait(msgbox('press OK to move onto next movie','Success','modal'));
				MIJ.run('Close All Without Saving');
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				msgbox('Press E in movie GUI to move onto next movie, close this box to continue','Success','modal')
				playMovie(thisMovie);
			end

			if options.askForPCICs==1
				% add arbitrary nPCs and nICs to the output
				answer = inputdlg({'nPCs','nICs'},'cell extraction estimates',1)
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
	% MIJ.exit;
	manageMiji('startStop','exit');
end
function inputMovie = cropInputMovieSlice(inputMovie,options,ResultsOutOriginal)
	% turboreg outputs 0s where movement goes off the screen
	thisMovieMinMask = zeros([size(inputMovie,1) size(inputMovie,2)]);
	options.turboreg.registrationFxn
	switch options.turboreg.registrationFxn
		case 'imtransform'
			reverseStr = '';
			for row=1:size(inputMovie,1)
				thisMovieMinMask(row,:) = logical(nanmax(isnan(squeeze(inputMovie(3,:,:))),[],2));
				reverseStr = cmdWaitbar(row,size(inputMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
			end
		case 'transfturboreg'
			reverseStr = '';
			for row=1:size(inputMovie,1)
				thisMovieMinMask(row,:) = logical(nanmin(squeeze(inputMovie(row,:,:))~=0,[],2)==0);
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

	rowLen = size(inputMovie,1);
	colLen = size(inputMovie,2);
	% set leftmost columns to NaN
	inputMovie(1:end,1:leftColCrop,:) = NaN;
	% set rightmost columns to NaN
	inputMovie(1:end,rightColCrop:end,:) = NaN;
	% set top rows to NaN
	inputMovie(1:topRowCrop,1:end,:) = NaN;
	% set bottom rows to NaN
	inputMovie(bottomRowCrop:end,1:end,:) = NaN;
end
function [movieList] = removeUnsupportedFiles(movieList,options)
	% Reject anything not HDF5, TIF, AVI, or ISXD
	movieNo = 1;
	movieTypeList = cell([1 length(movieList)]);
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
function [movieType, supported] = getMovieFileType(thisMoviePath)
	% determine how to load movie, don't assume every movie in list is of the same type
	supported = 1;
	try
		[pathstr,name,ext] = fileparts(thisMoviePath);
	catch
		movieType = '';
		supported = 0;
		return;
	end
	% files are assumed to be named correctly (lying does no one any good)
	if strcmp(ext,'.h5')||strcmp(ext,'.hdf5')
		movieType = 'hdf5';
	elseif strcmp(ext,'.tif')||strcmp(ext,'.tiff')
		movieType = 'tiff';
	elseif strcmp(ext,'.avi')
		movieType = 'avi';
	elseif strcmp(ext,'.isxd')
		movieType = 'isxd';
	else
		movieType = '';
		supported = 0;
	end
end