function [inputMovie] = detrendMovie(inputMovie,varargin)
	% Appends 3D data to existing dataset in hdf5 file, assumes x,y are the same, only appending z.
	% Biafra Ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	inputMovie = ciapkg.movie_processing.detrendMovie(inputMovie,'passArgs', varargin);
end