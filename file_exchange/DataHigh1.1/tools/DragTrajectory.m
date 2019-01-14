function varargout = DragTrajectory(varargin)
% DragTrajectory
%
%  Allows users to interactively change the dimension data by 
%  "dragging" and thus changing the values for each dimension.
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

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @DragTrajectory_OpeningFcn, ...
                       'gui_OutputFcn',  @DragTrajectory_OutputFcn, ...
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


function DragTrajectory_OpeningFcn(hObject, eventdata, handles, varargin)
% opening function
    handles.DataHighFig = varargin{1};
    handles.functions = varargin{2};
    hd = guidata(handles.DataHighFig);
    handles.selected_trial = hd.current_trial_selected;
    handles.D = hd.D;

    trials_list_Initialization(handles.trials_list, handles);
    handles = guidata(hObject);
    initialize_plots(hObject, handles);

    
    
end

function varargout = DragTrajectory_OutputFcn(hObject, eventdata, handles) 
% output function
end


function initialize_plots(hObject, handles)
%  set up all axes with impoints and correct projections

    hd = guidata(handles.DataHighFig);
    
    % find max

    handles.max_limit = max(max(abs(handles.D(handles.selected_trial).data)));

    
    % set up axes
    handles.panels = zeros(1, hd.num_dims);
    for ax = 1:17
        if (ax > hd.num_dims)
            h = handles.(sprintf('axes%d', ax));
            t = handles.(sprintf('text%d', ax));
            set(h, 'Visible', 'off');
            set(t, 'Visible', 'off');
        else
            handles.panels(ax) = handles.(sprintf('axes%d', ax));
            set(handles.panels(ax), 'NextPlot', 'replacechildren');
            set(handles.panels(ax), 'XTick', []);
            set(handles.panels(ax), 'YTick', []);
            set(handles.panels(ax), 'Box', 'on'); 
            set(handles.panels(ax), 'YLim', [-handles.max_limit handles.max_limit]);
            set(handles.panels(ax), 'XLim', [1 size(handles.D(handles.selected_trial).data,2)]);
        end
    end
    
    % set up mainAxes
    set(handles.mainAxes, 'NextPlot', 'replacechildren');
    set(handles.mainAxes, 'XTick', []);
    set(handles.mainAxes, 'YTick', []);
    set(handles.mainAxes, 'Box', 'on');  
    
    % plot original dimensions
    for dim = 1:length(handles.panels)
        set(gcf, 'CurrentAxes', handles.panels(dim));
        % plot original
        line(1:size(handles.D(handles.selected_trial).data,2), handles.D(handles.selected_trial).data(dim,:), 'Color', [0 .7 0], 'HitTest', 'off',...
            'UserData', 1);
        
        % save the points as full so we can use the impoint functions
        [spliner handles.points{dim}] = create_IMpoints(handles.panels(dim), handles.D(handles.selected_trial).data(dim,:));

        line(1:length(spliner), spliner, 'Color', [0 0 .7], 'HitTest', 'off', 'UserData', 3);
        
    end
    
    plot_mainAxes(handles);

    guidata(hObject, handles);
    
end


function [spliner pts] = create_IMpoints(panel, data)
% creates impoints on the plot 
    set(gcf, 'CurrentAxes', panel);
    
    hold(gca, 'on');
    point_indices = [1:5:length(data)-1 length(data)];
    spliner = spline(point_indices, data(point_indices), 1:length(data));
    pts = [];
    index = 1;
    for i = point_indices
        pts{index} = impoint(panel, i, spliner(i));
        setPositionConstraintFcn(pts{index}, @constrainPosition);
        addNewPositionCallback(pts{index},@updatePanel);
        index = index + 1;
    end
end


function [points_t points_y] = get_point_positions(handles, dim)
% helper function returns the point_indices for every impoint
    pts = handles.points{dim};
    for i = 1:length(handles.points{dim})
        pos = getPosition(pts{i});
        points_t(i) = pos(1);
        points_y(i) = pos(2);
    end 
end



function newPos = constrainPosition(pos)
% keeps the impoints constrained to their current x positions

    handles = guidata(gcf);
    
    if (length(gco) == 0)  %ignore the positional changes when internally move points
        newPos = pos;
        return
    end

    newPos = pos;
    %find the axes number we are on
    axesNum = find(handles.panels == gca);


    %find the current point that was moved
    [point_indices chugs] = get_point_positions(handles, axesNum);

    % get current point by finding the position in the gco
    g = get(gco);
    g = g.Children(1);
    oldPosition = get(g, 'XData');

    point_index = find(point_indices == oldPosition);

    current_point = handles.points{axesNum}{point_index};

    %get old position

    newPos(1) = point_indices(point_index);
    
    if (pos(2) > handles.max_limit)
        newPos(2) = handles.max_limit;
    elseif (pos(2) < -handles.max_limit)
        newPos(2) = -handles.max_limit;
    else
        newPos(2) = pos(2);
    end
end

