function [outputImages, outputMeanImageCorrs, outputMeanImageCorr2, outputMeanImageStruct] = createPeakTriggeredImages(inputMovie, inputImages, inputSignals, varargin)
	% Gets event triggered average image from an input movie based on cell images located in input image and trace matrix.
	% Biafra Ahanonu
	% started: 2015.09.28, abstracted from behaviorAnalysis
	% inputs
		% inputMovie - [x y frames]
		% inputImages - [x y nSignals]
		% inputSignals - [nSignals frames]
	% outputs
		%

	% changelog
		% 2016.01.02 [21:22:13] - added comments and refactored so that accepts inputImages as [x y nSignals] instead of [nSignals x y]
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2018.09 - large speedup by vectorizing corr2 and updating
		% readHDF5 chunking
	% TODO
		% Take 2 frames after peak and average to improve SNR

	%========================
	% Int: size in pixels to crop in the movie around cell centroid
	options.cropSize = 10;
	% hierarchy name in hdf5 where movie is
	options.inputDatasetName = '/1';
	% save time if already computed peaks
	% options.signalPeaks = [];
	options.signalPeaksArray = [];
	% show waitbar or not
	options.waitbarOn = 1;
	%
	options.normalizeOutput = 1;
	% Binary: 1 = read movie from HDD, 0 = load entire movie
	options.readMovieChunks = 0;
	% percent peaks to use
	options.pctPeaksToUse = 1;
	% Input pre-computed x,y coordinates for objects in images
	options.xCoords = [];
	options.yCoords = [];
	% Int: number of peaks to use
	options.maxPeaksToUse = 10;
	% Binary: float 0 - 1 threshold amount
	options.thresholdImages = [];
	% Matrix, pre-computed thresholdimages
	options.inputImagesThres = [];
	%
	options.runThresCorr = 0;
	%
	options.runSecondCorr = 0;
	%
	options.outputImageFlag = 1;
	% Int: Number of frames after event to average movie
	options.nFramesMeanTrigger = 1;
	% FID of the inputMovie via H5F.open to save time
	options.hdf5Fid = [];
	% Whether to keep HDF5 file open (for FID)
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
		clear varargin
		% load movie
		if ischar(inputMovie)
			if options.readMovieChunks==0
				inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
				movieDims = size(inputMovie);
			else
				% options.inputDatasetName
				movieDims = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'getMovieDims',1);
				movieDims = [movieDims.one movieDims.two movieDims.three];
			end

			% Force read movie chunks to be 1
			% options.readMovieChunks = 1;
			options.hdf5Fid = H5F.open(inputMovie);
			options.keepFileOpen = 1;
		else
			movieDims = size(inputMovie);
		end

		% decide whether to threshold images
		if ~isempty(options.inputImagesThres)
			inputImagesThres = options.inputImagesThres;
			options.inputImagesThres = [];
			options.thresholdImages = 1;
		elseif ~isempty(options.thresholdImages)
			inputImagesThres = thresholdImages(inputImages,'waitbarOn',options.waitbarOn,'binary',1,'threshold',options.thresholdImages);
		else
			inputImagesThres = thresholdImages(inputImages,'waitbarOn',options.waitbarOn,'binary',1,'threshold',0.4);
		end

		if isempty(options.signalPeaksArray)
			[~, signalPeaksArray] = computeSignalPeaks(inputSignals,'waitbarOn',options.waitbarOn,'makeSummaryPlots',0);
		else
			signalPeaksArray = options.signalPeaksArray;
		end

		% get the centroids and other info for movie
		if isempty(options.xCoords)
			[xCoords, yCoords] = findCentroid(inputImagesThres,'waitbarOn',options.waitbarOn,'runImageThreshold',0);
		else
			xCoords = options.xCoords;
			yCoords = options.yCoords;
		end
		xCoords = round(xCoords);
		yCoords = round(yCoords);

		nSignals = size(inputSignals,1);
		if options.outputImageFlag==1
			outputImages = NaN(size(inputImages),class(inputImages));
		else
			outputImages = [];
		end

		outputMeanImageCorrs = [];
		outputMeanImageCorrsMean = [];
		outputMeanImageCorr2 = [];
		outputMeanImageCorrMax = [];

		% reverseStr = '';
		% loop over all signals

		outputMeanImageStruct_corrPearson = [];
		outputMeanImageStruct_corrSpearman = [];
		outputMeanImageStruct_corrMax = [];
		outputMeanImageStruct_corrPearsonThres = [];
		outputMeanImageStruct_corrSpearmanThres = [];
		outputMeanImageStruct_corrMaxThres = [];

		options_cropSize = options.cropSize;
		options_maxPeaksToUse = options.maxPeaksToUse;
		options_readMovieChunks = options.readMovieChunks;
		options_inputDatasetName = options.inputDatasetName;
		options_thresholdImages = options.thresholdImages;
		options_runThresCorr = options.runThresCorr;
		options_waitbarOn = options.waitbarOn;
		options_runSecondCorr = options.runSecondCorr;
		options_outputImageFlag = options.outputImageFlag;

		options_hdf5Fid = options.hdf5Fid;
		options_keepFileOpen = options.keepFileOpen;

		% options_maxPeaksToUse

		disp('Starting movie images...')
		display(repmat('.',1,round(nSignals/20)))
		display(repmat('-',1,7))
		if options_readMovieChunks==1
			nWorkers = Inf;
		else
			nWorkers = 0;
		end

		% Only implement in Matlab 2017a and above
		if ~verLessThan('matlab', '9.2')
			D = parallel.pool.DataQueue;
			afterEach(D, @nUpdateParforProgress);
			p = 1;
			% N = nSignals;
		end
		% nInterval = round(nSignals/20);
		nInterval = 20;

		convertInputImagesToCell();
		% size(inputImages)
		% size(inputImagesThres)

		if options_readMovieChunks==0
			inputMovieCrop = cell(nSignals,1);
			for signalNo = 1:nSignals
				if isnan(xCoords(signalNo))
					inputMovieCrop{signalNo} = NaN;
					continue;
				end
				% get coordinates to crop
				xLow = xCoords(signalNo) - options_cropSize;
				xHigh = xCoords(signalNo) + options_cropSize;
				yLow = yCoords(signalNo) - options_cropSize;
				yHigh = yCoords(signalNo) + options_cropSize;
				% check that not outside movie dimensions
				xMin = 1 ;
				xMax = movieDims(2);
				yMin = 1 ;
				yMax = movieDims(1);

				% adjust for the difference in centroid location if movie is cropped
				xDiff = 0;
				yDiff = 0;
				if xLow<xMin xDiff = xLow-xMin; xLow = xMin; end
				if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
				if yLow<yMin yDiff = yLow-yMin; yLow = yMin; end
				if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end

				signalPeaksThis = signalPeaksArray{signalNo};
				signalPeaksThis = unique(signalPeaksThis);
				nPeaksToUse = length(signalPeaksThis);
				if ~isempty(options_maxPeaksToUse)
					% thisTrace = inputSignals(signalNo,:);
					thisTrace = inputSignals{signalNo};
					peakSignalAmplitude = thisTrace(signalPeaksThis);
					[~, peakIdx] = sort(peakSignalAmplitude,'descend');
					signalPeaksThis = signalPeaksThis(peakIdx);
					if nPeaksToUse>options_maxPeaksToUse
						nPeaksToUse = options_maxPeaksToUse;
					end
					signalPeaksThis = signalPeaksThis(1:nPeaksToUse);
					% signalPeaksThis = signalPeaksThis(randperm(length(signalPeaksThis),nPeaksToUse));
				end
				signalPeaksThis(signalPeaksThis>movieDims(3)) = [];
				inputMovieCrop{signalNo} = inputMovie(yLow:yHigh,xLow:xHigh,signalPeaksThis);
			end
		else
			inputMovieCrop = cell(nSignals,1);
		end

		xMax = movieDims(2);
		yMax = movieDims(1);
		% nFrames = size(inputSignals,2);
		nFrames = size(inputSignals{1},2);

		parfor(signalNo = 1:nSignals,nWorkers)
		% for signalNo = 1:nSignals
			try
				if isnan(xCoords(signalNo))||isnan(yCoords(signalNo))
					outputMeanImageCorrs(signalNo) = NaN;
					outputMeanImageCorrsMean(signalNo) = NaN;
					outputMeanImageCorr2(signalNo) = NaN;
					outputMeanImageCorrMax(signalNo) = NaN;
					outputMeanImageStruct_corrPearsonThres(signalNo) = NaN;
					outputMeanImageStruct_corrSpearmanThres(signalNo) = NaN;
					outputMeanImageStruct_corrMaxThres(signalNo) = NaN;
					if options_outputImageFlag==1
						outputImages(:,:,signalNo) = NaN;
					else
					end
					continue;
				end
				% get coordinates to crop
				xLow = xCoords(signalNo) - options_cropSize;
				xHigh = xCoords(signalNo) + options_cropSize;
				yLow = yCoords(signalNo) - options_cropSize;
				yHigh = yCoords(signalNo) + options_cropSize;
				% check that not outside movie dimensions
				xMin = 1 ;
				yMin = 1 ;

				% adjust for the difference in centroid location if movie is cropped
				xDiff = 0;
				yDiff = 0;
				if xLow<xMin xDiff = xLow-xMin; xLow = xMin; end
				if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
				if yLow<yMin yDiff = yLow-yMin; yLow = yMin; end
				if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end

				signalPeaksThis = signalPeaksArray{signalNo};
				signalPeaksThis = unique(signalPeaksThis);
				nPeaksToUse = length(signalPeaksThis);
				if ~isempty(options_maxPeaksToUse)
					% thisTrace = inputSignals(signalNo,:);
					thisTrace = inputSignals{signalNo};
					peakSignalAmplitude = thisTrace(signalPeaksThis);
					[~, peakIdx] = sort(peakSignalAmplitude,'descend');
					signalPeaksThis = signalPeaksThis(peakIdx);
					if nPeaksToUse>options_maxPeaksToUse
						nPeaksToUse = options_maxPeaksToUse;
					end
					signalPeaksThis = signalPeaksThis(1:nPeaksToUse);
					% signalPeaksThis = signalPeaksThis(randperm(length(signalPeaksThis),nPeaksToUse));
				end
				signalPeaksThis(signalPeaksThis>movieDims(3)) = [];
				%B = cellfun(@(x) num2str(x(:)'),signalPeaksThis,'UniformOutput',false);
				%[~,idx] = unique(B);
				%signalPeaksThis = signalPeaksThis(idx);

				if options_readMovieChunks==0
					% get frames when cell files into [x y frames] matrix
					% signalNo
					% signalImages = inputMovie(:,:,signalPeaksThis);
					% [yLow yHigh xLow xHigh]
					% crop to a region of x-y pixels around the cell's centroid
					% signalImagesCrop = signalImages(yLow:yHigh,xLow:xHigh,:);
					% signalImagesCrop = inputMovie(yLow:yHigh,xLow:xHigh,signalPeaksThis);
					signalImagesCrop = inputMovieCrop{signalNo};
				else
					% load only movie chunk needed directly from memory
					yLims = yLow:yHigh;
					xLims = xLow:xHigh;

					% signalPeaksThis
					if isempty(signalPeaksThis)
						signalPeaksThis = randperm(nFrames,2);
					end
					% signalImagesCrop = [];
					% signalImagesCrop = {};
					if nPeaksToUse>10
						nPeaksToUse = 10;
					end
					offset = {};
					block = {};
					for signalPeakFrameNo = 1:nPeaksToUse
						offset{signalPeakFrameNo} = [yLow-1 xLow-1 signalPeaksThis(signalPeakFrameNo)-1];
						block{signalPeakFrameNo} = [length(yLims) length(xLims) 1];
						% display(['loading chunk | offset: ' num2str(offset) ' | block: ' num2str(block)]);
						%[signalImagesCropTmp2] = readHDF5Subset(inputMovie, offset, block,'datasetName',options_inputDatasetName,'displayInfo',0);
						%signalImagesCrop{signalPeakFrameNo} = signalImagesCropTmp2;
						% if isempty(signalImagesCrop)
						% 	signalImagesCrop(:,:,1) = signalImagesCropTmp;
						% else
						% 	signalImagesCrop = cat(3,signalImagesCrop,signalImagesCropTmp);
						% end
					end
					[signalImagesCrop] = readHDF5Subset(inputMovie, offset, block,'datasetName',options_inputDatasetName,'displayInfo',0,'hdf5Fid',options_hdf5Fid,'keepFileOpen',options_keepFileOpen);
					%signalImagesCrop = cat(3,signalImagesCrop{:});
				end
				% corrVals = [];
				signalImagesCropTmp = signalImagesCrop;
				signalImagesCropTmp(isnan(signalImagesCropTmp)) = 0;
				% inputImageCrop = squeeze(inputImages(yLow:yHigh,xLow:xHigh,signalNo));
				inputImageCrop = squeeze(inputImages{signalNo}(yLow:yHigh,xLow:xHigh));

				% Mean image correlation
				outputMeanImageCorrsMean(signalNo) = corr2(nanmean(signalImagesCropTmp,3),inputImageCrop);


				if size(signalImagesCropTmp,3)>0
					% ===
					% Thanks and modified from https://stackoverflow.com/questions/26524950/how-to-apply-corr2-functions-in-multidimentional-arrays-in-matlab
					A = signalImagesCropTmp;
					% B = cat(3,inputImageCrop,inputImageCrop);
					B = inputImageCrop;

					szA = size(A);
					szB = size(B);
					szB(3) = 1;
					% If only have a single peak, compensate for that.
					if length(szA)==2
						szA(3) = 1;
					end
					dim12 = szA(1)*szA(2);

					a1 = bsxfun(@minus,A,mean(reshape(A,dim12,1,[])));
					b1 = bsxfun(@minus,B,mean(reshape(B,dim12,1,[])));

					v1 = reshape(b1,[],szB(3)).'*reshape(a1,[],szA(3));
					v2 = sqrt(sum(reshape(b1.*b1,dim12,[])).'*sum(reshape(a1.*a1,dim12,[])));

					corrVals = v1./v2;
					% corrVals = subfxnCalc2DCorr(signalImagesCropTmp,inputImageCrop);
				else
					corrVals = NaN;
				end
				% ===

				if options_runSecondCorr==1
					corrVals2 = [];
					for peakImageNo = 1:size(signalImagesCropTmp,3)
						% binMask = inputImageCrop>nanmax(inputImageCrop(:))*0.3;
						tmpImg = squeeze(signalImagesCropTmp(:,:,peakImageNo));

						% tmpImg(~binMask) = 0;
						% inputImageCrop(~binMask) = 0;
						% corrVals(peakImageNo) = corr2(inputImageCrop,tmpImg);
						if options_runSecondCorr==1
							corrVals2(peakImageNo) = corr(inputImageCrop(:),tmpImg(:),'type','Spearman');
						else
							corrVals2(peakImageNo) = NaN;
						end
						% corrVals2(peakImageNo) = NaN;

						% corrVals(peakImageNo) = corr2(inputImageCrop,squeeze(signalImagesCropTmp(:,:,peakImageNo)));
						% tmpImg = squeeze(signalImagesCropTmp(:,:,peakImageNo));
						% corrVals2(peakImageNo) = corr(inputImageCrop(:),tmpImg(:),'type','Spearman');
					end
				else
					corrVals2 = NaN(size(corrVals));
				end
				% corrVals
				outputMeanImageCorrs(signalNo) = nanmean(corrVals(:));
				outputMeanImageCorr2(signalNo) = nanmean(corrVals2(:));
				try
					outputMeanImageCorrMax(signalNo) = nanmax(corrVals(:));
				catch
					outputMeanImageCorrMax(signalNo) = NaN;
				end

				if options_runThresCorr==1&&~isempty(options_thresholdImages)
					% corrValsThres = [];

					corrVals2Thres = [];
					% inputImagesThresCrop = squeeze(inputImagesThres(yLow:yHigh,xLow:xHigh,signalNo));
					inputImagesThresCrop = squeeze(inputImagesThres{signalNo}(yLow:yHigh,xLow:xHigh));
					inputImageCropThres = inputImageCrop.*inputImagesThresCrop;

					% ===
					% Thanks and modified from https://stackoverflow.com/questions/26524950/how-to-apply-corr2-functions-in-multidimentional-arrays-in-matlab
					A = signalImagesCropTmp;
					% B = cat(3,inputImageCrop,inputImageCrop);
					B = inputImageCropThres;

					szA = size(A);
					szB = size(B);
					szB(3) = 1;
					dim12 = szA(1)*szA(2);

					a1 = bsxfun(@minus,A,mean(reshape(A,dim12,1,[])));
					b1 = bsxfun(@minus,B,mean(reshape(B,dim12,1,[])));

					v1 = reshape(b1,[],szB(3)).'*reshape(a1,[],szA(3));
					v2 = sqrt(sum(reshape(b1.*b1,dim12,[])).'*sum(reshape(a1.*a1,dim12,[])));

					corrValsThres = v1./v2;

					% corrValsThres = subfxnCalc2DCorr(signalImagesCropTmp,inputImageCropThres);
					outputMeanImageStruct_corrPearsonThres(signalNo) = nanmean(corrValsThres(:));
					try
						outputMeanImageStruct_corrMaxThres(signalNo) = nanmax(corrValsThres(:));
					catch
						outputMeanImageStruct_corrMaxThres(signalNo) = NaN;
					end

					if options_runSecondCorr==1
						for peakImageNo = 1:size(signalImagesCropTmp,3)
							% inputImagesThresCrop = squeeze(inputImagesThres(yLow:yHigh,xLow:xHigh,signalNo));
							% inputImageCropThres = inputImageCrop.*inputImagesThresCrop;
							% binMask = inputImageCrop>nanmax(inputImageCrop(:))*0.3;
							% tmpImg = squeeze(signalImagesCropTmp(:,:,peakImageNo));
							tmpImgThres = squeeze(signalImagesCropTmp(:,:,peakImageNo)).*inputImagesThresCrop;
							% corrValsThres(peakImageNo) = corr2(inputImageCropThres,tmpImgThres);
							corrVals2Thres(peakImageNo) = corr(inputImageCropThres(:),tmpImgThres(:),'type','Spearman');
						end
						outputMeanImageStruct_corrSpearmanThres(signalNo) = nanmean(corrVals2Thres(:));
					else
						outputMeanImageStruct_corrSpearmanThres(signalNo) = NaN;
					end

				else
					outputMeanImageStruct_corrPearsonThres(signalNo) = NaN;
					outputMeanImageStruct_corrSpearmanThres(signalNo) = NaN;
					outputMeanImageStruct_corrMaxThres(signalNo) = NaN;
				end

				%outputMeanImageStruct_corrPearson = outputMeanImageCorrs;
				%outputMeanImageStruct_corrSpearman = outputMeanImageCorr2;
				%outputMeanImageStruct_corrMax = outputMeanImageCorrMax;

				if options_outputImageFlag==1
					% take the average of all frames in matrix
					signalImagesCropSingle = squeeze(nanmean(signalImagesCrop,3));

					% signalImage = NaN(size(squeeze(inputImages(:,:,1))));
					signalImage = NaN(size(squeeze(inputImages{signalNo})));
					% size(signalImage)
					signalImage(yLow:yHigh,xLow:xHigh) = signalImagesCropSingle;

					% imagesc(signalImage);
					% store resulting image in
					% size(outputImages)
					outputImages(:,:,signalNo) = signalImage;
				end

				if ~verLessThan('matlab', '9.2')
					% Update
					send(D, signalNo);
				end
				% if (mod(signalNo,nInterval)==0|signalNo==nSignals)&options_waitbarOn==1
					% fprintf('.'); drawnow
					% cmdWaitbar(p,nSignals,'','inputStr','getting movie images','waitbarOn',1);
					% reverseStr = cmdWaitbar(signalNo,nSignals,reverseStr,'inputStr','getting movie images','waitbarOn',1);
				% end

			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
				outputImages(:,:,signalNo) = NaN;
				outputMeanImageCorrs(signalNo) = NaN;
				outputMeanImageCorrsMean(signalNo) = NaN;
				outputMeanImageCorr2(signalNo) = NaN;
				outputMeanImageCorrMax(signalNo) = NaN;
				outputMeanImageStruct_corrPearsonThres(signalNo) = NaN;
				outputMeanImageStruct_corrSpearmanThres(signalNo) = NaN;
				outputMeanImageStruct_corrMaxThres(signalNo) = NaN;
			end
		end

		outputMeanImageStruct.corrPearsonMean = outputMeanImageCorrsMean;
		outputMeanImageStruct.corrPearson = outputMeanImageCorrs;
		outputMeanImageStruct.corrSpearman = outputMeanImageCorr2;
		outputMeanImageStruct.corrMax = outputMeanImageCorrMax;
		outputMeanImageStruct.corrPearsonThres = outputMeanImageStruct_corrPearsonThres;
		outputMeanImageStruct.corrSpearmanThres = outputMeanImageStruct_corrSpearmanThres;
		outputMeanImageStruct.corrMaxThres = outputMeanImageStruct_corrMaxThres;

		if options.normalizeOutput==1
			% outputImages = permute(normalizeMovie(permute(outputImages,[2 3 1]),'normalizationType','zeroToOne'),[3 1 2]);
			outputImages = normalizeMovie(outputImages,'normalizationType','zeroToOne');
		end

		%
	catch err
		outputImages = [];
		outputMeanImageCorrs = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (mod(p,nInterval)==0||p==nSignals)&&options_waitbarOn==1
				cmdWaitbar(p,nSignals,'','inputStr','','waitbarOn',1);
			end
		end
	end
	function convertInputImagesToCell()
		% Convert input signals into cell array
		inputSignals = squeeze(mat2cell(inputSignals,ones(1,size(inputSignals,1)),size(inputSignals,2)));

		% Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputImages);
		% reshapeValue = size(inputImages);
		% Convert array to cell array, allows slicing (not contiguous memory block)
		inputImages = squeeze(mat2cell(inputImages,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

		% Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputImagesThres);
		% reshapeValue = size(inputImagesThres);
		% Convert array to cell array, allows slicing (not contiguous memory block)
		inputImagesThres = squeeze(mat2cell(inputImagesThres,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end
end
function corrVals = subfxnCalc2DCorr(signalImagesCropTmp,inputImageCrop)
	% ===
	% Thanks and modified from https://stackoverflow.com/questions/26524950/how-to-apply-corr2-functions-in-multidimentional-arrays-in-matlab
	A = signalImagesCropTmp;
	% B = cat(3,inputImageCrop,inputImageCrop);
	B = inputImageCrop;

	szA = size(A);
	szB = size(B);
	szB(3) = 1;
	dim12 = szA(1)*szA(2);

	a1 = bsxfun(@minus,A,mean(reshape(A,dim12,1,[])));
	b1 = bsxfun(@minus,B,mean(reshape(B,dim12,1,[])));

	v1 = reshape(b1,[],szB(3)).'*reshape(a1,[],szA(3));
	v2 = sqrt(sum(reshape(b1.*b1,dim12,[])).'*sum(reshape(a1.*a1,dim12,[])));

	corrVals = v1./v2;
end
