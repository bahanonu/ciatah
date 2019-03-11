function [k] = getObjCutMovie(inputMovie,inputImages,varargin)
	% Creates a movie cell array cut to a region around input cell images.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputMovie - [x y frames]
		% inputImages - [x y nSignals] - NOTE the dimensions, permute(inputImages,[3 1 2]) if you use [x y nSignals] convention
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]\
		% 2017.02.14 - updated to support extended crosshairs and outlines.
		% 2019.02.13 [14:52:33] - Update to add support to loading from disk and other speed improvements.
	% TODO
		%

	%========================
    % Vector: 3 element vector indicating [x y frames]
	options.inputMovieDims = [];
	% hierarchy name in hdf5 where movie is
	options.inputDatasetName = '/1';
    % number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
    options.frameList = [];
	% crop size from centroid in pixels
	options.cropSize = 10;
	%
	options.waitbarOn = 1;
	% vector [2 100 200] of frame to keep, if empty, output all
	options.filterVector = [];
	% 1 = make a montage of cut movies, 0 = output cell array of cuts
	options.createMontage = 1;
	% location of stim blink for montage.
	options.stimLocations = [];
	%
	options.crossHairsOn = 1;
	%
	options.crossHairVal = NaN;
	%
	options.extendedCrosshairs = 1;
	% Binary: 1 = add padding, 0 = no padding
	options.addPadding = 0;
	options.addPaddingForce = 0;
	options.outlines = 0;
	options.outlineVal = [];
    % Input pre-computed x,y coordinates for objects in images
    options.xCoords = [];
    options.yCoords = [];
    %
    options.hdf5Fid = [];
    options.keepFileOpen = 0;
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
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

	if isempty(options.inputMovieDims)
		if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
		    movieDims = loadMovieList(inputMovie,'frameList',[],'inputDatasetName',options.inputDatasetName,'getMovieDims',1,'displayInfo',0);
		    options.inputMovieDims = [movieDims.one movieDims.two movieDims.three];
		    % Force read movie chunks to be 1
		    % options.readMovieChunks = 1;
		else
		    options.inputMovieDims = size(inputMovie);
		end
	end

	if options.addPadding==1
		% display('Adding padding...')
		% inputImages = padarray(inputImages,[options.cropSize options.cropSize 0],NaN);
		% inputMovie = padarray(inputMovie,[options.cropSize options.cropSize 0],NaN);

		% padarray(inputImages,[options.cropSize options.cropSize 0],NaN);
		% padarray(inputMovie,[options.cropSize options.cropSize 0],NaN);
	end

	if options.addPaddingForce==1
		% display('Adding padding...')
		% inputImages = padarray(inputImages,[options.cropSize options.cropSize 0],NaN);
		% inputMovie = padarray(inputMovie,[options.cropSize options.cropSize 0],NaN);

		% padarray(inputImages,[options.cropSize options.cropSize 0],NaN);
		% padarray(inputMovie,[options.cropSize options.cropSize 0],NaN);
	end

	% get the centroids and other info for movie
	if isempty(options.xCoords)
		[xCoords, yCoords] = findCentroid(inputImages,'waitbarOn',options.waitbarOn);
	else
		xCoords = options.xCoords;
		yCoords = options.yCoords;
	end
	cropSize = options.cropSize;
	nSignals = size(inputImages,3);
	% nPoints = size(inputMovie,3);
	movieDims = options.inputMovieDims;

	reverseStr = '';
	k = cell([nSignals 1]);
	for signalNo = 1:nSignals
		% get region to crop
		% warning off;
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
        %yLow
        %yHigh
        %xLow
        %xHigh
        if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
            % load only movie chunk needed directly from memory
            yLims = yLow:yHigh;
            xLims = xLow:xHigh;

            % % signalPeaksThis
            % if isempty(signalPeaksThis)
            % 	signalPeaksThis = randperm(nFrames,2);
            % end
            % % signalImagesCrop = [];
            % % signalImagesCrop = {};
            % if nPeaksToUse>10
            % 	nPeaksToUse = 10;
            % end
            peakLocations = options.frameList;
            offset = {};
            block = {};
            nPeaksToUse = length(peakLocations);
            for signalPeakFrameNo = 1:nPeaksToUse
            	offset{signalPeakFrameNo} = [yLow-1 xLow-1 peakLocations(signalPeakFrameNo)-1];
            	block{signalPeakFrameNo} = [length(yLims) length(xLims) 1];
            end
            [k{signalNo}] = readHDF5Subset(inputMovie, offset, block,'datasetName',options.inputDatasetName,'displayInfo',0,'hdf5Fid',options.hdf5Fid,'keepFileOpen',options.keepFileOpen);
        else
			k{signalNo} = inputMovie(yLow:yHigh,xLow:xHigh,:);
        end

		if options.addPadding==1|options.addPaddingForce==1
			if xLowO<xMin; k{signalNo} = padarray(k{signalNo},[0 abs(xDiff) 0],NaN,'pre'); xDiff=0; end
			if xHighO>xMax; k{signalNo} = padarray(k{signalNo},[0 abs(xDiff) 0],NaN,'post'); xDiff=0; end
			if yLowO<yMin; k{signalNo} = padarray(k{signalNo},[abs(yDiff) 0 0],NaN,'pre'); yDiff=0; end
			if yHighO>yMax; k{signalNo} = padarray(k{signalNo},[abs(yDiff) 0 0],NaN,'post'); yDiff=0; end
		end

		cDims = size(k{signalNo});
		crossHairLocation = [round(cDims(2)/2+xDiff/2) round(cDims(1)/2+yDiff/2)];
		cHairX = crossHairLocation(1);
		cHairY = crossHairLocation(2);
		% add crosshair to images.

		if options.crossHairsOn==1
			% k{signalNo}(cHairY,cHairX,:) = options.crossHairVal;
            %cHairY
            %cHairX
			k{signalNo}(cHairY,cHairX,:) = NaN;
			switch options.extendedCrosshairs
				case 1
					tmpV1 = cast(options.crossHairVal,class(k{1}));
					k{signalNo}(cHairY-1,cHairX,:) = k{signalNo}(cHairY-1,cHairX,:)+tmpV1;
					k{signalNo}(cHairY+1,cHairX,:) = k{signalNo}(cHairY+1,cHairX,:)+tmpV1;
					k{signalNo}(cHairY,cHairX-1,:) = k{signalNo}(cHairY,cHairX-1,:)+tmpV1;
					k{signalNo}(cHairY,cHairX+1,:) = k{signalNo}(cHairY,cHairX+1,:)+tmpV1;
				case 2
					% idxY=1:size(k{signalNo},1);
					% idxX=1:size(k{signalNo},2);
					xS = size(k{signalNo},1);
					yS = size(k{signalNo},2);
					% idxY = setdiff(idxY,round(0.25*length(idxY)):round(0.75*length(idxY)));
					% idxX = setdiff(idxX,round(0.25*length(idxX)):round(0.75*length(idxX)));

					idxY = [1:round(0.25*yS) round(0.75*yS):yS];
					idxX = [1:round(0.25*xS) round(0.75*xS):xS];

					% k{signalNo}(:,cHairX,:) = k{signalNo}(:,cHairX,:)+options.crossHairVal;
					% k{signalNo}(cHairY,:,:) = k{signalNo}(cHairY,:,:)+options.crossHairVal;
					tmpV1 = cast(options.crossHairVal,class(k{1}));
					k{signalNo}(idxY,cHairX,:) = k{signalNo}(idxY,cHairX,:)+tmpV1;
					k{signalNo}(cHairY,idxX,:) = k{signalNo}(cHairY,idxX,:)+tmpV1;
				otherwise
					% body
			end
		end
		if options.outlines==1
			if isempty(options.outlineVal)
				maxVal = nanmax(k{signalNo}(:));
			else
				maxVal = options.outlineVal;
			end
			k{signalNo}(1,:,:) = maxVal;
			k{signalNo}(end,:,:) = maxVal;
			k{signalNo}(:,1,:) = maxVal;
			k{signalNo}(:,end,:) = maxVal;
		end
		reverseStr = cmdWaitbar(signalNo,nSignals,reverseStr,'inputStr','cutting out object movies','waitbarOn',options.waitbarOn,'displayEvery',2);
	end

	if options.createMontage==1
		[m, n, t] = size(k{1});
		if ~isempty(options.stimLocations)
			tmpMovie = NaN([m n t]);
			tmpMovie(:,:,options.stimLocations) = 1e5;
			k{end+1} = tmpMovie;
		end

		[xPlot, yPlot] = getSubplotDimensions(nSignals+1);
		squareNeed = xPlot*yPlot;
		length(k);
		dimDiff = squareNeed-length(k);
		% if dimDiff>0
			% k = cat(k,cell([dimDiff 1]));
		% end
		for ii=1:dimDiff
			k{end+1} = NaN([m n t]);
		end
		size(k);
		k = [k{:}];
		[m2, n2, t2] = size(k);
		nRows = yPlot+1;
		splitIdx = diff(ceil(linspace(1,n2,nRows)));
		splitIdx(end) = splitIdx(end)+1;
		k = mat2cell(k,m2,splitIdx,t2);
		k = vertcat(k{:});
	end

	% outputCutMovie = k;
	% clear k;
end