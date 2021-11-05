function [dataSubset, fid] = readHDF5Subset(inputFilePath, offset, block, varargin)
	% Gets a subset of data from an HDF5 file.
	% Biafra Ahanonu
	% started: 2013.11.10
	% based on code from MathWorks; for details, see http://www.mathworks.com/help/matlab/ref/h5d.read.html
	% inputs
		%
		% offset = cell array of [xOffset yOffset frameOffset]
		% block = cell array of [xDim yDim frames], xDim and yDim should be the same size across all cell arrays, note, the "frames" dimension SHOULD NOT have overlapping frames across cell arrays
	% options
		% datasetName = hierarchy where data is stored in HDF5 file
	% changelog
		% 2013.11.30 [17:59:14]
		% 2014.01.15 [09:59:53] cleaned up code, removed unnecessary options
		% 2017.01.18 [15:01:15] added option to deal with 3D data in 4D format with singleton 4th dimension
		% 2018.09.28 - changed so can read from multiple non-contiguous	slabs of data at the same time
		% 2019.02.13 [14:52:33] - Updated to support not closing file ID and importing an existing file ID to improve speed.
		% 2019.02.13 - Updated to support when user ask for multiple offsets at the same location in file.
		% 2019.02.13 [17:57:55] - Improved duplicate frame support, finds differences in frames, loads all unique as a single slab, then loads remaining and re-organizes to be in correct order.
		% 2019.05.03 [15:42:08] - Additional 4D support in cases where a 3D offset/block request is made.
		% 2019.10.10 [12:52:54] - Add correction for frame order. Select hyperslab in HDF5 makes blocks in sorted order, so after reading the explicit offset ordering is not the original unsorted order.
		% 2021.02.15 [12:02:36] - Updated support for files with datasets that contain 2D matrices.
	% TODO
		% DONE: Make support for duplicate frames more robust so minimize the number of file reads.

	[dataSubset, fid] = ciapkg.hdf5.readHDF5Subset(inputFilePath, offset, block,'passArgs', varargin);
end