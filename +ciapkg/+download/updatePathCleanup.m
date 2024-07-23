function [status] = updatePathCleanup(inputDirectory,varargin)
	% Cleans up the specified directory and sub-directories from MATLAB path along with the Java path. Used to allow updating of directories.
	% Biafra Ahanonu
	% started: 2020.06.28 [13:35:52]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% DESCRIPTION
	% options.exampleOption = '';
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
		status = 0;
		if nargin==0||isempty(inputDirectory)
			disp('Empty input path, returning')
			return;
		end

		disp('Removing external programs folders from PATH to allow updating.')

		% Remove references to MEX files
		clear mex
		ciapkg.loadBatchFxns('excludeExternalPrograms');

		pathCell = regexp(path, pathsep, 'split');
		if verLessThan('matlab','9.1')
			matchIdx = ~cellfun(@isempty,regexpi(pathCell,inputDirectory));
		else
			matchIdx = contains(pathCell,inputDirectory);
		end
		onPath = any(matchIdx);
		if onPath==1
			rmPaths = join(pathCell(matchIdx),pathsep);
			disp(rmPaths);
			fprintf('Found in path, removing %s\n',inputDirectory);
			% genpath(thisRootPath)
			rmpath(rmPaths{1});
		end

		javaDyna = javaclasspath('-dynamic');
		% matchIdx = ~cellfun(@isempty,regexpi(javaDyna,'Fiji'));
		% javaDynaPathStr = join(javaDyna(matchIdx),''',''');
		javaDynaPathStr = join(javaDyna,''',''');
		if ~isempty(javaDynaPathStr)
			disp('Removing dynamic Java path.')
			eval(sprintf('javarmpath(''%s'');',javaDynaPathStr{1}))
		else
			disp('Empty Java dynamic path!')
		end

		% For good measure, conduct Java garbage collection.
		java.lang.System.gc()
		java.lang.Runtime.getRuntime().gc

		status = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end