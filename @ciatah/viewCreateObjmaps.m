function obj = viewCreateObjmaps(obj,varargin)
	% Creates cell maps and plots of high-SNR example signals.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2019.12.19 [21:18:12] - Allow user to brighten processed overlay movie.
	% TODO
		%

	%========================
	% which table to read in
	options.onlyShowMapTraceGraph = 0;
	options.mapTraceGraphNo = 43;

	% specify cut point
	options.signalCutIdx = [];

	% specify where to add lines
	options.signalCutXline = [];

	options.movAvgFiltSize = 3;
	% number of frames to calculate median filter
	options.medianFilterLength = 201;
	% for the signals plot, how much to increment
	options.incrementAmount = 0.1;
	% whether to filter shown traces
	options.filterShownTraces = 0;
	% length in microns of scale bars to place on figures, assumes obj.MICRON_PER_PIXEL is correct
	options.scaleBarLengthMicron = 50;
	% whether to show cell outlines
	options.cellOutlines = 1;

	options.dilateOutlinesFactor = 0;
	% none or median
	options.medianFilterImages = 'none';
	% red, blue, gree
	options.plotSignalsGraphColor = 'red';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.05, 'Padding', 0, 'MarginTop', 0.05,'MarginBottom', 0.1,'MarginLeft', 0.07,'MarginRight', 0.03);

	if obj.guiEnabled==1
		movieSettings = inputdlg({...
				'directory to save pictures: ',...
				'video file filter',...
				'video frames',...
				'image threshold (0-1)',...
				'number signals to show?',...
				'signal cut length (frames or frameStart:frameEnd)',...
				'filter traces? (1 = yes, 0 = no)',...
				'Scale bar length (microns)',...
				'Cell outlines? (1 = yes, 0 = no)',...
				'Only show cellmap/trace graph? (1 = yes, 0 = no)',...
				'Micron per pixel for scale bar',...
				'Dilate outlines factor (integer)',...
				'Filter images (none, median)',...
				'Activity traces color (red, green, blue)?',...
				'Frames per second?',...
				'Processed movie multiplier (integer)?'...
			},...
			'view movie settings',1,...
			{...
				obj.picsSavePath,...
				obj.fileFilterRegexp,...
				'1:500',...
				'0.5',...
				'15',...
				'930',...
				'0',...
				num2str(options.scaleBarLengthMicron),...
				num2str(options.cellOutlines),...
				num2str(options.onlyShowMapTraceGraph),...
				num2str(obj.MICRON_PER_PIXEL),...
				num2str(options.dilateOutlinesFactor),...
				'none',...
				options.plotSignalsGraphColor,...
				num2str(obj.FRAMES_PER_SECOND),...
				'3'...
			}...
		);
		obj.picsSavePath = movieSettings{1};
		obj.fileFilterRegexp = movieSettings{2};
		userVideoFrames = str2num(movieSettings{3});
		userThreshold = str2num(movieSettings{4});
		nSignalsShow = str2num(movieSettings{5});
		cutLength = str2num(movieSettings{6});
		options.filterShownTraces = str2num(movieSettings{7});
		options.scaleBarLengthMicron = str2num(movieSettings{8});
		options.cellOutlines = str2num(movieSettings{9});
		options.onlyShowMapTraceGraph = str2num(movieSettings{10});
		obj.MICRON_PER_PIXEL = str2num(movieSettings{11});
		options.dilateOutlinesFactor = str2num(movieSettings{12});
		options.medianFilterImages = movieSettings{13};
		options.plotSignalsGraphColor = movieSettings{14};
		obj.FRAMES_PER_SECOND = str2num(movieSettings{15});
		processedMultiplier = str2num(movieSettings{16});
		if length(cutLength)==1
		else
			options.signalCutIdx = cutLength;
			cutLength = length(cutLength);
		end
	else
		% obj.picsSavePath
		% obj.fileFilterRegexp
		userThreshold = 0.5;
		userVideoFrames = 1:500;
		nSignalsShow = 10;
		cutLength = 930;
		options.filterShownTraces = 0;
	end

	options

	[figHandle figNo] = openFigure(959, '');
	[figHandle figNo] = openFigure(969, '');
	[figHandle figNo] = openFigure(970, '');
	[figHandle figNo] = openFigure(971, '');
	[figHandle figNo] = openFigure(972, '');
	[figHandle figNo] = openFigure(85, '');
	[figHandle figNo] = openFigure(123456, '');
	[figHandle figNo] = openFigure(7989, '');
	[figHandle figNo] = openFigure(48484848, '');
	[figHandle figNo] = openFigure(43, '');

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			nIDs = length(obj.stimulusNameArray);
			%
			nameArray = obj.stimulusNameArray;
			idArray = obj.stimulusIdArray;
			%
			% [inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');
			[inputSignals inputImages signalPeaks signalPeakIdx valid] = modelGetSignalsImages(obj,'returnType','filtered');
			if isempty(inputSignals);display('no input signals');continue;end
			% size(signalPeakIdx)
			% return
			% [inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj);
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(inputSignals,1);
			nFrames = size(inputSignals,2);
			%
			options.dfofAnalysis = obj.dfofAnalysis;
			timeSeq = obj.timeSequence;
			% subject = obj.subjectNum{obj.fileNum};
			subject = obj.subjectStr{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			%
			framesPerSecond = obj.FRAMES_PER_SECOND;
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			%
			figNoAll = obj.figNoAll;
			figNo = obj.figNo;
			figNames = obj.figNames;
			% magic numbers!
			% amount of time to make object maps before/after a stimulus
			prepostTime = 20;
			MICRON_PER_PIXEL = obj.MICRON_PER_PIXEL;
			%
			picsSavePath = [obj.picsSavePath filesep 'cellmaps' filesep];
			fileFilterRegexp = obj.fileFilterRegexp;
			% =====================

			% thisFileID = obj.fileIDNameArray{obj.fileNum};
			thisFileID = obj.fileIDArray{obj.fileNum};



			try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;check.manual=1; catch check.manual=0; end
			try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).regionMod;check.regionMod=1; catch check.regionMod=0; end
			if check.manual==1
				[figHandle figNo] = openFigure(123456, '');
				validManual = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;
				nCellsToShow = 3;
				nCellsToGrab = 40;
				% filter, trace, movie triggered
				nCols = 6;
				peakROI = [-20:20];
				[inputSignals2 inputImages2 signalPeaks2 signalPeakIdx2] = modelGetSignalsImages(obj,'returnType','raw');
				[peakOutputStat] = computePeakStatistics(inputSignals2,'waitbarOn',1,'testpeaks',signalPeaks2,'testpeaksArray',signalPeakIdx2,'spikeROI',peakROI);
				% inputImagesThresholded = thresholdImages(inputImages2,'binary',0,'threshold',userThreshold,'imageFilter','median');

				while 0
					clf
					subplotNum = 1;
					goodBadIndicator = [1 0];
					for gbIdx2 = 1:2
						gbIdx = goodBadIndicator(gbIdx2)
						if gbIdx2==1
							dispIdx = find(validManual==gbIdx,nCellsToGrab);
							dispIdx = [33 36 8];
						else
							dispIdx = find(validManual==gbIdx,nCellsToGrab,'last');
						end
						% dispIdx = find(validManual==gbIdx);
						dispIdx = dispIdx(randperm(length(dispIdx)));
						dispIdx = dispIdx(1:nCellsToShow);
						for signalIdx2 = 1:length(dispIdx)
							try
							signalIdx = dispIdx(signalIdx2);
							framesToGrab = signalPeakIdx2{signalIdx};
							movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
							inputMovie = loadMovieList(movieList{1},'convertToDouble',0,'frameList',framesToGrab,'inputDatasetName',obj.inputDatasetName);
							meanMovieImage = compareSignalToMovie(inputMovie, inputImages2(:,:,signalIdx), inputSignals2(signalIdx,:),'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',0,'outlines',0,'signalPeakArray',{[1:length(signalPeakIdx2(signalIdx))]},'cropSize',15,'getOnlyMeanImage',1);
							spikeCenterTrace = peakOutputStat.spikeCenterTrace{signalIdx};
							avgSpikeTrace = peakOutputStat.avgSpikeTrace(signalIdx,:);

							[thresholdedImages boundaryIndices] = thresholdImages(meanMovieImage(:,:,1),'binary',1,'getBoundaryIndex',1,'threshold',0.2,'imageFilter','median');
							meanMovieImage2 = meanMovieImage(:,:,2);
							meanMovieImage2([boundaryIndices{:}]) = NaN;

							% plot the image
							subplot(nCellsToShow,nCols,subplotNum);subplotNum=subplotNum+1;
								imagesc(meanMovieImage(:,:,1))
								axis off;
								title(num2str(signalIdx))
								colormap gray
							% plot the mean movie image
							subplot(nCellsToShow,nCols,subplotNum);subplotNum=subplotNum+1;
								imagesc(meanMovieImage2)
								caxis([0 0.05])
								axis off;
							% plot the average trace
							subplot(nCellsToShow,nCols,subplotNum);subplotNum=subplotNum+1;
							plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
								hold on;
								plot(peakROI, avgSpikeTrace,'k', 'LineWidth',3);box off;
								% add in zero line
								line([0 0],get(gca,'YLim'),'Color',[0 0 0],'LineWidth',2)
								ylim([-0.05 0.2])
							catch
							end
						end
					end
					pause
				end
			end
			drawnow

			normalFigs = 1;
			if normalFigs==1
				[figHandle figNo] = openFigure(options.mapTraceGraphNo, '');
				clf;
				try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;check.manual=1; catch check.manual=0; end
				try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).regionMod;check.regionMod=1; catch check.regionMod=0; end
				if check.manual==1
					% display(['using valid.' obj.signalExtractionMethod '.manual identifications...']);
					validManual = logical(obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual);
					if check.regionMod==1
						validRegion = logical(obj.valid{obj.fileNum}.(obj.signalExtractionMethod).regionMod);
					else
						validRegion = validManual;
					end
				else
					validManual = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto;
					validRegion = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto;
				end

				[inputSignalsTmp inputImagesTmp signalPeaksTmp signalPeakIdxTmp] = modelGetSignalsImages(obj,'returnType','raw','filterTraces',0);

				validRegion = validRegion(validManual);
				inputSignalsTmp = inputSignalsTmp(validManual,:);
				inputImagesTmp = inputImagesTmp(:,:,validManual);
				signalPeaksTmp = signalPeaksTmp(validManual,:);
				signalPeakIdxTmp = signalPeakIdxTmp(validManual);
				% get raw background movie
				movieList = getFileList(obj.inputFolders{obj.fileNum}, 'concat');
				if isempty(movieList)
					movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				end
				movieList
				if ~isempty(movieList)
					movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:100,'inputDatasetName',obj.inputDatasetName);
					[movieFrame] = downsampleMovie(movieFrame,'downsampleX',size(inputImages,1),'downsampleY',size(inputImages,2),'downsampleDimension','space');
					movieFrame = squeeze(max(movieFrame,[],3));

					% [inputImagesThresholded boundaryIndices] = thresholdImages(inputImagesTmp,'binary',0,'threshold',userThreshold,'imageFilter','median','getBoundaryIndex',1,'imageFilterBinary','median');
					[inputImagesThresholded boundaryIndices] = thresholdImages(inputImagesTmp,'binary',0,'threshold',userThreshold,'imageFilter',options.medianFilterImages,'getBoundaryIndex',1,'imageFilterBinary',options.medianFilterImages);
					% cells but not in FOV ROI
					colorObjMaps{1} = createObjMap(inputImagesThresholded(:,:,validRegion==0));
					% cells in FOV ROI
					iiTTmp = inputImagesThresholded(:,:,validRegion==1);
					colorObjMaps{2} = createObjMap(groupImagesByColor(iiTTmp,rand([size(iiTTmp,3) 1])+nanmax(iiTTmp(:)),'thresholdImages',0));
					colorObjMaps{3} = createObjMap(groupImagesByColor(iiTTmp,rand([size(iiTTmp,3) 1])+nanmax(iiTTmp(:)),'thresholdImages',0));

					colorObjMaps{2} = normalizeVector(double(colorObjMaps{2}),'normRange','zeroToOne');
					colorObjMaps{3} = normalizeVector(double(colorObjMaps{3}),'normRange','zeroToOne');

					% [thresholdedImages boundaryIndices] = thresholdImages(inputImages(:,:,validRegion==1),'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter','median');
					if options.cellOutlines==1
						nullImage = zeros([size(colorObjMaps{2})]);
						nullImage([boundaryIndices{:}]) = 1;
						nullImage = imdilate(nullImage,strel('disk',options.dilateOutlinesFactor));
						newIdx = find(nullImage);
						colorObjMaps{2}([newIdx(:)]) = 0.5;
						colorObjMaps{3}([newIdx(:)]) = 0.5;
						% colorObjMaps{2}([boundaryIndices{:}]) = 0.5;
						% colorObjMaps{3}([boundaryIndices{:}]) = 0.5;
					end

					% add concatenated movie
					movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
					movieDims = loadMovieList(movieList{1},'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
					if movieDims.three<nanmax(userVideoFrames)
						movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName);
					else
						movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',userVideoFrames,'inputDatasetName',obj.inputDatasetName);
					end
					[movieFrameProc] = downsampleMovie(movieFrameProc,'downsampleX',size(inputImages,1),'downsampleY',size(inputImages,2),'downsampleDimension','space');
					movieFrameProc = squeeze(max(movieFrameProc,[],3));
					movieFrameProc = normalizeVector(double(movieFrameProc),'normRange','zeroToOne')/2;
					tmpColormap = zeros([size(movieFrameProc)],class(movieFrameProc));
					if options.cellOutlines==1
						nullImage = zeros([size(tmpColormap)]);
						nullImage([boundaryIndices{:}]) = 1;
						nullImage = imdilate(nullImage,strel('disk',options.dilateOutlinesFactor));
						newIdx = find(nullImage);
						tmpColormap([newIdx(:)]) = 0.5;
					end
					clear Comb2
					Comb2(:,:,1) = processedMultiplier*movieFrameProc; % red
					Comb2(:,:,2) = processedMultiplier*movieFrameProc+tmpColormap; % green
					Comb2(:,:,3) = processedMultiplier*movieFrameProc; % blue

					E = normalizeVector(double(movieFrame),'normRange','zeroToOne');
					% E = E*0;
					% E = E';
					E = E*0.7;
					display(['E: ' num2str(size(E))])
					clear Comb;
					if isempty(colorObjMaps{1})
						Comb(:,:,1) = E;
					else
						% [thresholdedImages boundaryIndices] = thresholdImages(inputImages(:,:,validRegion==0),'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter','median','imageFilterBinary','median');
						[thresholdedImages boundaryIndices] = thresholdImages(inputImages(:,:,validRegion==0),'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter',options.medianFilterImages,'imageFilterBinary',options.medianFilterImages);
						colorObjMaps{1}([boundaryIndices{:}]) = 0.5;
						colorObjMaps{1} = normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne');
						Comb(:,:,1) = E+colorObjMaps{1}; % red
					end
					Comb(:,:,2) = E+0.8*colorObjMaps{2}; % green
					Comb(:,:,3) = E+0.8*colorObjMaps{3}; % blue
					linkImgAxes = [];
					linkImgAxes(end+1) = subplotTmp(2,3,2)
						imagesc(Comb2)
						hold on;
						box off
						title('Cellmap overlay processed movie')
						axis equal tight
					linkImgAxes(end+1) = subplotTmp(2,3,1)
						imagesc(Comb)
						hold on;
						box off
						title('Cellmap overlay raw movie')
						axis equal tight;

					cellCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod);
					cellCoords = cellCoords(validManual,:);

					%
					inputSignalsTmp = inputSignalsTmp(validRegion,:);
					inputImagesTmp = inputImagesTmp(:,:,validRegion);
					signalPeaksTmp = signalPeaksTmp(validRegion,:);
					signalPeakIdxTmp = signalPeakIdxTmp(validRegion);
					cellCoords = cellCoords(validRegion,:);

					% look at
					sortedinputSignals = signalPeaksTmp.*inputSignalsTmp;
					if isempty(options.signalCutIdx)
						% [signalSnr sortedIdx] = sort(max(sortedinputSignals,[],2),'descend');

						[signalSnr a] = computeSignalSnr(inputSignalsTmp,'testpeaks',signalPeaksTmp,'testpeaksArray',signalPeakIdxTmp);
						signalSnr(isinf(signalSnr)) = 0;
						[signalSnr sortedIdx] = sort(signalSnr,'descend');
					else
						[signalSnr sortedIdx] = sort(max(sortedinputSignals(:,options.signalCutIdx),[],2),'descend');
					end

					% max(sortedinputSignals,[],2)
					% sortedIdx
					% pause
					sortedinputSignals = inputSignalsTmp(sortedIdx,:);

					% create overlap with new images
					inputImagesThresholdedTmp = inputImagesThresholded(:,:,sortedIdx);
					if nSignalsShow>size(inputImagesThresholdedTmp,3)
						nSignalsShow = size(inputImagesThresholdedTmp,3);
					end
					inputImagesThresholdedTmp = inputImagesThresholdedTmp(:,:,1:nSignalsShow);
					inputImagesTmp2 = inputImagesTmp(:,:,sortedIdx);
					inputImagesTmp2 = inputImagesTmp2(:,:,1:nSignalsShow);
					colorObjMaps{1} = createObjMap(inputImagesThresholdedTmp);
					colorObjMaps{1} = normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne');
					% [thresholdedImages boundaryIndices] = thresholdImages(inputImagesTmp2,'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter','median','imageFilterBinary','median');
					[thresholdedImages boundaryIndices] = thresholdImages(inputImagesTmp2,'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter',options.medianFilterImages,'imageFilterBinary',options.medianFilterImages);

					nullImage = zeros([size(colorObjMaps{1})]);
					nullImage([boundaryIndices{:}]) = 1;
					nullImage = imdilate(nullImage,strel('disk',options.dilateOutlinesFactor));
					newIdx = find(nullImage);
					colorObjMaps{1}([newIdx(:)]) = 0.5;
					% colorObjMaps{1}([boundaryIndices{:}]) = 0.5;
					% size(E+colorObjMaps{1})
					% size(Comb(:,:,1))

					Comb(:,:,1) = E+colorObjMaps{1}; % red
					Comb(:,:,2) = Comb(:,:,2)-colorObjMaps{1}; % green
					Comb(:,:,3) = Comb(:,:,3)-colorObjMaps{1}; % green
					subplotTmp(2,3,1)
						imagesc(Comb)
						hold on;
						box off
						title('Cellmap overlay raw movie')
						axis equal tight;

					% nSignalsShow = 10;

					inputSignalsTmp = inputSignalsTmp(sortedIdx,:);
					inputImagesTmp = inputImagesTmp(:,:,sortedIdx);
					signalPeaksTmp = signalPeaksTmp(sortedIdx,:);
					cellCoords = cellCoords(sortedIdx,:);

					for signalNo = 1:nSignalsShow
						coordX = cellCoords(signalNo,1);
						coordY = cellCoords(signalNo,2);
						plot(coordX,coordY,'w.','MarkerSize',5)
						text(coordX,coordY,num2str(signalNo),'Color',[1 1 1])

						imgRowY = size(inputImagesTmp,1);
						imgColX = size(inputImagesTmp,2);
						scaleBarLengthPx = options.scaleBarLengthMicron/MICRON_PER_PIXEL;
						% [imgColX-scaleBarLengthPx-round(imgColX*0.05) imgRowY-round(imgRowY*0.05) scaleBarLengthPx 5]
						rectangle('Position',[imgColX-scaleBarLengthPx-imgColX*0.05 imgRowY-imgRowY*0.05 scaleBarLengthPx 5],'FaceColor',[1 1 1],'EdgeColor','none')
						% annotation('line',[imgRow-50 imgRow-30]/imgRow,[20 20]/imgCol,'LineWidth',3,'Color',[1 1 1]);
					end

					% subplot(2,2,[2 4])
					subplotTmp(2,3,[4 5 6])
					% cutLength = 200;
					if cutLength*2>size(inputSignalsTmp,2);cutLength=floor(size(inputSignalsTmp,2)/2.2);end
					if nSignalsShow>size(signalPeaksTmp,1);nSignalsShow=size(signalPeaksTmp,1);end
					if ~isempty(options.signalCutIdx)
						sortedinputSignalsCut = zeros([nSignalsShow length(options.signalCutIdx)]);
					else
						sortedinputSignalsCut = zeros([nSignalsShow cutLength*2+1]);
					end
					% display(['sortedinputSignalsCut: ' num2str(size(sortedinputSignalsCut))])
					shiftVector = round(linspace(round(cutLength/10),round(cutLength*0.9),nSignalsShow));
					shiftVector = shiftVector(randperm(length(shiftVector)));
					for signalNo = 1:nSignalsShow
						spikeIdx = find(signalPeaksTmp(signalNo,:));
						spikeIdxValues = sortedinputSignals(signalNo,spikeIdx);
						[k tmpIdx] = max(spikeIdxValues);
						if isempty(tmpIdx)
							continue;
						end
						spikeIdx = spikeIdx(tmpIdx(1));
						spikeIdx = spikeIdx(:);
						spikeIdx = spikeIdx-(round(cutLength/2)-shiftVector(signalNo));
						% spikeIdx
						% cutLength
						nPoints = size(inputSignalsTmp,2);
						try
							if (spikeIdx-cutLength)<0
								beginDiff = abs(spikeIdx-cutLength);
								cutIdx = bsxfun(@plus,spikeIdx,-(cutLength-beginDiff-1):(cutLength+beginDiff+1));
								cutIdx = 1:(cutLength*2+1);
							elseif (spikeIdx+cutLength)>nPoints
								endDiff = abs(-spikeIdx);
								cutIdx = bsxfun(@plus,spikeIdx,-(cutLength+endDiff+1):(cutLength-endDiff-1));
								cutIdx = (nPoints-(cutLength*2)):nPoints;
							else
								cutIdx = bsxfun(@plus,spikeIdx,-cutLength:cutLength);
							end
						catch err
							display(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							display(repmat('@',1,7))
							cutIdx = [];
							cutIdx = -cutLength:cutLength;
						end
						if options.filterShownTraces==1
							inputSignal99 = sortedinputSignals(signalNo,:);
							inputSignalMedian=medfilt1(inputSignal99,options.medianFilterLength);
							inputSignal99 = inputSignal99 - inputSignalMedian;
							inputSignal99 = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal99);
							sortedinputSignals(signalNo,:) = inputSignal99;
						end
						if ~isempty(options.signalCutIdx)
							tmpSignal = squeeze(sortedinputSignals(signalNo,:))';
							% figure;plot(tmpSignal)
							% options.signalCutIdx(:)
							% size(tmpSignal)
							sortedinputSignalsCut(signalNo,:) = tmpSignal(options.signalCutIdx(:));
						else
							if ~isempty(cutIdx)
								tmpSignal = squeeze(sortedinputSignals(signalNo,:))';
								% Remove cutIdx that are out of bounds
								cutIdx(cutIdx>length(tmpSignal)) = [];
								cutIdx(cutIdx<1) = [];
								if options.filterShownTraces==1
									inputSignalMedian=medfilt1(tmpSignal,options.medianFilterLength);
									tmpSignal = tmpSignal - inputSignalMedian;
									tmpSignal = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,tmpSignal);
								end
								sortedinputSignalsCut(signalNo,:) = tmpSignal(cutIdx(:)');
							end
						end
					end
					display(['sortedinputSignalsCut: ' num2str(size(sortedinputSignalsCut))])
					plotTracesFigure();

					% rectangle('Position',[0 0 10 3],'FaceColor',[0 0 0],'EdgeColor','none')

					axis tight;
					if ~isempty(options.signalCutXline)

					end

					openFigure(48484848, '');

						plotTracesFigure();

						% rectangle('Position',[0 0 10 3],'FaceColor',[0 0 0],'EdgeColor','none')

						axis tight;
						if ~isempty(options.signalCutXline)

						end

					[figHandle figNo] = openFigure(options.mapTraceGraphNo, '');
				end
				inputImages2 = inputImages;
				[inputImages2 boundaryIndices] = thresholdImages(inputImages2,'binary',0,'getBoundaryIndex',0,'threshold',userThreshold);
				% [inputImages2 boundaryIndices] = thresholdImages(inputImages2,'binary',0,'getBoundaryIndex',0,'threshold',0.2,'imageFilter',options.medianFilterImages,'imageFilterBinary',options.medianFilterImages);

				for cellNo = 1:size(inputImages,3)
					inputImages2(:,:,cellNo) = normalizeVector(inputImages2(:,:,cellNo),'normRange','zeroToOne');
				end
				emImages2 = zeros([size(inputImages2,1) size(inputImages2,2) 3]);
				for iii=1:3
					emImages2(:,:,iii) = nanmax(groupImagesByColor(inputImages2,1*rand([size(inputImages2,3) 1]),'thresholdImages',0),[],3);
				end
				clear inputImages2

				linkImgAxes(end+1) = subplotTmp(2,3,3)
					imagesc(emImages2); axis equal tight; box off;
					title('colored cell map')
					suptitle(sprintf('%s | # cells = %d',obj.folderBaseDisplayStr{obj.fileNum},sum(validRegion)))
					drawnow

				linkaxes(linkImgAxes);

				[figHandle figNo] = openFigure(options.mapTraceGraphNo, '');
				set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 15 10])
				suptitle(sprintf('%s | # cells = %d',obj.folderBaseDisplayStr{obj.fileNum},sum(validRegion)))
				binOld = obj.binDownsampleAmount; obj.binDownsampleAmount = [];
				% obj.modelSaveImgToFile([],['objMapLabeled' filesep obj.subjectStr{obj.fileNum}],'current',[]);
				obj.modelSaveImgToFile([],'objMapLabeled','current',[]);
				obj.binDownsampleAmount = binOld;
				if options.onlyShowMapTraceGraph==1
					% return
					continue
				end
				% [figHandle figNo] = openFigure(85, '');
				% 	[inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');

				% 	[signalSnr a] = computeSignalSnr(inputSignals,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
				% 	[signalSnr sortedIdx] = sort(signalSnr,'descend');

				% 	inputImages2 = inputImages;
				% 	for cellNo = 1:size(inputImages,3)
				% 		inputImages2(:,:,cellNo) = normalizeVector(inputImages2(:,:,cellNo),'normRange','zeroToOne');
				% 	end
				% 	emImages2 = zeros([size(inputImages2,1) size(inputImages2,2) 3])
				% 	for i=1:3
				% 		randColorVector = 1*rand([size(inputImages2,3) 1]);
				% 		randColorVector = randColorVector.*matchAcross;
				% 		% randColorVector = randColorVector+0.05;
				% 		randColorVector(randColorVector==0) = 0.2;
				% 		% size(randColorVector)
				% 		% figure;plot(randColorVector)
				% 		emImages2(:,:,i) = nanmax(groupImagesByColor(inputImages2,randColorVector,'thresholdImages',0),[],3);
				% 	end

				% 	clear inputImages2
				% 	imagesc(emImages2);drawnow
				% 	axis off

				% 	markers = {'+','o','*','.','x','s','d','^','v','>','<','p','h'};

				% 	legend()

				% 	title([subject ' | ' assay ' | overlap map | ' num2str(size(signalPeaks,1)) ' cells'],'fontsize',20)
				% 	set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 9 9])
				% 	% figure(figHandle)
				% 	obj.modelSaveImgToFile([],'cellmapObjColor_','current',[]);

				[figHandle figNo] = openFigure(85, '');
					imagesc(emImages2);drawnow
					axis off
					title([subject ' | ' assay ' | overlap map | ' num2str(size(signalPeaks,1)) ' cells'],'fontsize',20)
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 9 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapObjColor_','current',[]);

				% [figHandle figNo] = openFigure(options.mapTraceGraphNo, '');
				% 	subplotTmp(2,3,3)
				% 	imagesc(emImages2); axis equal tight; box off;
				% 	title('colored cell map')
				% 	suptitle(sprintf('%s | # cells = %d',obj.folderBaseDisplayStr{obj.fileNum},sum(validRegion)))
				% 	drawnow

				% if options.onlyShowMapTraceGraph==1
				% 	return
				% end

					markers = {'+','o','*','.','x','s','d','^','v','>','<','p','h'}

				[figHandle figNo] = openFigure(7989, '');
					thres = thresholdImages(inputImages,'binary',1,'threshold',userThreshold);
					thisCellmap = createObjMap(thres,'mapType','sum');
					imagesc(thisCellmap);colorbar;
					% colormap(obj.colormap);
					colormap([0 0 0;jet(nanmax(thisCellmap(:)))])
					title([subject ' | ' assay ' | overlap map | ' num2str(size(signalPeaks,1)) ' cells'],'fontsize',20)
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 9 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapObjOverlap_','current',[]);
				[figHandle figNo] = openFigure(969, '');
					s1 = subplot(1,2,1);
						% coloredObjs = groupImagesByColor(thresholdImages(inputImages),[]);
						% thisCellmap = createObjMap(coloredObjs);
						% firing rate grouped images
						display(['signalPeaks: ' num2str(size(signalPeaks))])
						numPeakEvents = sum(signalPeaks,2);
						numPeakEvents = numPeakEvents/size(signalPeaks,2)*framesPerSecond;
						display(['inputImages: ' num2str(size(inputImages))])
						display(['numPeakEvents: ' num2str(size(numPeakEvents))])
						thres = thresholdImages(inputImages,'threshold',userThreshold);
						[groupedImagesRates] = groupImagesByColor(inputImages,numPeakEvents);
						thisCellmap = createObjMap(groupedImagesRates);

						% if fileNum==1
						%     fig1 = figure(32);
						%     % colormap gray;
						% end
						% thisCellmap = createObjMap([thisDirSaveStr options.rawICfiltersSaveStr]);
						% subplot(round(nFiles/4),4,fileNum);
						plotBinaryCellMapFigure();
						title([subject ' | ' assay ' | firing rate map | ' num2str(size(signalPeaks,1)) ' cells'],'fontsize',20)
						hold on;

					[signalSnr a] = computeSignalSnr(inputSignals,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
					signalSnr(isinf(signalSnr)) = 0;
				[figHandle figNo] = openFigure(972, '');
					clf
					subplot(2,3,1);
						plotBinaryCellMapFigure();
				[figHandle figNo] = openFigure(969, '');
					s2 = subplot(1,2,2);
						if nSignals>1
							[signalSnr sortedIdx] = sort(signalSnr,'descend');
							sortedinputSignals = signalPeaks.*inputSignals;
							% [signalSnr sortedIdx] = sort(sum(sortedinputSignals,2),'descend');
							[signalSnr sortedIdx] = sort(max(sortedinputSignals,[],2),'descend');
							sortedinputSignals = inputSignals(sortedIdx,:);
							display('==============')
							display(['signalPeakIdx: ' num2str(size(signalPeakIdx))])
							display(['sortedIdx: ' num2str(size(sortedIdx))])
							display('==============')
							signalPeakIdx = {signalPeakIdx{sortedIdx}};
							% cutLength = 600;
							if cutLength*2>size(inputSignals,2);cutLength=floor(size(inputSignals,2)/2.2);end
							% cutLength
							% nSignalsShow = 20;
							if nSignalsShow>length(signalPeakIdx);nSignalsShow=length(signalPeakIdx);end
							sortedinputSignalsCut = zeros([nSignalsShow cutLength*2+1]);
							% display(['sortedinputSignalsCut: ' num2str(size(sortedinputSignalsCut))])
							shiftVector = round(linspace(round(cutLength/10),round(cutLength*0.9),nSignalsShow));
							shiftVector = shiftVector(randperm(length(shiftVector)));
							for sIdx=1:nSignalsShow
								spikeIdx = signalPeakIdx{sIdx};
								spikeIdxValues = sortedinputSignals(sIdx,spikeIdx);
								[k tmpIdx] = max(spikeIdxValues);
								if isempty(tmpIdx)
									continue;
								end
								spikeIdx = spikeIdx(tmpIdx(1));
								spikeIdx = spikeIdx(:);
								spikeIdx = spikeIdx-(round(cutLength/2)-shiftVector(sIdx));
								% spikeIdx
								% cutLength
								nPoints = size(inputSignals,2);
								try
									if (spikeIdx-cutLength)<0
										beginDiff = abs(spikeIdx-cutLength);
										cutIdx = bsxfun(@plus,spikeIdx,-(cutLength-beginDiff-1):(cutLength+beginDiff+1));
										cutIdx = 1:(cutLength*2+1);
									elseif (spikeIdx+cutLength)>nPoints
										endDiff = abs(-spikeIdx);
										cutIdx = bsxfun(@plus,spikeIdx,-(cutLength+endDiff+1):(cutLength-endDiff-1));
										cutIdx = (nPoints-(cutLength*2)):nPoints;
									else
										cutIdx = bsxfun(@plus,spikeIdx,-cutLength:cutLength);
									end
								catch err
									display(repmat('@',1,7))
									disp(getReport(err,'extended','hyperlinks','on'));
									display(repmat('@',1,7))
									cutIdx = [];
									cutIdx = -cutLength:cutLength;
								end
								if ~isempty(cutIdx)
									sortedinputSignalsCut(sIdx,:) = sortedinputSignals(sIdx,cutIdx(:)');
								end
							end
							%size(sortedinputSignalsCut)
							%imagesc(sortedinputSignals)
							% sortedinputSignalsCut = sortedinputSignals(1:nSignalsShow,:);
							% sortedinputSignalsCut = flip(sortedinputSignalsCut,1);
							display(['sortedinputSignalsCut: ' num2str(size(sortedinputSignalsCut))])
							% sortedinputSignalsCut = sortedinputSignals(1:7,:);
							% sortedinputSignalsCut = inputSignals(1:7,:);
							plotTracesFigure();
						else
							plot(inputSignals);
							xlabel('frames','fontsize',20);ylabel('\Delta F/F','fontsize',20);
							box off;
							title('example traces','fontsize',20);
						end

					d=0.02; %distance between images
					set(s1,'position',[d 0.15 0.5-2*d 0.8])
					set(s2,'position',[0.5+d 0.15 0.5-2*d 0.8])
					saveFile = char(strrep(strcat(picsSavePath,'cellmap_',thisFileID,''),'/',''));
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapObj_','current',[]);
					% print('-dpng','-r200',saveFile)
					% print('-dmeta','-r200',saveFile)
					% saveas(gcf,saveFile);
					drawnow;

					[figHandle figNo] = openFigure(972, '');
						subplot(2,3,2);
							if nSignals>1
								plotTracesFigure();
							else
								plot(inputSignals);
								xlabel('frames','fontsize',20);ylabel('\Delta F/F','fontsize',20);
								box off;
								% title('example traces','fontsize',20);
							end

				[figHandle figNo] = openFigure(970, '');
					% timeVector = (1:size(sortedinputSignalsCut,2))/framesPerSecond;
					if nSignals>1
						plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5);
						nTicks = 10;
						set(gca,'XTick',round(linspace(1,size(sortedinputSignalsCut,2),nTicks)))
						labelVector = round(linspace(1,size(sortedinputSignalsCut,2)/framesPerSecond,nTicks));
						set(gca,'XTickLabel',labelVector);
						xlabel('seconds','fontsize',20);ylabel('\Delta F/F','fontsize',20);
						box off;
						% axis off;
						% title('example traces');
					else
						plot(inputSignals);
						xlabel('frames','fontsize',20);ylabel('\Delta F/F','fontsize',20);
						box off;
						title('example traces','fontsize',20);
					end
					title([subject ' | ' assay ' | example traces'],'fontsize',20)
					saveFile = char(strrep(strcat(picsSavePath,'traces_',thisFileID,''),'/',''));
					saveFile
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapTraces_','current',[]);
					% print('-dpng','-r200',saveFile)
					% print('-dmeta','-r200',saveFile)
					% saveas(gcf,saveFile);
					drawnow;
			end
			movieList = getFileList(obj.inputFolders{obj.fileNum}, 'concat');
			if isempty(movieList)
				movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			end
			if ~isempty(movieList)
				movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:100,'inputDatasetName',obj.inputDatasetName);
				[movieFrame] = downsampleMovie(movieFrame,'downsampleX',size(inputImages,1),'downsampleY',size(inputImages,2),'downsampleDimension','space');
				% movieFrame = squeeze(movieFrame(:,:,1));
				movieFrame = squeeze(max(movieFrame,[],3));
				% imagesc(imadjust(movieFrame));
				% imagesc(movieFrame);
				% imshow(movieFrame);
				% axis off; colormap gray;
				% title([subject ' | ' assay ' | blue>green>red percentile rank']);
				% hold on;
				% imcontrast
				% continue
				% inputImagesThresholded = thresholdImages(inputImages,'binary',0)/3;
				% inputImagesThresholded = inputImages;
				% icaQ = quantile(numPeakEvents,[0.3 0.6]);
				% colorObjMaps{1} = createObjMap(inputImagesThresholded(numPeakEvents<icaQ(1),:,:));
				% colorObjMaps{2} = createObjMap(inputImagesThresholded(numPeakEvents>icaQ(1)&numPeakEvents<icaQ(2),:,:));
				% colorObjMaps{3} = createObjMap(inputImagesThresholded(numPeakEvents>icaQ(2),:,:));

				[inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');
				nSawSignals = size(inputSignals,1);

				try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;check.manual=1; catch check.manual=0; end
				if check.manual==1
					display(['using valid.' obj.signalExtractionMethod '.manual identifications...']);
					validAuto = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;
				else
					validAuto = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto;
				end
				validAuto = logical(validAuto);
				% inputImages = inputImages(:,:,validAuto);
				% validAuto = logical(obj.validManual{obj.fileNum});
				display('==============')
				if isempty(obj.validRegionMod)
					% validRegionMod = ones(size(validAuto));
					validRegionMod = [];
				else
					validRegionMod = obj.validRegionMod{obj.fileNum};
					% validRegionMod = validRegionMod(logical(validAuto));
					% validRegionMod = validRegionMod(validAuto);
				end
				validRegionMod = logical(validRegionMod);
				% class(validAuto)
				% validRegionMod
				display(['validRegionMod: ' num2str(size(validRegionMod))])
				display(['validAuto: ' num2str(size(validAuto))])
				% inputImagesThresholded = thresholdImages(inputImages(validAuto,:,:),'binary',0)/3;
				inputImagesThresholded = thresholdImages(inputImages,'binary',0,'threshold',userThreshold)/3;
				% inputImagesThresholded = inputImagesThresholded(validAuto);
				display(['inputImagesThresholded: ' num2str(size(inputImagesThresholded))])
				if isempty(validRegionMod)
					colorObjMaps{1} = createObjMap(inputImagesThresholded(:,:,validAuto==0));
					colorObjMaps{2} = createObjMap(inputImagesThresholded(:,:,validAuto==1));
				else
					colorObjMaps{1} = createObjMap(inputImagesThresholded(:,:,validRegionMod==0));
					colorObjMaps{2} = createObjMap(inputImagesThresholded(:,:,validRegionMod==1));
				end
				display(['colorObjMaps{1}: ' num2str(size(colorObjMaps{1}))])
				display(['colorObjMaps{2}: ' num2str(size(colorObjMaps{2}))])
				E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
				% E = E';
				display(['E: ' num2str(size(E))])
				if isempty(colorObjMaps{1})
					Comb(:,:,1) = E;
				else
					Comb(:,:,1) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % red
				end
				Comb(:,:,2) = E+normalizeVector(double(colorObjMaps{2}),'normRange','zeroToOne')/4; % green
				Comb(:,:,3) = E; % blue
				% Comb(:,:,3) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % blue
				[figHandle figNo] = openFigure(971, '');
					imagesc(Comb)
					% clear Comb
					axis off; colormap gray;
					title([subject ' | ' assay ' | blue-green-red percentile rank | cells=' num2str(nSignals)]);

					[nanmax(movieFrame(:)) nanmin(movieFrame(:))]
					[nanmax(colorObjMaps{1}(:)) nanmin(colorObjMaps{1}(:))]

					% zeroMap = zeros(size(movieFrame));
					% oneMap = ones(size(movieFrame));
					% green = cat(3, zeroMap, oneMap, zeroMap);
					% blue = cat(3, zeroMap, zeroMap, oneMap);
					% red = cat(3, oneMap, zeroMap, zeroMap);
					% warning off
					% blueOverlay = imshow(blue);
					% greenOverlay = imshow(green);
					% redOverlay = imshow(red);
					% warning on
					% set(redOverlay, 'AlphaData', colorObjMaps{1});
					% set(greenOverlay, 'AlphaData', colorObjMaps{2});
					% set(blueOverlay, 'AlphaData', colorObjMaps{3});
					set(gca, 'LooseInset', get(gca,'TightInset'))
					hold off;
					saveFile = char(strrep(strcat(picsSavePath,'cellmap_overlay_',thisFileID,''),'/',''));
					saveFile
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapObjOverlay_','current',[]);
					% print('-dpng','-r200',saveFile)
					% print('-dmeta','-r200',saveFile)
					% saveas(gcf,saveFile);
					% pause

				[figHandle figNo] = openFigure(972, '');
					subplot(2,3,3);
						imagesc(movieFrame)
						title('raw movie')

				[figHandle figNo] = openFigure(972, '');
					subplot(2,3,4);
						imagesc(Comb)
						clear Comb
						axis off; colormap gray;
						title('detected cells in green')
						% title([subject ' | ' assay ' | blue-green-red percentile rank | cells=' num2str(nSignals)]);
						% num2str(size(signalPeaks,1))
				movieList2 = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				if ~isempty(movieList2)
					movieDims = loadMovieList(movieList2{1},'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
					if movieDims.z<max(userVideoFrames);nFramesMax=1:movieDims.z;else nFramesMax=userVideoFrames;end
					movieFrame = loadMovieList(movieList2{1},'convertToDouble',0,'frameList',nFramesMax,'inputDatasetName',obj.inputDatasetName);
					[movieFrame] = downsampleMovie(movieFrame,'downsampleX',size(inputImages,1),'downsampleY',size(inputImages,2),'downsampleDimension','space');
					movieFrame = squeeze(max(movieFrame,[],3));
					E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
					display(['E: ' num2str(size(E))])
					if isempty(colorObjMaps{1})
						Comb(:,:,1) = E;
					else
						Comb(:,:,1) = E;
						% Comb(:,:,1) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % red
					end
					Comb(:,:,2) = E+normalizeVector(double(colorObjMaps{2}),'normRange','zeroToOne')/4; % green
					Comb(:,:,3) = E; % blue

					[figHandle figNo] = openFigure(972, '');
						subplot(2,3,5);
							imagesc(movieFrame)
							title(sprintf('processed movie (%d:%d frames max)',min(userVideoFrames),max(userVideoFrames)))

					[figHandle figNo] = openFigure(972, '');
						subplot(2,3,6);
							imagesc(Comb)
							clear Comb
							axis off; colormap gray;
							title('detected cells in green')
							% title([subject ' | ' assay ' | blue-green-red percentile rank | cells=' num2str(nSignals)]);
							% num2str(size(signalPeaks,1))
				end

				suptitle([subject ' | ' assay ' | firing rate map | ' num2str(sum(validAuto)) ' (' num2str(nSawSignals) ') cells'])
				% titleAxes = axes('Position', [0, 0.95, 1, 0.05],'Visible','off');
				% axes(titleAxes)
				% cla(ax,'reset')
				% set(titleAxes, 'Color', 'None', 'XColor', 'White', 'YColor', 'White' );
				% set( gca, 'Color', 'None', 'XColor', 'White', 'YColor', 'White' );
				% text(0.5, 0, [subject ' | ' assay ' | firing rate map | ' num2str(sum(validAuto)) ' cells'], 'FontSize', 14', 'FontWeight', 'Bold', 'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom' );
				set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 22 16])
				obj.modelSaveImgToFile([],'objMapAll_','current',[]);

				% inputImagesThresholded = thresholdImages(inputImages,'binary',0);
				% saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded.h5'));
				% thisObjMap = createObjMap(inputImagesThresholded);
				% movieSaved = writeHDF5Data(thisObjMap,saveFile)
				% inputImagesThresholded = thresholdImages(inputImages,'binary',1);
				% saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded_binary.h5'));
				% thisObjMap = createObjMap(inputImagesThresholded);
				% movieSaved = writeHDF5Data(thisObjMap,saveFile)
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function plotBinaryCellMapFigure()
		imagesc(thisCellmap);
		colormap(obj.colormap);
		s2Pos = get(gca,'position');
		cb = colorbar('location','southoutside'); ylabel(cb, 'Hz');
		set(gca,'position',s2Pos);
		% colormap hot; colorbar;
		% title(regexp(thisDir,'m\d+', 'match'));
		box off;
		axis tight;
		axis off;
		set(gca, 'LooseInset', get(gca,'TightInset'))

	end
	function plotTracesFigure()
		% options
		if size(sortedinputSignalsCut,1)==1
			plot(sortedinputSignalsCut)
		else
	%     	if sum(strcmp(obj.signalExtractionMethod,{'EM','CNMF','CNMFE'}))>0
				% plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5,'incrementAmount',[],'newAxisColorOrder',options.plotSignalsGraphColor,'smoothTrace',0,'maxIncrementPercent',0.4,'minAdd',0);
	%     	else
	%     		% plot(sortedinputSignalsCut)
				% plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5,'incrementAmount',options.incrementAmount,'newAxisColorOrder',options.plotSignalsGraphColor);
	%     	end
		% figure;
		% imagesc(sortedinputSignalsCut);
		% pause
			plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5,'incrementAmount',[],'newAxisColorOrder',options.plotSignalsGraphColor,'smoothTrace',0,'maxIncrementPercent',0.4,'minAdd',0);
		end
		nTicks = 10;
		set(gca,'XTick',round(linspace(1,size(sortedinputSignalsCut,2),nTicks)))
		labelVector = round(linspace(1,size(sortedinputSignalsCut,2),nTicks)/framesPerSecond);
		set(gca,'XTickLabel',labelVector);
		xlabel('seconds','fontsize',20);ylabel('\Delta F/F','fontsize',20);
		box off;
		% title('example traces','fontsize',20);
	end
end