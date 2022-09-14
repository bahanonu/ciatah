function [cnmfAnalysisOutput] = computeCnmfSignalExtractionPatch(inputMovie,numExpectedComponents,varargin)
	% Wrapper function for CNMF, update for most recent versions.
	% Building off of demo_script.m in CNMF github repo
	% Most recent commit tested on: https://github.com/epnev/ca_source_extraction/commit/187bbdbe66bca466b83b81861b5601891a95b8d1
	% https://github.com/epnev/ca_source_extraction/blob/master/demo_script_class.m
	% Biafra Ahanonu
	% started: 2019.03.11
	% inputs
		% inputMovie - a string or a cell array of strings pointing to the movies to be analyzed (recommended). Else, [x y t] matrix where t = frames.
		% numExpectedComponents - number of expected components
	% outputs
		% cnmfAnalysisOutput - structure containing extractedImages and extractedSignals along with input parameters to the algorithm
	% READ BEFORE RUNNING
		% Get CVX from http://cvxr.com/cvx/doc/install.html
		% Run the below commands in Matlab after unzipping
		% cvx_setup
		% cvx_save_prefs (permanently stores settings)

	% changelog
		% 2016.06.20 - updated to keep in line with recent changes to CNMF functions
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% MAIN PARAMETERS
	% turn on parallel
	options.nonCNMF.parallel = 1;
	% size of each patch along each dimension (optional, default: [32,32])
	options.nonCNMF.patch_size = [128,128];
	% amount of overlap in each dimension (optional, default: [4,4])
	options.nonCNMF.overlap = [16,16];
	% initialization parameters
	% Standard deviation of Gaussian kernel for initialization
	options.otherCNMF.tau = 4;
	% Order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
	options.otherCNMF.p = 2;
	% ===
	options.ssub = 1;  % Spatial down-sampling factor (scalar >= 1)  1
	options.tsub = 1;  % Temporal down-sampling factor (scalar >= 1)  1
	options.nb = 1;  % Number of background components per patch (positive integer)  1
	options.gnb = 3;  % Number of global background components (positive integer)  1
	options.gSig = 2*options.otherCNMF.tau+1;  % Size of Gaussian kernel  2*tau+1
	options.merge_thr = 0.85; % Merging threshold (positive between 0  and 1)  0.85
	% imaging frame rate in Hz (defaut: 30)
	options.fr = 30;
	% create a memory mapped file if it is not provided in the input (default: false)
	options.create_memmap = false;
	options.cnn_thr = 0.2;
	options.patch_space_thresh = 0.25;
	options.min_SNR = 1;
	% ================================================
	% NOT USED IN THIS FUNCTION CURRENTLY
	% for loading movie
	% run raw correction
	options.nonCNMF.dfofCorrect = 1;
	% run only initialization algorithm
	options.nonCNMF.onlyRunInitialization = 0;
	% list of frames to load in movie
	options.nonCNMF.frameList = [];
	% whether to load movie as double
	options.nonCNMF.convertToDouble = 0;
	% HDF5 dataset name
	options.nonCNMF.inputDatasetName = '/1';
	% HDF5 dataset name
	options.nonCNMF.showFigures = 1;
	% whether to use the old set of initialization parameters
	options.nonCNMF.useOldInitializationSetParams = 0;
	% path to cvx_setup.m
	options.nonCNMF.cvxPath = [];
	% allow users to initialize with their own components (images) and traces
	options.nonCNMF.initializeComponents = [];
	options.nonCNMF.initializeTraces = [];
	% movie parameters (automatically set later)
	options.d1 = []; % rows
	options.d2 = []; % columns
	% initialization parameters
	% should display merging
	options.otherCNMF.display_merging = 0;
	% preprocess_data.m
	options.flag_g = 0; % Flag for computing global time constants  0
	options.split_data = 0;  % Flag for computing noise values sequentially for memory reasons
	% initialize_components.m
	options.save_memory = 0;  % Perform spatial filter in patches sequentially to save memory (binary)  0 (not needed, use subsampling)
	options.maxIter = 5;  % Maximum number of HALS iterations  5
	options.bSiz = 3;  % Expansion factor for HALS localized updates  3
	options.snmf_max_iter = 100;  % Maximum number of sparse NMF iterations  100
	options.err_thr = 1e-4; % Relative change threshold for stopping sparse_NMF  1e-4
	options.eta = 1; % Weight on frobenius norm of temporal components * max(Y)^2  1
	options.beta = 0.5; % Weight on squared l1 norm of spatial components  0.5
	% update_spatial_components.m
	% options.use_parallel = 1; % Flag for solving optimization problem in parallel (binary)  1 (if parallel toolbox exists)
	options.spatial_parallel = 1; % update pixels in parallel (default: 1 if present)
	options.temporal_parallel = 1; % flag for parallel updating of temporal components (default: true if present)
	options.search_method = 'ellipse'; % Method for computing search locations (‘ellipse’ or ‘binary’)  ‘ellipse’
	options.min_size = 3; % Minimum size of ellipse axis (positive, real)  3
	options.max_size = 8; % Maximum size of ellipse axis (positive, real)  8
	options.dist = 3; % Ellipse expansion factor (positive, real)  3
	options.se = strel('disk',4,0); % Morphological element for method ‘dilate’ (binary image)  strel(‘disk’,4,0)
	options.nrgthr = 0.99; % Energy threshold (positive between 0 and 1)  0.99
	options.clos_op = strel('square',3); % Morphological closing operator for post-processing (binary image)  strel(‘square’,3)
	options.medw = [3,3]; % Size of 2-d median filter (2 x 1 array of positive integers)  [3,3]
	% update_temporal_components.m
	options.deconv_method = 'constrained_foopsi'; % Deconvolution method (see above for the 5 choices)  ‘constrained_foopsi’
	options.restimate_g = 1; % Flag for re-estimating time constants of each neuron (binary)  1
	options.temporal_iter = 2; % Max number of outer iterations of the block-coordinate descent (positive integer)  2
	% constrained_foopsi.m
	% options.p = 2; %Order of AR system (positive integer)  2
	options.method = 'cvx'; %Method for solving the CD problem (see above for options)  ‘cvx’
	options.bas_nonneg = 1; %Option for setting b nonnegative, otherwise b >= min(y) (binary)  1 (b>=0)
	options.noise_range = [0.25,0.5]; %Range of normalized frequencies over which to average PSD (2 x1 vector)  [0.25,0.5]
	options.noise_method = 'logmexp'; %Method to average PSD to reduce variance  ‘logmexp’
	options.lags = 5; %Number of autocorrelation lags to be used for estimating g (positive integer)  5
	options.resparse = 0; %Number of times to resparse obtained solution (nonnegative integer)  0 (no re-sparsening)
	options.fudge_factor = 0.98; %Multiplicative bias correction for g (positive between 0 and 1). Note: Slight changes can have large effects. Typically stay within [0.95-1].  1 (no correction)
	% ================================================

	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%    eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	options.p = options.otherCNMF.p;
	% ========================
	manageParallelWorkers('parallel',options.nonCNMF.parallel);
	% ========================
	% if cvx is not in the path, ask user for file
	if isempty(options.nonCNMF.cvxPath)
		if isempty(which('cvx_begin'))
			display('Dialog box: select cvx_setup.m.')
			[filePath,folderPath,~] = uigetfile(['*.*'],'select cvx_setup.m');
			run([folderPath filesep filePath]);
		end
	else
		run(options.nonCNMF.cvxPath);
	end
	startTimeWithMovie = tic;
	% re-initialize any options that are dependent on other options
	options.gSig = 2*options.otherCNMF.tau+1;  % Size of Gaussian kernel  2*tau+1

	% create output
	cnmfAnalysisOutput.success = 0;

	% get the movie
	% if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
	%     movieList = inputMovie;
	%     Y = loadMovieList(inputMovie,'convertToDouble',options.nonCNMF.convertToDouble,'frameList',options.nonCNMF.frameList,'inputDatasetName',options.nonCNMF.inputDatasetName,'treatMoviesAsContinuous',1);
	%     clear inputMovie;
	% else
	%     movieList = '';
	%     Y = inputMovie;
	%     clear inputMovie;
	% end
	% filename = '/Users/epnevmatikakis/Documents/Ca_datasets/Neurofinder/neurofinder.02.00/images/neurofinder0200_rig.tif';
			% path to file (assumed motion corrected)

	is_memmaped = options.create_memmap;        % choose whether you want to load the file in memory or not

	%% create object and load file

	CNM = CNMF();

	if ischar(inputMovie)
		fprintf('Loading: %s\n',inputMovie);
	elseif iscell(inputMovie)
		cellfun(@(x) fprintf('Loading: %s\n',x),inputMovie,'UniformOutput',false);
	end
	if is_memmaped
		CNM.readFile(inputMovie,is_memmaped);
	else
		% CNM.readFile(inputMovie,is_memmaped,1,2000); % load only a part of the file due to memory
		CNM.readFile(inputMovie,is_memmaped); % load only a part of the file due to memory
	end
	startTimeSansMovie = tic;

	%% set options and create patches

	% patch_size = [32,32];    % size of each patch along each dimension (optional, default: [32,32])
	patch_size = options.nonCNMF.patch_size; % size of each patch along each dimension (optional, default: [32,32])
	% overlap = [6,6];         % amount of overlap in each dimension (optional, default: [4,4])
	overlap = options.nonCNMF.overlap;         % amount of overlap in each dimension (optional, default: [4,4])
	% K = 10;                  % number of components to be found
	K = numExpectedComponents; % number of components to be found
	gSig = options.gSig;                % std of gaussian kernel (size of neuron)
	p = options.otherCNMF.p;                   % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
	% gnb = 3;                 % order of background
	gnb = options.gnb;
	% merge_thr = 0.8;         % merging threshold
	merge_thr = options.merge_thr;         % merging threshold

	optionsCNMF = CNMFSetParms(...
		'd1',CNM.dims(1),'d2',CNM.dims(2),...
		'search_method','dilate',...                % search locations when updating spatial components
		'deconv_method','constrained_foopsi',...    % activity deconvolution method
		'nb',options.nb,...                                  % number of background components per patch
		'gnb',options.gnb,...                               % number of global background components
		'ssub',options.ssub,...
		'tsub',options.tsub,...
		'p',p,...                                   % order of AR dynamics
		'merge_thr',options.merge_thr,...                   % merging threshold
		'gSig',options.gSig,...
		'spatial_method','regularized',...
		'cnn_thr',options.cnn_thr,...
		'patch_space_thresh',options.patch_space_thresh,...
		'min_SNR',options.min_SNR,...
		'fr',options.fr);

	CNM.optionsSet(optionsCNMF);
	CNM.gnb = gnb;
	CNM.K = K;
	CNM.patch_size = patch_size;                % size of each patch along each dimension (optional, default: [32,32])
	CNM.overlap = overlap;                      % amount of overlap in each dimension (optional, default: [4,4])
	disp('Creating patches...')
	CNM.createPatches();                        % create patches

	disp('Fitting patches...')
	%% fit all patches
	CNM.fitPatches();

	%% component classification

	CNM.evaluateComponents();   % evaluate spatial components based on their correlation with the data
	CNM.CNNClassifier('')       % evaluate spatial components with the CNN classifier
	CNM.eventExceptionality();  % evaluate traces
	CNM.keepComponents();       % keep the components that are above certain thresholds

	%% repeat processing
	disp('Updating components...')
	CNM.updateSpatial();
	CNM.updateTemporal();
	CNM.extractDFF();            % extract DF/F values.

	%% do some plotting
	% figure;
	% CNM.correlationImage();
	% CNM.plotContours();
	% CNM.plotComponentsGUI();     % display all components

	[cnmfAnalysisOutput] = organizeStandardOutput();

	function [cnmfAnalysisOutput] = organizeStandardOutput()
		% extract out images and organize them in standard format
		nSignals = size(CNM.A,2);
		d1 = CNM.dims(1);
		d2 = CNM.dims(2);

		extractedImages = zeros([d1 d2 nSignals]);
		% nSignals
		for signalNo = 1:nSignals
			extractedImages(:,:,signalNo) = reshape(CNM.A(:,signalNo),d1,d2);
		end

		% store background component
		C_df_or_background = CNM.C_df((end-options.gnb):end,:);
		% S_df_or = CNM.S;

		% add parameters and extractions to output structure
		cnmfAnalysisOutput.params.K = CNM.K;
		cnmfAnalysisOutput.params.tau = options.otherCNMF.tau;
		cnmfAnalysisOutput.params.p = options.otherCNMF.p;
		cnmfAnalysisOutput.datasetComponentProperties_P = CNM.P;
		if ischar(inputMovie)|iscell(inputMovie)
			cnmfAnalysisOutput.movieList = inputMovie;
		else
			cnmfAnalysisOutput.movieList = [];
		end
		cnmfAnalysisOutput.extractedImages = extractedImages;
		% correct for df/f output problems
		cnmfAnalysisOutput.extractedSignals = full(CNM.C_df);
		% if nanmean(C_df(:))<0&options.nonCNMF.dfofCorrect==1
		%     cnmfAnalysisOutput.extractedSignals = -1*full(C_df);
		% else
		%     cnmfAnalysisOutput.extractedSignals = full(C_df);
		% end
		cnmfAnalysisOutput.extractedSignalsBackground = full(C_df_or_background);
		cnmfAnalysisOutput.extractedSignalsType = 'dfof';
		cnmfAnalysisOutput.extractedSignalsEst = CNM.C;
		cnmfAnalysisOutput.extractedSignalsEstType = 'model';
		cnmfAnalysisOutput.extractedPeaks = CNM.S;
		cnmfAnalysisOutput.extractedPeaksEst = CNM.S;
		cnmfAnalysisOutput.cnmfOptions = optionsCNMF;
		cnmfAnalysisOutput.time.datetime = datestr(now,'yyyy_mm_dd_HHMM','local');
		cnmfAnalysisOutput.time.runtimeWithMovie = toc(startTimeWithMovie);
		cnmfAnalysisOutput.time.runtimeSansMovie = toc(startTimeSansMovie);
		% if verLessThan('matlab','8.4')
		%     % R2014a or earlier
		%     cnmfAnalysisOutput.time.datetime = datestr(now,'yyyymmdd_HHMM','local');
		% else
		%     % R2014b or later
		%     cnmfAnalysisOutput.time.datetime = datetime;
		% end
		cnmfAnalysisOutput.success = 1;
	end
end