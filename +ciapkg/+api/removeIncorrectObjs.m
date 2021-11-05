function [trackingTableFilteredCell] = removeIncorrectObjs(tablePath,varargin)
    % Removes incorrect objects from an ImageJ tracking CSV file
    % Biafra Ahanonu
    % started: 2014.05.01
    % inputs
        % tablePath - path to CSV file containing tracking information
    % outputs
        % trackingTableFiltered - table where each Slice (frame) only has a single associated set of column data, based on finding row with max area

    [trackingTableFilteredCell] = ciapkg.tracking.removeIncorrectObjs(tablePath,'passArgs', varargin);
end