function updatePanel(pos)
% impoint Callback that updates the spline, mainAxes, and the impoints
% closest to the moved impoint

    handles = guidata(gcf);

    %find the axes we are on
    currentAxesIndex = find(handles.panels == gca);

    if (isempty(gco))
        %this is a "ghost" position change...
        %   by changing the position of the impoints near the selected
        %   impoints, updateGraph is called on those impoints as well
        %   (but we don't want to update the graph each time)
        return;
    end


    %get the impoint that has been moved
    g = get(gco);
    child = g.Children(1);
    current_position = get(child, 'XData');
    if (current_position ~= pos(1)) % check if gco is the same as the given position
        % again, ghost impoints, but i'm not sure why we are getting
        %    empty gco's then...
        return
    end

    % get impoints of current axes
    ptsDimPoints = handles.points{currentAxesIndex};
    % get the number of impoints for axes
    numImpoints = length(ptsDimPoints);

    %update the current impoint and the two closest to it
    %   (half the distance though)
    [point_positions data] = get_point_positions(handles, currentAxesIndex);
    current_index = find(point_positions == current_position);  % points to the index in ptsDimPoints
    current_point = ptsDimPoints{current_index};
    current_position = getPosition(current_point);

    %   don't forget to update the impoints!
    if (current_index >= 1 && current_index < numImpoints)     % only update the rightPosition if index in range
        right_point = handles.points{currentAxesIndex}{current_index + 1};
        oldPos = getPosition(right_point);
        changeInPosition = (current_position(2) - oldPos(2))/16;
        setPosition(right_point, [oldPos(1) oldPos(2)+changeInPosition]);
    end

    if (current_index > 1 && current_index <= numImpoints)     % update leftPosition if index is in range
        left_point = handles.points{currentAxesIndex}{current_index - 1};
        oldPos = getPosition(left_point);
        changeInPosition = (current_position(2) - oldPos(2))/16;
        setPosition(left_point, [oldPos(1) oldPos(2)+changeInPosition]);
    end

    spliner = spline(point_positions, data, 1:point_positions(end));

    handles.D(handles.selected_trial).data(currentAxesIndex,:) = spliner;

    % remove the old plot (but not the original)
    children = get(handles.panels(currentAxesIndex), 'Children');
    types = get(children, 'UserData');
    if (iscell(types))
        types = cell2mat(types);
    end
    spliner_handle = children(types == 3);  %finds the spliner line
    set(spliner_handle, 'YData', spliner);

    % replot the mainAxes
    plot_mainAxes(handles);
    
    guidata(gcf, handles);
end



function plot_mainAxes(handles)
%  plot the traj on mainAxes
    hd = guidata(handles.DataHighFig);
    
    %  in future, possibly add grayed out other trajectories for that
    %  condition
    
    p = hd.proj_vecs * handles.D(handles.selected_trial).data;
    
    plot(handles.mainAxes, p(1,:), p(2,:), 'LineWidth', 3);
    
end



function trials_list_Callback(hObject, eventdata, handles)
% user selected a particular trial

% Hints: contents = cellstr(get(hObject,'String')) returns trials_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trials_list
    contents = cellstr(get(hObject, 'String'));
    handles.selected_trial = str2num(contents{get(hObject, 'Value')});

    clearAllPanels(handles);
    initialize_plots(hObject, handles);
    
end


function trials_list_CreateFcn(hObject, eventdata, handles)
%  fills the listbox with trial numbers

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    
end

function trials_list_Initialization(hObject, handles)
% helper function that readies the list box
    list_items = [];
    index = 1;
    for list_item = 1:length(handles.D)
        if (strcmp(handles.D(list_item).type, 'traj'))
            list_items{index} = num2str(list_item);
            index = index + 1;
        end
    end
    if (handles.selected_trial == 0)
        handles.selected_trial = str2num(list_items{1});
    end
   
    set(hObject, 'String', list_items);
    set(hObject, 'Value', find(ismember(list_items, num2str(handles.selected_trial))));
    guidata(hObject, handles);
end


function clearAllPanels(handles)
% clear all the panels
    for i = 1:length(handles.panels)
        cla(handles.panels(i));
    end
end


function save_changes_button_Callback(hObject, eventdata, handles)
% Upload the changes to actual data
    hd = guidata(handles.DataHighFig);
    hd.D = handles.D;  % replace the old data with the new version
    guidata(handles.DataHighFig, hd);
    
    close(gcf);
    
    figure(handles.DataHighFig);   % make DataHigh the active figure to plot
    handles.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);  % replot everything
end


function load_original_button_Callback(hObject, eventdata, handles)
% loads the original data (replacing any changes made by DragTrajectory
    hd = guidata(handles.DataHighFig);
    handles.D = hd.orig_data;
    guidata(hObject, handles);
    
    clearAllPanels(handles);
    initialize_plots(hObject, handles);
end



function drag_traj_helpbutton_Callback(hObject, eventdata, handles)
% help button for drag trajectories

    helpbox(['Drag Trajectory allows the user to change the values of latent\n' ...
        'variables.  This can aid in understanding how individual latent\n' ...
        'variables contribute to the neural trajectory.\n\n' ...
        'The user can select a trial and plot each latent variable for\n' ...
        'that trial''s neural trajectory.  Click and drag any of the blue\n' ...
        'markers to modify the latent variables'' values.  The changes\n' ...
        'can be uploaded to DataHigh or reset to their original values.']);
end
