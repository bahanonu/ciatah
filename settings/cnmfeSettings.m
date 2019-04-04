% Biafra Ahanonu
% 2019.04.04 [10:35:15]
% Settings to run CNMF-E, used in conjunction with modelExtractSignalsFromMovie.m or
% as input to "computeCnmfeSignalExtraction" using "computeCnmfeSignalExtraction(inputMovie,'options',cnmfeOpts)" after running "cnmfeSettings"

% ===COMPUTATION
% Float: GB, memory space you allow to use in MATLAB
cnmfeOpts.memory_size_to_use = 32; %
% Float: GB, memory space you allow to use in MATLAB
cnmfeOpts.memory_size_per_patch = 1.2; % 0.6
% Int vector: patch size in pixels
cnmfeOpts.patch_dims = [128, 128]; % [64, 64]
% ===SPATIAL
% Int: pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
cnmfeOpts.gSig = 3;
% Int: pixel, neuron diameter
cnmfeOpts.gSiz = 11;
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
% ===MERGING
% Binary: whether to run merging
cnmfeOpts.runMerge = 1;
% Float: 0 to 1, thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
cnmfeOpts.merge_thr = 0.65;
% Char: method for computing neuron distances {'mean', 'max'}
cnmfeOpts.method_dist = 'max';
% Int: minimum distances between two neurons. it is used together with merge_thr
cnmfeOpts.dmin = 5;
% Int: merge neurons if their distances are smaller than dmin_only.
cnmfeOpts.dmin_only = 2;
% Float vector: merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)
cnmfeOpts.merge_thr_spatial = [0.8, 0.4, -inf];
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