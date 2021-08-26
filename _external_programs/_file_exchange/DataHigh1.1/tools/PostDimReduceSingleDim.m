function varargout = PostDimReduceSingleDim(varargin)
% SingleDim displays all trajectories versus time for single dimensions
% As shown in Yu et. al (2009) with 15 dimensions
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

% Edit the above text to modify the response to help SingleDim

% Last Modified by GUIDE v2.5 11-Mar-2013 18:16:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PostDimReduceSingleDim_OpeningFcn, ...
                   'gui_OutputFcn',  @PostDimReduceSingleDim_OutputFcn, ...
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

function PostDimReduceSingleDim_OpeningFcn(hObject, eventdata, handles, varargin)
% opening function

    handles.D = varargin{1};
    handles.current_dim = 1;
    handles.max_dim = size(handles.D(1).data,1);
    
    % find maximum and min values of dimensions
    max_value = max(max([handles.D.data]));
    min_value = min(min([handles.D.data]));
    
    
    % prepare single axes
    hold(handles.single_axes, 'on');
    set(handles.single_axes, 'YLim', [min_value max_value]);
    
    % prepare the popup menu
    set(handles.single_dim_popup, 'String', cellstr(num2str((1:handles.max_dim)'))');
    set(handles.single_dim_popup, 'Value', 1);
    
    % plot the first dimension
    plot_trajs(handles);
    
    % Update handles structure
    guidata(hObject, handles);

end



function varargout = PostDimReduceSingleDim_OutputFcn(hObject, eventdata, handles) 
% closing function

end



function previous_button_Callback(hObject, eventdata, handles)
% Move to the previous dimension
    if (handles.current_dim - 1 < 1)
        handles.current_dim = handles.max_dim;
    else
        handles.current_dim = handles.current_dim - 1;
    end
    
    set(handles.single_dim_popup, 'Value', handles.current_dim);
   
    plot_trajs(handles);
    
    guidata(hObject, handles);
end





function next_button_Callback(hObject, eventdata, handles)
% Move to the next dimension
    if (handles.current_dim + 1 > handles.max_dim)
        handles.current_dim = 1;
    else
        handles.current_dim = handles.current_dim + 1;
    end
   
    set(handles.single_dim_popup, 'Value', handles.current_dim);
    
    plot_trajs(handles);
    
    guidata(hObject, handles);
end





function single_dim_popup_Callback(hObject, eventdata, handles)
% you can choose any dimension you'd like to observe

    contents = cellstr(get(hObject, 'String'));
    handles.current_dim = str2double(contents{get(hObject, 'Value')});

    plot_trajs(handles);
    
    guidata(hObject, handles);

end



function single_dim_popup_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function plot_trajs(handles)
% clears and plots all trajs of the current dimension

    cla(handles.single_axes);

    for itrial=1:length(handles.D)
        plot(handles.single_axes, handles.D(itrial).data(handles.current_dim,:), '-', 'Color', [.7 .7 .7]);
    end

end





function single_dim_help_Callback(hObject, eventdata, handles)
% gives the user a help message about single dims

    helpbox(['The SingleDim tool plots each orthonormalized latent\n' ...
        'variable on separate, individual plots.\n\n' ...
        'If a latent variable does not vary across trials or experimental\n' ...
        'conditions, that latent variable probably does not contribute\n' ...
        'much to explaining the data, and can be removed from the analyses.']);
end
