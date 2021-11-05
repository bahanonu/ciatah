function [success] = writeHDF5Data(inputData,fileSavePath,varargin)
	% Saves input data to a HDF5 file, tries to preserve datatype.
	% Biafra Ahanonu
	% started: 2013.11.01
	%
	% inputs
		% inputData: matrix, [x y frames] preferred.
		% fileSavePath: str, path where HDF5 file should be saved.
	% outputs
		% success = 1 if successful save, 0 if error.
	% options
		% datasetname = HDF5 hierarchy where data should be stored

	[success] = ciapkg.hdf5.writeHDF5Data(inputData,fileSavePath,'passArgs', varargin);
end