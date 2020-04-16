function [inputImages, inputSignals, choices] = signalSorter(inputImages,inputSignals,varargin)
	% Displays a GUI for sorting images (e.g. cells) and their associated signals (e.g. fluorescence activity traces). Also does preliminary sorting based on image/signal properties if requested by user.
	% See following URL for details of GUI and tips on manual sorting: https://github.com/bahanonu/calciumImagingAnalysis/wiki/Manual-cell-sorting-of-cell-extraction-outputs.
	% Biafra Ahanonu
	% started: 2013.10.08
	% Dependent code
		% getOptions.m, createObjMap.m, removeSmallICs.m, identifySpikes.m, etc., see repository
	% inputs
		% inputImages - [x y N] matrix where N = number of images, x/y are dimensions. Use permute(inputImages,[2 3 1]) if you use [N x y] for matrix indexing.
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames.
		% inputID - obsolete, kept for compatibility, just input empty []
		% nSignals - obsolete, kept for compatibility
	% outputs
		% inputImages - [N x y] matrix where N = number of images, x/y are dimensions with only manual choices kept.
		% inputSignals
		% choices

	% changelog
		% 2013.10.xx changed to ginput and altered UI to show more relevant information, now shows a objMap overlayed with the current filter, etc.
		% 2013.11.01 [15:48:56]
			% Finished removing all cell array indexing by day, increase maintainability.
			% Input is now filters and traces instead of loading a directory inside fxn (which is cryptic). Output is filtered traces.
			% Can now move forward AND back, 21st century stuff. Also changed some of the other controls to make UI more user friendly.
		% 2013.11.03 [12:45:03] added a panel so that you can see the average trace around all spikes in an IC filter's trace along with several other improvements.
		% 2013.11.04 [10:30:40] changed invalid subscripting to valid, previous way involved negating choices, prone to error.
		% 2013.11.13 [09:25:24] added the ability to loop around and pre-maturely exit
		% 2013.11.19 [09:19:07] auto-saves decisions in case of a crash or other problem
		% 2013.12.07 [16:30:32] added more option (e.g. 's' key to mark rest of signals as bad)
		% 2013.12.10 [09:38:57] refactored a bit to make code more clear
		% 2013.12.15 [22:48:56] now overlays the good and bad images onto the entire image cell map, good for determining whether you've hit all the 'relevant' images
		% 2014.01.05 [09:23:54] small amount of
		% 2014.01.27 - started better integration auto-detecting based on SNR, etc.
		% 2014.03.06 - integrated support for manual scoring of automatic classification via abstraction (not explicitly loading classifier, but scoring pre-defined questionable input signals)
		% 2014.03.12 - sort by SNR or random, view montage of movie frames at peak or compare the signal to the movie directly
		% 2014.05.19 - improved SNR sort for NaNs, montage handles traces with no peaks, etc.
		% 2015.11.22 - refactored to make createStimCutMovieMontage faster
		% 2016.08.06 [20:51:02] - updated to make obj cut movie montage the default instead of static images, more useful.
		% 2018.10.08 [14:43:10] - good cells now will always be on top regardless of overlapping bad cells, option to widen selector line.
		% 2018.10.21 - Misc. changes to make it easier to look at overlapping cells.
		% 2019.01.29 [11:19:10] - Changed how movie transient montages are created, no longer use the montage function and several other Cdata vs. imagesc related changes to improve speed, esp. in R2018b.
		% 2019.02.13 Made compatible with large movies, just input string into options.inputMovie.
		% 2019.02.13 [16:56:21] Major speed improvements going between cells by adding options.hdf5Fid (to several functions, in order to relay to readHDF5Subset in the end) to reduce readHDF5Subset fopen overhead.
		% 2019.03.07 [11:27:16] Change to display of movie cut images to reduce flicker on display of each new image
		% 2019.03.25 [21:53:06] - Pre-load transient still frames at the transient peak.
		% 2019.04.17 [13:16:52] - Added option to put secondary trace, as is the case for CELLMax and CNMF(-E).
		% 2019.05.14 [10:59:56] - Made changes to how often colormap and other display elements are updated to improve performance on MATLAB 2018b.
		% 2019.05.15 [16:17:42] - Added asynchronous loading of next cells when readMovieChunks = 0 and preComputeImageCutMovies = 0 to improve performance. Loads options.nSignalsLoadAsync number of cells in advance.
		% 2019.05.22 [22:16:44] - Changes (e.g. move colormap, caxis, etc. calls around) to reduce slow reduction in performance as more cells are chosen.
		% 2019.06.10 [10:24:54] - Updates to async memory handling to reduce RAM usage.
		% 2019.06.14/2019.06.15 [22:17:21] - Separate legend and keyboard shortcuts into different window, various GUI improvements.
		% 2019.07.17 [00:29:16] - Added support for sparse input images (mainly ndSparse format). Reduced memory usage for cases when "options.preComputeImageCutMovies = 0" and "options.inputMovie" is a matrix (NOT a path to a movie) by skipping async/use of parallel workers.
		% 2019.07.17 [20:37:09] - Added ability to change GUI font.
		% 2019.07.23 [03:42:48] - Enclosed user selections inside try-catch to better handle invalid input robustly with checks added in the subfxn as needed.
		% 2019.08.19 [18:07:27] - Added zoom and other functionality and a lock-check to prevent skipping forward to new cells based on pressing keyboard too long carrying over keypress into next source output, causing it to skip over outputs. Added progress bar for cell, non-cell, and unknown.
		% 2019.08.30 [14:46:22] - Update to use imcontrast to adjust image/movie contrast.
		% 2019.09.12 [15:39:12] - Legend is now closed on exiting signalSorter.
		% 2019.09.16 [11:39:28] - Improved computing of min/max of movie for display purposes.
		% 2019.10.03 [15:37:36] - Added a check for inputImages and inputSignals dimensions. Exit function if incorrect to avoid later errors. We do not silently transpose or permute the matrices since that can cause other issues.
		% 2019.10.09 [22:10:38] - New feature! Can now use B to toggle between movie montage of peaks and using a line to specifically select locations of the movie to view. Useful for checking problematic or interesting peaks.
		% 2019.10.10 [11:41:47] - Additional improvements to frame select feature and readHDF5Subset unique fix to ensure movie montage shows images in order of largest peak.
		% 2019.10.13 [16:53:12] - Changed keyboard legend to be a figure so don't have an extra pop-up menu chilling around and easier to access on small screens when sorting.
		% 2019.11.07 [19:25:18] - Added in ability to user to click on the cellmap to go to that cell. Users can now also go the most recently sorted cell for convenience.
		% 2019.11.09 [14:03:42] - Mouse is no longer invisible on the figure, callback to detect mouse click on cellmaps and trigger ability for user to select cells, and other improvements.
		% 2019.11.09 [14:37:15] - Remove many commented out code. And added removal of unconnected components from main component when thresholding images.
		% 2019.11.10 [20:21:03] - Made sorting will re-run in case of chooseSignals error, e.g. if GUI is overwritten.
	% TODO
		% DONE: New GUI interface to allow users to scroll through video and see cell activity at that point
		% DONE: allow option to mark rest as bad signals
		% DONE: Allows user to click on cellmap and goto that cell
		% c should make an obj cut movie for 10 or so signals
		% set viewMontageso it uses minValTraces maxValTraces
		% DONE: Allow asynchronous loading of cell information from disk, e.g. do the first 20 cells then load in background while person goes through the rest of the cells.

	%% ============================
	% ===ADDITIONAL DATA===
	% Matrix or str: used to find movie frames at peaks. Matrix, movie matching inputImages/inputSignals src. Str, path to the HDF5 movie.
	options.inputMovie = [];
	% Matrix: same form as inputSignals
	options.inputSignalsSecond = [];
	% Vector: vector of SNR values
	options.signalSnr = [];
	% IGNORE: Raw (not processed) movie matching inputImages/inputSignals src, used to find movie frames at peaks
	options.inputMovieRaw = [];
	% Input pre-computed x,y coordinates for objects in images
	options.coord.xCoords = [];
	options.coord.yCoords = [];
	% Vector of pre-load choices where 1 = good, 0 = bad, 2 = questionable OR 'neutralStart' (all questionable) OR []
	options.valid = 'neutralStart';

	% ===MOVIE SETTINGS===
	% Binary: 1 = normal movie cut images, 0 = user can select frame to use to view activity
	options.peakTrigMovieMontage = 1;
	% Int: number of frames before and after an event to view for peak-based movie montage.
	options.nMovieFrames = 10;
	% Vector: 3 element vector indicating [x y frames]
	options.inputMovieDims = [];
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% FID of the inputMovie via H5F.open to save time
	options.hdf5Fid = [];
	% Whether to keep HDF5 file open (for FID)
	options.keepFileOpen = 0;
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% Number of frames to sample of inputMovie to get statistics
	options.nFrameSampleInputMovie = 10;
	% Float: (Range: 0:1) fraction of movie to sample of inputMovie to get statistics
	options.fractionSampleInputMovie = 0.01;
	% Binary: 1 = read movie from HDD, 0 = load entire movie into RAM
	options.readMovieChunks = 0;
	% movie stats
	options.movieMax = NaN;
	options.movieMin = NaN;
	options.movieMinLim = -0.02;%-0.025
	options.movieMean = NaN;
	% Binary: 1 = pre-compute movies aligned to signal transients, 0 = do not pre-compute
	options.preComputeImageCutMovies = 0;
	% Int: number of signals ahead of current to asynchronously load imageCutMovies, might make the first couple signal selections slow while loading takes place
	options.nSignalsLoadAsync = 20;
	% Int: max movie cut images to show
	% options.maxSignalsToShow = 24;
	options.maxSignalsToShow = 15;
	% Int: Max size in MB of async transient cut movie and image storage
	options.maxAsyncStorageSize = 4000;
	% ===PRECOMPUTED VALUES===
	% Binary: 1 = remove unconnected even when no binary thresholding for images;
	options.removeUnconnected = 1;
	% ===OTHER SETTINGS===
	% Binary: 1 = mouse pointer will disappear, 0 = mouse pointer present
	options.disableMousePointer = 0;
	% set default options
	options.nSignals = size(inputImages,3);
	% string to display over the cell map
	options.inputStr = '';
	% directory to store temporary decisions
	options.tmpDir = ['private' filesep 'tmp'];
	% id for the current session, use system time since it'll be unique
	options.sessionID = num2str(java.lang.System.currentTimeMillis);
	% threshold for SNR auto-annotate
	options.SnrThreshold = 1.2;
	% TBD
	options.slopeRatioThreshold = 0;
	% location of classifier
	options.classifierFilepath = [];
	% type of classifier that was used
	options.classifierType = 'nnet';
	% upper range pct score to manually sort
	options.upperClassifierThres = 0.6;
	% lower range pct score to manually sort
	options.lowerClassifierThres = 0.3;
	% sort by the SNR
	options.sortBySNR = 0;
	% randomize order
	options.randomizeOrder = 0;
	% show ROI traces in addition to input traces
	options.showROITrace = 0;
	% pre-compute signal peaks
	options.signalPeaks = [];
	options.signalPeaksArray = [];
	% ROI for peak signal plotting
	options.peakROI = -20:20;
	% whether to median filter the input trace
	options.medianFilterTrace = 1;
	% whether to subtract mean during SNR calc
	options.subtractMean = 1;
	% 'original' or 'iterativeRemoveSignal'
	options.signalCalcType = 'iterativeRemoveSignal';
	% Min value to display
	options.minValConstant = -0.02; %-0.1
	% Max movie value to display
	options.maxValConstant = 0.4; %-0.1
	% size in pixels to crop around the movie
	options.cropSize = 5;
	options.cropSizeLength = 10;
	% what percent of movie max to have crosshair values
	options.crossHairPercent = 0.07;
	% threshold for thresholding images
	options.threshold = 0.3;
	% threshold for thresholding images
	options.thresholdOutline = 0.3;
	% enter in rgb (range 0 to 1) for background for each color
	options.backgroundGood = [208,229,180]/255;
	options.backgroundBad = [244,166,166]/255;
	options.backgroundNeutral = repmat(230,[1 3])/255;
	options.backgroundNegative = [166,166,244]/255;
	% type of colormap to use
	options.colormap = customColormap([],'nPoints',256);
	% colormap indx
	options.colormapIdx = 1;
	% list of different colormaps
	options.colormapColorList = {'gray','jet','hot','hsv','copper'};
	% For the secondary zoomed cellmap, pixels to crop around
	options.cellmapZoomPx = 40;
	% Binary: 1 = obj outline in signal cut movies, 0 = no outlines
	options.outlinesObjCutMovie = 0;
	% FPS to display event cut movies
	options.fps = 25;
	% Int: how many pixels to widen locating line of currently selected cell in cellmap.
	options.widenLine = 1;
	% Int: Distance in pixels to look for nearest neighbor cells
	options.neighborDistance = 20;
	% Int: Figure number for the secondary GUI screen to display additional information at user request
	options.secondFigNo = 426;
	% number of standard deviations above the threshold to count as spike
	options.numStdsForThresh = 2.3;
	% Binary: 1 = show the image correlation value when input path to options.inputMovie (e.g. when not loading entire movie into RAM).
	options.showImageCorrWithCharInputMovie = 0;
	% Binary: 1 = run tic-toc check on timing in signal loop, 0 =
	options.signalLoopTicTocCheck = 0;
	% Binary: 1 = make x and y axis equal for cell map and movies
	options.axisEqual = 1;
	% Int: minimum number of events a signal needs to have else will add pseudo peaks
	options.minEventsAddPeaks = 4;
	% Int: font size of GUI elements
	options.fontSize = 10;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	ignoreVarUnpack = {'inputMovie','inputSignalsSecond','inputMovieRaw'};
	for i=1:length(fn)
		if ismember(fn{i},ignoreVarUnpack);continue;end
		eval([fn{i} '=options.' fn{i} ';']);
	end
	display(options)

	% Check the input dimensions and warn user if they are incorrect
	disp(['inputImages size: ' num2str(size(inputImages))])
	disp(['inputSignals size: ' num2str(size(inputSignals))])
	if size(inputImages,3)~=size(inputSignals,1)
		disp(sprintf('Number of signals or cells in input images (%d) and activity traces (%d) DO NOT match. Please make sure input images are [x y cellNo] and input signals are [cellNo frames] format. Exiting function...',size(inputImages,3),size(inputSignals,1)))
		return;
	else
		disp(sprintf('Number of signals or cells in input images (%d) and activity traces (%d) DO match. Continuing...',size(inputImages,3),size(inputSignals,1)))
	end

	% ==========================================
	% COLORMAP SETUP
	colorbarsOn = 0;
	% clc
	% add custom colormap
	t = [255, 0, 0]./255;
	color1 = [1 1 1];
	color2 = [0 0 1];
	% color1 = [0 0 0];
	R = [linspace(color1(1),color2(1),50) linspace(color2(1),t(1),50)];
	G = [linspace(color1(2),color2(2),50) linspace(color2(2),t(2),50)];
	B = [linspace(color1(3),color2(3),50) linspace(color2(3),t(3),50)];
	redWhiteMap = [R', G', B'];
	[outputColormap2] = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
	outputColormap3 = diverging_map([0:0.01:1],[0 0 0.7],[0.7 0 0]);
	outputColormap4 = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
	if strcmp(options.colormap,'whiteRed')
		% outputColormap2 = customColormap([]);
		outputColormap = diverging_map([0:0.01:1],[0 0 1],[1 0 0]);
		options.colormap = outputColormap;
		% options.colormapIdx = 0;
	end
	grayRed = customColormap({[0 0 0],[0.5 0.5 0.5],[1 1 1],[0.7 0.2 0.2],[1 0 0]});
	options.colormapColorList = [...
		customColormap([],'nPoints',256),...
		outputColormap2,...
		{'gray'},...
		redWhiteMap,...
		grayRed,...
		options.colormap,...
		outputColormap4,...
		outputColormap3,...
		options.colormapColorList];
	%% ============================
	try
		instructionStr = subfxnCreateLegend();
	catch
		try
			instructionStr = subfxnCreateLegend();
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
	%% ============================

	disp(repmat('=',1,21))
	% pre-open all needed figures
	for figNoFake = [1996 1997 1776 1777 1778 1779 42 1]
		try;close(figNoFake);end
		[~, ~] = openFigure(figNoFake, '');
		clf
		drawnow
	end

	if ~isempty(options.inputMovie)
		if ischar(options.inputMovie)&options.readMovieChunks==0
			disp('Based on input configuration, movie needs to be loaded')
			options.inputMovie = loadMovieList(options.inputMovie,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName,'largeMovieLoad',1);
		end

		if ischar(options.inputMovie)||iscell(options.inputMovie)
			movieDims = loadMovieList(options.inputMovie,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName,'getMovieDims',1);
			options.inputMovieDims = [movieDims.one movieDims.two movieDims.three];
			% Force read movie chunks to be 1
			% options.readMovieChunks = 1;
			options.hdf5Fid = H5F.open(options.inputMovie);
			options.keepFileOpen = 1;
		else
			options.inputMovieDims = size(options.inputMovie);
		end
	end

	if ~isempty(options.inputMovie)
		% get the movie
		if ischar(options.inputMovie)||iscell(options.inputMovie)
			tmpFrameList = round(linspace(1,options.inputMovieDims(3),options.nFrameSampleInputMovie));
			tmpMovie = loadMovieList(options.inputMovie,'convertToDouble',0,'frameList',tmpFrameList,'inputDatasetName',options.inputDatasetName);
			options.movieMax = nanmax(tmpMovie(:));
			options.movieMin = nanmin(tmpMovie(:));
		else
			tmpMovie = options.inputMovie(floor(linspace(1,numel(options.inputMovie),round(numel(options.inputMovie)*options.fractionSampleInputMovie))));
		end

		if isnan(options.movieMax)
			disp('calculating movie max...')
			options.movieMax = nanmax(tmpMovie(:));
			% options.movieMax = prctile(tmpMovie,99.9); % use percentile to avoid randomly high max values
		end
		if isnan(options.movieMin)
			disp('calculating movie min...')
			options.movieMin = nanmin(tmpMovie(:));
		end
		disp('calculating movie mean...')
		try
			if ischar(options.inputMovie)||iscell(options.inputMovie)
				options.movieMean = nanmean(tmpMovie(:));
			else
				tmpMovie2 = options.inputMovie(1:10,1:10,:);
				options.movieMean = nanmean(tmpMovie2(:));
				clear tmpMovie2;
			end
		catch
			if ischar(options.inputMovie)||iscell(options.inputMovie)
				options.movieMean = nanmean(tmpMovie(:));
			else
				options.movieMean = nanmean(options.inputMovie(:));
			end
		end
		clear tmpMovie;
	end

	% Force to not be NaN
	if isnan(options.movieMax)
		options.movieMax = 0.1;
	end
	if isnan(options.movieMin)
		options.movieMin = 0;
	end

	% Set all starting values to neutral (e.g. gray in GUI, to reduce bias).
	if strcmp(valid,'neutralStart')==1
		valid = zeros([options.nSignals 1],'logical')+3;
	end
	% for manual classification of automated signals
	if ~isempty(valid)&&~isempty(find(valid==2,1))
		inputImagesBackup = inputImages;
		inputSignalsBackup = inputSignals;
		questionableSignalIdx = find(valid==2);
		inputImages = inputImages(:,:,questionableSignalIdx);
		inputSignals = inputSignals(questionableSignalIdx,:);
		validBackup = valid;
		valid = zeros(1,length(questionableSignalIdx));
	else
		validBackup = [];
	end

	% get the SNR for traces and sort traces by this if asked
	if isempty(options.signalSnr)
		[signalSnr, inputMse, inputSnrSignal, inputSnrNoise, inputSignalSignal, inputSignalNoise] = computeSignalSnr(inputSignals,'testpeaks',options.signalPeaks,'testpeaksArray',options.signalPeaksArray,'signalCalcType',options.signalCalcType,'medianFilter',options.medianFilterTrace,'subtractMean',options.subtractMean);
	else
		signalSnr = options.signalSnr;
	end
	if options.sortBySNR==1
		signalSnr(isnan(signalSnr)) = -Inf;
		[signalSnr, newIdx] = sort(signalSnr,'descend');
		signalSnr(isinf(signalSnr)) = NaN;
		inputSignals = inputSignals(newIdx,:);
		inputImages = inputImages(:,:,newIdx);
		if ~isempty(valid)
			valid = valid(newIdx);
		end
	end

	% randomize the order if asked
	if options.randomizeOrder==1
		randIdx = randperm(options.nSignals);
		inputSignals = inputSignals(randIdx,:);
		inputImages = inputImages(:,:,randIdx);
		if ~isempty(valid)
			valid = valid(randIdx);
		end
	end
	% =======
	% create a cell map to overlay current IC filter onto
	objMap = createObjMap(inputImages);
	if issparse(objMap)
		objMap = full(objMap);
	end

	% =======
	% Pre-compute values
	% Threshold images
	[inputImagesThres, inputImagesBoundaryIndices] = thresholdImages(inputImages,'waitbarOn',1,'binary',0,'normalizationType','zeroToOne','threshold',options.threshold,'getBoundaryIndex',1,'removeUnconnected',options.removeUnconnected);

	[imgStats] = computeImageFeatures(inputImagesThres,'thresholdImages',1);

	if isempty(options.signalPeaks)
		[signalPeaks, signalPeakIdx] = computeSignalPeaks(inputSignals,'makePlots', 0,'makeSummaryPlots',0,'waitbarOn',1,'numStdsForThresh',options.numStdsForThresh,'detectMethod','raw');
	else
		signalPeaks = options.signalPeaks;
		signalPeakIdx = options.signalPeaksArray;
	end
	signalPeakIdxOriginal = signalPeakIdx;
	signalPeaksOriginal = signalPeaks;

	% add max peak for those signals that don't otherwise have any
	minimumEvents = options.minEventsAddPeaks;
	peaksNoneIdx = cellfun(@length,signalPeakIdx)>minimumEvents;
	peaksNoneIdx = find(~peaksNoneIdx);
	if ~isempty(peaksNoneIdx)
		fprintf('Adding pseudo-peaks for %d low event signals...',length(peaksNoneIdx))
		nIdx = length(peaksNoneIdx);
		maxValueIndices = cell([1 nIdx]);
		inputSignalsCell = num2cell(inputSignals(peaksNoneIdx,:),2);
		signalPeakIdxTmp = signalPeakIdx(peaksNoneIdx);
		options_peakROI = options.peakROI;
		parfor idxHereNo = 1:nIdx
			tmpS = inputSignalsCell{idxHereNo};
			% If there are peaks, remove them from trace before estimating new locations, reduce duplicate peaks found
			if ~isempty(signalPeakIdxTmp{idxHereNo})
				% peakIdx = bsxfun(@plus,options_peakROI',signalPeakIdx{idxHere});
				peakIdx = bsxfun(@plus,options_peakROI',signalPeakIdxTmp{idxHereNo});
				peakIdx = unique(peakIdx(:));
				peakIdx(peakIdx>length(tmpS)) = [];
				peakIdx(peakIdx<=0) = [];
				tmpS(peakIdx) = NaN;
			end

			[~,sortingIndices] = sort(tmpS(:),'ascend');
			maxValueIndices{idxHereNo} = sortingIndices(1:minimumEvents);

			numStdsForThreshSet = 1.5;
			peaksTmp = {[]};
			while length(peaksTmp{1})<=minimumEvents
				[~, peaksTmp] = computeSignalPeaks(tmpS,...
					'makePlots', 0,'makeSummaryPlots',0,'waitbarOn',0,...
					'numStdsForThresh',numStdsForThreshSet,'outputInfo',0,'detectMethod','raw');
				if numStdsForThreshSet>=1
					numStdsForThreshSet = numStdsForThreshSet-0.5;
				else
					numStdsForThreshSet = numStdsForThreshSet-0.1;
				end
				% Break before infinite loop, set peaks to random frames
				if numStdsForThreshSet<0.2
					peaksTmp = {randperm(length(tmpS),minimumEvents)};
					break;
				end
			end
			minimumEventsHere = max(1,minimumEvents-length(signalPeakIdxTmp{idxHereNo}(:)));

			peakSignalAmplitude = tmpS(peaksTmp{1}(:));
			[~, peakIdx] = sort(peakSignalAmplitude,'descend');
			peaksTmp{1} = peaksTmp{1}(peakIdx);
			maxValueIndices{idxHereNo} = peaksTmp{1}(1:minimumEventsHere);
		end
		for idxHereNo = 1:nIdx
			idxHere = peaksNoneIdx(idxHereNo);
			signalPeakIdx{idxHere} = unique([maxValueIndices{idxHereNo}(:); signalPeakIdx{idxHere}(:)])';
			signalPeaks(idxHere,signalPeakIdxTmp{idxHereNo}(:)) = 1;
		end
	end
	signalPeaksArray = signalPeakIdx;

	% get the peak statistics
	[peakOutputStat] = computePeakStatistics(inputSignals,'waitbarOn',1,'testpeaks',signalPeaks,'testpeaksArray',signalPeaksArray,'spikeROI',options.peakROI,'medianFilter',options.medianFilterTrace);

	% Get correlation images
	if ~isempty(options.inputMovie)
		if ischar(options.inputMovie)||iscell(options.inputMovie)
			% Ignore for now.
			outputMeanImageCorrs = NaN([size(inputSignals,1) 1]);
			outputMeanImageCorrs2 = NaN([size(inputSignals,1) 1]);
			peakOutputStat.outputMeanImageCorrs = outputMeanImageCorrs(:);
			peakOutputStat.outputMeanImageCorrs2 = outputMeanImageCorrs2(:);

			% No ROI traces when enter a cell
			options.showROITrace = 0;
			ROItraces = [];
		else
			[~, outputMeanImageCorrs, outputMeanImageCorrs2] = createPeakTriggeredImages(options.inputMovie, inputImages, inputSignals,'cropSize',options.cropSize,'signalPeaksArray',signalPeakIdxOriginal,'xCoords',options.coord.xCoords,'yCoords',options.coord.yCoords,'maxPeaksToUse',5,'normalizeOutput',0,'inputImagesThres',inputImagesThres,'readMovieChunks',options.readMovieChunks,'outputImageFlag',0,'runSecondCorr',1);
			outputMeanImageCorrs(isnan(outputMeanImageCorrs)) = 0;
			outputMeanImageCorrs2(isnan(outputMeanImageCorrs2)) = 0;
			peakOutputStat.outputMeanImageCorrs = outputMeanImageCorrs(:);
			peakOutputStat.outputMeanImageCorrs2 = outputMeanImageCorrs2(:);
			% get ROI traces
			if options.showROITrace==1
				[ROItraces] = applyImagesToMovie(inputImagesThres,options.inputMovie,'alreadyThreshold',1,'waitbarOn',1);
			else
				ROItraces = [];
			end
		end
	else
		peakOutputStat.outputMeanImageCorrs = NaN([size(inputImages,3) 1]);
		peakOutputStat.outputMeanImageCorrs2 = NaN([size(inputImages,3) 1]);
		ROItraces = [];
	end
	% =======

	% display histogram of movie/trace
	histogramSwitch = 0;
	if ~isempty(options.inputMovie)&&histogramSwitch==1
		figure(45684)
		subplot(3,1,1)
		hist(inputSignals(:),100);xlabel('input values');ylabel('counts')
		title(['input | min: ' num2str(nanmin(inputSignals(:))) ' | max: ' num2str(nanmax(inputSignals(:)))],'FontSize',options.fontSize)
		subplot(3,1,2)
		hist(options.inputMovie(:),100);xlabel('movie values');ylabel('counts')
		title(['movie | min: ' num2str(nanmin(options.inputMovie(:))) ' | max: ' num2str(nanmax(options.inputMovie(:)))],'FontSize',options.fontSize)
		subplot(3,1,3)
		hist(ROItraces(:),100);xlabel('ROI values');ylabel('counts')
		title(['ROI | min: ' num2str(nanmin(ROItraces(:))) ' | max: ' num2str(nanmax(ROItraces(:)))],'FontSize',options.fontSize)
	end

	% remove small ICs unless a pre-list is loaded in
	if isempty(valid)
		[~, ~, valid, inputImageSizes] = filterImages(inputImages, inputSignals,'thresholdImages',1);

		% pre-select as valid if SNR is above a certain threshold
		validSNR = signalSnr>options.SnrThreshold;
		validPre = valid | validSNR;
		validSlope = peakOutputStat.slopeRatio>options.slopeRatioThreshold;
		validPre = validPre & validSlope;

		% Since 0=invalid, 1=valid, -1=unknown, set all '1' to unknown
		valid(valid==1) = -1;
	else
		inputImageSizes = sum(sum(inputImagesThres,1),2);
		inputImageSizes = inputImageSizes(:);
		if issparse(inputImageSizes)
			inputImageSizes = full(inputImageSizes);
		end
		validPre = valid;
	end

	% =======
	% plot information about the traces
	plotSignalStatisticsWrapper(inputSignals,inputImages,validPre,inputImageSizes,inputStr,signalSnr,peakOutputStat);

	% =======
	% loop over choices
	nSignals = size(inputImages,3);
	disp(['# signals: ' num2str(nSignals)]);

	% Re-run in case of any errors or problems with the GUI
	safeExit = 0;
	while safeExit==0
		try
			% Run the main decision-making function
			[choices, safeExit] = chooseSignals(options,1:nSignals, inputImages,inputSignals,objMap, valid, inputStr,tmpDir,sessionID,signalPeakIdx,signalSnr,inputImagesThres,inputImageSizes,peakOutputStat,ROItraces,imgStats,inputSignalSignal,inputSignalNoise,inputImagesBoundaryIndices,signalPeakIdxOriginal,signalPeaksOriginal,instructionStr);
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end

	% Assume all skips were good ICs that user forgot to enter
	validChoices = choices;;
	validChoices(validChoices==-1)=1;
	validChoices = logical(validChoices);

	% if manually scoring automatic, combine manual classification with automatic
	if ~isempty(validBackup)&&~isempty(validBackup==2)
		valid = validBackup;
		% add the manual scores for the questionable signals into the valid input vector
		valid(questionableSignalIdx) = validChoices;
		validChoices = logical(valid);
		choices = validChoices;
		% restore original input data
		inputImages = inputImagesBackup;
		inputSignals = inputSignalsBackup;
	end

	% =======
	% filter input for valid signals
	inputImages = inputImages(:,:,validChoices);
	inputSignals = inputSignals(validChoices,:);

	try
		close(findall(0,'Type','figure','Name','Key legend'))
		msgboxHandle = findall(0,'Type','figure','Name','signalSorter shortcuts/legend');
		close(msgboxHandle)
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
function viewObjMoviePlayer()
	% Plays

end
function plotSignalStatisticsWrapper(inputSignals,inputImages,validChoices,inputImageSizes,inputStr,signalSnr,peakOutputStat)
	% plot good and bad signals with different colors

	% determine number of IC filters to investigate
	pointColor = ['r','g'];
	for pointNum = 1:2
		if pointNum==1
			valid = logical(~validChoices);
		else
			valid = logical(validChoices);
		end
		% plot information about the traces
		plotSignalStatistics(inputSignals(valid,:),inputImageSizes(valid),inputStr,pointColor(pointNum),'hold on',signalSnr(valid),peakOutputStat.slopeRatio(valid))
	end
end
function plotSignalStatistics(inputSignals,inputImageSizes,inputStr,pointColor, holdState,signalSnr,slopeRatio)
	% plot statistics for input signal
	warning off;
	% get best fit line SNR v slopeRatio
	p = polyfit(signalSnr,slopeRatio,1);   % p returns 2 coefficients fitting r = a_1 * x + a_2
	r = p(1) .* signalSnr + p(2); % compute a new vector r that has matching datapoints in x
	if ~isempty(slopeRatio)&&~isempty(signalSnr)
		% start plotting!
		figNo = 1776;%AMERICA
		[~, figNo] = openFigure(figNo, '');
		hold off;
		plot(normalizeVector(slopeRatio),'Color',[4 4 4]/5);hold on;
		plot(normalizeVector(signalSnr),'r');
		title(['SNR in trace signal for ' inputStr])
		hleg1 = legend('S-ratio','SNR');
		xlabel('ic rank');ylabel('SNR');box off;hold off;

		[~, figNo] = openFigure(figNo, '');
		hold off;
		plot(slopeRatio,'Color',[4 4 4]/5);hold on;
		plot(signalSnr,'r');
		title(['SNR in trace signal for ' inputStr])
		hleg1 = legend('S-ratio','SNR');
		xlabel('ic rank');ylabel('SNR');box off;hold off;

		[~, figNo] = openFigure(figNo, '');
		scatter(signalSnr,slopeRatio,[pointColor '.']);hold on;
		plot(signalSnr, r, 'k-');
		title(['SNR v S-ratio for ' inputStr])
		xlabel('SNR');ylabel('S-ratio');box off;
		eval(holdState);

		[~, figNo] = openFigure(figNo, '');
		scatter3(signalSnr,slopeRatio,inputImageSizes,[pointColor '.'])
		title(['SNR, S-ratio, filter size for ' inputStr])
		xlabel('SNR');ylabel('S-ratio');zlabel('ic size');
		legend({'bad','good'});rotate3d on;
		eval(holdState);
	end
	warning on;
end
function [valid, safeExit] = chooseSignals(options,signalList, inputImages,inputSignals,objMap, valid, inputStr,tmpDir,sessionID,signalPeakIdx,signalSnr,inputImagesThres,inputImageSizes,peakOutputStat,ROItraces,imgStats,inputSignalSignal,inputSignalNoise,inputImagesBoundaryIndices,signalPeakIdxOriginal,signalPeaksOriginal,instructionStr)
	% manually decide which signals are good or bad, pre-computed values input to speed up movement through signals

	warning('off','all')
	warning('query','all')

	if ~exist(tmpDir,'file')
		mkdir(tmpDir);
	end

	subplotCustom = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.07, 'Padding', 0, 'MarginTop', 0.1,'MarginBottom', 0.07,'MarginLeft', 0.03,'MarginRight', 0.07); % ,'Holdaxis',1

	mainFig = figure(1);
	% prevent matlab from giving command window focus
	% set(mainFig,'KeyPressFcn', '1;');

	% % Prepare the figure
	% hFig = figure;  % etc. - prepare the figure
	% % Get the underlying Java reference
	% warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
	% jFig = get(hFig, 'JavaFrame');
	% jAxis = jFig.getAxisComponent;
	% % Set the focus event callback
	% set(jAxis.getComponent(0),'FocusLostCallback',{@subfxnLostFocusMainFig,hFig});
	% set(jAxis,'FocusGainedCallback',{@myMatlabFunc,hFig});
	% perhaps also set the FocusLostCallback here

	if isempty(options.inputMovie)
		objMapPlotLoc = [7 8];
		objMapZoomPlotLoc = [1 2];
		tracePlotLoc = [9 10 11 12];
		avgSpikeTracePlot = [3 4];
	else
		% objMapPlotLoc = [1 2 7 8];
		objMapPlotLoc = [7 8];
		objMapZoomPlotLoc = [1 2];
		tracePlotLoc = [10 11 12];
		avgSpikeTracePlot = 9;
	end
	% inputMoviePlotLoc = 1:2;
	inputMoviePlotLoc = [3 4];
	inputMoviePlotLoc2 = [5 6];
	filterPlotLoc = inputMoviePlotLoc2;
	subplotX = 6;
	subplotY = 2;

	figure(mainFig);

	% plot the cell map to provide context
	subplotCustom(subplotY,subplotX,objMapPlotLoc);
	imagesc(objMap); axis off;
	colormap gray;
	title(['objMap' inputStr],'FontSize',options.fontSize,'Interpreter','tex');hold on;

	% make color image overlays
	zeroMap = zeros(size(objMap));
	oneMap = ones(size(objMap))*0.5;
	green = cat(3, zeroMap, oneMap, zeroMap);
	blue = cat(3, zeroMap, zeroMap, oneMap);
	red = cat(3, oneMap, zeroMap, zeroMap);
	warning off
	imageOverlay = imshow(blue);
	goodFilterOverlay = imshow(green);
	badFilterOverlay = imshow(red);
	warning on
	hold off

	% get values for plotting
	peakROI = options.peakROI;
	minValTraces = nanmin(inputSignals(:));
	if minValTraces<options.minValConstant
		minValTraces = options.minValConstant;
	end
	maxValTraces = prctile(inputSignals(:),99.99);
	if maxValTraces>options.maxValConstant||maxValTraces<0.3
		% maxValTraces = 0.35;
	end

	% filter based on the list
	inputImages = inputImages(:,:,signalList);
	inputSignals = inputSignals(signalList,:);

	% loop over chosen filters
	nImages = size(inputImages,3);

	% initialize loop variables
	saveData=0;
	i = 1; % the current signal # being sorted
	reply = 0;
	loopCount = 1;
	warning off

	if ~isempty(options.inputMovie)
		disp('calculating movie min/max...')
		maxValMovie = options.movieMax;
		minValMovie = options.movieMin;
	else
		maxValMovie = NaN;
		minValMovie = NaN;
	end

	if isempty(options.coord.xCoords)
		[xCoords, yCoords] = findCentroid(inputImagesThres,'thresholdValue',0.8,'imageThreshold',options.threshold,'runImageThreshold',0);
		options.coord.xCoords = xCoords;
		options.coord.yCoords = yCoords;
	else
		xCoords = options.coord.xCoords;
		yCoords = options.coord.yCoords;
	end

	neighborsCell = identifyNeighborsAuto(inputImages, inputSignals,'inputImagesThres',inputImagesThres,'xCoords',options.coord.xCoords,'yCoords',options.coord.yCoords);

	reverseStr = '';
	nSignalsHere = size(inputImages,3);
	objCutMovieCollection = cell([nSignalsHere 1]);
	objCutImagesCollection = cell([nSignalsHere 1]);
	if ~isempty(options.inputMovie)&&options.preComputeImageCutMovies==1
		disp('pre-loading preview transient-aligned movies')
		for signalNo = 1:nSignalsHere
			thisTrace = inputSignals(signalNo,:);
			testpeaks = signalPeakIdx{signalNo};
			try
				% Pre-compute the transient movies
				[objCutMovieCollection{signalNo}] = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,signalNo,options.cropSizeLength,maxValMovie);

				% Pre-compute the still frames at transient times
				[objCutImagesCollection{signalNo},~] = viewMontage(options.inputMovie,inputImages(:,:,signalNo),options,thisTrace,[signalPeakIdx{signalNo}],minValMovie,maxValMovie,options.cropSizeLength,signalNo,1);
			catch err
				objCutMovieCollection{signalNo} = {};
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
			if signalNo==1||mod(signalNo,20)==0
				reverseStr = cmdWaitbar(signalNo,nSignalsHere,reverseStr,'inputStr','Pre-loading preview images','waitbarOn',1,'displayEvery',1);
			end
		end
	else
		for signalNo = 1:nSignalsHere
			objCutMovieCollection{signalNo} = {};
		end
	end

	% ensure main figure hasn't been closed
	mainFig = figure(1);

	% For async loading of transient aligned movies and images
	objCutMovieAsyncF = cell([1 nSignalsHere]);
	objCutImagesAsyncF = cell([1 nSignalsHere]);

	% Setup frame callback
	sliderPos = 2;
	nFrames = size(inputSignals,2);
	frameSlider = uicontrol('style','slider','Units', 'normalized','position',[15 0 83 sliderPos]/100,...
			'min',1,'max',nFrames,'Value',1,'SliderStep',[1/nFrames (nFrames*0.07)*(1/nFrames)],'callback',@movieCallback);
	set(frameSlider,'Enable','off');
	frameNo = max(1,round(get(frameSlider,'value')));
	addlistener(frameSlider, 'Value', 'PostSet',@frameCallback);
	['Frame ' num2str(frameNo) '/' num2str(nFrames)]
	frameText = uicontrol('style','edit','Units', 'normalized','position',[1 0 14 sliderPos]/100,'FontSize',9,'string','Disabled. Press B to active');
	set(frameText,'ForegroundColor',[0.7 0.7 0.7]);
	zoomHandle = [];
	frameLineHandle = [];

	lastSortedSignal = i;

	safeExit = 0;

	% only exit if user clicks options that calls for saving the data
	while saveData==0
		if options.signalLoopTicTocCheck==1
			tic
		end

		figure(mainFig);
		% change figure color based on nature of current choice
		if valid(i)==1
			set(mainFig,'Color',options.backgroundGood);
		elseif valid(i)==0
			set(mainFig,'Color',options.backgroundBad);
		elseif valid(i)==-1
			set(mainFig,'Color',options.backgroundNegative);
		else
			set(mainFig,'Color',options.backgroundNeutral);
		end

		if options.movieMin<options.movieMinLim
			minHere = options.movieMinLim;
		else
			minHere = options.movieMin;
		end
		maxHere = options.movieMax;

		% get loop specific values
		directionOfNextChoice=0;
		thisImage = squeeze(inputImages(:,:,i));
		if issparse(thisImage)
			thisImage = full(thisImage);
		end
		thisTrace = inputSignals(i,:);
		testpeaks = signalPeakIdx{i};
		cellIDStr = ['#' num2str(i) '/' num2str(nImages)];

		if ~isempty(options.inputMovie)
			if i==1
				inputMoviePlotLoc2Handle = subplotCustom(subplotY,subplotX,inputMoviePlotLoc2);
			else
				set(mainFig,'CurrentAxes',inputMoviePlotLoc2Handle);
			end

			if options.showImageCorrWithCharInputMovie==1
				[~, outputMeanImageCorrs, ~] = createPeakTriggeredImages(options.inputMovie, thisImage, inputSignals(i,:),'cropSize',options.cropSize,'signalPeaksArray',signalPeakIdxOriginal(i),'xCoords',options.coord.xCoords(i),'yCoords',options.coord.yCoords(i),'maxPeaksToUse',5,'normalizeOutput',0,'inputImagesThres',inputImagesThres,'readMovieChunks',options.readMovieChunks,'displayInfo',0,'movieDims',options.inputMovieDims,'runThresCorr',0,'runSecondCorr',0);

				peakOutputStat.outputMeanImageCorrs(i) = outputMeanImageCorrs(:);
			end

			oldPlotHere = 1;
			if oldPlotHere==1
				if(~isempty(testpeaks))
					try
						% if i==1
						% end
						% Select whether to use existing peaks or not.
						if isempty(objCutImagesCollection{i})&&ischar(options.inputMovie)==1
							if exist('objCutImagesAsyncF','var')==1
								if isempty(objCutImagesAsyncF{i})
									[objCutImagesCollection{i}, ~] = viewMontage(options.inputMovie,thisImage,options,thisTrace,[signalPeakIdx{i}],minValMovie,maxValMovie,options.cropSizeLength,i,1);
								else
									% Fetch output, blocks UI until read
									croppedPeakImages = fetchOutputs(objCutImagesAsyncF{i});
									objCutImagesCollection{i} = croppedPeakImages;
									% Remove old objects from memory
									delete(objCutImagesAsyncF{i});
									objCutImagesAsyncF{i} = [];
								end
							else
								[objCutImagesCollection{i}, ~] = viewMontage(options.inputMovie,thisImage,options,thisTrace,[signalPeakIdx{i}],minValMovie,maxValMovie,options.cropSizeLength,i,1);
							end
							p = gcp(); % Get the current parallel pool

							if exist('optionsCpy2','var')==1
							else
								optionsCpy2.colormap = options.colormap;
								optionsCpy2.maxSignalsToShow = options.maxSignalsToShow;
								optionsCpy2.coord = options.coord;
								optionsCpy2.crossHairPercent = options.crossHairPercent;
								optionsCpy2.inputDatasetName = options.inputDatasetName;
								optionsCpy2.inputMovieDims = options.inputMovieDims;
								optionsCpy2.hdf5Fid = options.hdf5Fid;
								optionsCpy2.keepFileOpen = options.keepFileOpen;
								optionsCpy2.thresholdOutline = options.thresholdOutline;
								% optionsCpy = options;
								optionsCpy2.hdf5Fid = [];
							end
							for kk = (i+1):(i+options.nSignalsLoadAsync)
								% Don't try to load signals out of range
								if kk>nSignalsHere
									continue;
								end
								if isempty(objCutImagesAsyncF{kk})&&isempty(objCutImagesCollection{kk})
									objCutImagesAsyncF{kk} = parfeval(p,@viewMontage,1,options.inputMovie,inputImages(:,:,kk),optionsCpy2,inputSignals(kk,:),[signalPeakIdx{kk}],minValMovie,maxValMovie,options.cropSizeLength,kk,0);
								else

								end
							end
						else
							[objCutImagesCollection{i}, ~] = viewMontage(options.inputMovie,thisImage,options,thisTrace,[signalPeakIdx{i}],minValMovie,maxValMovie,options.cropSizeLength,i,1);
						end

						j = whos('objCutImagesCollection');j.bytes=j.bytes*9.53674e-7;
						objCutImagesCollectionMB = j.bytes;
						if objCutImagesCollectionMB>options.maxAsyncStorageSize&&options.readMovieChunks==1&&options.preComputeImageCutMovies==0
							display(['objCutImagesCollection: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
							disp('Removing old images to save space...')
							for kk = 1:(i-5)
								if kk<nSignalsHere&&kk>1
									objCutImagesCollection{kk} = [];
								end
							end
						end

						if isempty(objCutImagesCollection{i})
						else
							% disp('Using existing')
							croppedPeakImages2 = objCutImagesCollection{i};
							imAlpha = ones(size(croppedPeakImages2));
							imAlpha(isnan(croppedPeakImages2))=0;
							if i==1
								imagesc(croppedPeakImages2,'AlphaData',imAlpha);
								colormap(options.colormap);
							else
								% findobj(gca,'Type','image')
							end
							montageHandle = findobj(gca,'Type','image');
							set(montageHandle,'Cdata',croppedPeakImages2,'AlphaData',imAlpha);
							set(gca,'color',[0 0 0]);
							set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'))
							set(gca,'color',[0 0 0]);
							warning on
						end
						try
							caxis([minHere maxHere]);
						catch
							caxis([-0.05 0.1]);
						end
						if i==1
							if options.axisEqual==1
								axis equal tight;
							end
							s2Pos = plotboxpos(inputMoviePlotLoc2Handle);
							cbh = colorbar(inputMoviePlotLoc2Handle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)],'FontSize',options.fontSize-2);
							ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)','FontSize',options.fontSize-1);
						end
					catch err

						imAlpha=ones(size(thisImage));
						imAlpha(isnan(thisImage)) = 0;
						imagesc(thisImage,'AlphaData',imAlpha);
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
					end
					try
						sigDig = 100;
						title(['imageCorr = ' num2str(round(peakOutputStat.outputMeanImageCorrs(i)*sigDig)/sigDig) 10 'Press Y to go to last sorted signal.'],'FontSize',options.fontSize,'Interpreter','tex');
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
					end
				else
					imagesc(thisImage);
				end
				if i==1
					colormap(gca,options.colormap);
				end
			end
		else
			% show the current image
			if i==1
				inputMoviePlotLoc2Handle = subplotCustom(subplotY,subplotX,inputMoviePlotLoc2);
			else
				set(mainFig,'CurrentAxes',inputMoviePlotLoc2Handle);
			end
				[thisImageCrop] = subfxnCropImages(thisImage);
				imagesc(thisImageCrop);
				% colormap gray
				axis off; % ij square
				title(['signal ' cellIDStr 10 '(' num2str(sum(valid==1)) ' good)'],'FontSize',options.fontSize,'Interpreter','tex');
		end

		% use thresholded image as AlphaData to overlay on cell map, reduce number of times this is accessed to speed-up analysis
		if loopCount==1||~exist('Comb','var')
			Comb(:,:,1) = zeros(size(squeeze(inputImagesThres(:,:,i))));
			Comb(:,:,2) = zeros(size(squeeze(inputImagesThres(:,:,i))));
			Comb(:,:,3) = zeros(size(squeeze(inputImagesThres(:,:,i))));
			disp(num2str([min(Comb(:)) max(Comb(:))]))
			CombTmp = Comb;
			goodImages = createObjMap(inputImagesThres(:,:,valid==1));
			if isempty(goodImages); goodImages = zeros(size(objMap)); end
			badImages = createObjMap(inputImagesThres(:,:,valid==0));
			if isempty(badImages); badImages = zeros(size(objMap)); end
			if sum(valid==3)>0
				neutralImages = createObjMap(inputImagesThres(:,:,valid==3));
			else
				neutralImages = zeros(size(objMap));
			end
		end

		if i==1
			objMapPlotLocHandle = subplotCustom(subplotY,subplotX,objMapPlotLoc);
		else
			set(mainFig,'CurrentAxes',objMapPlotLocHandle);
		end

		set(objMapPlotLocHandle,'tag','objMapPlotLocHandle')

		% currentImage = squeeze(inputImages(:,:,i));
		currentImageThres = squeeze(inputImagesThres(:,:,i));
		Comb(:,:,2) = ones(size(currentImageThres));

		CombTmp(:,:,1) = badImages-5*goodImages; %red
		CombTmp(:,:,2) = goodImages; %green
		CombTmp(:,:,3) = neutralImages-5*goodImages; %blue
		switch valid(i)
			case 0
				CombTmp(:,:,1) = CombTmp(:,:,1)-currentImageThres;
			case 1
				CombTmp(:,:,2) = CombTmp(:,:,2)-currentImageThres;
			case 3
				CombTmp(:,:,3) = CombTmp(:,:,3)-currentImageThres;
			otherwise
				% body
		end
		CombTmp(:,:,1) = CombTmp(:,:,1)+currentImageThres;
		CombTmp(:,:,2) = CombTmp(:,:,2)+currentImageThres;
		CombTmp(:,:,3) = CombTmp(:,:,3)+currentImageThres;

		% re-color cellmap
		tmpImage = squeeze(CombTmp(:,:,3));
		neutralIdx = tmpImage>0;
		% lighten the good/bad colors
		alterIdx = cell([2 1]);
		for dimNo = 1:2
			CombTmpMain = squeeze(CombTmp(:,:,dimNo));
			alterIdx{dimNo} = CombTmpMain>0;
		end
		for dimNo = 1:2
			CombTmpMain = squeeze(CombTmp(:,:,dimNo));
			for dimNo2 = 1:size(CombTmp,3)
				if dimNo==dimNo2;continue;end
				CombTmp1 = squeeze(CombTmp(:,:,dimNo2));
				CombTmp1(alterIdx{dimNo}) = CombTmpMain(alterIdx{dimNo})/4;
				CombTmp(:,:,dimNo2) = CombTmp1;
			end
		end
		currentIdx = currentImageThres>0;
		% set not picked to gray
		for dimNo = 1:size(CombTmp,3)
			CombTmp1 = squeeze(CombTmp(:,:,dimNo));
			CombTmp1(neutralIdx) = tmpImage(neutralIdx);
			% set current to blue
			if dimNo~=3
				CombTmp1(currentIdx) = 0;
			end
			CombTmp(:,:,dimNo) = CombTmp1;

		end

		CombTmp2 = CombTmp;

		widenLine = -options.widenLine:1:options.widenLine;
		yCoordsMod = max(yCoords(i)+widenLine,1);
		xCoordsMod = max(xCoords(i)+widenLine,1);

		yCoordsMod = min(yCoordsMod,size(CombTmp2,1));
		xCoordsMod = min(xCoordsMod,size(CombTmp2,2));

		CombTmp2(:,xCoordsMod,3) = 0.5+CombTmp2(:,xCoordsMod,3);
		CombTmp2(yCoordsMod,:,3) = 0.5+CombTmp2(yCoordsMod,:,3);
		CombTmp2(:,xCoordsMod,[1 2]) = 0.3+CombTmp2(:,xCoordsMod,[1 2]);
		CombTmp2(yCoordsMod,:,[1 2]) = 0.3+CombTmp2(yCoordsMod,:,[1 2]);

		CombTmp23 = CombTmp2(:,:,1); CombTmp23(currentIdx) = NaN;
		CombTmp2(:,:,1) = CombTmp23;
		CombTmp23 = CombTmp2(:,:,2); CombTmp23(currentIdx) = NaN;
		CombTmp2(:,:,2) = CombTmp23;
		CombTmp23 = CombTmp2(:,:,3); CombTmp23(currentIdx) = NaN;
		CombTmp23(currentIdx) = currentImageThres(currentIdx);
		CombTmp2(:,:,3) = CombTmp23;

		objMapImgHandle = imagesc(CombTmp2);
		objMapImgHandle.HitTest = 'off';
		box off;
		if options.axisEqual==1
			axis equal tight;
		end
		axisH = gca;
		axisH.XRuler.Axle.LineStyle = 'none';
		axisH.YRuler.Axle.LineStyle = 'none';
		if isempty(options.inputStr)
			title([strrep(options.inputStr,'_','\_') 10 'Legend: green(good), red(bad), blue(current)'],'FontSize',options.fontSize,'Interpreter','tex')
		else
			title([strrep(options.inputStr,'_','\_') 10 'Legend: green(good), red(bad), blue(current)'],'FontSize',options.fontSize,'Interpreter','tex')
		end

		if i==1
			objMapZoomPlotLocHandle = subplotCustom(subplotY,subplotX,objMapZoomPlotLoc);
		else
			set(mainFig,'CurrentAxes',objMapZoomPlotLocHandle);
		end
		set(objMapZoomPlotLocHandle,'tag','objMapZoomPlotLocHandle')
			% inputImagesBoundaryIndices
			% good
			dd = find(valid==1); dd(dd==i) = [];
			goodBoundIdx = inputImagesBoundaryIndices(dd);
			gImg = zeros(size(thisImage));
			gImg([goodBoundIdx{:}]) = 1;
			% gImg(inputImagesBoundaryIndices{i}) = 0; % remove current index

			% bad
			dd = find(valid==0); dd(dd==i) = [];
			badBoundIdx = inputImagesBoundaryIndices(dd);
			bImg = zeros(size(thisImage));
			bImg([badBoundIdx{:}]) = 0.6;
			% bImg(inputImagesBoundaryIndices{i}) = 0; % remove current index

			% neutral
			dd = find(valid>1); dd(dd==i) = [];
			neutralBoundIdx = inputImagesBoundaryIndices(dd);
			nImg = zeros(size(thisImage));
			nImg([neutralBoundIdx{:}]) = 0.3;
			nImgO = nImg;
			% nImg(inputImagesBoundaryIndices{i}) = 0; % remove current index
			% nImgO(inputImagesBoundaryIndices{i}) = 0.9; % Add back into original idx

			thisImageThres = squeeze(inputImagesThres(:,:,i));
			currentIdxList = find(thisImageThres>0);
			currentIdxList(ismember(currentIdxList,[goodBoundIdx{:}])) = [];
			nImgO(currentIdxList(:)) = 0.9+nImgO(currentIdxList(:));
			bImg = bImg-gImg+nImg;
			gImg = gImg+nImg;
			rgbImg = cat(3,bImg,gImg,nImgO);

			currentImage2(:,:,1) = thisImage;
			try
				[outputCutMovie] = getObjCutMovie(rgbImg,currentImage2,'waitbarOn',0,'cropSize',options.cellmapZoomPx,'addPadding',1,'xCoords',xCoords(i),'yCoords',yCoords(i));

				zoomCellmapImg = outputCutMovie(1:round(end/2),:,:);
				objMapZoomImgHandle = imagesc(zoomCellmapImg);
				objMapZoomImgHandle.HitTest = 'off';
				if options.axisEqual==1
					axis equal tight;
				end
				title(['signal ' cellIDStr ' (' num2str(sum(valid==1)) ' good)' 10 'Legend: green(good), red(bad), blue(current)' 10 'Press L for keyboard shortcut legend.' 10 'Mouse click or press V to select cell on cellmap.'],'FontSize',options.fontSize,'Interpreter','tex')

				box off;
				axisH = gca;
				axisH.XRuler.Axle.LineStyle = 'none';
				axisH.YRuler.Axle.LineStyle = 'none';
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end

		% if signal has peaks, plot the average signal and other info
		testpeaks = signalPeakIdx{i};
		if(~isempty(testpeaks))
			% plot all signals and the average
			if i==1
				avgSpikeTracePlotHandle = subplotCustom(subplotY,subplotX,avgSpikeTracePlot);
			else
				set(mainFig,'CurrentAxes',avgSpikeTracePlotHandle);
			end

			plotPeakSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces,peakROI,peakOutputStat.avgSpikeTrace(i,:),peakOutputStat.slopeRatio(i),peakOutputStat.spikeCenterTrace{i},valid);
			axisH = gca;
			axisH.XRuler.Axle.LineStyle = 'none';
			axisH.YRuler.Axle.LineStyle = 'none';
			% add in the ratio of the rise/decay slopes. Should be >>1 for calcium

			if i==1
				tracePlotLocHandle = subplotCustom(subplotY,subplotX,tracePlotLoc);
			else
				set(mainFig,'CurrentAxes',tracePlotLocHandle);
			end

			sigDig = 100;
			thisStr = [...
				'SNR = ' num2str(round(signalSnr(i)*sigDig)/sigDig)...
				' | S-ratio = ' num2str(round(peakOutputStat.slopeRatio(i)*sigDig)/sigDig)...
				' | # peaks = ' num2str(length(testpeaks))...
				10 ...
				'size (px) = ' num2str(round(inputImageSizes(i)*sigDig)/sigDig)...
				' | imageCorr = ' num2str(round(peakOutputStat.outputMeanImageCorrs(i)*sigDig)/sigDig) ',' num2str(peakOutputStat.outputMeanImageCorrs2(i))...
				' | Eccentricity = ' num2str(round(imgStats.Eccentricity(i)*sigDig)/sigDig)...
				10 ...
				'Perimeter = ' num2str(round(imgStats.Perimeter(i)*sigDig)/sigDig)...
				' | traceAutoCorr = ' num2str(round(peakOutputStat.traceAutoCorr(i)*sigDig)/sigDig)...
				' | EquivD = ' num2str(round(imgStats.EquivDiameter(i)*sigDig)/sigDig)];
				% ' | Solidity = ' num2str(round(imgStats.Solidity(i)*sigDig)/sigDig)...
			plotSignal(thisTrace,testpeaks,'',thisStr,minValTraces,maxValTraces,options,inputSignalSignal{i},inputSignalNoise{i});

			if options.peakTrigMovieMontage==0
				set(mainFig,'CurrentAxes',tracePlotLocHandle);

				peakSignalAmplitude = thisTrace(signalPeakIdx{i}(:));
				% peakSignalAmplitude
				[peakSignalAmplitude, peakIdx] = sort(peakSignalAmplitude,'descend');

				set(frameSlider,'value',signalPeakIdx{i}(peakIdx(1)));
				% Create handle for frame indicator line
				frNoCall = max(1,round(get(frameSlider,'value')));
				frameLineHandle = line([frNoCall frNoCall],[get(gca,'YLim')],'Color',[0 0 0]);
				uistack(frameLineHandle,'bottom');
				frameCallback();

				nFrames = size(inputSignals,2);
				set(frameSlider,'min',1,'max',nFrames,'SliderStep',[1/nFrames (nFrames*0.07)*(1/nFrames)])
			end

			if ~isempty(options.inputMovie)&&options.showROITrace==1&&~ischar(options.inputMovie)
				hold on
				tmpTrace = ROItraces(i,:);
				tmpTrace = squeeze(tmpTrace);
				if abs(nanmax(tmpTrace))<abs(nanmin(tmpTrace))
					tmpTrace = -tmpTrace;
				end
				traceRatio = nanmax(thisTrace)/nanmax(tmpTrace);
				tmpTrace = tmpTrace*traceRatio+0.1;
				plot(tmpTrace,'k');
				legend('original','ROI');legend boxoff;
				axis([0 length(thisTrace) minValTraces maxValTraces+0.1]);
				hold off
			end
			axisH = gca;
			axisH.XRuler.Axle.LineStyle = 'none';
			axisH.YRuler.Axle.LineStyle = 'none';
		else
			% subplot(subplotY,subplotX,avgSpikeTracePlot);
			if i==1
				avgSpikeTracePlotHandle = subplotCustom(subplotY,subplotX,avgSpikeTracePlot);
			else
				set(mainFig,'CurrentAxes',avgSpikeTracePlotHandle);
			end

			plot(peakROI,thisTrace(1:length(peakROI)));
			xlabel('frames');
			ylabel('\DeltaF/F');
			ylim([minValTraces maxValTraces]);
			title(['signal peaks ' cellIDStr],'FontSize',options.fontSize,'Interpreter','tex')

			% subplot(subplotY,subplotX,tracePlotLoc)
			if i==1
				tracePlotLocHandle = subplotCustom(subplotY,subplotX,tracePlotLoc);
			else
				set(mainFig,'CurrentAxes',tracePlotLocHandle);
			end

			plot(thisTrace, 'r');
			xlabel('frames');
			ylabel('Fluorescence (e.g. \DeltaF/F)','Interpreter','tex');
			axis([0 length(thisTrace) minValTraces maxValTraces]);
			thisStr = ['SNR = ' num2str(signalSnr(i)) ' | S-ratio = ' num2str(NaN) ' | # peaks = ' num2str(length(testpeaks)) ' | size (px) = ' num2str(inputImageSizes(i))];
			title(thisStr,'FontSize',options.fontSize,'Interpreter','tex')
		end

		% Force to be on the main figure
		if i==1
			figure(mainFig);
		end
		% Turn off ability for users to alter existing axes
		% set(findobj(gcf,'type','axes'),'hittest','off')

		set(mainFig,'CurrentAxes',avgSpikeTracePlotHandle);
			% set(gca,'hittest','off')
			box off;
		set(mainFig,'CurrentAxes',tracePlotLocHandle);
			% set(gca,'hittest','off')
			box off;
		set(mainFig,'CurrentAxes',objMapPlotLocHandle);
			box off;
		set(mainFig,'CurrentAxes',objMapZoomPlotLocHandle);
			box off;
		linkaxes([avgSpikeTracePlotHandle tracePlotLocHandle],'y');

		validPrevious = valid(i);
		warning('off','all')

		% Disable pointer in the window
		if options.disableMousePointer==1
			set(gcf,'pointer','custom','PointerShapeCData',NaN([16 16]));
		end

		if ~isempty(options.inputMovie)
			try
				if options.peakTrigMovieMontage==0
					movieCallback();
				elseif isempty(objCutMovieCollection{i})&&ischar(options.inputMovie)==1
					if exist('objCutMovieAsyncF','var')==1
						if isempty(objCutMovieAsyncF{i})
							objCutMovie = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,i,options.cropSizeLength,maxValMovie);
						else
							% Fetch output, blocks UI until read
							objCutMovie = fetchOutputs(objCutMovieAsyncF{i});
							objCutMovieCollection{i} = objCutMovie;
							% Remove job and associated storage
							delete(objCutMovieAsyncF{i});
						end
					else
						objCutMovie = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,i,options.cropSizeLength,maxValMovie);
					end
					p = gcp(); % Get the current parallel pool

					if exist('optionsCpy','var')==1
					else
						optionsCpy.inputMovie = options.inputMovie;
						optionsCpy.inputMovieDims = options.inputMovieDims;
						optionsCpy.maxSignalsToShow = options.maxSignalsToShow;
						optionsCpy.coord = options.coord;
						optionsCpy.crossHairPercent = options.crossHairPercent;
						optionsCpy.inputDatasetName = options.inputDatasetName;
						optionsCpy.hdf5Fid = options.hdf5Fid;
						optionsCpy.keepFileOpen = options.keepFileOpen;
						optionsCpy.outlinesObjCutMovie = options.outlinesObjCutMovie;
						% optionsCpy = options;
						optionsCpy.hdf5Fid = [];
						optionsCpy.nMovieFrames = options.nMovieFrames;
					end
					for kk = (i+1):(i+options.nSignalsLoadAsync)
						% Don't try to load signals out of range
						if kk>nSignalsHere
							continue;
						end
						if isempty(objCutMovieAsyncF{kk})&&isempty(objCutMovieCollection{kk})
							objCutMovieAsyncF{kk} = parfeval(p,@createObjCutMovieSignalSorter,1,optionsCpy,signalPeakIdx{kk},inputSignals(kk,:),inputImages(:,:,kk),kk,options.cropSizeLength,maxValMovie);
						else

						end
					end
				elseif isempty(objCutMovieCollection{i})&&ischar(options.inputMovie)==0
					objCutMovie = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,i,options.cropSizeLength,maxValMovie);
				else
					objCutMovie = objCutMovieCollection{i};
				end

				j = whos('objCutMovieCollection');j.bytes=j.bytes*9.53674e-7;
				objCutMovieCollectionMB = j.bytes;
				if objCutMovieCollectionMB>options.maxAsyncStorageSize&&options.readMovieChunks==1&&options.preComputeImageCutMovies==0
					display(['objCutMovieCollection: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
					disp('Removing old images to save space...')
					for kk = 1:(i-5)
						if kk<nSignalsHere&&kk>1
							objCutMovieCollection{kk} = [];
						end
					end
				end

				if options.movieMin<options.movieMinLim
					objCutMovie(1,1,:) = options.movieMinLim;
					minHere = options.movieMinLim;
				else
					objCutMovie(1,1,:) = options.movieMin;
					minHere = options.movieMin;
				end
				maxHere = options.movieMax;
				objCutMovie(1,2,:) = options.movieMax;

				if i==1
					inputMoviePlotLocHandle = subplotCustom(subplotY,subplotX,inputMoviePlotLoc);
				else
					set(mainFig,'CurrentAxes',inputMoviePlotLocHandle);
				end

				% set title and turn off ability to change
				if ~isempty(objCutMovie)
					imAlpha=ones(size(objCutMovie(:,:,1)));
					imAlpha(isnan(objCutMovie(:,:,1)))=0;
					imagesc(objCutMovie(:,:,1),'AlphaData',imAlpha);
					try
						caxis([minHere maxHere]);
					catch
						caxis([-0.05 0.1]);
					end
					if options.axisEqual==1
						axis equal tight;
					end
					set(gca,'color',[0 0 0]);
				else

				end
				set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'))

				% Force re-draw
				if i==1
					drawnow
				end

				frameNoMax = size(objCutMovie,3);
				frameNo = round(frameNoMax*0.40);
				set(gcf,'currentch','3');
				keyIn = get(gcf,'CurrentCharacter');

				if i==1
					colormap([options.colormap]);
				end

				if ~isempty(objCutMovie)
					imAlpha=ones(size(objCutMovie(:,:,1)));
					imAlpha(isnan(objCutMovie(:,:,1)))=0;
					imAlpha(objCutMovie(:,:,1)==0)=0;
					set(gca,'color',[0 0 0]);
				end

				set(gca,'color',[0 0 0]);
				loopImgHandle = imagesc(objCutMovie(:,:,frameNo),'AlphaData',imAlpha);
				if options.axisEqual==1
					axis equal tight;
				end

				set(gca,'color',[0 0 0]);
				set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'))

				if options.signalLoopTicTocCheck==1
					toc
				end

				try
					caxis([minHere maxHere]);
				catch
					caxis([-0.05 0.1]);
				end

				if options.peakTrigMovieMontage==1
					title(['Press Q to change movie contrast.' 10 'Press Z to turn zoom on.' 10 'Press B to select specific frame for movie' 10 'Frame slider at bottom.'],'FontSize',options.fontSize,'Interpreter','tex')
				else
					title(['Press Q to change movie contrast.' 10 'Press Z to turn zoom on.' 10 'Press B to switch to movie montage.' 10 'Zoom enabled in trace panel.'],'FontSize',options.fontSize,'Interpreter','tex')
				end

				% ==========================================
				% ADD PROGRESS BAR
				if exist('axValid','var')==1
					[axValid axValidAll] = subfxnSignalSorterProgressBars(i,valid,inputMoviePlotLocHandle,inputMoviePlotLoc2Handle,options,mainFig,axValid,axValidAll,cellIDStr);
				else
					[axValid axValidAll] = subfxnSignalSorterProgressBars(i,valid,inputMoviePlotLocHandle,inputMoviePlotLoc2Handle,options,mainFig,[],[],cellIDStr);
				end

				set(mainFig,'CurrentAxes',inputMoviePlotLocHandle);

				frameNoTotal = 0; % use this to lock

				if options.peakTrigMovieMontage==0
					% zoom on;
					zoomHandle = zoom;
					zoomHandle.Enable = 'on';
					set(zoomHandle,'ActionPostCallback',@sliderZoomCallback);
				end

				set(objMapPlotLocHandle,'tag','objMapPlotLocHandle')
				set(objMapZoomPlotLocHandle,'tag','objMapZoomPlotLocHandle')
				% if strcmp(get(zoom(1),'Enable'),'off')
				% 	pan on;
				% end
				set(objMapPlotLocHandle,'ButtonDownFcn',@subfxnSelectCellOnCellmap)
				set(objMapZoomPlotLocHandle,'ButtonDownFcn',@subfxnSelectCellOnCellmap)
				set(mainFig, 'KeyPressFcn', @(source,eventdata) figure(mainFig));

				while strcmp(keyIn,'3')
					frameNoTotal = frameNoTotal+1;
					if frameNoTotal>3
						keyIn = get(gcf,'CurrentCharacter');
					else
						set(gcf,'currentch','3');
					end
					if ~isempty(objCutMovie)
						% Use Cdata update instead of imagesc to improve drawnow speed, esp. on Matlab 2018b.
						set(loopImgHandle,'Cdata',squeeze(objCutMovie(:,:,frameNo)));
					else

					end
					if frameNo==frameNoMax
						frameNo = 1;
					end
					pause(1/options.fps);
					frameNo = frameNo + 1;
				end
				set(objMapPlotLocHandle,'tag','objMapPlotLocHandle')
				set(objMapZoomPlotLocHandle,'tag','objMapZoomPlotLocHandle')

				reply = double(keyIn);
				set(gcf,'currentch','3');
			catch err
				size(objCutMovie)
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				keyIn = get(gcf,'CurrentCharacter');
				reply = double(keyIn);
				set(gcf,'currentch','3');
			end
		else
			keyIn = get(gcf,'CurrentCharacter');
			reply = double(keyIn);
			set(gcf,'currentch','3');
		end
		figure(mainFig);
		warning('on','all')

		try
			subfxnUserInputGui();
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end

		% update images
		if validPrevious==valid(i)
		elseif valid(i)==1
			goodImages = goodImages+currentImageThres;goodImages(goodImages<0) = 0;
			% badImages = badImages-currentImageThres;badImages(badImages<0) = 0;
			badImages = badImages-100*goodImages;badImages(badImages<0) = 0;
			if validPrevious==3
				neutralImages = neutralImages-currentImageThres;
			end
		elseif valid(i)==0
			if validPrevious==1
				goodImages = goodImages-currentImageThres;goodImages(goodImages<0) = 0;
			end
			badImages = badImages+currentImageThres;badImages(badImages<0) = 0;
			if validPrevious==3
				neutralImages = neutralImages-currentImageThres;
			end
		end
		% loop if user gets to either end
		i=i+directionOfNextChoice;
		if i<=0; i = nImages; end
		if i>nImages; i = 1; end
		figure(mainFig);

		% already checked that tmp folder exists, then save
		try
			if exist(tmpDir,'file')
				save([tmpDir filesep 'tmpDecisions_' sessionID '.mat'],'valid');
			end
		catch

		end

		loopCount = loopCount+1;
	end
	% warning on
	warning('on','all')
	warning('query','all')
	safeExit = 1;
	function subfxnUserInputGui()
		% 'M' make a montage of peak frames
		if isequal(reply, 109)&&~isempty(options.inputMovie)
			try
				% [~, ~] = openFigure(options.secondFigNo, '');
				figure(options.secondFigNo)
				clf
				croppedPeakImages2 = viewMontage(options.inputMovie,thisImage,options,thisTrace,[signalPeakIdx{i}],minValMovie,maxValMovie,options.cropSizeLength,i,1);
				imAlpha = ones(size(croppedPeakImages2));
				imAlpha(isnan(croppedPeakImages2))=0;
				imagesc(croppedPeakImages2,'AlphaData',imAlpha);
				if options.axisEqual==1
					axis equal tight;
				end
				set(gca,'color',[0 0 0]);
				colormap(options.colormap);
				set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'))
						set(gca,'color',[0 0 0]);

				colorbar('Location','eastoutside');

				suptitle('Press any key to exit')
				set(gcf,'currentch','3');
				keyIn = get(gcf,'CurrentCharacter');
				drawnow
				while strcmp(keyIn,'3')
					keyIn = get(gcf,'CurrentCharacter');
					pause(1/options.fps);
				end
				close(options.secondFigNo);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		% 'P' display neighboring cells
		elseif isequal(reply, 112)
			disp('Paused, press key to resume.')
			pause;
		% 'Y' go to the last displayed cell
		elseif isequal(reply, 121)
			i = lastSortedSignal;
		% 'V' Allow user to select and go to cell on cellmap
		elseif isequal(reply, 118)
			subfxnSelectCellOnCellmap();
		% 'B' toggle movie frame montage and frame select
		elseif isequal(reply, 98)
			if options.peakTrigMovieMontage==1
				options.peakTrigMovieMontage = 0;
				set(frameSlider,'Enable','on');
				set(frameText,'ForegroundColor',[0 0 0]);
				set(mainFig,'CurrentAxes',inputMoviePlotLocHandle);
			else
				options.peakTrigMovieMontage = 1;
				set(frameSlider,'Enable','off');
				set(frameText,'ForegroundColor',[0.7 0.7 0.7],'String','Disabled. Press B to active');
			end
		% 'Z' toggle zoom
		elseif isequal(reply, 122)
			zoom on;
		% 'T' display neighboring cells
		elseif isequal(reply, 116)
			overlapDistance = inputdlg('Enter distance to look for neighbors','',[1 50],{'10'});
			if isempty(overlapDistance)

			else
				overlapDistance = str2double(overlapDistance{1});
				viewNeighborsAuto(inputImages, inputSignals, {}, 'inputImagesThres',inputImagesThres,'xCoords',options.coord.xCoords,'yCoords',options.coord.yCoords,'startCellNo',i,'cropSizeLength',options.cropSizeLength,'overlapDistance',overlapDistance);
			end
		% 'D' change colormap
		elseif isequal(reply, 100)
			options.colormap = options.colormapColorList{options.colormapIdx};
			options.colormapIdx = options.colormapIdx+1;
			if options.colormapIdx>length(options.colormapColorList)
				options.colormapIdx = 1;
			end
			colormap(options.colormap);
		% 'A' change global font
		elseif isequal(reply, 97)
			userInput = inputdlg('New font');
			userInput = str2num(userInput{1});
			options.fontSize = userInput;
			set(findall(gcf,'-property','FontSize'),'FontSize',options.fontSize);
		% 'L' re-display legend
		elseif isequal(reply, 108)
			subfxnCreateLegend();
		% 'I' display trace with median removed
		elseif isequal(reply, 105)
			% [~, ~] = openFigure(options.secondFigNo, '');
			figure(options.secondFigNo)
				clf
				set(gcf,'currentch','3');
				keyIn = get(gcf,'CurrentCharacter');

				imAlpha = ones(size(thisImage));
				imAlpha(isnan(thisImage)) = 0;
				imAlpha(thisImage==0) = 0;
				imagesc(thisImage,'AlphaData',imAlpha);
				set(gca,'color',[0 0 0]);

				axis equal tight
				colormap([options.colormap]);
				colorbar
				suptitle('Current signal source image | Press any key to exit')
				drawnow
				while strcmp(keyIn,'3')
					keyIn = get(gcf,'CurrentCharacter');
					pause(1/options.fps);
				end
				close(options.secondFigNo)
		% 'R' display trace with median removed
		elseif isequal(reply, 114)
			% [~, ~] = openFigure(options.secondFigNo, '');
			figure(options.secondFigNo)
				clf
				set(gcf,'currentch','3');
				keyIn = get(gcf,'CurrentCharacter');

				% thisTrace
				medianFilterLength = 200;
				% options.medianFilterLength
				inputSignalMedianTmp = medfilt1(thisTrace,medianFilterLength);
				sigTmp1 = inputSignalSignal{i} - inputSignalMedianTmp;
				noiseTmp1 = inputSignalNoise{i} - inputSignalMedianTmp;
				plotYn = 5;
				linkAx = [];
				linkAx(end+1) = subplot(plotYn,1,1);
					plot(thisTrace,'k');
					hold on;
					scatter(testpeaks, min(maxValTraces*0.97,thisTrace(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
					title('Original','FontSize',options.fontSize)
					box off;zoom on;
				linkAx(end+1) = subplot(plotYn,1,2);
					plot(inputSignalNoise{i},'Color',[0.5 0.5 0.5]);
					hold on
					plot(inputSignalSignal{i},'r');

					ss1 = inputSignalNoise{i};
					ss1(isnan(ss1)) = 0;
					ss2 = inputSignalSignal{i};
					ss2(isnan(ss2)) = 0;
					ss1 = ss1 + ss2;
					scatter(testpeaks, min(maxValTraces*0.97,ss1(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0]);
					title('Displayed','FontSize',options.fontSize)
					box off;zoom on;
				linkAx(end+1) = subplot(plotYn,1,3);
					plot(noiseTmp1,'k');
					hold on
					plot(sigTmp1,'r');

					ss1 = sigTmp1;
					ss1(isnan(ss1)) = 0;
					ss2 = noiseTmp1;
					ss2(isnan(ss2)) = 0;
					ss1 = ss1 + ss2;
					scatter(testpeaks, min(maxValTraces*0.97,ss1(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0]);

					title('Median filtered','FontSize',options.fontSize)
					box off;zoom on;
				linkAx(end+1) = subplot(plotYn,1,4);
					if ~isempty(options.inputMovie)&&~ischar(options.inputMovie)
						[ROItraces] = applyImagesToMovie(inputImagesThres(:,:,i),options.inputMovie,'alreadyThreshold',1,'waitbarOn',1);
						% linkAx(end+1) = subplot(plotYn,1,4);
							plot(ROItraces,'k');
							hold on;
							scatter(testpeaks, min(maxValTraces*0.97,ROItraces(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0]);
							title('ROI calculated trace','FontSize',options.fontSize)
							box off;zoom on;

						% frImg = cat(3,inputImagesThres(:,:,i),inputImagesThres(:,:,i));
						% LStraces = calculateTraces(frImg, options.inputMovie,'removeBelowThreshPixelsForRecalc',0);

						% % LStraces = calculateTraces(inputImagesThres, options.inputMovie,'removeBelowThreshPixelsForRecalc',0);
						% % size(LStraces)
						% % LStraces = permute(double(extract_traces(options.inputMovie,frImg)),[2 1]);
						% % LStraces(1,1:00)
						% % LStraces = LStraces(i,:);
						% subplot(plotYn,1,4)
							% plot(LStraces(1,:),'k'); hold on;
							% plot(LStraces(1,:)-medfilt1(LStraces(1,:),medianFilterLength),'r');
							% legend({'Normal','Median removed'})
							% title('Least Squares')
					else
						title('NO DATA, EXCLUDED: ROI calculated trace','FontSize',options.fontSize)
					end
				linkAx(end+1) = subplot(plotYn,1,5);
					if ~isempty(options.inputSignalsSecond)
						tmpSecondTrace = options.inputSignalsSecond(i,:);
						plot(tmpSecondTrace,'k');
						hold on;
						scatter(testpeaks, min(maxValTraces*0.97,tmpSecondTrace(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0]);
						title('Original trace (secondary)','FontSize',options.fontSize)
						box off;zoom on;
					else
						title('NO DATA, EXCLUDED: Original trace (secondary)','FontSize',options.fontSize)
					end

				suptitle('Press any key to exit | Zoom is enabled on traces, x axes are linked')
				linkaxes(linkAx,'x');
				drawnow
			while strcmp(keyIn,'3')
				keyIn = get(gcf,'CurrentCharacter');
				pause(1/options.fps);
			end
			close(options.secondFigNo)

		% 'Q' to change the min/max used for movie contrast
		elseif isequal(reply, 113)
			[sel, ok] = listdlg('ListString',{'Adjustable contrast GUI','Contrast input dialog'},'ListSize',[300 300]);
			if sel==1
				try
					fixMultiplier = 1e5;
					thisFrameTmp = double(objCutMovie(:,:,frameNo));
					thisHandle = inputMoviePlotLocHandle;
					montageHandle = findobj(thisHandle,'Type','image');
					set(montageHandle,'Cdata',thisFrameTmp*fixMultiplier,'AlphaData',imAlpha);
					minCurr = double(options.movieMin)*fixMultiplier;
					maxCurr = double(options.movieMax)*fixMultiplier;
					[minCurr maxCurr]
					caxis(thisHandle,[minCurr maxCurr]);

					htool = imcontrast(thisHandle);
					set(htool,'WindowStyle','normal');
					caxis(thisHandle,[minCurr maxCurr]);

					warning on
					uiwait(msgbox('Adjust the contrast then hit OK','Contrast'));
					% Grab from the UI llabels for Window Minimum and Maximum
					options.movieMax = str2num(htool.Children(1).Children(3).Children.Children(2).Children.Children(2).Children(2).String)/fixMultiplier;
					options.movieMin = str2num(htool.Children(1).Children(3).Children.Children(2).Children.Children(2).Children(5).String)/fixMultiplier;
					disp(['New min: ' num2str(options.movieMin) ' and max: ' num2str(options.movieMax)])

					set(montageHandle,'Cdata',thisFrameTmp,'AlphaData',imAlpha);
					caxis(thisHandle,[options.movieMin options.movieMax]);
					close(htool);
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			else
				try
					answer = inputdlg({'min','max'},'Movie min/max for contrast',[1 100],{num2str(minHere),num2str(maxHere)});
					if ~isempty(answer)
						options.movieMin = str2double(answer{1});
						options.movieMax = str2double(answer{2});
					end
					colorbar(inputMoviePlotLoc2Handle,'off');
					s2Pos = plotboxpos(inputMoviePlotLoc2Handle);
					cbh = colorbar(inputMoviePlotLoc2Handle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)],'FontSize',6);
					ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)','FontSize',8);
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			end

		% 'W' to change the min/max used for traces
		elseif isequal(reply, 119)
			answer = inputdlg({'min','max'},'Signal trace min/max for plotting',[1 100],{num2str(minValTraces),num2str(maxValTraces)});
			if ~isempty(answer)
				minValTraces = str2double(answer{1});
				maxValTraces = str2double(answer{2});
			end
		% 'E' to change the FPS
		elseif isequal(reply, 101)
			answer = inputdlg({'fps'},'FPS for displaying movie',[1 100],{num2str(options.fps)});
			if ~isempty(answer)
				options.fps = str2double(answer{1});
			end
		% 'C' compare signal to movie
		elseif isequal(reply, 99)&&~isempty(options.inputMovie)
			signalPeakArray = [signalPeakIdx{i}];
			peakSignalAmplitude = thisTrace(signalPeakArray(:));
			[peakSignalAmplitude, peakIdx] = sort(peakSignalAmplitude,'descend');
			signalPeakArray = {signalPeakArray(peakIdx)};
			try
				compareSignalToMovie(options.inputMovie, thisImage, thisTrace,'waitbarOn',0,'timeSeq',-10:10,'signalPeakArray',signalPeakArray,'cropSize',options.cropSizeLength,'movieMinMax',[minHere maxHere],'inputDatasetName',options.inputDatasetName,'inputMovieDims',options.inputMovieDims,'colormap',options.colormap);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				disp('Error displaying movie signal')
			end
		% 'X' montage cut movie
		elseif (isequal(reply, 120)||isequal(reply, 2)||isequal(reply, 48))&&~isempty(options.inputMovie)
			try
				[objCutMovie] = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,i,options.cropSizeLength,maxValMovie);
				% objCutMovie(:,:,1) = nanmax(objCutMovie(:));
				playMovie(objCutMovie,'fps',15,'movieMinMax',[minHere maxHere],'colormapColor',options.colormap);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		else
			[valid, directionOfNextChoice, saveData, i, lastSortedSignal] = respondToUserInput(reply,i,valid,directionOfNextChoice,saveData,nImages,lastSortedSignal);
		end
	end
	function subfxnSelectCellOnCellmap(source,eventdata)
		[xUser,yUser,~] = ginputCustom(1);
		mapTags = {'objMapPlotLocHandle','objMapZoomPlotLocHandle'};
		thisPlotTag = find(ismember(mapTags, get(gca,'tag')));
		if isempty(thisPlotTag)
			% zoom;
		elseif thisPlotTag<0|thisPlotTag>length(mapTags)
			% zoom;
		else
			thisPlotTag = mapTags{thisPlotTag};
			switch thisPlotTag
				% Normal cellmap
				case 'objMapPlotLocHandle'
					distancePointToCells = ((xCoords - xUser).^2 + (yCoords - yUser).^2).^(1/2);
					[~,jumpToCell] = min(distancePointToCells);
				% Zoomed in cellmap
				case 'objMapZoomPlotLocHandle'
					% Map from the zoomed space back to the full cellmap space to calculate distance, using the knowledge that the current cell is at the center of the zoomed image
					xCurr = xCoords(i);
					yCurr = yCoords(i);
					xCent = size(zoomCellmapImg,2)/2;
					yCent = size(zoomCellmapImg,1)/2;
					xUser2 = xCurr + (xUser - xCent);
					yUser2 = yCurr + (yUser - yCent);
					% xCorrection =
					% yCorrection =
					distancePointToCells = ((xCoords - xUser2).^2 + (yCoords - yUser2).^2).^(1/2);
					[~,jumpToCell] = min(distancePointToCells);
				otherwise
					% User selected invalid plot, stay at the same cell
					jumpToCell = i;
			end
			if ~isempty(jumpToCell)
				icChange = jumpToCell;
				% Check user entered integer
				if mod(icChange,1) == 0
					if icChange>nImages||icChange<1
						% do nothing, invalid command
						disp('Goto value entered not in range')
					else
						i = icChange;
						directionOfNextChoice = 0;
					end
				end
			else
				disp('Enter actual number')
			end
		end
		% Force exit current display loop and display chosen cell since callback.
		keyIn = 1e7;
	end
	function sliderZoomCallback(source,eventdata)
		% When user zooms in on the activity trace, adjust the slider range accordingly
		% disp('CHECK1')
		nFrames = size(inputSignals,2);
		xlimHere = get(tracePlotLocHandle,'XLim');
		frameNoCall = max(1,round(get(frameSlider,'value')));
		frameNoCall = min(xlimHere(2)+1,max(xlimHere(1)-1,round(frameNoCall)));
		if frameNoCall<xlimHere(1)|frameNoCall>xlimHere(2)
			frameNoCall = round(mean(xlimHere(:)));
		end
		set(frameSlider,'value',frameNoCall);
		try
			nFrameTmp = round(xlimHere(2) - xlimHere(1));
			set(frameSlider,'min',xlimHere(1),'max',xlimHere(2),'SliderStep',[1/nFrameTmp (nFrameTmp*0.07)*(1/nFrameTmp)])
		catch
			set(frameSlider,'min',xlimHere(1),'max',xlimHere(2),'SliderStep',[1/nFrames (nFrames*0.07)*(1/nFrames)])
		end
	end
	function frameCallback(source,eventdata)
		% Whenever the frame slider is moved, update the frame text and indicator line

		frameNoCall = max(1,round(get(frameSlider,'value')));
		% signalNo = max(1,round(get(signalSlider,'value')));
		nFrames = size(inputSignals,2);
		set(frameSlider,'value',frameNoCall);
		set(frameText,'visible','on','string',['Frame ' num2str(frameNoCall) '/' num2str(nFrames)])

		breakLoop = 1;

		% Update the frame line indicator
		set(mainFig,'CurrentAxes',tracePlotLocHandle)
			if isvalid(frameLineHandle)
				frameLineHandle.XData = [frameNoCall frameNoCall];
			end
	end
	function movieCallback(source,eventdata)
		try
			frameNoCall = max(1,round(get(frameSlider,'value')));
			thisCellImg = inputImages(:,:,i);
			breakLoop = 0;
			if ~isempty(options.inputMovie)
				% Get the image cut movie
				frameListHere = frameNoCall+[-options.nMovieFrames:options.nMovieFrames];
				nFrames = size(inputSignals,2);
				frameListHere(frameListHere>nFrames) = nFrames;
				frameListHere(frameListHere<1) = 1;
				if ischar(options.inputMovie)||iscell(options.inputMovie)
					objCutMovie = getObjCutMovie(options.inputMovie,thisCellImg,'createMontage',0,'extendedCrosshairs',0,'outlines',0,'waitbarOn',0,'cropSize',options.cropSize,'crossHairsOn',0,'addPadding',0,'frameList',frameListHere);
				else
					tmpMovieHere = options.inputMovie(:,:,frameListHere);
					objCutMovie = getObjCutMovie(tmpMovieHere,thisCellImg,'createMontage',0,'extendedCrosshairs',0,'outlines',0,'waitbarOn',0,'cropSize',options.cropSize,'crossHairsOn',0,'addPadding',0,'frameList',frameListHere);
				end
				objCutImg = getObjCutMovie(thisCellImg,thisCellImg,'createMontage',0,'extendedCrosshairs',0,'outlines',0,'waitbarOn',0,'cropSize',options.cropSize,'crossHairsOn',0,'addPadding',0);
				objCutImg = objCutImg{1};
				objCutMovie = objCutMovie{1};
				thresholdOutline = options.thresholdOutline;
				[thresholdedImages, boundaryIndices] = thresholdImages(objCutImg,'binary',1,'getBoundaryIndex',1,'threshold',thresholdOutline);
				if length(frameListHere)>1
					for zzzz = 1:size(objCutMovie,3)
						tmpFrame = objCutMovie(:,:,zzzz);
						tmpFrame([boundaryIndices{:}]) = NaN;
						objCutMovie(:,:,zzzz) = tmpFrame;
					end
				end
				imAlpha = ones(size(objCutMovie(:,:,1)));
				imAlpha(isnan(objCutMovie(:,:,1))) = 0;
				imAlpha(objCutMovie(:,:,1)==0) = 0;
				set(loopImgHandle,'Cdata',squeeze(objCutMovie(:,:,1)),'AlphaData',imAlpha);
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
end
function [axValid axValidAll] = subfxnSignalSorterProgressBars(i,valid,inputMoviePlotLocHandle,inputMoviePlotLoc2Handle,options,mainFig,axValid,axValidAll,cellIDStr)
	validData = cat(3,double(valid(:)'==0|valid(:)'>1),double(valid(:)'==1|valid(:)'>1),double(valid(:)'>1))/2;
	validData(:,valid==0,1) = 1;
	validData(:,valid==1,2) = 1;
	if i==1
		if ~isempty(axValid)
			delete(findobj(mainFig,'Tag','colorProgressBar1'));
		end
		colorbar(inputMoviePlotLoc2Handle,'off')
		s2Pos = plotboxpos(inputMoviePlotLoc2Handle);
		cbh = colorbar(inputMoviePlotLoc2Handle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)],'FontSize',options.fontSize-2);
		ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)','FontSize',options.fontSize-1);

		s3Pos = plotboxpos(gca);

		axValid = axes('Position',[s3Pos(1) 0.98 s3Pos(3) 0.02],'XTick',[],'YTick',[]);
		validImgHandle = imagesc(axValid,validData);
		set(axValid,'XTick',[],'YTick',[],'Tag','colorProgressBar1')
		xlabel(['Cell (green), non-cell (red), unknown (gray) | ' 'signal ' cellIDStr ' (' num2str(sum(valid==1)) ' good)'],'FontSize',options.fontSize-2)
	else
		thisHandle = findobj(axValid,'Type','image');
		set(thisHandle,'CData',validData);
		set(mainFig,'CurrentAxes',axValid);
		xlabel(['Cell (green), non-cell (red), unknown (gray) | ' 'signal ' cellIDStr ' (' num2str(sum(valid==1)) ' good)'],'FontSize',options.fontSize-2)
	end

	validSorted = sort(valid);
	validData = cat(3,double(validSorted(:)'==0|validSorted(:)'>1),double(validSorted(:)'==1|validSorted(:)'>1),double(validSorted(:)'>1))/2;
	validData(:,validSorted==0,1) = 1;
	validData(:,validSorted==1,2) = 1;
	if i==1
		if ~isempty(axValidAll)
			delete(findobj(mainFig,'Tag','colorProgressBar2'));
		end
		set(mainFig,'CurrentAxes',inputMoviePlotLoc2Handle);
		s3Pos = plotboxpos(gca);
		axValidAll = axes('Position',[s3Pos(1) 0.98 s3Pos(3) 0.02],'XTick',[],'YTick',[]);
		validImgHandle = imagesc(axValidAll,validData);
		set(axValidAll,'XTick',[],'YTick',[],'Tag','colorProgressBar2')
		xlabel(['Percent: cell (green), non-cell (red), unknown (gray).'],'FontSize',options.fontSize-2)
	else
		thisHandle = findobj(axValidAll,'Type','image');
		set(thisHandle,'CData',validData);
	end
end
function subfxnLostFocusMainFig(jAxis, jEventData, hFig)
   figure(hFig);
end

function instructionStr = subfxnCreateLegend()
	sepStrNum = 10;
	instructionStr =  [...
	'signalSorter',sepStrNum,...
	'Keyboard shortcuts and legend',sepStrNum,...
	'Drag edges to resize legend window.',sepStrNum,sepStrNum,...
	'===Keyboard shortcuts===',sepStrNum,...
	'Mouse click cellmap to select and go to cell',sepStrNum,...
	'KEY        | COMMAND',sepStrNum,...
	'up/down    | mark current as good/bad',sepStrNum,...
	'left/right | move to next/previous signal',sepStrNum,...
	'v          | select cell on cellmap',sepStrNum,...
	'y          | go to last sorted cell',sepStrNum,...
	'f          | finish and save selections',sepStrNum,...
	'q          | change movie CONTRAST (min/max)',sepStrNum,...
	'g          | goto signal #...',sepStrNum,...
	'c          | movie during transients',sepStrNum,...
	't          | GUI for comparing neighboring signals',sepStrNum,...
	'r          | show traces in full figure',sepStrNum,...
	'm          | movie snapshot during transients',sepStrNum,...
	'i          | full FOV for current cell extraction image',sepStrNum,...
	'x          | montage transients in movie',sepStrNum,...
	's          | set remaining signals as bad',sepStrNum,...
	'w          | change trace min/max',sepStrNum,...
	'e          | change fps of transient movies',sepStrNum,...
	'd          | change colormap',sepStrNum,...
	'l          | create new legend',sepStrNum,...
	'p          | pause GUI, goto command window',sepStrNum,...
	'z          | toggle zoom',sepStrNum,...
	'a          | change GUI font',sepStrNum,sepStrNum,...
	'b          | Toggle movie frame select',sepStrNum,sepStrNum,...
	'===Cell map legend===',sepStrNum,...
	'green = good',sepStrNum,...
	'red = bad',sepStrNum,...
	'gray = undecided',sepStrNum,...
	'blue = current',sepStrNum,sepStrNum,...
	'===Auto classify parameters===',sepStrNum,...
	'Eccentricity>0.4',sepStrNum,...
	'imageSizes>10,<100',sepStrNum,...
	'Perimeter<50,>5',sepStrNum,...
	'EquivDiameter>3,<30',sepStrNum,...
	'signalSnr>1.45',sepStrNum,...
	'slopeRatio>0.02',sepStrNum,sepStrNum];
	% msgbox(instructionStr)

	tmpHandle = figure(2);
	close(tmpHandle);
	tmpHandle = figure(2);
	clf
	set(tmpHandle,'Name','Key legend','NumberTitle','off')
	uicontrol('style','text','string',instructionStr,'Units', 'normalized','position',[1 1 80 90]/100,'horizontalAlignment', 'left','FontSize',9)
	suptitle('signalSorter shortcuts/legend')
	axis off

	% s.Interpreter = 'tex';
	% % s.WindowStyle = 'non-modal';
	% s.WindowStyle = 'replace';
	% h = msgbox_custom(['\fontsize{10}' instructionStr],'signalSorter shortcuts/legend',s);
	% sspos = get(h, 'position'); %makes box bigger
	% scnsize = get(0,'ScreenSize');
	% set(h, 'position', [0 0 sspos(3)*1 sspos(4)*1]); %makes box bigger
end

function [objCutMovie] = createObjCutMovieSignalSorter(options,testpeaks,thisTrace,inputImages,i,cropSizeLength,maxValMovie)
	usePadding = 1;
	preOffset = options.nMovieFrames;
	postOffset = options.nMovieFrames;
	timeVector = (-preOffset:postOffset)';
	if ischar(options.inputMovie)||iscell(options.inputMovie)
		nPoints = options.inputMovieDims(3);
	else
		nPoints = size(options.inputMovie,3);
	end
	maxSignalsToShow = options.maxSignalsToShow-1;
	% bias toward high amplitude signals
	peakSignalAmplitude = thisTrace(testpeaks(:));
	[peakSignalAmplitude, peakIdx] = sort(peakSignalAmplitude,'descend');
	testpeaks = testpeaks(peakIdx);

	if length(testpeaks)==1
		testpeaks(end+1:end+2) = testpeaks;
	end

	testpeaks((testpeaks-preOffset)<1) = [];
	testpeaks((testpeaks+postOffset)>length(thisTrace)) = [];

	if length(testpeaks)>maxSignalsToShow
		% choose a random subset
		framesToAlign = testpeaks(1:maxSignalsToShow);
	else
		framesToAlign = testpeaks;
	end

	%remove points outside valid range
	peakIdxs = bsxfun(@plus,timeVector,framesToAlign(:)');
	nAlignPts = length(framesToAlign(:));
	% remove frame alignment outside range
	peakIdxs((peakIdxs<1)) = [];
	peakIdxs((peakIdxs>nPoints)) = [];
	objCutMovieNum = size(peakIdxs,2);
	peakIdxs = peakIdxs(:);

	xCoords = options.coord.xCoords(i);
	yCoords = options.coord.yCoords(i);

	if size(inputImages,3)==1
		tmpImgHere = inputImages;
	else
		tmpImgHere = inputImages(:,:,i);
	end
	if issparse(tmpImgHere)
		tmpImgHere = full(tmpImgHere);
	end
	% get movie cut around cell
	if ischar(options.inputMovie)||iscell(options.inputMovie)
		objCutMovie = getObjCutMovie(options.inputMovie,tmpImgHere,'createMontage',0,'extendedCrosshairs',2,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN,'frameList',peakIdxs,'inputDatasetName',options.inputDatasetName,'inputMovieDims',options.inputMovieDims,'hdf5Fid',options.hdf5Fid,'keepFileOpen',options.keepFileOpen);
	else
		tmpMovieHere = options.inputMovie(:,:,peakIdxs);
		objCutMovie = getObjCutMovie(tmpMovieHere,tmpImgHere,'createMontage',0,'extendedCrosshairs',2,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN,'inputMovieDims',options.inputMovieDims,'hdf5Fid',options.hdf5Fid,'keepFileOpen',options.keepFileOpen);
	end

	% Convert from cell to matrix
	objCutMovie = vertcat(objCutMovie{:});

	% Insure that the peak images are the same class as the input images for calculation purposes
	objCutMovie = cast(objCutMovie,class(tmpImgHere));

	dimSize = [size(objCutMovie,1) size(objCutMovie,2) length(timeVector)];
	diffDiffMatrix = NaN(dimSize);
	diffDiffMatrix2 = diffDiffMatrix;
	nStimMovies = 2;
	objCutMovieNum = objCutMovieNum+nStimMovies;
	for iii = 1:nStimMovies
		objCutMovie = cat(3, diffDiffMatrix, objCutMovie);
	end
	dimDiff = maxSignalsToShow + nStimMovies - objCutMovieNum;
	for diffNo = 1:dimDiff
		objCutMovie = cat(3, objCutMovie, diffDiffMatrix2);
	end

	inputImageAddObjCut = getObjCutMovie(tmpImgHere,tmpImgHere,'createMontage',0,'extendedCrosshairs',2,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN);
	inputImageAddObjCut = inputImageAddObjCut{1};
	inputImageAddObjCut = inputImageAddObjCut(:,:,1);
	inputImageAddObjCut = normalizeVector(inputImageAddObjCut,'normRange','zeroToOne')*nanmax(objCutMovie(:));

	inputImageAddObjCut2 = getObjCutMovie(tmpImgHere,tmpImgHere,'createMontage',0,'extendedCrosshairs',0,'crossHairsOn',0,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN);
	inputImageAddObjCut2 = inputImageAddObjCut2{1};
	inputImageAddObjCut2 = inputImageAddObjCut2(:,:,1);
	inputImageAddObjCut2 = normalizeVector(inputImageAddObjCut2,'normRange','zeroToOne')*nanmax(objCutMovie(:));

	inputImageAddObjCut = {inputImageAddObjCut,inputImageAddObjCut2};

	nStimPoints = length(timeVector);
	for imageNo = 0:(nStimMovies-1)
		idxToUse = ((imageNo*nStimPoints+1):((imageNo+1)*nStimPoints));
		% inputImageAddObjCut{imageNo+1} = inputImageAddObjCut{imageNo+1}+minHere;
		for iii = 1:length(idxToUse)
			objCutMovie(:,:,idxToUse(iii)) = inputImageAddObjCut{imageNo+1};
		end
	end

	if options.outlinesObjCutMovie==1
		croppedPeakImages = compareSignalToMovie(options.inputMovie, tmpImgHere, thisTrace,'crosshairs',0,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',0,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',0,'signalPeakArray',{testpeaks},'cropSize',cropSizeLength,'inputDatasetName',options.inputDatasetName,'inputMovieDims',options.inputMovieDims);
		[~, boundaryIndices] = thresholdImages(croppedPeakImages(:,:,1),'binary',1,'getBoundaryIndex',1,'threshold',options.thresholdOutline);
		for imageNo = nStimMovies:nStimMovies+2
			idxToUse = ((imageNo*nStimPoints+1):((imageNo+1)*nStimPoints));
			for iii = 1:length(idxToUse)
				tmpImg = objCutMovie(:,:,idxToUse(iii));
				tmpImg([boundaryIndices{:}]) = tmpImg([boundaryIndices{:}])+maxValMovie*options.crossHairPercent;
				objCutMovie(:,:,idxToUse(iii)) = tmpImg;
			end
		end
	end

	nAlignPts = nAlignPts+nStimMovies+dimDiff;
	[objCutMovie] = createStimCutMovieMontage(objCutMovie,nAlignPts,timeVector,'squareMontage',1,'addStimMovie',0);
end
function [croppedPeakImages2, croppedPeakImages] = viewMontage(inputMovie,inputImage,options,thisTrace,signalPeakArray,minValMovie,maxValMovie,cropSizeLength,i,dispImgFinal)
	displayImg = 1;
	if isempty(signalPeakArray)
		if displayImg==1
			imagesc(inputImage);
			colormap(options.colormap);
			axis off;
		end
		croppedPeakImages2 = inputImage;
		return
	end
	maxSignalsToShow = options.maxSignalsToShow-1;
	peakSignalAmplitude = thisTrace(signalPeakArray(:));
	[peakSignalAmplitude, peakIdx] = sort(peakSignalAmplitude,'descend');
	signalPeakArray = signalPeakArray(peakIdx);
	if length(signalPeakArray)>maxSignalsToShow
		% choose a random subset
		signalPeakArray = signalPeakArray(1:maxSignalsToShow);
	end

	signalPeakArray((signalPeakArray-31)<1) = [];
	signalPeakArray((signalPeakArray+31)>length(thisTrace)) = [];

	signalPeakArray = {signalPeakArray};
	xCoords = options.coord.xCoords(i);
	yCoords = options.coord.yCoords(i);

	% options.hdf5Fid
	croppedPeakImages = compareSignalToMovie(inputMovie, inputImage, thisTrace,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',2,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',1,'signalPeakArray',signalPeakArray,'cropSize',cropSizeLength,'addPadding',1,'outlineVal',NaN,'xCoords',xCoords,'yCoords',yCoords,'inputDatasetName',options.inputDatasetName,'inputMovieDims',options.inputMovieDims,'hdf5Fid',options.hdf5Fid,'keepFileOpen',options.keepFileOpen);
	meanTransientImageTmp = nanmean(croppedPeakImages(2:end-1,2:end-1,2:end),3);
	meanTransientImageTmp = padarray(meanTransientImageTmp,[1 1],NaN);
	meanTransientImage = zeros([size(meanTransientImageTmp,1) size(meanTransientImageTmp,2) 1]);
	meanTransientImage(:,:,1) = meanTransientImageTmp;
	croppedPeakImages = cat(3,meanTransientImage,croppedPeakImages);

	croppedPeakImages222 = compareSignalToMovie(inputMovie, inputImage, thisTrace,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',2,'crossHairVal',maxValMovie*options.crossHairPercent,'outlines',0,'signalPeakArray',signalPeakArray,'cropSize',cropSizeLength,'crosshairs',0,'addPadding',1,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN,'inputDatasetName',options.inputDatasetName,'inputMovieDims',options.inputMovieDims,'hdf5Fid',options.hdf5Fid,'keepFileOpen',options.keepFileOpen);
	[thresholdedImages, boundaryIndices] = thresholdImages(croppedPeakImages222(:,:,1),'binary',1,'getBoundaryIndex',1,'threshold',options.thresholdOutline,'removeUnconnectedBinary',0);
	for imageNo = 1:size(croppedPeakImages,3)
		tmpImg = croppedPeakImages(:,:,imageNo);
		tmpImg(boundaryIndices{1}) = NaN;
		croppedPeakImages(:,:,imageNo) = tmpImg;
	end
	if size(croppedPeakImages,3)<(options.maxSignalsToShow+1)
		dimDiff = (options.maxSignalsToShow+1)-size(croppedPeakImages,3);
		croppedPeakImagesTmp = NaN([size(croppedPeakImages,1) size(croppedPeakImages,2) dimDiff]);
		croppedPeakImages = cat(3,croppedPeakImages,croppedPeakImagesTmp);
	end

	% force outline
	outlineValTmp = NaN;
	croppedPeakImages(1,:,:) = outlineValTmp;
	croppedPeakImages(end,:,:) = outlineValTmp;
	croppedPeakImages(:,1,:) = outlineValTmp;
	croppedPeakImages(:,end,:) = outlineValTmp;

	[xPlot, yPlot] = getSubplotDimensions(size(croppedPeakImages,3));
	if yPlot>xPlot
		yPlotTmp = yPlot;
		yPlot = xPlot;
		xPlot = yPlotTmp;
	end

	nImagesH2 = xPlot*yPlot;
	croppedPeakImagesCell = cell([1 nImagesH2]);
	for iii = 1:nImagesH2
		if iii>size(croppedPeakImages,3)
			croppedPeakImagesCell{iii} = NaN(size(croppedPeakImages(:,:,1)));
		else
			croppedPeakImagesCell{iii} = croppedPeakImages(:,:,iii);
		end
	end

	croppedPeakImages2(:,:,:,1) = croppedPeakImages;

	if displayImg==1
		warning off

		mNum = 1;
		g = cell([xPlot 1]);
		rowNum = 1;
		for yNo = 1:yPlot
			for xNo = 1:xPlot
				g{rowNum} = cat(2,g{rowNum},croppedPeakImagesCell{mNum});
				mNum = mNum + 1;
			end
			rowNum = rowNum + 1;
		end
		croppedPeakImages2 = cat(1,g{:});
		croppedPeakImages2(1,1) = 0;
		croppedPeakImages2(1,2) = maxValMovie;

		imAlpha = ones(size(croppedPeakImages2));
		imAlpha(isnan(croppedPeakImages2))=0;

		if dispImgFinal==0
			return;
		end
		if i==1
			imagesc(croppedPeakImages2,'AlphaData',imAlpha);
		end
		montageHandle = findobj(gca,'Type','image');
		set(montageHandle,'Cdata',croppedPeakImages2,'AlphaData',imAlpha);


		set(gca,'color',[0 0 0]);
		if i==1
			colormap(options.colormap);
		end
		set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'))
		set(gca,'color',[0 0 0]);
		warning on
	end
end

function [slopeRatio] = plotPeakSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces,peakROI,avgSpikeTrace,slopeRatio,spikeCenterTrace,valid)
	% display plots of the signal around peaks in the signal

	try
		[peakSignalAmplitude, peakIdx] = sort(spikeCenterTrace(:,round(end/2)+1),'descend');
		spikeCenterTrace = spikeCenterTrace(peakIdx,:);
		if size(spikeCenterTrace,1)>20
			spikeCenterTrace = spikeCenterTrace(1:20,:);
		end

		plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
		hold on;
		plot(peakROI, avgSpikeTrace,'k', 'LineWidth',3);box off;
		plot(peakROI, nanmean(spikeCenterTrace),'Color',[1 0 0 1.0], 'LineWidth',2);box off;

		xlabel('frames');
		ylabel('Fluorescence (e.g. \DeltaF/F)','Interpreter','tex');
		ylim([minValTraces maxValTraces]);

		% add in zero line
		xval = 0;
		x=[xval,xval];
		y = ylim;
		h = plot(x,y,'r'); box off;
		uistack(h,'bottom');

		axisH = gca;
		axisH.XRuler.Axle.LineStyle = 'none';
		axisH.YRuler.Axle.LineStyle = 'none';

		hold off;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end

function plotSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces,options,inputSignalSignal,inputSignalNoise)
	peakSignalAmplitude = thisTrace(testpeaks(:));
	[peakSignalAmplitude, peakIdx] = sort(peakSignalAmplitude,'descend');
	testpeaks = testpeaks(peakIdx);
	if length(testpeaks)>options.maxSignalsToShow
		testpeaks = testpeaks(1:options.maxSignalsToShow);
	end

	% plots a signal along with test peaks
	options.movAvgFiltSize = 3;
	% number of frames to calculate median filter
	options.medianFilterLength = 201;

	plot(thisTrace, 'Color','k','LineWidth',1);
	hold on;
	plot(inputSignalNoise,'Color',[127 127 255]/255,'LineWidth',0.5);
	plot(inputSignalSignal,'Color',[255 0 0]/255,'LineWidth',0.5);

	scatter(testpeaks, min(maxValTraces*0.97,thisTrace(testpeaks)*1.4), 60, '.', 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])

	title([cellIDStr instructionStr],'FontSize',options.fontSize,'Interpreter','tex')
	xlabel('frames');
	axis([0 length(thisTrace) minValTraces maxValTraces]);
	box off;

	axisH = gca;
	axisH.XRuler.Axle.LineStyle = 'none';
	axisH.YRuler.Axle.LineStyle = 'none';

	hold off;
end
function [valid, directionOfNextChoice, saveData, i, lastSortedSignal] = respondToUserInput(reply,i,valid,directionOfNextChoice,saveData,nFilters,lastSortedSignal)
	% decide what to do based on input (not a switch due to multiple comparisons)
	if isequal(reply, 3)||isequal(reply, 110)||isequal(reply, 31)
		% 'N' key or right click
		directionOfNextChoice=1;
		% disp('invalid IC');
		% set(mainFig,'Color',[0.8 0 0]);
		valid(i) = 0;
		lastSortedSignal = i;
	elseif isequal(reply, 28)
		% go back, left
		directionOfNextChoice=-1;
		lastSortedSignal = i;
	elseif isequal(reply, 29)
		% go forward, right
		directionOfNextChoice=1;
		lastSortedSignal = i;
	elseif isequal(reply, 102)
		% user clicked 'F' for finished, exit loop
		movieDecision = questdlg('Are you sure you want to exit?', ...
			'Finish sorting', ...
			'yes','no','yes');
		if strcmp(movieDecision,'yes')
			saveData=1;
		end
		% i=nFilters+1;
	elseif isequal(reply, 103)
		% if user clicks 'G' for goto, ask for which IC they want to see
		icChange = inputdlg('enter signal #');
		if ~isempty(icChange{1})
			icChange = str2double(icChange{1});
			% Check user entered integer
			if mod(icChange,1) == 0
				if icChange>nFilters||icChange<1
					% do nothing, invalid command
					disp('Goto value entered not in range')
				else
					i = icChange;
					directionOfNextChoice = 0;
				end
			end
		else
			disp('Enter actual number')
		end
	elseif isequal(reply, 115)
		movieDecision = questdlg('Are you sure you want to exit?', ...
			'Finish sorting', ...
			'yes','no','yes');
		if strcmp(movieDecision,'yes')
			% 's' if user wants to get ride of the rest of the ICs
			disp(['classifying the following signals as bad: ' num2str(i) ':' num2str(nFilters)])
			valid(i:nFilters) = 0;
			saveData=1;
		end
	elseif isequal(reply, 121)||isequal(reply, 1)||isequal(reply, 30)
		% y key or left click
		directionOfNextChoice=1;
		lastSortedSignal = i;
		% disp('valid IC');
		% set(mainFig,'Color',[0 0.8 0]);
		valid(i) = 1;
	else
		% forward=1;
		% valid(i) = 1;
	end
	if directionOfNextChoice~=0
		try
			zoom off;
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
end
function [outputImage] = subfxnCropImages(inputImages)
	signalNo = 1;
	cropSize = 15;
	movieDims = size(inputImages);
	% get the centroids and other info for movie
	[xCoords, yCoords] = findCentroid(inputImages,'waitbarOn',0);

	% get region to crop
	warning off;
	xLow = xCoords(signalNo) - cropSize;
	xHigh = xCoords(signalNo) + cropSize;
	yLow = yCoords(signalNo) - cropSize;
	yHigh = yCoords(signalNo) + cropSize;
	% check that not outside movie dimensions
	xMin = 0;
	xMax = movieDims(2);
	yMin = 0;
	yMax = movieDims(1);

	% adjust for the difference in centroid location if movie is cropped
	% xDiff = 0;
	% yDiff = 0;
	if xLow<=xMin; xDiff = xLow-xMin; xLow = xMin+1; end
	if xHigh>=xMax; xDiff = xHigh-xMax; xHigh = xMax-1; end
	if yLow<=yMin; yDiff = yLow-yMin; yLow = yMin+1; end
	if yHigh>=yMax; yDiff = yHigh-yMax; yHigh = yMax-1; end

	outputImage = inputImages(yLow:yHigh,xLow:xHigh);
end