function [inputImages, boundaryIndices, numObjects] = thresholdImages(inputImages,varargin)
	% Thresholds input images and makes them binary if requested. Also gets boundaries to allow for cell shape outlines in other code.
	% Biafra Ahanonu
	% started: 2013.10.xx
	% adapted from SpikeE
	%
	% inputs
		%
	% outputs
		%

	[inputImages, boundaryIndices, numObjects] = ciapkg.image.thresholdImages(inputImages,'passArgs', varargin);
end