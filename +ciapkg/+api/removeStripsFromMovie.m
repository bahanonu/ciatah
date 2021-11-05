function [inputMovie] = removeStripsFromMovie(inputMovie,varargin)
	% Removes vertical or horizontal stripes from movies.
	% Biafra Ahanonu
	% started: 2019.01.26 [14:17:16]
	% inputs
		% inputMovie = [x y frames] 3D matrix movie.
	% outputs
		% inputMovie = [x y frames] 3D matrix movie with stripes removed.

	[inputMovie] = ciapkg.movie_processing.removeStripsFromMovie(inputMovie,'passArgs', varargin);
end