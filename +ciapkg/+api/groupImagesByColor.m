function [groupedImages] = groupImagesByColor(inputImages,groupVector,varargin)
	% Groups images by color based on input grouping vector.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputImages - [x y nImages]
		% groupVector - vector with same number of elements as images in inputImages
	% outputs
		%


	[groupedImages] = ciapkg.image.groupImagesByColor(inputImages,groupVector,'passArgs', varargin);
end