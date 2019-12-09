function obj = modelExtractSignalsFromMovie(obj,varargin)
	% Runs signal extraction algorithms and associated saving/other functions.
	% Biafra Ahanonu
	% started: 2015.01.05 (date might be wrong, likely late 2014)
	% inputs
		% inputMovie - a string or a cell array of strings pointing to the movies to be analyzed (recommended). Else, [x y t] matrix where t = frames.
		% numExpectedComponents - number of expected components
	% outputs
		% cnmfAnalysisOutput - structure containing extractedImages and extractedSignals along with input parameters to the algorithm
	% READ BEFORE RUNNING
		% Get CVX from http://cvxr.com/cvx/doc/install.html
		% Run the below commands in Matlab after unzipping
		% cvx_setup
		% cvx_save_prefs (permanently stores settings)

	% changelog
		% 2016.02.19 - rewrite of code to allow non-overwrite mode, so that multiple computers can connect to the same server and process the same series of folders in parallel while automatically ignoring folders that have already been processed. Could extend to include some date-based measure for analysis re-runs
		% 2019.04.15 - Added new method of inputting CNMF-E settings using MATLAB editor. More flexible.
		% 2019.08.20 [12:29:31] - Contrast added to cell size/width decision-making.
		% 2019.10.29 [17:21:23] - Added a check to make sure that filenames produced are valid MATLAB ones for settings, e.g. for CNMF-e.
		% 2019.11.10 [20:34:42] - Add a warning with some common tips for users if error during cell extraction. Skip modelVarsFromFiles and viewObjmaps loading to reduce user confusion for any folders that had issues during cell extraction.
	% TODO
		%

	%========================
	% Root path for external signal-extraction algorithm folders.
	options.signalExtractionRootPath = '_external_programs';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% Make sure private settings folder is created
	if ~exist(obj.settingsSavePath,'dir');mkdir(obj.settingsSavePath);fprintf('Creating directory: %s\n',obj.settingsSavePath);end

	scnsize = get(0,'ScreenSize');
	signalExtractionMethodStr = {'EM','PCAICA','PCAICA_old','CNMF','CNMFE','EXTRACT','ROI'};
	currentIdx = find(strcmp(signalExtractionMethodStr,obj.signalExtractionMethod));
	signalExtractionMethodDisplayStr = {'CELLMax | Lacey Kitch & Biafra Ahanonu',...
	'PCAICA (Mukamel, 2009) | Hakan Inan & Tony Kim version',...
	'PCAICA (Mukamel, 2009) | Eran Mukamel, Jerome Lecoq, Lacey Kitch, Maggie Carr & Biafra Ahanonu version',...
	'CNMF | Pnevmatikakis, 2016 or Giovannucci, 2019',...
	'CNMF-E | Zhou, 2018',...
	'EXTRACT | Inan, 2017',...
	'ROI - only do after running either PCAICA, CELLMax, EXTRACT, or CNMF'};
	[signalIdxArray, ok] = listdlg('ListString',signalExtractionMethodDisplayStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','which signal extraction method?','InitialValue',currentIdx);
	% signalIdxArray
	signalExtractionMethod = signalExtractionMethodStr(signalIdxArray);

	oldPCAICA = 0;
	if iscell(signalExtractionMethod)
		nSignalExtractMethods = length(signalExtractionMethod);
	else
		nSignalExtractMethods = 1;
	end
	for signalExtractNo = 1:nSignalExtractMethods
		switch signalExtractionMethod{signalExtractNo}
			case 'PCAICA_old'
				oldPCAICA = 1;
				signalExtractionMethod = {'PCAICA'};
			case 'EM'
				getAlgorithmRootPath('CELLMax_Wrapper.m','CELLMax',obj);
			case 'EXTRACT'
				getAlgorithmRootPath('extractor.m','EXTRACT',obj);
			otherwise
		end
	end

	% overwriteAnalysisFileSwitch = [1 0];
	% usrIdxChoiceStr = {'overwrite analysis','DO NOT overwrite analysis'};
	% [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
	% overwriteAnalysisFileSwitch = overwriteAnalysisFileSwitch(sel);

	idopts.Resize = 'on';
    idopts.WindowStyle = 'modal';
    idopts.Interpreter = 'none';

	movieSettings = inputdlg({...
			'Regular expression for movie files to extract signals from',...
			'Overwrite existing analysis files (e.g. skip folders already being analyzed on another computer)? (1 = yes, 0 = no)',...
			'Number of parallel workers (integer, no more than max # logical cores)',...
			'Parallel enabled (1 = yes, 0 = no)',...
			'Input HDF5 dataset name',...
			'Use default options (1 = yes, 0 = no)',...
			'Runtime Matlab profiler (1 = yes, 0 = no)',...
			'Regular expression for alternative movie (e.g. non-downsampled, LEAVE blank)',...
			'View results after cell extraction? (1 = yes, 0 = no)',...
		},...
		'Cell extraction parameters for all algorithms',1,...
		{...
			obj.fileFilterRegexp,...
			'1',...
			num2str(java.lang.Runtime.getRuntime().availableProcessors-1),...
			'1',...
			obj.inputDatasetName,...
			'0',...
			'0',...
			obj.fileFilterRegexpAltCellExtraction,...
			'1',...
		},idopts...
	);setNo = 1;
	obj.fileFilterRegexp = movieSettings{setNo};setNo = setNo+1;
	overwriteAnalysisFileSwitch = str2num(movieSettings{setNo});setNo = setNo+1;
	options.numWorkers = str2num(movieSettings{setNo});setNo = setNo+1;
	options.useParallel = str2num(movieSettings{setNo});setNo = setNo+1;
	obj.inputDatasetName = movieSettings{setNo};setNo = setNo+1;
	options.defaultOptions = str2num(movieSettings{setNo});setNo = setNo+1;
	options.profiler = str2num(movieSettings{setNo});setNo = setNo+1;
	obj.fileFilterRegexpAltCellExtraction = movieSettings{setNo};setNo = setNo+1;
	viewResultsAfter = str2num(movieSettings{setNo});setNo = setNo+1;

	% get files to process
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	if iscell(signalExtractionMethod)
		nSignalExtractMethods = length(signalExtractionMethod);
	else
		nSignalExtractMethods = 1;
	end

	getAlgorithmOptions();
	% ==========================================
	% ==========================================
	% pre processing for each
	for signalExtractNo = 1:nSignalExtractMethods
		switch signalExtractionMethod{signalExtractNo}
			case 'ROI'
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
			case 'PCAICA'
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
				pcaicaPCsICsSwitchStr = subfxnNumExpectedSignals();
			case 'EM'
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
				cellmaxIntMethod = {'grid','ica'};
				[signalIdxArray, ok] = listdlg('ListString',cellmaxIntMethod,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Which type of initialization method to use for CELLMax?');
				options.CELLMax.initMethod = cellmaxIntMethod{signalIdxArray};
				[gridWidth gridSpacing] = subfxnSignalSizeSpacing();
				% if strcmp(options.CELLMax.initMethod,'grid')
					% get each animals grid spacing and width
					% nFiles = length(obj.rawSignals);
					% [gridWidth gridSpacing] = subfxnSignalSizeSpacing();
				% else
				% 	subjectList = unique(obj.subjectStr(fileIdxArray));
				% 	for thisSubjectStr=subjectList
				% 		display(repmat('=',1,21))
				% 		thisSubjectStr = thisSubjectStr{1};
				% 		display(thisSubjectStr);
				% 		gridWidth.(thisSubjectStr) = NaN;
				% 		gridSpacing.(thisSubjectStr) = NaN;
				% 	end
				% end
			case 'EXTRACT'
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
				% pcaicaPCsICsSwitchStr = subfxnNumExpectedSignals();
				[gridWidth gridSpacing] = subfxnSignalSizeSpacing();
			case 'CNMF'
				% options.CNMFE.originalCurrentSwitch
				[success] = cnmfVersionDirLoad(options.CNMF.originalCurrentSwitch);
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
				[gridWidth gridSpacing] = subfxnSignalSizeSpacing();
				pcaicaPCsICsSwitchStr = subfxnNumExpectedSignals();
				if options.CNMF.iterateOverParameterSpace==1
					paramSetTmp = inputdlg({...
							'merge_thr | Merging threshold (positive between 0  and 1)',...
							'noise_range | Range of normalized frequencies over which to average PSD (2 x1 vector)',...
							'nrgthr | Energy threshold (positive between 0 and 1)',...
							'beta | Weight on squared L1 norm of spatial components',...
							'maxIter | Maximum number of HALS iterations',...
							'bSiz | Expansion factor for HALS localized updates'...
						},...
						'CNMF parameters, leave field blank to ignore',1,...
						{...
							'{0.98, 0.99}',...
							'{[0.10,0.6],[0.05,0.8]}',...
							'{0.85,0.80}',...
							'{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9}',...
							'{5,10,20,30}',...
							'{1,2,3,4,5,6}'...
						}...
					);
					parameterSpaceStr = {'merge_thr','noise_range','nrgthr','beta','maxIter','bSiz'};
					% initialize based on parameter strings above
					nParams = length(paramSetTmp);
					for paramNo = 1:nParams
						if ~isempty(paramSetTmp{paramNo})
							paramSetMaster.(parameterSpaceStr{paramNo}) = eval(paramSetTmp{paramNo});
						end
					end
				end
			case 'CNMFE'
				% options.CNMFE.originalCurrentSwitch
				[success] = cnmfVersionDirLoad('cnmfe');
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};
				% pcaicaPCsICsSwitchStr = subfxnNumExpectedSignals();
				if isempty(options.CNMFE.settingsFile)
					[gridWidth gridSpacing] = subfxnSignalSizeSpacing();
				else

				end
			otherwise
				% body
		end
	end
	% ==========================================
	% ==========================================
	% open parallel workers
	if options.useParallel==1
		manageParallelWorkers('setNumCores',options.numWorkers);
	end
	% ==========================================
	% ==========================================
	% Run signal extraction for each over all folders
	nFolders = length(fileIdxArray);
	successList = [];
	errorList = [];
	for thisFileNumIdx = 1:nFolders
		try
			% currentDateTimeStr = char(datetime('now','TimeZone','local','Format','yyyyMMdd_HHmm'));

			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);

			fileFilterRegexp = obj.fileFilterRegexp;
			fileFilterRegexpAltCellExtraction = obj.fileFilterRegexpAltCellExtraction;
			if iscell(signalExtractionMethod)
				nSignalExtractMethods = length(signalExtractionMethod);
			else
				nSignalExtractMethods = 1;
			end

			for signalExtractNo = 1:nSignalExtractMethods
				obj.signalExtractionMethod = signalExtractionMethod{signalExtractNo};

				currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
				diary([obj.logSavePath filesep currentDateTimeStr '_' obj.folderBaseSaveStr{obj.fileNum} '_' signalExtractionMethod{signalExtractNo} '.log']);
				startTime = tic;
				display(repmat('-',1,7))
				display(signalExtractionMethod{signalExtractNo})

				% set the save variable names and determine whether to skip files
				thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
				switch signalExtractionMethod{signalExtractNo}
					case 'ROI'
						% saveID = {obj.rawROItracesSaveStr};
						saveID = {obj.rawROIStructSaveStr};
						saveVariable = {'ROItraces'};
					case 'PCAICA'
						options.rawICfiltersSaveStr = '_ICfilters.mat';
						options.rawICtracesSaveStr = '_ICtraces.mat';
						% saveID = {options.rawICfiltersSaveStr,options.rawICtracesSaveStr,obj.rawPCAICAStructSaveStr};
						% saveVariable = {'IcaFilters','IcaTraces','pcaicaAnalysisOutput'};
						saveID = {obj.rawPCAICAStructSaveStr};
						saveVariable = {'pcaicaAnalysisOutput'};
					case 'EM'
						saveID = {obj.rawEMStructSaveStr};
						saveVariable = {'emAnalysisOutput'};
					case 'EXTRACT'
						saveID = {obj.rawEXTRACTStructSaveStr};
						saveVariable = {'extractAnalysisOutput'};
					case 'CNMF'
						saveID = {obj.rawCNMFStructSaveStr,'_paramSet.mat'};
						saveVariable = {'cnmfAnalysisOutput','saveParams'};
					case 'CNMFE'
						saveID = {obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod)};
						saveVariable = {obj.extractionMethodStructVarname.(obj.signalExtractionMethod)};
					otherwise
						% do nothing
				end

				% skip this analysis if files already exist
				if overwriteAnalysisFileSwitch==0
					checkSaveString = [thisDirSaveStr saveID{1}];
					if exist(checkSaveString,'file')~=0
						display('SKIPPING ANALYSIS FOR THIS FOLDER')
						continue
					end
				end

				% Check that the regular expression will find a movie, if not skip folder and notify user
				movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				if isempty(movieList)
					errorStr = sprintf('No movie found matching %s in %s.\n',fileFilterRegexp,obj.inputFolders{obj.fileNum});
					warning(errorStr)
					% s.WindowStyle = 'non-modal';
					s.Interpreter = 'tex';
					s.WindowStyle = 'replace';
					h = msgbox_custom(['\fontsize{10}' errorStr],'WARNING: cell-extraction',s);
					return;
				end

				% save temporary file to prevent file checking from starting multiple runs on the same folder
				savestring = [thisDirSaveStr saveID{1}];
				display(['saving temporary: ' savestring])
				tmpVar = 'Peace is our Profession.';
				% save(savestring,saveVariable{i},'-v7.3','emOptions');
				save(savestring,'tmpVar','-v7.3');

				switch signalExtractionMethod{signalExtractNo}
					case 'ROI'
						runROISignalFinder();
						saveRunTimes('roi');
					case 'PCAICA'
						runPCAICASignalFinder();
						saveRunTimes('pcaica');
					case 'EM'
						try
							emOptions = runCELLMaxSignalFinder();
						catch err
							fprintf('Removing temporary file: %s\n',savestring)
							delete(savestring)
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
						saveRunTimes('cellmax_v3');
						clear emOptions;
					case 'EXTRACT'
						emOptions = runEXTRACTSignalFinder();
						saveRunTimes('extract');
						clear extractAnalysisOutput;
						%
					case 'CNMF'
						[success] = cnmfVersionDirLoad(options.CNMF.originalCurrentSwitch);
						[cnmfOptions] = runCNMFSignalFinder();
						saveRunTimes('cnmf');
						clear cnmfOptions;
					case 'CNMFE'
						[success] = cnmfVersionDirLoad('cnmfe');
						[cnmfOptions] = runCNMFESignalFinder();
						saveRunTimes('cnmfe');
						clear cnmfOptions;
					otherwise
						% body
				end
				toc(startTime)
				diary OFF;
			end
			successList(end+1) = fileNum;
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
			try
				errorList(end+1) = fileNum
			catch
			end
		end
	end
	% ==========================================
	% ==========================================
	if ~isempty(successList)
		obj.foldersToAnalyze = successList;
		% add information about the extracted signals to the object for later processing
		objGuiOld = obj.guiEnabled;
		obj.guiEnabled = 0;
		obj.modelVarsFromFiles();
		obj.guiEnabled = 0;
		% obj.viewCreateObjmaps();
		if viewResultsAfter==1
			obj.viewObjmaps();
		end
		obj.guiEnabled = objGuiOld;
		try
			if ~isempty(successList)
				disp(repmat('=',1,21))
				disp(['Successful ran the following folders: ' num2str(successList)])
				disp(repmat('=',1,21))
			end
		catch
		end
	end
	if isempty(successList)|length(successList)~=nFolders
		try
			if ~isempty(errorList)
				disp(repmat('=',1,21))
				disp(['Error in the following folders: ' num2str(errorList)])
				disp('Re-run after checking below warning tips.')
				disp(repmat('=',1,21))
			end
		catch
		end
		subfxnRunWarning();
	end
	% ==========================================
	% ==========================================
	function subfxnRunWarning()
		warning([10 ...
			repmat('=',1,21) 10 ...
			'Error during cell extraction with "modelExtractSignalsFromMovie". Some tips:' 10 ...
			'- Make sure REGEXP for finding movie is correct.' 10 ...
			'- Make sure folder has files in it and is accessible to MATLAB.' 10 ...
			'- Try and avoid running cell extraction of extremely small movies (e.g. 100x100 movie with 25 frames).' 10 ...
			'- Make sure folder added with "modelAddNewFolders" points to an actual folder and not a file.' 10 ...
			'- CNMF and CNMF-E: check that they are installed under "_external_programs" folder.' 10 ...
			'- PCA-ICA: make sure there are MORE frames than PCs and ICs requested, else PCA-ICA will not run.' 10 ...
			'- ROI: make sure you have run a previous cell-extraction method.' 10 ...
			repmat('=',1,21) 10])
	end
	function getAlgorithmRootPath(algorithmFile,algorithmName,obj)
		if exist(algorithmFile,'file')~=2
			pathToAlgorithm = uigetdir('\.',sprintf('Enter path to %s root folder (e.g. from github)',algorithmName));
			if ischar(pathToAlgorithm)
				privateLoadBatchFxnsPath = obj.privateSettingsPath;
				% if exist(privateLoadBatchFxnsPath,'file')~=0
				% 	fid = fopen(privateLoadBatchFxnsPath,'at')
				% 	fprintf(fid, '\nalgorithmPath.%s = ''%s'';\n', algorithmName, pathToAlgorithm);
				% 	fclose(fid);
				% end
				pathList = genpath(pathToAlgorithm);
				pathListArray = strsplit(pathList,pathsep);
				pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep '.git']));
				pathListArray = pathListArray(pathFilter);
				cellfun(@disp,pathListArray)
				pathList = strjoin(pathListArray,pathsep);
				fprintf('Adding folders: %s\n',pathList)
				addpath(pathList);
			end
		end
	end
	function saveRunTimes(algorithm)
		% save algorithm runtimes to a CSV for later comparison

		% don't use tables if not at least Matlab R2014b
		if verLessThan('matlab', '8.4.0')
			return
		end
		runtimeTablePath = [obj.dataSavePathFixed filesep 'database_processing_runtimes_' obj.currentDateTimeSessionStr '.csv'];
		runtimeTableExists = 0;
		if exist(runtimeTablePath,'file')
			[runtimeTable] = readExternalTable(runtimeTablePath,'delimiter',',');
			addRow = size(runtimeTable,1)+1;
			% runtimeTable = table2struct(runtimeTable);
			runtimeTable.runtime_seconds(addRow,1) = toc(startTime);
			runtimeTableExists = 1;
		else
			runtimeTable = table(0,...
				{'0000.00.00'},...
				{'00:00'},...
				{'tmp'},...
				{'tmp'},...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				0,...
				{'tmp'},...
				0,...
				0,...
				0,...
				{'tmp'},...
				0,...
				'VariableNames',{...
				'runtime_seconds',...
				'date',...
				'daytime',...
				'folder',...
				'algorithm',...
				'frames',...
				'width',...
				'height',...
				'parallel',...
				'workers',...
				'minIters',...
				'maxIters',...
				'maxSqSize',...
				'maxDeltaParams',...
				'gridSpacing',...
				'gridWidth',...
				'initMethod',...
				'sqSizeX',...
				'sqSizeY',...
				'numSignalsDetected',...
				'versionAlgorithm',...
				'selectRandomFrames'})
			% runtimeTable.runtime_seconds = toc(startTime);

			addRow = size(runtimeTable,1)+1;
			% runtimeTable = table2struct(runtimeTable);
			runtimeTable.runtime_seconds(addRow,1) = toc(startTime);
			runtimeTableExists = 1;
		end

		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1,'getMovieDims',1);

		% add time and movie information
		runtimeTable.date{addRow,1} = datestr(now,'yyyy.mm.dd','local');
		runtimeTable.daytime{addRow,1} = datestr(now,'HH:MM','local');
		runtimeTable.folder{addRow,1} = obj.folderBaseSaveStr{obj.fileNum};
		runtimeTable.algorithm{addRow,1} = algorithm;
		runtimeTable.frames(addRow,1) = movieDims.z;
		runtimeTable.width(addRow,1) = movieDims.x;
		runtimeTable.height(addRow,1) = movieDims.y;

		fprintf('saving %s\n',runtimeTablePath);
		writetable(runtimeTable,runtimeTablePath,'FileType','text','Delimiter',',');
		parametersToAdd = {'minIters','maxIters','maxSqSize','maxSqSize','maxDeltaParams','gridSpacing','gridWidth','initMethod','sqSizeX','sqSizeY','numSignalsDetected','selectRandomFrames'};
		if strcmp(algorithm,'cellmax_v3')
			try
				runtimeTable.parallel(addRow,1) = emOptions.useParallel;
				runtimeTable.runtime_seconds(addRow,1) = emOptions.time.cellmaxRuntime;
			catch
				runtimeTable.parallel(addRow,1) = NaN;
			end
			runtimeTable.workers(addRow,1) = 7;
			fn_structdisp(emOptions);
			for parameterNo = 1:length(parametersToAdd)
				parameterStr = parametersToAdd{parameterNo};
				% check that parameter name exists
				% if any(strcmp(parameterStr,fieldnames(runtimeTable)))
				if isfield(emOptions.CELLMaxoptions,parameterStr)
				else
					continue
				end
				if ~isfield(runtimeTable,parameterStr)
					if isfield(emOptions.CELLMaxoptions,parameterStr)
						if ischar(emOptions.CELLMaxoptions.(parameterStr))
							runtimeTable.(parameterStr){addRow,1} = '';
						else
							runtimeTable.(parameterStr)(addRow,1) = NaN;
						end
					end
				end
				if isfield(emOptions.CELLMaxoptions,'maxSqSize')&&~isempty(emOptions.CELLMaxoptions.(parameterStr))
					if iscell(runtimeTable.(parameterStr))
						runtimeTable.(parameterStr){addRow,1} = emOptions.CELLMaxoptions.(parameterStr);
					else
						runtimeTable.(parameterStr)(addRow,1) = emOptions.CELLMaxoptions.(parameterStr);
					end
				else
					if iscell(runtimeTable.(parameterStr))
						runtimeTable.(parameterStr){addRow,1} = '';
					else
						runtimeTable.(parameterStr)(addRow,1) = NaN;
					end
				end
			end
		else
			runtimeTable.parallel(addRow,1) = NaN;
			runtimeTable.workers(addRow,1) = NaN;
			for parameterNo = 1:length(parametersToAdd)
				parameterStr = parametersToAdd{parameterNo};
				if isfield(runtimeTable,parameterStr)
					display([parameterStr ' | ' num2str(iscell(runtimeTable.(parameterStr)))])
					if iscell(runtimeTable.(parameterStr))
						runtimeTable.(parameterStr){addRow,1} = '';
					else
						runtimeTable.(parameterStr)(addRow,1) = NaN;
					end
				else
					try
						runtimeTable.(parameterStr)(addRow,1) = NaN;
					catch
						runtimeTable.(parameterStr){addRow,1} = '';
					end
				end
			end
		end

		% if runtimeTableExists==0
		% 	runtimeTable = struct2table(runtimeTable);
		% end
		writetable(runtimeTable,runtimeTablePath,'FileType','text','Delimiter',',');
	end
	function getAlgorithmOptions()
		% ==========================================
		% ==========================================
		% get options for each
		for signalExtractNo = 1:nSignalExtractMethods
			dlgStr = [signalExtractionMethod{signalExtractNo} ' cell extraction parameters'];
			switch signalExtractionMethod{signalExtractNo}
				case 'ROI'
					movieSettings = inputdlg({...
							'ROI | image threshold fraction max (0 to 1)'...
						},...
						dlgStr,1,...
						{...
							'0.5'...
						}...
					);setNo = 1;
					options.ROI.threshold = str2num(movieSettings{setNo});setNo = setNo+1;

					% signalExtractionMethodStr2 = {'PCAICA','EM','EXTRACT','CNMF'};
					signalExtractionMethodStr2 = {'EM','PCAICA','CNMF','CNMFE','EXTRACT'};

					currentIdx = find(strcmp(signalExtractionMethodStr2,obj.signalExtractionMethod));
					% signalExtractionMethodDisplayStr2 = {'PCAICA','CELLMax (Lacey)','EXTRACT (Hakan)','CNMF (Pnevmatikakis, 2015)'};
					signalExtractionMethodDisplayStr2 = {'CELLMax (Lacey/Biafra)','PCAICA (Mukamel, 2009)','CNMF (Pnevmatikakis, 2016 or Giovannucci, 2019)','CNMF-E (Zhou, 2018)','EXTRACT (Inan, 2017)'};
					[signalIdxArray2, ~] = listdlg('ListString',signalExtractionMethodDisplayStr2,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','Which signal extraction method for ROI? SELECT ONE','InitialValue',currentIdx);
					% signalIdxArray
					options.ROI.signalExtractionMethod = signalExtractionMethodStr2{signalIdxArray2};

				case 'PCAICA'
					movieSettings = inputdlg({...
							'PCAICA | output units: std, 2norm, fl, or var',...
							'PCAICA | mu parameter (0 to 1)',...
							'PCAICA | term_tol (e.g. 1e-6)',...
							'PCAICA | max_iter (int, e.g. 1e3)'...
						},...
						dlgStr,1,...
						{...
							'fl',...
							num2str(0.1),...
							num2str(5e-6),...
							num2str(1e3)...
						}...
					);setNo = 1;
					options.PCAICA.outputUnits = movieSettings{setNo};setNo = setNo+1;
					options.PCAICA.mu = str2num(movieSettings{setNo});setNo = setNo+1;
					options.PCAICA.term_tol = str2num(movieSettings{setNo});setNo = setNo+1;
					options.PCAICA.max_iter = str2num(movieSettings{setNo});setNo = setNo+1;
					options.PCAICA
				case 'EM'
					AddOpts.Resize='on';
					AddOpts.WindowStyle='normal';
					AddOpts.Interpreter='tex';
					movieSettings = inputdlgcol({...
							'CELLMax | read movie chunks from disk? (1 = yes, 0 = no)',...
							'CELLMax | fraction of total frames subset each iteration?',...
							'CELLMax | number of min iterations?',...
							'CELLMax | number of max iterations?',...
							'CELLMax | gridSpacing? (leave blank for manual)',...
							'CELLMax | gridWidth? (leave blank for manual)',...
							'CELLMax | max square tile size?',...
							'CELLMax | percent frames for PCA-ICA?',...
							'CELLMax | use GPU? (1 = yes, 0 = no)',...
							'CELLMax | subsample method (random, resampleRemaining)?',...
							'CELLMax | sizeThresh?',...
							'CELLMax | sizeThreshMax?',...
							'CELLMax | areaOverlapThresh?',...
							'CELLMax | removeCorrProbs?',...
							'CELLMax | distanceThresh?',...
							'CELLMax | corrRemovalAreaOverlapThresh?',...
							'CELLMax | threshForElim? (elimination threshold scaled phi?)',...
							'CELLMax | scaledPhiCorrThresh?',...
							'CELLMax | runMovieImageCorrThreshold?',...
							'CELLMax | movieImageCorrThreshold?',...
							'CELLMax | loadPreviousChunks?',...
							'CELLMax | saveIterMovie?',...
							'CELLMax | sqOverlap?',...
							'CELLMax | downsampleFactorTime?',...
							'CELLMax | downsampleFactorSpace?',...
							'CELLMax | spatialFilterMovie (0 = no, 1 = yes, after loading)?',...
							'CELLMax | useSparseImageMatrix (0 = no, 1 = yes)?',...
							'CELLMax | exitEarlySaveSparse (0 = no, 1 = yes)?',...
							'CELLMax | numFramesSampleFitNoiseSigma (Int, frames)?',...
							'CELLMax | recalculateFinalTraces (0 = no, 1 = yes)?',...
							'CELLMax | dsInitializeThreshold (Float, range 0:1)?',...
							'CELLMax | numSigmasThresh (Float)?',...
							'CELLMax | numPhotonsPerSigma (Int)?',...
							'CELLMax | upsampleFullIters (Int)?',...
							'CELLMax | removeAutoCorrThres (Float, range 0:1)?',...
						},...
						dlgStr,1,...
						{...
							'1',...
							'0.3',...
							'50',...
							'120',...
							'',...
							'',...
							'101',...
							'0.5',...
							'0',...
							'random',...
							'5',...
							'250',...
							'0.65',...
							'1',...
							'3',...
							'0.3',...
							'0.005',...
							'0.3',...
							'1',...
							'0.15',...
							'0',...
							'0',...
							'16',...
							'1',...
							'1',...
							'0',...
							'0',...
							'0',...
							'1000',...
							'1',...
							'0.01',...
							'0',...
							'10',...
							'2',...
							'0.65'...
						},AddOpts,2);
					setNo = 1;
					options.CELLMax.readMovieChunks = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.percentFramesPerIteration = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.minIters = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.maxIters = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.gridSpacing = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.gridWidth = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.maxSqSize = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.percentFramesPCAICA = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.useGPU = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.subsampleMethod = movieSettings{setNo};setNo = setNo+1;

					options.CELLMax.sizeThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.sizeThreshMax = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.areaOverlapThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.removeCorrProbs = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.distanceThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.corrRemovalAreaOverlapThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.threshForElim = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.scaledPhiCorrThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.runMovieImageCorrThreshold = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.movieImageCorrThreshold = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.loadPreviousChunks = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.saveIterMovie = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.sqOverlap = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.downsampleFactorTime = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.downsampleFactorSpace = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.spatialFilterMovie = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.useSparseImageMatrix = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.exitEarlySaveSparse = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.numFramesSampleFitNoiseSigma = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.recalculateFinalTraces = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.dsInitializeThreshold = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.numSigmasThresh = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.numPhotonsPerSigma = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.upsampleFullIters = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CELLMax.removeAutoCorrThres = str2num(movieSettings{setNo});setNo = setNo+1;

				case 'EXTRACT'
					movieSettings = inputdlg({...
							'EXTRACT | Use GPU (''gpu'') or CPU (''cpu'')?',...
							'EXTRACT | avg_cell_radius (Avg. cell radius, also controls cell elimination)? Leave blank for GUI to estimate radius.',...
							'EXTRACT | cellfind_min_snr (threshold on the max instantaneous per-pixel SNR in the movie for searching for cells)?',...
							'EXTRACT | preprocess? (1 = yes, 0 = no)',...
							'EXTRACT | num_partitions? Int: number of partitions in x and y.',...
							'EXTRACT | compact_output? (1 = yes, 0 = no)'...
						},...
						dlgStr,1,...
						{...
							'cpu',...
							'',...
							'2'...
							'0',...
							'1',...
							'0',...
						}...
					);setNo = 1;
					options.EXTRACT.gpuOrCPU = movieSettings{setNo};setNo = setNo+1;
					options.EXTRACT.avg_cell_radius = str2num(movieSettings{setNo});setNo = setNo+1;
					options.EXTRACT.cellfind_min_snr = str2num(movieSettings{setNo});setNo = setNo+1;
					options.EXTRACT.preprocess = str2num(movieSettings{setNo});setNo = setNo+1;
					options.EXTRACT.num_partitions_x = str2num(movieSettings{setNo});setNo = setNo+1;
					options.EXTRACT.num_partitions_y = options.EXTRACT.num_partitions_x;
					options.EXTRACT.compact_output = str2num(movieSettings{setNo});setNo = setNo+1;

				case 'CNMF'
					movieSettings = inputdlg({...
							'CNMF | Use original ("original") or most recent ("current" or "current_patch" for patch version) CNMF version?'...
							'CNMF | save each parameter run to new directory? (1 = yes, 0 = no)',...
							'CNMF | iterate over parameter space? (1 = yes, 0 = no)',...
							'CNMF | only run initialization algorithm? (1 = yes, 0 = no)',...
							'CNMF | Spatial down-sampling factor (scalar >= 1)',...
							'CNMF | Temporal down-sampling factor (scalar >= 1)',...
							'CNMF | Movie frame rate (scalar >= 1)',...
							'CNMF | Create a memory mapped file if it is not provided in the input (1 = yes, 0 = no)',...
							'CNMF | Patch size (power of 2 pref, e.g. 64, 128, 256, 512)',...
							'CNMF | Patch overlap size (power of 2 pref, e.g. 4, 8, 16, 32)',...
							'CNMF | tau (enter cell diameter in pixels)',...
							'CNMF | Run CNMF output classifier (1 = yes, 0 = no)',...
							'CNMF | initialization method ("greedy","greedy_corr","sparse_NMF","HALS") (default: "greedy")',...
						},...
						dlgStr,1,...
						{...
							'current',...
							'0',...
							'0',...
							'0',...
							'1',...
							'1',...
							num2str(obj.FRAMES_PER_SECOND),...
							'0',...
							'[128,128]',...
							'[16, 16]',...
							'',...
							'1',...
							'greedy'...
						}...
					);setNo = 1;
					options.CNMF.originalCurrentSwitch = movieSettings{setNo};setNo = setNo+1;
					options.CNMF.saveEachRunNewDirSwitch = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.iterateOverParameterSpace = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.onlyRunInitialization = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.ssub = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.tsub = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.fr = str2num(movieSettings{setNo});setNo = setNo+1; obj.FRAMES_PER_SECOND = options.CNMF.fr;
					options.CNMF.create_memmap = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.patch_size = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.overlap = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.gridWidth = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.classifyComponents = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMF.init_method = movieSettings{setNo};setNo = setNo+1;
				case 'CNMFE'
					movieSettings = inputdlg({...
							'CNMF-E | Edit all settings in text file? 1 = opens up Matlab editor. 2 = select file to load.',...
							'CNMF-E | delete temporary CNMF-E folder? (1 = yes, 0 = no)',...
							'CNMF-E | Use CNMF-F ("cnmfe"), original ("original"), or most recent ("current") CNMF version?'...
							'CNMF-E | save each parameter run to new directory? (1 = yes, 0 = no)',...
							'CNMF-E | iterate over parameter space? (1 = yes, 0 = no)',...
							'CNMF-E | only run initialization algorithm? (1 = yes, 0 = no)',...
							'CNMF-E | Spatial down-sampling factor (scalar >= 1)',...
							'CNMF-E | Temporal down-sampling factor (scalar >= 1)'...
						},...
						dlgStr,1,...
						{...
							'1',...
							'1',...
							'cnmfe',...
							'0',...
							'0',...
							'0',...
							'1',...
							'1'...
						}...
					);setNo = 1;
					options.CNMFE.openEditor = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.deleteTempFolders = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.originalCurrentSwitch = movieSettings{setNo};setNo = setNo+1;
					options.CNMFE.saveEachRunNewDirSwitch = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.iterateOverParameterSpace = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.onlyRunInitialization = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.ssub = str2num(movieSettings{setNo});setNo = setNo+1;
					options.CNMFE.tsub = str2num(movieSettings{setNo});setNo = setNo+1;

					if options.CNMFE.deleteTempFolders==1
						display(repmat('*',1,21))
						nFolders = length(fileIdxArray);
						for thisFileNumIdx = 1:length(fileIdxArray)
							fileNum = fileIdxArray(thisFileNumIdx);
							rmDirFolders = getFileList(obj.inputFolders{fileNum},'_source_extraction');
							fclose all;
							if ~isempty(rmDirFolders)
								% Delete temporary folder.
								for zz = 1:length(rmDirFolders)
									fprintf('Deleting temporary folder: %s\n',rmDirFolders{zz})
									status = rmdir(rmDirFolders{zz},'s')
								end
							end
						end
						display(repmat('*',1,21))
					end

					if options.CNMFE.openEditor==1||options.CNMFE.openEditor==2
						if options.CNMFE.openEditor==1
							% Use default settings
							originalSettings = ['settings' filesep 'cnmfeSettings.m'];
						else
							% Ask user to input their own custom settings
							display('Dialog box: Select CNMF-E settings file to load.')
							[filePath,folderPath,~] = uigetfile([pwd filesep '*.*'],'Select settings file to load.');
							% [~,fileNameH,extH] = fileparts([folderPath filePath]);
							% fileNameH = strrep(fileNameH,'cnmfeSettings_','');
							originalSettings = [folderPath filesep filePath];
						end

						[~,foldername,~] = fileparts(obj.inputFolders{obj.fileNum});
						timeStr = datestr(now,'yyyymmdd_HHMMSS','local');
						newFile = ['cnmfeSettings_' timeStr '_' foldername];

						% Truncate to deal with MATLAB limit
						if (length(newFile)+2)>namelengthmax
							fprintf('Truncating filename to comply with maximum file length limits in MATLAB.\nOld: "%s"\nNew: "%s"\n\n',newFile,newFile(1:namelengthmax-2));
							newFile = newFile(1:namelengthmax-2);
						end

						% Make sure contains valid name so MATLAB can run m-file code later.
						% newFile = strrep(newFile,'-','_');
                        newFile = matlab.lang.makeValidName(newFile);

						newSettings = ['private' filesep 'settings' filesep newFile '.m'];

						fprintf('Copying "%s" to\n"%s"\n\n',originalSettings,newSettings);
						copyfile(originalSettings,newSettings);

						% Add a note about original filename
						fileID = fopen(newSettings);
						fileText = textscan(fileID,'%s','Delimiter','\n','CollectOutput',true);
						fclose(fileID);
						fileID = fopen(newSettings,'w');
						fileText{1}{end+1} = ['% From original settings file: ' originalSettings];
						fileText{1} = fileText{1}([end,1:end-1]);
						for rowNo = 1:length(fileText{1})
							fprintf(fileID,'%s\n',fileText{1}{rowNo});
						end
						fclose(fileID);

						h1 = matlab.desktop.editor.openDocument([pwd filesep newSettings]);
						disp(['Close "' newFile '.m" file in Editor to continue!'])
						% pause while user edits
						while h1.Opened==1;end
						h1.close
						% Use editor API
						%a1 = matlab.desktop.editor.getAll;
						% Close the most recently open document
						%a1(end).close

						options.CNMFE.settingsFile = newSettings;
					else
						options.CNMFE.settingsFile = [];
					end
					disp(['Using settings file: ' options.CNMFE.settingsFile])
				otherwise
					% body
			end
		end
	end
	function runROISignalFinder()
		% Use other algorithms to get an extracted ROI trace
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		[inputMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList,'convertToDouble',0,'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);
		obj.signalExtractionMethod = options.ROI.signalExtractionMethod;
		obj.guiEnabled = 0;
		obj.modelVarsFromFiles();
		obj.guiEnabled = 0;
		[inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
		obj.signalExtractionMethod = 'ROI';
		options.ROI.threshold
		[ROItraces] = applyImagesToMovie(inputImages,inputMovie,'threshold',options.ROI.threshold);
		[figHandle figNo] = openFigure(1, '');
			ROItracesTmp = ROItraces;
			ROItracesTmp(ROItracesTmp<0.1) = 0;
			imagesc(ROItracesTmp);
			ylabel('filter number');xlabel('frame');
			colormap(obj.colormap);colorbar;
			title(obj.fileIDNameArray{obj.fileNum})
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 30 10])
			obj.modelSaveImgToFile([],'ROItraces_','current',obj.fileIDArray{obj.fileNum});

		tracesSaveDimOrder = '[signalNo frameNo]';

		roiAnalysisOutput.traces = ROItraces;
		roiAnalysisOutput.filters = inputImages;
		roiAnalysisOutput.signalExtractionMethod = obj.signalExtractionMethod;

		clear inputMovie inputImages;
		% =======
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i},'tracesSaveDimOrder','roiAnalysisOutput','-v7.3');
		end
		% =======
	end
	function runPCAICASignalFinder()
		switch pcaicaPCsICsSwitchStr
			case 'Subject'
				nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum})
			case 'Folder'
				nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{obj.fileNum}
			otherwise
				% body
		end
		% return;

		nPCs = nPCsnICs(1);
		nICs = nPCsnICs(2);
		%
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		% [inputMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',[]);

		if oldPCAICA==1
			display('running PCA-ICA, old version...')
			[PcaFilters PcaTraces] = runPCA(movieList, '', nPCs, fileFilterRegexp,'inputDatasetName',obj.inputDatasetName);
			if isempty(PcaFilters)
				display('PCs are empty, skipping...')
				return;
			end
			[IcaFilters IcaTraces] = runICA(PcaFilters, PcaTraces, '', nICs, '');
			traceSaveDimOrder = '[nComponents frames]';
			% reorder if needed
			options.IcaSaveDimOrder = 'xyz';
			if strcmp(options.IcaSaveDimOrder,'xyz')
				IcaFilters = permute(IcaFilters,[2 3 1]);
				imageSaveDimOrder = 'xyz';
			else
				imageSaveDimOrder = 'zxy';
			end
		else
			display('running PCA-ICA, new version...')
			[PcaOutputSpatial PcaOutputTemporal PcaOutputSingularValues PcaInfo] = run_pca(movieList, nPCs, 'movie_dataset_name',obj.inputDatasetName);

			if isempty(PcaOutputTemporal)
				display('PCs are empty, skipping...')
				return;
			end

			display('+++')
			movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1,'getMovieDims',1);

			% output_units = 'fl';
			% output_units = 'std';
			% options.PCAICA.term_tol = 5e-6;
			% options.PCAICA.max_iter = 1e3;
			[IcaFilters, IcaTraces, IcaInfo] = run_ica(PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, movieDims.x, movieDims.y, nICs, 'output_units',options.PCAICA.outputUnits,'mu',options.PCAICA.mu,'term_tol',options.PCAICA.term_tol,'max_iter',options.PCAICA.max_iter);
			IcaTraces = permute(IcaTraces,[2 1]);
			traceSaveDimOrder = '[nComponents frames]';
			% reorder if needed
			options.IcaSaveDimOrder = 'xyz';
			if strcmp(options.IcaSaveDimOrder,'xyz')
				imageSaveDimOrder = 'xyz';
			else
				IcaFilters = permute(IcaFilters,[3 1 2]);
				imageSaveDimOrder = 'zxy';
			end
			pcaicaAnalysisOutput.IcaInfo = IcaInfo;
		end


		pcaicaAnalysisOutput.IcaFilters = IcaFilters;
		pcaicaAnalysisOutput.IcaTraces = IcaTraces;
		pcaicaAnalysisOutput.imageSaveDimOrder = imageSaveDimOrder;
		pcaicaAnalysisOutput.traceSaveDimOrder = traceSaveDimOrder;
		pcaicaAnalysisOutput.nPCs = nPCs;
		pcaicaAnalysisOutput.nICs = nICs;
		pcaicaAnalysisOutput.time.startTime = startTime;
		pcaicaAnalysisOutput.time.endTime = toc(startTime);
		pcaicaAnalysisOutput.time.dateTime = datestr(now,'yyyymmdd_HHMM','local');
		pcaicaAnalysisOutput.movieList = movieList;
		% =======
		% save ICs
		saveOutput = 1;
		if saveOutput==1
			for i=1:length(saveID)
				savestring = [thisDirSaveStr saveID{i}];
				display(['saving: ' savestring])
				save(savestring,saveVariable{i},'','-v7.3');
			end
		end
		% =======
	end
	% function [emOptions] = runEMSignalFinder()
	function [emOptions] = runCELLMaxSignalFinder()
		% emOptions.dsMovieDatasetName = options.datasetName;
		% emOptions.movieDatasetName = options.datasetName;
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);

		% The second upsampled movie if there is one
		movieListAlt = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexpAltCellExtraction);

		% movieFilename=[];
		% upsampledMovieList = getFileList(thisDir, fileFilterRegexp);
		% mpiprofile on
		% emOptions.CELLMaxoptions = emOptions.EMoptions;
		display(['input movie: ' movieList{1}])

		% =====================
		clear emOptions;

		if strcmp(options.CELLMax.initMethod,'grid')
			emOptions.CELLMaxoptions.initMethod = 'grid';
		elseif strcmp(options.CELLMax.initMethod,'ica')
			emOptions.CELLMaxoptions.initMethod='ica';
		end
		emOptions.CELLMaxoptions.gridSpacing = gridSpacing.(obj.subjectStr{obj.fileNum});
		emOptions.CELLMaxoptions.gridWidth = gridWidth.(obj.subjectStr{obj.fileNum});
		if ~isempty(options.CELLMax.gridSpacing)
			emOptions.CELLMaxoptions.gridSpacing = options.CELLMax.gridSpacing;
			emOptions.CELLMaxoptions.gridWidth = options.CELLMax.gridWidth;
		end
		emOptions.useParallel = options.useParallel;
		emOptions.CELLMaxoptions.inputSizeManual = 0;

		emOptions.CELLMaxoptions.subsampleMethod = options.CELLMax.subsampleMethod;

		% [maxIters nMovieFrames]
		% options.subsampleFrameMatrix = [];
		% [1 nMovieFrames] - vector of frames to use in a movie
		% options.subsampleFrameVector = [];
		% options.selectRandomFrames=1;
		% options.numFramesRandom=2000;
		% 0 to 1, percentage of frames per iteration to select
		emOptions.CELLMaxoptions.percentFramesPerIteration = options.CELLMax.percentFramesPerIteration;
		% subsampleMethod = 'resampleRemaining', fr
		emOptions.CELLMaxoptions.percentRemainingSubsample = 1;
		emOptions.CELLMaxoptions.maxSqSize = options.CELLMax.maxSqSize;
		emOptions.CELLMaxoptions.sqOverlap = options.CELLMax.sqOverlap;
		emOptions.CELLMaxoptions.percentFramesPCAICA = options.CELLMax.percentFramesPCAICA;
		emOptions.CELLMaxoptions.useGPU = options.CELLMax.useGPU;

		emOptions.CELLMaxoptions.sizeThresh = options.CELLMax.sizeThresh;
		emOptions.CELLMaxoptions.sizeThreshMax = options.CELLMax.sizeThreshMax;
		emOptions.CELLMaxoptions.areaOverlapThresh = options.CELLMax.areaOverlapThresh;
		emOptions.CELLMaxoptions.removeCorrProbs = options.CELLMax.removeCorrProbs;
		emOptions.CELLMaxoptions.distanceThresh = options.CELLMax.distanceThresh;
		emOptions.CELLMaxoptions.corrRemovalAreaOverlapThresh = options.CELLMax.corrRemovalAreaOverlapThresh;
		emOptions.CELLMaxoptions.threshForElim = options.CELLMax.threshForElim;
		emOptions.CELLMaxoptions.scaledPhiCorrThresh = options.CELLMax.scaledPhiCorrThresh;
		emOptions.CELLMaxoptions.runMovieImageCorrThreshold = options.CELLMax.runMovieImageCorrThreshold;
		emOptions.CELLMaxoptions.movieImageCorrThreshold = options.CELLMax.movieImageCorrThreshold;
		emOptions.CELLMaxoptions.removeAutoCorrThres = options.CELLMax.removeAutoCorrThres;

		emOptions.CELLMaxoptions.loadPreviousChunks = options.CELLMax.loadPreviousChunks;

		emOptions.CELLMaxoptions.numSigmasThresh = options.CELLMax.numSigmasThresh;
		emOptions.CELLMaxoptions.numPhotonsPerSigma = options.CELLMax.numPhotonsPerSigma;

		emOptions.CELLMaxoptions.downsampleFactorTime = options.CELLMax.downsampleFactorTime;
		emOptions.CELLMaxoptions.downsampleFactorSpace = options.CELLMax.downsampleFactorSpace;
		emOptions.CELLMaxoptions.dsInitializeThreshold = options.CELLMax.dsInitializeThreshold;
		emOptions.CELLMaxoptions.upsampleFullIters = options.CELLMax.upsampleFullIters;

		emOptions.CELLMaxoptions.spatialFilterMovie = options.CELLMax.spatialFilterMovie;

		emOptions.CELLMaxoptions.useSparseImageMatrix = options.CELLMax.useSparseImageMatrix;
		emOptions.CELLMaxoptions.exitEarlySaveSparse = options.CELLMax.exitEarlySaveSparse;
		emOptions.CELLMaxoptions.numFramesSampleFitNoiseSigma = options.CELLMax.numFramesSampleFitNoiseSigma;
		emOptions.CELLMaxoptions.recalculateFinalTraces = options.CELLMax.recalculateFinalTraces;

		if options.defaultOptions==0
			emOptions.CELLMaxoptions.localICimgs = [];
			emOptions.CELLMaxoptions.localICtraces = [];
			emOptions.CELLMaxoptions.minIters = options.CELLMax.minIters;
			emOptions.CELLMaxoptions.maxIters = options.CELLMax.minIters;
			emOptions.CELLMaxoptions.inputSizeManual = 0;
			emOptions.CELLMaxoptions.numSigmasThresh = 0.5;
			emOptions.CELLMaxoptions.nParallelWorkers = options.numWorkers;
			emOptions.CELLMaxoptions.generateNovelSeed = 1;
			% emOptions.CELLMaxoptions.randNumGenSeed = 2;
			movieDims = loadMovieList(movieList{1},'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
			emOptions.CELLMaxoptions.numFramesRandom = round(movieDims.z*options.CELLMax.percentFramesPerIteration);
			if emOptions.CELLMaxoptions.numFramesRandom<3e3
				emOptions.CELLMaxoptions.numFramesRandom = 3e3;
			end
			emOptions.CELLMaxoptions.readMovieChunks = options.CELLMax.readMovieChunks;
		end

		emOptions.movieDatasetName = obj.inputDatasetName;
		emOptions.CELLMaxoptions.movieFilename = movieList{1};
		if isempty(movieListAlt)
			emOptions.movieFilenameAlt = '';
		else
			emOptions.movieFilenameAlt = movieListAlt{1};
		end
		% =====================

		fn_structdisp(emOptions);

		if options.profiler==1
			currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
			profilerSaveLocation = [obj.inputFolders{obj.fileNum} filesep 'profilerCELLMax_' currentDateTimeStr];
			display(['Profiler will be saved to: ' profilerSaveLocation])
			profile on
		end

		[emAnalysisOutput, ~] = CELLMax_Wrapper(movieList{1},'options',emOptions);

		if options.profiler==1
			profile off
			profsave(profile('info'),profilerSaveLocation);
		end
		% [emAnalysisOutput, ~] = EM_CellFind_Wrapper(movieList{1},[],'options',emOptions);
		% emOptions.CELLMaxoptions.sqSizeX = NaN;
		% emOptions.CELLMaxoptions.sqSizeY = NaN;

		emOptions.CELLMaxoptions.sqSizeX = [];
		emOptions.CELLMaxoptions.sqSizeY = [];
		% emAnalysisOutput.dsCellTraces = emAnalysisOutput.cellTraces;
		% emOptions.CELLMaxoptions.numSignalsDetected = size(emAnalysisOutput.dsCellTraces,1);
		emOptions.CELLMaxoptions.numSignalsDetected = size(emAnalysisOutput.cellTraces,1);
		emOptions.versionCellmax = emAnalysisOutput.versionCellmax;
		% emOptions.EMoptions = emOptions.CELLMaxoptions;
		% mpiprofile off
		% mpiprofile viewer
		% pause

		% output.cellImages : images representing sources found (candidate cells). not all will be cells. Size is [x y numCells]
		% output.centroids : centroids of each cell image, x (horizontal) and then y (vertical). Size is [numCells 2]
		% output.convexHulls : convex hull (line tracing around edge) of each cell, in x then y. Cell Array, Size is [numCells 1], each entry is hull of one cell.
		% output.dsEventTimes : event timings on the down sampled probability traces.
		% output.dsScaledProbabilities : a scaled probability trace for each cell, from the downsampled movie. Can be used as a denoised fluorescence trace.
		% output.dsCellTraces : fluorescence traces for each cell, from the temporally downsampled movie. Size is [numCells numFrames] for numFrames of downsampled movie
		% output.cellTraces : fluorescence traces for each cell, from the full temporal resolution movie. Size is [numCells numFrames] for numFrames of full movie
		% output.eventTimes : event timings as output by detectEvents.
		% output.EMoptions : options that EM was run with. Good to keep for recordkeeping purposes.

		emOptions.time.startTime = startTime;
		emOptions.time.endTime = toc(startTime);
		emOptions.time.cellmaxRuntime = emAnalysisOutput.runtime;
		try
			emOptions.time.cellmaxRuntime = emAnalysisOutput.runtimeWithIO;
		catch
		end
		emAnalysisOutput

		% =======
		% save output components
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i},'-v7.3','emOptions');
			% save(savestring,saveVariable{i},'emOptions');
		end
		% =======
	end
	function [extractAnalysisOutput] = runEXTRACTSignalFinder()
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		[inputMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList,'convertToDouble',0,'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);
		inputMovie(isnan(inputMovie)) = 0;

		% opts.movie_dataset = obj.inputDatasetName;
		% % opts.save_to_movie_dir = 1;
		% % % make larger if using 2x downsampled movie
		% % opts.spat_linfilt_halfwidth = 2;
		% % opts.ss_cell_size_threshold = 5;
		% % opts.spat_medfilt_enabled = 0;
		% % opts.trim_pixels = 0.4;
		% % opts.verbos = 2;
		% % opts.disableGPU = 1;

		% % options.turboreg = getFxnSettings();
		% % options.turboreg
		% % options.datasetName = options.turboreg.datasetName;

		% % settingDefaults = struct(...
		% %     'movie_dataset',{{'/1','/Movie','/movie'}},...
		% %     'save_to_movie_dir',  {{1,0}},...
		% %     'spat_linfilt_halfwidth', {{2,5}},...
		% %     'ss_cell_size_threshold', {{5,10}},...
		% %     'spat_medfilt_enabled', {{0,1}},...
		% %     'trim_pixels', {{0.4,0.6}},...
		% %     'verbos', {{0,1}},...
		% %     'disableGPU', {{1,0}}...
		% % );
		% % settingStr = struct(...
		% %     'movie_dataset',{{'/1','/Movie','/movie'}},...
		% %     'save_to_movie_dir',  {{1,0}},...
		% %     'spat_linfilt_halfwidth', {{2,5}},...
		% %     'ss_cell_size_threshold', {{5,10}},...
		% %     'spat_medfilt_enabled', {{0,1}},...
		% %     'trim_pixels', {{0.4,0.6}},...
		% %     'verbos', {{0,1}},...
		% %     'disableGPU', {{1,0}}...
		% % );

		% [h,w,t] = size(inputMovie);

		% opts.max_cell_radius=30;
		% opts.min_cell_spacing=5;
		% opts.remove_duplicate_cells = 0;
		% % Use GPU
		% opts.compute_device='gpu';

		% % This is how to call the function 'partition_helper()' to find out how many partitions are necessary:
		% num_parts = partition_helper(h,w,t,opts.min_cell_spacing,opts.max_cell_radius);

		% % Below call returned num_parts=20. We decide to partition x axis to 4, and y axis to 5. This makes 20 parititions overall.
		% nPlotsRoot = sqrt(num_parts);
		% if nPlotsRoot<2
		% 	nPlotsRoot = 2;
		% end
		% integ = fix(nPlotsRoot);
		% fract = abs(nPlotsRoot - integ);
		% opts.num_partition_y = ceil(nPlotsRoot);
		% opts.num_partition_x = floor(nPlotsRoot)+round(fract)

		% min_cell_spacing=3;
		% max_cell_radius=10;
		% num_partition_x=3;
		% num_partitiony=3;
		% cell_keep_tolerance=5;
		% subtract_background=1;

		% opts.config.diffuse_F=1;
		% opts.config.smooth_T = 0;
		% opts.config.smooth_F = 0;
		% opts.config.cell_keep_tolerance

		% [filters,traces,info,opts] = extractor(movieList{1},opts);
		% [filters,traces,info,opts] = extractor(inputMovie,opts);
		% outStruct = extractor(inputMovie,opts);

		% switch pcaicaPCsICsSwitchStr
		% 	case 'Subject'
		% 		nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum})
		% 	case 'Folder'
		% 		nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{obj.fileNum}
		% 	otherwise
		% 		% body
		% end
		% extractConfig.num_estimated_cells = nPCsnICs(1);

		extractConfig.avg_cell_radius = gridWidth.(obj.subjectStr{obj.fileNum});
		extractConfig.preprocess = options.EXTRACT.preprocess;
		switch options.EXTRACT.gpuOrCPU
			case 'gpu'
				extractConfig.use_gpu = 1;
			case 'cpu'
				extractConfig.use_gpu = 0;
				extractConfig.parallel_cpu = 1;
			otherwise
				% body
		end
		extractConfig.remove_static_background = false;
		extractConfig.skip_dff = true;

		% extractConfig.cellfind_min_snr = options.EXTRACT.cellfind_min_snr;
		% extractConfig.num_partitions_x = options.EXTRACT.num_partitions_x;
		% extractConfig.num_partitions_y = options.EXTRACT.num_partitions_y;
		% extractConfig.compact_output = options.EXTRACT.compact_output;

		% extractConfig.thresholds.T_min_snr = 3; % multiply with noise_std
		% extractConfig.thresholds.size_lower_limit = 1/5; % multiply with avg_cell_area
		% extractConfig.thresholds.size_upper_limit = 5; % multiply with avg_cell_area
		% extractConfig.thresholds.temporal_corrupt_thresh = 0.7;
		% extractConfig.thresholds.spatial_corrupt_thresh = 0.7;
		% extractConfig.thresholds.T_dup_corr_thresh = 0.95;
		% extractConfig.thresholds.S_dup_corr_thresh = 0.95;
		% extractConfig.thresholds.eccent_thresh = 6; % set to inf if dendrite aware
		% extractConfig.thresholds.low_ST_index_thresh = 1e-2;
		% extractConfig.thresholds.high_ST_index_thresh = 0.8;


		startTime = tic;
		outStruct = extractor(inputMovie,extractConfig);
		outStruct

		% im_dup_corr_thresh = 0.05; % Image correlation threshold
		% trace_dup_corr_thresh = 0.6; % Trace correlation threshold
		% outStruct = remove_duplicates(outStruct,im_dup_corr_thresh,trace_dup_corr_thresh);

		extractAnalysisOutput.filters = outStruct.spatial_weights;
		% permute so it is [nCells frames]
		extractAnalysisOutput.traces = permute(outStruct.temporal_weights, [2 1]);
		extractAnalysisOutput.info = outStruct.info;
		extractAnalysisOutput.config = outStruct.config;
		extractAnalysisOutput.info = outStruct.info;
		% Remove the large summary field since takes up unnecessary space
		extractAnalysisOutput.info.summary = [];
		extractAnalysisOutput.file = movieList{1};
		extractAnalysisOutput.userInputConfig = extractConfig;
		% for backwards compatibility
		extractAnalysisOutput.opts = outStruct.config;
		extractAnalysisOutput.time.startTime = startTime;
		extractAnalysisOutput.time.endTime = tic;
		extractAnalysisOutput.time.totalTime = toc(startTime);

		% =======
		% save EXTRACT signals
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			% save(savestring,saveVariable{i},'-v7.3','emOptions');
			save(savestring,saveVariable{i},'-v7.3');
		end
		% =======
	end
	function [cnmfOptions] = runCNMFSignalFinder()

		% Check CVX is installed and if not, setup.
		runCvxSetup();

		% Get the number of cells that should be requested
		switch pcaicaPCsICsSwitchStr
			case 'Subject'
				nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum})
				nPCsnICs = nPCsnICs(1);
			case 'Folder'
				nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{obj.fileNum}
				nPCsnICs = nPCsnICs(1);
			otherwise
				% body
		end

		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);

		% Y = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);

		% whether to use parallel processing
		% cnmfOptions.use_parallel = 1;
		cnmfOptions.nonCNMF.parallel = 1;
		cnmfOptions.nonCNMF.inputDatasetName = obj.inputDatasetName;

		% initialization method ('greedy','greedy_corr','sparse_NMF','HALS') (default: 'greedy')
		cnmfOptions.init_method = options.CNMF.init_method;

		% Merging threshold (positive between 0  and 1)
		cnmfOptions.merge_thr = 0.85;
		% Range of normalized frequencies over which to average PSD (2 x1 vector)
		cnmfOptions.noise_range = [0.10,0.6];
		% Size of 2-d median filter (2 x 1 array of positive integers)
		cnmfOptions.medw = [2,2];
		% cnmfOptions.medw = [3,3];
		% Energy threshold (positive between 0 and 1)
		% cnmfOptions.nrgthr = 0.97;
		cnmfOptions.nrgthr = 0.85;
		% Morphological closing operator for post-processing (binary image)
		cnmfOptions.clos_op = strel('disk',3,0);
		% Flag for computing noise values sequentially for memory reasons
		cnmfOptions.split_data = 0;
		% Spatial down-sampling factor (scalar >= 1)
		cnmfOptions.ssub = options.CNMF.ssub;
		% Temporal down-sampling factor (scalar >= 1)
		cnmfOptions.tsub = options.CNMF.tsub;
		% Maximum number of sparse NMF iterations
		cnmfOptions.snmf_max_iter = 200;
		% Weight on squared L1 norm of spatial components
		cnmfOptions.beta = 0.5;
		% Weight on frobenius norm of temporal components * max(Y)^2
		cnmfOptions.eta = 1;
		% Relative change threshold for stopping sparse_NMF
		cnmfOptions.err_thr = 1e-4; %1e-5
		% Maximum number of HALS iterations
		cnmfOptions.maxIter = 5;
		% Expansion factor for HALS localized updates
		cnmfOptions.bSiz = 3; %1e-5
		% imaging frame rate in Hz (defaut: 30)
		cnmfOptions.fr = options.CNMF.fr;
		% create a memory mapped file if it is not provided in the input (default: false)
		cnmfOptions.create_memmap = options.CNMF.create_memmap;

		% Standard deviation of Gaussian kernel for initialization
		% cnmfOptions.otherCNMF.tau = 9;
		cnmfOptions.otherCNMF.tau = gridWidth.(obj.subjectStr{obj.fileNum})/2;
		% cnmfOptions.otherCNMF.tau = [3 2 1; 3 2 1]';
		% Order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
		cnmfOptions.otherCNMF.p = 2;


		if options.CNMF.onlyRunInitialization==1
			% run only initialization algorithm
			cnmfOptions.nonCNMF.onlyRunInitialization = 1;
		else
			% run only initialization algorithm
			cnmfOptions.nonCNMF.onlyRunInitialization = 0;
		end

		% set of parameters to vary
		if options.CNMF.iterateOverParameterSpace==1
			paramSet = paramSetMaster;
		else
			paramSet.beta = {0.1};
			paramSet.maxIter = {5};
			paramSet.bSiz = {1};
		end

		% make a list of all possible combinations
		paramNames = fieldnames(paramSet);
		nParams = length(paramNames);
		paraSpace = [];
		paramStr = 'paraSpace = combvec(';
		for paramNo = 1:nParams
			paramStr = [paramStr '1:' num2str(length(paramSet.(paramNames{paramNo})))];
			if paramNo~=nParams
				paramStr = [paramStr ','];
			end
		end
		paramStr = [paramStr ');'];
		eval(paramStr);

		for paramNo = 1:nParams
			paramIdx = paraSpace(paramNo,:);
			paramSet.(paramNames{paramNo}) = paramSet.(paramNames{paramNo})(paramIdx(:));
		end
		% [p,q,r] = meshgrid(1:length(paramSet.merge_thr),1:length(paramSet.noise_range),1:length(paramSet.nrgthr));
		% paraSpace = [p(:) q(:) r(:)];
		% paraSpace = combvec(1:2,1:4,1:3);
		% paramSet.merge_thr = paramSet.merge_thr(p(:));
		% paramSet.noise_range = paramSet.noise_range(q(:));
		% paramSet.nrgthr = paramSet.nrgthr(r(:));

		% paramSet.tau = {};
		% paramSet.p = {};
		nParameterSets = size(paraSpace,2);
		% decide whether to iterate over new parameters
		iterateParameters = 0;
		saveParams.null = 1;

		if iterateParameters==0
			nParameterSets = 1;
		end
		for parameterSetNo = 1:nParameterSets
			try
				display(repmat('*',1,14))
				% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
				display(['parameter set:' num2str(parameterSetNo) '/' num2str(nParameterSets)]);

				if iterateParameters==1
					% add the iterated parameter here
					paramNames = fieldnames(paramSet);
					nParams = length(paramNames);
					for paramNo = 1:nParams
						cnmfOptions.(paramNames{paramNo}) = paramSet.(paramNames{paramNo}){parameterSetNo};
						saveParams.(paramNames{paramNo}) = paramSet.(paramNames{paramNo}){parameterSetNo};
					end
					saveParams
				end

				startTime = tic;
				cnmfAnalysisOutput = [];
				% [cnmfAnalysisOutput] = computeCnmfSignalExtraction(movieList,obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum}),'options',cnmfOptions);

				numExpectedComponents = obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum});
				numExpectedComponents = numExpectedComponents(1);
				originalPath = [options.signalExtractionRootPath filesep 'cnmf_original'];
				currentPath = [options.signalExtractionRootPath filesep 'cnmf_current'];
				switch options.CNMF.originalCurrentSwitch
					case 'original'
						% Add and remove necessary CNMF directories from path
						[success] = cnmfVersionDirLoad('original');
						% fprintf('Remove %s\n Add %s\n',currentPath,originalPath);
						% rmpath(genpath(currentPath));
						% addpath(genpath(originalPath));
						[cnmfAnalysisOutput] = computeCnmfSignalExtractionOriginal(movieList,numExpectedComponents,'options',cnmfOptions);
					case 'current'
						% Add and remove necessary CNMF directories from path
						[success] = cnmfVersionDirLoad('current');

						cnmfOptions.nonCNMF.classifyComponents = options.CNMF.classifyComponents;

						% fprintf('Remove %s\n Add %s\n',originalPath,currentPath);
						% rmpath(genpath(originalPath));
						% addpath(genpath(currentPath));
						% [cnmfAnalysisOutput] = computeCnmfSignalExtraction_v2(movieList,numExpectedComponents,'options',cnmfOptions);

						[cnmfAnalysisOutput] = computeCnmfSignalExtractionClass(movieList,numExpectedComponents,'options',cnmfOptions);

					case 'current_patch'
						% Add and remove necessary CNMF directories from path
						[success] = cnmfVersionDirLoad('current');

						cnmfOptions.nonCNMF.parallel = 1;
						cnmfOptions.merge_thr = 0.85;
						cnmfOptions.ssub = options.CNMF.ssub;
						cnmfOptions.tsub = options.CNMF.tsub;
						cnmfOptions.fr = options.CNMF.fr;
						cnmfOptions.create_memmap = options.CNMF.create_memmap;
						cnmfOptions.otherCNMF.tau = gridWidth.(obj.subjectStr{obj.fileNum})/2;
						cnmfOptions.otherCNMF.p = 2;

						cnmfOptions.nonCNMF.patch_size = options.CNMF.patch_size;
						cnmfOptions.nonCNMF.overlap = options.CNMF.overlap;

						% fprintf('Remove %s\n Add %s\n',originalPath,currentPath);
						% rmpath(genpath(originalPath));
						% addpath(genpath(currentPath));
						[cnmfAnalysisOutput] = computeCnmfSignalExtractionPatch(movieList{1},numExpectedComponents,'options',cnmfOptions);
					otherwise
						% do nothing
				end

				% [cnmfAnalysisOutput] = computeCnmfSignalExtractionOriginal(movieList,obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum}),'options',cnmfOptions);
				% [cnmfAnalysisOutput] = computeCnmfSignalExtractionOriginal(movieList,nPCsnICs,'options',cnmfOptions);

				[figHandle figNo] = openFigure(1337, '');hold off;
				obj.modelSaveImgToFile([],'initializationROIs_',1337,[obj.folderBaseSaveStr{obj.fileNum} '_run0' num2str(parameterSetNo)]);
				[figHandle figNo] = openFigure(1339, '');hold off;
				obj.modelSaveImgToFile([],'cellmapContours_',1339,[obj.folderBaseSaveStr{obj.fileNum} '_run0' num2str(parameterSetNo)]);

				cnmfAnalysisOutput.time.startTime = startTime;
				cnmfAnalysisOutput.time.endTime = tic;
				cnmfAnalysisOutput.time.totalTime = toc(startTime);

				cnmfAnalysisOutput.versionOutput = options.CNMF.originalCurrentSwitch;

				% save ICs
				if options.CNMF.saveEachRunNewDirSwitch==0
					saveID = {obj.rawCNMFStructSaveStr,'_paramSet.mat'};
					saveVariable = {'cnmfAnalysisOutput','saveParams'};
					thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
				else
					saveID = {obj.rawCNMFStructSaveStr,'_paramSet.mat'};
					saveVariable = {'cnmfAnalysisOutput','saveParams'};
					thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep 'run0' num2str(parameterSetNo) filesep];
					if (~exist(thisDirSaveStr,'dir')) mkdir(thisDirSaveStr); end;
					thisDirSaveStr = [thisDirSaveStr obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
				end

				% =======
				for i=1:length(saveID)
					savestring = [thisDirSaveStr saveID{i}];
					display(['saving: ' savestring])
					% save(savestring,saveVariable{i},'-v7.3','emOptions');
					save(savestring,saveVariable{i},'-v7.3');
				end
				% =======
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end
	function [cnmfeOptions] = runCNMFESignalFinder()

		% Check CVX is installed and if not, setup.
		runCvxSetup();

		% switch pcaicaPCsICsSwitchStr
		% 	case 'Subject'
		% 		nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).(obj.subjectStr{obj.fileNum})
		% 	case 'Folder'
		% 		nPCsnICs = obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{obj.fileNum}
		% 	otherwise
		% 		% body
		% end

		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);

		if isempty(options.CNMFE.settingsFile)
			cnmfeOptions.gSiz = gridWidth.(obj.subjectStr{obj.fileNum});
			cnmfeOptions.gSig = ceil(gridWidth.(obj.subjectStr{obj.fileNum})/4);
			cnmfeOptions.ssub = options.CNMFE.ssub;
			cnmfeOptions.tsub = options.CNMFE.tsub;
		else
			% Run the settings file and transfer to settings
			cnmfeOpts.ssub = 1;
			run(options.CNMFE.settingsFile);
			cnmfeOptions = cnmfeOpts;
		end

		cnmfOptions.nonCNMF.inputDatasetName = obj.inputDatasetName;

		try
			display(repmat('*',1,14))
			startTime = tic;
			cnmfeAnalysisOutput = [];
			% [cnmfeAnalysisOutput] = computeCnmfeSignalExtraction(movieList{1},'options',cnmfeOptions);
			[cnmfeAnalysisOutput] = computeCnmfeSignalExtraction_batch(movieList{1},'options',cnmfeOptions);

			% [figHandle figNo] = openFigure(1337, '');hold off;
			% obj.modelSaveImgToFile([],'initializationROIs_',1337,[obj.folderBaseSaveStr{obj.fileNum} '_run0' num2str(parameterSetNo)]);
			% [figHandle figNo] = openFigure(1339, '');hold off;
			% obj.modelSaveImgToFile([],'cellmapContours_',1339,[obj.folderBaseSaveStr{obj.fileNum} '_run0' num2str(parameterSetNo)]);

			cnmfeAnalysisOutput.time.startTime = startTime;
			cnmfeAnalysisOutput.time.endTime = tic;
			cnmfeAnalysisOutput.time.totalTime = toc(startTime);
			cnmfeAnalysisOutput.obj.cnmfeOptions = cnmfeOptions;

			% save CNMF-E components
			% =======
			for i=1:length(saveID)
				savestring = [thisDirSaveStr saveID{i}];
				display(['saving: ' savestring])
				% save(savestring,saveVariable{i},'-v7.3','emOptions');
				save(savestring,saveVariable{i},'-v7.3');
			end
			% =======
			% To allow deletion of cnmfe temporary directory
			fclose('all')
			%
			% Delete temporary folder.
			display(repmat('*',1,21))
			fprintf('Deleting temporary folder: %s\n',cnmfeAnalysisOutput.P.folder_analysis)
			display(repmat('*',1,21))
			status = rmdir(cnmfeAnalysisOutput.P.folder_analysis,'s')
			% _source_extraction
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))

			% To allow deletion of cnmfe temporary directory
			fclose('all')
			try
				% Delete temporary folder.
				display(repmat('*',1,21))
				fprintf('Deleting temporary folder: %s\n',cnmfeAnalysisOutput.P.folder_analysis)
				display(repmat('*',1,21))
				status = rmdir(cnmfeAnalysisOutput.P.folder_analysis,'s')
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end
	function [gridWidth gridSpacing] = subfxnSignalSizeSpacing()
		subjectList = unique(obj.subjectStr(fileIdxArray));

		if strcmp(signalExtractionMethod{signalExtractNo},'EM')
			if ~isempty(options.CELLMax.gridSpacing) & ~isempty(options.CELLMax.gridWidth)
				display('Use manually entered values.')
				for thisSubjectStr=subjectList
					display(repmat('=',1,21))
					thisSubjectStr = thisSubjectStr{1};
					display(thisSubjectStr);
					gridWidth.(thisSubjectStr) = options.CELLMax.gridWidth;
					gridSpacing.(thisSubjectStr) = options.CELLMax.gridSpacing;
				end
				gridWidth
				gridSpacing
				return;
			end
		end

		if strcmp(signalExtractionMethod{signalExtractNo},'CNMF')
			if ~isempty(options.CNMF.gridWidth)
				display('Use manually entered values.')
				for thisSubjectStr=subjectList
					display(repmat('=',1,21))
					thisSubjectStr = thisSubjectStr{1};
					display(thisSubjectStr);
					gridWidth.(thisSubjectStr) = options.CNMF.gridWidth;
					gridSpacing.(thisSubjectStr) = options.CNMF.gridWidth;
				end
				gridWidth
				gridSpacing
				return;
			end
		end

		for thisSubjectStr=subjectList
			try
				display(repmat('=',1,21))
				thisSubjectStr = thisSubjectStr{1};
				fprintf('Subject: %s\n',thisSubjectStr);
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				% filter for folders chosen by the user
				validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
				if isempty(validFoldersIdx)
					continue;
				end

				movieList = getFileList(obj.inputFolders{validFoldersIdx(1)}, obj.fileFilterRegexp);
				DFOFList.(thisSubjectStr) = loadMovieList(movieList,'convertToDouble',0,'frameList',[1:500],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
		for thisSubjectStr=subjectList
			try
				display(repmat('=',1,21))
				thisSubjectStr = thisSubjectStr{1};
				fprintf('Subject: %s\n',thisSubjectStr);
				% display(thisSubjectStr);
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				% filter for folders chosen by the user
				validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
				if isempty(validFoldersIdx)
					continue;
				end

				movieList = getFileList(obj.inputFolders{validFoldersIdx(1)}, obj.fileFilterRegexp);
				% DFOF = loadMovieList(movieList,'convertToDouble',0,'frameList',[1:500],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);
				DFOF = DFOFList.(thisSubjectStr);

				mainFig = figure; clear gca
				% display movie
				maxProj=max(DFOF,[],3);
				imagesc(squeeze(maxProj));
				colormap gray;
				imcontrast
				figure(mainFig)
				% imellipse has different behavior depending on axis in 2015b and 2017a
				% if verLessThan('matlab','9.0')
				% 	axis equal;
				% else
				% 	axis equal tight
				% end
				ax = gca;
				ax.PlotBoxAspectRatio = [1 1 0.5];
				mymenu = uimenu('Parent',mainFig,'Label','Hot Keys');
				uimenu('Parent',mymenu,'Label','Zoom','Accelerator','z','Callback',@(src,evt)zoom(mainFig,'on'));
				uimenu('Parent',mymenu,'Label','Zoom','Accelerator','x','Callback',@(src,evt)zoom(mainFig,'off'));
				box off;
				title(sprintf('Select (green) a region covering one cell (best to select one near another cell).\nDouble-click region to continue.\nEnable zoom with crtl+Z = zoom on, ctrl+x = zoom off. Turn off to re-enable cell size selection'))

				% open up first picture
				movieDims = size(DFOF);
				% handle01 = imellipse(gca,round([movieDims(2)/2 movieDims(1)/2 movieDims(2)/4 movieDims(1)/4]));
				xH = movieDims(2);
				yW = movieDims(1);
				handle01 = imellipse(gca,round([min(xH,yW)/2 min(xH,yW)/2 min(xH,yW)/4 min(xH,yW)/4]));
				setColor(handle01,'g');
				addNewPositionCallback(handle01,@(p) title(sprintf('Select a region covering one cell (best to select one near another cell).\nDouble-click region to continue.\nEnable zoom with crtl+Z = zoom on, ctrl+x = zoom off. Turn off to re-enable cell size selection\nDiameter = %d px.',round(p(3)))));
				setFixedAspectRatioMode(handle01,true);
				fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
				setPositionConstraintFcn(handle01,fcn);
				wait(handle01);
				pos1 = getPosition(handle01);
				gridWidthTmp = round(pos1(3));

				title(sprintf('Select (red) the closest neighboring cell or place at location with average distance between cells.\n Double-click region to continue.\nEnable zoom with crtl+Z = zoom on, ctrl+x = zoom off. Turn off to re-enable cell size selection'))
				handle02 = imellipse(gca,round([movieDims(1)/2 movieDims(2)/2 gridWidthTmp gridWidthTmp]));
				setColor(handle02,'r');
				% Create closure/anonymous function to calculate distance
				distFunction = @(p) title(sprintf('Select the closest neighboring cell or place at location with average distance between cells.\n Double-click region to continue.\nEnable zoom with crtl+Z = zoom on, ctrl+x = zoom off. Turn off to re-enable cell size selection\n Diameter = %d px | Distance = %d.',gridWidthTmp,ceil(norm(pos1(1:2)-p(1:2)))+1));
				addNewPositionCallback(handle02,distFunction);
				setFixedAspectRatioMode(handle02,true);
				fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
				setPositionConstraintFcn(handle02,fcn);
				wait(handle02);
				pos2 = getPosition(handle02);
				gridSpacingTmp = ceil(norm(pos1(1:2)-pos2(1:2)))+1;

				gridWidth.(thisSubjectStr) = gridWidthTmp;
				gridSpacing.(thisSubjectStr) = gridSpacingTmp;

				% h=figure;
				% maxProj=max(DFOF,[],3);
				% clear gca
				% imagesc(maxProj); hax=gca;
				% movieDecision = 'no';
				% while strcmp(movieDecision,'no')
				% 	title('Select a region covering one cell (best to select one near another cell). Double-click region to continue.')
				% 	cell1=imellipse(hax);
				% 	wait(cell1);
				% 	img1=createMask(cell1);
				% 	gridWidth.(thisSubjectStr)=ceil(sqrt(sum(img1(:)==1)/pi));
				% 	% addNewPositionCallback(h,@(p) title(mat2str(p,3)));
				% 	movieDecision = questdlg(['Radius = ' num2str(gridWidth.(thisSubjectStr)) ' px?'], 'Movie decision', 'yes','no','other','yes');
				% 	if strcmp(movieDecision,'no')
				% 		delete(cell1)
				% 	end
				% end
				% movieDecision = 'no';
				% while strcmp(movieDecision,'no')
				% 	title('Select the closest neighboring cell. Double-click region to continue.')
				% 	cell2=imellipse(hax);
				% 	wait(cell2);
				% 	pos1=getPosition(cell1);
				% 	pos2=getPosition(cell2);
				% 	gridSpacing.(thisSubjectStr)=ceil(norm(pos1(1:2)-pos2(1:2)))+1;
				% 	movieDecision = questdlg(['Distance = ' num2str(gridSpacing.(thisSubjectStr)) ' px?'], 'Movie decision', 'yes','no','other','yes');
				% 	if strcmp(movieDecision,'no')
				% 		delete(cell2)
				% 	end
				% end
				% close(h);
				% clear DFOF;
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
		try
			fn_structdisp(gridWidth);
			fn_structdisp(gridSpacing);
		catch
		end
	end
	% function dd
	% 	h = imellipse(gca, [10 10 100 100]);
	% 	addNewPositionCallback(h,@(p) title(mat2str(p,3)));
	% 	fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
	% 	setPositionConstraintFcn(h,fcn);
	function pcaicaPCsICsSwitchStr = subfxnNumExpectedSignals()
		pcaicaPCsICsSwitchStr = {'Subject','Folder'};
		[signalIdxArray, ok] = listdlg('ListString',pcaicaPCsICsSwitchStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','Select PCs/ICs by subject or folder?','InitialValue',1);
		% signalIdxArray
		pcaicaPCsICsSwitchStr = pcaicaPCsICsSwitchStr{signalIdxArray};

		% use subject or folder for PC/ICA list?
		switch pcaicaPCsICsSwitchStr
			case 'Subject'
				% create expected PC/ICs signal structure if doesn't already exist
				subjectList = unique(obj.subjectStr);
				% if isempty(obj.numExpectedSignals)
				for subjectNum = 1:length(subjectList)
					% obj.subjectStr{subjectNum}
					% obj.numExpectedSignals.(obj.signalExtractionMethod)
					try obj.numExpectedSignals.(obj.signalExtractionMethod).(subjectList{subjectNum});check.numExpectedSignals=1; catch; check.numExpectedSignals=0; end
					check.numExpectedSignals
					if check.numExpectedSignals==0
						obj.numExpectedSignals.(obj.signalExtractionMethod).(subjectList{subjectNum}) = [];
					end
					clear check;
				end

				% create default [PCs ICs] list else empty
				defaultList = {};
				for subjectNum = 1:length(subjectList)
					if ~isempty(obj.numExpectedSignals.(obj.signalExtractionMethod).(subjectList{subjectNum}))
						defaultList{subjectNum} = num2str(obj.numExpectedSignals.(obj.signalExtractionMethod).(subjectList{subjectNum}));
					else
						defaultList{subjectNum} = '';
					end
				end

				% ask user for nPCs/ICs
				numExpectedSignalsArray = inputdlg(subjectList,[obj.signalExtractionMethod ' | # of PCs/ICs to use [PCs ICs] or for CNMF # of components [nComponents nComponents]'],[1 150],defaultList);
				for subjectNum = 1:length(subjectList)
					obj.numExpectedSignals.(obj.signalExtractionMethod).(subjectList{subjectNum}) = str2num(numExpectedSignalsArray{subjectNum});
				end
			case 'Folder'
				% nFolders = length(fileIdxArray);
				nFolders = length(obj.inputFolders);

				% if isempty(obj.numExpectedSignals)
				for folderNo = 1:nFolders
					try obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{folderNo};check.numExpectedSignals=1; catch; check.numExpectedSignals=0; end
					if check.numExpectedSignals==0
						obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{folderNo} = [];
					end
					clear check;
				end

				% create default [PCs ICs] list else empty
				defaultList = {};
				for folderNo = 1:nFolders
					if ~isempty(obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{folderNo})
						defaultList{folderNo} = num2str(obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{folderNo});
					else
						defaultList{folderNo} = '';
					end
				end

				% ask user for nPCs/ICs and store
				defaultList
				numExpectedSignalsArray = inputdlg(obj.folderBasePlaneSaveStr,[obj.signalExtractionMethod ' | # of PCs/ICs to use [PCs ICs] or for CNMF # of components [nComponents nComponents]'],[1 150],defaultList);
				for folderNo = 1:nFolders
					obj.numExpectedSignals.(obj.signalExtractionMethod).Folders{folderNo} = str2num(numExpectedSignalsArray{folderNo});
				end

			otherwise
				% body
		end
		try
			fn_structdisp(obj.numExpectedSignals)
		catch
		end
	end
end
function [turboregSettingStruct] = getFxnSettings()

	% propertySettings = turboregSettingDefaults;

	propertyList = fieldnames(turboregSettingDefaults);
	nPropertiesToChange = size(propertyList,1);

	% add current property to the top of the list
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		propertyOptions = turboregSettingStr.(property);
		propertySettingsStr.(property) = propertyOptions;
		% propertySettingsStr.(property);
	end

	uiListHandles = {};
	uiTextHandles = {};
	uiXIncrement = 0.05;
	uiYOffset = 0.95;
	uiTxtSize = 0.3;
	uiBoxSize = 0.4;
	[figHandle figNo] = openFigure(1337, '');
	clf
	uicontrol('Style','Text','String','processing options','Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(nPropertiesToChange+1) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiTextHandles{propertyNo} = uicontrol('Style','Text','String',[property ': '],'Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*propertyNo uiTxtSize 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
		uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiTxtSize uiYOffset-uiXIncrement*propertyNo uiBoxSize 0.05]);
	end
	uicontrol('Style','Text','String','press enter to continue','Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(nPropertiesToChange+1) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	pause

	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiListHandleData = get(uiListHandles{propertyNo});
		turboregSettingStruct.(property) = turboregSettingDefaults.(property){uiListHandleData.Value};
	end
	close(1337)
end