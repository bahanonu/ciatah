function obj = initializeObj(obj)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% load dependencies.
	loadBatchFxns();
	cnmfVersionDirLoad('none','displayOutput',0);
	% [success] = cnmfVersionDirLoad('cnmfe');

	% Load colormaps
	obj.colormap = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
	obj.colormapAlt = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
	obj.colormapAlt2 = diverging_map(linspace(0,1,100),[0 0 0.7],[0.7 0 0]);

	% Check required toolboxes are available, warn if not
	disp(repmat('*',1,42))
	toolboxList = {...
	'distrib_computing_toolbox',...
	'image_toolbox',...
	'signal_toolbox',...
	'statistics_toolbox',...
	};
	secondaryToolboxList = {...
		'video_and_image_blockset',...
		'bioinformatics_toolbox',...
		'financial_toolbox',...
		'neural_network_toolbox',...
	};
	allTollboxList = {toolboxList,secondaryToolboxList};
	nLists = length(allTollboxList);
	for listNo = 1:nLists
		toolboxListHere = allTollboxList{listNo};
		nToolboxes = length(toolboxListHere);
		if listNo==1
		else
			disp('2nd tier toolbox check (not required for main pre-processing pipeline).')
		end
		for toolboxNo = 1:nToolboxes
			toolboxName = toolboxListHere{toolboxNo};
			if license('test',toolboxName)==1
				fprintf('Toolbox available! %s\n',toolboxName)
			else
				if listNo==1
					warning('Please install %s toolbox before running calciumImagingAnalysis. This toolbox is likely required.',toolboxName);
				else
					warning('Please install %s toolbox before running calciumImagingAnalysis. Some features (e.g. for cell extraction) may not work otherwise.',toolboxName);
				end
				% if ~verLessThan('matlab', '9.5')
				%	  warning('Please install Neural Network toolbox before running classifySignals');
				% else
				%	  warning('Please install Deep Learning Toolbox before running classifySignals');
				% end
				% return;
			end
		end
	end
	disp(repmat('*',1,42))

	% Ensure date paths are up to date
	obj.picsSavePath = ['private' filesep 'pics' filesep datestr(now,'yyyymmdd','local') filesep];
	obj.dataSavePath = ['private' filesep 'data' filesep datestr(now,'yyyymmdd','local') filesep];
	obj.logSavePath = ['private' filesep 'logs' filesep datestr(now,'yyyymmdd','local') filesep];
	obj.settingsSavePath = ['private' filesep 'settings'];
	obj.videoSaveDir = ['private' filesep 'vids' filesep datestr(now,'yyyymmdd','local') filesep];

	% ensure private folders are set
	if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);fprintf('Creating directory: %s\n',obj.picsSavePath);end
	if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);fprintf('Creating directory: %s\n',obj.dataSavePath);end
	if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);fprintf('Creating directory: %s\n',obj.logSavePath);end
	if ~exist(obj.settingsSavePath,'dir');mkdir(obj.settingsSavePath);fprintf('Creating directory: %s\n',obj.settingsSavePath);end
	if ~exist(obj.videoSaveDir,'dir');mkdir(obj.videoSaveDir);fprintf('Creating directory: %s\n',obj.videoSaveDir);end

	% load user specific settings
	loadUserSettings = [obj.settingsSavePath filesep 'calciumImagingAnalysisInitialize.m'];
	if exist(loadUserSettings,'file')~=0
		run(loadUserSettings);
	else
		% create privateLoadBatchFxns.m
	end

	% if use puts in a single folder or a path to a txt file with folders
	if ~isempty(obj.rawSignals)&ischar(obj.rawSignals)
		if isempty(regexp(obj.rawSignals,'.txt'))&exist(obj.rawSignals,'dir')==7
			% user just inputs a single directory
			obj.rawSignals = {obj.rawSignals};
		else
			% user input a file linking to directories
			fid = fopen(obj.rawSignals, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			obj.rawSignals = tmpData{1,1};
			fclose(fid);
		end
		obj.inputFolders = obj.rawSignals;
		obj.dataPath = obj.rawSignals;
	end
	% add subject information to object given datapath
	if ~isempty(obj.dataPath)
		obj.modelGetFileInfo();
	else
		disp('No folder paths input, run <a href="matlab: obj.currentMethod=''modelAddNewFolders'';obj">modelAddNewFolders</a> method to add new folders.');
		% warning('Input data paths for all files!!! option: dataPath')
	end
	if ~isempty(obj.discreteStimulusTable)&~strcmp(class(obj.discreteStimulusTable),'table')
		obj.modelReadTable('table','discreteStimulusTable');
		obj.modelTableToStimArray('table','discreteStimulusTable','tableArray','discreteStimulusArray','nameArray','stimulusNameArray','idArray','stimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName);
	end
	if ~isempty(obj.continuousStimulusTable)&~strcmp(class(obj.continuousStimulusTable),'table')
		obj.delimiter = ',';
		obj.modelReadTable('table','continuousStimulusTable','addFileInfoToTable',1);
		obj.delimiter = ',';
		obj.modelTableToStimArray('table','continuousStimulusTable','tableArray','continuousStimulusArray','nameArray','continuousStimulusNameArray','idArray','continuousStimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName,'grabStimulusColumnFromTable',1);
	end
	% load behavior tables
	if ~isempty(obj.behaviorMetricTable)&~strcmp(class(obj.behaviorMetricTable),'table')
		obj.modelReadTable('table','behaviorMetricTable');
		obj.modelTableToStimArray('table','behaviorMetricTable','tableArray','behaviorMetricArray','nameArray','behaviorMetricNameArray','idArray','behaviorMetricIdArray','valueName','value');
	end
	% modify stimulus naming scheme
	if ~isempty(obj.stimulusNameArray)
		obj.stimulusSaveNameArray = obj.stimulusNameArray;
		obj.stimulusNameArray = strrep(obj.stimulusNameArray,'_',' ');
	end
	% load all the data
	if ~isempty(obj.rawSignals)&ischar(obj.rawSignals{1})
		disp('paths input, going to load files')
		obj.guiEnabled = 0;
		obj = modelVarsFromFiles(obj);
		obj.guiEnabled = 1;
	end
	% check if signal peaks have already been calculated
	if isempty(obj.signalPeaks)&~isempty(obj.rawSignals)
		% obj.computeSignalPeaksFxn();
	else
		disp('No folder data specified, load data with <a href="matlab: obj.currentMethod=''modelVarsFromFiles'';obj">modelVarsFromFiles</a> method.');
		% warning('no signal data input!!!')
	end
	% load stimulus tables

	disp(repmat('*',1,42))
	% Check java heap size
	try
		javaHeapSpaceSizeGb = java.lang.Runtime.getRuntime.maxMemory*1e-9;
		if javaHeapSpaceSizeGb<6.7
			javaErrorStr = sprintf('Java max heap memory is %0.3f Gb. This might cause Miji errors when loading videos due to insufficient memory.\n\nPlease put "java.opts" file in the MATLAB start-up path or change MATALB start-up folder to the calciumImagingAnalysis root folder and restart MATLB before continuing.\n',javaHeapSpaceSizeGb);
			warning(javaErrorStr);
			msgbox(javaErrorStr,'Note to user','modal')
		else
			fprintf('Java max heap memory is %0.3f Gb, this should be sufficient to run Miji without problems. Please change "java.opts" file to increase heap space if run into Miji memory errors.\n',javaHeapSpaceSizeGb);
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end