function [croppedPeakImages] = compareSignalToMovie(inputMovie, inputImages, inputSignal, varargin)
	% Shows a cropped version of inputMovie for each inputImages and aligns it to inputSignal peaks to make sure detection is working.
	% Biafra Ahanonu
	% started: 2013.11.04 [18:40:45]
	% inputs
		% inputMovie - matrix dims are [X Y t] - where t = number of time points
		% inputImages - matrix dims are [X Y n] - where n = number of filters, NOTE THE DIFFERENCE
		% inputSignal - matrix dims are [n t] - where n = number of signals, t = number of time points
	% outputs
		% none, this is a display function
	% changelog
		% 2014.01.18 [12:24:29] fully implemented, cut out from controllerAnalysis, need to improve handling at beginning of movie, but that's a playMovie function issue
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2017.02.14 - updated to support extended crosshairs and outlines.
	% TODO
		%

	%========================
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	% size in pixels to show signal image
	options.cropSize = 20;
	% frames before/after to show
	options.timeSeq = -10:10;
	% waitbar
	options.waitbarOn = 1;
	% whether to just get the peak images and ignore showing the movie
	options.getOnlyPeakImages = 0;
	% whether to just get the peak images and ignore showing the movie
	options.getOnlyMeanImage = 0;
	% 1 = plus shaped crosshairs, 0 = dot
	options.extendedCrosshairs = 1;
	%
	options.crosshairs = 1;
	%
	options.crossHairVal = NaN;
	% 1 = outline around each cut
	options.outlines = 1;
	options.outlineVal = [];
	%
	options.signalPeakArray = [];
	% set to 1 if input images should be normalized
	options.normalizeMovieImages = 0;
	% Binary: 1 = add padding, 0 = no padding
	options.addPadding = 0;
	% Input pre-computed x,y coordinates for objects in images
	options.xCoords = [];
	options.yCoords = [];
	% pre-set the min/max for movie display
	options.movieMinMax = [];
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(options.signalPeakArray)
		[signalPeaks, signalPeakArray] = computeSignalPeaks(inputSignal, 'makePlots', 0,'makeSummaryPlots',0,'waitbarOn',options.waitbarOn);
	else
		signalPeakArray = options.signalPeakArray;
	end

	% get the centroids and other info for movie
	% get the centroids and other info for movie
	if isempty(options.xCoords)
		[xCoords, yCoords] = findCentroid(inputImages,'waitbarOn',options.waitbarOn);
	else
		xCoords = options.xCoords;
		yCoords = options.yCoords;
	end

	cropSize = options.cropSize;
	nSignals = size(inputImages,3);
	nPoints = size(inputMovie,3);
	movieDims = size(inputMovie);
	timeSeq = options.timeSeq;

	% inputMovie(inputMovie>1.3) = NaN;
	% inputMovie(inputMovie<0.8) = NaN;

	% loop over all signals and visualize their peaks side-by-side with movie
	exitSignal = 0;
	for signalNo=1:nSignals
		peakLocations = signalPeakArray{signalNo};

		% get region to crop
		warning off;
		xLow = xCoords(signalNo) - cropSize;
		xHigh = xCoords(signalNo) + cropSize;
		yLow = yCoords(signalNo) - cropSize;
		yHigh = yCoords(signalNo) + cropSize;
		% check that not outside movie dimensions
		xMin = 1;
		xMax = movieDims(2);
		yMin = 1;
		yMax = movieDims(1);

		% adjust for the difference in centroid location if movie is cropped
		xDiff = 0;
		yDiff = 0;
		xLowO = xLow;
		xHighO = xHigh;
		yLowO = yLow;
		yHighO = yHigh;
		% if xLow<=xMin; xDiff = xLow-xMin; xLow = xMin+1; end
		% if xHigh>=xMax; xDiff = xHigh-xMax; xHigh = xMax-1; end
		% if yLow<=yMin; yDiff = yLow-yMin; yLow = yMin+1; end
		% if yHigh>=yMax; yDiff = yHigh-yMax; yHigh = yMax-1; end
		if xLow<xMin; xDiff = xLow-xMin; xLow = xMin; end
		if xHigh>xMax; xDiff = xHigh-xMax; xHigh = xMax; end
		if yLow<yMin; yDiff = yLow-yMin; yLow = yMin; end
		if yHigh>yMax; yDiff = yHigh-yMax; yHigh = yMax; end

		% need to add a way to adjust the cropped movie target point if near the boundary

		% get the cropped movie at peaks
		% yLow
		% yHigh
		% xLow
		% xHigh
		% peakLocations
		croppedPeakImages = inputMovie(yLow:yHigh,xLow:xHigh,peakLocations);
		firstImg = squeeze(inputImages(yLow:yHigh,xLow:xHigh,signalNo));

		if options.addPadding==1&(xDiff~=0|yDiff~=0)
			if xLowO<xMin; croppedPeakImages = padarray(croppedPeakImages,[0 abs(xDiff) 0],NaN,'pre'); firstImg = padarray(firstImg,[0 abs(xDiff) 0],NaN,'pre'); xDiff=0; end
			if xHighO>xMax; croppedPeakImages = padarray(croppedPeakImages,[0 abs(xDiff) 0],NaN,'post'); firstImg = padarray(firstImg,[0 abs(xDiff) 0],NaN,'post'); xDiff=0; end
			if yLowO<yMin; croppedPeakImages = padarray(croppedPeakImages,[abs(yDiff) 0 0],NaN,'pre'); firstImg = padarray(firstImg,[abs(yDiff) 0 0],NaN,'pre'); yDiff=0; end
			if yHighO>yMax; croppedPeakImages = padarray(croppedPeakImages,[abs(yDiff) 0 0],NaN,'post'); firstImg = padarray(firstImg,[abs(yDiff) 0 0],NaN,'post'); yDiff=0; end
		end

		firstImg = normalizeVector(firstImg,'normRange','zeroToOne');
		maxVec = nanmax(croppedPeakImages(:));
		minVec = nanmin(croppedPeakImages(:));
		firstImg = firstImg*maxVec;
		% firstImg = (firstImg-minVec)./(maxVec-minVec);
		% if options.normalizeMovieImages==1
		% end
		if options.getOnlyMeanImage==1
			croppedPeakImagesTmp = croppedPeakImages;
			croppedPeakImages(:,:,1) = firstImg;
			croppedPeakImages(:,:,2) = nanmean(croppedPeakImagesTmp,3);
			croppedPeakImages = croppedPeakImages(:,:,1:2);
			% playMovie(croppedPeakImages);
			return;
		end
		% firstImg = padarray(firstImg(2:end-1,2:end-1),[1 1],max(firstImg(:)));
		croppedPeakImages(:,:,end+1) = firstImg;
		% move inputImage to the front
		croppedPeakImages = circshift(croppedPeakImages,[0 0 1]);
		% croppedPeakImagesTmp = croppedPeakImages(:,:,end);
		% croppedPeakImagesTmp(:,:,end+1:end+(length(croppedPeakImages)-1)) = croppedPeakImages(:,:,1:(end-1));
		% croppedPeakImages = croppedPeakImagesTmp;
		for frameNo=1:size(croppedPeakImages,3)
			cropImg = squeeze(croppedPeakImages(:,:,frameNo));
			if options.normalizeMovieImages==1
				cropImg = normalizeVector(cropImg,'normRange','zeroToOne');
			end
			croppedPeakImages(:,:,frameNo) = cropImg;
		end
		% croppedPeakImages = normalizeMovie(croppedPeakImages,'normalizationType','meanDivision');
		cDims = size(croppedPeakImages);
		crossHairLocation = [round(cDims(2)/2+xDiff/2) round(cDims(1)/2+yDiff/2)];
		cHairX = crossHairLocation(1);
		cHairY = crossHairLocation(2);
		% add crosshair to images.

		if options.crosshairs==1
			% croppedPeakImages(cHairY,cHairX,:) = options.crossHairVal;
			croppedPeakImages(cHairY,cHairX,:) = NaN;
			switch options.extendedCrosshairs
				case 1
					croppedPeakImages(cHairY-1,cHairX,:) = croppedPeakImages(cHairY-1,cHairX,:)+options.crossHairVal;
					croppedPeakImages(cHairY+1,cHairX,:) = croppedPeakImages(cHairY+1,cHairX,:)+options.crossHairVal;
					croppedPeakImages(cHairY,cHairX-1,:) = croppedPeakImages(cHairY,cHairX-1,:)+options.crossHairVal;
					croppedPeakImages(cHairY,cHairX+1,:) = croppedPeakImages(cHairY,cHairX+1,:)+options.crossHairVal;
				case 2
					xS = size(croppedPeakImages,2);
					yS = size(croppedPeakImages,1);
					idxY = [1:round(0.25*yS) round(0.75*yS):yS];
					idxX = [1:round(0.25*xS) round(0.75*xS):xS];

					% idxY=1:size(croppedPeakImages,1);
					% idxX=1:size(croppedPeakImages,2);
					% idxY = setdiff(idxY,round(0.25*length(idxY)):round(0.75*length(idxY)));
					% idxX = setdiff(idxX,round(0.25*length(idxX)):round(0.75*length(idxX)));

					croppedPeakImages(idxY,cHairX,:) = croppedPeakImages(idxY,cHairX,:)+options.crossHairVal;
					croppedPeakImages(cHairY,idxX,:) = croppedPeakImages(cHairY,idxX,:)+options.crossHairVal;
				otherwise
					% body
			end
		end
		if options.outlines==1
			% display(['Adding outline'])
			if isempty(options.outlineVal)
				maxVal = nanmax(croppedPeakImages(:));
			else
				maxVal = options.outlineVal;
			end
			croppedPeakImages(1,:,:) = maxVal;
			croppedPeakImages(end,:,:) = maxVal;
			croppedPeakImages(:,1,:) = maxVal;
			croppedPeakImages(:,end,:) = maxVal;
		end

		if options.getOnlyPeakImages==0
			peakIdxs = bsxfun(@plus,timeSeq(:),peakLocations(:)');
			peakIdxs(find(peakIdxs<1)) = 1;
			peakIdxs(find(peakIdxs>nPoints)) = 1;
			% get cropped version of the movie
			croppedMovie = inputMovie(yLow:yHigh,xLow:xHigh,peakIdxs);
			inputMovieCut = inputMovie(:,:,peakIdxs);
			% inputMovieCut
			cDims = size(croppedMovie);
			exitSignal = playMovie(inputMovieCut,'extraMovie',croppedMovie,...
				'extraLinePlot',inputSignal(signalNo,peakIdxs),...
				'windowLength',30,...
				'extraTitleText',['signal #' num2str(signalNo) '/' num2str(nSignals) '    peaks: ' num2str(length(peakLocations))],...
				'primaryPoint',[xCoords(signalNo) yCoords(signalNo)],...
				'secondaryPoint',crossHairLocation,...
				'movieMinMax',options.movieMinMax);
				% 'recordMovie','test.avi',...
		end
		warning on;
		if exitSignal==1
			break;
		end
	end
end