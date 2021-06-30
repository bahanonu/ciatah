function obj = runPipeline(obj,varargin)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.09 [18:36:01] - Added a check to make sure certain directories are unloaded after running a module if they are not needed.
	% TODO
		%

	try
		setFigureDefaults();
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
		obj.loadBatchFunctionFolders();
	end
	try
		set(0, 'DefaultUICOntrolFontSize', obj.fontSizeGui)
	catch
		set(0, 'DefaultUICOntrolFontSize', 11)
	end
	close all;clc;

	fxnsToRun = obj.methodsList;
	%========================
	options.fxnsToRun = fxnsToRun;
	% get options
	options = getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	fxnsToRun = options.fxnsToRun;
	% initialDir = pwd;
	% set back to initial directory in case exited early
	% restoredefaultpath;
	% loadBatchFxns();
	if strcmp(obj.defaultObjDir,pwd)~=1
		cd(obj.defaultObjDir);
	end

	if ischar(obj.videoDir)
		obj.videoDir = {obj.videoDir};
	end

	% ensure private folders are set
	if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);end
	if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);end
	if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);end

	props = properties(obj);
	totSize = 0;
	% for ii=1:length(props)
	%	  currentProperty = getfield(obj, char(props(ii)));
	%	  s = whos('currentProperty');
	%	  totSize = totSize + s.bytes;
	% end
	% sprintf('%.f',totSize*1.0e-6)
	% fprintf(1, '%d bytes\n', totSize*1.0e-6);
	% runs all currently implemented view functions

	scnsize = get(0,'ScreenSize');
	dlgSize = [scnsize(3)*0.4 scnsize(4)*0.6];

	currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));
	% Only keep the 1st method if it is twice in the function list.
	[~,duplicateIdx] = unique(fxnsToRun,'stable');
	currentIdx = intersect(currentIdx,duplicateIdx);
	% [idNumIdxArray, ok] = listdlg('ListString',fxnsToRun,'InitialValue',currentIdx(1),'ListSize',dlgSize,'Name','Sir! I have a plan! Select a calcium imaging analysis method or procedure to run:');

	[idNumIdxArray, fileIdxArray, ok] = obj.ciatahMainGui(fxnsToRun,['"Sir! I have a plan!" Hover over ' ciapkg.pkgName ' methods for tooltips.'],currentIdx);
	obj.foldersToAnalyze = fileIdxArray;
	bypassUI = 1;

	% [idNumIdxArray, ok] = obj.pipelineListBox(fxnsToRun,['"Sir! I have a plan!" Select a calciumImagingAnalysis method or procedure to run. Hover over items for tooltip descriptions.'],currentIdx);
	if ok==0;
		subfxnCheckDirs();
		return;
	end

	% excludeList = {'showVars','showFolders','setMainSettings','modelAddNewFolders','loadDependencies','saveObj','setStimulusSettings','modelDownsampleRawMovies'};
	% excludeListVer2 = {'modelEditStimTable','behaviorProtocolLoad','modelPreprocessMovie','modelModifyMovies','removeConcurrentAnalysisFiles'};
	% excludeListStimuli = {'modelVarsFromFiles'};
	excludeList = obj.methodExcludeList;
	excludeListVer2 = obj.methodExcludeListVer2;
	excludeListStimuli = obj.methodExcludeListStimuli;

	if isempty(intersect(fxnsToRun,excludeList))&isempty(intersect(fxnsToRun,excludeListVer2))
		% [guiIdx, ok] = listdlg('ListString',{'Yes','No'},'InitialValue',1,'ListSize',dlgSize,'Name','GUI Enabled?');
		[guiIdx, ok] = obj.pipelineListBox({'Yes','No'},['GUI Enabled?'],1);
		if ok==0; return; end
		% idNumIdxArray
		% turn off gui elements, run in batch
		obj.guiEnabled = guiIdx==1;
	end

	fxnsToRun = {fxnsToRun{idNumIdxArray}};
	obj.currentMethod = fxnsToRun{1};

	if bypassUI==0&isempty(intersect(fxnsToRun,excludeList))
		scnsize = get(0,'ScreenSize');
		usrIdxChoiceStr = obj.usrIdxChoiceStr;
		usrIdxChoiceDisplay = obj.usrIdxChoiceDisplay;
		% use current string as default
		currentIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));
		% [sel, ok] = listdlg('ListString',usrIdxChoiceDisplay,'InitialValue',currentIdx,'ListSize',dlgSize,'Name','Get to the data! Cell extraction algorithm to use for analysis?');
		[sel, ok] = obj.pipelineListBox(usrIdxChoiceDisplay,['"Get to the data!" Cell extraction algorithm to use for analysis?'],currentIdx);

		if ok==0; return; end
		% (Americans love a winner)
		usrIdxChoiceList = {2,1};
		obj.signalExtractionMethod = usrIdxChoiceStr{sel};
	end
	if bypassUI==0&~isempty(obj.inputFolders)&isempty(intersect(fxnsToRun,excludeList))&isempty(intersect(fxnsToRun,excludeListVer2))
		if isempty(obj.protocol)
			obj.modelGetFileInfo();
		end
		folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
		selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
		% set(0, 'DefaultUICOntrolFontSize', 16)
		% select subjects to analyze
		subjectStrUnique = unique(obj.subjectStr);
		% [subjIdxArray, ok] = listdlg('ListString',subjectStrUnique,'ListSize',dlgSize,'Name','Which subjects to analyze?');
		[subjIdxArray, ok] = obj.pipelineListBox(subjectStrUnique,['Which subjects to analyze?'],1);
		if ok==0; return; end
		subjToAnalyze = subjectStrUnique(subjIdxArray);
		subjToAnalyze = find(ismember(obj.subjectStr,subjToAnalyze));
		% get assays to analyze
		assayStrUnique = unique(obj.assay(subjToAnalyze));
		% [assayIdxArray, ok] = listdlg('ListString',assayStrUnique,'ListSize',dlgSize,'Name','Which assays to analyze?');
		[assayIdxArray, ok] = obj.pipelineListBox(assayStrUnique,['Which assays to analyze?'],1);
		if ok==0; return; end
		assayToAnalyze = assayStrUnique(assayIdxArray);
		assayToAnalyze = find(ismember(obj.assay,assayToAnalyze));
		% filter for folders chosen by the user
		validFoldersIdx = intersect(subjToAnalyze,assayToAnalyze);
		% if isempty(validFoldersIdx)
		%	  continue;
		% end
		useAltValid = {'no additional filter','manual index entry','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file']};
		useAltValidStr = {'no additional filter','manual index entry','manually sorted folders','not manually sorted folders','manual classification already in obj',['has extracted cells'],'missing extracted cells','fileFilterRegexp','valid auto','movie file'};
		% [choiceIdx, ok] = listdlg('ListString',useAltValid,'ListSize',dlgSize,'Name','Choose additional folder sorting filters');
		[choiceIdx, ok] = obj.pipelineListBox(useAltValid,['Choose additional folder sorting filters'],1);
		if ok==0; return; end

		if ok==1
			useAltValid = useAltValidStr{choiceIdx};
		else
			useAltValid = 0;
		end
		% useAltValid = 0;
		[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx);

		% [fileIdxArray, ok] = listdlg('ListString',selectList,'ListSize',dlgSize,'Name','Which folders to analyze?','InitialValue',validFoldersIdx);
		[fileIdxArray, ok] = obj.pipelineListBox(selectList,['Which folders to analyze?'],validFoldersIdx);
		if ok==0; return; end

		obj.foldersToAnalyze = fileIdxArray;
		if isempty(obj.stimulusNameArray)|~isempty(intersect(fxnsToRun,excludeListVer2))|~isempty(intersect(fxnsToRun,excludeListStimuli))
			obj.discreteStimuliToAnalyze = [];
		else
			% [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',dlgSize,'Name','which stimuli to analyze?');
			[idNumIdxArray, ok] = obj.pipelineListBox(obj.stimulusNameArray,['Which stimuli to analyze?'],1);
			if ok==0; return; end

			obj.discreteStimuliToAnalyze = idNumIdxArray;
		end
	elseif bypassUI==0&~isempty(intersect(fxnsToRun,excludeListVer2))
		folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
		selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
		% [fileIdxArray, ok] = listdlg('ListString',selectList,'ListSize',dlgSize,'Name','Which folders to analyze?','InitialValue',1);
		[fileIdxArray, ok] = obj.pipelineListBox(selectList,['Which folders to analyze?'],1);
		if ok==0; return; end

		obj.foldersToAnalyze = fileIdxArray;
	else
		if isempty(obj.stimulusNameArray)|~isempty(intersect(fxnsToRun,excludeListVer2))|~isempty(intersect(fxnsToRun,excludeListStimuli))
			obj.discreteStimuliToAnalyze = [];
		else
			% [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',dlgSize,'Name','which stimuli to analyze?');
			[idNumIdxArray, ok] = obj.pipelineListBox(obj.stimulusNameArray,['Which stimuli to analyze?'],1);
			if ok==0; return; end

			obj.discreteStimuliToAnalyze = idNumIdxArray;
		end
	end

	for thisFxn = fxnsToRun
		try
			disp(repmat('!',1,21))
			if ismethod(obj,thisFxn)
				disp(['Running: obj.' thisFxn{1}]);
				obj.(thisFxn{1});
			else
				disp(['Method not supported, skipping: obj.' thisFxn{1}]);
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
			if strcmp(obj.defaultObjDir,pwd)~=1
				restoredefaultpath;
				cd(obj.defaultObjDir);
				loadBatchFxns();
				% cnmfVersionDirLoad('current','displayOutput',0);
			end
		end
	end
	obj.guiEnabled = 1;
	obj.foldersToAnalyze = [];
	% set back to initial directory in case exited early
	% restoredefaultpath;
	% loadBatchFxns();
	if strcmp(obj.defaultObjDir,pwd)~=1
		cd(obj.defaultObjDir);
	end

	subfxnCheckDirs();

	% Force back to command window.
	commandwindow

	disp([10 10 ...
	'Run processing pipeline by typing below (or clicking link) into command window (no semi-colon!):' 10 ...
	'<a href="matlab: obj">obj</a>'])
end
function subfxnCheckDirs()
	% Re-run load folders if certain functions are still present in the path
	fxnCheckList = {'CELLMax_Wrapper.m','extractor.m','normcorre.m'};
	if any(cellfun(@(x) ~isempty(which(x)),fxnCheckList))==1
		loadBatchFxns;
	end
end