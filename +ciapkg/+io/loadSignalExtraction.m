function [inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = loadSignalExtraction(inputFilePath,varargin)
	% Loads CIAtah-style MAT or NWB files containing signal extraction results.
	% Biafra Ahanonu
	% started: 2021.02.03 [10:53:11]
	% inputs
		% inputFilePath - path to signal extraction output
	% outputs
		% inputImages - 3D or 4D matrix containing cells and their spatial information, format: [x y nCells].
		% inputSignals - 2D matrix containing activity traces in [nCells nFrames] format.
		% infoStruct - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
		% algorithmStr - String of the algorithm name.
		% inputSignals2 - same as inputSignals but for secondary traces an algorithm outputs.

	% changelog
		% 2021.03.10 [18:50:48] - Updated to add support for initial set of cell-extraction algorithms.
	% TODO
		%

	% ========================
	% Struct: name of structures for CIAtah-style outputs.
	options.extractionMethodStructVarname = struct(...
			'PCAICA', 'pcaicaAnalysisOutput',...
			'EM', 'emAnalysisOutput',...
			'CELLMax','cellmaxAnalysisOutput',...
			'EXTRACT', 'extractAnalysisOutput',...
			'CNMF', 'cnmfAnalysisOutput',...
			'CNMFE', 'cnmfeAnalysisOutput',...
			'ROI', 'roiAnalysisOutput'...
		);

	options.extractionMethodStructSaveStr = struct(...
		'pcaicaAnalysis','PCAICA',...
		'emAnalysis','EM',...
		'cellmaxAnalysis','CELLMax',...
		'extractAnalysis','EXTRACT',...
		'cnmfAnalysis','CNMF',...
		'cnmfeAnalysis','CNMFE',...
		'roiAnalysis','ROI'...
	);
	% Name of H5 group for images and signal series in NWB files
	options.nwbGroupImages = '/processing/ophys/ImageSegmentation/PlaneSegmentation';
	options.nwbGroupSignalSeries = '/processing/ophys/Fluorescence/RoiResponseSeries';
	% Int: indicates which trace output to use from 1 = primary trace, 2 = secondary trace, etc.
	options.signalExtractionTraceOutputType = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		inputImages = [];
		inputSignals = [];
		inputSignals2 = [];
		algorithmStr = '';
		infoStruct = struct;

		if iscell(inputFilePath)
			inputFilePath = inputFilePath{1};
		end
		% Return if not a string, return as not appropriate input
		if ~ischar(inputFilePath)
			return;
		end

		[~,~,inputEXT] = fileparts(inputFilePath);
		switch inputEXT
			case '.nwb'
				nwbOpts.groupImages = options.nwbGroupImages;
				nwbOpts.groupSignalSeries = options.nwbGroupSignalSeries;
				[inputImages,inputSignals,infoStruct,algorithmStr] = loadNeurodataWithoutBorders(inputFilePath,'options',nwbOpts);
				return;
			case '.mat'
				% Do nothing, go to the next steps below.
			otherwise
				% Do nothing
		end

		% Get list of variables in the MAT file, use this to determine which algorithm to load.
		variableInfo = who('-file', inputFilePath);

		algList = fieldnames(options.extractionMethodStructVarname);
		algorithm = '';
		for i = 1:length(algList)
			algName = algList{i};
			algMatch = options.extractionMethodStructVarname.(algName);
			matchAlg = any(strcmp(variableInfo,algMatch));
			if matchAlg==1
				algorithm = algName;
			end
		end
		algorithmStr = algorithm;

		switch algorithm
			case 'ROI'
				[inputImages,inputSignals,infoStruct] = subfxnROI(inputFilePath,options);
			case 'PCAICA'
				[inputImages,inputSignals,infoStruct] = subfxnPCAICA(inputFilePath,options);
			case {'EM','CELLMax'}
				[inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCELLMax(inputFilePath,options);
			case 'EXTRACT'
				[inputImages,inputSignals,infoStruct] = subfxnEXTRACT(inputFilePath,options);
			case 'CNMF'
				[inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCNMF(inputFilePath,options);
			case 'CNMFE'
				[inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCNMFE(inputFilePath,options);
			otherwise
				disp('Input MAT file is not recognized or not in CIAtah-style format.')
		end

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
function [inputImages,inputSignals,infoStruct] = subfxnPCAICA(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

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
	if exist('IcaTraces','var')
		inputSignals = IcaTraces;
	end
	if exist('IcaFilters','var')
		% inputImages = IcaFilters;
		inputImages = permute(IcaFilters,[2 3 1]);
	end
end
function [inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCELLMax(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

	% if exist(options.structEMVarname,'var')
	if exist('emAnalysisOutput','var')|exist('cellmaxAnalysisOutput','var')
		if exist('cellmaxAnalysisOutput','var')
			emAnalysisOutput = cellmaxAnalysisOutput;
		end
		inputImages = emAnalysisOutput.cellImages;

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

		switch options.signalExtractionTraceOutputType
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

	end
end
function [inputImages,inputSignals,infoStruct] = subfxnEXTRACT(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

	% if exist(options.structEXTRACTVarname,'var')
	if exist('extractAnalysisOutput','var')
		% inputImages = double(permute(extractAnalysisOutput.filters,[3 1 2]));
		inputImages = double(extractAnalysisOutput.filters);
		% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));
		inputSignals = double(extractAnalysisOutput.traces);
	end
end
function [inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCNMF(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

	% if exist(options.structCNMRVarname,'var')
	if exist('cnmfAnalysisOutput','var')
		% inputImages = double(permute(cnmfAnalysisOutput.extractedImages,[3 1 2]));
		inputImages = double(cnmfAnalysisOutput.extractedImages);
		% inputSignals = double(permute(extractAnalysisOutput.traces, [2 1]));

		switch options.signalExtractionTraceOutputType
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

		% Convert units to relative dF/F for later analysis
		inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages);
		inputSignals2 = normalizeSignalExtractionActivityTraces(inputSignals2,inputImages);
	end
end
function [inputImages,inputSignals,infoStruct,inputSignals2] = subfxnCNMFE(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

	if exist('cnmfeAnalysisOutput','var')
		inputImages = double(cnmfeAnalysisOutput.extractedImages);

		switch options.signalExtractionTraceOutputType
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

		% Convert units to relative dF/F for later analysis
		inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages);
		inputSignals2 = normalizeSignalExtractionActivityTraces(inputSignals2,inputImages);
	end
end
function [inputImages,inputSignals,infoStruct] = subfxnROI(inputFilePath,options)
	infoStruct = struct;
	load(inputFilePath);

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
	if exist('ROItraces','var')
		inputSignals = ROItraces;
	end
end