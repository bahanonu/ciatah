function [movieType, supported, movieType2] = getMovieFileType(thisMoviePath)
	% Determine how to load movie, don't assume every movie in list is of the same type
	% Biafra Ahanonu
	% started: 2020.09.01 [‏‎14:16:57]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.08.13 [02:31:48] - Added HDF5 capitalized file extension.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	supported = 1;
	try
		[pathstr,name,ext] = fileparts(thisMoviePath);
	catch
		movieType = '';
		movieType2 = '';
		supported = 0;
		return;
	end
	% files are assumed to be named correctly (lying does no one any good)
	movieType2 = '';
	if strcmp(ext,'.h5')||strcmp(ext,'.hdf5')||strcmp(ext,'.HDF5')
		movieType = 'hdf5';
	elseif strcmp(ext,'.nwb')
		movieType = 'hdf5';
		movieType2 = 'nwb';
	elseif strcmp(ext,'.tif')||strcmp(ext,'.tiff')
		movieType = 'tiff';
	elseif strcmp(ext,'.avi')
		movieType = 'avi';
	elseif strcmp(ext,'.isxd')
		movieType = 'isxd';
	else
		movieType = '';
		supported = 0;
	end
	if isempty(movieType2)
		movieType2 = movieType;
	end
end