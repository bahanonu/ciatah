function [outputVector] = normalizeVector(inputVector,varargin)
    % Normalizes a vector or matrix (2D or 3D) using the method specified
    % Biafra Ahanonu
    % started: 2014.01.14 [23:42:58]
    % inputs
    	% inputVector - 1D vector of any unit type. If a matrix, will normalize with respect the the entire matrix.
    % outputs
    	%

    [outputVector] = ciapkg.signal_processing.normalizeVector(inputVector,'passArgs', varargin);
end