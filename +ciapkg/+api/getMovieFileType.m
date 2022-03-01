function [movieType, supported, movieType2] = getMovieFileType(thisMoviePath)
	% Determine how to load movie, don't assume every movie in list is of the same type
	% Biafra Ahanonu
	% started: 2020.09.01 [‏‎14:16:57]
	% inputs
		% thisMoviePath - String: path to movie file.
	% outputs
		% movieType - Movie type
		% supported - logical, whether movie is supported by CIAtah.
		% movieType2 - Second movie type name (e.g. for NWB, where primary is HDF5).

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.08.13 [02:31:48] - Added HDF5 capitalized file extension.
		% 2022.01.04 [12:23:47] - Update all strcmp to endsWith to ensure finding file extension as there are cases where software will export metadata into files with naming schema like NAME.tif.xml for NAME.tif and this can cause issues when using strcmp without endsWith-like checks.
		% 2022.01.04 [13:28:05] - Update docs.
	% TODO
		%

	[movieType, supported, movieType2] = ciapkg.io.getMovieFileType(thisMoviePath,'passArgs', varargin);
end