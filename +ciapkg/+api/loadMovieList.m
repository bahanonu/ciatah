function [outputMovie, movieDims, nPixels, nFrames] = loadMovieList(movieList, varargin)
	% Load movies, automatically detects type (avi, tif, or hdf5) and concatenates if multiple movies in a list.
		% NOTE:
			% The function assumes input is 2D time series movies with [x y frames] as dimensions
			% If movies are different sizes, use largest dimensions and align all movies to top-left corner.
	% Biafra Ahanonu
	% started: 2013.11.01
	
	[outputMovie, movieDims, nPixels, nFrames] = loadMovieList(movieList, 'passArgs', varargin);
end
