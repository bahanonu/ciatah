function [success] = convertInscopixIsxdToHdf5(inputFilePath,varargin)
	% Converts Inscopix proprietary ISXD to HDF5.
	% By default all dropped frames are included in the output as a frame full of zeros.
	% Biafra Ahanonu
	% started: 2019.01.15 [21:17:45]
	% inputs
		% inputMoviePath - char: path to ISXD file.
	% outputs
		%

	[success] = ciapkg.image.convertInscopixIsxdToHdf5(inputFilePath,'passArgs', varargin);
end