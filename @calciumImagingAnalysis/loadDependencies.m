function obj = loadDependencies(obj)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.12 [17:40:37] - Updated to enable GUI-less loading of dependencies. In particular for easier unit testing.
	% TODO
		% Verify all dependencies download and if not ask user to download again.

	scnsize = get(0,'ScreenSize');
	dependencyStr = {'downloadMiji','downloadCnmfGithubRepositories','example_downloadTestData','loadMiji','downloadNeuroDataWithoutBorders'};
	dispStr = {'Download Fiji (to run Miji)','Download CNMF, CNMF-E, and CVX code.','Download test one-photon data.','Load Fiji/Miji into MATLAB path.','Download NWB (NeuroDataWithoutBorders)'};
	if obj.guiEnabled==1
		[fileIdxArray, ~] = listdlg('ListString',dispStr,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Which dependencies to load? (Can select multiple)','InitialValue',[1 2 3 5]);
	else
		fileIdxArray = [1 2 3 5];
	end
	analysisTypeD = dependencyStr(fileIdxArray);
	dispStr = dispStr(fileIdxArray);
	for depNo = 1:length(fileIdxArray)
		disp([10 repmat('>',1,42)])
		disp(dispStr{depNo})
		switch analysisTypeD{depNo}
			case 'downloadCnmfGithubRepositories'
				[success] = downloadCnmfGithubRepositories();
			case 'downloadMiji'
				depStr = {'Save Fiji to default directory','Save Fiji to custom directory'};
				if obj.guiEnabled==1
					[fileIdxArray, ~] = listdlg('ListString',depStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Where to save Fiji?');
				else
					fileIdxArray = 1;
				end
				depStr = depStr{fileIdxArray};
				if fileIdxArray==1
					downloadMiji();
				else
					downloadMiji('defaultDir','');
				end
				% if exist('pathtoMiji','var')
				% end
			case 'loadMiji'
				modelAddOutsideDependencies('miji');
			case 'example_downloadTestData'
				example_downloadTestData();
			case 'downloadCellExtraction'
				optionsH.signalExtractionDir = obj.externalProgramsDir;
				optionsH.gitNameDisp = {'nwb_schnitzer_lab','yamlmatlab','matnwb'};
				optionsH.gitRepos = {'https://github.com/schnitzer-lab/nwb_schnitzer_lab','https://github.com/ewiger/yamlmatlab','https://github.com/NeurodataWithoutBorders/matnwb'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadNeuroDataWithoutBorders'
				optionsH.signalExtractionDir = obj.externalProgramsDir;
				optionsH.gitNameDisp = {'nwb_schnitzer_lab','yamlmatlab','matnwb'};
				optionsH.gitRepos = {'https://github.com/schnitzer-lab/nwb_schnitzer_lab','https://github.com/ewiger/yamlmatlab','https://github.com/NeurodataWithoutBorders/matnwb'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				[success] = downloadGithubRepositories('options',optionsH);

				% Load NWB Schema as needed
				if exist('types.core.Image')==0
					try
						disp('Generating matnwb types core files with "generateCore.m"')
						origPath = pwd;
						mat2nwbPath = [obj.defaultObjDir filesep obj.externalProgramsDir filesep 'matnwb'];
						disp(['cd ' mat2nwbPath])
						cd(mat2nwbPath);
						generateCore;
						disp(['cd ' origPath])
						cd(origPath);
					catch
						cd(obj.defaultObjDir);
					end
				else
					disp('NWB Schema types already loaded!')
				end
				% Add NWB folders to path.
				obj.loadBatchFunctionFolders;
			otherwise
				% nothing
		end
	end
end