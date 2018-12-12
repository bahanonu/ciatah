function [success] = viewAcceptedRejectedCellExtraction(inputImages,inputSignals,valid,inputMovie,varargin)
	% Plots cell image, peak transients, and image from activity in movie for accepted and rejected cells, useful for publications.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% Int: number of cells to show for EACH accepted and rejected
	options.nCellsShow = 3;
	% Int vector: vector of cell indexes if want to analyze a specific subset
	options.showSpecificCells = [];
	% if loading movie inside function, provide framelist
	options.frameList = [];
	% name in HDF5 file where data is stored
	options.inputDatasetName = '/1';
    % pre-compute signal peaks
    options.signalPeaks = [];
    options.signalPeaksArray = [];
    % Int: 1/2 length in pixels of crop square
    options.cropSizeLength = 20;
    % Float: Value between 0 and 1 of max to crop image to get outline
    options.thresholdOutline = 0.1;
    % ROI for peak signal plotting
    options.peakROI = [-20:20];
    % number of standard deviations above the threshold to count as spike
    options.numStdsForThresh = 3.0;
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
		success = 0;

		% make accepted/rejected vector a logical
		valid = logical(valid);

		% check whether movie is a string or not, load
		inputMovieClass = class(inputMovie);
		if strcmp(inputMovieClass,'char')
		    inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'frameList',options.frameList);
		    % [pathstr,name,ext] = fileparts(inputFilePath);
		    % options.newFilename = [pathstr '\concat_' name '.h5'];
		end

		% calculate grid size based
		nPlotsPerCell = 3;
		% [xPlot yPlot] = getSubplotDimensions(nPairs);
		xPlot = options.nCellsShow;
		yPlot = nPlotsPerCell*2;

		% get list of cells to show
		if isempty(options.showSpecificCells)
			% get list of cell's SNR
			[signalSnr ~] = computeSignalSnr(inputSignals,'testpeaks',options.signalPeaks,'testpeaksArray',options.signalPeaksArray,'numStdsForThresh',options.numStdsForThresh);
			signalSnr(isnan(signalSnr)) = nanmean(signalSnr(:));
			[signalSnr newIdx] = sort(signalSnr,'descend');

			% get top SNR accepted
			topSnrAccepted = newIdx(valid==1);
			topSnrAccepted = topSnrAccepted(1:options.nCellsShow);

			% get bottom SNR rejected
			bottomSnrRejected = newIdx(valid==0);
			bottomSnrRejected = bottomSnrRejected((end-options.nCellsShow+1):end);
			% bottomSnrRejected = bottomSnrRejected(randperm(length(bottomSnrRejected),options.nCellsShow));

			cellsToShow = cat(2,topSnrAccepted(:),bottomSnrRejected(:))';
			cellsToShow = cellsToShow(:);
		else
			cellsToShow = options.showSpecificCells;
		end

		% calculate signal peaks
		if isempty(options.signalPeaks)
		    [signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals,'makePlots', 0,'makeSummaryPlots',0,'waitbarOn',1);
		else
		    signalPeaks = options.signalPeaks;
		    signalPeaksArray = options.signalPeaksArray;
		end

		% get the peak statistics
		[peakOutputStat] = computePeakStatistics(inputSignals,'waitbarOn',1,'testpeaks',signalPeaks,'testpeaksArray',signalPeaksArray,'spikeROI',options.peakROI);

		figure;

		% loop and plot each cell
		tracesHere = inputSignals(cellsToShow,:);
		minValTraces = nanmin(tracesHere(:));
		maxValTraces = nanmax(tracesHere(:));
		for cellNo = 1:length(cellsToShow)
			cellIdx = cellsToShow(cellNo);

			thisTrace = inputSignals(cellIdx,:);

			% get peaks for this cell
			peakIdxs = signalPeaksArray{cellIdx};

			% get cropped view of the algorithm image
			inputImageAddObjCut = getObjCutMovie(inputImages,inputImages(:,:,cellIdx),'createMontage',0,'extendedCrosshairs',0,'crossHairsOn',0,'outlines',0,'waitbarOn',0,'cropSize',options.cropSizeLength,'addPadding',1);
			inputImageAddObjCut = inputImageAddObjCut{1};
			inputImageAddObjCut = inputImageAddObjCut(:,:,cellIdx);

			% get cropped view from the movie
			objCutMovie = getObjCutMovie(inputMovie(:,:,peakIdxs),inputImages(:,:,cellIdx),'createMontage',0,'extendedCrosshairs',0,'outlines',0,'waitbarOn',0,'cropSize',options.cropSizeLength,'crossHairsOn',0,'addPadding',1);
			objCutMovie = cat(3,objCutMovie{:});
			movieFrame = nanmean(objCutMovie,3);

			% create RGB with outline of cell
			[thresholdedImages boundaryIndices] = thresholdImages(inputImageAddObjCut,'binary',1,'getBoundaryIndex',1,'threshold',options.thresholdOutline);
			E = normalizeVector(double(movieFrame),'normRange','zeroToOne');
			tmpImg = zeros([size(E)]);
			tmpImg([boundaryIndices{:}]) = 1;
			movieRGB = [];
			movieRGB(:,:,1) = E+tmpImg;
			movieRGB(:,:,2) = E;
			movieRGB(:,:,3) = E;

			subplot(xPlot,yPlot,((cellNo-1)*nPlotsPerCell+1))
				imagesc(inputImageAddObjCut)
				box off;axis off;
				axis equal tight

			subplot(xPlot,yPlot,((cellNo-1)*nPlotsPerCell+2))
				imagesc(movieRGB)
				box off;axis off;
				axis equal tight

				imgRowY = size(movieRGB,1);
				imgColX = size(movieRGB,2);
				MICRON_PER_PIXEL = 2.37;
				options.scaleBarLengthMicron = 20;
				scaleBarLengthPx = options.scaleBarLengthMicron/MICRON_PER_PIXEL;
				% [imgColX-scaleBarLengthPx-round(imgColX*0.05) imgRowY-round(imgRowY*0.05) scaleBarLengthPx 5]
				rectangle('Position',[imgColX-scaleBarLengthPx-imgColX*0.05 imgRowY-imgRowY*0.05 scaleBarLengthPx 5],'FaceColor',[1 1 1],'EdgeColor','none')

			subplot(xPlot,yPlot,((cellNo-1)*nPlotsPerCell+3))
				spikeCenterTrace = peakOutputStat.spikeCenterTrace{cellIdx};
				% spikeCenterTrace
				avgSpikeTrace = peakOutputStat.avgSpikeTrace(cellIdx,:);
				% avgSpikeTrace
				peakROI = options.peakROI;
				peakSignalAmplitude = thisTrace(peakIdxs(:));
				[peakSignalAmplitude peakIdx] = sort(spikeCenterTrace(:,round(end/2)+1),'descend');
				spikeCenterTrace = spikeCenterTrace(peakIdx,:);
				if size(spikeCenterTrace,1)>20
				    spikeCenterTrace = spikeCenterTrace(1:20,:);
				end

				plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
				hold on;
				plot(peakROI, avgSpikeTrace,'r', 'LineWidth',3);box off;
				ylim([minValTraces maxValTraces]);
				% plot(peakROI, nanmean(spikeCenterTrace),'Color',[1 0 0 1.0], 'LineWidth',2);box off;
				% add in zero line
				% xval = 0;
				% x=[xval,xval];
				% y=[minValTraces maxValTraces];
				% plot(x,y,'r'); box off;
		end

		success = 1;
	catch err
		success = 0;
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end