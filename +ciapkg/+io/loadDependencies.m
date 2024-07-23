function [success] = loadDependencies(varargin)
	% Download and load CIAtah dependencies.
	% Biafra Ahanonu
	% started: 2014.07.31
		% 2021.02.01 [15:09:46] branched from CIAtah
		% branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.12 [17:40:37] - Updated to enable GUI-less loading of dependencies. In particular for easier unit testing.
		% 2020.06.28 [14:25:04] - Added ability for users to force update.
		% 2021.01.22 [13:42:36] - NWB from specific release to reduce compatibility errors.
		% 2021.02.01 [15:10:41] - Separated into non-class function for use in more functions without needing to load CIAtah class.
		% 2021.02.01 [15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.03.20 [18:12:20] - Added EXTRACT support to list of functions to download.
		% 2021.06.19 [23:46:58] - Switched to support for original MIJ calling of ImageJ using just jar files, easier compatibility across MATLAB versions and OSes.
		% 2021.06.21 [16:45:59] - Update order.
		% 2021.07.13 [08:34:18] - Added backup URL for downloading mij.jar.
		% 2021.07.23 [00:22:22] - Added gramm (https://github.com/piermorel/gramm) support/downloading for graphics plotting.
		% 2021.07.26 [13:16:37] - Added Turboreg (moved from within ciapkg) to make explicit that this is an external program.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.03.04 [06:57:14] - Added PatchWarp (https://github.com/ryhattori/PatchWarp). Code clean up.
		% 2022.03.09 [17:01:54] - Updated NoRMCorre to use https://github.com/bahanonu/NoRMCorre as that is a package version, cleaner namespace.
		% 2022.04.08 [15:17:28] - Added CIAtah utilities repository (https://github.com/bahanonu/ciatah_utils) to separate outside code from main repository.
		% 2022.07.10 [20:27:29] - Add SlideBook .jar reader to Bio-Formats download.
		% 2022.09.14 [09:33:53] - Ensure NoRMCorre is in default options.
		% 2022.09.14 [09:47:20] - Ensure bfmatlab_readers directory exists, else websave errors occur.
		% 2022.11.06 [12:47:17] - Ensure display location of SlideBook6Reader.jar saving.
		% 2022.12.05 [11:14:36] - Add success output.
		% 2024.04.30 [22:39:32] - Update Bio-Formats to 7.3.0.
	% TODO
		% Verify all dependencies download and if not ask user to download again.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% DESCRIPTION
	options.externalProgramsDir = ciapkg.getDirExternalPrograms();
	options.guiEnabled = 1;
	options.dependencyStr = {...
		'downloadCIAtahUtils';
		'downloadTurboreg';
		'downloadImageJ';
		'downloadCnmfGithubRepositories';
		'example_downloadTestData';
		'downloadNeuroDataWithoutBorders';
		'downloadEXTRACT';
		'downloadBioFormats';
		'downloadGramm';
		'downloadNoRMCorre';
		'downloadMiji';
		'downloadPatchWarp';
		'loadMiji';
	};

	options.dispStr = {...
		'Download CIAtah utilities/dependencies';
		'Download Turboreg (motion correction)';
		'Download ImageJ';
		'Download CNMF, CNMF-E, and CVX code.';
		'Download test one- and two photon datasets.';
		'Download NWB (NeuroDataWithoutBorders)';
		'Download EXTRACT';
		'Download Bio-Formats';
		'Download gramm (GRAMmar of graphics for Matlab, e.g. ggplot2-like)';
		'Download NoRMCorre (motion correction)';
		'Download Fiji (to run Miji)';
		'Download PatchWarp (motion correction)';
		'Load Fiji/Miji into MATLAB path.';
	};
	% Int vector: index of options.dependencyStr to run by default with no GUI
	options.depIdxArray = [1 2 3 4 5 6 7 8 9 10];
	% Binary: 1 = force update even if already downloaded. 0 = skip if already downloaded
	options.forceUpdate = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	success = 0;

	scnsize = get(0,'ScreenSize');
	if ischar(options.dispStr)
		options.dispStr = {options.dispStr};
	end
	if ischar(options.dependencyStr)
		options.dependencyStr = {options.dependencyStr};
	end
	dependencyStr = options.dependencyStr;

	dispStr = options.dispStr;
	if options.guiEnabled==1
		[depIdxArray, ~] = listdlg('ListString',dispStr,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Which dependencies to load? (Can select multiple)','InitialValue',options.depIdxArray);

		forceDownloadVec = [0 1];
		[forceUpdate, ~] = listdlg('ListString',{'No - skip installing dependency if already available.','Yes - force update to most recent version of dependency.'},'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Force download/update? (e.g. "Yes" to update dependencies)','InitialValue',[1]);
		forceUpdate = forceDownloadVec(forceUpdate);
	else
		depIdxArray = options.depIdxArray;
		forceUpdate = 0;
	end
	analysisTypeD = dependencyStr(depIdxArray);
	dispStr = dispStr(depIdxArray);
	for depNo = 1:length(depIdxArray)
		disp([10 repmat('>',1,42)])
		disp(dispStr{depNo})

		optionsH.forceUpdate = forceUpdate;
		optionsH.signalExtractionDir = options.externalProgramsDir;

		switch analysisTypeD{depNo}
			case 'downloadCnmfGithubRepositories'
				[success] = downloadCnmfGithubRepositories('forceUpdate',forceUpdate);
			case 'downloadMiji'
				depStr = {'Save Fiji to default directory','Save Fiji to custom directory'};
				if options.guiEnabled==1
					[depIdxArray, ~] = listdlg('ListString',depStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Where to save Fiji?');
				else
					depIdxArray = 1;
				end
				depStr = depStr{depIdxArray};
				if depIdxArray==1
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
			case 'downloadCIAtahUtils'
				optionsH.gitNameDisp = {'ciatah_utils'};
				% optionsH.gitRepos = {'https://github.com/flatironinstitute/NoRMCorre'};
				optionsH.gitRepos = {'https://github.com/bahanonu/ciatah_utils'};				
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				% optionsH.gitName = {'NoRMCorre-public-master'};
				optionsH.gitName = {'ciatah_utils-master'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadTurboreg'
				optionsH.gitNameDisp = {'turboreg'};
				optionsH.gitRepos = {'http://tiny.ucsf.edu/ciatahTurboreg'};
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName = {'Motion_Correction_Turboreg'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadCellExtraction'
				optionsH.gitNameDisp = {'cellmax_clean','extract'};
				optionsH.gitRepos = {'https://github.com/schnitzer-lab/CELLMax_CLEAN','https://github.com/schnitzer-lab/EXTRACT'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadNoRMCorre'
				optionsH.gitNameDisp = {'normcorre'};
				% optionsH.gitRepos = {'https://github.com/flatironinstitute/NoRMCorre'};
				optionsH.gitRepos = {'https://github.com/bahanonu/NoRMCorre'};				
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				% optionsH.gitName = {'NoRMCorre-public-master'};
				optionsH.gitName = {'NoRMCorre-master'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadPatchWarp'
				optionsH.gitNameDisp = {'patchwarp'};
				optionsH.gitRepos = {'https://github.com/ryhattori/PatchWarp'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName = {'PatchWarp-main'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadGramm'
				optionsH.gitNameDisp = {'gramm'};
				optionsH.gitRepos = {'https://github.com/piermorel/gramm'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName = {'gramm-master'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadEXTRACT'
				optionsH.gitNameDisp = {'extract'};
				optionsH.gitRepos = {'https://github.com/schnitzer-lab/EXTRACT-public'};
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName = {'EXTRACT-public-master'};
				[success] = downloadGithubRepositories('options',optionsH);
			case 'downloadNeuroDataWithoutBorders'
				optionsH.gitNameDisp = {'nwbpkg','yamlmatlab','matnwb'};
				optionsH.gitRepos = {'https://github.com/schnitzer-lab/nwbpkg','https://github.com/ewiger/yamlmatlab'};
				% 'https://github.com/NeurodataWithoutBorders/matnwb'
				optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
                
                % Add matnwb
				optionsH.gitRepos = [optionsH.gitRepos 'https://github.com/NeurodataWithoutBorders/matnwb/archive/v2.2.5.3.zip'];
				optionsH.outputDir = optionsH.gitNameDisp;
				optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName{end} = 'matnwb-2.2.5.3';
                
				[success] = downloadGithubRepositories('options',optionsH);

				% Add NWB folders to path.
				ciapkg.nwb.setupNwb('checkDependencies',0);
				% obj.loadBatchFunctionFolders;
			case 'downloadBioFormats'
				optionsH.gitNameDisp = {'bfmatlab'};
				% optionsH.gitRepos = {'https://downloads.openmicroscopy.org/bio-formats/6.10.0/artifacts/bfmatlab.zip'};
				optionsH.gitRepos = {'https://downloads.openmicroscopy.org/bio-formats/7.3.0/artifacts/bfmatlab.zip'};
				optionsH.outputDir = optionsH.gitNameDisp;
				% optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
				optionsH.gitName = {'bfmatlab'};
				[success] = downloadGithubRepositories('options',optionsH);

				% Download SlideBook reader.
				downloadUrl = 'https://sites.imagej.net/SlideBook/jars/bio-formats/SlideBook6Reader.jar-20190125132114';
				% Ensure directory exists
				ciapkg.io.mkdir(fullfile(ciapkg.getDirExternalPrograms(),'bfmatlab_readers'));
				% Download
				rawSavePathDownloadTmp = fullfile(ciapkg.getDirExternalPrograms());
				rawSavePathDownloadTmp = fullfile(rawSavePathDownloadTmp,'bfmatlab_readers','SlideBook6Reader.jar');
				fprintf('Downloading %s file to %s\n',downloadUrl,rawSavePathDownloadTmp)
				websave(rawSavePathDownloadTmp,downloadUrl);

				slideBookPath = fullfile(ciapkg.getDirExternalPrograms(),'bfmatlab_readers','SlideBook6Reader.jar');
				if isfile(slideBookPath)==1
					javaaddpath(slideBookPath);
				end
				
			case 'downloadImageJ'
				% Download mij.jar and ij.ar with Box backup in case mij.jar site offline.
				downloadFiles = {'http://bigwww.epfl.ch/sage/soft/mij/mij.jar','http://rsb.info.nih.gov/ij/upgrade/ij.jar','http://tiny.ucsf.edu/3wFyol'};
				downloadFileNames = {'mij.jar','ij.jar','mij.jar'};
				imagejPath = [options.externalProgramsDir filesep 'imagej'];
				ciapkg.io.mkdir(imagejPath);
				nFiles = length(downloadFiles);
				downloadSuccess = zeros([1 nFiles],'logical');
				for i=1:nFiles
					rawSavePathDownload = [imagejPath filesep downloadFileNames{i}];
					downloadUrl = downloadFiles{i};
					if i==3
						if ~isempty(downloadSuccess)
							if downloadSuccess(1)==1
								continue
							else
								warning('mij.jar download on EPFL Miji site failed, using Box backup.');
							end
						end
					end
					if exist(rawSavePathDownload,'file')~=2|forceUpdate==1
						fprintf('Downloading %s file to %s\n',downloadUrl,rawSavePathDownload)
						wopts = weboptions;
						wopts.Timeout = 5;
						try
							websave(rawSavePathDownload,downloadUrl,wopts);
							downloadSuccess(i) = 1;
						catch err
							downloadSuccess(i) = 0;
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
					else
						downloadSuccess(i) = 1;
						fprintf('Already downloaded %s\n',rawSavePathDownload)
					end
				end
				manageMiji('startStop','setupImageJ');
			otherwise
				% nothing
		end
	end
	ciapkg.loadBatchFxns;
end