function [inputImages, inputSignals, valid, imageSizes, imgFeatures] = filterImages(inputImages, inputSignals, varargin)
	% Filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes.
	% Biafra Ahanonu
	% 2013.10.31
	% based on SpikeE code
	% inputs
		%
	% outputs
		%

	% changelog
		% updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterImages, name-change due to alteration in function, can slowly replace in codes
		% 2014.04.08 [17:17:59] vectorized algorithm, speed increase. for loop left for potential use later.
		% 2016.08.20 [21:54:11] added some more options for better control of filtering
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2019.07.17 [00:29:16] - Added support for sparse input images (mainly ndSparse format).
	% TODO
		%

	%========================
	% get options
	options.threshold = 0.5;
	options.makePlots=1;
	options.waitbarOn=1;
	options.thresholdImages = 1;
	options.minNumPixels=10;
	options.maxNumPixels=100;
	options.SNRthreshold = 2;
	options.minPerimeter = 5;
	options.maxPerimeter = 50;
	options.minSolidity = 0.8;
	options.maxSolidity = 1.0;
	options.minEquivDiameter = 3;
	options.maxEquivDiameter = 30;
	options.maxEccentricity = 0.9;
	options.slopeRatioThreshold = 0.04;
	options.maxNumObjects = 3;
	% save time if already computed peaks
	options.testpeaks = [];
	options.testpeaksArray = [];
	% 1 = open workers, 0 = do not open workers
	options.parallel = 1;
	% list of image features to calculate using regionprops
	options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity'};
	% options.featureList = {'EquivDiameter','Area','Perimeter','Solidity'};
	options.modifyInputImage = 0;

	options.xCoords = [];
	options.yCoords = [];

	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	display('filtering images...')
	% options

	nImages = size(inputImages,3);

	valid = zeros(1,nImages);
	reverseStr = '';

	if options.thresholdImages==1
		if options.modifyInputImage==1
			[inputImages,~,numObjects] = thresholdImages(inputImages,'waitbarOn',options.waitbarOn,'binary',1,'threshold',options.threshold);
		else
			[inputImagesCopy,~,numObjects] = thresholdImages(inputImages,'waitbarOn',options.waitbarOn,'binary',1,'threshold',options.threshold);
		end
	else
		if options.modifyInputImage==1

		else
			inputImagesCopy = inputImages;
		end
		numObjects = ones([1 size(inputImages,3)]);
	end

	imageSizes = sum(sum(inputImagesCopy,1),2);
	imageSizes = imageSizes(:);
	if issparse(imageSizes)
		imageSizes = full(imageSizes);
	end
	% imageSizes
	[figHandle figNo] = openFigure(98, '');
		plot(1);
		plot(imageSizes,'b');
		box off;
		xlabel('rank');ylabel('image size (px)');


	% valid = (imageSizes>options.minNumPixels)&(imageSizes<options.maxNumPixels);
	% ensure vector dims are compatibly with previous scripts
	% valid = valid(:)';
	if options.modifyInputImage==1
		[imgStats] = computeImageFeatures(inputImages,'thresholdImages',0,'featureList',options.featureList,'xCoords',options.xCoords,'yCoords',options.yCoords);
	else
		[imgStats] = computeImageFeatures(inputImagesCopy,'thresholdImages',0,'featureList',options.featureList,'xCoords',options.xCoords,'yCoords',options.yCoords);

	end
	imgFeatures = cell2mat(struct2cell(imgStats))';

	[figHandle figNo] = openFigure(98, '');
		hold on
		plot(imgStats.Area,'r')

	% validCompute =...
	valid = ...
	(imgStats.Perimeter(:)>options.minPerimeter)...
	&(imgStats.Perimeter(:)<options.maxPerimeter)...
	&(imgStats.Area(:)<options.maxNumPixels)...
	&(imgStats.Area(:)>options.minNumPixels)...
	&(imgStats.Eccentricity(:)<options.maxEccentricity)...
	&(imgStats.Solidity(:)>options.minSolidity)...
	&(imgStats.Solidity(:)<=options.maxSolidity)...
	&(imgStats.EquivDiameter(:)>options.minEquivDiameter)...
	&(imgStats.EquivDiameter(:)<options.maxEquivDiameter)...
	&(numObjects(:)<options.maxNumObjects);

	% [(imgStats.Perimeter(:)>options.minPerimeter)...
	%  (imgStats.Perimeter(:)<options.maxPerimeter)...
	%  (imgStats.Area(:)<options.maxNumPixels)...
	%  (imgStats.Area(:)>options.minNumPixels)...
	%  (imgStats.Eccentricity(:)<options.maxEccentricity)...
	%  (imgStats.Solidity(:)>options.minSolidity)...
	%  (imgStats.Solidity(:)<=options.maxSolidity)...
	%  (imgStats.EquivDiameter(:)>options.minEquivDiameter)...
	%  (imgStats.EquivDiameter(:)<options.maxEquivDiameter)...
	%  (numObjects(:)<options.maxNumObjects)];
	% ...
	% &(~ismember(imgStats.Orientation,[90 -90 0]));
	valid = valid(:)';
	% valid = valid&validCompute(:)';

	% filter by SNR if inputSignals added
	if ~isempty(inputSignals)
		% SNR filter
		[signalSnr, ~] = computeSignalSnr(inputSignals,'testpeaks',options.testpeaks,'testpeaksArray',options.testpeaksArray,'signalCalcType','iterativeRemoveSignal');
		validSNR = signalSnr>options.SNRthreshold;
		valid = validSNR & valid;
		% Slope ratio filter
		[peakOutputStat] = computePeakStatistics(inputSignals,'waitbarOn',options.waitbarOn,'testpeaks',options.testpeaks,'testpeaksArray',options.testpeaksArray,'onlySlopeRatio',1);
		validSlope = peakOutputStat.slopeRatio>options.slopeRatioThreshold;
		valid = validSlope & valid;
		% [vs.signalPeaks, vs.signalPeakIdx] = computeSignalPeaks(vs.IcaTraces,'makePlots',0,'makeSummaryPlots',0);
		[figHandle figNo] = openFigure(95, '');
			plot(peakOutputStat.slopeRatio)
			xlabel('Rank');ylabel('Slope ratio')
	end

	% only keep valid images
	inputImages = inputImages(:,:,logical(valid));
	if ~isempty(inputSignals)
		inputSignals = inputSignals(logical(valid),:);
	else
		inputSignals = [];
	end

	display('done!');

	if options.makePlots==1
		[figHandle figNo] = openFigure(99, '');
			%
			subplot(2,1,1)
			hist(imageSizes,round(logspace(0,log10(max(imageSizes)))));
			box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
			set(gca,'xscale','log');
			h = findobj(gca,'Type','patch');
			set(h,'FaceColor',[0 0 0],'EdgeColor','w');
			%
			subplot(2,1,2)
			hist(find(valid==0),round(logspace(0,log10(max(find(valid==0))))));
			box off;title('rank of removed ICs');xlabel('rank');ylabel('count');
			set(gca,'xscale','log')
			h = findobj(gca,'Type','patch');
			set(h,'FaceColor',[0 0 0],'EdgeColor','w');
	end
