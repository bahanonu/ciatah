function [outputVector] = normalizeVector(inputVector,varargin)
    % Normalizes a vector or matrix (2D or 3D) using the method specified
    % Biafra Ahanonu
    % started: 2014.01.14 [23:42:58]
    % inputs
    	% inputVector - 1D vector of any unit type. If a matrix, will normalize with respect the the entire matrix.
    % outputs
    	%

    % changelog
    	% 2014.02.17 added zero centered normalization
        % 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
        % 2021.10.08 [10:33:32] - Added percentile name-value options for soft zero to one.
    % TODO
    	%

    import ciapkg.api.* % import CIAtah functions in ciapkg package API.

    %========================
    % Str: oneToNegativeOne, oneToOne, zeroToOne, zeroToOneSoft, zeroCentered, zeroCenteredCorrect, dfof
    options.normRange = 'oneToNegativeOne';
    % Int: 0-100, max percentile value to use to calculate zeroToOneSoft
    options.prctileMax = 99;
    % Int: 0-100, min percentile value to use to calculate zeroToOneSoft
    options.prctileMin = 1;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    % 	eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================
    maxVec = nanmax(inputVector(:));
    minVec = nanmin(inputVector(:));
    meanVec = nanmean(inputVector(:));
    switch options.normRange
        case 'oneToNegativeOne'
            outputVector = ((inputVector-minVec)./(maxVec-minVec) - 0.5 ) *2;
        case 'oneToOne'
            outputVector = (inputVector-minVec)./(maxVec-minVec);
        case 'zeroToOne'
            % outputVector = (inputVector-minVec)./(maxVec-minVec);
            outputVector = (1-0)/(maxVec-minVec).*(inputVector-maxVec)+1;
        case 'zeroToOneSoft'
            maxVec = prctile(inputVector(:),options.prctileMax);
            minVec = prctile(inputVector(:),options.prctileMin);
            % outputVector = (inputVector-minVec)./(maxVec-minVec);
            outputVector = (1-0)/(maxVec-minVec).*(inputVector-maxVec)+1;
        case 'standardize'
            % vectorMean = nanmean(inputVector,2);
            % vectorStd = nanstd(inputVector,[],2);
            % outputVector = (inputVector-vectorMean)/vectorStd;
            maxVec = prctile(inputVector(:),95);
            minVec = prctile(inputVector(:),5);
            outputVector = (1-0)/(maxVec-minVec).*(inputVector-maxVec)+1;
        case 'zeroCentered'
            vectorMean = nanmean(inputVector,2);
            outputVector = bsxfun(@rdivide,inputVector,vectorMean)-1;
        case 'zeroCenteredCorrect'
            outputVector = inputVector-meanVec;
        case 'dfof'
            outputVector = inputVector/meanVec-1;
        otherwise
            % body
    end
end