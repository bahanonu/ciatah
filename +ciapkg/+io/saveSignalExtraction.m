function [success] = saveSignalExtraction(inputImages,inputSignals,signalExtractionMethod,outputFilePath,varargin)
	% Convert signal extraction outputs to CIAtah-style MAT files.
	% Biafra Ahanonu
	% started: 2021.02.02 [14:24:35]
	% inputs
		% Matrix: inputImages - [x y z] matrix
		% Matrix: inputSignals - {1 N} cell with N = number of different signal traces for that algorithm. Make sure each signal trace matrix is in form of [nSignals nFrames].
		% Str: signalExtractionMethod - Name of the signal-extraction method used. Options: CELLMax, PCAICA, CELLMax, EXTRACT, CNMF, CNMFE, ROI.
		% Str: outputFilePath - file path to save MAT file to. This function will automatically add the appropriate suffix and extension.
	% outputs
		% success - alerts user of saving of files was successful.

	% changelog
		% 2021.03.20 [20:35:50] - Adding support for all existing methods.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% Str: Name of the movie that signal extraction was performed on.
	options.movieList = '';
	% Matrix: 2D matrix of [nCells nFrames], secondary input activity trace if needed.
	options.inputSignals2 = [];
	% Struct: name of structures for CIAtah-style outputs.
	options.extractionMethodStructSaveStr = struct(...
		'PCAICA', '_pcaicaAnalysis.mat',...
		'EM', '_emAnalysis.mat',...
		'CELLMax', '_cellmaxAnalysis.mat',...
		'EXTRACT', '_extractAnalysis.mat',...
		'CNMF', '_cnmfAnalysis.mat',...
		'CNMFE', '_cnmfeAnalysis.mat',...
		'ROI', '_roiAnalysis.mat'...
	);
	% Struct: name of structures for CIAtah-style outputs.
	options.extractionMethodStructVarname = struct(...
		'PCAICA', 'pcaicaAnalysisOutput',...
		'EM', 'emAnalysisOutput',...
		'CELLMax', 'cellmaxAnalysisOutput',...
		'EXTRACT', 'extractAnalysisOutput',...
		'CNMF', 'cnmfAnalysisOutput',...
		'CNMFE', 'cnmfeAnalysisOutput',...
		'ROI', 'roiAnalysisOutput'...
	);
	% INTERNAL
	% Str: name of algorithm being analyzed
	options.signalExtractionMethod = '';

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
		success = 0;
		if ~strcmp(signalExtractionMethod,'ROI')
			options.signalExtractionMethod = signalExtractionMethod;
		end

		[filePath,fileName,ext] = fileparts(outputFilePath);

		try
			% Append the expected CIAtah-style suffix and MAT file extension.
			outputFilePath = [filePath filesep fileName options.extractionMethodStructSaveStr.(signalExtractionMethod)];
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end

		switch signalExtractionMethod
			case 'ROI'
				subfxnROI(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			case 'PCAICA'
				subfxnPCAICA(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			case {'EM','CELLMax'}
				subfxnCELLMax(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			case 'EXTRACT'
				subfxnEXTRACT(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			case 'CNMF'
				subfxnCNMF(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			case 'CNMFE'
				subfxnCNMFE(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options);
			otherwise
				disp('Input MAT file is not recognized or not in CIAtah-style format.')
				success = 0;
				return;
		end
		success = 1;
	catch err
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
function subfxnSaveOutput(inputOutputStruct,additonalStruct,outputFilePath,options)
	% Save using that algorithms structure name
	structSaveName = options.extractionMethodStructVarname.(options.signalExtractionMethod);
	tmpStruct.(structSaveName) = inputOutputStruct;
	if ~isempty(additonalStruct)
		tmpStruct.(additonalStruct{1}) = additonalStruct{2};
	end
	% =======
	% save output components
	saveID = {'1'};
	thisDirSaveStr = outputFilePath;
	for i=1:length(saveID)
		savestring = [thisDirSaveStr saveID{i}];
		display(['Saving: ' outputFilePath])
		save(outputFilePath,'-struct', 'tmpStruct','-v7.3');
	end
end
function subfxnROI(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)
	roiAnalysisOutput.filters = inputImages;
	roiAnalysisOutput.traces = inputSignals;
	roiAnalysisOutput.signalExtractionMethod = options.signalExtractionMethod;

	options.signalExtractionMethod = signalExtractionMethod;

	subfxnSaveOutput(roiAnalysisOutput,[],outputFilePath,options);
end
function subfxnPCAICA(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)
	%

	imageSaveDimOrder = 'xyz';
	traceSaveDimOrder = '[nComponents frames]';

	pcaicaAnalysisOutput.IcaFilters = inputImages;
	pcaicaAnalysisOutput.IcaTraces = inputSignals;

	pcaicaAnalysisOutput.imageSaveDimOrder = imageSaveDimOrder;
	pcaicaAnalysisOutput.traceSaveDimOrder = traceSaveDimOrder;
	pcaicaAnalysisOutput.nPCs = NaN;
	pcaicaAnalysisOutput.nICs = size(inputImages,3);
	pcaicaAnalysisOutput.time.startTime = NaN; %startTime;
	pcaicaAnalysisOutput.time.endTime = NaN; %toc(startTime);
	pcaicaAnalysisOutput.time.dateTime = NaN; %datestr(now,'yyyymmdd_HHMM','local');
	pcaicaAnalysisOutput.movieList = options.movieList;
	pcaicaAnalysisOutput.IcaInfo = []; % IcaInfo;

	subfxnSaveOutput(pcaicaAnalysisOutput,[],outputFilePath,options);
end
function subfxnCELLMax(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)
	%
	currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');

	cellmaxAnalysisOutput.movieFilename = options.movieList;

	cellmaxAnalysisOutput.cellImages = inputImages;
	cellmaxAnalysisOutput.scaledProbability = inputSignals;
	cellmaxAnalysisOutput.cellTraces = options.inputSignals2;

	cellmaxAnalysisOutput.scaledProbabilityDff = [];
	cellmaxAnalysisOutput.cellTracesDff = [];

	cellmaxAnalysisOutput.versionCellmax = '';
	cellmaxAnalysisOutput.runCompletedNoErrors = 1;
	cellmaxAnalysisOutput.movieDims = NaN;
	cellmaxAnalysisOutput.centroids = [];
	cellmaxAnalysisOutput.CELLMaxoptions = struct;
	cellmaxAnalysisOutput.filtTraces = [];
	cellmaxAnalysisOutput.eventTimes = {};
	cellmaxAnalysisOutput.eventOptions = struct;
	cellmaxAnalysisOutput.runtime = NaN;
	cellmaxAnalysisOutput.runtimeWithIO = NaN;
	cellmaxAnalysisOutput.options = struct;

	% Secondary options structure
	emOptions.CELLMaxoptions.numSignalsDetected = size(inputSignals,1);

	emOptions.CELLMaxoptions.sqSizeX = [];
	emOptions.CELLMaxoptions.sqSizeY = [];
	emOptions.versionCellmax = NaN;
	emOptions.time.startTime = NaN;
	emOptions.time.endTime = NaN;
	emOptions.time.cellmaxRuntime = NaN;
	emOptions.time.cellmaxRuntime = NaN;

	subfxnSaveOutput(cellmaxAnalysisOutput,{'emOptions',emOptions},outputFilePath,options);
end
function subfxnEXTRACT(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)

	extractAnalysisOutput.filters = inputImages;
	% MAKE SURE TRANSPOSED
	disp('Note: make sure EXTRACT traces are transposed to [# of cells x # of frames] instead of EXTRACT default format [# of frames x # of cells]')
	extractAnalysisOutput.traces = inputSignals;

	extractAnalysisOutput.file = options.movieList;

	extractAnalysisOutput.info = struct;
	extractAnalysisOutput.config = struct;
	extractAnalysisOutput.info = struct;

	% Remove the large summary field since takes up unnecessary space
	extractAnalysisOutput.info.summary = [];
	extractAnalysisOutput.userInputConfig = struct;

	% for backwards compatibility
	extractAnalysisOutput.opts = struct;
	extractAnalysisOutput.time.startTime = NaN;
	extractAnalysisOutput.time.endTime = NaN;
	extractAnalysisOutput.time.totalTime = NaN;

	subfxnSaveOutput(extractAnalysisOutput,{},outputFilePath,options);
end
function subfxnCNMF(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)
	cnmfAnalysisOutput.extractedImages = inputImages;
	% correct for df/f output problems
	cnmfAnalysisOutput.extractedSignals = inputSignals;
	cnmfAnalysisOutput.extractedSignalsEst = options.inputSignals2;

	% add parameters and extractions to output structure
	cnmfAnalysisOutput.params.K = NaN;
	cnmfAnalysisOutput.params.tau = NaN;
	cnmfAnalysisOutput.params.p = NaN;
	cnmfAnalysisOutput.datasetComponentProperties_P = NaN;
	cnmfAnalysisOutput.movieList = options.movieList;

	cnmfAnalysisOutput.extractedSignalsBackground = NaN;
	cnmfAnalysisOutput.extractedSignalsType = 'dfof';
	cnmfAnalysisOutput.extractedSignalsEstType = 'model';
	cnmfAnalysisOutput.extractedPeaks = NaN;
	cnmfAnalysisOutput.extractedPeaksEst = NaN;
	cnmfAnalysisOutput.cnmfOptions = struct;
	cnmfAnalysisOutput.time.datetime = '';
	cnmfAnalysisOutput.time.runtimeWithMovie = NaN;
	cnmfAnalysisOutput.time.runtimeSansMovie = NaN;

	cnmfAnalysisOutput.time.startTime = NaN;
	cnmfAnalysisOutput.time.endTime = NaN;
	cnmfAnalysisOutput.time.totalTime = NaN;

	cnmfAnalysisOutput.versionOutput = 'current';

	subfxnSaveOutput(cnmfAnalysisOutput,{},outputFilePath,options);
end
function subfxnCNMFE(inputImages,inputSignals,signalExtractionMethod,outputFilePath,options)
	cnmfeAnalysisOutput.extractedImages = inputImages;
	cnmfeAnalysisOutput.extractedSignals = inputSignals;
	cnmfeAnalysisOutput.extractedSignalsEst = options.inputSignals2;

	cnmfeAnalysisOutput.success = 1;
	cnmfeAnalysisOutput.params = NaN;
	cnmfeAnalysisOutput.movieList = options.movieList;
	% cnmfeAnalysisOutput.extractedImages = reshape(full(results.A),[size(results.P.sn) size(results.C,1)]);

	cnmfeAnalysisOutput.extractedSignalsType = 'model';
	cnmfeAnalysisOutput.extractedSignalsEstType = 'dfof';
	cnmfeAnalysisOutput.extractedPeaks = [];
	cnmfeAnalysisOutput.Cn = [];
	cnmfeAnalysisOutput.P = [];

	cnmfeAnalysisOutput.time.startTime = NaN;
	cnmfeAnalysisOutput.time.endTime = NaN;
	cnmfeAnalysisOutput.time.totalTime = NaN;
	cnmfeAnalysisOutput.obj.cnmfeOptions = struct;

	subfxnSaveOutput(cnmfeAnalysisOutput,{},outputFilePath,options);
end