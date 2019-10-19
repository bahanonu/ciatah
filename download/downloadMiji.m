function [success] = downloadMiji(varargin)
	% Biafra Ahanonu
	% Downloads the correct Miji version for each OS.
	% started: 2019.07.30 [09:58:04]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.10.15 [10:48:10] - Fix so DMGs downloaded for MAC have the proper file extension.
	% TODO
		%

	%========================
	% options.defaultDir = ['private' filesep 'programs'];
	options.defaultDir = ['_external_programs'];
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
		disp('Downloading Fiji (for use of Miji within Matlab)')
		if isempty(options.defaultDir)
			dispStr = 'Enter path where want to install Miji';
			disp(dispStr)
			options.defaultDir = uigetdir('\.',dispStr);
			% addpath(pathToMiji);
		else
		end
		signalExtractionDir = options.defaultDir;

		if ~exist(signalExtractionDir,'dir');mkdir(signalExtractionDir);fprintf('Made folder: %s',signalExtractionDir);end

		% mexw32                32 bit MATLAB on Windows
		% mexw64                64 bit MATLAB on Windows
		% mexglx                32 bit MATLAB on Linux
		% mexa64                64 bit MATLAB on Linux
		% mexmac                32 bit MATLAB on Mac
		% mexmaci               32 bit MATLAB on Intel-based Mac
		% mexmaci64             64 bit MATLAB on Intel-based Mac
		sysArch = mexext;

		urlH.mexw32 = 'https://downloads.imagej.net/fiji/Life-Line/fiji-win32-20151222.zip';
		urlH.mexw64 = 'https://downloads.imagej.net/fiji/Life-Line/fiji-win64-20151222.zip';
		urlH.mexglx = 'https://downloads.imagej.net/fiji/Life-Line/fiji-linux32-20151222.zip';
		urlH.mexa64 = 'https://downloads.imagej.net/fiji/Life-Line/fiji-linux64-20151222.zip';
		urlH.mexmac = 'https://downloads.imagej.net/fiji/Life-Line/fiji-macosx-20151222.dmg';
		urlH.mexmaci = 'https://downloads.imagej.net/fiji/Life-Line/fiji-macosx-20151222.dmg';
		urlH.mexmaci64 = 'https://downloads.imagej.net/fiji/Life-Line/fiji-macosx-20151222.dmg';

		gitNameDisp = {'Fiji (for Miji)'};
		gitRepos = {urlH.(sysArch)};
		outputDir = {''};
		gitName = {''};

		% if ismac
		%
		% elseif isunix
		%
		% elseif ispc
		%
		% else
		% 	disp('Platform not supported')
		% end

		nRepos = length(outputDir);

		for gitNo = 1:nRepos
			display(repmat('=',1,7))
			fprintf('%s\n',gitNameDisp{gitNo});
			% if exist([signalExtractionDir filesep outputDir{gitNo}],'dir')
			% 	fprintf('Already extracted %s\n',[signalExtractionDir filesep outputDir{gitNo}]);
			% 	continue;
			% end
			% Make directory
			rawSavePathDownload = [signalExtractionDir];
			if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end

			[pathstr,outputDir{gitNo},ext] = fileparts(gitRepos{gitNo});
			gitName{gitNo} = outputDir{gitNo};

			% Download git repo zip
			if ismac
				rawSavePathDownload = [rawSavePathDownload filesep outputDir{gitNo} '.dmg'];
			else
				rawSavePathDownload = [rawSavePathDownload filesep outputDir{gitNo} '.zip'];
			end

			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading %s file to %s\n',gitRepos{gitNo},rawSavePathDownload)
				websave(rawSavePathDownload,gitRepos{gitNo});
			else
				fprintf('Already downloaded %s\n',rawSavePathDownload)
			end

			unzipPath = [signalExtractionDir filesep outputDir{gitNo}];
			if ismac
				uiwait(msgbox(['Congrats! You are special and on a Mac. Please go to "' signalExtractionDir '" folder, install Fiji there (drag icon into folder), *then* click OK!']));
				modelAddOutsideDependencies('miji');
			elseif exist(unzipPath,'dir')~=7
				% Unzip the repo file
				if ~exist(unzipPath,'dir');mkdir(unzipPath);fprintf('Made folder: %s\n',unzipPath);end
				fprintf('Unzipping file %s to %s\n',rawSavePathDownload,unzipPath)
				% unzipPath = [signalExtractionDir filesep outputDir{gitNo}];
				filenames = unzip(rawSavePathDownload,unzipPath);
				% cellfun(@disp,filenames,'UniformOutput',unzipPath)
			else
				fprintf('Already downloaded %s\n',unzipPath)
			end

			% Rename to proper folder for calciumImagingAnalysis
			% fprintf('Renaming %s to %s \n',[signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}])
			% movefile([signalExtractionDir filesep gitName{gitNo}],[signalExtractionDir filesep outputDir{gitNo}]);
		end

		% if exist('unzipPath','var')&&exist(unzipPath,'dir')==7
		% 	defaultExternalProgramDir = unzipPath;
		% else
		% 	defaultExternalProgramDir = options.defaultDir;
		% end
		% modelAddOutsideDependencies('miji','defaultExternalProgramDir',defaultExternalProgramDir);
		defaultExternalProgramDir = options.defaultDir;
		modelAddOutsideDependencies('miji','defaultExternalProgramDir',defaultExternalProgramDir);

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