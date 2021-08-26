function [success] = downloadCnmfGithubRepositories(varargin)
	% Biafra Ahanonu
	% Downloads CNMF and CNMF-E repositories.
	% started: 2019.01.14 [10:23:05]
	% changelog
		% 2020.04.03 [14:02:33] - Save downloaded compressed files (e.g. zips) to a sub-folder.
		% 2020.06.28 [13:08:16] - Final implementation of force update, to bring to most current version of all git directories.
		% 2020.06.28 [14:01:17] - Switch to calling downloadGithubRepositories for downloads to prevent bugs introduced by similar code between two functions.
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.

	%========================
	options.defaultExternalProgramDir = ciapkg.getDirExternalPrograms();
	% 1 = force update of the git repository, 0 = skip if already downloaded
	options.forceUpdate = 0;
	% options.downloadPreprocessed = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		signalExtractionDir = options.defaultExternalProgramDir;

		gitNameDisp = {'CNMF-E','CNMF | CaImAn','cvx-rd'};
		gitRepos = {'https://github.com/bahanonu/CNMF_E/archive/master.zip','https://github.com/flatironinstitute/CaImAn-MATLAB/archive/master.zip','http://web.cvxr.com/cvx/cvx-rd.zip'};
		outputDir = {'cnmfe','cnmf_current','cvx_rd'};
		gitName = {'CNMF_E-master','CaImAn-MATLAB-master','cvx'};
		nRepos = length(outputDir);

		optionsH.forceUpdate = options.forceUpdate;
		optionsH.signalExtractionDir = options.defaultExternalProgramDir;
		optionsH.gitNameDisp = gitNameDisp;
		optionsH.gitRepos = gitRepos;
		optionsH.outputDir = outputDir;
		optionsH.gitName = gitName;
		[success] = downloadGithubRepositories('options',optionsH);

		% if cvx is not in the path, ask user for file
		if isempty(which('cvx_begin'))
			checkCVXpath = [options.defaultExternalProgramDir filesep 'cvx_rd'];
			if exist(checkCVXpath,'dir')==7
				mfileToRun = [options.defaultExternalProgramDir filesep 'cvx_rd' filesep 'cvx_setup.m'];
				fprintf('AUTOMATICALLY running cvx_setup.m: %s\n',mfileToRun)
			else
				display('Dialog box: Select cvx_setup.m (likely `calciumImagingAnalysis/_external_programs/cvx_rd`')
				[filePath,folderPath,~] = uigetfile(['*.*'],'Select cvx_setup.m (likely `calciumImagingAnalysis/_external_programs/cvx_rd`');
				mfileToRun = [folderPath filesep filePath];
			end
			run(mfileToRun);
		end

		success = 1;
	catch err
		success = 0;
		disp('Check internet connection or download and unzip files manually, see:')
		cellfun(@disp,gitRepos,'UniformOutput',false)
		fprintf('\n\n')
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function subfxnOldDownload()
		% % If forcing an update, make sure to remove all external programs from the path
		% if options.forceUpdate==1
		% 	ciapkg.download.updatePathCleanup(options.signalExtractionDir);
		% end

		% for gitNo = 1:nRepos
		% 	display(repmat('=',1,7))
		% 	fprintf('%s\n',gitNameDisp{gitNo});

		% 	outDirPath = [signalExtractionDir filesep outputDir{gitNo}];

		% 	% Make directory
		% 	rawSavePathDownload = [signalExtractionDir filesep '_downloads'];
		% 	if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end
		% 	rawSavePathDownload = [rawSavePathDownload filesep outputDir{gitNo} '.zip'];

		% 	% Remove directory and downloaded zip file if forcing an update.
		% 	if options.forceUpdate==1
		% 		if exist(outDirPath,'dir')
		% 			fprintf('Removing directory to allow updates: %s\n', outDirPath);
		% 			status = rmdir(outDirPath,'s');
		% 			if status==0
		% 				disp('Something went wrong removing the directory, check for proper permissions, etc.')
		% 			end
		% 		end
		% 		if exist(rawSavePathDownload,'file')==2
		% 			fprintf('Removing zip file to allow update: %s\n',rawSavePathDownload)
		% 			delete(rawSavePathDownload)
		% 		end
		% 	end

		% 	% Download git repo zip
		% 	if exist(rawSavePathDownload,'file')~=2
		% 		fprintf('Downloading %s file to %s\n',gitRepos{gitNo},rawSavePathDownload)
		% 		websave(rawSavePathDownload,gitRepos{gitNo});
		% 	else
		% 		fprintf('Already downloaded %s\n',rawSavePathDownload)
		% 	end

		% 	% To ensure do not have mixed extraction directories, still check directory is there before extracting even in case of forced update.
		% 	if exist(outDirPath,'dir')
		% 		fprintf('Already extracted %s\n',outDirPath);
		% 		continue;
		% 	end

		% 	% Unzip the repo file
		% 	fprintf('Unzipping file %s\n',rawSavePathDownload)
		% 	filenames = unzip(rawSavePathDownload,signalExtractionDir);
		% 	% cellfun(@disp,filenames,'UniformOutput',false)

		% 	% Rename to proper folder for calciumImagingAnalysis
		% 	fprintf('Renaming %s to %s \n',[signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}])
		% 	movefile([signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}]);

		% 	% fprintf('\n\n')
		% end
	end
end