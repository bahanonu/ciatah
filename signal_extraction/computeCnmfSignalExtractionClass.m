function [cnmfAnalysisOutput] = computeCnmfSignalExtractionClass(inputMovie,numExpectedComponents,varargin)
    % Wrapper function for CNMF, update for most recent versions.
    % Building off of demo_script.m in CNMF github repo
    % Most recent commit tested on: https://github.com/epnev/ca_source_extraction/commit/187bbdbe66bca466b83b81861b5601891a95b8d1
    % https://github.com/epnev/ca_source_extraction/blob/master/demo_script_class.m
    % Biafra Ahanonu
    % started: 2019.03.14 [10:53:12]
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
        % 2019.03.14 [16:48:13] Converted to using CNMF class since the demo script without using the class appears to have issues and is producing incorrect dF/F results
    % TODO
        %

    %========================
    % for loading movie
    % turn on parallel
    options.nonCNMF.parallel = 1;
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
    % Binary: 1 = classify components,
    options.nonCNMF.classifyComponents = 1;
    % Binary: 1 = plot contours and make components GUI at the end
    options.nonCNMF.plot_contours_components = 1;
    % Binary: 1 = plot merged components
    options.nonCNMF.display_merging = 1;

    % allow users to initialize with their own components (images) and traces
    options.nonCNMF.initializeComponents = [];
    options.nonCNMF.initializeTraces = [];

    % movie parameters (automatically set later)
    options.d1 = []; % rows
    options.d2 = []; % columns

    % initialization parameters
    % Standard deviation of Gaussian kernel for initialization
    options.otherCNMF.tau = 4;
    % Order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    options.otherCNMF.p = 2;
    % should display merging
    options.otherCNMF.display_merging = 0;
    % initialization method ('greedy','greedy_corr','sparse_NMF','HALS') (default: 'greedy')
    options.init_method = 'greedy';

    % preprocess_data.m
    options.flag_g = 0; % Flag for computing global time constants  0
    options.split_data = 0;  % Flag for computing noise values sequentially for memory reasons

    % initialize_components.m
    options.ssub = 1;  % Spatial down-sampling factor (scalar >= 1)  1
    options.tsub = 2;  % Temporal down-sampling factor (scalar >= 1)  1
    options.nb = 1;  % Number of background components (positive integer)
    options.gnb = 3;  % Number of global background components (positive integer)  1
    options.gSig = 2*options.otherCNMF.tau+1;  % Size of Gaussian kernel  2*tau+1
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
    % options.search_method = 'dilate'; % Method for computing search locations (‘ellipse’ or ‘binary’)  ‘ellipse’
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

    % merge_components.m
    options.merge_thr = 0.85; % Merging threshold (positive between 0  and 1)  0.85

    % imaging frame rate in Hz (defaut: 30)
    options.fr = 30;
    % create a memory mapped file if it is not provided in the input (default: false)
    options.create_memmap = false;

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

    if ~isempty(options.nonCNMF.initializeComponents)
        % Force to be dilate method to get around eigs NaN/Inf issue in determine_search_location
        options.search_method = 'dilate';
    end

    % create output
    cnmfAnalysisOutput.success = 0;

    % get the movie
    inputMovieOriginal = inputMovie;
    if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
        movieList = inputMovie;
        Y = loadMovieList(inputMovie,'convertToDouble',options.nonCNMF.convertToDouble,'frameList',options.nonCNMF.frameList,'inputDatasetName',options.nonCNMF.inputDatasetName,'treatMoviesAsContinuous',1);
        clear inputMovie;
    else
        movieList = '';
        Y = inputMovie;
        clear inputMovie;
    end
    Y(isnan(Y)) = 0;
    startTimeSansMovie = tic;
    % Y = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1);

    % nam = 'demoMovie.tif';          % insert path to tiff stack here
    % sframe=1;                       % user input: first frame to read (optional, default 1)
    % num2read=2000;                  % user input: how many frames to read   (optional, default until the end)
    % Y = bigread2(nam,sframe,num2read);

    %Y = Y - min(Y(:));
    % if ~isa(Y,'double');    Y = double(Y);  end         % convert to single
    % if ~isa(Y,'single');    Y = single(Y);  end         % convert to single

    % [d1,d2,T] = size(Y);                                % dimensions of dataset
    % d = d1*d2;                                          % total number of pixels

    %% Set parameters

    CNM = CNMF;                                     % contruct CNMF object

    K = numExpectedComponents; % number of components to be found
    tau = options.otherCNMF.tau; % std of gaussian kernel (size of neuron)
    p = options.otherCNMF.p; % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    merge_thr = options.merge_thr; % merging threshold

    % cnmfOptions = CNMFSetParms(...
    %     'p',2,...                                   % order of AR dynamics
    %     'gSig',5,...                                % half size of neuron
    %     'merge_thr',0.80,...                        % merging threshold
    %     'nb',2,...                                  % number of background components
    %     'min_SNR',3,...                             % minimum SNR threshold
    %     'space_thresh',0.5,...                      % space correlation threshold
    %     'cnn_thr',0.2...                            % threshold for CNN classifier
    %     );

        % 'd1',d1,'d2',d2,...                         % dimensions of datasets
    cnmfOptions = CNMFSetParms(...
        'search_method','dilate','dist',3,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'temporal_iter',2,...                       % number of block-coordinate descent steps
        'p',options.p,...
        'init_method',options.init_method,...
        'flag_g',options.flag_g,...
        'split_data',options.split_data,...
        'ssub',options.ssub,...
        'tsub',options.tsub,...
        'nb',options.nb,...
        'gSig',options.gSig,...
        'save_memory',options.save_memory,...
        'maxIter',options.maxIter,...
        'bSiz',options.bSiz,...
        'snmf_max_iter',options.snmf_max_iter,...
        'err_thr',options.err_thr,...
        'eta',options.eta,...
        'beta',options.beta,...
        'spatial_parallel',options.spatial_parallel,...
        'temporal_parallel',options.temporal_parallel,...
        'search_method',options.search_method,...
        'min_size',options.min_size,...
        'max_size',options.max_size,...
        'dist',options.dist,...
        'se',options.se,...
        'nrgthr',options.nrgthr,...
        'clos_op',options.clos_op,...
        'medw',options.medw,...
        'deconv_method',options.deconv_method,...
        'restimate_g',options.restimate_g,...
        'temporal_iter',options.temporal_iter,...
        'method',options.method,...
        'bas_nonneg',options.bas_nonneg,...
        'noise_range',options.noise_range,...
        'noise_method',options.noise_method,...
        'lags',options.lags,...
        'resparse',options.resparse,...
        'fudge_factor',options.fudge_factor,...
        'fr',options.fr,...
        'create_memmap',options.create_memmap,...
        'merge_thr',options.merge_thr...
        );
    %% Data pre-processing

    %% load the dataset and create the object
    CNM.readFile(Y);                         % insert path to file here
    CNM.optionsSet(cnmfOptions);                        % setup the options structure

    %% Process the dataset

    CNM.preprocess;             % preprocessing (compute some quantities)

    %% fast initialization of spatial components using greedyROI and HALS
    if isempty(options.nonCNMF.initializeComponents)
        CNM.initComponents(K);      % initialization
    else
        disp('Using user input initialization components...')
        % initComp = thresholdImages(options.nonCNMF.initializeComponents,'threshold',0.1);
        % initComp = normalizeMovie(initComp,'normalizationType','imfilterSmooth','blurRadius',5,'imfilterType','disk');
        % initComp = normalizeMovie(initComp,'normalizationType','imfilterSmooth','blurRadius',5);
        initComp = normalizeMovie(normalizeMovie(thresholdImages(options.nonCNMF.initializeComponents,'threshold',0.2),'normalizationType','medianFilter'),'normalizationType','zeroToOne');
        % Use size invariant properties to remove irrelevant signals
        imageProps = computeImageFeatures(initComp,'addedFeatures',1,'makePlots',0);
        filterIdx = imageProps.Eccentricity~=0&imageProps.Eccentricity<0.995&imageProps.Orientation~=0;
        initComp = initComp(:,:,filterIdx);
        clear imageProps;
        % initComp = options.nonCNMF.initializeComponents;
        initComp(isnan(initComp)) = 0;
        initComp(isinf(initComp)) = 0;

        % Place into class
        CNM.A = sparse(double(reshape(initComp,[CNM.dims(1)*CNM.dims(2) size(initComp,3)])));
        CNM.C = [double(options.nonCNMF.initializeTraces(filterIdx,:))];
        CNM.C(CNM.C<0) = 0;
        bin = double(initComp(:,:,end));
        CNM.b = [bin(:)]; clear bin;
        CNM.f = [options.nonCNMF.initializeTraces(end,:)];
        ndOriginal = CNM.nd;
        CNM.nd = 2;
        CNM.COM();
        CNM.nd = ndOriginal;
        clear initComp ndOriginal filterIdx;
    end

    CNM.plotCenters()           % plot center of ROIs detected during initialization
    CNM.updateSpatial();        % update spatial components
    CNM.updateTemporal(0);      % update temporal components (do not deconvolve at this point)

    %% component classification

    if options.nonCNMF.classifyComponents==1
        CNM.evaluateComponents();   % evaluate spatial components based on their correlation with the data
        CNM.CNNClassifier('')       % evaluate spatial components with the CNN classifier
        CNM.eventExceptionality();  % evaluate traces
        CNM.keepComponents();       % keep the components that are above certain thresholds
    else
        % CNM.keep_cnn = true(size(CNM.A,2),1);
        % CNM.val_cnn = ones(size(CNM.A,2),1);
    end

    %% merge found components
    CNM.merge();

    display_merging = options.nonCNMF.display_merging; % flag for displaying merging example
    if options.nonCNMF.showFigures==1&&display_merging==1
        CNM.displayMerging();
    end

    %% repeat processing

    CNM.updateSpatial();
    CNM.updateTemporal();
    CNM.extractDFF();           % extract DF/F values.

    disp('Organizing output struct...')
    [cnmfAnalysisOutput] = organizeStandardOutput();

    try
        if options.nonCNMF.showFigures==1&&options.nonCNMF.plot_contours_components==1

            figure;
            CNM.plotContours();
            CNM.plotComponentsGUI();     % display all components

            % figure;
            % [Coor,json_file] = plot_contours(A_or,Cn,cnmfOptions,1); % contour plot of spatial footprints
            %savejson('jmesh',json_file,'filename');        % optional save json file with component coordinates (requires matlab json library)

            %% display components

            % plot_components_GUI(Yr,A_or,C_or,b2,f2,Cn,cnmfOptions);

            %% make movie

            % make_patch_video(A_or,C_or,b2,f2,Yr,Coor,options)
        end
    catch err
        disp(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        disp(repmat('@',1,7))
    end

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
        if ischar(inputMovieOriginal)|iscell(inputMovieOriginal)
            cnmfAnalysisOutput.movieList = inputMovieOriginal;
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
        cnmfAnalysisOutput.cnmfOptions = cnmfOptions;
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