function [success] = downsampleHdf5Movie(inputFilePath, varargin)
	% Downsamples the Hdf5 movie in inputFilePath piece by piece and appends it to already created hdf5 file.
	% Biafra Ahanonu
	% started: 2013.12.19
	% base append code based on work by Dinesh Iyer (http://www.mathworks.com/matlabcentral/newsreader/author/130530)
	% note: checked between this implementation and imageJ's scale, they are nearly identical (subtracted histogram mean is 1 vs each image mean of ~1860, so assuming precision error).
	% inputs
		% inputFilePath
	% options
		% datasetName = hierarchy where data is stored in HDF5 file

	[success] = ciapkg.hdf5.downsampleHdf5Movie(inputFilePath,'passArgs', varargin);
end