function [inputImages, inputSignals, valid, imageSizes, imgFeatures] = filterImages(inputImages, inputSignals, varargin)
	% Filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes.
	% Biafra Ahanonu
	% 2013.10.31
	% based on SpikeE code
	% inputs
		%
	% outputs
		%

	[inputImages, inputSignals, valid, imageSizes, imgFeatures] = ciapkg.image.filterImages(inputImages, inputSignals,'passArgs', varargin);
end