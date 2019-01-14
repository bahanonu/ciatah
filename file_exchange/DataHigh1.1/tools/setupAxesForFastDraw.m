function setupAxesForFastDraw(ha)
% setupAxesForFastDraw(ha)
%
% Based in part on Matlab's doc_perfex, this function sets up the
% properties of a set of axes to speed up drawing. A bunch of camera and
% tick modes get set to manual, and the DrawMode gets set to fast.
%
% ha is the handle to the axes object
%
% ***THIS FUNCTION MAY NO LONGER BE USED.  SUGGESTED TO REMOVE. BRC
% 9/26/2013
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

set(ha, 'DrawMode', 'fast');
% According to the original documentation for doc_perfex:
% Do not set CameraViewAngleMode, DataAspectRatioMode,
% and PlotBoxAspectRatioMode to avoid exposing a bug
%
% In addition, there appears to be a bug introduced when setting
% CameraPositionMode or CameraTargetMode to manual. Whatever.
pn = {'ALimMode', ...
  'CameraUpVectorMode','CLimMode',...
  'TickDirMode','XLimMode',...
  'YLimMode','ZLimMode',...
  'XTickMode','YTickMode',...
  'ZTickMode','XTickLabelMode',...
  'YTickLabelMode','ZTickLabelMode'};

% For reference, the list of properties set by doc_perfex:
% pn = {'ALimMode',...
%   'CameraPositionMode','CameraTargetMode',...
%   'CameraUpVectorMode','CLimMode',...
%   'TickDirMode','XLimMode',...
%   'YLimMode','ZLimMode',...
%   'XTickMode','YTickMode',...
%   'ZTickMode','XTickLabelMode',...
%   'YTickLabelMode','ZTickLabelMode'};

pv = repmat({'manual'}, 1, length(pn));
set(ha, pn, pv);
