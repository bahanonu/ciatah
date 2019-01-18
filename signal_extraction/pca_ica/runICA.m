function [IcaFilters IcaTraces] = runICA(PcaFilters, PcaTraces, inputID, nICs, PCAsuffix, varargin)
    % Runs ICA on input PCA filters/traces.
    % Biafra Ahanonu
    % started: 2013.10.08
    % based on SpikeE script
    % started 2013.02.xx by maggie carr
    % inputs
        % inputDir: path to input data
        % inputID: unique identifier
        % nICs: number of requested output ICs, use nICs=[] to have nICs=nPCs
        % PCAsuffix: extra identifier, e.g. 'clean' that PC file should have.
    % outputs
        % IcaFilters - [n x y], n = # signals, x/y = dimensions of each image
        % IcaTraces - [m n], m = signals, n = time points
    % options:
        % Spatial_Temporal_Tradeoff: Relative weight of spatial and temporal
        %     variance for ICA. Default = 0.1.
        % IC_Convergence_Error: Error tolerance for the ICA. Default = 1e-5.
        % MaxRoundsICs: Rounds of ICA to complete. Default = 750.
        % Threshold: Threshold applied to the IC filters.Default = 0.5
        % IC_Iterations: Number of times to run ICA. Default = 10.
        % MaxDist: Determines the maximum distance between two centroids for two ICs
        %     to be identified as the same. Default = 1.5.

    % changelog
        % updated: 2013.10.xx: added back ability to have different number of output ICs than input PCs, this had been removed...
        % updated: 2013.10.31 [13:36:20]
            % re-factored code to remove multi-iteration decision making (for determining consistent ICs) into separate function
            % added back the the code from SpikeE to sort the filters AND traces (was removed...)
            % moved
        % updated: 2013.11.01 [10:14:28]
            % fxn now outputs traces that you can then save in a controller function, much better abstraction and easier to maintain going forward. Also, now accepts PcaFilters and PcaTraces as inputs instead of loading them, again, easier to maintain.
            % removed all references to days and dayInd, they were compatibility headaches. That can be abstracted to a controller function.
        % 2014.01.20 [11:28:02] standardized i/o options to be like other functions, replaced waitbar with cmdWaitbar.

    %========================
    options.Mu = 0.1;
    options.TermTolICs=1e-4;
    options.MaxRoundsICs=750;
    options.threshold = 0.5;
    options.minNumPixels=25;
    options.IC_iterations = 1;
    options.maxDist = 1.5;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    display(['convergence error: ' num2str(TermTolICs)]);
    display(['max rounds ICA: ' num2str(MaxRoundsICs)]);
    display(['ICA iterations: ' num2str(IC_iterations)]);

    % pre-processing steps
    display('pre-processing PCs for ICA...');
    MovieSize = size(PcaFilters);
    % determine whether to use IC # from PCs or from input
    if isempty(nICs)
        nICs = MovieSize(3);
    elseif nICs>MovieSize(3)
        nICs = MovieSize(3);
    else
        nICs=nICs;
    end
    display(['#ICs: ' num2str(nICs)]);

    %Prepare for ICA
    nPCs = size(PcaFilters,3);
    PcaFilters = reshape(PcaFilters,MovieSize(1)*MovieSize(2),nPCs)';
    PcaTraces = PcaTraces';

    % Determine distribution of PCA skewness
    % pcskew = skewness(PcaTraces');

    % Center the data by removing the mean of each PC
    meanTraces = mean(PcaTraces,2);
    PcaTraces = PcaTraces - meanTraces * ones(1, size(PcaTraces,2));
    meanFilters = mean(PcaFilters,2);
    PcaFilters = PcaFilters - meanFilters * ones(1, size(PcaFilters,2));

    % Perform ICA multiple times
    IC_filters = cell(1,IC_iterations);
    % open waitbar
    for repeat = 1:IC_iterations
        display(['ICA repeat ' num2str(repeat) '/' num2str(IC_iterations)]);
        tic

        % Create concatenated data for spatio-temporal ICA
        if Mu == 1
            IcaMixed = PcaTraces; % Pure temporal ICA
        elseif Mu == 0
            IcaMixed = PcaFilters; % Pure spatial ICA
        else
            IcaMixed = [(1-Mu)*PcaFilters, Mu*PcaTraces]; % Spatial-temporal ICA
            IcaMixed = IcaMixed / sqrt(1-2*Mu+2*Mu^2); % This normalization ensures that, if both PcaFilters and PcaTraces have unit covariance, then so will IcaTraces
        end

        % Perform ICA
        numSamples = size(IcaMixed,2);
        % Seed for the ICs calculation
        rng('shuffle'); %seed the random number generator with the cpu time
        ica_A = orth(randn(nPCs, nICs));
        BOld = zeros(size(ica_A));
        numiter = 0;
        minAbsCos = 0;

        % We preallocate an intermediate matrix
        Interm=zeros(size(IcaMixed,2),nICs,'double');

        reverseStr = '';
        while (numiter<MaxRoundsICs) && ((1-minAbsCos)>TermTolICs)
            numiter = numiter + 1;
            if numiter>1
                Interm=IcaMixed'*ica_A;
                Interm=Interm.^2;
                ica_A = IcaMixed*Interm/numSamples;
            end

            % Symmetric orthogonalization.
            ica_A = ica_A * real(inv(ica_A' * ica_A)^(1/2));

            % Test for termination condition.
            minAbsCos = min(abs(diag(ica_A' * BOld)));

            BOld = ica_A;
            if mod(numiter,3)==0|numiter==MaxRoundsICs
                reverseStr = cmdWaitbar(numiter,MaxRoundsICs,reverseStr,'inputStr','iterating through ICA');
            end
        end

        ica_A = ica_A';
        % clear BOld minAbsCos Interm IcaMixed numSamples numiter

        % Add the mean back in.
        display('adding back IC means...')
        IcaTraces = ica_A*PcaTraces+ica_A*(meanTraces*ones(1,size(PcaTraces,2)));
        IcaFilters = ica_A*PcaFilters+ica_A*(meanFilters*ones(1,size(PcaFilters,2)));
        % clear ica_A

        % Sort ICs according to skewness of the temporal component
        display('sorting ICs based on skewness...')
        icskew = skewness(IcaTraces');
        [icskew, ICCoord] = sort(icskew, 'descend');
        ica_A = ica_A(:,ICCoord);
        IcaTraces = IcaTraces(ICCoord,:);
        IcaFilters = IcaFilters(ICCoord,:);
        % icskew = icskew(ICCoord);

        % Note that with these definitions of IcaFilters and IcaTraces, we can decompose
        % the sphered and original movie data matrices as:
        %     mov_sphere ~ PcaFilters * PcaTraces = IcaFilters * IcaTraces = (PcaFilters*ica_A') * (ica_A*PcaTraces),
        %     mov ~ PcaFilters * pca_D * PcaTraces.
        % This gives:
        %     IcaFilters = PcaFilters * ica_A' = mov * PcaTraces' * inv(diag(pca_D.^(1/2)) * ica_A'
        %     IcaTraces = ica_A * PcaTraces = ica_A * inv(diag(pca_D.^(1/2))) * PcaFilters' * mov

        %Remove ICs that do not have a skewness greater than %75 of pcskew
        % valid = icskew > (prctile(pcskew,75));
        % IcaFilters = IcaFilters(valid,:);
        % nICs = sum(valid);

        % keep all ICs
        valid = ones(length(icskew),1);
        nICs = sum(valid);

        clear icskew ICCoord valid

        % Reshape the filter to have a proper image
        IcaFilters = reshape(IcaFilters,nICs,MovieSize(1),MovieSize(2));

        toc
    end
    % clear PcaTraces PcaFilters IcaFilters MovieSize

    %Match across runs of ICA, re-factored this portion to a separate function
    % IC_filters = model_matchICsAcrossDays();

function obsoleteThresholdCrop()
    % removed, unneeded

    % ic_count = 1;
    % for i=1:nICs
    %     thisFilt=squeeze(double(IcaFilters(i,:,:)));
    %     IC_filters{repeat}.Image{ic_count}=thisFilt;
    %     imagesum = sum(sum(IC_filters{repeat}.Image{ic_count}));

        % if i == 1
        %     xCoords = repmat(1:size(thisFilt,2), size(thisFilt,1), 1);
        %     yCoords=repmat((1:size(thisFilt,1))', 1,size(thisFilt,2));
        % end
        % IC_filters{repeat}.centroid(ic_count,:) = [sum(sum(thisFilt.*xCoords))/imagesum ...
        %     sum(sum(thisFilt.*yCoords))/imagesum];
    %     ic_count = ic_count+1;
    % end
    % clear ic_count thisFilt maxVal imagesum