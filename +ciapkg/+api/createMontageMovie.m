function [inputMovies] = createMontageMovie(inputMovies,varargin)
	% Creates a movie montage from a cell array of movies
	% adapted from signalSorter and other subfunction.
	% Biafra Ahanonu
	% started: 2015.04.09


	[inputMovies] = ciapkg.video.createMontageMovie(inputMovies,'passArgs', varargin);
end