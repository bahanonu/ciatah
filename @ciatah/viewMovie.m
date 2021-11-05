function obj = viewMovie(obj)
	% View movies in folder using MATLAB or ImageJ video player GUIs.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.08.30 [12:59:44] - Added fallback to playMovie in case of Miji error
		% 2019.10.09 [17:58:22] - Make view movie multi-column
		% 2020.10.25 [21:05:21] - Added support for viewing movies from disk.
		% 2021.02.24 [09:04:24] - Fix treatMoviesAsContinuous=0 + playMovieFromDisk=1 issue.
		% 2021.06.18 [21:41:07] - added modelVarsFromFilesCheck() to check and load signals if user hasn't already.
		% 2021.06.20 [‏‎00:14:59] - Added support for simple and advanced settings.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	% =====================
	% fileFilterRegexp = obj.fileFilterRegexp;
	FRAMES_PER_SECOND = obj.FRAMES_PER_SECOND;
	% DOWNSAMPLE_FACTOR = obj.DOWNSAMPLE_FACTOR;
	options.videoPlayer = [];
	options.settingsType = '';
	% =====================
	currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
	if isempty(options.videoPlayer)
		usrIdxChoiceStr = {'matlab','imagej'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which video player to use?');
		if ok==0
			return;
		end
		options.videoPlayer = usrIdxChoiceStr{sel};
	end
	if strcmp(options.videoPlayer,'imagej')
		modelAddOutsideDependencies('miji');
	end

	if isempty(options.settingsType)
		usrIdxChoiceStr = {'Simple settings','Advanced settings'};
		usrIdxChoiceSetting = {'simple','advanced'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Which settings to load?');
		if ok==0
			return;
		end
		options.settingsType = usrIdxChoiceSetting{sel};
	end

	% Load folders to be analyzed.
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	% Check whether preprocessed movie is there by default in 1st folder. Else load standard regexp for raw movie.
	defaultFileFilterRegexp = obj.fileFilterRegexp;
	movieList = getFileList(obj.inputFolders{fileIdxArray(1)}, defaultFileFilterRegexp);
	processedMovieFlag = 1;
	if isempty(movieList)
		fprintf('No files with default obj.fileFilterRegexp (%s), using obj.fileFilterRegexpRaw (%s).\n',obj.fileFilterRegexp,obj.fileFilterRegexpRaw);
		processedMovieFlag = 0;
		defaultFileFilterRegexp = obj.fileFilterRegexpRaw;
	end
	% =====================
	if iscell(obj.videoDir)
		videoDir = strjoin(obj.videoDir,',');
	else
		videoDir = obj.videoDir;
	end
	% =====================
	AddOpts.Resize='on';
	AddOpts.WindowStyle='normal';
	AddOpts.Interpreter='tex';

	options.settingsType

	settingStr = {...
			'char: Imaging movie regexp (IMPORTANT, make sure matches the movie you want to view):',...
			'start:end frames (leave blank for all)',...
			'behavior:movie sample rate (downsample factor): ',...
			'Play movie from disk (1 = yes, 0 = no):',...
			'video folder(s), separate multiple folders by a comma:',...
			'side-by-side save folder:',...
			'analyze specific folder (leave blank if no) ("same" = input folder)',...
			'show behavior video (0 = no, 1 = yes)',...
			'create movie montages (0 = no, 1 = yes)',...
			'create signal-based movie montages (0 = no, 1 = yes)',...
			'ask for movie list (0 = no, 1 = yes)'...
			'save movie? (0 = no, 1 = yes)',...
			'raw imaging movie regexp (leave blank if don''t want raw movie):',...
			'recursively search video directory (0 = no, 1 = yes)',...
			'add text labels to movie (0 = no, 1 = yes):',...
			'normalize movies (0 = no, 1 = yes):',...
			'preload primary movies (0 = no, 1 = yes):',...
			'load movie in equal parts (0 = disable feature):',...
			'downsample factor for movie  (1 = no downsample):',...
			'video regular expression:',...
			'rotate second video (0 = no, 1 = yes)',...
			'treat movie as continuous (0 = no, 1 = yes):',...
			'HDF5 dataset name',...
			'downsample factor for movie viewing (1 = no downsample):',...
			'Create cell extraction outlines on movie (0 = no, 1 = yes, 2 = yes, all outputs):',...
			'Cell extraction outlines threshold (float btwn 0 and 1):',...
			};
	settingDefaults = {...
			defaultFileFilterRegexp,...
			'1:500',...
			num2str(obj.DOWNSAMPLE_FACTOR),...
			'0',...
			videoDir,....
			obj.videoSaveDir,...
			'',...
			'0',...
			'0',...
			'0',...
			'0',...
			'0',...
			'',...
			'0',...
			'0',...
			'0',...
			'0',...
			'0',...
			'1',...
			obj.behaviorVideoRegexp,...
			'0',...
			'0',...
			obj.inputDatasetName...
			'1',...
			'0',...
			'0.4',...
		};

	switch options.settingsType
		case 'simple'
			settingsKeepIdx = [1 2 3 4 13 17 23];
			nCols = 1;
		otherwise
			settingsKeepIdx = 1:length(settingStr);
			nCols = 2;
			% Do nothing
	end

	% movieSettings = inputdlg({...
	movieSettings = inputdlgcol(settingStr(settingsKeepIdx),...
		'view movie settings',[1 100],...
		settingDefaults(settingsKeepIdx),...
		AddOpts,nCols);

	switch options.settingsType
		case 'simple'
			% Add new settings to default
			settingStr{settingsKeepIdx};
			sN = 1;
			for ii = 1:length(settingsKeepIdx)
				settingDefaults{settingsKeepIdx(ii)} = movieSettings{sN};
				sN=sN+1;
			end
			movieSettings = settingDefaults;
		otherwise
			% Do nothing
	end
	
	% concat the two
	% movieSettings = cat(1,movieSettings,movieSettings2);
	% obj.fileFilterRegexp = movieSettings{3};
	% fileFilterRegexp = obj.fileFilterRegexp;
	sN = 1;
	fileFilterRegexp = movieSettings{sN}; sN=sN+1;
	if processedMovieFlag==1
		obj.fileFilterRegexp = fileFilterRegexp;
	end
	frameList = str2num(movieSettings{sN}); sN=sN+1;
	DOWNSAMPLE_FACTOR = str2num(movieSettings{sN}); sN=sN+1;
	playMovieFromDisk = str2num(movieSettings{sN}); sN=sN+1;
	% eval(['{''',movieSettings{sN},'''}'])
	obj.videoDir = strsplit(movieSettings{sN},','); videoDir = obj.videoDir; sN=sN+1;
	obj.videoSaveDir = movieSettings{sN}; videoSaveDir = obj.videoSaveDir; sN=sN+1;
	analyzeSpecificFolder = movieSettings{sN}; sN=sN+1;
	showBehaviorVideo = str2num(movieSettings{sN}); sN=sN+1;
	createMontageVideosSwitch = str2num(movieSettings{sN}); sN=sN+1;
	createSignalBasedVideosSwitch = str2num(movieSettings{sN}); sN=sN+1;
	askForMovieList = str2num(movieSettings{sN}); sN=sN+1;
	saveCopyOfMovie = str2num(movieSettings{sN}); sN=sN+1;
	rawFileFilterRegexp = movieSettings{sN}; sN=sN+1;
	recursiveVideoSearch = str2num(movieSettings{sN}); sN=sN+1;
	viewOptions.useIdentifyText = str2num(movieSettings{sN}); sN=sN+1;
	normalizeMovieSwitch = str2num(movieSettings{sN}); sN=sN+1;
	preLoadPrimaryMovie = str2num(movieSettings{sN}); sN=sN+1;
	loadMovieInEqualParts = str2num(movieSettings{sN}); sN=sN+1;
	downsampleFactorSave = str2num(movieSettings{sN}); sN=sN+1;
	videoFilterRegexp = movieSettings{sN}; sN=sN+1;
		obj.behaviorVideoRegexp = videoFilterRegexp;
	rotateVideoSwitch = str2num(movieSettings{sN}); sN=sN+1;
	treatMoviesAsContinuous = str2num(movieSettings{sN}); sN=sN+1;
	obj.inputDatasetName = movieSettings{sN}; sN=sN+1;
	downsampleFactorView = str2num(movieSettings{sN}); sN=sN+1;
	createImageOutlineOnMovieSwitch = str2num(movieSettings{sN}); sN=sN+1;
	thresholdOutline = str2num(movieSettings{sN}); sN=sN+1;

	noCrop = 0;
	% =====================
	% FINISH INCORPORATING!!
	videoTrialRegExp = '';
	videoTrialRegExpIdx = 1;
	if showBehaviorVideo==1
		videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','yymmdd_mNNN_assayNN','subject_assay','yymmdd_mNNN','videoFilterRegexp'};
		scnsize = get(0,'ScreenSize');
		[videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
		local_getVideoRegexp();
		% videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','subject_assay'};
		% scnsize = get(0,'ScreenSize');
		% [videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
	else

	end
	% % =====================
	if strcmp(options.videoPlayer,'imagej')&saveCopyOfMovie==0
		% Miji
;		% try
		% 	MIJ.exit;
		% catch
		% 	clear MIJ miji Miji mij;
		% 	resetMiji();
		% 	Miji;
		% end
		% MIJ.start;
		manageMiji('startStop','start');
	end
	if ~isempty(analyzeSpecificFolder)
		nFilesToAnalyze = 1;
	end
	primaryMoviePreloaded = {};
	display(repmat('=',1,21))
	display(repmat('=',1,21))
	display('PRE-LOADING MOVIES')
	if preLoadPrimaryMovie == 1
		for thisFileNumIdx = 1:nFilesToAnalyze
			try
				fileNum = fileIdxArray(thisFileNumIdx);
				obj.fileNum = fileNum;
				display(repmat('=',1,21))
				display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.fileIDNameArray{obj.fileNum}]);

				if isempty(analyzeSpecificFolder)
					movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				else
					analyzeSpecificFolder
					fileFilterRegexp
					movieList = getFileList(analyzeSpecificFolder, fileFilterRegexp);
				end
				if ischar(movieList)
					display(movieList)
				elseif iscell(movieList)
					cellfun(@display,movieList);
				end
				movieMontageIdx = 1:length(movieList);
				nMovies = length(movieMontageIdx);
				if treatMoviesAsContinuous==1
					movieMontageIdx = 1;
				end
				for movieNo = 1:length(movieMontageIdx)
					display(['movie ' num2str(movieMontageIdx(movieNo)) '/' num2str(nMovies) ': ' movieList{movieMontageIdx(movieNo)}])
					% =================================================
					[frameListTmp] = getProperFrameList('primary');
					if treatMoviesAsContinuous==1
						movieListTmp2 = movieList;
						% if iscell(movieList)
						% else
						% 	movieListTmp2 = {movieList};						
						% end
					else
						movieListTmp2 = movieList{movieMontageIdx(movieNo)};
					end
					[primaryMoviePreloaded{thisFileNumIdx}{movieNo}] = loadMovieList(movieListTmp2,'convertToDouble',0,'frameList',frameListTmp(:),'treatMoviesAsContinuous',treatMoviesAsContinuous,'inputDatasetName',obj.inputDatasetName);

					if downsampleFactorView~=1
						[primaryMoviePreloaded{thisFileNumIdx}{movieNo}] = downsampleMovie(primaryMoviePreloaded{thisFileNumIdx}{movieNo},'downsampleDimension','space','downsampleFactor',downsampleFactorView);
					end

					% [primaryMoviePreloaded{thisFileNumIdx}{movieNo}] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameListTmp(:));
				end
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
		display(repmat('=',1,21))
		display(repmat('=',1,21))
	end

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			% subject = obj.subjectNum{obj.fileNum};
			% assay = obj.assay{obj.fileNum};
			% =====================
			% frameList
			if isempty(analyzeSpecificFolder)
				movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			else
				analyzeSpecificFolder
				fileFilterRegexp
				movieList = getFileList(analyzeSpecificFolder, fileFilterRegexp);
			end
			if isempty(movieList)
				display('No movie files found! Please check "Imaging movie regexp:" option that regular expression matches existing movie in the repository.')
				if strcmp(options.videoPlayer,'imagej')&saveCopyOfMovie==0
					% MIJ.exit;
					manageMiji('startStop','exit');
				end
				% return;
				continue;
			end
			if ischar(movieList)
				display(movieList)
			elseif iscell(movieList)
				cellfun(@display,movieList);
			end
			if askForMovieList == 1;
				scnsize = get(0,'ScreenSize');
				[movieMontageIdx, ok] = listdlg('ListString',movieList,'ListSize',[scnsize(3)*0.7 scnsize(4)*0.25],'Name','which movies to view?');
			else
				movieMontageIdx = 1:length(movieList);
			end
			if treatMoviesAsContinuous==1
				movieMontageIdx = 1;
			end
			nMovies = length(movieMontageIdx);

			for movieNo = 1:length(movieMontageIdx)
				display(['movie ' num2str(movieMontageIdx(movieNo)) '/' num2str(nMovies) ': ' movieList{movieMontageIdx(movieNo)}])
				% =================================================
				[frameListTmp] = getProperFrameList('primary');
				if treatMoviesAsContinuous==1
					if iscell(movieList)
						movieListTmp2 = movieList;
					else
						movieListTmp2 = {movieList};						
					end
				else
					movieListTmp2 = movieList{movieMontageIdx(movieNo)};
				end

				if playMovieFromDisk==1
					disp('dddd')
					movieListTmp2
					if ~iscell(movieListTmp2)
						movieListTmp2 = {movieListTmp2};
					end
					try
						[exitSignal, movieStruct] = playMovie(movieListTmp2{1},'extraTitleText','');
					catch err
						display(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
					end
					% fileIDNameArray
					movieDecision = questdlg('Is the movie good?', ...
						'Movie decision', ...
						'yes','motion','other','yes');
					continue;
				end

				if preLoadPrimaryMovie == 1
					primaryMovie = primaryMoviePreloaded{thisFileNumIdx}{movieNo};
				else
					[primaryMovie] = loadMovieList(movieListTmp2,'convertToDouble',0,'frameList',frameListTmp(:),'treatMoviesAsContinuous',treatMoviesAsContinuous,'inputDatasetName',obj.inputDatasetName);

					if downsampleFactorView~=1
						[primaryMovie] = downsampleMovie(primaryMovie,'downsampleDimension','space','downsampleFactor',downsampleFactorView);
					end
				end
				identifyingText = {'dfof'};
				% treatMoviesAsContinuous
				switch fileFilterRegexp
					case 'concat'
						primaryMovie = single(primaryMovie);
					otherwise
						% body
				end
				if normalizeMovieSwitch==1
					[primaryMovie] = normalizeVector(primaryMovie,'normRange','zeroToOne');
				end
				% primaryMovie = primaryMovie+nanmin(primaryMovie(:));
				% =================================================
				% frameListTmp = 1:min(cellfun(@(x) size(x,3), primaryMovie));
				if isempty(frameList)
					% trueVidTotalFrames = size(primaryMovie,3)*DOWNSAMPLE_FACTOR;
					if DOWNSAMPLE_FACTOR==1
						frameListTmp = frameList;
					else
						% frameListTmp = 1:size(primaryMovie{1},3);
						frameListTmp = [1 (1:size(primaryMovie,3))*DOWNSAMPLE_FACTOR];
						% frameListTmp
					end
					% frameListTmp = round(frameListTmp/DOWNSAMPLE_FACTOR);
				else
					frameListTmp = frameList*DOWNSAMPLE_FACTOR;
				end
				% =================================================
				if ~isempty(rawFileFilterRegexp)
					identifyingText{end+1} = 'raw';
					movieListRaw = getFileList(obj.inputFolders{obj.fileNum}, rawFileFilterRegexp);
					[frameListTmp] = getProperFrameList('raw');
					if iscell(primaryMovie)
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					% movieListRaw{movieMontageIdx(movieNo)}
					[primaryMovie{end+1}] = loadMovieList(movieListRaw,'convertToDouble',0,'frameList',frameListTmp(:),'treatMoviesAsContinuous',treatMoviesAsContinuous,'loadSpecificImgClass',class(primaryMovie{1}),'inputDatasetName',obj.inputDatasetName);
					% [primaryMovie{end}] = normalizeMovie(primaryMovie{end},'normalizationType','meanSubtraction');
					% primaryMovie{end} = normalizeMovie(single(primaryMovie{end}),'normalizationType','lowpassFFTDivisive','freqLow',1,'freqHigh',4,'waitbarOn',1,'bandpassMask','gaussian');
					if normalizeMovieSwitch==1
						[primaryMovie{end}] = normalizeVector(single(primaryMovie{end}),'normRange','zeroToOne');
					end
					% playMovie(primaryMovie{end});
					equalizeMovieHistograms()
				end
				% =================================================
				local_getVideoRegexp();
				% vidList = getFileList(videoDir,videoTrialRegExp);
				if recursiveVideoSearch==1
					vidList = getFileList(videoDir,videoTrialRegExp,'regexpWithFolder',1,'recusive',1);
				else
					vidList = getFileList(videoDir,videoTrialRegExp);
				end
				if ~isempty(vidList)&showBehaviorVideo==1
					% get the movie
					% vidList
					if iscell(primaryMovie)
						% [primaryMovie{end+1}] = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw');
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					primaryMovie{end+1} = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListTmp(:),'treatMoviesAsContinuous',1,'loadSpecificImgClass','single');
					if rotateVideoSwitch==1
						display('rotating video...')
						primaryMovie{end} = permute(primaryMovie{end}, [2 1 3]);
					end
					% class(primaryMovie{end})
					if normalizeMovieSwitch==1
						[primaryMovie{end}] = normalizeVector(single(primaryMovie{end}),'normRange','zeroToOne');
					end
					[primaryMovie{end}] = normalizeMovie(primaryMovie{end},'normalizationType','meanSubtraction');
					equalizeMovieHistograms()
					% playMovie(primaryMovie{end});
					identifyingText{end+1} = 'behavior';
				else
					% [primaryMovie] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:));
				end
				% =================================================
				if createSignalBasedVideosSwitch==1
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered');
					% {rawICfiltersSaveStr,rawICtracesSaveStr}
					% {rawICfiltersSaveStr,rawROItracesSaveStr}
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% [inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','filtered','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					% [inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','raw','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					[inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','filtered');
					if iscell(primaryMovie)
						% [primaryMovie{end+1}] = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw');
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					% tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw','normalizeOutputMovie','no');
					tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','peak','normalizeOutputMovie','no','inputPeaks',signalPeaks(:,frameList(:)));
					tmpMovie(tmpMovie<0.03) = NaN;
					% tmpMovie(1:20,1:20,1)
					% imagesc(squeeze(tmpMovie(:,:,1)));colorbar
					if length(primaryMovie)==2
						primaryMovie = flip(primaryMovie);
						identifyingText = flip(identifyingText);
						% primaryMovie{end+1} = primaryMovie{1};
						% primaryMovie{1} = primaryMovie{2};
						% primaryMovie{2} = {};
						% [primaryMovie{end+1}] = tmpMovie; clear tmpMovie;
					end
					[primaryMovie{end+1}] = tmpMovie; clear tmpMovie;
					if normalizeMovieSwitch==1
						[primaryMovie{end}] = normalizeVector(single(primaryMovie{end}),'normRange','zeroToOne');
					end
					% primaryMovie{end} = primaryMovie{end} - 0.1;
					% % [inputSignals, ~, ~, ~] = modelGetSignalsImages(obj,'returnType','filtered_traces');
					% [inputSignals, ~, ~, ~] = modelGetSignalsImages(obj,'returnType','raw_traces');
					% tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw','normalizeOutputMovie','no');
					% tmpMovie(tmpMovie<0.03) = NaN;
					% [primaryMovie{end+1}] = tmpMovie; clear tmpMovie;

					identifyingText{end+1} = 'signalBased';
				end
				% =================================================
				if createImageOutlineOnMovieSwitch==1||createImageOutlineOnMovieSwitch==2
					if createImageOutlineOnMovieSwitch==1
						[inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','filtered');
					elseif createImageOutlineOnMovieSwitch==2
						[inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','raw');
					end
					primaryMovie = createImageOutlineOnMovie(primaryMovie,inputImages,'thresholdOutline',thresholdOutline,'movieVal',NaN);
				end

				% =================================================
				if iscell(primaryMovie)
					% primaryMovie = montageMovies(primaryMovie);
					if viewOptions.useIdentifyText==0
						identifyingText = [];
					end
					[primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',identifyingText,'normalizeMovies', zeros([length(primaryMovie) 1]),'singleRowMontage',1);
					primaryMovie = permute(primaryMovie,[2 1 3]);
				end
				% =================================================
				if downsampleFactorSave~=1
					[primaryMovie] = downsampleMovie(primaryMovie,'downsampleDimension','time','downsampleType','bilinear','downsampleFactor',downsampleFactorSave);
				end

				if saveCopyOfMovie==1
					savePathDir = [obj.videoSaveDir filesep 'preview' filesep];
					savePathName = [obj.videoSaveDir filesep 'preview' filesep obj.folderBaseSaveStr{obj.fileNum} '.h5'];
					display(['saving: ' savePathName])
					[output] = writeHDF5Data(primaryMovie,savePathName);

					tiffOptions.comp = 'no';
					savePathName = [obj.videoSaveDir filesep 'preview' filesep obj.folderBaseSaveStr{obj.fileNum} '.tiff'];
					% display(['saving: ' savePathName])
					% saveastiff(primaryMovie, savePathName, tiffOptions);
				else

					[movieDecision] = playMovieThisFunction()

					if exist('runtimeTable','var')
						addRow = size(runtimeTable,1)+1;
						runtimeTable.fileNum(addRow,1) = obj.fileNum;
						runtimeTable.movieNo(addRow,1) = movieNo;
						runtimeTable.foldername{addRow,1} = obj.folderBaseSaveStr{obj.fileNum};
						runtimeTable.folderPath{addRow,1} = obj.inputFolders{obj.fileNum};
						runtimeTable.goodMovie{addRow,1} = movieDecision;
					else
						runtimeTable = table(...
							obj.fileNum,...
							movieNo,...
							{obj.folderBaseSaveStr{obj.fileNum}},...
							{obj.inputFolders{obj.fileNum}},...
							{movieDecision},...
							'VariableNames',{...
							'fileNum',...
							'movieNo',...
							'foldername',...
							'folderPath',...
							'goodMovie'});
					end
					runtimeTablePath = [obj.dataSavePath filesep 'database_movie_processing_' obj.protocol{obj.fileNum} '_' currentDateTimeStr '.csv'];
					cd(obj.defaultObjDir)
					writetable(runtimeTable,runtimeTablePath,'FileType','text','Delimiter',',');
				end
				clear primaryMovie;
			end

			if createMontageVideosSwitch==1
				% if strcmp(analyzeSpecificFolder,'same')
				% 	movieList = getFileList(obj.inputFolders{obj.fileNum}, '.h5');
				% end
				scnsize = get(0,'ScreenSize');
				if askForMovieList == 1;
					scnsize = get(0,'ScreenSize');
					[movieMontageIdx, ok] = listdlg('ListString',movieList,'ListSize',[scnsize(3)*0.7 scnsize(4)*0.25],'Name','which movies to make montage?');
				else
					movieMontageIdx = 1:length(movieList);
				end
				clear primaryMovie;
				if ok==1
					movieList{movieMontageIdx}
					if noCrop==1
						for movieNo = 1:nMovies
							cropCoords{movieNo} = {};
						end
					else
						[cropCoords noCrop] = getCropMovieCoords({movieList{movieMontageIdx}});
					end

					for movieNo = 1:length(movieMontageIdx)
						[primaryMovie{movieNo}] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:),'inputDatasetName',obj.inputDatasetName);
						fileInfo = getFileInfo(movieList{movieMontageIdx(movieNo)});
						movieTmp = primaryMovie{movieNo};
						nFrames = size(movieTmp,3);
						if viewOptions.useIdentifyText==0
							identifyingText{movieNo} = [];
						else
							fileInfo = getFileInfo(movieList{movieMontageIdx(movieNo)});
							identifyingText{movieNo} = fileInfo.subject;
						end
						% for frameNo = 1:nFrames
						% 	movieTmp(:,:,frameNo) = squeeze(sum(...
						% 		insertText(movieTmp(:,:,frameNo),[0 0],[fileInfo.subject '_' fileInfo.assay],...
						% 		'BoxColor','white',...
						% 		'AnchorPoint','LeftTop',...
						% 		'BoxOpacity',1)...
						% 	,3));
						% end
						if isempty(cropCoords{movieNo})
							primaryMovie{movieNo} = movieTmp;
						else
							pts = cropCoords{movieNo};
							primaryMovie{movieNo} = movieTmp(pts(2):pts(4), pts(1):pts(3),:);
						end
					end

					videoTrialRegExp
					if recursiveVideoSearch==1
						vidList = getFileList(videoDir,videoTrialRegExp,'regexpWithFolder',1,'recusive',1);
					else
						vidList = getFileList(videoDir,videoTrialRegExp,'regexpWithFolder',1);
					end

					vidList
					% identifyingText = {'CA1','PrL'};
					if ~isempty(vidList)&showBehaviorVideo==1
						% get the movie
						vidList
						% frameListTmp = 1:min(cellfun(@(x) size(x,3), primaryMovie));
						if isempty(frameList)
							% trueVidTotalFrames = size(primaryMovie,3)*DOWNSAMPLE_FACTOR;
							if DOWNSAMPLE_FACTOR==1
								frameListTmp = frameList;
							else
								% frameListTmp = 1:size(primaryMovie{1},3);
								frameListTmp = 1:size(primaryMovie,3);
							end
							% frameListTmp = round(frameListTmp/DOWNSAMPLE_FACTOR);
						else
							frameListTmp = frameList;
						end
						primaryMovie{end+1} = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListTmp(:)*DOWNSAMPLE_FACTOR,'treatMoviesAsContinuous',1,'loadSpecificImgClass',class(primaryMovie{1}));
						if normalizeMovieSwitch==1
							[primaryMovie{end}] = normalizeVector(primaryMovie{end},'normRange','zeroToOne');
						end
						[primaryMovie{end}] = normalizeMovie(primaryMovie{end},'normalizationType','meanSubtraction');
						identifyingText{end+1} = 'behavior';
					end

					% primaryMovie = montageMovies(primaryMovie,'identifyingText',identifyingText);
					if viewOptions.useIdentifyText==0
						identifyingText = [];
					end
					[primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',identifyingText,'normalizeMovies', zeros([length(primaryMovie) 1]));
					% [primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',{'dfof','','ROI','ICA'});
					if downsampleFactorSave~=1
						[primaryMovie] = downsampleMovie(primaryMovie,'downsampleDimension','time','downsampleType','bilinear','downsampleFactor',downsampleFactorSave);
					end

					if saveCopyOfMovie==1
						savePathName = [obj.videoSaveDir filesep obj.folderBaseSaveStr{obj.fileNum} '_montage_' obj.fileIDArray{obj.fileNum} '.h5'];
						display(['saving: ' savePathName])
						[output] = writeHDF5Data(primaryMovie,savePathName);
					else
						[movieDecision] = playMovieThisFunction()
					end
				end
			end

		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	if strcmp(options.videoPlayer,'imagej')&saveCopyOfMovie==0
		% MIJ.exit;
		manageMiji('startStop','exit');
	end
	try
		msgboxHandle = findall(0,'Type','figure','Name','Success');
		close(msgboxHandle)
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [movieDecision] = playMovieThisFunction()
		displayStrMovie = [num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) '[' num2str(movieNo) '/' num2str(nMovies) ']' ': ' obj.folderBaseDisplayStr{obj.fileNum}];
		switch options.videoPlayer
			case 'matlab'
				[exitSignal movieStruct] = playMovie(primaryMovie,'extraTitleText',displayStrMovie);
				% fileIDNameArray
				movieDecision = questdlg('Is the movie good?', ...
					'Movie decision', ...
					'yes','motion','other','yes');
			case 'imagej'
				try
					% Miji;
					% MIJ.createImage([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) '[' num2str(movieNo) '/' num2str(nMovies) ']' ': ' obj.folderBaseSaveStr{obj.fileNum}], primaryMovie, true);
					s.Interpreter = 'tex';
					s.WindowStyle = 'replace';
					ciapkg.overloaded.msgbox('Click movie to open next dialog box.','Success','normal',s)
					MIJ.createImage(displayStrMovie, primaryMovie, true);
					% if size(primaryMovie,1)<300
					% 	for foobar=1:3; MIJ.run('In [+]'); end
					% end
					for foobar=1:2; MIJ.run('Enhance Contrast','saturated=0.35'); end
					MIJ.run('Start Animation [\]');
					clear primaryMovie;
					% uiwait(ciapkg.overloaded.msgbox('press OK to move onto next movie','Success','modal'));
					movieDecision = questdlg('Is the movie good?', ...
						'Movie decision', ...
						'yes','motion','other','yes');
					% MIJ.run('Close');
					% MIJ.run('Close All Without Saving');
					manageMiji('startStop','closeAllWindows');
					% MIJ.exit;
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
					try
						playMovie(primaryMovie);
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
					end
				end

			otherwise
				% body
		end
	end
	function local_getVideoRegexp()
		switch videoTrialRegExpIdx
			case 1
				videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			case 2
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
			case 3
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'_',obj.subjectStr{obj.fileNum},'_',obj.assay{obj.fileNum});
			case 4
				videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
			case 5
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'_',obj.subjectStr{obj.fileNum});
			case 6
				videoTrialRegExp = videoFilterRegexp;
			otherwise
				videoTrialRegExp = fileFilterRegexp;
		end
	end
	function equalizeMovieHistograms()
		% primaryMovie{end} = primaryMovie{end}/10+0.05;
		% reverseStr = '';
		% nFrames = size(primaryMovie{end},3);
		% for frameNo = 1:nFrames
		% 	% primaryMovie{end}(:,:,frameNo) = imcomplement(primaryMovie{end}(:,:,frameNo));
		% 	g = squeeze(primaryMovie{1}(:,:,frameNo));
		% 	% g(isnan(g)) = nanmean(g(:));
		% 	g(isnan(g)) = -1;
		% 	g(g~=-1) = NaN;
		% 	% subplot(1,2,1)
		% 	% imagesc(g)
		% 	rowFirst = find(isnan(g(round(end/2),:)),1,'first');
		% 	rowLast = find(isnan(g(round(end/2),:)),1,'last');
		% 	colFirst = find(isnan(g(:,round(end/2))),1,'first');
		% 	colLast = find(isnan(g(:,round(end/2))),1,'last');
		% 	primaryMovie{end}(:,:,frameNo) = imhistmatch(primaryMovie{end}(:,:,frameNo),primaryMovie{1}(colFirst:colLast,rowFirst:rowLast,frameNo),3000);
		% 	% primaryMovie{end}(:,:,frameNo) = imhistmatch(primaryMovie{end}(:,:,frameNo),g,1000);
		% 	% subplot(1,2,2)
		% 	% imagesc(primaryMovie{1}(colFirst:colLast,rowFirst:rowLast,frameNo))
		% 	if mod(frameNo,50)==0
		% 		reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','equalizing histograms','waitbarOn',1,'displayEvery',50);
		% 	end
		% end
	end
	function [frameListTmp] = getProperFrameList(movieType)
		if treatMoviesAsContinuous==1
			movieListTmp2 = movieList;
		else
			movieListTmp2 = movieList{movieMontageIdx(movieNo)};
		end
		if isempty(frameList)
			frameListTmp = frameList;
		else
			switch movieType
				case 'primary'
					movieDims = loadMovieList(movieListTmp2,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'getMovieDims',1,'treatMoviesAsContinuous',treatMoviesAsContinuous);
				case 'raw'
					movieDims = loadMovieList(movieListRaw,'convertToDouble',0,'frameList',[],'treatMoviesAsContinuous',treatMoviesAsContinuous,'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
				otherwise
					% body
			end
			nMovieFrames = sum(movieDims.z);
			display(['movie frames: ' num2str(nMovieFrames)]);
			frameListTmp = frameList;
			frameListTmp(frameListTmp>nMovieFrames) = [];
		end
		if loadMovieInEqualParts~=0
			switch movieType
				case 'primary'
					movieDims = loadMovieList(movieListTmp2,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',treatMoviesAsContinuous,'loadSpecificImgClass','single','getMovieDims',1);
				case 'raw'
					movieDims = loadMovieList(movieListRaw,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',treatMoviesAsContinuous,'loadSpecificImgClass','single','getMovieDims',1);
					% movieDims = loadMovieList(movieListRaw,'convertToDouble',0,'frameList',[],'treatMoviesAsContinuous',treatMoviesAsContinuous,'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
				otherwise
					% body
			end

			if isempty(frameListTmp)
				defaultNumFrames = 100;
				tmpList = round(linspace(1,sum(movieDims.z)-defaultNumFrames,loadMovieInEqualParts));
				display(['tmpList' num2str(tmpList)])
				tmpList = bsxfun(@plus,tmpList,[1:defaultNumFrames]');
			else
				tmpList = round(linspace(1,sum(movieDims.z)-length(frameListTmp),loadMovieInEqualParts));
				display(['tmpList' num2str(tmpList)])
				tmpList = bsxfun(@plus,tmpList,frameListTmp(:));
			end
			frameListTmp = tmpList(:);
			frameListTmp(frameListTmp<1) = [];
			frameListTmp(frameListTmp>sum(movieDims.z)) = [];
		end
		% frameListTmp
	end
end
function [inputMovies] = montageMovies(inputMovies)
	nMovies = length(inputMovies);
	[xPlot yPlot] = getSubplotDimensions(nMovies);
	% movieLengths = cellfun(@(x){size(x,3)},inputMovies);
	% maxMovieLength = max(movieLengths{:});
	normalizeMoviesOption = 0;
	inputMovieNo = 1;
	for xNo = 1:xPlot
		for yNo = 1:yPlot
			if inputMovieNo>length(inputMovies)
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},NaN(size(inputMovies{1})),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
			elseif yNo==1
				[behaviorMovie{xNo}] = inputMovies{inputMovieNo};
			else
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},inputMovies{inputMovieNo},'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
			end
			size(behaviorMovie{xNo})
			inputMovieNo = inputMovieNo+1;
		end
	end
	size(behaviorMovie{1})
	behaviorMovie{1} = permute(behaviorMovie{1},[2 1 3]);
	size(behaviorMovie{1})
	display(repmat('-',1,7))
	for concatNo = 2:length(behaviorMovie)
		[behaviorMovie{1}] = createSideBySide(behaviorMovie{1},permute(behaviorMovie{concatNo},[2 1 3]),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
		behaviorMovie{concatNo} = {};
		size(behaviorMovie{1});
	end
	inputMovies = behaviorMovie{1};
	% behaviorMovie = cat(behaviorMovie{:},3)
end
%% getCropMovieCoords: function description
function [cropCoords noCrop] = getCropMovieCoords(movieList)
	% movieList
	noCrop = 0;
	nMovies = length(movieList);
	options.refCropFrame = 1;
	options.datasetName = '/1';

	usrIdxChoiceStr = {'YES | duplicate coords across multiple movies','NO | do not duplicate coords across multiple movies'};
	scnsize = get(0,'ScreenSize');
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','use coordinates over multiple folders?');
	cropCoord = {};
	if ok==0
		noCrop = 1;
		for movieNo = 1:nMovies
			cropCoords{movieNo} = {};
		end
		return
	end
	usrIdxChoiceList = {1,0};
	applyPreviousCoords = usrIdxChoiceList{sel};

	for movieNo = 1:nMovies
		inputFilePath = movieList{movieNo};

		[pathstr,name,ext] = fileparts(inputFilePath);
		if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
			hinfo = hdf5info(inputFilePath);
			hReadInfo = hinfo.GroupHierarchy.Datasets(1);
			xDim = hReadInfo.Dims(1);
			yDim = hReadInfo.Dims(2);
			% select the first frame from the dataset
			thisFrame = readHDF5Subset(inputFilePath,[0 0 options.refCropFrame],[xDim yDim 1],'datasetName',options.datasetName);
		elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
			TifLink = Tiff(inputFilePath, 'r'); %Create the Tiff object
			thisFrame = TifLink.read();%Read in one picture to get the image size and data type
			TifLink.close(); clear TifLink
		end

		[figHandle figNo] = openFigure(9, '');
		subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('click, drag-n-draw region')
		set(0,'DefaultTextInterpreter','none');
		suptitle([num2str(movieNo) '\' num2str(nMovies) ': ' strrep(inputFilePath,'\','/')]);
		set(0,'DefaultTextInterpreter','latex');

		% Use ginput to select corner points of a rectangular
		% region by pointing and clicking the subject twice
		% fileInfo = getFileInfo(thisDir);
		if movieNo==1
			p = round(getrect);
		elseif applyPreviousCoords==1
			% skip, reuse last coordinates
		else
			p = round(getrect);
		end

		% Get the x and y corner coordinates as integers
		cropCoords{movieNo}(1) = p(1); %xmin
		cropCoords{movieNo}(2) = p(2); %ymin
		cropCoords{movieNo}(3) = p(1)+p(3); %xmax
		cropCoords{movieNo}(4) = p(2)+p(4); %ymax

		% Index into the original image to create the new image
		pts = cropCoords{movieNo};
		thisFrameCropped = thisFrame(pts(2):pts(4), pts(1):pts(3));
		% Display the subsetted image with appropriate axis ratio
		[figHandle figNo] = openFigure(9, '');
		subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
	end
end