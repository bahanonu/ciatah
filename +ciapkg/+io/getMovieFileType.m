function [movieType, supported, movieType2] = getMovieFileType(thisMoviePath,varargin)
	% [movieType, supported, movieType2] = getMovieFileType(thisMoviePath,varargin)
	%
	% Determine whether movie is a type supported by CIAtah, don't assume every movie in list is of the same type.
	%
	% Biafra Ahanonu
	% started: 2020.09.01 [14:16:57]
	%
	% Inputs
	% 	thisMoviePath - String: path to movie file.
	%
	% Outputs
	% 	movieType - Movie type
	% 	supported - logical, whether movie is supported by CIAtah.
	% 	movieType2 - Second movie type name (e.g. for NWB, where primary is HDF5).

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.08.13 [02:31:48] - Added HDF5 capitalized file extension.
		% 2022.01.04 [12:23:47] - Update all strcmp to endsWith to ensure finding file extension as there are cases where software will export metadata into files with naming schema like NAME.tif.xml for NAME.tif and this can cause issues when using strcmp without endsWith-like checks.
		% 2022.01.04 [13:28:05] - Update docs.
		% 2022.02.24 [09:37:55] - Added varargin support.
		% 2022.03.01 [08:56:21] - Added support for checking if a cell was accidentally input instead of a string path along with verifying that input was a string. Added support for oir and czi/lsm Olympus and Zeiss file formats that already was in loadMovieList.
		% 2022.03.14 [02:17:28] - Added MAT-file support.
		% 2022.07.05 [21:21:35] - Add SlideBook Bio-Formats support.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% DESCRIPTION
	% OPTIONS ARE THE SAME AS loadMovieList.
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	supported = 1;
	movieType = '';
	movieType2 = '';

	% Check to see if user input a cell array, attempt to grab string inside.
	if iscell(thisMoviePath)
		try
			thisMoviePath = thisMoviePath{1};
		catch
			supported = 0;
			return;
		end
	end

	if ~ischar(thisMoviePath)
		disp('Input not supported, input a string to full file path.')
		supported = 0;
		return;
	end

	try
		[pathstr, name, ext] = fileparts(thisMoviePath);
	catch
		supported = 0;
		return;
	end
	% files are assumed to be named correctly (lying does no one any good)
	movieType2 = '';
	if endsWith(ext,'.h5','IgnoreCase',true)||endsWith(ext,'.hdf5','IgnoreCase',true)||endsWith(ext,'.HDF5','IgnoreCase',true)
		movieType = 'hdf5';
	elseif endsWith(ext,'.nwb','IgnoreCase',true)
		movieType = 'hdf5';
		movieType2 = 'nwb';
	elseif endsWith(ext,'.tif','IgnoreCase',true)||endsWith(ext,'.tiff','IgnoreCase',true)
		movieType = 'tiff';
	elseif endsWith(ext,'.avi','IgnoreCase',true)
		movieType = 'avi';
	elseif endsWith(ext,'.mat','IgnoreCase',true)
		movieType = 'mat';
	elseif endsWith(ext,'.isxd','IgnoreCase',true) % Inscopix file format
		movieType = 'isxd';
	elseif endsWith(ext,'.oir') % Olympus file format
		movieType = 'bioformats';
	elseif endsWith(ext,{'.czi','.lsm'}) % Zeiss file format
		movieType = 'bioformats';
	elseif endsWith(ext,'.sld') % SlideBook file format
		movieType = 'bioformats';
	else
		movieType = '';
		supported = 0;
	end
	if isempty(movieType2)
		movieType2 = movieType;
	end
end