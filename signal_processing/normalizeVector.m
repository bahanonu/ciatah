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
    % TODO
    	%

    %========================
    % Str: oneToNegativeOne, oneToOne, zeroToOne, zeroToOneSoft, zeroCentered, zeroCenteredCorrect, dfof
    options.normRange = 'oneToNegativeOne';
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
            maxVec = prctile(inputVector(:),95);
            minVec = prctile(inputVector(:),5);
            % outputVector = (inputVector-minVec)./(maxVec-minVec);
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