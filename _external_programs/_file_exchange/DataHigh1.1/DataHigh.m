function DataHigh(varargin)
%  DataHigh is a graphical user interface to interact with and
%     visualize high-dimensional population activity.
%
% Usage: DataHigh(D, ...)
%
% INPUT:
%
%  D: struct (where D(i) refers to the ith trial or ith condition)
%     data  [neurons x 1ms time bins] (for DimReduce) or
%           [latent variables x data points] (for DataHigh)
%     type ['traj', 'state']  (optional field if using DimReduce)
%     condition  [condition identifier in String format] (optional field)
%     epochStarts [indices x 1] (optional field)
%     epochColors [indices x 3] (optional field)
%
%  'DimReduce' (optional)
%     - perform dimensionality reduction before starting DataHigh
%     - suggested if user is inputting raw data (spike trains)
%     Ex.:   DataHigh(D, 'DimReduce')
%
%  Website:
%    http://www.ece.cmu.edu/~byronyu/software/DataHigh/datahigh.html
%
%  Authors:
%       Benjamin Cowley, Carnegie Mellon University, 
%       Matthew Kaufman, Stanford University
%       Zachary Butler, University of California-Irvine
%  Contributors:
%       Byron Yu, Carnegie Mellon University
%  Contact:
%       datahigh@gmail.com
%
%  Getting started with your own data:
%  1. Create a struct D, where field
%       D(i).data [neurons x 1ms timebins] is
%       a matrix of 0's and 1's whose rows are the spike
%       trains for the ith trial.
%  2. Enter "DataHigh(D, 'DimReduce')" into the Matlab
%       command line.  The DimReduce figure pops up.
%
%  Quick tutorial for DataHigh:
%  1.  Go to the examples/ folder.
%  2.  Enter "ex2_visualize" into the Matlab command line.
%  3.  Use the preview panels (to the left and right of the
%       central panel) to rotate the projection plane.
%  
%  ***Please see instructional videos and step-by-step tutorials
%   on the DataHigh website.  The tutorials are also in the
%   User Guide.***
%
%
%  Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013

% ---GNU General Public License Copyright---
% This file is part of DataHigh.
% 
% DataHigh is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, version 2.
% 
% DataHigh is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details in COPYING.txt found
% in the main DataHigh directory.
% 
% You should have received a copy of the GNU General Public License
% along with DataHigh.  If not, see <http://www.gnu.org/licenses/>.
%
% If planning to re-distribute, do not delete original code 
% (but original code can be commented out).  Make changes clear, 
% obvious, and well-documented.  All changes must be explicitly 
% listed in an added section at the top of the changed file, 
% the main DataHigh.m file, and in a readme_CHANGES.txt file 
% in the main DataHigh directory. Explicitly list the authors
% who made the changes, and that the original authors do not
% endorse any changes.  If changes are useful, consider 
% contacting the authors to incorporate into the next DataHigh 
% code release.
%
% Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013
    
    
    
    % check if DataHigh is already added to the path or not, then add the
    % functions

    w = which('DataHigh_engine');
    if (isempty(w)) % DataHigh_engine not found
        currentFolder = fileparts(which('DataHigh'));
        addpath(fullfile(currentFolder));
        addpath(fullfile(currentFolder, 'gui'));
        addpath(fullfile(currentFolder, 'tools'));
        addpath(fullfile(currentFolder, 'data'));
        addpath(fullfile(currentFolder, 'util'));
        addpath(fullfile(currentFolder, 'gpfa'));
        % folders inside gpfa
        addpath(fullfile(currentFolder, 'gpfa/core_gpfa'));
        addpath(fullfile(currentFolder, 'gpfa/core_twostage'));
        addpath(fullfile(currentFolder, 'gpfa/plotting'));
        addpath(fullfile(currentFolder, 'gpfa/util'));
        addpath(fullfile(currentFolder, 'gpfa/util/precomp'));
        addpath(fullfile(currentFolder, 'gpfa/util/invToeplitz'));
        
        % use mac figures (the differences between mac and windows are BIG)
        if (ismac)
            addpath(fullfile(currentFolder, 'mac_figs'));
        else
            addpath(fullfile(currentFolder, 'windows_figs'));
        end
    end
    
    % check correct number of arguments
    if (length(varargin) == 1)
        DataHigh_engine(varargin{1});
    elseif (length(varargin) == 2 && strcmp(varargin{2}, 'DimReduce'))
        DataHigh_engine(varargin{1}, 'DimReduce');
    else
        disp(char(10));
        disp('Incorrect number of arguments, try: DataHigh(D) or DataHigh(D, ''DimReduce'').');
        disp('Please see "help DataHigh" or consult the User''s Manual for further information.');     
    end
end
