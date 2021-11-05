function [output] = writeOptionsToHDF5(varargin)
	% Write options to HDF5, implemented in writeHDF5Data instead.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	[output] = ciapkg.hdf5.writeOptionsToHDF5('passArgs', varargin);
end