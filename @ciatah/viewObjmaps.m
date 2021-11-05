function obj = viewObjmaps(obj,varargin)
	% Creates cell maps and plots of high-SNR example signals.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2020.05.07 [14:54:27] - Fix to deal with empty valid folders.
		% 2021.06.18 [21:41:07] - added modelVarsFromFilesCheck() to check and load signals if user hasn't already.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Row and column size, don't change generally
	options.rowSubP = 2;
	options.colSubP = 4;

	% which table to read in
	options.onlyShowMapTraceGraph = 0;
	options.mapTraceGraphNo = 43;
	options.figList = [2000 5000 4000 45];

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

	[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = obj.getAnalysisSubsetsToAnalyze();

	subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.05, 'Padding', 0.01, 'MarginTop', 0.05,'MarginBottom', 0.1,'MarginLeft', 0.03,'MarginRight', 0.02);

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
				'Frames per second?'...
			},...
			'view movie settings',1,...
			{...
				obj.picsSavePath,...
				obj.fileFilterRegexp,...
				'1:500',...
				'0.4',...
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
				num2str(obj.FRAMES_PER_SECOND)...
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

	disp(options)
	for figNo1 = options.figList
		for thisFileNumIdx = 1:nFilesToAnalyze
			[~,~] = openFigure(figNo1+thisFileNumIdx, '');
		end
	end
	% [figHandle figNo] = openFigure(969, '');

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			[~,foldername,~] = fileparts(obj.inputFolders{obj.fileNum});
			validType = 'NULL';
			linkAx = [];

			% Check that signal extraction information is loaded.
			obj.modelVarsFromFilesCheck(thisFileNum);

			% =====================
			% for backwards compatibility, will be removed in the future.
			nIDs = length(obj.stimulusNameArray);
			%
			nameArray = obj.stimulusNameArray;
			idArray = obj.stimulusIdArray;
			[~,~] = openFigure(options.figList(4)+thisFileNumIdx, '');
			%
			% [inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');
			[inputSignals, inputImages, signalPeaks, signalPeakIdx, valid, validType, inputSignals2] = modelGetSignalsImages(obj,'returnType','raw');
			% inputSignals = inputSignals2;
			if isempty(inputSignals)
				disp('no input signals');
				try
					suptitle([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.folderBaseDisplayStr{obj.fileNum} ' | ' strrep(foldername,'_','\_') ' | ' validType ' | ' obj.signalExtractionMethod,])
				catch
				end
				continue;
			end
			if sum(valid==1)==0
				disp('Switching to random labels since no cells')
				if isempty(valid)
					valid = rand([1 size(inputSignals,1)])>0.5;
				else
					valid = rand(size(valid))>0.5;
				end
				validType = 'random';
			end
			% size(signalPeakIdx)
			% return

			[thresholdedImages, ~] = thresholdImages(inputImages,'binary',1,'getBoundaryIndex',0,'threshold',userThreshold,'imageFilter','none');

			rowSubP = options.rowSubP;
			colSubP = options.colSubP;

			try
				groupingVector = zeros([size(inputImages,3) 1]);
				groupingVector(valid==1) = sum(valid==0)+randperm(sum(valid==1));
				% groupingVector(valid==0) = 1:sum(valid==0);
				tmpVec = 1:sum(valid==0);
				groupingVector(valid==0) = tmpVec(randperm(length(tmpVec)));
				output1 = createObjMap(groupImagesByColor(thresholdedImages,groupingVector,'thresholdImages',0));
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
				output1 = createObjMap(groupImagesByColor(thresholdedImages,rand([size(inputImages,3) 1]),'thresholdImages',0));
			end

			linkAx(end+1) = subplotTmp(rowSubP,colSubP,1);
				imagesc(output1)
				% colormap(gca,[gray(sum(valid==0));customColormap([],'nPoints',round(sum(valid==1)/2))])
				% colormap(gca,[gray(sum(valid==0));jet(sum(valid==1))])
				grayColors = gray(sum(valid==0)*2);
				colormap(gca,[0 0 0;grayColors((sum(valid==0)+1):end,:)/2;parula(sum(valid==1))])
				axis equal tight; box off;
				title('Cellmap | colored = cells | gray = non-cells')

			linkAx(end+1) = subplotTmp(rowSubP,colSubP,2);
				imagesc(imadjust(nanmax(inputImages,[],3)))
				% imagesc(nanmax(inputImages,[],3))
				colormap(gca,'parula')
				% colormap(gca,[0 0 0;parula(250)])
				% s2Pos = get(gca,'position');
				% cbh = colorbar(gca,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]);
				% ylabel(cbh,'Raw extraction image value','FontSize',15);
				axis equal tight; box off;
				title('Cellmap | All extraction outputs')

			% Threshold
			% subplotTmp(rowSubP,colSubP,3)
				% inputImagesThres = inputImages(:,:,logical(valid));
				% boundaryIndices = boundaryIndices(logical(valid));
				[thresholdedImages, boundaryIndices] = thresholdImages(inputImages(:,:,logical(valid)),'binary',1,'getBoundaryIndex',1,'threshold',userThreshold,'imageFilter','median');
				cellmapHere = zeros(size(output1));
				% cellmapHere([boundaryIndices{:}]) = 1;
				% imagesc(cellmapHere)
				% axis equal tight;
				rMap = cellmapHere;
				gMap = cellmapHere;
				bMap = cellmapHere;
				nCells = size(thresholdedImages,3);
				% nCells = sum(valid);
				for cellNo = 1:nCells
					rMap([boundaryIndices{cellNo}]) = rand(1);
					gMap([boundaryIndices{cellNo}]) = rand(1);
					bMap([boundaryIndices{cellNo}]) = rand(1);
				end

				rMap = imdilate(rMap,strel('disk',options.dilateOutlinesFactor));
				gMap = imdilate(gMap,strel('disk',options.dilateOutlinesFactor));
				bMap = imdilate(bMap,strel('disk',options.dilateOutlinesFactor));

				% rgbImg = cat(3,rMap,gMap,bMap);
				% imagesc(rgbImg)
				% axis equal tight; box off;
				% title('Cellmap | Outlines')

			subfxnDisplayMovie();

			subplotTmp(rowSubP,colSubP,[3 4 7 8])
				if isempty(nSignalsShow)
					plotSignalsGraph(inputSignals(logical(valid),:),'newAxisColorOrder','default');
				else
					inputSignalsTmp = inputSignals(logical(valid),:);
					if size(inputSignalsTmp,1)>nSignalsShow
						plotSignalsGraph(inputSignalsTmp(1:nSignalsShow,:),'newAxisColorOrder','default');
					else
						plotSignalsGraph(inputSignalsTmp(:,:),'newAxisColorOrder','default');
					end
				end
				axis tight
				zoom on
				title('Cell activity traces | zoom on')
				xlabel('Frames');
				ylabel('Fluorescence')

			axHandle = subplotTmp(rowSubP,colSubP,2);
			linkAx(end+1) = axHandle;
				imagesc(nanmax(inputImages,[],3))
				axis equal tight; box off;
				title('Cellmap | All extraction outputs')

			% suptitle([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.folderBaseDisplayStr{obj.fileNum} ' | ' strrep(foldername,'_','\_') ' | ' validType])

			titleStr = sprintf('%d/%d: %s | %s | %s\n %s | %d cells, %d total | Zoom enabled',thisFileNumIdx,nFilesToAnalyze,obj.folderBaseDisplayStr{obj.fileNum},strrep(foldername,'_','\_'),validType,obj.signalExtractionMethod,sum(valid==1),length(valid));
			ciapkg.overloaded.suptitle(titleStr)

				% s2Pos = get(gca,'position');
				s2Pos = plotboxpos(gca);
				cbh = colorbar(gca,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]);
				% ylabel(cbh,'Raw extraction image value','FontSize',15);
				% colorbar(inputMoviePlotLoc2Handle,'off')

			set(gcf,'SizeChangedFcn',{@resizeui,axHandle});

			linkaxes(linkAx);

			% =======
			plotSets = [options.figList(1) options.figList(2)];
			% Plot cellmaps with all cells individually numbered
			for plotSetNo = plotSets
				[~,~] = openFigure(plotSetNo+thisFileNumIdx, '');
					clf
					% createObjMap(groupImagesByColor(inputImages,rand([size(inputImages,3) 1])+nanmax(inputImages(:)),'thresholdImages',0))
					cellCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod);
					if plotSetNo==options.figList(1)
						cellCoords = cellCoords(valid,:);
						inputImagesTmp = inputImages(:,:,logical(valid));
					else
						cellCoords = cellCoords(:,:);
						inputImagesTmp = inputImages(:,:,:);
					end
					% cellCoords = cellCoords(validRegion,:);

					try
						output1 = createObjMap(groupImagesByColor(inputImagesTmp,rand([size(inputImagesTmp,3) 1]),'thresholdImages',1));
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
						output1 = createObjMap(groupImagesByColor(inputImages(:,:,logical(valid)),rand([size(inputImages,3) 1]),'thresholdImages',1));
					end
					% imagesc(max(inputImages(:,:,logical(valid)),[],3))
					imagesc(output1)
					% colormap([0 0 0;customColormap([])])
					zoom on
					colormap([0 0 0;customColormap({[1 0 0],[0 0 1]})])
					axis equal tight
					hold on
					colorbar

					for signalNo = 1:size(inputImagesTmp,3)
						coordX = cellCoords(signalNo,1);
						coordY = cellCoords(signalNo,2);
						% plot(coordX,coordY,'w.','MarkerSize',5)
						text(coordX,coordY,num2str(signalNo),'Color',[1 1 1],'HorizontalAlignment','center')

					end
					% imgRowY = size(inputImagesTmp,1);
					% imgColX = size(inputImagesTmp,2);
					% scaleBarLengthPx = options.scaleBarLengthMicron/obj.MICRON_PER_PIXEL;
					% [imgColX-scaleBarLengthPx-round(imgColX*0.05) imgRowY-round(imgRowY*0.05) scaleBarLengthPx 5]
					% rectangle('Position',[imgColX-scaleBarLengthPx-imgColX*0.05 imgRowY-imgRowY*0.05 scaleBarLengthPx 5],'FaceColor',[1 1 1],'EdgeColor','none')
					% annotation('line',[imgRow-50 imgRow-30]/imgRow,[20 20]/imgCol,'LineWidth',3,'Color',[1 1 1]);

					suptitle([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.folderBaseDisplayStr{obj.fileNum} ' | ' strrep(foldername,'_','\_') ' | ' validType 10  'Zoom enabled.'])

					titleStr = sprintf('%d/%d: %s | %s | %s\n %s | %d cells, %d total | Zoom enabled',thisFileNumIdx,nFilesToAnalyze,obj.folderBaseDisplayStr{obj.fileNum},strrep(foldername,'_','\_'),validType,obj.signalExtractionMethod,sum(valid==1),length(valid));
					ciapkg.overloaded.suptitle(titleStr)
			end

			% =======
			% Plot cellmaps in a binary fashion to look at overlapping cells
			[~,~] = openFigure(options.figList(3)+thisFileNumIdx, '');
				[thresholdedImages,~] = thresholdImages(inputImages,'binary',1,'getBoundaryIndex',0,'threshold',userThreshold,'imageFilter','none');
				thisCellmap = sum(thresholdedImages,3);
				imagesc(thisCellmap)
				axis equal tight
				zoom on
				colormap([0 0 0;customColormap([])])
				cbh = colorbar;
				ylabel(cbh,'# cells at that pixel location','FontSize',10);
				titleStr = sprintf('Cell overlap | %d/%d: %s | %s | %s\n %s | %d cells, %d total | Zoom enabled',thisFileNumIdx,nFilesToAnalyze,obj.folderBaseDisplayStr{obj.fileNum},strrep(foldername,'_','\_'),validType,obj.signalExtractionMethod,sum(valid==1),length(valid));
				ciapkg.overloaded.suptitle(titleStr)

		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
			try
				[~,~] = openFigure(options.figList(4)+thisFileNumIdx, '');
				subfxnDisplayMovie()
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
			try
				for iii = [options.figList(4) options.figList(1)]
					[~,~] = openFigure(iii+thisFileNumIdx, '');
					suptitle([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.folderBaseDisplayStr{obj.fileNum} ' | ' strrep(foldername,'_','\_') ' | ' validType ' | ' obj.signalExtractionMethod,])
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end
	function subfxnDisplayMovie()
		movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
		if ~isempty(movieList)
			movieDims = loadMovieList(movieList{1},'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
			if movieDims.three<nanmax(userVideoFrames)
				movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName);
			else
				movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',userVideoFrames,'inputDatasetName',obj.inputDatasetName);
			end
			movieFrameProc = cast(movieFrameProc,class(rMap));

			linkAx(end+1) = subplotTmp(rowSubP,colSubP,colSubP+1);
				imagesc(nanmax(movieFrameProc,[],3))
				axis equal tight; box off;
				% colormap([0 0 0;obj.colormap])
				colormap(gca,'gray')
				title('Movie | raw, no pre-processing')

			movieFrameProcNorm = normalizeVector(nanmax(movieFrameProc,[],3),'normRange','zeroToOne');
			rgbImgCopy = cat(3,rMap,gMap,bMap);
			movieFrameProcNorm(max(rgbImgCopy,[],3)>0) = 0;
			rMap = movieFrameProcNorm+rMap;
			gMap = movieFrameProcNorm+gMap;
			bMap = movieFrameProcNorm+bMap;

			% nCells = size(inputImagesThres,3);
			% for cellNo = 1:nCells
			% 	rMap([boundaryIndices{cellNo}]) = rand(1);
			% 	gMap([boundaryIndices{cellNo}]) = rand(1);
			% 	bMap([boundaryIndices{cellNo}]) = rand(1);
			% end

			rgbImg = cat(3,rMap,gMap,bMap);

			linkAx(end+1) = subplotTmp(rowSubP,colSubP,colSubP+2);
				imagesc(rgbImg)
				axis equal tight; box off;
				title('Movie | raw, no pre-processing with cellmap')

		end
	end
end
function resizeui(hObject,event,axHandle)
	% inputMoviePlotLoc2Handle = subplotTmp(rowSubP,colSubP,2)
	% disp('Check')
	colorbar(axHandle,'off')
	% s2Pos = get(axHandle,'position');
	warning off
	s2Pos = plotboxpos(axHandle);
	warning on
	% s2Pos
	% [s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]
	cbh = colorbar(axHandle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]);
	% ylabel(cbh,'Raw extraction image value','FontSize',15);
end