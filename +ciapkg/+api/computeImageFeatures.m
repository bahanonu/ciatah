function [imgStats] = computeImageFeatures(inputImages, varargin)
	% Filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes.
	% Biafra Ahanonu
	% 2013.10.31
	% based on SpikeE code
	% inputs
	%   inputImages - [x y nSignals]
	% outputs
	%   imgStats -
	% options
	%   minNumPixels
	%   maxNumPixels
	%   thresholdImages

	[imgStats] = ciapkg.image.computeImageFeatures(inputImages,'passArgs', varargin);
end