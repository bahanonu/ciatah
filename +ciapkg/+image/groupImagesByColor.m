function [groupedImages] = groupImagesByColor(inputImages,groupVector,varargin)
	% Groups images by color based on input grouping vector.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputImages - [x y nImages]
		% groupVector - vector with same number of elements as images in inputImages
	% outputs
		%
	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.07.20 [14:47:26] - Added fast thresholding option and other threshold image options.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Binary: 1 = threshold images, 0 = images already thresholded
	options.thresholdImages = 1;
	% Float: fraction of image maximum value below which all pixels set to zero (range 0:1)
	options.threshold = 0.5;
	% Binary: 1 = fast thresholding (vectorized), 0 = normal thresholding
	options.fastThresholding = 1;
	% image filter: none, median,
	options.imageFilter = 'none';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	if options.thresholdImages==1
		disp('Thresholding images...')
		[thresholdedImages] = thresholdImages(inputImages,'binary',1,'waitbarOn',0,'threshold',options.threshold,'fastThresholding',options.fastThresholding,'imageFilter',options.imageFilter);
	else
		thresholdedImages = inputImages;
	end
	if isempty(groupVector)
		groupVector = rand(1,size(thresholdedImages,3));
	end
	if size(groupVector,2)>size(groupVector,1)
		groupVector = groupVector';
	end
	% multiple thresholded images by the grouping vector
	groupedImages = bsxfun(@times,groupVector(:),permute(thresholdedImages,[3 1 2]));
	groupedImages = permute(groupedImages,[2 3 1]);
	% cellmap = createObjMap(groupedImages);
	% imagesc(cellmap);colorbar
	% title(options.title);
end