function [IcaOutputSpatial, IcaOutputTemporal, IcaOutputInfo] = run_ica(spatial, temporal, S, movie_height, movie_width, num_ICs, varargin)
    % runs ICA on input PCA filters/traces
    % inputs
        % spatial - [x y nPCs] where nPCs does not necessarily need to equal the number of PCs from the initial guess nPCs.
        % temporal - [nPCs frames] output traces from
        % S - PCA singular values.
        % PcaInfo - structure with information about this PCA run.
        % inputMatrix: input movie (give a character string pointing to the movie file) or matrix ([x y frames]) to run PCA on.
        % movie_height = scalar, height of movie PCA was run on.
        % movie_width = scalar, width of movie PCA was run on.
        % num_ICs: scalar value with initial guess as to number of ICs, e.g. 100.
    % outputs
        % 
    % Usage:
      % IGNORE: run_ica([x y frame], 200, 0.1); % pca_source, num_ICs, mu
    %options:
        % output_units: string of either fluorescence ('fl') or standard deviation ('std').
        % mu: parameter (between 0 and 1) specifying weight of temporal information in spatio-temporal ICA
        % term_tol: Termination tolerance, e.g. 1e-5.
        % max_iter: Max iterations of FastICA, e.g. 750.

    % changelog
        % ‎15 ‎December, ‎2017, ‏‎11:36:50
        % 

    %========================
    options.output_units = 'std';
    options.mu = 0.1;
    options.term_tol = 1e-5;
    options.max_iter = 750;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % Defaults
    output_units = options.output_units;
    mu = options.mu;

    % ICA
    %------------------------------------------------------------
    fprintf('%s: Computing ICA weights...\n', datestr(now));

    ica_mixed = compute_spatiotemporal_ica_input(spatial, temporal, mu);

    term_tol = options.term_tol; % Termination tolerance
    max_iter = options.max_iter;  % Max iterations of FastICA
    ica_W = compute_ica_weights(ica_mixed, num_ICs, term_tol, max_iter)'; %#ok<*NASGU>

    IcaOutputInfo.type = 'ica';
    % IcaOutputInfo.pca_source = pca_source;
    IcaOutputInfo.num_pairs = num_ICs;
    IcaOutputInfo.mu = mu; %#ok<*STRNU>
    IcaOutputInfo.term_tol = options.term_tol;
    IcaOutputInfo.max_iter = options.max_iter;

    % Save ICA results
    %------------------------------------------------------------
    % timestamp = datestr(now, 'yymmdd-HHMMSS');
    % ica_savename  = sprintf('ica_%s.mat',  timestamp);
    % icaw_savename = sprintf('icaw_%s.mat', timestamp);

    % save(icaw_savename, 'info', 'ica_W'); % Save weights

    fprintf('%s: Computing ICA pairs (filters, traces) from weights...\n', datestr(now));

    [filters, traces] = compute_ica_pairs(spatial, temporal, S, movie_height, movie_width, ica_W);
    % [filters, traces] = compute_ica_pairs(pca_source, icaw_savename);  %#ok<*ASGLU>

    % Output normalization or lack-thereof
    switch output_units
        case 'std'
            display('converting traces to units of standard deviation')
            traceNormVal = std(traces,1);
            traces = bsxfun(@rdivide,traces,traceNormVal);
        case '2norm'
            display('setting 2-norm of all traces to 1')
            traceNormVal = sqrt(sum(traces.^2,1));
            traces = bsxfun(@rdivide,traces,traceNormVal);
        case 'fl'
            display('converting traces to units of fluorescence')
            max_vals = max(filters,[],1);
            max_vals = squeeze(max(max_vals,[],2));
            max_vals = max_vals'; % make row vector
            traces = bsxfun(@times,traces,max_vals);
        case 'var'
            display('setting var of all traces to 1')
            traceNormVal = var(traces,1);
            traces = bsxfun(@rdivide,traces,traceNormVal);
        otherwise
            % body
    end
    IcaOutputSpatial = filters;
    IcaOutputTemporal = traces;

    % save(ica_savename,  'info', 'filters', 'traces'); % Save ICA pairs

    fprintf('%s: All done!\n', datestr(now));
end