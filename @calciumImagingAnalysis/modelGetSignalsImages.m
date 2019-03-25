function [inputSignals inputImages signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj,varargin)
	% Grabs input signals and images from current folder
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		% thisFileNum - this should be set to the folder
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%

	%========================
	% which table to read in
	% 'filtered' or 'raw'
	options.returnType = 'filtered';
	options.returnOnlyValid = 0;
	options.emSaveSorted = '_emAnalysisSorted.mat';
	options.forceManual = 0;
	options.fileNum = [];
	options.filterTraces = 0;
		% options.movAvgFiltSize = 5;
		options.movAvgFiltSize = [];
		% number of frames to calculate median filter
		% options.medianFilterLength = 201;
		options.medianFilterLength = 50;
	% decide whether to load algorithm peaks by default
	options.loadAlgorithmPeaks = 0;
	% SignalsImages, Images, Signals
	% options.getSpecificData = 'SignalsImages';
	%
	options.regexPairs = {...
		% {'_ICfilters_sorted.mat','_ICtraces_sorted.mat'},...
		% {'holding.mat','holding.mat'},...
		{obj.rawPCAICAStructSaveStr},...
		{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
		{obj.rawEMStructSaveStr},...
		{obj.rawEXTRACTStructSaveStr},...
		{obj.rawCNMFStructSaveStr},...
		{obj.sortedICfiltersSaveStr,obj.sortedICtracesSaveStr},...
	};
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	pause(0.001)

	if isempty(options.fileNum)
		thisFileNum = obj.fileNum;
	else
		thisFileNum = options.fileNum;
	end

	options.returnTypeTwo = options.returnType;
	switch options.returnType
		case 'sorted'
			options.regexPairs = {{obj.sortedICfiltersSaveStr,obj.sortedICtracesSaveStr}};
			options.returnType = 'raw';
		case 'filtered_traces'
			options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICtracesSaveStr}};
			options.returnType = 'filtered';
		case 'filtered_images'
			options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICfiltersSaveStr}};
			options.returnType = 'filtered';
		case 'raw_traces'
			options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICtracesSaveStr}};
			options.returnType = 'raw';
		case 'raw_images'
			options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICfiltersSaveStr}};
			options.returnType = 'raw';
		case 'raw_CellMax'
			options.regexPairs = {{obj.rawEMStructSaveStr}};
			options.returnType = 'raw';
		otherwise
			switch obj.signalExtractionMethod
				case 'PCAICA'
					options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},{obj.sortedICfiltersSaveStr,obj.sortedICtracesSaveStr}};
				case 'EM'
					options.regexPairs = {{obj.rawEMStructSaveStr}};
				case 'EXTRACT'
					options.regexPairs = {{obj.rawEXTRACTStructSaveStr}};
				case 'CNMF'
					options.regexPairs = {{obj.rawCNMFStructSaveStr}};
				case 'ROI'
					options.regexPairs = {{obj.rawROIStructSaveStr}};
				otherwise
					fprintf('Search: %s\n',obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod))
					options.regexPairs = {{obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod)}};
			end
	end

	regexPairs = options.regexPairs;

	% get valid signals, priority is region excluded, manual sorting, automatic sorting, and all valid otherwise.
	% use try/catch to check whether nested structure fieldname exists
	try obj.validRegionMod{thisFileNum};check.regionMod=1; catch; check.regionMod=0; end
	try obj.valid{thisFileNum}.(obj.signalExtractionMethod).classifier;check.classifier=1; catch; check.classifier=0; end
	try obj.valid{thisFileNum}.(obj.signalExtractionMethod).manual;check.manual=1; catch; check.manual=0; end
	try obj.validManual{thisFileNum};check.manualOld=1; catch; check.manualOld=0; end
	try obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto;check.auto=1; catch; check.auto=0; end
	try obj.validAuto{thisFileNum};check.autoOld=1; catch; check.autoOld=0; end

	if check.regionMod&options.forceManual==0
		valid = obj.validRegionMod{thisFileNum};
		display('using regional identifications...')
	elseif check.classifier&options.forceManual==0
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).classifier;
		display('using classifier identifications...')
	elseif check.manual
		display(['using valid.' obj.signalExtractionMethod '.manual identifications...'])
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).manual;
	elseif check.manualOld
		valid = logical(obj.validManual{thisFileNum});
		% size(valid)
		display('using manual identifications...')
	elseif check.auto
		display(['using valid.' obj.signalExtractionMethod '.auto identifications...'])
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto;
	elseif check.autoOld
		valid = obj.validAuto{thisFileNum};
		display('using auto identifications...')
	elseif ~isempty(obj.rawSignals)
		valid = ones([1 size(obj.rawSignals{thisFileNum},1)]);
	else
		valid = [];
	end

	% make sure valid is a logical
	valid = logical(valid);
	if ~isempty(valid)
		if sum(valid)==0
			valid(1:end) = 1;
		end
	end

	if options.returnOnlyValid==1
		inputSignals = [];
		inputImages = [];
		signalPeaks = [];
		signalPeaksArray = [];
		return;
	end

	if length(obj.rawSignals)==0
		rawSignalsEmpty = 1;
	else
		rawSignalsEmpty = isempty(obj.rawSignals{thisFileNum});
	end
	% rawSignalsEmpty
	if rawSignalsEmpty==1
		inputSignals = [];
		inputImages = [];
		signalPeaks = [];
		signalPeaksArray = [];
		if strmatch('#',obj.dataPath{thisFileNum})
			return;
		else
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.dataPath{fileNum}]);
		end

		% get list of files to load
		filesToLoad = [];
		fileToLoadNo = 1;
		nRegExps = length(regexPairs);
		while isempty(filesToLoad)
			filesToLoad = getFileList(obj.dataPath{thisFileNum},strrep(regexPairs{fileToLoadNo},'.mat',''));
			fileToLoadNo = fileToLoadNo+1;
			if fileToLoadNo>nRegExps
				break;
			end
		end
	    if isempty(filesToLoad)
	    % if(~exist(filesToLoad{1}, 'file'))
	    	display('no files');
	    	inputSignals = [];
	    	inputImages = [];
	    	signalPeaks = [];
	    	signalPeaksArray = [];
	        return;
	    end
		% rawFiles = 0;
		% % get secondary list of files to load
		% % |strcmp(options.returnType,'raw')
		% if isempty(filesToLoad)
		%     filesToLoad = getFileList(obj.dataPath{thisFileNum},regexPairs{2});
		%     rawFiles = 1;
		% end
		% load files in order
		for i=1:length(filesToLoad)
		    display(['loading: ' filesToLoad{i}]);
		    try
		    	load(filesToLoad{i});
		    catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
		    	pause(3)
		    	display(['trying, loading again: ' filesToLoad{i}]);
		    	load(filesToLoad{i});
			end

		end

		if exist('pcaicaAnalysisOutput','var')
			inputSignals = double(pcaicaAnalysisOutput.IcaTraces);
			if strcmp(pcaicaAnalysisOutput.imageSaveDimOrder,'xyz')
				% inputImages = permute(double(pcaicaAnalysisOutput.IcaFilters),[3 1 2])
				inputImages = double(pcaicaAnalysisOutput.IcaFilters);
			elseif strcmp(pcaicaAnalysisOutput.imageSaveDimOrder,'zxy')
				inputImages = permute(double(pcaicaAnalysisOutput.IcaFilters),[2 3 1]);
				% inputImages = pcaicaAnalysisOutput.IcaFilters;
			else
				% inputImages = permute(double(pcaicaAnalysisOutput.IcaFilters));
				inputImages = pcaicaAnalysisOutput.IcaFilters;
			end
		end
		% if exist(obj.structEXTRACTVarname,'var')
		if exist('extractAnalysisOutput','var')
			% inputImages = double(permute(extractAnalysisOutput.filters,[3 1 2]));
			inputImages = double(extractAnalysisOutput.filters);
			% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));
			inputSignals = double(extractAnalysisOutput.traces);

			% inputSignals = extractAnalysisOutput.traces;
			% inputImages = permute(extractAnalysisOutput.filters,[3 1 2]);
		end
		% if exist(obj.structCNMRVarname,'var')
		if exist('cnmfAnalysisOutput','var')
			% inputImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
			inputImages = double(cnmfAnalysisOutput.extractedImages);
			% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));
			inputSignals = double(cnmfAnalysisOutput.extractedSignals);
			% inputSignals = double(cnmfAnalysisOutput.extractedSignalsEst);

			if options.loadAlgorithmPeaks==1
				signalPeaks = cnmfAnalysisOutput.extractedPeaks>0;
				nCells=size(signalPeaks,1);
				signalPeaksArray=cell(nCells,1);
				for cInd=1:nCells
				    signalPeaksArray{cInd}=find(signalPeaks(cInd,:));
				end
				obj.signalPeaksArray{thisFileNum} = signalPeaksArray;
				obj.signalPeaks{thisFileNum} = signalPeaks;
				obj.nSignals{thisFileNum} = size(signalPeaks,1);
			end
			% inputSignals = extractAnalysisOutput.traces;
			% inputImages = permute(extractAnalysisOutput.filters,[3 1 2]);
		end
		if exist('cnmfeAnalysisOutput','var')
			% inputImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
			inputImages = double(cnmfeAnalysisOutput.extractedImages);
			% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));
			inputSignals = double(cnmfeAnalysisOutput.extractedSignalsEst);
			% inputSignals = double(cnmfeAnalysisOutput.extractedSignals);

			if options.loadAlgorithmPeaks==1
				signalPeaks = cnmfeAnalysisOutput.extractedPeaks>0;
				nCells=size(signalPeaks,1);
				signalPeaksArray=cell(nCells,1);
				for cInd=1:nCells
				    signalPeaksArray{cInd}=find(signalPeaks(cInd,:));
				end
				obj.signalPeaksArray{thisFileNum} = signalPeaksArray;
				obj.signalPeaks{thisFileNum} = signalPeaks;
				obj.nSignals{thisFileNum} = size(signalPeaks,1);
			end
			% inputSignals = extractAnalysisOutput.traces;
			% inputImages = permute(extractAnalysisOutput.filters,[3 1 2]);
		end
		% if exist(obj.structEMVarname,'var')
		if exist('emAnalysisOutput','var')
			% inputSignals = emAnalysisOutput.dsCellTraces;
			% if length(emAnalysisOutput.dsCellTraces)==1
			% 	inputSignals = emAnalysisOutput.cellTraces;
			% else
			% 	inputSignals = emAnalysisOutput.dsCellTraces;
			% end
			if isfield(emAnalysisOutput,'scaledProbability')
				display('using scaled probability...')
				inputSignals = double(emAnalysisOutput.scaledProbability);
			elseif isfield(emAnalysisOutput,'dsScaledProbability')
				inputSignals = double(emAnalysisOutput.dsScaledProbability);
			elseif isfield(emAnalysisOutput,'cellTraces')
				inputSignals = double(emAnalysisOutput.cellTraces);
			elseif isfield(emAnalysisOutput,'dsCellTraces')
				if length(emAnalysisOutput.dsCellTraces)==1
					inputSignals = emAnalysisOutput.cellTraces;
				else
					inputSignals = emAnalysisOutput.dsCellTraces;
				end
			else
				inputSignals = emAnalysisOutput.cellTraces;
			end

			% inputSignals = double(emAnalysisOutput.scaledProbabilityAlt);

			% inputImages = permute(emAnalysisOutput.cellImages,[3 1 2]);
			inputImages = emAnalysisOutput.cellImages;

			if options.loadAlgorithmPeaks==1
				signalPeaksArray = emAnalysisOutput.eventTimes;
				signalPeaks = zeros([size(inputSignals,1) size(inputSignals,2)]);
				for signalNo = 1:obj.nSignals{thisFileNum}
					signalPeaks(signalNo,signalPeaksArray{signalNo}) = 1;
				end
				obj.signalPeaksArray{thisFileNum} = signalPeaksArray;
				obj.signalPeaks{thisFileNum} = signalPeaks;
				obj.nSignals{thisFileNum} = size(signalPeaks,1);
			end

			% if isempty(obj.signalPeaks{thisFileNum})
			% 	signalPeaks = [];
			% 	signalPeaksArray = [];
			% else
			% 	signalPeaks = obj.signalPeaks{thisFileNum};
			% 	signalPeaksArray = {obj.signalPeaksArray{thisFileNum}};
			% end
		end
		if exist('roiAnalysisOutput','var')
			% inputImages = double(permute(extractAnalysisOutput.filters,[3 1 2]));
			inputImages = double(roiAnalysisOutput.filters);
			% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));
			if isfield(roiAnalysisOutput,'tracesDemix')
				display('Using demixed ROI traces!')
				inputSignals = double(roiAnalysisOutput.tracesDemix);
			else
				inputSignals = double(roiAnalysisOutput.traces);
			end
		end

		if exist('IcaTraces','var')
			inputSignals = IcaTraces;
		end
		if exist('ROItraces','var')
			inputSignals = ROItraces;
		end
		if exist('IcaFilters','var')
			% inputImages = IcaFilters;
			inputImages = permute(IcaFilters,[2 3 1]);
		end

		% if skipping modelVarsFromFiles
		if isempty(valid)
			switch options.returnType
				case 'raw'
					try obj.signalPeaksArray{thisFileNum};calcPeaks=1; catch; calcPeaks=0; end
					if calcPeaks==0
                        [signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
                    else
                        signalPeaksArray = obj.signalPeaksArray{thisFileNum};
                        % obj.signalPeaksArray{thisFileNum}
                    end
                    signalPeaksArray = obj.signalPeaksArray{thisFileNum};
                    signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
                    display('creating signalPeaks...')
                    for signalNo = 1:obj.nSignals{thisFileNum}
                        signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
                    end
					%if isempty(signalPeaks)
					%	[signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
					%end
					% signalPeaks = [];
					% signalPeaksArray = [];
					valid = [];
					display(['inputSignals: ' num2str(size(inputSignals))])
					display(['inputImages: ' num2str(size(inputImages))])
					return
				otherwise
					try obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto;check.auto=1; catch; check.auto=0; end
					if check.auto
						display(['using valid.' obj.signalExtractionMethod '.auto identifications...'])
						valid = logical(obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto);
						% [signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
						% [~, obj.signalPeaksArray{thisFileNum}] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
						% obj.nSignals{thisFileNum} = size(inputSignals,1);
						% obj.nFrames{thisFileNum} = size(inputSignals,2);
					elseif isempty(valid)
						[~, ~, validAuto, imageSizes] = filterImages(inputImages, inputSignals,'options',obj.filterImageOptions);
						obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto = logical(validAuto);
						valid = logical(validAuto);
						% [~, obj.signalPeaksArray{thisFileNum}] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
						% [signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
						% obj.nSignals{thisFileNum} = size(inputSignals,1);
						% obj.nFrames{thisFileNum} = size(inputSignals,2);
					end
					try obj.signalPeaksArray{thisFileNum};calcPeaks=1; catch; calcPeaks=0; end
					if calcPeaks==0
						[~, obj.signalPeaksArray{thisFileNum}] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
					end
					obj.nSignals{thisFileNum} = size(inputSignals,1);
					obj.nFrames{thisFileNum} = size(inputSignals,2);
			end
		end

		% if exist('inputSignals','var')
		if ~isempty(inputSignals)
			if isempty(obj.signalPeaksArray{thisFileNum})
				signalPeaks = [];
				signalPeaksArray = [];
			else
				signalPeaksArray = obj.signalPeaksArray{thisFileNum};
				signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
				display('creating signalPeaks...')
				for signalNo = 1:length(signalPeaksArray)
					signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
				end
				% signalPeaks = obj.signalPeaks{thisFileNum};
			end
			switch options.returnType
				case 'raw'

				case 'filtered'
					inputSignals = inputSignals(valid,:);
					signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{valid}};
					% signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
					signalPeaks = zeros([length(signalPeaksArray) obj.nFrames{thisFileNum}]);
					for signalNo = 1:length(signalPeaksArray)
						signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
					end
					% signalPeaks = signalPeaks(valid,:);
				case 'filteredAndRegistered'
					inputSignals = inputSignals(valid,:);
					% inputImages = IcaFilters(valid,:,:);
					signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{valid}};

					% signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
					signalPeaks = zeros([length(signalPeaksArray) obj.nFrames{thisFileNum}]);
					for signalNo = 1:length(signalPeaksArray)
						signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
					end
					% signalPeaks = signalPeaks(valid,:);
				otherwise
					% body
			end
			display(['signalPeaks: ' num2str(size(signalPeaks))])
			% obj.nFrames{thisFileNum} = size(inputSignals,2);
			% obj.nSignals{thisFileNum} = size(inputSignals,1);
		end


		% if exist('inputImages','var')
		if ~isempty(inputImages)
			switch options.returnType
				case 'raw'

				case 'filtered'
					inputImages = inputImages(:,:,valid);
				case 'filteredAndRegistered'
					inputImages = inputImages(:,:,valid);
					% register images based on cross session alignment
					globalRegCoords = obj.globalRegistrationCoords.(obj.subjectStr{thisFileNum});
					if ~isempty(globalRegCoords)
						display('registering images')
						% get the global coordinate number based
						% globalRegCoords = globalRegCoords{strcmp(obj.assay{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
                        % globalRegCoords = globalRegCoords{strcmp(obj.date{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
                        globalRegCoords = globalRegCoords{strcmp(obj.folderBaseSaveStr{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
						if ~isempty(globalRegCoords)
							% inputImages = permute(inputImages,[2 3 1]);
							for iterationNo = 1:length(globalRegCoords)
								fn=fieldnames(globalRegCoords{iterationNo});
								for i=1:length(fn)
									localCoords = globalRegCoords{iterationNo}.(fn{i});
									% playMovie(inputImages);
									[inputImages, localCoords] = turboregMovie(inputImages,'precomputedRegistrationCooords',localCoords);
								end
							end
							% inputImages = permute(inputImages,[3 1 2]);
						end
					end
				otherwise
					% body
			end
		end
	else
		display('Using variables in ram')
		inputSignals = obj.rawSignals{thisFileNum}(:,:);
		inputImages = obj.rawImages{thisFileNum}(:,:,:);
		signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{:}};
		% signalPeaks = obj.signalPeaks{thisFileNum}(valid,:);

		signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
		for signalNo = 1:obj.nSignals{thisFileNum}
			signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
		end
		switch options.returnType
			case 'raw'

			case 'filtered'
				inputSignals = obj.rawSignals{thisFileNum}(valid,:);
				inputImages = obj.rawImages{thisFileNum}(:,:,valid);
				signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{valid}};
				signalPeaks = signalPeaks(valid,:);
			otherwise
				% body
		end
		obj.nFrames{thisFileNum} = size(inputSignals,2);
		obj.nSignals{thisFileNum} = size(inputSignals,1);
	end

	if options.filterTraces==1
		fprintf('Median (%d frames) and average (%d frames)  filtering traces.\n',options.medianFilterLength,options.movAvgFiltSize)
		for signalNoNow = 1:size(inputSignals,1)
			inputSignal = inputSignals(signalNoNow,:);
			inputSignalMedian = medfilt1(inputSignal,options.medianFilterLength,'omitnan','truncate');
			inputSignal = inputSignal - inputSignalMedian;
			if ~isempty(options.movAvgFiltSize)
				inputSignals(signalNoNow,:) = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal);
			end
		end
	end

	display(['inputSignals: ' num2str(size(inputSignals))])
	display(['inputImages: ' num2str(size(inputImages))])
	display(['signalPeaks: ' num2str(size(signalPeaks))])
	display(['signalPeaksArray: ' num2str(size(signalPeaksArray))])
end