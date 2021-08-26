function varargout = Weights(varargin)
%  Pops out a simple figure that shows the weights of the projection
%  vectors
%   Possible ideas:
%    Have user manipulate bars to change the projection vector values
%    Inset the bar graphs into the DataHigh display, so as the person is
%    navigating, it instantly updates the weights
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

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @Weights_OpeningFcn, ...
                       'gui_OutputFcn',  @Weights_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end


function Weights_OpeningFcn(hObject, eventdata, handles, varargin)
    h = guidata(varargin{1});
    
    set(gcf, 'CurrentAxes', handles.axes1);
    bar(1:h.num_dims, h.proj_vecs(1,:));
    ylim([-1 1]);
    
    set(gcf, 'CurrentAxes', handles.axes2);
    bar(1:h.num_dims, h.proj_vecs(2,:));
    ylim([-1 1]);
end



function varargout = Weights_OutputFcn(hObject, eventdata, handles) 

end


function weights_helpbutton_Callback(hObject, eventdata, handles)
% help button for weights

    helpbox(['Displays the current projection vectors'' weights.\n\n' ...
        'If a latent dimension has a large weight, that dimension\n' ...
        'contributes to the current 2-d projection.\n\n' ...
        'A small weight implies that the corresponding latent dimension\n' ...
        'is not well represented in the current 2-d projection.']);
end
