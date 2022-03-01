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

	[movieInfo] = ciapkg.io.getMovieInfo(inputMovie,'passArgs', varargin);
end