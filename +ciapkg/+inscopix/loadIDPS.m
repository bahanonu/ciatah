function loadIDPS(varargin)
	% % Test that Inscopix MATLAB API ISX package installed.
	% Biafra Ahanonu
	% started: 2020.09.01 [14:37:07]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% ========================
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
	% ========================

	try
		if ismac
			baseInscopixPath = './';
		elseif isunix
			baseInscopixPath = './';
		elseif ispc
			baseInscopixPath = 'C:\Program Files\Inscopix\Data Processing';
		else
			disp('Platform not supported')
		end

		if exist(baseInscopixPath,'dir')==7
			pathToISX = baseInscopixPath;
		else
			baseInscopixPath = '.\';
			pathToISX = uigetdir(baseInscopixPath,'Enter path to Inscopix Data Processing program installation folder (e.g. +isx should be in the directory)');
		end
		addpath(pathToISX);
		help isx
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end