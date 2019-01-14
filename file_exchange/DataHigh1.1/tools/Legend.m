function varargout = Legend(varargin)
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
                   'gui_OpeningFcn', @Legend_OpeningFcn, ...
                   'gui_OutputFcn',  @Legend_OutputFcn, ...
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



function Legend_OpeningFcn(hObject, eventdata, handles, varargin)
%  place the condition names with the appropriate color

    handles.LegendFig = hObject;
    handles.DataHighFig = varargin{1};
    hd = guidata(handles.DataHighFig);
    
    % find the number of epochs for each condition to let user choose which
    % epoch to use as the condition color
    max_num = 0;
    for idata = 1:length(hd.D)
        if (max_num < length(hd.D(idata).epochStarts))
            max_num = length(hd.D(idata).epochStarts);
        end
    end
    handles.max_num_epochs = max_num;
    set(handles.epoch_popupmenu, 'String', cellstr(num2str((1:handles.max_num_epochs)'))');
    
    
    % see how many conditions can be displayed on the axes
    handles.conds = unique({hd.D.condition});
    handles.conds = handles.conds(hd.selected_conds);
    handles.num_conds = length(handles.conds);
    
    set(gcf, 'CurrentAxes', handles.cond_axes);
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    set(gca, 'Box', 'on')
    ylim([0 15]);
    
    if (handles.num_conds <= 15)  % no need to have a slider
        set(handles.cond_slider, 'Visible', 'off');
        
        % print all the conditions and be done
        
    else
        % set slider parameters to fit number of conditions
        set(handles.cond_slider, 'Max', handles.num_conds-15);
        set(handles.cond_slider, 'Min', 0);
        set(handles.cond_slider, 'SliderStep', [1/(handles.num_conds-15) 1/(handles.num_conds-15)]);
        set(handles.cond_slider, 'Value', handles.num_conds-15);
        handles.bottomCondIndex = 15;
    end

    printConditions(handles);
    guidata(handles.LegendFig, handles);
end




function varargout = Legend_OutputFcn(hObject, eventdata, handles) 

end


% not used
function epoch_popupmenu_CreateFcn(hObject, eventdata, handles)
end



function epoch_popupmenu_Callback(hObject, eventdata, handles)
% should switch the currently selected epoch for condition difference

% Hints: contents = cellstr(get(hObject,'String')) returns epoch_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from epoch_popupmenu
    printConditions(handles);
end




function cond_slider_Callback(hObject, eventdata, handles)
% allows user to scroll down to see other condition colors
%  has to be at integer values

    value = get(handles.cond_slider, 'Value');
    % the slider should remain at integer values
    if (value ~= round(value))
        set(handles.cond_slider, 'Value', round(value));
    end
    
    value = get(handles.cond_slider, 'Value');
    
    % find which condition should be at the bottom
    handles.bottomCondIndex = handles.num_conds - value;
    guidata(handles.LegendFig, handles);
    
    printConditions(handles);

end


function cond_slider_CreateFcn(hObject, eventdata, handles)
% not used...
    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end


function printConditions(handles)
%  prints the text on the axes
%  handles.bottomCondIndex  is the index for the first condition to be on top
    hd = guidata(handles.DataHighFig);
    cla(gca);
    
    if (handles.num_conds <= 15)
        for i = 1:handles.num_conds
            t = text(0.025, 15-i, handles.conds{i});
            set(t, 'VerticalAlignment', 'bottom');
            set(t, 'FontSize', 13);
            members = find(ismember({hd.D.condition}, handles.conds{i}));
            set(t, 'Color', hd.D(members(1)).epochColors(get(handles.epoch_popupmenu, 'Value'), :));
        end
    else

        for i = 1:15
            t = text(0.025, 15-i, handles.conds{handles.bottomCondIndex-15+i});
            set(t, 'VerticalAlignment', 'bottom');
            set(t, 'FontSize', 13);
            members = find(ismember({hd.D.condition}, handles.conds{handles.bottomCondIndex-15+i}));
            set(t, 'Color', hd.D(members(1)).epochColors(get(handles.epoch_popupmenu, 'Value'), :));
        end
    end
end
