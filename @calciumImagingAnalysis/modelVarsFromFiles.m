function obj = modelVarsFromFiles(obj)
	% Loads signals and images from input folders into object
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		% ADD SUPPORT FOR EM ANALYSIS

	%========================
	% options.populationDistanceType = 'mahal';

	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	display(repmat('#',1,21))
	display('loading files...')

	for figNo = [98 1996 1997 95 99]
		openFigure(figNo, '');
	end
	drawnow;

	signalExtractionMethod = obj.signalExtractionMethod;
	% usrIdxChoiceStr = {'PCAICA','EM'};
	% [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
	% usrIdxChoiceList = {2,1};
	% signalExtractionMethod = usrIdxChoiceStr{sel};

	optFieldnames = fieldnames(obj.filterImageOptions);
	if obj.guiEnabled==1
		AddOpts.Resize='on';
		AddOpts.WindowStyle='normal';
		AddOpts.Interpreter='tex';

		% usrInput = inputdlg([...
		usrInput = inputdlgcol([...
			optFieldnames; {'numStdsForThresh'}; {'loadVarsToRam'}; {'reportMidpoint'}; {'NWB file regular expression (override default)'}],...
			'Automatic classification parameters',[1 35],...
			[cellfun(@num2str,struct2cell(obj.filterImageOptions),'UniformOutput',false); {'2.5'}; {num2str(obj.loadVarsToRam)}; {'0'}; {obj.nwbFileRegexp}],AddOpts,2);
		for fieldnameNo = 1:length(optFieldnames)
			obj.filterImageOptions.(optFieldnames{fieldnameNo}) = str2num(usrInput{fieldnameNo});
		end
		numStdsForThresh = str2num(usrInput{fieldnameNo+1});
		obj.loadVarsToRam = str2num(usrInput{fieldnameNo+2});
		reportMidpoint = str2num(usrInput{fieldnameNo+3});
		obj.nwbFileRegexp = usrInput{fieldnameNo+3};
	else
		% only update the threshold
		% numStdsForThresh = 3;
		numStdsForThresh = 2.3;
		reportMidpoint = 0;
	end

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			% display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
	% nFolders = length(obj.dataPath);
	% for fileNum = 1:nFolders
	% 	display(repmat('-',1,7))
	% 	try
			obj.rawSignals{fileNum} = [];
			obj.rawImages{fileNum} = [];
			obj.signalPeaks{fileNum} = [];
			obj.signalPeaksArray{fileNum} = [];
			obj.nSignals{fileNum} = [];
			obj.nFrames{fileNum} = [];
			obj.objLocations{fileNum} = [];
			obj.validManual{fileNum} = [];
			obj.validAuto{fileNum} = [];
			if strmatch('#',obj.dataPath{fileNum})
				% display([num2str(fileNum) '/' num2str(nFolders) ' | skipping: ' obj.dataPath{fileNum}]);
				% display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) ') | skipping: ' obj.fileIDNameArray{obj.fileNum}]);
				fprintf('%d/%d (%d/%d) | skipping: %s\n',thisFileNumIdx,nFilesToAnalyze,fileNum,nFiles,obj.fileIDNameArray{obj.fileNum});
				obj.rawSignals{fileNum} = [];
				obj.rawImages{fileNum} = [];
				continue;
			else
				% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.dataPath{fileNum}]);
				% obj.fileIDNameArray{obj.fileNum}
				% display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
				fprintf('%d/%d (%d/%d): %s\n',thisFileNumIdx,nFilesToAnalyze,fileNum,nFiles,obj.fileIDNameArray{obj.fileNum});
			end

			signalExtractionMethodOriginal = signalExtractionMethod;
			if obj.nwbLoadFiles==1
				signalExtractionMethod = 'NWB';
			end
			switch signalExtractionMethod
				case 'NWB'
					% Check whether to use override NWB regular expression, else use calciumImagingAnalysis defaults.
					if isempty(obj.nwbFileRegexp)
						filesToLoad = getFileList([obj.dataPath{fileNum} filesep obj.nwbFileFolder],obj.extractionMethodSaveStr.(obj.signalExtractionMethod));
					else
						filesToLoad = getFileList([obj.dataPath{fileNum} filesep obj.nwbFileFolder],obj.nwbFileRegexp);
					end

					if ~isempty(filesToLoad)
						nwbOpts.algorithm = obj.signalExtractionMethod;
						nwbOpts.groupImages = obj.nwbGroupImages;
						nwbOpts.groupSignalSeries = obj.nwbGroupSignalSeries;
						[signalImages,signalTraces,infoStruct] = loadNeurodataWithoutBorders(filesToLoad{1},'options',nwbOpts);
					else
						% No NWB, check for CIA file format being present in the folder.
						disp('No NWB files, checking for calciumImagingAnalysis files.')
						signalExtractionMethod = signalExtractionMethodOriginal;
					end
					rawFiles = 1;
				otherwise
			end

			switch signalExtractionMethod
				case 'PCAICA'
					% [signalTraces signalImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','sorted');

					regexPairs = {...
						% {'_ICfilters_sorted.mat','_ICtraces_sorted.mat'},...
						% {'holding.mat','holding.mat'},..
						{obj.rawPCAICAStructSaveStr,obj.sortedICdecisionsSaveStr,obj.classifierICdecisionsSaveStr,obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
						{obj.sortedICdecisionsSaveStr,obj.classifierICdecisionsSaveStr,obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
						{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
						{obj.sortedICfiltersSaveStr,obj.sortedICtracesSaveStr}...
						% {obj.rawEMStructSaveStr},...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					rawFiles = 0;
					filesToLoad = [];
					fileToLoadNo = 1;
					nRegExps = length(regexPairs);
					while isempty(filesToLoad)
						filesToLoad = getFileList(obj.dataPath{obj.fileNum},strrep(regexPairs{fileToLoadNo},'.mat',''));
						fileToLoadNo = fileToLoadNo+1;
						if fileToLoadNo>nRegExps
							break;
						end
					end
					if fileToLoadNo==2
						rawFiles = 1;
					end
					cellfun(@(x) fprintf('Found: %s\n',x),filesToLoad)
					if isempty(filesToLoad)
					% if(~exist(filesToLoad{1}, 'file'))
						display('no files!');
						continue
					end

					% get secondary list of files to load
					% if isempty(filesToLoad)|length(filesToLoad)<3
					%     filesToLoad = getFileList(obj.dataPath{fileNum},regexPairs{2});
					%     rawFiles = 1;
					%     if isempty(filesToLoad)
					%     % if(~exist(filesToLoad{1}, 'file'))
					%     	display('no files!');
					%         continue
					%     end
					% end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					if exist('pcaicaAnalysisOutput','var')
						signalTraces = double(pcaicaAnalysisOutput.IcaTraces);
						% signalImages = permute(double(pcaicaAnalysisOutput.IcaFilters),[3 1 2]);
						if strcmp(pcaicaAnalysisOutput.imageSaveDimOrder,'xyz')
							signalImages = double(pcaicaAnalysisOutput.IcaFilters);
						elseif strcmp(pcaicaAnalysisOutput.imageSaveDimOrder,'zxy')
							signalImages = permute(double(pcaicaAnalysisOutput.IcaFilters),[2 3 1]);
							% inputImages = pcaicaAnalysisOutput.IcaFilters;
						else
							% inputImages = permute(double(pcaicaAnalysisOutput.IcaFilters));
							signalImages = pcaicaAnalysisOutput.IcaFilters;
						end

						clear pcaicaAnalysisOutput;
					else
						signalImages = permute(IcaFilters,[2 3 1]);
						signalTraces = IcaTraces;
						clear IcaFilters IcaTraces;
					end
					rawFiles = 1;
				case {'EM','CELLMax'}
					regexPairs = {...
						obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod),...
						obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod),...
						obj.extractionMethodClassifierSaveStr.(obj.signalExtractionMethod)...
					};
						% {obj.rawEMStructSaveStr,obj.sortedEMStructSaveStr,obj.classifierEMStructSaveStr}...
					% };
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					if isempty(filesToLoad)
						display('no files!');
						continue
					end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					if exist('cellmaxAnalysisOutput','var')
						emAnalysisOutput = cellmaxAnalysisOutput;
					end
					% signalImages = permute(emAnalysisOutput.cellImages,[3 1 2]);
					signalImages = emAnalysisOutput.cellImages;
					if isfield(emAnalysisOutput,'scaledProbability')
						% signalTraces = emAnalysisOutput.scaledProbabilityAlt;
						signalTraces = emAnalysisOutput.scaledProbability;
					elseif isfield(emAnalysisOutput,'dsCellTraces')
						if length(emAnalysisOutput.dsCellTraces)==1
							signalTraces = emAnalysisOutput.cellTraces;
						else
							signalTraces = emAnalysisOutput.dsCellTraces;
						end
					else
						signalTraces = emAnalysisOutput.cellTraces;
					end
					% size(signalTraces)
					rawFiles = 1;
				case 'EXTRACT'
					regexPairs = {...
						{obj.rawEXTRACTStructSaveStr,obj.sortedEXTRACTStructSaveStr,obj.classifierEXTRACTStructSaveStr}...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					if isempty(filesToLoad)
						display('no files!');
						continue
					end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					signalImages = double(extractAnalysisOutput.filters);
					% signalImages = double(permute(extractAnalysisOutput.filters,[3 1 2]));
					% signalTraces = double(permute(extractAnalysisOutput.traces, [2 1]));
					signalTraces = double(extractAnalysisOutput.traces);
					% size(signalTraces)
					% size(signalImages)
					% class(signalTraces)
					% class(signalImages)
					rawFiles = 1;
				case 'CNMF'
					regexPairs = {...
						{obj.rawCNMFStructSaveStr,obj.sortedCNMFStructSaveStr,obj.classifierCNMFStructSaveStr}...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					if isempty(filesToLoad)
						display('no files!');
						continue
					end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					% signalImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
					signalImages = double(cnmfAnalysisOutput.extractedImages);
					% signalTraces = double(cnmfAnalysisOutput.extractedSignals);
					signalTraces = double(cnmfAnalysisOutput.extractedSignalsEst);
					rawFiles = 1;
				case 'CNMFE'
					regexPairs = {...
						{obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod),obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod),obj.extractionMethodClassifierSaveStr.(obj.signalExtractionMethod)}...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					if isempty(filesToLoad)
						display('no files!');
						continue
					end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					% signalImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
					signalImages = double(cnmfeAnalysisOutput.extractedImages);
					% signalTraces = double(cnmfAnalysisOutput.extractedSignals);
					signalTraces = double(cnmfeAnalysisOutput.extractedSignalsEst);
					rawFiles = 1;
				case 'ROI'
					regexPairs = {...
						{obj.rawROIStructSaveStr}...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},strrep(regexPairs{1},'.mat',''));
					if isempty(filesToLoad)
						display('no files!');
						continue
					end
					% load files in order
					for i=1:length(filesToLoad)
						display(['loading: ' filesToLoad{i}]);
						load(filesToLoad{i});
					end
					% signalImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
					signalImages = double(roiAnalysisOutput.filters);
					% signalTraces = double(cnmfAnalysisOutput.extractedSignals);
					signalTraces = double(roiAnalysisOutput.traces);
					rawFiles = 1;
				otherwise
					% body
			end

			signalExtractionMethod = signalExtractionMethodOriginal;

			display(['signalTraces: ' num2str(size(signalTraces))])
			display(['signalImages: ' num2str(size(signalImages))])
			% display(['signalPeaks: ' num2str(size(signalPeaks))])
			% display(['signalPeaksArray: ' num2str(size(signalPeaksArray))])

			% if manually sorted signals, add
			% if exist('valid','var')|exist('validCellMax','var')|exist('validEXTRACT','var')
			varList = who;
			% if length(intersect({obj.validPCAICAStructVarname,obj.validEMStructVarname,obj.validPCAICAStructVarname,obj.validEXTRACTStructVarname,obj.validCNMFStructVarname},varList))>0
			if length(intersect({obj.extractionMethodValidVarname.(obj.signalExtractionMethod)},varList))>0
				display('adding manually sorted values...')
				display(['adding valid{' num2str(fileNum) '}.' obj.signalExtractionMethod '.manual identifications...'])
				if exist(obj.validPCAICAStructVarname,'var')
					obj.validManual{fileNum} = valid;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = valid;
					clear valid;
				end
				if exist(obj.validEMStructVarname,'var')
					obj.validManual{fileNum} = validCellMax;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = validCellMax;
					clear validCellMax;
				end
				if exist(obj.validEXTRACTStructVarname,'var')
					obj.validManual{fileNum} = validEXTRACT;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = validEXTRACT;
					clear validEXTRACT;
				end
				if exist(obj.validCNMFStructVarname,'var')
					obj.validManual{fileNum} = validCNMF;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = validCNMF;
					clear validCNMF;
				end
				if exist(obj.extractionMethodValidVarname.('CNMFE'),'var')
					obj.validManual{fileNum} = validCNMFE;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = validCNMFE;
					clear validCNMFE;
				end
				if exist(obj.extractionMethodValidVarname.('ROI'),'var')
					obj.validManual{fileNum} = validROI;
					obj.valid{fileNum}.(obj.signalExtractionMethod).manual = validROI;
					clear validROI;
				end
				display('clearing manual variable...')
			end
			if exist('validClassifier','var')
				display('adding classifier annotation for signals...')
				obj.valid{fileNum}.(obj.signalExtractionMethod).classifier = validClassifier;
				display('clearing manual variable...')
				clear validClassifier;
			end

			% compute peaks
			if exist('signalTraces','var')
				% [obj.signalPeaks{fileNum}, obj.signalPeaksArray{fileNum}] = computeSignalPeaks(signalTraces, 'makePlots', 0,'makeSummaryPlots',0);
				[testpeaks, obj.signalPeaksArray{fileNum}] = computeSignalPeaks(signalTraces, 'makePlots', 0,'makeSummaryPlots',0,'numStdsForThresh',numStdsForThresh,'detectMethod','diff','reportMidpoint',reportMidpoint);
				obj.nSignals{fileNum} = size(signalTraces,1);
				obj.nFrames{fileNum} = size(signalTraces,2);
			end


			% get the x/y coordinates
			if isempty(signalImages);continue;end;
			[xCoords yCoords] = findCentroid(signalImages,'thresholdValue',0.4,'imageThreshold',0.4);
			obj.objLocations{fileNum}.(obj.signalExtractionMethod) = [xCoords(:) yCoords(:)];

			% rawFiles
			if rawFiles==1
				if exist('signalTraces','var')
					signalTracesTmp = signalTraces;
				else
					signalTracesTmp = [];
				end

				% % get list of movies
				% movieList = getFileList(obj.dataPath{fileNum}, obj.fileFilterRegexp);
				% [inputMovie o m n] = loadMovieList(movieList);
				% signalImagesTmp = NaN([size(signalImages,1) 20 20]);
				% for imageNo = 1:size(signalImages,1)
				% 	[signalImagesTmp(imageNo,:,:)] = viewMontage(inputMovie,signalImages(imageNo,:,:),signalTraces(imageNo,:),obj.signalPeaksArray{fileNum});
				% end
				% signalImages = signalImagesTmp;
				display(['traces dims: ' num2str(size(signalTracesTmp))])
				display(['images dims: ' num2str(size(signalImages))])
				[~, ~, validAuto, imageSizes, imgFeatures] = filterImages(signalImages, signalTracesTmp,'featureList',obj.classifierImageFeaturesNames,'options',obj.filterImageOptions,'testpeaks',testpeaks,'testpeaksArray',obj.signalPeaksArray{fileNum},'xCoords',xCoords,'yCoords',yCoords);

				% obj.classifierFeatures{fileNum}.(obj.signalExtractionMethod).imageFeatures = imgFeatures;
				obj.classifierFeatures.autoClassifier{fileNum}.(obj.signalExtractionMethod).imageFeatures = imgFeatures;
				% obj.classifierFeatures{fileNum}.signalFeatures = ;

					[figHandle figNo] = openFigure(98, '');
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					obj.modelSaveImgToFile([],'objSize_','current',[]);
					[figHandle figNo] = openFigure(1997, '');
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					obj.modelSaveImgToFile([],'objFeatures_','current',[]);

				% classify signals with a classifier

				% [filterImageGroups] = groupImagesByColor(signalImages,validAuto+1);
				% obj.rawImagesFiltered{fileNum} = createObjMap(filterImageGroups);
				size(validAuto)
				% validAuto
				display(['adding valid{' num2str(fileNum) '}.' obj.signalExtractionMethod '.auto identifications...'])
				obj.validAuto{fileNum} = validAuto;
				obj.valid{fileNum}.(obj.signalExtractionMethod).auto = validAuto;
				clear validAuto
				% [figHandle figNo] = openFigure(2014+round(rand(1)*100), '');
				%     imagesc(filterImageGroups);
				%     colormap(customColormap([]));
				%     box off; axis off;
				%     % colorbar
			end

			% add files
			if obj.loadVarsToRam == 1
				display('Loading variables into ram.')
				if exist('signalTraces','var')
					obj.rawSignals{fileNum} = signalTraces;
				end
				if exist('signalImages','var')
					obj.rawImages{fileNum} = signalImages;
				end
			else
				obj.rawSignals{fileNum} = [];
				obj.rawImages{fileNum} = [];
			end
			clear signalTraces signalImages
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	obj.guiEnabled = 0;
	obj.modelModifyRegionAnalysis();
	obj.guiEnabled = 1;
end
function [croppedPeakImages2] = viewMontage(inputMovie,inputImage,thisTrace,signalPeakArray)

	if isempty(signalPeakArray)
		imagesc(inputImage);
		colormap(customColormap([]));
		axis off;
		croppedPeakImages2 = inputImage;
		return
	end
	% signalPeakArray
	maxSignalsToShow = 20;
	peakSignalAmplitude = thisTrace(signalPeakArray(:));
	% peakSignalAmplitude
	[peakSignalAmplitude peakIdx] = sort(peakSignalAmplitude,'descend');
	% peakSignalAmplitude
	signalPeakArray = signalPeakArray(peakIdx);
	if length(signalPeakArray)>maxSignalsToShow
		% choose a random subset
		signalPeakArray = signalPeakArray(1:maxSignalsToShow);
	end
	signalPeakArray = {signalPeakArray};
	% signalPeakArray
	croppedPeakImages = compareSignalToMovie(inputMovie, inputImage, thisTrace,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',0,'crosshairs',0,'signalPeakArray',signalkkPeakArray);
	croppedPeakImages = squeeze(nanmean(croppedPeakImages(:,:,2:end),3));
end