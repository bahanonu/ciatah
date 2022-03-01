function [movieInfo] = getMovieInfo(inputMovie,varargin)
	% Wrapper to quickly get movie information. Options are the same as loadMovieList.
	% Biafra Ahanonu
	% started: 2020.09.29 [13:23:57]
	% inputs
		% inputMovie - [x y frames] or char string (path to movie).
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
        % 2022.01.20 [22:50:25] - Directly call loadMovieList and bypass ciapkg.api.
	% TODO
		%

	% import ciapkg.api.* % import CIAtah functions in ciapkg package API.

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
		movieInfo = ciapkg.io.loadMovieList(inputMovie,'getMovieDims',1,'passArgs',varargin);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end