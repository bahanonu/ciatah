classdef progress < handle
%PROGRESS Wrapper class to provide an iterator object for loop creation
% -------------------------------------------------------------------------
% This class provides the possibility to create an iterator object in
% MATLAB to make the handling of ProgressBar() even easier. The following
% example shows the usage. Although no ProgressBar() is called by the user,
% a progress bar is shown. The input arguments are the same as for
% ProgressBar(), so please refer to the documentation of ProgressBar().
% 
% Note that this implementation is slower than the conventional
% ProgressBar() class since the subsref() method is called with
% non-optimized values in every iteration.
% 
% =========================================================================
% Example:
% 
% for k = progress(1:100)
%   % do some processing
% end
% 
% Or with additional name-value pairs:
% 
% for k = progress(1:100, ...
%     'Title', 'Computing...' ...
%     )
% 
%   % do some processing
% end
% 
% =========================================================================
%
% progress Properties:
%	none
%
% progress Methods:
%	progress - class constructor
% 
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  23-Jun-2016 19:24:50
%

% Version:  v1.0  initial version, 23-Jun-2016 (JA)
%           v1.1  rename variables and update documentation, 
%                 26-Jun-2016 (JA)
%


properties (Access = private)
    IterationList;
    ProgressBar;
end

methods
    % Class Constructor
    function self = progress(in, varargin)
        if ~nargin,
            return;
        end
        
        self.IterationList = in;
        
        % pass all varargins to ProgressBar()
        self.ProgressBar = ProgressBar(length(in), varargin{:});
    end
    
    % Class Destructor
    function delete(self)
        % call the destructor of the ProgressBar() object
        delete(self.ProgressBar);
    end
    
    function [varargout] = subsref(self, S)
    % This method implements the subsref method and only calls the update()
    % method of ProgressBar. The actual input 'S' is passed to the default
    % subsref method of the class of self.IterationList.
    
        self.ProgressBar.update();
        varargout = {subsref(self.IterationList, S)};
    end
    
    function [m, n] = size(self)
    % This method implements the size() function for the progress() class.
    
        [m, n] = size(self.IterationList);
    end
end
end





% End of file: progress.m
