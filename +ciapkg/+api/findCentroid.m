function [xCoords, yCoords, allCoords] = findCentroid(inputMatrix,varargin)
	% Finds the x,y centroid coordinates of each 2D in the 3D input matrix.
	% Biafra Ahanonu
	% started: 2013.10.31 [19:39:33]
	% adapted from SpikeE code
	% inputs
		%
	% outputs
		%

	[xCoords, yCoords, allCoords] = ciapkg.image.findCentroid(inputMatrix,'passArgs', varargin);
end