end
	% for i = 1:nImages
	%     if options.thresholdImages==1
	%         thisFilt = squeeze(inputImages(i,:,:));
	%         thisFiltThresholded = thresholdImages(thisFilt,'waitbarOn',0);
	%     else
	%         thisFiltThresholded = squeeze(inputImages(i,:,:));
	%     end
	%     imageSizes(i) = sum(thisFiltThresholded(:)>0);
	%     % regionStat = regionprops(thisFiltThresholded, 'Eccentricity');
	%     % imageEccentricity = regionStat.Eccentricity;

	%     % display([num2str(imageSizes) ' ' num2str(imageSizes>minNumPixels)]);

	%     if (imageSizes(i)>minNumPixels)&(imageSizes(i)<maxNumPixels)
	%         valid(i) = 1;
	%     end
	%     reverseStr = cmdWaitbar(i,nImages,reverseStr,'inputStr','filtering inputs','waitbarOn',options.waitbarOn,'displayEvery',5);
	% end

	% [filterImageGroups] = groupImagesByColor(inputImages,valid+1);
	% filterImageGroups = createObjMap(filterImageGroups);
	% [figHandle figNo] = openFigure(2014+round(rand(1)*100), '');
	%     imagesc(filterImageGroups);
	%     colormap(customColormap([]));
	%     box off; axis off;
	%     % colorbar