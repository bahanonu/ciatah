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
		% 2021.01.24 [14:29:06] - Added trace origin type to output structure.
		% 2021.03.20 [20:20:27] - extractedSignalsType, extractedSignalsEstType struct update.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% OVERALL
	% turn on parallel
	options.nonCNMF.parallel = 1;
	% Binary: 1 = run merging algorithms
	options.runMerge = 1;
	% Binary: 1 = remove false positives using CNMF-E algorithm
	options.runRemoveFalsePositives = 1;
	% ===COMPUTATION
	% Float: GB, memory space you allow to use in MATLAB
	options.memory_size_to_use = 8; %
	% Float: GB, memory space you allow to use in MATLAB
	options.memory_size_per_patch = 0.6; % 0.6
	% Int vector: patch size in pixels
	options.patch_dims = [64, 64]; % [64, 64]
	% Int: number of frames per batch, leave blank to turn off batch
	options.batch_frames = 5000;
	% ===SPATIAL
	% Int: pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
	options.gSig = 3;
	% Int: pixel, neuron diameter
	options.gSiz = 11;
	% Int: spatial downsampling factor
	options.ssub = 1;
	% Binary: movie has dendrites?
	options.with_dendrites = true;
	% Int: expand kernel for HALS growing (default: 3) and expansion factor of ellipse (default: 3)
	options.updateA_bSiz = 5;
	% Char: hals, hals_thresh, lars, nnls
	options.spatial_algorithm = 'hals_thresh';
	% ===TEMPORAL
	% Int: temporal downsampling factor
	options.tsub = 1;
	% Int: frame rate
	options.Fs = 10;
	% Float: minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
	options.deconv_smin = -5;
	% Int: maximum decay time (unit: frame);
	options.max_tau = 100;
	% Int: detrending the slow fluctuation. usually 1 is fine (no detrending)
	options.nk = 3;
	% ===BACKGROUND
	% Char: model of the background {'ring', 'svd'(default), 'nmf'}
	options.bg_model = 'ring';
	% Int: number of background sources for each patch (only be used in SVD and NMF model)
	options.nb = 1;
	% Int: when the ring model used, it is the radius of the ring used in the background model. otherwise, it's just the width of the overlapping area
	options.ring_radius = 18;
	% Int: downsample background for a faster speed
	options.bg_ssub = 2;
	% ===MERGING
	% Float: 0 to 1, thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
	options.merge_thr = 0.65;
	% Char: method for computing neuron distances {'mean', 'max'}
	options.method_dist = 'max';
	% Int: minimum distances between two neurons. it is used together with merge_thr
	options.dmin = 5;
	% Int: merge neurons if their distances are smaller than dmin_only.
	options.dmin_only = 2;
	% Float vector: merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)
	options.merge_thr_spatial = [0.8, 0.4, -inf];
	% ===INITIALIZATION
	% Int: maximum number of neurons per patch. when K=[], take as many as possible.
	options.K = [];
	% Float: minimum local correlation for a seeding pixel
	options.min_corr = 0.8;
	% minimum peak-to-noise ratio for a seeding pixel
	options.min_pnr = 8;
	options.bd = 0;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
	options.use_parallel = true;    % use parallel computation for parallel computing
	options.show_init = true;   % show initialization results
	options.center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
	% set the value as false when the background fluctuation is small (2p)
	% ===Residual
	% Float: 0 to 1, minimum local correlation for initializing a neuron (default: 0.3)
	options.min_corr_res = 0.7;
	% Float: stands for minimum peak-to-noise ratio to look for a cell
	options.min_pnr_res = 6;
	% Char: method for initializing neurons from the residual. 'auto' or 'manual'
	options.seed_method_res = 'auto';
	% Binary: boolean, update noise level for each pixel
	options.update_sn = true;

	% get options
	options = getOptions(options,varargin);
	% ========================

	try
		disp(repmat('=',1,21))
		disp('Running CNMF-e batch wrapper script')
		fn_structdisp(options)

		% if cvx is not in the path, ask user for file
		runCvxSetup();

		% Make sure consistent
		% options.bg_ssub = options.ssub;

		%% clear the workspace and select data
		% clear; clc; close all;

		%% choose multiple datasets or just one
		inputFilename = inputMovie;

		neuron = Sources2D();
		nams = {inputFilename};          % you can put all file names into a cell array; when it's empty, manually select files
		if ~isempty(options.batch_frames)
			nams = neuron.select_multiple_files(nams);  %if nam is [], then select data interactively
		else
			neuron.select_data(inputFilename);  %if nam is [], then select data interactively
		end

		%% parameters
		% -------------------------    COMPUTATION    -------------------------  %
		pars_envs = struct('memory_size_to_use', options.memory_size_to_use, ...   % GB, memory space you allow to use in MATLAB
			'memory_size_per_patch', options.memory_size_per_patch, ...   % GB, space for loading data within one patch
			'patch_dims', options.patch_dims,...   %GB, patch size
			'batch_frames', options.batch_frames);   % number of frames per batch

		% -------------------------      SPATIAL      -------------------------  %
		gSig = options.gSig;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
		gSiz = options.gSiz;          % pixel, neuron diameter
		ssub = options.ssub;           % spatial downsampling factor
		with_dendrites = options.with_dendrites;   % with dendrites or not
		if with_dendrites
			% determine the search locations by dilating the current neuron shapes
			updateA_search_method = 'dilate';  %#ok<UNRCH>
			updateA_bSiz = options.updateA_bSiz;
			updateA_dist = neuron.options.dist;
		else
			% determine the search locations by selecting a round area
			updateA_search_method = 'ellipse'; %#ok<UNRCH>
			updateA_dist = options.updateA_bSiz;
			updateA_bSiz = neuron.options.dist;
		end
		spatial_constraints = struct('connected', true, 'circular', false);  % you can include following constraints: 'circular'
		spatial_algorithm = options.spatial_algorithm;

		% -------------------------      TEMPORAL     -------------------------  %
		Fs = options.Fs;             % frame rate
		tsub = options.tsub;           % temporal downsampling factor
		deconv_flag = true;     % run deconvolution or not
		deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'}
			'method', 'foopsi', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'}
			'smin', options.deconv_smin, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
			'optimize_pars', true, ...  % optimize AR coefficients
			'optimize_b', true, ...% optimize the baseline);
			'max_tau', options.max_tau);    % maximum decay time (unit: frame);

		nk = 3;             % detrending the slow fluctuation. usually 1 is fine (no detrending)
		% when changed, try some integers smaller than total_frame/(Fs*30)
		detrend_method = 'spline';  % compute the local minimum as an estimation of trend. method for detrending {'spline', 'local_min'}

		% -------------------------     BACKGROUND    -------------------------  %
		bg_model = options.bg_model;  % model of the background {'ring', 'svd'(default), 'nmf'}
		nb = options.nb;             % number of background sources for each patch (only be used in SVD and NMF model)
		ring_radius = options.ring_radius;  % when the ring model used, it is the radius of the ring used in the background model.
		%otherwise, it's just the width of the overlapping area
		num_neighbors = []; % number of neighbors for each neuron
		bg_ssub = options.bg_ssub;        % downsample background for a faster speed

		% -------------------------      MERGING      -------------------------  %
		show_merge = false;  % if true, manually verify the merging step
		merge_thr = options.merge_thr;     % thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
		method_dist = options.method_dist;   % method for computing neuron distances {'mean', 'max'}
		dmin = options.dmin;       % minimum distances between two neurons. it is used together with merge_thr
		dmin_only = options.dmin_only;  % merge neurons if their distances are smaller than dmin_only.
		merge_thr_spatial = options.merge_thr_spatial;  % merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)

		% -------------------------  INITIALIZATION   -------------------------  %
		K = options.K;             % maximum number of neurons per patch. when K=[], take as many as possible.
		min_corr = options.min_corr;     % minimum local correlation for a seeding pixel
		min_pnr = options.min_pnr;       % minimum peak-to-noise ratio for a seeding pixel
		min_pixel = gSig^2;      % minimum number of nonzero pixels for each neuron
		bd = options.bd;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
		frame_range = [];   % when [], uses all frames
		save_initialization = false;    % save the initialization procedure as a video.
		use_parallel = options.use_parallel;    % use parallel computation for parallel computing
		show_init = options.show_init;   % show initialization results
		choose_params = false; % manually choose parameters
		center_psf = options.center_psf;  % set the value as true when the background fluctuation is large (usually 1p data)
		% set the value as false when the background fluctuation is small (2p)

		% -------------------------  Residual   -------------------------  %
		min_corr_res = options.min_corr_res;
		min_pnr_res = options.min_pnr_res;
		seed_method_res = options.seed_method_res;  % method for initializing neurons from the residual
		update_sn = options.update_sn;

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
			'deconv_flag', deconv_flag, ...
			'deconv_options', deconv_options, ...
			'nk', nk, ...
			'detrend_method', detrend_method, ...
			'background_model', bg_model, ...       % -------- background --------
			'nb', nb, ...
			'ring_radius', ring_radius, ...
			'num_neighbors', num_neighbors, ...
			'bg_ssub', bg_ssub, ...
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
		if ~isempty(options.batch_frames)
			neuron.getReady_batch(pars_envs);
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
		else
			neuron.getReady(pars_envs);

			%% initialize neurons from the video data within a selected temporal range
			if choose_params
				% change parameters for optimized initialization
				[gSig, gSiz, ring_radius, min_corr, min_pnr] = neuron.set_parameters();
			end

			[center, Cn, PNR] = neuron.initComponents_parallel(K, frame_range, save_initialization, use_parallel);
			neuron.compactSpatial();
			if show_init
				figure();
				ax_init= axes();
				imagesc(Cn, [0, 1]); colormap gray;
				hold on;
				plot(center(:, 2), center(:, 1), '.r', 'markersize', 10);
			end

			%% estimate the background components
			neuron.update_background_parallel(use_parallel);
			neuron_init = neuron.copy();

			%%  merge neurons and update spatial/temporal components
			neuron.merge_neurons_dist_corr(show_merge);
			neuron.merge_high_corr(show_merge, merge_thr_spatial);

			%% update spatial components

			%% pick neurons from the residual
			[center_res, Cn_res, PNR_res] =neuron.initComponents_residual_parallel([], save_initialization, use_parallel, min_corr_res, min_pnr_res, seed_method_res);
			if show_init
				axes(ax_init);
				plot(center_res(:, 2), center_res(:, 1), '.g', 'markersize', 10);
			end
			neuron_init_res = neuron.copy();

			%% udpate spatial&temporal components, delete false positives and merge neurons
			% update spatial
			if update_sn
				neuron.update_spatial_parallel(use_parallel, true);
				udpate_sn = false;
			else
				neuron.update_spatial_parallel(use_parallel);
			end
			% merge neurons based on correlations
			neuron.merge_high_corr(show_merge, merge_thr_spatial);

			for m=1:2
				% update temporal
				neuron.update_temporal_parallel(use_parallel);

				% delete bad neurons
				neuron.remove_false_positives();

				% merge neurons based on temporal correlation + distances
				neuron.merge_neurons_dist_corr(show_merge);
			end

			%% add a manual intervention and run the whole procedure for a second time
			neuron.options.spatial_algorithm = 'nnls';
			if with_manual_intervention
				show_merge = true;
				neuron.orderROIs('snr');   % order neurons in different ways {'snr', 'decay_time', 'mean', 'circularity'}
				neuron.viewNeurons([], neuron.C_raw);

				% merge closeby neurons
				neuron.merge_close_neighbors(true, dmin_only);

				% delete neurons
				tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
				ids = find(tags>0);
				if ~isempty(ids)
					neuron.viewNeurons(ids, neuron.C_raw);
				end
			end

			%% run more iterations
			neuron.update_background_parallel(use_parallel);
			neuron.update_spatial_parallel(use_parallel);
			neuron.update_temporal_parallel(use_parallel);

			K = size(neuron.A,2);
			tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
			neuron.remove_false_positives();
			neuron.merge_neurons_dist_corr(show_merge);
			neuron.merge_high_corr(show_merge, merge_thr_spatial);

			if K~=size(neuron.A,2)
				neuron.update_spatial_parallel(use_parallel);
				neuron.update_temporal_parallel(use_parallel);
				neuron.remove_false_positives();
			end

			%% save the workspace for future analysis
			neuron.orderROIs('snr');
		end

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
		cnmfeAnalysisOutput.extractedSignalsType = 'model';
		cnmfeAnalysisOutput.extractedSignalsEstType = 'dfof';
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
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end

		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end