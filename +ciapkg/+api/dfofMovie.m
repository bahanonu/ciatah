function [dfofMatrix, inputMovieF0, inputMovieStd] = dfofMovie(inputMovie, varargin)
	% Does deltaF/F and other relative fluorescence changes calculations for a movie using bsxfun for faster processing.
	% Biafra Ahanonu
	% started 2013.11.09 [09:12:36]
	% inputs
		% inputMovie - either a [x y t] matrix or a char string specifying a HDF5 movie.
	% outputs
		%

	[dfofMatrix, inputMovieF0, inputMovieStd] = ciapkg.movie_processing.dfofMovie(inputMovie,'passArgs', varargin);
end