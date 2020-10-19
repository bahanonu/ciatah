function [movieType, supported, movieType2] = getMovieFileType(thisMoviePath)
	% determine how to load movie, don't assume every movie in list is of the same type
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
	if strcmp(ext,'.h5')||strcmp(ext,'.hdf5')
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