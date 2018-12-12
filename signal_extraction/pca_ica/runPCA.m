function [PcaFilters PcaTraces] = runPCA(inputMatrix, inputID, numberPCs, fileRegExp, varargin)
    % runs PCA on an input 3D matrix aiming to output number of PCs specified in input
    % Biafra Ahanonu
    % updated starting: 2013.10.08
    % Written by Maggie Carr April 2013, based on code by Eran Mukamel, Jerome Lecoq, and Lacey Kitch
    % inputs
        % inputMatrix: input movie to run PCA on
        % inputID: identifier for this runs output .mat files
        % numberPCs: number of expected PCs
        % fileRegExp: regular expression to filter movies on
    %options:
        % nPCs: Initial guess as to number of principal components. Default = 1000.
        % UseNoiseFloor: Determines whether or not to use an estimate of the noise floor to determine number of PCs to keep. Default = 1.
    % outputs
        %
    % changelog
        % 2013.10.08 [12:36:53] Generalized the code so it no longer relies on a specific file or structure implementation. Removing references to days, etc.
        % 2013.11.01 [10:08:12] made movie loading into a separate function, fxn now accepts a movie as an input
        % 2013.11.18 [15:46:47] updated mean subtraction to use bsxfun, should be faster
        % 2014.01.24 - now removes NaNs from the input matrix
        % 2014.06.08 [13:06:33]
        % 2015.03.20 [13:28:20] - moved calculatePCA function to make a nested, saves memory and allows processing of larger matrices. also moved cov() into the function as well to save memory. now REQUIRES that inputMatrix is a path to a file, will change this behavior in the future.
    % TODO
        %

    %========================
    options.numberPCs = 1000;
    options.npcs = 1000;
    options.usenoisefloor = 0;
    options.frameList = [];
    options.inputDatasetName = '/1';
    %
    options.inputIsPath = 0;
    % get options
    options = getOptions(options,varargin);
    options.numberPCs = options.npcs;
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % get the movie if a string input
    if strcmp(class(inputMatrix),'char')|strcmp(class(inputMatrix),'cell')
        inputMatrixPath = inputMatrix;
        inputMatrix = loadInputMatrix(inputMatrixPath,options);
        options.inputIsPath = 1;
    else

    end

    % get movie information
    DFOFsize = size(inputMatrix);
    if isempty(inputMatrix)|strcmp(class(inputMatrix),'char')|strcmp(class(inputMatrix),'cell')
        PcaFilters = [];
        PcaTraces = [];
        display('no movie...skipping...')
    else
        Npixels = DFOFsize(1)*DFOFsize(2);
        Ntime = DFOFsize(3);


        %Perform mean subtraction for optimal PCA performance
        % display('performing mean subtraction...');drawnow
        % inputMean = nanmean(nanmean(inputMatrix,1),2);
        % inputMean = cast(inputMean,class(inputMatrix));
        % inputMatrix = bsxfun(@minus,inputMatrix,inputMean);
        % for frameInd=1:Ntime
        %     thisFrame=squeeze(inputMatrix(:,:,frameInd));
        %     meanThisFrame = mean(thisFrame(:));
        %     inputMatrix(:,:,frameInd) = inputMatrix(:,:,frameInd)-meanThisFrame;
        % end
        clear thisFrame meanThisFrame

        % TODO
            % % get 1xP matrix of mean for each frame
            % DFOFmean = mean(mean(inputMatrix));
            % % convert to MxNxP, with MxN slice containing repeat of the mean
            % DFOFmean = repmat(DFOFmean,[])
            % %
            % inputMatrix = bsxfun(@minus,inputMatrix,DFOFmean);


        % Check that the number of PCs is fewer than the number of frames
        display('checking # PCs < # frames...')
        if options.numberPCs>Ntime && Ntime>50
            options.numberPCs = Ntime-50;
        elseif options.numberPCs>Ntime && Ntime<=50
            error('Number of PCs must be less than number of frames in movie')
        end

        if options.usenoisefloor
            display('calculating noise floor...')
            %Compute a random matrix prediction (Sengupta & Mitra)
            q = max(DFOFsize(1)*DFOFsize(2),DFOFsize(3));
            p = min(DFOFsize(1)*DFOFsize(2),DFOFsize(3));
            sigma = 1;
            lmax = sigma*sqrt(p+q + 2*sqrt(p*q));
            lmin = sigma*sqrt(p+q - 2*sqrt(p*q));
            lambda = lmin: (lmax-lmin)/100.0123423421: lmax;
            rho = (1./(pi*lambda*(sigma^2))).*sqrt((lmax^2-lambda.^2).*(lambda.^2-lmin^2));
            rho(isnan(rho)) = 0;
            rhocdf = cumsum(rho)/sum(rho);
            noiseigs = interp1(rhocdf, lambda, (p:-1:1)'/p, 'linear', 'extrap').^2 ;
            clear q p sigma lmax lmin lambda rho rhocdf
        end

        nPCs = options.numberPCs; %Starting guess of nPCs for each day
        % display(['Running PCA calculation on day ', num2str(days(dayInd))])

        if options.usenoisefloor %Determine how many PCs to keep, using an estimate of the noise floor
            display('determining PCs to keep based on noise floor...')
            reachederrorfloorlimit = 0;

            while isequal(reachederrorfloorlimit,0) %Increase nPCs until noise floor is reached if using noise floor

                %Calculate PCA with current nPCs
                [CovEvals PcaTraces nPCs] = calculatePCAInternal(inputMatrix,nPCs,inputMatrixPath,options,DFOFsize);

                %Normalize the PC spectrum and determine where it crosses the noisefloor
                normrank = min(DFOFsize(3)-1,length(CovEvals));
                pca_norm = CovEvals*noiseigs(normrank) / (CovEvals(normrank)*noiseigs(1));
                indices = find(pca_norm < (noiseigs(1:normrank)./noiseigs(1)),1);

                if ~isempty(indices)
                    CovEvals = CovEvals(1:indices);
                    PcaTraces = PcaTraces(:,1:indices);
                    reachederrorfloorlimit = 1;
                    nPCs = size(CovEvals,1);
                else
                    nPCs = nPCs + 100;
                    display(['Did not reach noise floor, increasing number of PCs to ' num2str(nPCs)])
                end
            end
            clear normrank pca_norm indices covmat noiseigs reachederrorfloorlimit

        else %Calculate PCA with user defined nPCs
            display('finding PCs...')
            try
                [CovEvals PcaTraces PcaFilters nPCs] = calculatePCAInternal(inputMatrix,nPCs,inputMatrixPath,options,DFOFsize);
                % do something
            catch err
                display(repmat('@',1,7))
                disp(getReport(err,'extended','hyperlinks','on'));
                display(repmat('@',1,7))
            end
        end
    end
    % end

    function inputMatrix = loadInputMatrix(inputMatrix,options)
        display('loading matrix inside PCA function.')
        inputMatrix = loadMovieList(inputMatrix,'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);

        % replace any NaNs with zero
        display('removing NaNs...');drawnow
        inputMatrix(isnan(inputMatrix)) = 0;

        %Perform mean subtraction for optimal PCA performance
        display('performing mean subtraction...');drawnow
        inputMean = nanmean(inputMatrix(:));
        inputMean = cast(inputMean,class(inputMatrix));
        inputMatrix = bsxfun(@minus,inputMatrix,inputMean);
    end

    % function covmat = covInternal()
    %     xc = bsxfun(@minus,x,sum(x,1)/m);  % Remove mean
    %     xy = (xc' * xc) / m;

    function inputMatrix = modifyInputMatrix(inputMatrix)
        OldClass=class(inputMatrix);

        % convert to double for calculation
        inputMatrix = double(inputMatrix);

        % get movie dimensions
        inputMovieSize = size(inputMatrix);
        Npixels = inputMovieSize(1)*inputMovieSize(2);
        Ntime = inputMovieSize(3);

        %Create covariance matrix in the time domain as it is computationally more advantageous than in space and mathematically equivalent.
        display('creating covariance matrix...');drawnow
        inputMatrix = reshape(inputMatrix, Npixels, Ntime);
    end

    function [CovEvals PcaTraces PcaFilters nPCs] = calculatePCAInternal(inputMatrix,nPCs,inputMatrixPath,options,DFOFsize)
        % Runs PCA on inputMovie and looks for a specific number of ICs
        % created by Jerome Lecoq in 2011
        % Biafra Ahanonu
        % started updating: 2013.10.31
        % inputs
            %
        % outputs
            %
        % changelog
            % updated: 2013.10.31 [13:26:17] added PcaFilter variance correction into function
        % TODO
            %

        inputMatrix = modifyInputMatrix(inputMatrix);

        [m,n] = size(inputMatrix);
        covmat = bsxfun(@minus,inputMatrix,sum(inputMatrix,1)/m);  % Remove mean
        % j = whos('inputMatrix');j.bytes=j.bytes*9.53674e-7;j
        clear inputMatrix;
        covmat = (covmat' * covmat) / m;

        % covmat = cov(inputMatrix);
        covmat=double(covmat);
        % j = whos('covmat');j.bytes=j.bytes*9.53674e-7;j

        % Options for the Eigenvectors extraction
        opts.issym = 'true'; %Options for the Eigenvectors extraction
        % opts.maxit = 100;
        % opts.disp = 1;
        % opts.tol = 1e-3;

        display('extracting eigenvectors...');drawnow
        if nPCs<size(covmat,1)
            [PcaTraces, CovEvals] = eigs(covmat, nPCs, 'LM', opts);
        else
            [PcaTraces, CovEvals] = eig(covmat);
            nPCs = size(CovEvals,1);
        end

        %At this stage PcaTraces is Ntime x nPCs, ie each column is an eigenvector
        %CovEvals is a square diagonal matrix with the eigenvalues on the diagonal
        %We only keep the diagonal values, ie we no longer have a diagonal matrix

        % Throw out negative eigenvalues
        display('throwing out negative eigenvalues...');drawnow
        CovEvals=diag(CovEvals);
        if nnz(CovEvals<=0)
            nPCs = nPCs - nnz(CovEvals<=0);
            PcaTraces = PcaTraces(:,CovEvals>0);
            CovEvals = CovEvals(CovEvals>0);
        end
        % sort based on values
        display('sorting PCs...');drawnow
        [CovEvals, indices]=sort(CovEvals, 'descend');
        PcaTraces=PcaTraces(:,indices);

        %Ensure that PcaFilters has variance 1
        display('setting variance to 1...');drawnow
        CovEvals = diag(CovEvals);
        CovEvals = CovEvals*Npixels;

        %Calculate the PcaFilters.
        display('extracting pca filters...');drawnow
        %We need to get the eigenvalues of the Movie, not of the covariance
        %matrix. This is the reason for 1/2 power.
        Sinv = inv(CovEvals.^(1/2));

        % Adjust nPCs
        nPCs = size(CovEvals,1);

        clear covmat CovEvals;
        covmat = [];
        CovEvals = [];
        inputMatrix = loadInputMatrix(inputMatrixPath,options);
        inputMatrix = modifyInputMatrix(inputMatrix);

        %Calculate the corresponding space filters
        PcaFilters = double(inputMatrix*PcaTraces*Sinv);

        %Now because the Filters are not an EXACT calculation, their variance can be slightly off 1. We make sure it is 1, as this can slightly affect the spatio-temporal ICA that expect normalize eigenvectors.
        for i=1:nPCs
            PcaFilters(:,i)=PcaFilters(:,i)/norm(PcaFilters(:,i));
        end

        % clear input matrix
        clear inputMatrix
        inputMatrix = [];

        %Reshape the filter to have a proper image inputMovie = cast(inputMovie,OldClass);
        PcaFilters = reshape(PcaFilters,DFOFsize(1),DFOFsize(2),nPCs);

    end
end