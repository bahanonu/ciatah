function [inputMovie] = downsampleMovie(inputMovie, varargin)
	% Downsamples a movie in either space or time, uses floor to calculate downsampled dimensions.
	% Biafra Ahanonu
	% started 2013.11.09 [09:31:32]
	%
	% inputs
		% inputMovie: a NxMxP matrix
	% options
		% downsampleType
		% downsampleFactor - amount to downsample in time

	[inputMovie] = ciapkg.movie_processing.downsampleMovie(inputMovie,'passArgs', varargin);
end