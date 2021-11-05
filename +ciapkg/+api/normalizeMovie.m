function [inputMovie] = normalizeMovie(inputMovie, varargin)
	% Takes an input movie and applies a particular spatial or temporal normalization (e.g. lowpass divisive).
	% Biafra Ahanonu
	% started: 2013.11.09 [09:25:48]
	% inputs
		% inputMovie = [x y frames] 3D matrix
	% outputs
		% inputMovie = [x y frames] 3D matrix normalized

	[inputMovie] = ciapkg.movie_processing.normalizeMovie(inputMovie,'passArgs', varargin);
end