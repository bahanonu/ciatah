function [matchIndsReal, matchIndsEst, meanDist] = computeCentroidMatches(realCellParams, estCellParams, varargin)
    % Matches real and estimates cells based on centroid location.
    % Lacey Kitsch & Biafra Ahanonu
    % started: updating 2016.04.24
    % inputs
        %
    % outputs
        %


    [matchIndsReal, matchIndsEst, meanDist] = ciapkg.image.computeCentroidMatches(realCellParams, estCellParams,'passArgs', varargin);
end