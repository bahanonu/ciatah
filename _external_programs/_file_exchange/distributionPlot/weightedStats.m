function [weightedMean,weightedStdOfMean,weightedStdOfSample] = weightedStats(data, weightsOrSigma,sw)
%wStats calculates weighted statistics (mean, stdev of mean) for a list of inputs with corresponding weights or {std}
%
%SYNOPSIS [weightedMean,weightedStd] = weightedStats(data, weightsOrSigma,sw)
%
%INPUT data: vector of imput values. 
%
%      weightsOrSigma: weights or standardDeviations of the input data
%      sw (opt): switch, either 'w' or {'s'}
%
%       -> if either data or weights are matrices, the computation is done
%       column-wise
%
%OUTPUT weightedMean: mean of the data weighted with weights (rowVector)
%       weightedStdOfMean: sigma1 = sqrt[sum_i{(yi-mw)^2/sigmai^2}/((n-1)*sum_i{1/sigmai^2})]
%           which is the general weighted std OF THE MEAN (not the sample, i.e. it is divided by sqrt(n))
%       weightedStdOfSample = weightedStdOfMean * sqrt(n)
%       
%       CAUTION: according to www-gsi-vms.gsi.de/eb/people/wolle/buch/error.ps, if
%       the uncertainity of the data points is much larger than the
%       difference between them, sigma1 underestimates the "true" sigma.
%       Hence, sigma2 = sqrt[1/sum_i{1/sigmai^2}] should be used. In
%       general, the true sigma is to be max(sigma1,sigma2)
%
%reference: Taschenbuch der Mathematik, p. 815
%
%c: 06/03 jonas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%test input: count input arguments
if nargin < 2 | isempty(weightsOrSigma) | isempty(data)
    error('not enough or empty input arguments!')
end
weights = weightsOrSigma;

%test input: data size
sDat = size(data);
sIS = size(weights);

if any(sDat ~= sIS)
    %one is a matrix and the other a vector, or bad user input
    if sDat(1) ~= sIS(1)
        if sDat(1) == sIS(2) & sDat(2) == sIS(1)
            %bad user input: badly arranged vectors: make col-vectors
            if sDat(1) == 1
                data = data';
            else
                weights = weights';
            end
        else
            %bad user input: fatal
            error('bad input data size: if you want to specify a vector and a matrix for input, use a column-vector!')
        end
    else
        %one's a vector, the other a matrix
        if sDat(2) == 1
            %make data a matrix
            data = data*ones(1,sIS(2));
        elseif sIS(2) == 1
            %make weights a matrix
            weights = weights*ones(1,sDat(2));
        else
            %bad input
            error('bad input data size: specify either two matrices of equal size or a matrix and a vector or two vectors')
        end
    end
else
    if sDat(1) == 1
        %make both col vectors
        data = data';
        weights = weights';
    end
end

%get # of data points
numRows = size(data,1);
numCols = size(data,2);

%calculate weights if necessary
if nargin == 2 | ~(strcmp(sw,'w')|strcmp(sw,'s'))
    sw = 's';
end
if strcmp(sw,'s')
    %w = 1/sigma^2
    if any(weights == 0)
        warning('WEIGHTEDSTATS:SigmaIsZero','At least one sigma == 0; set to eps');
	weights = max(weights,eps);
    end
    %assign weight 1 to the measurement with smallest error
    weights = (repmat(min(weights,[],1),numRows,1)./weights).^2; 
end


%make sure the weights are positive
weights = abs(weights);


%calc weightedMean : each dataPoint is multiplied by the corresponding weight, the sum is divided
%by the sum of the weights
sumWeights = nansum(weights,1);
weightedMean = nansum(weights.*data,1)./sumWeights;

%---calc weightedStd---
squareDiffs = (data-repmat(weightedMean,numRows,1)).^2;
weightedSSQ = nansum(squareDiffs.*weights,1);


switch sw
    
    case 'w'
        
        %weighted mean : each squared difference from mean is weighted and divided by
        %the number of non-zero weights http://www.itl.nist.gov/div898/software/dataplot/refman2/ch2/weightsd.pdf
        
        %get divisor (nnz is not defined for matrices)
        for i=numCols:-1:1
            % set NaN-weights to 0
            nanWeights = isnan(weights(:,i));
            weights(nanWeights,i) = 0;
            nnzw = nnz(weights(:,i));
            divisor(1,i) = (nnzw-1)/nnzw*sumWeights(i);
        end
        
        %assign output
        sigma = sqrt(weightedSSQ./divisor);
        weightedStdOfSample = sigma;
        weightedStdOfMean = sigma/sqrt(nnzw);
        
    case 's'
        %calculate sigma1 = sqrt[sum_i{(yi-mw)^2/sigmai^2}/((n-1)*sum_i{1/sigmai^2})]
        %which is the general weighted std OF THE MEAN (not the sample, i.e. it is divided by sqrt(n))
        %
        %CAUTION: according to www-gsi-vms.gsi.de/eb/people/wolle/buch/error.ps, if
        %the uncertainity of the data points is much larger than the
        %difference between them, sigma1 underestimates the "true" sigma.
        %Hence, sigma2 = sqrt[1/sum_i{1/sigmai^2}] should be used. In
        %general, the true sigma is to be max(sigma1,sigma2)

        
        %sigma1. Correct number of observations
        numRows = sum(~isnan(data) & ~isnan(weights),1);
        divisor = (numRows-1).*sumWeights;
        sigma1 = sqrt(weightedSSQ./divisor);
        
        %sigma2
        %sigma2 = sqrt(1/sumWeights);
        
        %assign output
        %weightedStdOfMean = max(sigma1,sigma2);
        weightedStdOfMean = sigma1;
        weightedStdOfSample = sigma1.*sqrt(numRows);
        
        
end
