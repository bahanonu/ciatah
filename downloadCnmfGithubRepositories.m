function [success] = downloadCnmfGithubRepositories(varargin)
	% Biafra Ahanonu
	% Downloads CNMF and CNMF-E repositories.
	% started: 2019.01.14 [10:23:05]

	%========================
	% options.downloadPreprocessed = 0;
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		signalExtractionDir = 'signal_extraction';

		gitNameDisp = {'CNMF-E','CNMF | CaImAn','cvx-rd'};
		gitRepos = {'https://github.com/bahanonu/CNMF_E/archive/master.zip','https://github.com/flatironinstitute/CaImAn-MATLAB/archive/master.zip','http://web.cvxr.com/cvx/cvx-rd.zip'};
		outputDir = {'cnmfe','cnmf_current','cvx_rd'};
		gitName = {'CNMF_E-master','CaImAn-MATLAB-master','cvx'};
		nRepos = length(outputDir);

		for gitNo = 1:nRepos
			display(repmat('=',1,7))
			fprintf('%s\n',gitNameDisp{gitNo});
			if exist([signalExtractionDir filesep outputDir{gitNo}],'dir')
				fprintf('Already extracted %s\n',[signalExtractionDir filesep outputDir{gitNo}]);
				continue;
			end
			% Make directory
			rawSavePathDownload = [signalExtractionDir];
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

		% if cvx is not in the path, ask user for file
		if isempty(which('cvx_begin'))
			display('Dialog box: Select cvx_setup.m (likely `calciumImagingAnalysis/signal_extraction/cvx_rd`')
			[filePath,folderPath,~] = uigetfile(['*.*'],'Select cvx_setup.m (likely `calciumImagingAnalysis/signal_extraction/cvx_rd`');
			run([folderPath filesep filePath]);
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
end