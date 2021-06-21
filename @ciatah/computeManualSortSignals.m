function obj = computeManualSortSignals(obj)
	% Manual sorting of cell extraction outputs
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2014.10.09 - finished re-implementing for behaviorAnalysis class
		% 2019.05.15 [13:13:10] Added support for reading movie from disk to allow sorting of large imaging movies
		% 2019.09.09 [18:14:48] - Update to handling uigetfile output.
		% 2021.01.21 [10:37:07] - Updated to support HDF5 and regexp for movie manual names along with misc. other changes.
		% 2021.03.17 [16:34:59] - If user hasn't called modelVarsFromFiles, computeManualSortSignals called the function. However, this lead to a mismatch between computeManualSortSignals fileNum and obj.fileNum, leading to mismatch between xcoords, etc. and input signals/images.
		% 2021.06.18 [21:41:07] - added modelVarsFromFilesCheck() to check and load signals if user hasn't already.
	% ADDED
		% ADD PERSONS NAME TO THE FILE - DONE.
	% TODO

	% =======
	options.emSaveRaw = '_emAnalysis.mat';
	options.emSaveSorted = obj.sortedEMStructSaveStr;
	options.cleanedICfiltersSaveStr = obj.sortedICfiltersSaveStr;
	options.cleanedICtracesSaveStr = obj.sortedICtracesSaveStr;
	options.cleanedICdecisionsSaveStr = obj.sortedICdecisionsSaveStr;
	% =======

	for figNoFake = [1996 1997 1776 1777 1778 1779 42 1]
		[~, ~] = openFigure(figNoFake, '');
		clf
	end
	drawnow

	display(repmat('#',1,21))
	display('computing signal peaks...')
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			% fileNum = obj.fileNum;
			display(repmat('#',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(obj.fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);

			% Check that signal extraction information is loaded.
			obj.modelVarsFromFilesCheck(fileNum);
			% =======
			% path to current folder
			currentFolderPath = obj.inputFolders{obj.fileNum};
			% process movie regular expression
			fileFilterRegexp = obj.fileFilterRegexp;
			% get list of movies
			movieList = getFileList(currentFolderPath, fileFilterRegexp);
			% subject information
			subject = obj.subjectNum{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			folderBaseSaveStr = obj.folderBaseSaveStr{obj.fileNum};
			%
			currentFolderSaveStr = [currentFolderPath filesep obj.folderBaseSaveStr{obj.fileNum}];

			usrIdxChoiceSignalType = obj.signalExtractionMethod;
			% =======
			if ~exist('usrIdxChoiceSettings','var')|strcmp(usrIdxChoiceSettings,'per folder settings')
				% usrIdxChoiceStr = {'sorting','viewing'};
				% [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
				% usrIdxChoiceSortType = usrIdxChoiceStr{sel};

			 %    usrIdxChoiceStr = {'load movie','do not load movie'};
			 %    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			 %    usrIdxChoiceMovie = usrIdxChoiceStr{sel};

			 %    usrIdxChoiceStr = {'do not classify','classify'};
			 %    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			 %    usrIdxChoiceClassification = usrIdxChoiceStr{sel};

			 %    usrIdxChoiceStr = {'DO NOT show ROI trace','show ROI trace'};
			 %    usrIdxChoiceStrNum = [0 1];
			 %    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			 %    usrIdxChoiceROI = usrIdxChoiceStrNum(sel);

			 %    usrIdxChoiceStr = {'start with blank','start with auto classify'};
			 %    usrIdxChoiceStrNum = [0 1];
			 %    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			 %    usrIdxChoiceAutoValid = usrIdxChoiceStrNum(sel);
				[settingStruct] = subfxnGetSettings('Signal sorting settings',fileFilterRegexp,obj.inputDatasetName);
				fn=fieldnames(settingStruct);
				for i=1:length(fn)
				  eval([fn{i} '=settingStruct.' fn{i} ';']);
				end
				% usrIdxChoiceFileFilterRegexp
				obj.fileFilterRegexp = usrIdxChoiceFileFilterRegexp;
				fileFilterRegexp = obj.fileFilterRegexp;

				scorerName = inputdlg(obj.folderBasePlaneSaveStr{obj.fileNum},'Name of user sorting data (e.g. first name)?',[1 100],{obj.userName});
				scorerName = scorerName{1};
				obj.userName = scorerName;
				% usrIdxChoiceSettings = settingStruct.usrIdxChoiceSettings;
			end

			% get list of movies
			movieList = getFileList(currentFolderPath, fileFilterRegexp);
			if strcmp(usrIdxChoiceMovie,'load movie')
				if isempty(movieList)
					display('Dialog box: Select movie to load.')
					[filePath,folderPath,~] = uigetfile([currentFolderPath filesep '*.*'],'Select movie to load.');
					% exit if user picks nothing
					% if folderListInfo==0; return; end
					movieList = [folderPath filesep filePath];
					movieList = {movieList};
				end
			end
			% if ~exist('usrIdxChoiceSettings','var')
			% 	usrIdxChoiceStr = {'settings across all folders','per folder settings'};
			% 	[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			% 	usrIdxChoiceSettings = usrIdxChoiceStr{sel};
			% end
			% =======
			if usrIdxChoiceAutoValid==2
				dlgBoxMsg = sprintf('select previous decisions to load for %s',obj.fileIDNameArray{obj.fileNum});
				display(['Dialog box: ' dlgBoxMsg])
				[filePathDecisions,folderPathDecisions,~] = uigetfile(['.\private\tmp' filesep '*.*'],dlgBoxMsg);
				% exit if user picks nothing
				% if folderListInfo==0; return; end
				tmpDecisionList = {[folderPathDecisions filesep filePathDecisions]};
				display(['loading temp decisions: ' tmpDecisionList{1}])
				load(tmpDecisionList{1});
			end
			if usrIdxChoiceAutoValid==4
				dlgBoxMsg = sprintf('select previous decisions to load for %s',obj.fileIDNameArray{obj.fileNum});
				display(['Dialog box: ' dlgBoxMsg])
				[filePathDecisions,folderPathDecisions,~] = uigetfile([obj.inputFolders{obj.fileNum} filesep '*.*'],dlgBoxMsg);
				% exit if user picks nothing
				% if folderListInfo==0; return; end
				tmpDecisionList = {[folderPathDecisions filesep filePathDecisions]};
				display(['loading decisions: ' tmpDecisionList{1}])
				load(tmpDecisionList{1});
				valid = validClassifier;
			end

			if skipReload==0
				[rawSignals, rawImages, signalPeaks, signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
			end
			switch usrIdxChoiceSignalType
				case 'PCAICA'
					% if skipReload==0
					% 	[rawSignals rawImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% end
					% check if the folder has temporary decisions to load (e.g. if a crash occured)
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(options.cleanedICdecisionsSaveStr,'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
						end
					end
					% ioptions.minValConstant = -1;
					ioptions.minValConstant = -0.02;
					ioptions.threshold = 0.5;
				case 'EM'
					% if skipReload==0
					% 	[rawSignals, rawImages, signalPeaks, signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw_CellMax');
					% end
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(options.emSaveSorted,'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
							valid = validCellMax;
						end
					end
					ioptions.minValConstant = -400;
					ioptions.threshold = 0.5;
				case 'EXTRACT'
					% if skipReload==0
					% 	[rawSignals, rawImages, signalPeaks, signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% end
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(obj.sortedEXTRACTStructSaveStr,'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
							valid = validEXTRACT;
						end
					end
					% valid = obj.validAuto{obj.fileNum};
					ioptions.minValConstant = -10;
					ioptions.threshold = 0.5;
				case 'CNMF'
					% if skipReload==0
					% 	[rawSignals, rawImages, signalPeaks, signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% end
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(obj.sortedCNMFStructSaveStr,'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
							valid = validCNMF;
						end
					end
					% valid = obj.validAuto{obj.fileNum};
					ioptions.minValConstant = -200;
					ioptions.threshold = 0.3;
				case 'CNMFE'
					% if skipReload==0
					% 	[rawSignals, rawImages, signalPeaks, signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
					% end
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod),'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
							valid = validCNMFE;
						end
					end
					% valid = obj.validAuto{obj.fileNum};
					ioptions.minValConstant = -10;
					ioptions.threshold = 0.4;
				case 'ROI'
					% if skipReload==0
					% 	[rawSignals, rawImages, signalPeaks, signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
					% end
					if usrIdxChoiceAutoValid==3
						previousDecisionList = getFileList(currentFolderPath, strrep(obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod),'.mat',''));
						if ~isempty(previousDecisionList)
							display(['loading previous decisions: ' previousDecisionList{1}])
							load(previousDecisionList{1});
							valid = validROI;
						end
					end
					% valid = obj.validAuto{obj.fileNum};
					ioptions.minValConstant = -10;
					ioptions.threshold = 0.4;
				otherwise
					% body
			end

			if usrIdxChoiceAutoValid==0
				display('starting with blank decisions...')
				% valid = valid*0;valid = valid+3;
				% valid = 3*ones([1 size(rawSignals,1)]);
				valid = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto;
				valid = valid*0;valid = valid+3;
			elseif usrIdxChoiceAutoValid==1
				display('starting with automatically sorted decisions...')
				valid = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto;
				% [~, ~, ~, ~, valid] = modelGetSignalsImages(obj,'returnType','filtered','returnOnlyValid',1);
				% valid = obj.validAuto{obj.fileNum};
			end

			% valid
			% =======
			% load movie?
			if strcmp(usrIdxChoiceMovie,'load movie')&&userIdxReadMovieChunks==0
				% load movies
				if isempty(movieList)
					disp('Dialog box: select movie to load.')
					[filePath,folderPath,~] = uigetfile([currentFolderPath filesep '*.*'],'select movie to load');
					% exit if user picks nothing
					% if folderListInfo==0; return; end
					movieList = [folderPath filesep filePath];
				end
				obj.inputDatasetName = userIdxInputDatasetName;
				[ioptions.inputMovie, o, m, n] = loadMovieList(movieList,'inputDatasetName',userIdxInputDatasetName,'forcePerFrameRead',userIdxForcePerFrameRead,'largeMovieLoad',userIdxLargeMovieLoad);
				% 'frameList',1:1000
				tmpMovie = ioptions.inputMovie(1:10,1:10,:);
				if nanmean(tmpMovie(:))>0.9
					disp('setting mean to zero')
					ioptions.inputMovie = ioptions.inputMovie-1;
				end
			elseif userIdxReadMovieChunks==1
				if isempty(movieList)
					disp('Dialog box: select movie to load.')
					[filePath,folderPath,~] = uigetfile([currentFolderPath filesep '*.*'],'select movie to load');
					% exit if user picks nothing
					% if folderListInfo==0; return; end
					movieList = [folderPath filesep filePath];
					movieList = {movieList};
				end
				ioptions.inputMovie = movieList{1};
			end
			% =======
			ioptions.signalPeaks = signalPeaks;
			ioptions.signalPeaksArray = signalPeaksArray;
			% ioptions.inputStr = subjAssayIDStr;
			ioptions.valid = valid;
			ioptions.sessionID = [folderBaseSaveStr '_' num2str(java.lang.System.currentTimeMillis)];
			ioptions.inputStr = [num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(obj.fileNum) '/' num2str(nFiles) '): ' obj.folderBaseSaveStr{obj.fileNum}];
			ioptions.showROITrace = usrIdxChoiceROI;
			ioptions.cropSizeLength = usrIdxCropSizeLength;
			ioptions.cropSize = usrIdxCropSizeLength;
			ioptions.threshold = userIdxImageThreshold;
			ioptions.thresholdOutline = userIdxImageThresholdOutline;
			ioptions.colormap = obj.colormap;

			ioptions.coord.xCoords = max(1,round(obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(:,1)));
			ioptions.coord.yCoords = max(1,round(obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(:,2)));

			ioptions.inputSignalsSecond = rawSignals2;

			ioptions.preComputeImageCutMovies = userIdxPreComputeImageCutMovies;

			ioptions.readMovieChunks = userIdxReadMovieChunks;

			ioptions.signalLoopTicTocCheck = userIdxSignalLoopTicTocCheck;

			ioptions.inputDatasetName = obj.inputDatasetName;

			% ioptions.classifierFilepath = options.classifierFilepath;
			% ioptions.classifierType = options.classifierType;

			if userIdxOnlyResortGoodSources==1&usrIdxChoiceAutoValid==3
				newValid = logical(valid);
				rawImages = rawImages(:,:,newValid);
				rawSignals = rawSignals(newValid,:);
				rawSignals2 = rawSignals2(newValid,:);
				ioptions.signalPeaks = ioptions.signalPeaks(newValid,:);
				ioptions.signalPeaksArray = ioptions.signalPeaksArray(newValid);
				ioptions.inputSignalsSecond = rawSignals2;
				ioptions.valid = ioptions.valid(newValid);
				ioptions.coord.xCoords = ioptions.coord.xCoords(newValid);
				ioptions.coord.yCoords = ioptions.coord.yCoords(newValid);
			end

			[rawImages rawSignals valid] = signalSorter(rawImages, rawSignals,'options',ioptions);

			if userIdxOnlyResortGoodSources==1&usrIdxChoiceAutoValid==3
				% replace old with new classifications
				originalValid = newValid;
				newValid(newValid) = valid;
				valid = newValid;
			end
			clear ioptions;
			% rawImages = rawImages(valid,:,:);
			% rawSignals = rawSignals(valid,:);

			% add manual sorting to object
			obj.validManual{obj.fileNum} = valid;
			% commandwindow;

			% save sorted ICs
			if strcmp(usrIdxChoiceSortType,'sorting')
				switch usrIdxChoiceSignalType
					case 'PCAICA'
						valid = valid;
						methodStr = obj.sortedICdecisionsSaveStr;
						saveVariable = {'valid'};
					case 'EM'
						validCellMax = valid;
						methodStr = obj.sortedEMStructSaveStr;
						saveVariable = {'validCellMax'};
					case 'CELLMax'
						validCellMax = valid;
						methodStr = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
						saveVariable = {obj.extractionMethodValidVarname.(obj.signalExtractionMethod)};
					case 'EXTRACT'
						validEXTRACT = valid;
						methodStr = obj.sortedEXTRACTStructSaveStr;
						saveVariable = {'validEXTRACT'};
					case 'CNMF'
						validCNMF = valid;
						methodStr = obj.sortedCNMFStructSaveStr;
						saveVariable = {obj.validCNMFStructVarname};
					case 'CNMFE'
						validCNMFE = valid;
						methodStr = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
						saveVariable = {obj.extractionMethodValidVarname.(obj.signalExtractionMethod)};
					case 'ROI'
						validROI = valid;
						methodStr = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
						saveVariable = {obj.extractionMethodValidVarname.(obj.signalExtractionMethod)};
					otherwise
						% body
				end
				manualSort.signalExtractionMethod = obj.signalExtractionMethod;
				manualSort.scorerName = scorerName;
				manualSort.manualDecisions.(usrIdxChoiceSignalType) = valid;
				manualSort.videoID = movieList;
				manualSort.timestamp = datestr(now,'yyyy_mm_dd_HHMMSS','local');
				manualSort.classVersion = obj.classVersion;
				if userIdxOnlyResortGoodSources==1&usrIdxChoiceAutoValid==3
					% replace old with new classifications
					manualSort.originalValid = originalValid;
				end

				[PATHSTR,NAME,EXT] = fileparts(methodStr);
				saveID = {[NAME '_' scorerName EXT]};
				for i=1:length(saveID)
					savestring = [currentFolderSaveStr saveID{i}];
					fprintf('Saving %s to %s\n',saveVariable{i},savestring);
					% display(['saving: ' savestring])
					save(savestring,saveVariable{i},'manualSort');
				end
			end
			success = 1;
			clear rawImages rawSignals valid
		catch err
			success = 0;
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	if success==1&userIdxLoadPostSort==1
		% add information about the extracted signals to the object for later processing
		objGuiOld = obj.guiEnabled;
		obj.guiEnabled = 0;
		obj.modelVarsFromFiles();
		obj.guiEnabled = 0;
		obj.viewCreateObjmaps();
		obj.guiEnabled = objGuiOld;
	end
end
function [settingStruct] = subfxnGetSettings(inputTitleStr,fileFilterRegexp,inputDatasetName)

	regSettingDefaults = struct(...
		'usrIdxChoiceSortType', {{'sorting','viewing'}},...
		'usrIdxChoiceMovie',  {{'load movie','do not load movie'}},...
		'usrIdxChoiceROI', {{0,1}},...
		'usrIdxChoiceAutoValid',{{0,1,2,3,4}},...
		'usrIdxChoiceFileFilterRegexp',{{fileFilterRegexp,'turboreg','crop','manualCut','dfof','downsample','other'}},...
		'userIdxInputDatasetName',{{inputDatasetName,'/1','/Movie','/movie','/images','/Data/Images','/Data/Downsampled_images','other'}},...
		'userIdxForcePerFrameRead',{{0,1}},...
		'userIdxLargeMovieLoad',{{1,0}},...
		'userIdxPreComputeImageCutMovies',{{1,0}},...
		'userIdxOnlyResortGoodSources',{{0,1}},...
		'userIdxLoadPostSort',{{0,1}},...
		'userIdxReadMovieChunks',{{0,1}},...
		'usrIdxCropSizeLength',{{15,5,10,15,20,25,30,35,40,45,50,55,60,100,200}},...
		'userIdxImageThreshold',{{0.4,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95}},...
		'userIdxImageThresholdOutline',{{0.4,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95}},...
		'usrIdxChoiceSettings',{{'settings across all folders','per folder settings'}},...
		'userIdxSignalLoopTicTocCheck',{{0,1}},...
		'usrIdxChoiceClassification', {{'do not classify','classify'}}...
	);
	regSettingStr = struct(...
		'usrIdxChoiceSortType', {{'Sorting (decisions are saved)','Viewing (decisions are NOT saved)'}},...
		'usrIdxChoiceMovie',  {{'Load movie (show images cut to signal peaks)','Do not load movie'}},...
		'usrIdxChoiceROI', {{'DO NOT show ROI trace','show ROI trace'}},...
		'usrIdxChoiceAutoValid',{{'Start with blank','Start with auto classify','Start with TEMP manually chosen classifications (e.g. backups)','Start with FINISHED manually chosen classifications','Start with ARBITRARY classifications in folder'}},...
		'usrIdxChoiceFileFilterRegexp',{{fileFilterRegexp,'turboreg','crop','manualCut','dfof','downsample','other (manually enter name)'}},...
		'userIdxInputDatasetName',{{inputDatasetName,'/1','/Movie','/movie','/images','/Data/Images','/Data/Downsampled_images','other (manually enter name)'}},...
		'userIdxForcePerFrameRead', {{'Read movie normally (read into memory all at once)','Force read movie frame-by-frame (lower memory overhead)'}},...
		'userIdxLargeMovieLoad',{{'Single large movie (avoid pre-allocation, saves memory)','Normal movie (pre-allocates memory)'}},...
		'userIdxPreComputeImageCutMovies',{{'DO pre-compute event aligned movies','DO NOT pre-compute event aligned movies'}},...
		'userIdxOnlyResortGoodSources',{{'DO sort all sources','DO only sort good sources'}},...
		'userIdxLoadPostSort',{{'DO NOT load data after sorting','DO load data after sorting'}},...
		'userIdxReadMovieChunks',{{'DO NOT load movie from disk, e.g. into RAM (HDF5)','DO load movie from disk (HDF5)'}},...
		'usrIdxCropSizeLength',{{15,5,10,15,20,25,30,35,40,45,50,55,60,100,200}},...
		'userIdxImageThreshold',{{0.4,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95}},...
		'userIdxImageThresholdOutline',{{0.4,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95}},...
		'usrIdxChoiceSettings',{{'Settings across all folders','Per folder settings'}},...
		'userIdxSignalLoopTicTocCheck',{{'DO NOT run signal loop tic-toc','DO run signal loop tic-toc'}},...
		'usrIdxChoiceClassification', {{'Do not classify','Classify'}}...
	);

	regSettingTitles = struct(...
		'usrIdxChoiceSortType','Sort or view cell extraction results?',...
		'usrIdxChoiceMovie','Display movie in GUI?',...
		'usrIdxChoiceROI','Compute and display ROI trace?',...
		'usrIdxChoiceAutoValid','Use CIAtah auto classifications?',...
		'usrIdxChoiceFileFilterRegexp','Regular expression for movies to load?',...
		'userIdxInputDatasetName','HDF5 dataset name?',...
		'userIdxForcePerFrameRead','How to load movie:',...
		'userIdxLargeMovieLoad','Type of movie:',...
		'userIdxPreComputeImageCutMovies','Pre-compute transient movie montages?',...
		'userIdxOnlyResortGoodSources','Only load "good" cells?',...
		'userIdxLoadPostSort','Load data into CIAtah after sorting?',...
		'userIdxReadMovieChunks','Load movie into RAM or read from disk?',...
		'usrIdxCropSizeLength','Size of movie montages (px)?',...
		'userIdxImageThreshold','Cell image threshold',...
		'userIdxImageThresholdOutline','Cell image outline threshold',...
		'usrIdxChoiceSettings','Batch apply settings?',...
		'userIdxSignalLoopTicTocCheck','[Debug] Time sorting speed',...
		'usrIdxChoiceClassification','IGNORE'...
	);

	% propertySettings = regSettingDefaults;

	propertyList = fieldnames(regSettingDefaults);
	nPropertiesToChange = size(propertyList,1);

	% add current property to the top of the list
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		propertyOptions = regSettingStr.(property);
		propertySettingsStr.(property) = propertyOptions;
		% propertySettingsStr.(property);
	end

	uiListHandles = {};
	uiTextHandles = {};
	uiXIncrement = 0.03;
	uiYOffset = 0.90;
	uiTxtSize = 0.3;
	uiBoxSize = 0.65;
	[figHandle figNo] = openFigure(1337, '');
	clf
	uicontrol('Style','Text','String',inputTitleStr,'Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(0) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiTextHandles{propertyNo} = uicontrol('Style','text','String',[regSettingTitles.(property) '' 10],'Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*propertyNo+0.03 uiTxtSize 0.02],'BackgroundColor',[0.9 0.9 0.9],'ForegroundColor','black','HorizontalAlignment','Left');
		% uiTextHandles{propertyNo}.Enable = 'Inactive';
		uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiTxtSize uiYOffset-uiXIncrement*propertyNo uiBoxSize 0.05],'Callback',@subfxnSettingsCallback,'Tag',property);
	end
	uicontrol('Style','Text','String','press enter to continue','Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(nPropertiesToChange+2) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	% uicontrol('Style','Text','String',inputTitleStr,'Units','normalized','Position',[0.0 uiYOffset 0.15 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	pause

	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiListHandleData = get(uiListHandles{propertyNo});
		settingStruct.(property) = regSettingDefaults.(property){uiListHandleData.Value};
	end
	close(1337)
	
	function [outputs] = subfxnSettingsCallback(hObject,callbackdata)
		set(hObject, 'Backgroundcolor', [208,229,180]/255)
		% hObject
		hString = get(hObject,'String');
		hVal = get(hObject,'Value');
		hTag = get(hObject,'Tag');
		if strcmp(hTag,'usrIdxChoiceFileFilterRegexp')==1&strcmp(hString{hVal},'other (manually enter name)')
			fileFilterRegexp = inputdlg('Regexp','Regular expression for movie (e.g. "concat","downsample",etc.)?',[1 100],{hString{1}});
			fileFilterRegexp = fileFilterRegexp{1};
			% Add the new regexp to the list
			regSettingDefaults.('usrIdxChoiceFileFilterRegexp'){end+1} = fileFilterRegexp;
			set(hObject,'String',[hString; fileFilterRegexp]);
			set(hObject,'Value',length(hString)+1);
		end

		if strcmp(hTag,'userIdxInputDatasetName')==1&strcmp(hString{hVal},'other (manually enter name)')
			inputDatasetName = inputdlg('HDF5','HDF5 dataset name?',[1 100],{hString{1}});
			inputDatasetName = inputDatasetName{1};
			% Add the new regexp to the list
			regSettingDefaults.('userIdxInputDatasetName'){end+1} = inputDatasetName;
			set(hObject,'String',[hString; inputDatasetName]);
			set(hObject,'Value',length(hString)+1);
		end
	end
end


% ostruct.inputImages{ostruct.counter} = IcaFilters;
% ostruct.inputSignals{ostruct.counter} = IcaTraces;
% ostruct.validArray{ostruct.counter} = valid;

% if exist(options.classifierFilepath, 'file')&strcmp(usrIdxChoiceClassification,'classify')&0
	% display(['loading: ' options.classifierFilepath]);
	% load(options.classifierFilepath)
	% options.trainingOrClassify = 'classify';
	% ioption.classifierType = options.classifierType;
	% ioption.trainingOrClassify = options.trainingOrClassify;
	% ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
	% ioption.inputStruct = classifierStruct;
	% [ostruct.classifier] = classifySignals({ostruct.inputImages{ostruct.counter}},{ostruct.inputSignals{ostruct.counter}},'options',ioption);
	% valid = ostruct.classifier.classifications;
	% % originalValid = valid;
	% validNorm = normalizeVector(valid,'normRange','oneToOne');
	% validDiff = [0 diff(valid')];
	% %
	% figure(100020);close(100020);figure(100020);
	% plot(valid);hold on;
	% plot(validDiff,'g');
	% %
	% % validQuantiles = quantile(valid,[0.4 0.3]);
	% % validHigh = validQuantiles(1);
	% % validLow = validQuantiles(2);
	% validHigh = 0.7;
	% validLow = 0.5;
	% %
	% valid(valid>=validHigh) = 1;
	% valid(valid<=validLow) = 0;
	% valid(isnan(valid)) = 0;
	% % questionable classification
	% valid(validDiff<-0.3) = 2;
	% valid(valid<validHigh&valid>validLow) = 2;
	% %
	% plot(valid,'r');
	% plot(validNorm,'k');box off;
	% legend({'scores','diff(scores)','classification','normalized scores'})
	% % valid
% else
% 	display(['no classifier at: ' options.classifierFilepath])
% end