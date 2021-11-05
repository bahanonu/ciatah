function [options] = getSettings(functionName)
    % Send back default options to getOptions, users can modify settings here.
    % Biafra Ahanonu
    % started: 2014.12.10
    %
    % inputs
    %   functionName - name of function whose option should be loaded
    %
    % note
    %   don't let this function call getOptions! Else you'll potentially get into an infinite loop.

    [options] = ciapkg.settings.getSettings(functionName,'passArgs', varargin);
end