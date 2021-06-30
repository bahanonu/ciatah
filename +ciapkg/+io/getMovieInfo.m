function [movieInfo] = getMovieInfo(inputMovie,varargin)
	% Wrapper to quickly get movie information. Options are the same as loadMovieList.
	% Biafra Ahanonu
	% started: 2020.09.29 [13:23:57]
	% inputs
		% inputMovie - [x y frames] or char string (path to movie).
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% ========================
	% DESCRIPTION
	% OPTIONS ARE THE SAME AS loadMovieList.
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
		movieInfo = [];
		movieInfo = loadMovieList(inputMovie,'getMovieDims',1,'passArgs',varargin);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end