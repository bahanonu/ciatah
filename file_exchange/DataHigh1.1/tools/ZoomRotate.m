function varargout = ZoomRotate(varargin)
% ZoomRotate
%
% Allows the user to zoom the display, change the speed of rotation, and
% spin the current axes.
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
                       'gui_OpeningFcn', @ZoomRotate_OpeningFcn, ...
                       'gui_OutputFcn',  @ZoomRotate_OutputFcn, ...
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



function ZoomRotate_OpeningFcn(hObject, eventdata, handles, varargin)
    
    handles.DataHighFig = varargin{1};
    handles.ZoomRotateFig = hObject;
    guidata(hObject, handles);

    
    
    % prepare zoom slider
    hd = guidata(handles.DataHighFig);
    handles.old_proj_vecs = hd.proj_vecs;
    guidata(hObject, handles);
    conds = unique({hd.D.condition});
    % set bounds to highest var in PC1 and lowest in the last PC
    [u sc lat] = princomp([hd.D(ismember({hd.D.condition}, conds(hd.selected_conds))).data]');
    set(handles.zoom_slider, 'Max', 5*sqrt(lat(1)));
    set(handles.zoom_slider, 'Min', sqrt(lat(end)));
    if (hd.max_limit < sqrt(lat(end)) || hd.max_limit > 5*sqrt(lat(1)))  % the max_limit needs to be updated
        hd.max_limit = (5*sqrt(lat(1))+sqrt(lat(end)))/2;
        guidata(handles.DataHighFig, hd);
        figure(hd.DataHighFig);
        hd.functions.choose_conditions(hd.DataHighFig, hd.selected_conds);
        figure(handles.ZoomRotateFig);
    end
    set(handles.zoom_slider, 'Value', hd.max_limit);


    % prepare alpha slider
    hd = guidata(handles.DataHighFig);
    % set bounds to 1/2pi and highest to pi/3
    set(handles.rot_speed_slider, 'Max', pi/3);
    set(handles.rot_speed_slider, 'Min', 1/1000);
    set(handles.rot_speed_slider, 'Value', hd.alpha);
    
    
    % prepare spin slider
    hd = guidata(handles.DataHighFig);
    set(handles.spin_slider, 'Max', pi);
    set(handles.spin_slider, 'Min', -pi);
    set(handles.spin_slider, 'Value', 0);

end


% --- Outputs from this function are returned to the command line.
function varargout = ZoomRotate_OutputFcn(hObject, eventdata, handles) 


end



function zoom_slider_Callback(hObject, eventdata, handles)
% change the zoom (x,y limits) for the current projection

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    hd = guidata(handles.DataHighFig);
    
    hd.max_limit = get(hObject, 'Value');
    guidata(handles.DataHighFig, hd);
    
    figure(hd.DataHighFig);
    hd.functions.choose_conditions(hd.DataHighFig, hd.selected_conds);
    figure(handles.ZoomRotateFig);

end




function zoom_slider_CreateFcn(hObject, eventdata, handles)

    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end



function rot_speed_slider_Callback(hObject, eventdata, handles)
% changes the rotational speed of the main axes

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    hd = guidata(handles.DataHighFig);
    
    hd.alpha = get(hObject, 'Value');
    guidata(hd.DataHighFig, hd);
    
end

function rot_speed_slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end


function spin_slider_Callback(hObject, eventdata, handles)
% change the projection vectors to "spin" the projection

    hd = guidata(handles.DataHighFig);
    angle = get(hObject, 'Value');
    
    R = [cos(angle) -sin(angle); sin(angle) cos(angle)];
    hd.proj_vecs = R * handles.old_proj_vecs;
    [hd.Q1 hd.Q2] = hd.functions.calculateQ(hd.DataHighFig, hd);
    guidata(hd.DataHighFig, hd);
    
    figure(hd.DataHighFig);
    hd.functions.choose_conditions(hd.DataHighFig, hd.selected_conds);
    figure(handles.ZoomRotateFig);
    

end


function spin_slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end



function zoom_rotate_helpbutton_Callback(hObject, eventdata, handles)
% help button for zoom and rotate
    
    helpbox(['Zoom will scale the current 2-d projection.\n\n' ...
        'Rotation Speed controls how fast the 2-d projection plane rotates.\n\n' ...
        'Rotate in Plane takes the current 2-d projection and ''''spins'''' it\n' ...
        'by the chosen angle. This is like rotating a saved image with\n' ...
        'photo-editing software.\n']);
end
