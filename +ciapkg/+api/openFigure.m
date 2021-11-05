function [figHandle, figAdd] = openFigure(figNo, figSize,varargin)
    % Opens a figure, if default not set to docked, opens figure on the left half of the screen.
    % Biafra Ahanonu
    % started: 2013.10.29
    % inputs
        %
    % outputs
        %
    if nargin==1
        [figHandle, figAdd] = ciapkg.view.openFigure(figNo, '','passArgs', varargin);
    else
        [figHandle, figAdd] = ciapkg.view.openFigure(figNo, figSize,'passArgs', varargin);
    end
end