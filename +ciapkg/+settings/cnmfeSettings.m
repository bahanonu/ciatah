% Biafra Ahanonu
% 2019.04.04 [10:35:15]
% Settings to run CNMF-E, used in conjunction with modelExtractSignalsFromMovie.m or
% as input to "computeCnmfeSignalExtraction" using "computeCnmfeSignalExtraction(inputMovie,'options',cnmfeOpts)" after running "cnmfeSettings"
% changelog
	% 2024.03.29 [19:02:12] - Updated merge settings to reduce duplicates in output.

% ========================
% OVERALL
% turn on parallel
cnmfeOpts.nonCNMF.parallel = 1;
% Binary: 1 = run merging algorithms
cnmfeOpts.runMerge = 1;
% Binary: 1 = remove false positives using CNMF-E algorithm
cnmfeOpts.runRemoveFalsePositives = 1;
% ===COMPUTATION
% Float: GB, memory space you allow to use in MATLAB
cnmfeOpts.memory_size_to_use = 8; %
% Float: GB, memory space you allow to use in MATLAB
cnmfeOpts.memory_size_per_patch = 0.6; % 0.6
% Int vector: patch size in pixels
cnmfeOpts.patch_dims = [64, 64]; % [64, 64]
% Int: number of frames per batch, leave blank to turn off batch
cnmfeOpts.batch_frames = [];
% ===SPATIAL
% Int: pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
cnmfeOpts.gSig = 7;
% Int: pixel, neuron diameter
cnmfeOpts.gSiz = 13;
% Int: spatial downsampling factor
cnmfeOpts.ssub = 1;
% Binary: movie has dendrites?
cnmfeOpts.with_dendrites = true;
% Int: expand kernel for HALS growing (default: 3) and expansion factor of ellipse (default: 3)
cnmfeOpts.updateA_bSiz = 5;
% Char: hals, hals_thresh, lars, nnls
cnmfeOpts.spatial_algorithm = 'hals_thresh';
% ===TEMPORAL
% Int: temporal downsampling factor
cnmfeOpts.tsub = 1;
% Int: frame rate
cnmfeOpts.Fs = 10;
% Float: minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
cnmfeOpts.deconv_smin = -5;
% Int: maximum decay time (unit: frame);
cnmfeOpts.max_tau = 100;
% Int: detrending the slow fluctuation. usually 1 is fine (no detrending)
cnmfeOpts.nk = 3;
% ===BACKGROUND
% Char: model of the background {'ring', 'svd'(default), 'nmf'}
cnmfeOpts.bg_model = 'ring';
% Int: number of background sources for each patch (only be used in SVD and NMF model)
cnmfeOpts.nb = 1;
% Int: when the ring model used, it is the radius of the ring used in the background model. otherwise, it's just the width of the overlapping area
cnmfeOpts.ring_radius = 18;
% Int: downsample background for a faster speed
cnmfeOpts.bg_ssub = 2;
% ===MERGING
% Float: 0 to 1, thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
cnmfeOpts.merge_thr = 0.2;
% Char: method for computing neuron distances {'mean', 'max'}
cnmfeOpts.method_dist = 'mean';
% Int: minimum distances between two neurons. it is used together with merge_thr
cnmfeOpts.dmin = 10;
% Int: merge neurons if their distances are smaller than dmin_only.
cnmfeOpts.dmin_only = 10;
% Float vector: merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)
cnmfeOpts.merge_thr_spatial = [0.3, 0.1, -inf];
% ===INITIALIZATION
% Int: maximum number of neurons per patch. when K=[], take as many as possible.
cnmfeOpts.K = [];
% Float: minimum local correlation for a seeding pixel
cnmfeOpts.min_corr = 0.8;
% minimum peak-to-noise ratio for a seeding pixel
cnmfeOpts.min_pnr = 8;
cnmfeOpts.bd = 0;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
cnmfeOpts.use_parallel = true;    % use parallel computation for parallel computing
cnmfeOpts.show_init = true;   % show initialization results
cnmfeOpts.center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
% set the value as false when the background fluctuation is small (2p)
% ===Residual
% Float: 0 to 1, minimum local correlation for initializing a neuron (default: 0.3)
cnmfeOpts.min_corr_res = 0.7;
% Float: stands for minimum peak-to-noise ratio to look for a cell
cnmfeOpts.min_pnr_res = 6;
% Char: method for initializing neurons from the residual. 'auto' or 'manual'
cnmfeOpts.seed_method_res = 'auto';
% Binary: boolean, update noise level for each pixel
cnmfeOpts.update_sn = true;