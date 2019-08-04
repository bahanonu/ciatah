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

	% changelog
		% updated: 2013.11.04 [15:30:05] added try...catch block to get around some errors for specific filters
		% 2014.01.14 refactored so it now can handle multiple images instead of just one
		% 2014.01.16 [16:30:36] fixed error after refactoring where thresholdedImage dims were not a 3D matrix, caused assignment errors.
		% 2014.03.13 slight change to support double and other non-integer images
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2017 or 2018 - added boundaryIndices support.
		% 2019.03.05 [19:21:30] Change to using bwareafilt to remove unconnected points from main structure
		% 2019.04.23 [19:51:26] Deal with images that are all zeros.
		% 2019.06.02 [22:14:03] - Revert back to slicing the 3D inputImages
		% 2019.07.17 [00:29:16] - Added support for sparse input images (mainly ndSparse format).
		% rather than converting to a cell
	% TODO
		%

	%========================
	options.threshold = 0.5;
	options.waitbarOn = 1;
	options.binary = 0;
	% 1 = open workers, 0 = do not open workers
	options.parallel = 1;
	% 1 = get boundary index, 0 = do nothing
	options.getBoundaryIndex = 0;
	% image filter: none, median,
	options.imageFilter = 'none';
	% image filter: none, median,
	options.imageFilterBinary = 'none';
	% size of neighborhood to use for median filter
	options.medianFilterNeighborhoodSize = 6;
	% normalize images
	options.normalizationType = [];
	% Binary: 1 = normalize each filter with max set to 1
	options.normalize = 1;
	% Binary: 1 = remove unconnected even when no binary thresholding
	options.removeUnconnected = 0;
	% Binary: 1 = remove unconnected even when binary thresholding
	options.removeUnconnectedBinary = 1;
	% Str: 'holes' or 'noholes'
	options.boundaryHoles = 'holes';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	nImages = size(inputImages);
	inputDims = size(inputImages);
	inputDimsLen = length(inputDims);
	if inputDimsLen==3
		nImages = size(inputImages,3);
	elseif inputDimsLen==2
		nImages = 1;
		if issparse(inputImages)
		else
			tmpImage = inputImages; clear inputImages;
			inputImages(:,:,1) = tmpImage;
		end
		
		options.waitbarOn = 0;
	else
		return
	end
	% loop over all images and threshold
	% reverseStr = '';
	% pre-allocate for speed
	% thresholdedImages = zeros(size(inputImages),class(inputImages));
	boundaryIndices = cell([nImages 1]);
	manageParallelWorkers('parallel',options.parallel);
	if options.waitbarOn==1
		disp('thresholding images...')
	end

	options_imageFilter = options.imageFilter;
	options_medianFilterNeighborhoodSize = options.medianFilterNeighborhoodSize;
	options_threshold = options.threshold;
	options_binary = options.binary;
	options_imageFilterBinary = options.imageFilterBinary;
	options_getBoundaryIndex = options.getBoundaryIndex;
	options_waitbarOn = options.waitbarOn;
	options_normalize = options.normalize;
	options_removeUnconnectedBinary = options.removeUnconnectedBinary;
	options_removeUnconnected = options.removeUnconnected;
	options_normalizationType = options.normalizationType;
	options_boundaryHoles = options.boundaryHoles;

	try
		% convertInputImagesToCell();
		nWorkers = Inf;
		% cellLoad = 1;
	catch
		disp('Memory error, using non-parfor')
		nWorkers = 0;
		% cellLoad = 0;
	end

	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D = parallel.pool.DataQueue;
		afterEach(D, @nUpdateParforProgress);
		p = 1;
		% N = nImages;
		nInterval = 100;
	end

	numObjects = [];

	replaceVal = 0;
	% startState = ticBytes(gcp);
	parfor(imageNo=1:nImages,nWorkers)
		% thisFilt = squeeze(inputImages{imageNo});
		thisFilt = inputImages(:,:,imageNo);
        if issparse(thisFilt)
            thisFilt = full(thisFilt);
        end
		% if cellLoad==1
		% else
			% thisFilt = squeeze(inputImages(:,:,imageNo));
		% end
		switch options_imageFilter
			case 'median'
				thisFilt = medfilt2(thisFilt,[options_medianFilterNeighborhoodSize options_medianFilterNeighborhoodSize]);
			otherwise
				% body
		end

		% Threshold the image
		maxVal=nanmax(thisFilt(:));
		cutoffVal = maxVal*options_threshold;
		thisFilt(thisFilt<cutoffVal) = replaceVal;
		thisFilt(isnan(thisFilt)) = replaceVal;

		% make image binary
		if options_binary==1
			thisFilt(thisFilt>=cutoffVal)=1;
			thisFilt = logical(thisFilt);
			switch options_imageFilterBinary
				case 'median'
					thisFilt = medfilt2(thisFilt,[options_medianFilterNeighborhoodSize options_medianFilterNeighborhoodSize]);
				otherwise
					% body
			end
			if options_removeUnconnectedBinary==1
				% Remove any pixels not connected to the image max value if there is a filter with max values at the edge, try...catch to get around errors
				try
					[~,numObjects(imageNo)] = bwlabel(thisFilt);
					warning off
					thisFilt = bwareafilt(thisFilt,1,'largest');
					warning on
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			end

		elseif options_normalize==1
			% normalize, don't divide by zero (e.g. for zero variance images)
			if maxVal~=0
				thisFilt=thisFilt/maxVal;
			else
			end
			thisFilt(isnan(thisFilt)) = replaceVal;
		else
			% do nothing
		end

		if options_removeUnconnected==1
			thisFilt2 = thisFilt;
			% thisFilt2(thisFilt2>=cutoffVal)=1;
			thisFilt2 = logical(thisFilt2);
			switch options_imageFilterBinary
				case 'median'
					thisFilt2 = medfilt2(thisFilt2,[options_medianFilterNeighborhoodSize options_medianFilterNeighborhoodSize]);
				otherwise
					% body
			end
			% Remove any pixels not connected to the image max value if there is a filter with max values at the edge, try...catch to get around errors
			try
				warning off
				thisFilt2 = bwareafilt(thisFilt2,1,'largest');
				thisFilt(~thisFilt2) = 0;
				warning on
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end

		% inputImages{imageNo} = thisFilt;
		inputImages(:,:,imageNo) = thisFilt;
		% if cellLoad==1
		% else
			% inputImages(:,:,imageNo)=thisFilt;
		% end

		if options_binary==1&&options_getBoundaryIndex==1
			thisFilt = logical(thisFilt);
			[B,~] = bwboundaries(thisFilt,options_boundaryHoles);
			for iNo = 1:length(B)
				boundaryIndices{imageNo} = [boundaryIndices{imageNo} sub2ind(size(thisFilt),B{iNo}(:,1),B{iNo}(:,2))'];
			end
			boundaryIndices{imageNo} = boundaryIndices{imageNo}(:)';
		elseif options_binary==0&&options_getBoundaryIndex==1
			thisFilt(thisFilt>=cutoffVal)=1;
			thisFilt = logical(thisFilt);
			try
				warning off
				thisFilt = bwareafilt(thisFilt,1,'largest');
				warning on
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end

			[B,~] = bwboundaries(thisFilt,options_boundaryHoles);
			for iNo = 1:length(B)
				boundaryIndices{imageNo} = [boundaryIndices{imageNo} sub2ind(size(thisFilt),B{iNo}(:,1),B{iNo}(:,2))'];
			end
			boundaryIndices{imageNo} = boundaryIndices{imageNo}(:)';
		end
		% within loop
		% if (mod(imageNo,20)==0|imageNo==nImages)&options_waitbarOn==1
			%reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','thresholding images');
		% end
		if ~verLessThan('matlab', '9.2')
			send(D, imageNo); % Update
		end
	end

	% tocBytes(gcp,startState)

	% inputImages = cat(3,inputImages{:});
	% if cellLoad==1
	% end

	% ensure backwards compatibility
	if nImages==1&&inputDimsLen<3
		% thresholdedImages = squeeze(thresholdedImages);
		inputImages = squeeze(inputImages);
	end
	if nImages>1&&~isempty(options_normalizationType)
		% thresholdedImages = permute(normalizeMovie(permute(thresholdedImages,[2 3 1]),'normalizationType','zeroToOne'),[3 1 2]);
		inputImages = normalizeMovie(inputImages,'normalizationType','zeroToOne');
		% thresholdedImages = normalizeMovie(thresholdedImages,'normalizationType','zeroToOne');
	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (p==2||mod(p,nInterval)==0||p==nImages)&&options_waitbarOn==1
				% cmdWaitbar(p,nImages,'','inputStr','','waitbarOn',1);
				if p==nImages
					fprintf('%d\n',round(p/nImages*100))
				else
					fprintf('%d|',round(p/nImages*100))
				end
			end
		end
	end
	function convertInputImagesToCell()
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputImages);
		% reshapeValue = size(inputImages);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputImages = squeeze(mat2cell(inputImages,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end
end

% [indx indy] = find(thisFilt==1); %Find the maximum
% [B,nObjs] = bwlabeln(thisFilt);
% objsN = [];
% for iii = 1:nObjs
%    objsN(iii) = length(find(B==iii));
% end
% [~,idxH] = max(objsN);
% thisFilt(B~=idxH) = 0;
%thisFilt(B~=B(indx,indy)) = 0;
% B = bwlabeln(thisFilt);
