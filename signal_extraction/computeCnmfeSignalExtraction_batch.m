function [cnmfeAnalysisOutput] = computeCnmfeSignalExtraction_batch(inputMovie,varargin)
	% Wrapper function for CNMF-E, update for most recent versions.
	% Building off of demo_large_data_1p.m in CNMF-E github repo
	% Most recent commit tested on: https://github.com/epnev/ca_source_extraction/commit/187bbdbe66bca466b83b81861b5601891a95b8d1
	% https://github.com/epnev/ca_source_extraction/blob/master/demo_script_class.m
	% Biafra Ahanonu
	% started: 2018.10.20 [16:38:24]
	% inputs
		% inputMovie - a string or a cell array of strings pointing to the movies to be analyzed (recommended).
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
	% TODO
		%


	% ========================
	% for loading movie
	% turn on parallel
	options.nonCNMF.parallel = 1;

	options.gSig = 3;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
	options.gSiz = 11;          % pixel, neuron diameter
	options.ssub = 1;           % spatial downsampling factor
	options.tsub = 1;           % temporal downsampling factor
	options.batch_frames = 1000;           % temporal downsampling factor
	% get options
	options = getOptions(options,varargin);
	% ========================

	try
		%% clear the workspace and select data
		% clear; clc; close all;

		%% choose multiple datasets or just one
		inputFilename = inputMovie;

		neuron = Sources2D();
		nams = {inputFilename};          % you can put all file names into a cell array; when it's empty, manually select files
		nams = neuron.select_multiple_files(nams);  %if nam is [], then select data interactively

		%% parameters
		% -------------------------    COMPUTATION    -------------------------  %
		pars_envs = struct('memory_size_to_use', 8, ...   % GB, memory space you allow to use in MATLAB
			'memory_size_per_patch', 0.5, ...   % GB, space for loading data within one patch
			'patch_dims', [64, 64],...  %GB, patch size
			'batch_frames', options.batch_frames);           % number of frames per batch
		  % -------------------------      SPATIAL      -------------------------  %
		gSig = options.gSig;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
		gSiz = options.gSiz;          % pixel, neuron diameter
		ssub = options.ssub;           % spatial downsampling factor
		with_dendrites = true;   % with dendrites or not
		if with_dendrites
			% determine the search locations by dilating the current neuron shapes
			updateA_search_method = 'dilate';  %#ok<UNRCH>
			updateA_bSiz = 5;
			updateA_dist = neuron.options.dist;
		else
			% determine the search locations by selecting a round area
			updateA_search_method = 'ellipse'; %#ok<UNRCH>
			updateA_dist = 5;
			updateA_bSiz = neuron.options.dist;
		end
		spatial_constraints = struct('connected', true, 'circular', false);  % you can include following constraints: 'circular'
		spatial_algorithm = 'hals';

		% -------------------------      TEMPORAL     -------------------------  %
		Fs = 10;             % frame rate
		tsub = options.tsub;           % temporal downsampling factor
		deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'}
			'method', 'foopsi', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'}
			'smin', -5, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
			'optimize_pars', true, ...  % optimize AR coefficients
			'optimize_b', true, ...% optimize the baseline);
			'max_tau', 100);    % maximum decay time (unit: frame);

		nk = 3;             % detrending the slow fluctuation. usually 1 is fine (no detrending)
		% when changed, try some integers smaller than total_frame/(Fs*30)
		detrend_method = 'spline';  % compute the local minimum as an estimation of trend.

		% -------------------------     BACKGROUND    -------------------------  %
		bg_model = 'ring';  % model of the background {'ring', 'svd'(default), 'nmf'}
		nb = 1;             % number of background sources for each patch (only be used in SVD and NMF model)
		bg_neuron_factor = 1.4;
		ring_radius = round(bg_neuron_factor * gSiz);  % when the ring model used, it is the radius of the ring used in the background model.
		%otherwise, it's just the width of the overlapping area
		num_neighbors = 50; % number of neighbors for each neuron

		% -------------------------      MERGING      -------------------------  %
		show_merge = false;  % if true, manually verify the merging step
		merge_thr = 0.65;     % thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
		method_dist = 'max';   % method for computing neuron distances {'mean', 'max'}
		dmin = 5;       % minimum distances between two neurons. it is used together with merge_thr
		dmin_only = 2;  % merge neurons if their distances are smaller than dmin_only.
		merge_thr_spatial = [0.8, 0.4, -inf];  % merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)

		% -------------------------  INITIALIZATION   -------------------------  %
		K = [];             % maximum number of neurons per patch. when K=[], take as many as possible.
		min_corr = 0.8;     % minimum local correlation for a seeding pixel
		min_pnr = 8;       % minimum peak-to-noise ratio for a seeding pixel
		min_pixel = gSig^2;      % minimum number of nonzero pixels for each neuron
		bd = 0;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
		frame_range = [];   % when [], uses all frames
		save_initialization = false;    % save the initialization procedure as a video.
		use_parallel = true;    % use parallel computation for parallel computing
		show_init = true;   % show initialization results
		choose_params = true; % manually choose parameters
		center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
		% set the value as false when the background fluctuation is small (2p)

		% -------------------------  Residual   -------------------------  %
		min_corr_res = 0.7;
		min_pnr_res = 6;
		seed_method_res = 'auto';  % method for initializing neurons from the residual
		update_sn = true;

		% ----------------------  WITH MANUAL INTERVENTION  --------------------  %
		with_manual_intervention = false;

		% -------------------------  FINAL RESULTS   -------------------------  %
		save_demixed = true;    % save the demixed file or not
		kt = 3;                 % frame intervals

		% -------------------------    UPDATE ALL    -------------------------  %
		neuron.updateParams('gSig', gSig, ...       % -------- spatial --------
			'gSiz', gSiz, ...
			'ring_radius', ring_radius, ...
			'ssub', ssub, ...
			'search_method', updateA_search_method, ...
			'bSiz', updateA_bSiz, ...
			'dist', updateA_bSiz, ...
			'spatial_constraints', spatial_constraints, ...
			'spatial_algorithm', spatial_algorithm, ...
			'tsub', tsub, ...                       % -------- temporal --------
			'deconv_options', deconv_options, ...
			'nk', nk, ...
			'detrend_method', detrend_method, ...
			'background_model', bg_model, ...       % -------- background --------
			'nb', nb, ...
			'ring_radius', ring_radius, ...
			'num_neighbors', num_neighbors, ...
			'merge_thr', merge_thr, ...             % -------- merging ---------
			'dmin', dmin, ...
			'method_dist', method_dist, ...
			'min_corr', min_corr, ...               % ----- initialization -----
			'min_pnr', min_pnr, ...
			'min_pixel', min_pixel, ...
			'bd', bd, ...
			'center_psf', center_psf);
		neuron.Fs = Fs;

		%% distribute data and be ready to run source extraction
		neuron.getReady_batch(pars_envs);

		%% initialize neurons in batch mode
		neuron.initComponents_batch(K, save_initialization, use_parallel);

		%% udpate spatial components for all batches
		neuron.update_spatial_batch(use_parallel);

		%% udpate temporal components for all bataches
		neuron.update_temporal_batch(use_parallel);

		%% update background
		neuron.update_background_batch(use_parallel);

		%% delete neurons

		%% merge neurons

		%% get the correlation image and PNR image for all neurons
		neuron.correlation_pnr_batch();

		%% concatenate temporal components
		neuron.concatenate_temporal_batch();
		% neuron.viewNeurons([],neuron.C_raw);

		% Get the folder path string
		[PATHSTR,NAME,EXT] = fileparts(inputFilename);
		[~,folderName,~] = fileparts(PATHSTR);

		results = neuron.obj2struct();
		cnmfeAnalysisOutput.success = 1;
		cnmfeAnalysisOutput.params = results.options;
		cnmfeAnalysisOutput.movieList = inputFilename;
		% cnmfeAnalysisOutput.extractedImages = reshape(full(results.A),[size(results.P.sn) size(results.C,1)]);

		cnmfeAnalysisOutput.extractedImages = reshape(full(results.A),[neuron.options.d1 neuron.options.d2 size(results.C,1)]);
		cnmfeAnalysisOutput.extractedSignals = results.C;
		cnmfeAnalysisOutput.extractedSignalsEst = results.C_raw;
		cnmfeAnalysisOutput.extractedPeaks = results.S;
		cnmfeAnalysisOutput.Cn = results.Cn;
		cnmfeAnalysisOutput.P = results.P;

		%% save workspace
		% neuron.save_workspace_batch();
	catch err
		try
			results = neuron.obj2struct();
			cnmfeAnalysisOutput.P = results.P;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end

		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end