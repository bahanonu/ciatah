function [xCoords yCoords allCoords] = findCentroid(inputMatrix,varargin)
	% Finds the x,y centroid coordinates of each 2D in the 3D input matrix.
	% Biafra Ahanonu
	% started: 2013.10.31 [19:39:33]
	% adapted from SpikeE code
	% inputs
		%
	% outputs
		%
	% changelog
		% 2016.01.02 [21:22:13] - added comments and refactored so that accepts inputImages as [x y nSignals] instead of [nSignals x y]
		% 2016.08.06 - some changes to speed up algorithm by using thresholded rather than weighted sum of image.
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%

	%========================
	options.waitbarOn = 1;
	options.thresholdValue = 0.4;
	% threshold for images
	options.imageThreshold = 0.4;
	% whether need to re-run image thresholding
	options.runImageThreshold = 1;
	% whether to round centroid position to the nearest whole value
	options.roundCentroidPosition = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	inputDims = size(inputMatrix);
	inputDimsLen = length(inputDims);
	if inputDimsLen==3
		nImages = size(inputMatrix,3);
	elseif inputDimsLen==2
		nImages = 1;
		tmpImage = inputMatrix; clear inputMatrix;
		inputMatrix(:,:,1) = tmpImage;
		options.waitbarOn = 0;
	else
		return
	end

	if options.runImageThreshold==1
		inputMatrixThreshold = thresholdImages(inputMatrix,'waitbarOn',options.waitbarOn,'threshold',options.imageThreshold,'removeUnconnected',1);
	else
		inputMatrixThreshold = inputMatrix;
	end

	reverseStr = '';
	if options.waitbarOn==1
		display('finding centroids...')
	end

	options_thresholdValue = options.thresholdValue;
	options_roundCentroidPosition = options.roundCentroidPosition;
	options_waitbarOn = options.waitbarOn;

	parfor imageNum=1:nImages
		% threshold image
		thisImage = squeeze(inputMatrixThreshold(:,:,imageNum));
		% get the sum of the image
		% imagesum = sum(thisImage(:));
		% get coordinates
		[i,j,imgValue] = find(thisImage > options_thresholdValue);
		% weight the centroid by the intensity of the image

		% imgValue = imgValue*0; imgValue = imgValue+1;
		centroidPos = [mean(i(:).*(imgValue*100))/nanmean(imgValue*100) mean(j(:).*(imgValue*100))/nanmean(imgValue*100)];

		if length(centroidPos)==1
			% size(i)
			% size(j)
			% centroidPos
			centroidPos = [centroidPos 1];
		end
		if options_roundCentroidPosition==1
			xCoords(imageNum) = round(centroidPos(2));
			yCoords(imageNum) = round(centroidPos(1));
		else
			xCoords(imageNum) = centroidPos(2);
			yCoords(imageNum) = centroidPos(1);
		end

		% clf;imagesc(thisImage);colorbar; hold on;
		% plot(xCoords(imageNum),yCoords(imageNum),'r+')
		% pause

		% xTmp = repmat(1:size(thisImage,2), size(thisImage,1), 1);
		% yTmp = repmat((1:size(thisImage,1))', 1,size(thisImage,2));
		% xCoords(imageNum) = sum(sum(thisImage.*xTmp))/imagesum;
		% yCoords(imageNum) = sum(sum(thisImage.*yTmp))/imagesum;
		% use median instead of mean?

		if (mod(imageNum,20)==0|imageNum==nImages)&options_waitbarOn==1
			%reverseStr = cmdWaitbar(imageNum,nImages,reverseStr,'inputStr','finding centroids');
		end
	end

	allCoords = [xCoords(:) yCoords(:)];
end