function obj = loadDependencies(obj,varargin)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.12 [17:40:37] - Updated to enable GUI-less loading of dependencies. In particular for easier unit testing.
		% 2020.06.28 [14:25:04] - Added ability for users to force update.
		% 2021.01.22 [13:42:36] - NWB from specific release to reduce compatibility errors.
		% 2021.02.01 [15:10:41] - Calls non-class function for use in more functions without needing to load CIAtah class.
	% TODO
		% Verify all dependencies download and if not ask user to download again.

	%========================
	% DESCRIPTION
	options.guiEnabled = 1;
	options.dependencyStr = {'downloadMiji','downloadCnmfGithubRepositories','example_downloadTestData','loadMiji','downloadNeuroDataWithoutBorders'};

	options.dispStr = {'Download Fiji (to run Miji)','Download CNMF, CNMF-E, and CVX code.','Download test one- and two photon datasets.','Load Fiji/Miji into MATLAB path.','Download NWB (NeuroDataWithoutBorders)'};
	% Int vector: index of options.dependencyStr to run by default with no GUI
	options.depIdxArray = [1 2 3 5];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% scnsize = get(0,'ScreenSize');
	% dependencyStr = options.dependencyStr;
	% dispStr = options.dispStr;
	% if obj.guiEnabled==1
	% 	[depIdxArray, ~] = listdlg('ListString',dispStr,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Which dependencies to load? (Can select multiple)','InitialValue',options.depIdxArray);

	% 	forceDownloadVec = [0 1];
	% 	[forceUpdate, ~] = listdlg('ListString',{'No - skip installing dependency if already available.','Yes - force update to most recent version of dependency.'},'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Force download/update? (e.g. "Yes" to update dependencies)','InitialValue',[1]);
	% 	forceUpdate = forceDownloadVec(forceUpdate);
	% else
	% 	depIdxArray = options.depIdxArray;
	% 	forceUpdate = 0;
	% 	% sopts.forceUpdate = 1;
	% end

	sopts.guiEnabled = obj.guiEnabled;
	sopts.dependencyStr = options.dependencyStr;
	sopts.dispStr = options.dispStr;
	sopts.depIdxArray = options.depIdxArray;

	ciapkg.io.loadDependencies('options',sopts);

	% analysisTypeD = dependencyStr(depIdxArray);
	% dispStr = dispStr(depIdxArray);
	% for depNo = 1:length(depIdxArray)
	% 	disp([10 repmat('>',1,42)])
	% 	disp(dispStr{depNo})
	% 	switch analysisTypeD{depNo}
	% 		case 'downloadCnmfGithubRepositories'
	% 			[success] = downloadCnmfGithubRepositories('forceUpdate',forceUpdate);
	% 		case 'downloadMiji'
	% 			depStr = {'Save Fiji to default directory','Save Fiji to custom directory'};
	% 			if obj.guiEnabled==1
	% 				[depIdxArray, ~] = listdlg('ListString',depStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Where to save Fiji?');
	% 			else
	% 				depIdxArray = 1;
	% 			end
	% 			depStr = depStr{depIdxArray};
	% 			if depIdxArray==1
	% 				downloadMiji();
	% 			else
	% 				downloadMiji('defaultDir','');
	% 			end
	% 			% if exist('pathtoMiji','var')
	% 			% end
	% 		case 'loadMiji'
	% 			modelAddOutsideDependencies('miji');
	% 		case 'example_downloadTestData'
	% 			example_downloadTestData();
	% 		case 'downloadCellExtraction'
	% 			optionsH.forceUpdate = forceUpdate;
	% 			optionsH.signalExtractionDir = obj.externalProgramsDir;
	% 			optionsH.gitNameDisp = {'cellmax_clean','extract'};
	% 			optionsH.gitRepos = {'https://github.com/schnitzer-lab/CELLMax_CLEAN','https://github.com/schnitzer-lab/EXTRACT'};
	% 			optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
	% 			optionsH.outputDir = optionsH.gitNameDisp;
	% 			optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
	% 			[success] = downloadGithubRepositories('options',optionsH);
	% 		case 'downloadNeuroDataWithoutBorders'
	% 			optionsH.forceUpdate = forceUpdate;
	% 			optionsH.signalExtractionDir = obj.externalProgramsDir;
	% 			optionsH.gitNameDisp = {'nwb_schnitzer_lab','yamlmatlab','matnwb'};
	% 			optionsH.gitRepos = {'https://github.com/schnitzer-lab/nwb_schnitzer_lab','https://github.com/ewiger/yamlmatlab'};

	% 			% 'https://github.com/NeurodataWithoutBorders/matnwb'
	% 			optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
	% 			optionsH.gitRepos = [optionsH.gitRepos 'https://github.com/NeurodataWithoutBorders/matnwb/archive/v2.2.5.3.zip'];
	% 			optionsH.outputDir = optionsH.gitNameDisp;
	% 			optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
	% 			optionsH.gitName{end} = 'matnwb-2.2.5.3';
	% 			[success] = downloadGithubRepositories('options',optionsH);

	% 			% Add NWB folders to path.
	% 			ciapkg.nwb.setupNwb;
	% 			% obj.loadBatchFunctionFolders;
	% 		otherwise
	% 			% nothing
	% 	end
	% end
end