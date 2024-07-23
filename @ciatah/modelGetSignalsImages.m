function [inputSignals, inputImages, signalPeaks, signalPeaksArray, valid, validType, inputSignals2] = modelGetSignalsImages(obj,varargin)
	% Grabs input signals and images from current folder
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		% thisFileNum - this should be set to the folder
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2020.04.16 [19:59:43] - Small fix to NWB file checking.
		% 2020.05.12 [18:02:04] - Update to make sure inputSignals2 with NWB.
		% 2020.12.08 [01:14:09] - Reorganized returnType to be outside raw signals flag, so common filtering mechanism regardless of variables loaded into RAM or not. This fixes if a user loads variables into RAM then uses cross-session alignment, the viewMatchObjBtwnSessions method may not display registered images (cross-session alignment is still fine and valid).
		% 2021.06.30 [14:52:23] - Updated to allow loading raw files without calling modelVarsFromFiles.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.04.09 [20:30:52] - Ensure when loading cell extraction CIAtah-style that only MAT files are loaded.
		% 2023.05.09 [11:52:23] - Added support for registering images (e.g. after cross-day registration) using multiple methods instead of just turboreg.
	% TODO
		% Give a user a warning() output if there are no or empty cell-extraction outputs

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Type of file to return: 'filtered' or 'raw'
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
	% 1 = Load signal peaks
	options.loadSignalPeaks = 1;
	% Binary: 1 = loads raw files quickly without additional checks. 0 = normal loading.
	options.fastFileLoad = 0;
	% SignalsImages, Images, Signals
	% which table to read in
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

	validType = '';

	if isempty(options.fileNum)
		thisFileNum = obj.fileNum;
	else
		thisFileNum = options.fileNum;
	end

	inputSignals2 = [];

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
			options.regexPairs = {{obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod)}};
			options.returnType = 'raw';
		otherwise
			switch obj.signalExtractionMethod
				case 'PCAICA'
					options.regexPairs = {{obj.rawPCAICAStructSaveStr},{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},{obj.sortedICfiltersSaveStr,obj.sortedICtracesSaveStr}};
				case {'EM','CELLMax'}
					% options.regexPairs = {{obj.rawEMStructSaveStr}};
					options.regexPairs = {{obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod)}};
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
	% REGION ANALYSIS
	try
		obj.validRegionMod{thisFileNum};
		check.regionMod=1;
	catch
		check.regionMod=0;
	end
	% CLASSIFIER ANALYSIS
	try
		obj.valid{thisFileNum}.(obj.signalExtractionMethod).classifier;
		check.classifier=1;
	catch
		check.classifier=0;
	end
	% MANUAL ANALYSIS
	try
		obj.valid{thisFileNum}.(obj.signalExtractionMethod).manual;
		check.manual=1;
	catch
		check.manual=0;
	end
	% MANUAL ANALYSIS OLD
	try
		if isempty(obj.validManual{thisFileNum});
			check.manualOld=0;
		else
			check.manualOld=1;
		end
	catch
		check.manualOld=0;
		% if isempty(obj.validManual{thisFileNum})
		% 	check.manualOld=0;
		% end
	end
	% AUTOMATIC ANALYSIS
	try
		obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto;
		check.auto=1;
	catch
		check.auto=0;
	end
	% AUTOMATIC ANALYSIS OLD
	try
		obj.validAuto{thisFileNum};check.autoOld=1;
	catch
		check.autoOld=0;
	end
	% AUTOMATIC ANALYSIS OLD
	try
		~isempty(obj.rawSignals{thisFileNum});check.raw=1;
	catch
		check.raw=0;
	end

	% Change which sorting is done
	if check.regionMod&options.forceManual==0
		disp('using regional identifications...')
		valid = obj.validRegionMod{thisFileNum};
		validType = 'validRegionMod';
	elseif check.classifier&options.forceManual==0
		disp('using classifier identifications...')
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).classifier;
		validType = 'validClassifier';
	elseif check.manual
		disp(['using valid.' obj.signalExtractionMethod '.manual identifications...'])
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).manual;
		validType = 'validManual';
	elseif check.manualOld
		disp('using manual identifications...')
		valid = logical(obj.validManual{thisFileNum});
		validType = 'validManualOld';
	elseif check.auto
		disp(['using valid.' obj.signalExtractionMethod '.auto identifications...'])
		valid = obj.valid{thisFileNum}.(obj.signalExtractionMethod).auto;
		validType = 'validAuto';
	elseif check.autoOld
		disp('using auto identifications...')
		valid = obj.validAuto{thisFileNum};
		validType = 'validAutoOld';
	elseif check.raw
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

	if isempty(obj.rawSignals)
		rawSignalsEmpty = 1;
	else
		if check.raw==1
			rawSignalsEmpty = isempty(obj.rawSignals{thisFileNum});
		else
			rawSignalsEmpty = 1;
		end
	end
	% rawSignalsEmpty
	if rawSignalsEmpty==1
		inputSignals = [];
		inputImages = [];
		signalPeaks = [];
		signalPeaksArray = [];
		if strcmp('#',obj.dataPath{thisFileNum})
			return;
		else
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.dataPath{fileNum}]);
		end

		% get list of files to load
		filesToLoad = [];
		fileToLoadNo = 1;
		nRegExps = length(regexPairs);

		% Flag for whether to load the default calciumImagingAnalysis filetype
		loadCiaFiles = 1;
		
		if options.fastFileLoad==1
			if obj.nwbLoadFiles==1
				if isempty(obj.nwbFileRegexp)
					filesToLoad = getFileList([obj.dataPath{thisFileNum} filesep obj.nwbFileFolder],[obj.extractionMethodSaveStr.(obj.signalExtractionMethod) '*.nwb']);
				else
					filesToLoad = getFileList([obj.dataPath{thisFileNum} filesep obj.nwbFileFolder],obj.nwbFileRegexp);
				end
			else
				while isempty(filesToLoad)
					filesToLoad = getFileList(obj.dataPath{thisFileNum},strrep(regexPairs{fileToLoadNo},'.mat','.*.mat$'));
					fileToLoadNo = fileToLoadNo+1;
					if fileToLoadNo>nRegExps
						break;
					end
				end
			end
			if isempty(filesToLoad)
			else
				[inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = ciapkg.io.loadSignalExtraction(filesToLoad{1});
			end
			signalPeaks = [];
			signalPeaksArray = [];
			return;
		end

		if obj.nwbLoadFiles==1
			% Check whether to use override NWB regular expression, else use calciumImagingAnalysis defaults.
			if isempty(obj.nwbFileRegexp)
				filesToLoad = getFileList([obj.dataPath{thisFileNum} filesep obj.nwbFileFolder],[obj.extractionMethodSaveStr.(obj.signalExtractionMethod) '*.nwb']);
			else
				filesToLoad = getFileList([obj.dataPath{thisFileNum} filesep obj.nwbFileFolder],obj.nwbFileRegexp);
			end

			if ~isempty(filesToLoad)
				nwbOpts.algorithm = obj.signalExtractionMethod;
				nwbOpts.groupImages = obj.nwbGroupImages;
				nwbOpts.groupSignalSeries = obj.nwbGroupSignalSeries;
				[inputImages,inputSignals,infoStruct] = loadNeurodataWithoutBorders(filesToLoad{1},'options',nwbOpts);

				if nargout>=7
					% If user request second signal series, load it from data.
					nwbOpts.signalSeriesNo = 2;
					nwbOpts.loadImages = 0;
					[~,inputSignals2,~] = loadNeurodataWithoutBorders(filesToLoad{1},'options',nwbOpts);
				end
				loadCiaFiles = 0;
			end
		else

		end

		if loadCiaFiles==1
			while isempty(filesToLoad)
				filesToLoad = getFileList(obj.dataPath{thisFileNum},strrep(regexPairs{fileToLoadNo},'.mat','.*.mat$'));
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

			switch obj.signalExtractionTraceOutputType
				case 1
					inputSignals = double(cnmfAnalysisOutput.extractedSignals);
					inputSignals2 = double(cnmfAnalysisOutput.extractedSignalsEst);
				case 2
					inputSignals = double(cnmfAnalysisOutput.extractedSignalsEst);
					inputSignals2 = double(cnmfAnalysisOutput.extractedSignals);
				otherwise
					inputSignals = double(cnmfAnalysisOutput.extractedSignalsEst);
					inputSignals2 = double(cnmfAnalysisOutput.extractedSignals);
			end

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

			% Convert units to relative dF/F for later analysis
			inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages);
			inputSignals2 = normalizeSignalExtractionActivityTraces(inputSignals2,inputImages);
		end
		if exist('cnmfeAnalysisOutput','var')
			inputImages = double(cnmfeAnalysisOutput.extractedImages);

			switch obj.signalExtractionTraceOutputType
				case 1
					inputSignals = double(cnmfeAnalysisOutput.extractedSignals);
					inputSignals2 = double(cnmfeAnalysisOutput.extractedSignalsEst);
				case 2
					inputSignals = double(cnmfeAnalysisOutput.extractedSignalsEst);
					inputSignals2 = double(cnmfeAnalysisOutput.extractedSignals);
				otherwise
					inputSignals = double(cnmfeAnalysisOutput.extractedSignalsEst);
					inputSignals2 = double(cnmfeAnalysisOutput.extractedSignals);
			end

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

			% Convert units to relative dF/F for later analysis
			inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages);
			inputSignals2 = normalizeSignalExtractionActivityTraces(inputSignals2,inputImages);
		end
		% if exist(obj.structEMVarname,'var')
		if exist('emAnalysisOutput','var')|exist('cellmaxAnalysisOutput','var')
			if exist('cellmaxAnalysisOutput','var')
				emAnalysisOutput = cellmaxAnalysisOutput;
			end
			% inputSignals = emAnalysisOutput.dsCellTraces;
			% if length(emAnalysisOutput.dsCellTraces)==1
			% 	inputSignals = emAnalysisOutput.cellTraces;
			% else
			% 	inputSignals = emAnalysisOutput.dsCellTraces;
			% end
			% inputImages = permute(emAnalysisOutput.cellImages,[3 1 2]);
			inputImages = emAnalysisOutput.cellImages;

			% switch obj.signalExtractionTraceOutputType
			% 	case 1
			% 		%
			% 	case 2
			% 		%
			% 	otherwise
			% 		%
			% end

			emOutputType = {'scaledProbability','dsScaledProbability','cellTraces','dsCellTraces'};
			for emI = 1:length(emOutputType)
				if isfield(emAnalysisOutput,emOutputType{emI})
					disp(['Using ' emOutputType{emI} '...'])
					inputSignals = double(emAnalysisOutput.(emOutputType{emI}));
					break;
				end
			end

			if 0
				if isfield(emAnalysisOutput,'scaledProbability')
					disp('Using scaledProbability...')
					inputSignals = double(emAnalysisOutput.scaledProbability);
				elseif isfield(emAnalysisOutput,'dsScaledProbability')
					disp('Using dsScaledProbability...')
					inputSignals = double(emAnalysisOutput.dsScaledProbability);
				elseif isfield(emAnalysisOutput,'cellTraces')
					disp('Using cellTraces...')
					inputSignals = double(emAnalysisOutput.cellTraces);
				elseif isfield(emAnalysisOutput,'dsCellTraces')
					disp('Using dsCellTraces...')
					if length(emAnalysisOutput.dsCellTraces)==1
						inputSignals = emAnalysisOutput.cellTraces;
					else
						inputSignals = emAnalysisOutput.dsCellTraces;
					end
				else
					inputSignals = emAnalysisOutput.cellTraces;
				end
			end

			inputSignals2 = double(emAnalysisOutput.cellTraces);

			switch obj.signalExtractionTraceOutputType
				case 1
					%
				case 2
					inputSignals2Tmp = inputSignals2;
					inputSignals2 = inputSignals;
					inputSignals = inputSignals2Tmp;
				otherwise
					%
			end

			% Convert to dF/F values
			inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages);
			inputSignals2 = normalizeSignalExtractionActivityTraces(inputSignals2,inputImages);

			% inputSignals = double(emAnalysisOutput.scaledProbabilityAlt);


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
					if options.loadSignalPeaks==1
						try obj.signalPeaksArray{thisFileNum};obj.nFrames{thisFileNum};calcPeaks=1; catch; calcPeaks=0; end
						if isempty(obj.signalPeaksArray{thisFileNum})
							calcPeaks = 1;
						end
						if calcPeaks==0
							[signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
							obj.signalPeaksArray{thisFileNum} = signalPeaksArray;
							obj.nSignals{thisFileNum} = length(obj.signalPeaksArray{thisFileNum});
							obj.nFrames{thisFileNum} = size(signalPeaks,2);
						else
							signalPeaksArray = obj.signalPeaksArray{thisFileNum};
							% obj.signalPeaksArray{thisFileNum}
							% signalPeaksArray = obj.signalPeaksArray{thisFileNum};
							signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
						end
						display('creating signalPeaks...')
						for signalNo = 1:obj.nSignals{thisFileNum}
							signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
						end
					else
						signalPeaks = [];
						signalPeaksArray = {};
					end
					%if isempty(signalPeaks)
					%	[signalPeaks, signalPeaksArray] = computeSignalPeaks(inputSignals, 'makePlots', 0,'makeSummaryPlots',0);
					%end
					% signalPeaks = [];
					% signalPeaksArray = [];

					% valid = [];
					display(['inputSignals: ' num2str(size(inputSignals))])
					display(['inputImages: ' num2str(size(inputImages))])
					display(['signalPeaks: ' num2str(size(signalPeaks))])
					display(['signalPeaksArray: ' num2str(size(signalPeaksArray))])
					display(['valid: ' num2str(size(valid))])
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
	else
		display('Using variables in ram')
		inputSignals = obj.rawSignals{thisFileNum}(:,:);
		inputSignals2 = inputSignals;
		inputImages = obj.rawImages{thisFileNum}(:,:,:);
		signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{:}};
		% signalPeaks = obj.signalPeaks{thisFileNum}(valid,:);

		signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
		for signalNo = 1:obj.nSignals{thisFileNum}
			signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
		end
		% switch options.returnType
		% 	case 'raw'

		% 	case 'filtered'
		% 		inputSignals = obj.rawSignals{thisFileNum}(valid,:);
		% 		inputImages = obj.rawImages{thisFileNum}(:,:,valid);
		% 		signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{valid}};
		% 		signalPeaks = signalPeaks(valid,:);
		% 	otherwise
		% 		% body
		% end
		obj.nFrames{thisFileNum} = size(inputSignals,2);
		obj.nSignals{thisFileNum} = size(inputSignals,1);
	end

	% if exist('inputSignals','var')
	if ~isempty(inputSignals)
		if isempty(obj.signalPeaksArray)
			disp('Please run modelVarsFromFiles')
			signalPeaks = [];
			signalPeaksArray = [];
		elseif isempty(obj.signalPeaksArray{thisFileNum})
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
				if ~isempty(inputSignals2)
					inputSignals2 = inputSignals2(valid,:);
				end
				signalPeaksArray = {obj.signalPeaksArray{thisFileNum}{valid}};
				% signalPeaks = zeros([obj.nSignals{thisFileNum} obj.nFrames{thisFileNum}]);
				signalPeaks = zeros([length(signalPeaksArray) obj.nFrames{thisFileNum}]);
				for signalNo = 1:length(signalPeaksArray)
					signalPeaks(signalNo,obj.signalPeaksArray{thisFileNum}{signalNo}) = 1;
				end
				% signalPeaks = signalPeaks(valid,:);
			case 'filteredAndRegistered'
				inputSignals = inputSignals(valid,:);
				if ~isempty(inputSignals2)
					inputSignals2 = inputSignals2(valid,:);
				end
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
				% register images based on manual registration if performed

				% register images based on cross session alignment
				globalRegCoords = obj.globalRegistrationCoords.(obj.subjectStr{thisFileNum});
				if ~isempty(globalRegCoords)
					display('registering images')
					% get the global coordinate number based
					% globalRegCoords = globalRegCoords{strcmp(obj.assay{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
					% globalRegCoords = globalRegCoords{strcmp(obj.date{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
					% globalRegCoords = globalRegCoords{strcmp(obj.folderBaseSaveStr{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}))};
                    globalSubjectNo = strcmp(obj.folderBaseSaveStrUnique{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}));
					globalRegCoords = globalRegCoords{globalSubjectNo};
					if ~isempty(globalRegCoords)
						% inputImages = permute(inputImages,[2 3 1]);

						% (R3'*S3'*T3'*R2'*S2'*T2'*R1'*S1'*T1')'
						% T1*S1*R1*T3*S3*R2*T3*S3*R3
						% Where 1, 2, ... indicate matrix for iterations 1,2,... and R, S, T are rotation, skew (shear + scale) and translation matrices, respectively.
						% Translation
						% Rotation
						% Skew

						% Get settings for this one
					 	mcMethod = obj.globalIDStruct.(obj.subjectStr{thisFileNum}).inputOptions.mcMethod;
						registrationFxn = obj.globalIDStruct.(obj.subjectStr{thisFileNum}).inputOptions.registrationFxn;

						for iterationNo = 1:length(globalRegCoords)
							fn=fieldnames(globalRegCoords{iterationNo});
							for i=1:length(fn)
								localCoords = globalRegCoords{iterationNo}.(fn{i});
								% playMovie(inputImages);
								[inputImages, localCoords] = ciapkg.motion_correction.turboregMovie(inputImages,...
									'precomputedRegistrationCooords',localCoords,...
									'mcMethod',mcMethod,...
									'registrationFxn',registrationFxn);
							end
						end
						% inputImages = permute(inputImages,[3 1 2]);
					end
                end
                globalSubjectNo = strcmp(obj.folderBaseSaveStrUnique{thisFileNum},obj.globalIDFolders.(obj.subjectStr{thisFileNum}));
                inputImages = obj.globalIDStruct.(obj.subjectStr{thisFileNum}).inputImages{globalSubjectNo};
			otherwise
				% body
		end
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
	display(['valid: ' num2str(size(valid))])
end