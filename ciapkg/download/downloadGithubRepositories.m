function [success] = downloadGithubRepositories(varargin)
	% Downloads Github repositories repositories.
	% Biafra Ahanonu
	% started: 2019.01.14 [10:23:05]
	% changelog
		% 2020.04.03 [11:15:32] - Allow inputs to use getOptions. Also allow force updating of git repository.
		% 2020.04.03 [14:02:33] - Save downloaded compressed files (e.g. zips) to a sub-folder.
		% 2020.06.28 [13:08:16] - Final implementation of force update, to bring to most current version of all git directories.
		% 2021.01.22 [13:18:25] - Update to allow regexp backup to find name of downloaded Github repo folder after unzipping, e.g. in cases where a release or non-master branch is downloaded. - IGNORE
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.

	%========================
	% 1 = force update of the git repository, 0 = skip if already downloaded
	options.forceUpdate = 0;
	% Str: directory of external download path.
	options.signalExtractionDir = ciapkg.getDirExternalPrograms();
	options.gitNameDisp = {'NoRMCorre'};
	options.gitRepos = {'https://github.com/flatironinstitute/NoRMCorre/archive/master.zip'};
	options.outputDir = {'normcorre'};
	options.gitName = {'NoRMCorre-master'};

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
		signalExtractionDir = options.signalExtractionDir;

		gitNameDisp = options.gitNameDisp;
		gitRepos = options.gitRepos;
		outputDir = options.outputDir;
		gitName = options.gitName;
		nRepos = length(outputDir);

		% If forcing an update, make sure to remove all external programs from the path
		if options.forceUpdate==1
			ciapkg.download.updatePathCleanup(options.signalExtractionDir);
			pause(0.02)
		end

		for gitNo = 1:nRepos
			display(repmat('=',1,7))
			fprintf('%s\n',gitNameDisp{gitNo});

			outDirPath = [signalExtractionDir filesep outputDir{gitNo}];
			% Make download directory
			rawSavePathDownload = [signalExtractionDir filesep '_downloads'];
			if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end
			% Download save path
			rawSavePathDownload = [rawSavePathDownload filesep outputDir{gitNo} '.zip'];

			% Remove directory and downloaded zip file if forcing an update.
			if options.forceUpdate==1
				if exist(outDirPath,'dir')
					fprintf('Removing directory to allow updates: %s\n', outDirPath);
					status = 0;
					tryCount = 1;
					% Try to delete several times else print out warning
					while status==0&tryCount<4
						[status,msg,msgID] = rmdir(outDirPath,'s');
						tryCount = tryCount + 1;
						pause(0.1);
					end
					if status==0
						warning('	Something went wrong removing the directory, check for proper permissions, etc.')
						warning(['	' msg])
						disp(['	' msgID])
					else
						disp('	Successfully removed directory!')
					end
				end
				if exist(rawSavePathDownload,'file')==2
					fprintf('Removing zip file to allow update: %s\n',rawSavePathDownload)
					delete(rawSavePathDownload)
				end
			else

			end

			% Download git repo zip
			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading %s file to %s\n',gitRepos{gitNo},rawSavePathDownload)
				websave(rawSavePathDownload,gitRepos{gitNo});
			else
				fprintf('Already downloaded %s\n',rawSavePathDownload)
			end

			% To ensure do not have mixed extraction directories, still check directory is there before extracting even in case of forced update.
			if exist(outDirPath,'dir')
				fprintf('Already extracted %s\n', outDirPath);
				continue;
			end

			% Unzip the repo file
			fprintf('Unzipping file %s\n',rawSavePathDownload)
			filenames = unzip(rawSavePathDownload,signalExtractionDir);
			% cellfun(@disp,filenames,'UniformOutput',false)

			% Rename to proper folder for calciumImagingAnalysis
			fprintf('Renaming %s to %s \n',[signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}])
			oldDir = [signalExtractionDir filesep gitName{gitNo}];
			newDir = [signalExtractionDir filesep outputDir{gitNo}];
			if strcmp(oldDir,newDir)==1
				disp('Same directory, ignore name change!')
			else
				movefile(oldDir,newDir);
			end

			% fprintf('\n\n')
		end

		success = 1;
	catch err
		success = 0;
		disp('Check internet connection or download and unzip files manually, see:')
		try
			cellfun(@disp,gitRepos,'UniformOutput',false)
		catch err2
			display(repmat('@',1,7))
			disp(getReport(err2,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
		fprintf('\n\n')
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end