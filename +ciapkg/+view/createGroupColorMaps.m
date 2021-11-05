function [output1,output2] = createGroupColorMaps(inputImages,groupVector,varargin)
	% Make an outline and filled colormap for cells in inputImages based on groups in groupVector
	% Biafra Ahanonu
	% started: 2020.04.18 [20:09:25]
	% inputs
		% inputImages: [x y N] matrix where N = # of cells
		% groupVector: [1 N] vector where N = # of cells
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Int: make larger values to make cell outlines have greater width
	options.dilateOutlinesFactor = 0;
	% Float: threshold for thresholding images, fraction of maximum image value.
	options.threshold = 0.4;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		% Input images, e.g. from PCA-ICA or CNMF
		% inputImages = pcaicaAnalysisOutput.IcaFilters;

		% Get boundary indices (for outline of cell locations)
		[inputImagesThresholded, boundaryIndices] = thresholdImages(inputImages,'binary',0,'threshold',options.threshold,'imageFilter','none','getBoundaryIndex',1,'imageFilterBinary','none');

		dilateOutlinesFactor = options.dilateOutlinesFactor;

		% integers indicating group association for each cell
		% NOTE: change to make relevant for your image
		% groupVector = [randi(3,[1 size(inputImages,3)])];

		groupNums = unique(groupVector);
		nGroups = length(groupNums);
		nullImage = zeros([size(inputImages(:,:,1))]);
		for gNo = 1:nGroups
			nullImageTmp = zeros([size(inputImages(:,:,1))]);
			boundaryIndicesTmp = boundaryIndices(groupNums(gNo)==groupVector);
			nullImageTmp([boundaryIndicesTmp{:}]) = groupNums(gNo);
			% Make outlines for group larger
			nullImageTmp = imdilate(nullImageTmp,strel('disk',dilateOutlinesFactor));
			nullImage = nullImage + nullImageTmp;
		end
		figure;
		subplot(1,2,1)
		unique(nullImage(:))
		imagesc(nullImage)
		colorList = [0 0 0;hsv(nanmax(nullImage(:)))];
		colorList
		colormap(gca,colorList)
		axis equal tight;box off
		colorbar
		title('Outline cell map')

		% Or create cellmap with binary cell images split along group dimensions
		% groupVector should be 1:N groups, DO NOT associate group with zero value
		colorImg = nanmax(groupImagesByColor(inputImages,groupVector,'thresholdImages',1),[],3);
		% figure;
		subplot(1,2,2)
		imagesc(colorImg)
		% colormap([0 0 0;hsv(nGroups+1)])
		colormap(gca,colorList(1:(nanmax(colorImg(:))+1),:))
		axis equal tight; box off;
		colorbar
		title('Filled cell map')
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end