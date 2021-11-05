function [inputMatrix, coords] = cropMatrix(inputMatrix,varargin)
	% Crops a matrix either by removing rows or adding NaNs to where data was previously.
	% Biafra Ahanonu
	% 2014.01.23 [16:06:01]
	% inputs
		% inputMatrix - a [m n p] matrix of any class type
	% outputs
		% inputMatrix - cropped or NaN'd matrix, same name to reduce memory usage

	[inputMatrix, coords] = ciapkg.image.cropMatrix(inputMatrix,'passArgs', varargin);
end