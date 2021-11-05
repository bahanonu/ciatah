function [success] = saveMatrixToFile(inputMatrix,savePath,varargin)
	% Save 3D matrix to arbitrary file type (HDF5, TIF, AVI for now).
	% Biafra Ahanonu
	% started: 2016.01.12 [11:09:53]
	% inputs
		% inputMatrix - [x y frame] movie matrix
		% savePath - character string of path to file with extension included,
	% outputs
		%

	[success] = ciapkg.io.saveMatrixToFile(inputMatrix,savePath,'passArgs', varargin);
end