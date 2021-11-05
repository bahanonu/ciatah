function appendDataToHdf5(filename, datasetName, inputData, varargin)
	% Appends 3D data to existing dataset in hdf5 file, assumes x,y are the same, only appending z.
	% Biafra Ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	ciapkg.hdf5.appendDataToHdf5(filename, datasetName, inputData,'passArgs', varargin);
end