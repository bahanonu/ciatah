function [vectorMovie] = createMovieFromVector(inputVector,movieDim,varargin)
	% Creates a movie with specific dimensions based on a vector; useful for natively synchronizing 1D signals with movies without having to hack plot commands.
	% Biafra Ahanonu
	% started: 2015.11.08
	% inputs
		% inputVector - 1D vector (any type, preferably single), e.g. [1 2 3 10 3 3 -1 20]
		% movieDim - 3 element 1D vector of matrix dimensions, e.g. [x y t] = [100 100 245]
	% outputs
		% vectorMovie - 3D movie ([x y t]) with dimensions of movieDim and class of inputVector

	[vectorMovie] = ciapkg.video.createMovieFromVector(inputVector,movieDim,'passArgs', varargin);
end