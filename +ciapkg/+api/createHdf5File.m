function createHdf5File(filename, datasetName, inputData, varargin)
	% Creates an HDF5 file at filename under given datasetName hierarchy and saves inputData.
	% Biafra Ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	ciapkg.hdf5.createHdf5File(filename, datasetName, inputData,'passArgs', varargin);
end