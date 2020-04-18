function [success] = downloadGithubRepositories(varargin)
	% Downloads Github repositories repositories.
	% Biafra Ahanonu
	% started: 2019.01.14 [10:23:05]
	% changelog
		% 2020.04.03 [11:15:32] - Allow inputs to use getOptions. Also allow force updating of git repository.
		% 2020.04.03 [14:02:33] - Save downloaded compressed files (e.g. zips) to a sub-folder.

	%========================
	% 1 = force update of the git repository, 0 = skip if already downloaded
	options.forceUpdate = 0;
	options.signalExtractionDir = '_external_programs';
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

		for gitNo = 1:nRepos
			display(repmat('=',1,7))
			fprintf('%s\n',gitNameDisp{gitNo});
			if exist([signalExtractionDir filesep outputDir{gitNo}],'dir')
				fprintf('Already extracted %s\n',[signalExtractionDir filesep outputDir{gitNo}]);
				continue;
			end
			% Make directory
			rawSavePathDownload = [signalExtractionDir filesep '_downloads'];
			if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end

			% Download git repo zip
			rawSavePathDownload = [rawSavePathDownload filesep outputDir{gitNo} '.zip'];
			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading %s file to %s\n',gitRepos{gitNo},rawSavePathDownload)
				websave(rawSavePathDownload,gitRepos{gitNo});
			else
				fprintf('Already downloaded %s\n',rawSavePathDownload)
			end

			% Unzip the repo file
			fprintf('Unzipping file %s\n',rawSavePathDownload)
			filenames = unzip(rawSavePathDownload,signalExtractionDir);
			% cellfun(@disp,filenames,'UniformOutput',false)

			% Rename to proper folder for calciumImagingAnalysis
			fprintf('Renaming %s to %s \n',[signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}])
			movefile([signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}]);

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