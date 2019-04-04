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
	options.medianFilterImages = 'none'
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
				'Frames per second?'...
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

	options

	for thisFileNumIdx = 1:nFilesToAnalyze
		[~,~] = openFigure(45+thisFileNumIdx, '');
	end
	% [figHandle figNo] = openFigure(969, '');

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
			[inputSignals inputImages signalPeaks signalPeakIdx valid] = modelGetSignalsImages(obj,'returnType','raw');
			if isempty(inputSignals);display('no input signals');continue;end
			% size(signalPeakIdx)
			% return

			try
				output1 = createObjMap(groupImagesByColor(inputImages,rand([size(inputImages,3) 1])+valid(:)'),'thresholdImages',0);
			catch
				output1 = createObjMap(groupImagesByColor(inputImages,rand([size(inputImages,3) 1])),'thresholdImages',0);
			end

			[~,~] = openFigure(45+thisFileNumIdx, '');
			subplot(2,2,1)
				imagesc(output1)
				axis equal tight;
			subplot(2,2,2)
				imagesc(nanmax(inputImages,[],3))
				axis equal tight;

			movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
			if ~isempty(movieList)
				movieDims = loadMovieList(movieList{1},'getMovieDims',1,'inputDatasetName',obj.inputDatasetName);
				if movieDims.three<nanmax(userVideoFrames)
					movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName);
				else
					movieFrameProc = loadMovieList(movieList{1},'convertToDouble',0,'frameList',userVideoFrames,'inputDatasetName',obj.inputDatasetName);
				end
			end
			subplot(2,2,3)
				imagesc(nanmax(movieFrameProc,[],3))
				axis equal tight;

			suptitle(obj.folderBaseDisplayStr{obj.fileNum})

			% createObjMap(groupImagesByColor(inputImages,rand([size(inputImages,3) 1])+nanmax(inputImages(:)),'thresholdImages',0))
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end