function [cnmfAnalysisOutput] = computeCnmfSignalExtraction_v2(inputMovie,numExpectedComponents,varargin)
	% Wrapper function for CNMF, update for most recent versions.
	% Building off of demo_script.m in CNMF github repo
	% Most recent commit tested on: https://github.com/epnev/ca_source_extraction/commit/187bbdbe66bca466b83b81861b5601891a95b8d1
	% https://github.com/epnev/ca_source_extraction/blob/master/demo_script_class.m
	% Biafra Ahanonu
	% started: 2016.01.20
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
	options.nb = 1;  % Number of background components (positive integer)  1
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
	if ~isa(Y,'single');    Y = single(Y);  end         % convert to single

	[d1,d2,T] = size(Y);                                % dimensions of dataset
	d = d1*d2;                                          % total number of pixels

	%% Set parameters

	K = numExpectedComponents; % number of components to be found
	tau = options.otherCNMF.tau; % std of gaussian kernel (size of neuron)
	p = options.otherCNMF.p; % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
	merge_thr = options.merge_thr; % merging threshold

	cnmfOptions = CNMFSetParms(...
		'd1',d1,'d2',d2,...                         % dimensionality of the FOV
		'p',p,...                                   % order of AR dynamics
		'gSig',tau,...                              % half size of neuron
		'merge_thr',0.80,...                        % merging threshold
		'nb',2,...                                  % number of background components
		'min_SNR',3,...                             % minimum SNR threshold
		'space_thresh',0.5,...                      % space correlation threshold
		'cnn_thr',0.2...                            % threshold for CNN classifier
		);

	cnmfOptions = CNMFSetParms(...
		'd1',d1,'d2',d2,...                         % dimensions of datasets
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

	[P,Y] = preprocess_data(Y,p);
	%% fast initialization of spatial components using greedyROI and HALS

	% [Ain,Cin,bin,fin,center] = initialize_components(Y,K,tau,cnmfOptions,P);  % initialize
	%% fast initialization of spatial components using greedyROI and HALS
	if isempty(options.nonCNMF.initializeComponents)
		[Ain,Cin,bin,fin,center] = initialize_components(Y,K,tau,cnmfOptions,P);
	else
		disp('Using user input initialization components...')
		% initComp = thresholdImages(options.nonCNMF.initializeComponents,'threshold',0.1);
		% initComp = normalizeMovie(initComp,'normalizationType','imfilterSmooth','blurRadius',5,'imfilterType','disk');
		% initComp = normalizeMovie(initComp,'normalizationType','imfilterSmooth','blurRadius',5);
		initComp = normalizeMovie(thresholdImages(options.nonCNMF.initializeComponents,'threshold',0.2),'normalizationType','medianFilter');
		% Use size invariant properties to remove irrelevant signals
		imageProps = computeImageFeatures(initComp,'addedFeatures',1,'makePlots',0);
		initComp(:,:,imageProps.Eccentricity~=0&imageProps.Orientation~=0);
		clear imageProps;
		% initComp = options.nonCNMF.initializeComponents;
		initComp(isnan(initComp)) = 0;
		initComp(isinf(initComp)) = 0;
		Ain = sparse(double(reshape(initComp,[d size(initComp,3)])));
		Cin = [double(options.nonCNMF.initializeTraces)];
		bin = double(initComp(:,:,end));
		bin = [bin(:)];
		fin = [options.nonCNMF.initializeTraces(end,:)];
		center = [];
		clear initComp;
	end

	% display centers of found components
	Cn =  correlation_image(Y); %reshape(P.sn,d1,d2);  %max(Y,[],3); %std(Y,[],3); % image statistic (only for display purposes)
	if options.nonCNMF.showFigures==1&&~isempty(center)
		figure;imagesc(Cn);
			axis equal; axis tight; hold all;
			scatter(center(:,2),center(:,1),'mo');
			title('Center of ROIs found from initialization algorithm');
			drawnow;
	end

	%% manually refine components (optional)
	if options.nonCNMF.showFigures==1&&~isempty(center)
		refine_components = false;  % flag for manual refinement
		if refine_components
			[Ain,Cin,center] = manually_refine_components(Y,Ain,Cin,center,Cn,tau,cnmfOptions);
		end
	end

	%% update spatial components
	Yr = reshape(Y,d,T);
	[A,b,Cin] = update_spatial_components(Yr,Cin,fin,[Ain,bin],P,cnmfOptions);

	%% update temporal components
	P.p = 0;    % set AR temporarily to zero for speed
	[C,f,P,S,YrA] = update_temporal_components(Yr,A,b,Cin,fin,P,cnmfOptions);

	%% classify components
	if options.nonCNMF.classifyComponents==1
		display('classifying components')
		[ROIvars.rval_space,ROIvars.rval_time,ROIvars.max_pr,ROIvars.sizeA,keep] = classify_components(Y,A,C,b,f,YrA,cnmfOptions);
		keep = logical(keep+1);
		A_keep = A(:,keep);
		C_keep = C(keep,:);
	else
		disp('Not classifying components')
		A_keep = A;
		C_keep = C;
	end

	%% merge found components
	% display(repmat('@',1,7))
	disp('Merging components as needed...')
	[Am,Cm,K_m,merged_ROIs,Pm,Sm] = merge_components(Yr,A_keep,b,C_keep,f,P,S,cnmfOptions);

	%%
	display_merging = options.nonCNMF.display_merging; % flag for displaying merging example
	if options.nonCNMF.showFigures==1&&and(display_merging, ~isempty(merged_ROIs))
		i = 1; %randi(length(merged_ROIs));
		ln = length(merged_ROIs{i});
		figure;
			% set(gcf,'Position',[300,300,(ln+2)*300,300]);
			for j = 1:ln
				subplot(1,ln+2,j); imagesc(reshape(A_keep(:,merged_ROIs{i}(j)),d1,d2));
					title(sprintf('Component %i',j),'fontsize',16,'fontweight','bold'); axis equal; axis tight;
			end
			subplot(1,ln+2,ln+1); imagesc(reshape(Am(:,K_m-length(merged_ROIs)+i),d1,d2));
					title('Merged Component','fontsize',16,'fontweight','bold');axis equal; axis tight;
			subplot(1,ln+2,ln+2);
				plot(1:T,(diag(max(C_keep(merged_ROIs{i},:),[],2))\C_keep(merged_ROIs{i},:))');
				hold all; plot(1:T,Cm(K_m-length(merged_ROIs)+i,:)/max(Cm(K_m-length(merged_ROIs)+i,:)),'--k')
				title('Temporal Components','fontsize',16,'fontweight','bold')
			drawnow;
	end

	%% refine estimates excluding rejected components

	Pm.p = p;    % restore AR value
	[A2,b2,C2] = update_spatial_components(Yr,Cm,f,[Am,b],Pm,cnmfOptions);
	[C2,f2,P2,S2,YrA2] = update_temporal_components(Yr,A2,b2,C2,f,Pm,cnmfOptions);


	%% do some plotting

	[A_or,C_or,S_or,P_or] = order_ROIs(A2,C2,S2,P2); % order components
	K_m = size(C_or,1);
	% playMovie(reshape(Yr,d1,d2,size(C_or,2)));
	[C_df,~] = extract_DF_F(Yr,A_or,C_or,P_or,cnmfOptions); % extract DF/F values (optional)
	% figure;plotSignalsGraph(C_df*-1);
	% pause

	disp('Organizing output struct...')
	[cnmfAnalysisOutput] = organizeStandardOutput();

	try
		if options.nonCNMF.showFigures==1&&options.nonCNMF.plot_contours_components==1
			figure;
			[Coor,json_file] = plot_contours(A_or,Cn,cnmfOptions,1); % contour plot of spatial footprints
			%savejson('jmesh',json_file,'filename');        % optional save json file with component coordinates (requires matlab json library)

			%% display components

			plot_components_GUI(Yr,A_or,C_or,b2,f2,Cn,cnmfOptions);

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
		nSignals = size(A_or,2);
		extractedImages = zeros([d1 d2 nSignals]);
		% nSignals
		for signalNo = 1:nSignals
			extractedImages(:,:,signalNo) = reshape(A_or(:,signalNo),d1,d2);
		end

		% store background component
		C_df_or_background = C_df(end,:);
		S_df_or = S_or;

		% figure;imagesc(C_df);

		% add parameters and extractions to output structure
		cnmfAnalysisOutput.params.K = K;
		cnmfAnalysisOutput.params.tau = options.otherCNMF.tau;
		cnmfAnalysisOutput.params.p = options.otherCNMF.p;
		cnmfAnalysisOutput.datasetComponentProperties_P = P;
		cnmfAnalysisOutput.movieList = movieList;
		cnmfAnalysisOutput.extractedImages = extractedImages;
		% correct for df/f output problems
		if nanmean(C_df(:))<0&options.nonCNMF.dfofCorrect==1
			cnmfAnalysisOutput.extractedSignals = full(-1*C_df);
		else
			cnmfAnalysisOutput.extractedSignals = full(C_df);
		end
		% cnmfAnalysisOutput.extractedSignals = full(C_df);

		cnmfAnalysisOutput.extractedSignalsBackground = full(C_df_or_background);
		cnmfAnalysisOutput.extractedSignalsType = 'dfof';
		cnmfAnalysisOutput.extractedSignalsEst = full(C_or);
		cnmfAnalysisOutput.extractedSignalsEstType = 'model';
		cnmfAnalysisOutput.extractedPeaks = S_df_or;
		cnmfAnalysisOutput.extractedPeaksEst = S_or;
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