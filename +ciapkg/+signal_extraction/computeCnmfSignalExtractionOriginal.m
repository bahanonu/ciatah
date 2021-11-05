function [cnmfAnalysisOutput] = computeCnmfSignalExtractionOriginal(inputMovie,numExpectedComponents,varargin)
	% Wrapper for CNMF, for use with https://github.com/epnev/ca_source_extraction/commit/8799b13df2b09f30e27fc852e4f5f39ae6f44405
	% Building off of demo_script.m in CNMF github repo
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
		% 2016.09.xx - force update of
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% for loading movie
	% run only initialization algorithm
	options.nonCNMF.onlyRunInitialization = 0;
	% list of frames to load in movie
	options.nonCNMF.frameList = [];
	% whether to load movie as double
	options.nonCNMF.convertToDouble = 0;
	% HDF5 dataset name
	options.nonCNMF.inputDatasetName = '/1';
	% HDF5 dataset name
	options.nonCNMF.showFigures = 0;
	% whether to use the old set of initialization parameters
	options.nonCNMF.useOldInitializationSetParams = 0;

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

	% preprocess_data.m
	options.flag_g = 0; % Flag for computing global time constants  0
	options.split_data = 0;  % Flag for computing noise values sequentially for memory reasons

	% initialize_components.m
	options.ssub = 1;  % Spatial down-sampling factor (scalar >= 1)  1
	options.tsub = 1;  % Temporal down-sampling factor (scalar >= 1)  1
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
	options.use_parallel = 1; % Flag for solving optimization problem in parallel (binary)  1 (if parallel toolbox exists)
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
	options.fudge_factor = 0.98; %Multiplicative bias correction for g (positive between 0 and 1). Note: Slight changes can have large effects. Typically stay within [0.95-1]. 	1 (no correction)

	% merge_components.m
	options.merge_thr = 0.85; % Merging threshold (positive between 0  and 1)  0.85

	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	try
		% if cvx is not in the path, ask user for file
		runCvxSetup();

		startTimeWithMovie = tic;
		% re-initialize any options that are dependent on other options
		options.gSig = 2*options.otherCNMF.tau+1;  % Size of Gaussian kernel  2*tau+1

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

		% =======
		% Based on demo_script.m in CNMF documentation
		if ~isa(Y,'double');    Y = double(Y);  end         % convert to double

		[d1,d2,T] = size(Y);                                % dimensions of dataset
		d = d1*d2;                                          % total number of pixels
		options.d1 = d1;
		options.d2 = d2;

		%% Set parameters
		K = numExpectedComponents;                                           % number of components to be found
		tau = options.otherCNMF.tau;                                          % std of gaussian kernel (size of neuron)
		p = options.otherCNMF.p;                                            % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
		merge_thr = options.merge_thr;                                  % merging threshold

		if options.nonCNMF.useOldInitializationSetParams == 1
			cnmfOptions = CNMFSetParms(...
				'd1',d1,'d2',d2,...                         % dimensions of datasets
				'search_method','ellipse','dist',3,...      % search locations when updating spatial components
				'deconv_method','constrained_foopsi',...    % activity deconvolution method
				'temporal_iter',2,...                       % number of block-coordinate descent steps
				'fudge_factor',0.98,...                      % bias correction for AR coefficients
				'merge_thr',merge_thr...                    % merging threshold
				);
		else
			% construct a cell array of parameters and pass to CNMFSetParms
			optionNames = fieldnames(options);
			nOptions = length(optionNames);
			optionsArray = {};
			for optionNo = 1:nOptions
				% ignore non CNMF parameters
				if strcmp(optionNames(optionNo),'nonCNMF')||strcmp(optionNames(optionNo),'otherCNMF')
					continue;
				end
				optionsArray{end+1} = optionNames{optionNo};
				% optionNames(optionNo)
				% class(optionNames(optionNo))
				optionsArray{end+1} = options.(optionNames{optionNo});
			end
			% optionsArray
			cnmfOptions = CNMFSetParms(optionsArray{:});
		end

		%% Data pre-processing
		[P,Y] = preprocess_data(Y,p);

		%% fast initialization of spatial components using greedyROI and HALS
		if isempty(options.nonCNMF.initializeComponents)
			[Ain,Cin,bin,fin,center] = initialize_components(Y,K,tau,cnmfOptions);  % initialize
		else
			Ain = reshape(options.nonCNMF.initializeComponents,[d size(options.nonCNMF.initializeComponents,3)]);
			Cin = [];
			bin = [];
			fin = [];
			center = [];
		end

		% display centers of found components
		if options.nonCNMF.showFigures==1&~isempty(center)
			Cn =  correlation_image(Y); %max(Y,[],3); %std(Y,[],3); % image statistic (only for display purposes)
			[figHandle figNo] = openFigure(1337, '');
			clf
			imagesc(Cn);
				axis equal; axis tight; hold all;
				scatter(center(:,2),center(:,1),'mo');
				title('Center of ROIs found from initialization algorithm');
				drawnow;
		 end

		% exit if user only wants to run a part of the algorithm
		if options.nonCNMF.onlyRunInitialization==1
			return
		end

		%% update spatial components
		Yr = reshape(Y,d,T);
		clear Y;
		options.show_sum = 1;
		disp('===Updating spatial components')
		[A,b,Cin] = update_spatial_components(Yr,Cin,fin,Ain,P,cnmfOptions);

		%% update temporal components
		disp('===Updating temporal components')
		[C,f,Y_res,P,S] = update_temporal_components_parallel(Yr,A,b,Cin,fin,P,cnmfOptions);

		%% merge found components
		disp('===Merging components')
		[Am,Cm,K_m,merged_ROIs,P,Sm] = merge_components(Y_res,A,b,C,f,P,S,cnmfOptions);
		% flag for displaying merging example
		if options.nonCNMF.showFigures==1
			display_merging = options.otherCNMF.display_merging;
			if display_merging
				i = 1; randi(length(merged_ROIs));
				ln = length(merged_ROIs{i});

				[figHandle figNo] = openFigure(1338, '');
					clf
					set(gcf,'Position',[300,300,(ln+2)*300,300]);
					for j = 1:ln
						subplot(1,ln+2,j); imagesc(reshape(A(:,merged_ROIs{i}(j)),d1,d2));
							title(sprintf('Component %i',j),'fontsize',16,'fontweight','bold'); axis equal; axis tight;
					end
					subplot(1,ln+2,ln+1); imagesc(reshape(Am(:,K_m-length(merged_ROIs)+i),d1,d2));
							title('Merged Component','fontsize',16,'fontweight','bold');axis equal; axis tight;
					subplot(1,ln+2,ln+2);
						plot(1:T,(diag(max(C(merged_ROIs{i},:),[],2))\C(merged_ROIs{i},:))');
						hold all; plot(1:T,Cm(K_m-length(merged_ROIs)+i,:)/max(Cm(K_m-length(merged_ROIs)+i,:)),'--k')
						title('Temporal Components','fontsize',16,'fontweight','bold')
					drawnow;
			end
		end

		%% repeat
		disp('===Updating spatial components again...')
		[A2,b2,Cm] = update_spatial_components(Yr,Cm,f,Am,P,cnmfOptions);
		disp('===Updating temporal components again...')
		[C2,f2,Y_res,P,S2] = update_temporal_components_parallel(Yr,A2,b2,Cm,f,P,cnmfOptions);
		K_m = size(C2,1);
		disp('===Extracting dF/F traces...')
		[C_df,~,S_df] = extract_DF_F(Yr,[A2,b2],[C2;f2],S2,K_m+1); % extract DF/F values (optional)

		% order components
		[A_or,C_or,S_or,P,srt] = order_ROIs(A2,C2,S2,P);
		% order dfof values
		C_df_or = C_df(srt,:);
		S_df_or = S_df(srt,:);

		if options.nonCNMF.showFigures==1
			contour_threshold = 0.95; % amount of energy used for each component to construct contour plot
			%% do some plotting
			[figHandle figNo] = openFigure(1339, '');
			clf
			[Coor,json_file] = plot_contours(A_or,reshape(P.sn,d1,d2),contour_threshold,1);
			drawnow
		end
		% contour plot of spatial footprints
		% pause;
		%savejson('jmesh',json_file,'filename');        % optional save json file with component coordinates (requires matlab json library)
		% view_components(Yr,A_or,C_or,b2,f2,Cn,cnmfOptions);         % display all components
		% =======

		% extract out images and organize them in standard format
		nSignals = size(A_or,2);
		extractedImages = zeros([d1 d2 nSignals]);
		% nSignals
		for signalNo = 1:nSignals
			extractedImages(:,:,signalNo) = reshape(A_or(:,signalNo),d1,d2);
		end

		% add parameters and extractions to output structure
		cnmfAnalysisOutput.params.K = K;
		cnmfAnalysisOutput.params.tau = options.otherCNMF.tau;
		cnmfAnalysisOutput.params.p = options.otherCNMF.p;
		cnmfAnalysisOutput.datasetComponentProperties_P = P;
		cnmfAnalysisOutput.movieList = movieList;
		cnmfAnalysisOutput.extractedImages = extractedImages;
		cnmfAnalysisOutput.extractedSignals = C_df_or;
		cnmfAnalysisOutput.extractedSignalsEst = C_or;
		cnmfAnalysisOutput.extractedPeaks = S_df_or;
		cnmfAnalysisOutput.extractedPeaksEst = S_or;
		cnmfAnalysisOutput.cnmfOptions = cnmfOptions;
		cnmfAnalysisOutput.time.datetime = datestr(now,'yyyy_mm_dd_HHMM','local');
		cnmfAnalysisOutput.time.startTimeWithMovie = toc(startTimeWithMovie);
		cnmfAnalysisOutput.time.startTimeSansMovie = toc(startTimeSansMovie);

		% fix negative traces output
		for iii = 1:size(cnmfAnalysisOutput.extractedSignals,1)
			tmpTrace = cnmfAnalysisOutput.extractedSignals(iii,:);
			if nanmean(tmpTrace(:))<0
				cnmfAnalysisOutput.extractedSignals(iii,:) = -1*tmpTrace;
			end

			tmpTrace = cnmfAnalysisOutput.extractedSignalsEst(iii,:);
			if nanmean(tmpTrace(:))<0
				cnmfAnalysisOutput.extractedSignalsEst(iii,:) = -1*tmpTrace;
			end
		end

		% if verLessThan('matlab','8.4')
		%     % R2014a or earlier
		%     cnmfAnalysisOutput.time.datetime = datestr(now,'yyyymmdd_HHMM','local');
		% else
		%     % R2014b or later
		%     cnmfAnalysisOutput.time.datetime = datetime;
		% end
		cnmfAnalysisOutput.success = 1;

		% cnmfAnalysisOutput
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end