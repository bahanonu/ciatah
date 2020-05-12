function obj = viewCellExtractionOnMovie(obj,varargin)
	% Creates outlines of the cell extraction outputs on the movie.
	% Biafra Ahanonu
	% started: 2019.06.14 [09:08:08]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.10.29 [16:31:37] - Added a check for already loaded files
	% TODO
		% Give users the option to scroll back and forth by having a horizontal scrollbar


	%========================
	% DESCRIPTION
	options.baseOption = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% =====================
	% fileFilterRegexp = obj.fileFilterRegexp;
	FRAMES_PER_SECOND = obj.FRAMES_PER_SECOND;
	% DOWNSAMPLE_FACTOR = obj.DOWNSAMPLE_FACTOR;
	options.videoPlayer = [];
	% =====================
	currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
	if isempty(options.videoPlayer)
		usrIdxChoiceStr = {'matlab','imagej'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which video player to use?');
		options.videoPlayer = usrIdxChoiceStr{sel};
	end
	if strcmp(options.videoPlayer,'imagej')
		modelAddOutsideDependencies('miji');
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
	if iscell(obj.videoDir);
		videoDir = strjoin(obj.videoDir,',');
	else
		videoDir = obj.videoDir;
	end;
	% =====================
	AddOpts.Resize='on';
	AddOpts.WindowStyle='normal';
	AddOpts.Interpreter='tex';

	% movieSettings = inputdlg({...
	movieSettings = inputdlgcol({...
			'char: Imaging movie regexp (IMPORTANT, make sure matches the movie you want to view):',...
			'start:end frames (leave blank for all)',...
			'raw:processed downsample factor: ',...
			'Create cell extraction outlines on movie (1 = sorted outputs, 2 = all outputs):',...
			'Cell extraction outlines threshold (float btwn 0 and 1):',...
			'video folder(s), separate multiple folders by a comma:',...
			'side-by-side save folder:',...
			'analyze specific folder (leave blank if no) ("same" = input folder)',...
			'create movie montages (0 = no, 1 = signal peak + overlay movie, 2 = only signal-peak movie)',...
			'create signal-based movie montages (0 = no, 1 = yes)',...
			'type of signal-based movie ("raw" or "peak")',...
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
			'dataset name',...
			'downsample factor for movie viewing (1 = no downsample):',...
			'Display raw movie (1 = yes, 0 = no):',...
		},...
		'view movie settings',[1 100],...
		{...
			defaultFileFilterRegexp,...
			'1:500',...
			num2str(obj.DOWNSAMPLE_FACTOR),...
			'2',...
			'0.4',...
			videoDir,....
			obj.videoSaveDir,...
			'',...
			'0',...
			'0',...
			'peak',...
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
			'1',...
			obj.inputDatasetName,...
			'1',...
			'0'...
		},AddOpts,2);
	% movieSettings2 = inputdlg({...
	% 		'recursively search video directory (0 = no, 1 = yes)',...
	% 		'add text labels to movie (0 = no, 1 = yes):',...
	% 		'normalize movies (0 = no, 1 = yes):',...
	% 		'preload primary movies (0 = no, 1 = yes):',...
	% 		'load movie in equal parts (0 = disable feature):',...
	% 		'downsample factor for movie  (1 = no downsample):',...
	% 		'video regular expression:',...
	% 		'rotate second video (0 = no, 1 = yes)',...
	% 		'treat movie as continuous (0 = no, 1 = yes):',...
	% 		'dataset name',...
	% 		'downsample factor for movie viewing (1 = no downsample):',...
	% 	},...
	% 	'view movie settings',[1 100],...
	% 	{...
	% 		'0',...
	% 		'0',...
	% 		'0',...
	% 		'0',...
	% 		'0',...
	% 		'1',...
	% 		obj.behaviorVideoRegexp,...
	% 		'0',...
	% 		'1',...
	% 		obj.inputDatasetName,...
	% 		'1'...
	% 	}...
	% );
	% concat the two
	% movieSettings = cat(1,movieSettings,movieSettings2);
	i=1;
	fileFilterRegexp = movieSettings{i};i=i+1;
	if processedMovieFlag==1
		obj.fileFilterRegexp = fileFilterRegexp;
	end
	frameList = str2num(movieSettings{i}); i=i+1;
	DOWNSAMPLE_FACTOR = str2num(movieSettings{i}); i=i+1;
	createImageOutlineOnMovieSwitch = str2num(movieSettings{i}); i=i+1;
	thresholdOutline = str2num(movieSettings{i}); i=i+1;
	obj.videoDir = strsplit(movieSettings{i},','); i=i+1;
		videoDir = obj.videoDir;
	obj.videoSaveDir = movieSettings{i}; i=i+1;
		videoSaveDir = obj.videoSaveDir;
	analyzeSpecificFolder = movieSettings{i}; i=i+1;
	createMontageVideosSwitch = str2num(movieSettings{i}); i=i+1;
	createSignalBasedVideosSwitch = str2num(movieSettings{i}); i=i+1;
	userSignalBasedType = movieSettings{i}; i=i+1;
	askForMovieList = str2num(movieSettings{i}); i=i+1;
	saveCopyOfMovie = str2num(movieSettings{i}); i=i+1;
	rawFileFilterRegexp = movieSettings{i}; i=i+1;
	recursiveVideoSearch = str2num(movieSettings{i}); i=i+1;
	viewOptions.useIdentifyText = str2num(movieSettings{i}); i=i+1;
	normalizeMovieSwitch = str2num(movieSettings{i}); i=i+1;
	preLoadPrimaryMovie = str2num(movieSettings{i}); i=i+1;
	loadMovieInEqualParts = str2num(movieSettings{i}); i=i+1;
	downsampleFactorSave = str2num(movieSettings{i}); i=i+1;
	videoFilterRegexp = movieSettings{i}; i=i+1;
		obj.behaviorVideoRegexp = videoFilterRegexp;
	rotateVideoSwitch = str2num(movieSettings{i}); i=i+1;
	treatMoviesAsContinuous = str2num(movieSettings{i}); i=i+1;
	obj.inputDatasetName = movieSettings{i}; i=i+1;
	downsampleFactorView = str2num(movieSettings{i}); i=i+1;
	displayRawMovie = str2num(movieSettings{i}); i=i+1;
	noCrop = 0;


	% % =====================
	% Check files already loaded
	try
		[rawSignals rawImages signalPeaks signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
		skipReload = 1;
	catch
		obj.guiEnabled = 0;
		obj.modelVarsFromFiles();
		obj.guiEnabled = 1;
		skipReload = 0;
	end
	% % =====================
	if strcmp(options.videoPlayer,'imagej')&saveCopyOfMovie==0
		% Miji
		% try
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
					movieListTmp2 = movieList;
				else
					movieListTmp2 = movieList{movieMontageIdx(movieNo)};
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
				if createImageOutlineOnMovieSwitch==1||createImageOutlineOnMovieSwitch==2
					if createImageOutlineOnMovieSwitch==1
						[inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','filtered');
					elseif createImageOutlineOnMovieSwitch==2
						[inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','raw');
					end
					if displayRawMovie==1
						if iscell(primaryMovie)
						else
							primaryMovieTmp = primaryMovie; clear primaryMovie;
							primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
						end
						primaryMovieTmp = createImageOutlineOnMovie(primaryMovie{1},inputImages,'thresholdOutline',thresholdOutline,'movieVal',NaN);
						primaryMovie{end+1} = primaryMovieTmp;
						primaryMovie = flip(primaryMovie);
					else
						primaryMovie = createImageOutlineOnMovie(primaryMovie,inputImages,'thresholdOutline',thresholdOutline,'movieVal',NaN);
					end
				end
				% =================================================
				if createSignalBasedVideosSwitch==1||createSignalBasedVideosSwitch==2
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered');
					% {rawICfiltersSaveStr,rawICtracesSaveStr}
					% {rawICfiltersSaveStr,rawROItracesSaveStr}
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% [inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','filtered','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					% [inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','raw','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					% [inputSignals, inputImages, signalPeaks, ~] = modelGetSignalsImages(obj,'returnType','filtered');
					if iscell(primaryMovie)
						% [primaryMovie{end+1}] = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw');
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					% tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw','normalizeOutputMovie','no');
					tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType',userSignalBasedType,'normalizeOutputMovie','no','inputPeaks',signalPeaks(:,frameList(:)));

					% CHANGE TO USER THRESHOLD
					% tmpMovie(tmpMovie<0.03) = NaN;

					% tmpMovie(1:20,1:20,1)
					% imagesc(squeeze(tmpMovie(:,:,1)));colorbar
					if createSignalBasedVideosSwitch==2
						primaryMovie = tmpMovie;
						clear tmpMovie;
					elseif iscell(primaryMovie)
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
				if iscell(primaryMovie)
					% primaryMovie = montageMovies(primaryMovie);
					if viewOptions.useIdentifyText==0
						identifyingText = [];
					end
					[primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',identifyingText,'normalizeMovies', zeros([length(primaryMovie) 1]),'singleRowMontage',1);
					primaryMovie = permute(primaryMovie,[2 1 3]);
				end
				if saveCopyOfMovie==1
					savePathName = [obj.videoSaveDir filesep obj.folderBaseSaveStr{obj.fileNum} '_montage_' obj.fileIDArray{obj.fileNum} '.h5'];
					display(['saving: ' savePathName])
					[output] = writeHDF5Data(primaryMovie,savePathName);
				else
					[movieDecision] = playMovieThisFunction()
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
	function [movieDecision] = playMovieThisFunction()
		displayStrMovie = [num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) '[' num2str(movieNo) '/' num2str(nMovies) ']' ': ' obj.folderBaseDisplayStr{obj.fileNum}];
		switch options.videoPlayer
			case 'matlab'
				msgHandle = msgbox('Change contrast by pressing "j"');
				[exitSignal movieStruct] = playMovie(primaryMovie,'extraTitleText',displayStrMovie);

				% Remove msg box
				delete(msgHandle);
				% fileIDNameArray
				% movieDecision = questdlg('Is the movie good?', ...
				% 	'Movie decision', ...
				% 	'yes','motion','other','yes');
				movieDecision = 'yes';
			case 'imagej'
				msgbox('Change contrast by pressing ctrl+shift+c');
				try
					% Miji;
					% MIJ.createImage([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) '[' num2str(movieNo) '/' num2str(nMovies) ']' ': ' obj.folderBaseSaveStr{obj.fileNum}], primaryMovie, true);
					MIJ.createImage(displayStrMovie, primaryMovie, true);
					if size(primaryMovie,1)<300
						% for foobar=1:3; MIJ.run('In [+]'); end
					end
					for foobar=1:2; MIJ.run('Enhance Contrast','saturated=0.35'); end
					MIJ.run('Start Animation [\]');
					clear primaryMovie;
					uiwait(msgbox('press OK to move onto next movie','Success','modal'));
					% movieDecision = questdlg('Is the movie good?', ...
					% 	'Movie decision', ...
					% 	'yes','motion','other','yes');
					movieDecision = 'yes';
					% MIJ.run('Close');
					MIJ.run('Close All Without Saving');
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
