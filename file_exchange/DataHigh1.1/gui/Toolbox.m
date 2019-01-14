function varargout = Toolbox(varargin)
% Toolbox
%
%  A whole host of choices to enhance the experience of DataHigh.
%  This includes input/output options, including saving the projection
%  vectors, uploading new datasets, and modifying the current datasets.
%
%  Features refer to things that change the display of the main axes.
%  Options refer to pop-up figures that provide further utility.
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
                   'gui_OpeningFcn', @Toolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @Toolbox_OutputFcn, ...
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



% --- Executes just before Toolbox is made visible.
function Toolbox_OpeningFcn(hObject, eventdata, handles, varargin)
    
    
    initialize_handles(hObject, handles, varargin{1}, varargin{2});
    handles = guidata(hObject);
    
    
    % Choose default command line output for Toolbox
    handles.output = hObject;

    
    % activate which panel is to be shown
    activate_panel(hObject, handles, 'cond');
    handles = guidata(hObject);
    
    % place the condition buttons in the condition panel
    place_conditions(hObject, handles);
    handles = guidata(hObject);
    
    
    % disable buttons if inappropriate (i.e., if only trajs, disable all
    % state buttons
    disable_buttons(hObject, handles);
    handles = guidata(hObject);
    
    
    % create struct that stores saved projections
    handles.saved_projs = struct('proj_vecs', repmat({[]},1,6), 'selected_cond', repmat({[]}, 1,6), ...
        'selected_feats', repmat({[]},1,6));
    handles.saved_projs_index = 0;
    
    
    %  put buttons in correct toggle states
    set(handles.trajectories_button, 'Value', handles.selected_feats(1));
    set(handles.cues_button, 'Value', handles.selected_feats(2));
    set(handles.datapoints_button, 'Value', handles.selected_feats(3));
    set(handles.cov_ellipses_button, 'Value', handles.selected_feats(4));
    set(handles.first_pc_button, 'Value', handles.selected_feats(5));    
    set(handles.avg_traj_button, 'Value', handles.selected_feats(6));
    set(handles.origin_button, 'Value', handles.selected_feats(7));
    set(handles.cluster_means_button, 'Value', handles.selected_feats(8));
    set(handles.depth_percept_button, 'Value', handles.selected_feats(9));
    set(handles.traj2_anns_togbutton, 'Value', 1);  % always "selected"
    set(handles.state1_anns_togbutton, 'Value', 1);
    
    
    % set up the saved projection axes
    for i = 1:6
        handles.saved_proj_axes(i) = handles.(sprintf('saved_proj%d',i));
        handles.functions.setUpPanel(handles.saved_proj_axes(i), handles.max_limit);
        set(handles.saved_proj_axes(i), 'ButtonDownFcn', @Saved_Proj_ButtonDownFcn);
    end
    
    
    
    guidata(hObject, handles);

end



% --- Outputs from this function are returned to the command line.
function varargout = Toolbox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;

    set(gcf, 'Units', 'normalized', 'OuterPosition', [.85 0 .15 1]);
end


% control for the toggle buttons in the upper "toolbox"

function cond_button_Callback(hObject, eventdata, handles)
    place_conditions(handles.ToolboxFig, handles); % they may be updated through UpdateData
    handles = guidata(hObject);
    activate_panel(hObject, handles, 'cond');
end

function anns_button_Callback(hObject, eventdata, handles)
% if D has all states, then jump to states, else go to trajs

    hd = guidata(handles.DataHighFig);
    
    if (all(ismember({hd.D.type}, 'state')))
        activate_panel(hObject, handles, 'state_anns');
    else
        activate_panel(hObject, handles, 'traj_anns');
    end
end

function opt_button_Callback(hObject, eventdata, handles)
    activate_panel(hObject, handles, 'opt');
end

function saved_projs_button_Callback(hObject, eventdata, handles)
    activate_panel(hObject, handles, 'saved_projs');
end





%%%  Conditions  %%%

function recenter_data_button_Callback(hObject, eventdata, handles)
% recenters the data based on the currently selected conditions

    
    figure(handles.DataHighFig);
    h = guidata(handles.DataHighFig);
    handles.functions.recenter_data(handles.DataHighFig, h);
    
    figure(handles.ToolboxFig);
end


function legend_button_Callback(hObject, eventdata, handles)
% pops up a legend that shows the conditions with colors

    Legend(handles.DataHighFig);
    
end



%%%  Trajectory Features  %%%

function traj2_anns_togbutton_Callback(hObject, eventdata, handles)
% this is disabled...you are already looking at Trajectories annotations
    set(handles.traj2_anns_togbutton, 'Value', 1);
end

function state2_anns_button_Callback(hObject, eventdata, handles)
% switches to activate the cluster features panel
    activate_panel(hObject, handles, 'state_anns');
end

function trajectories_button_Callback(hObject, eventdata, handles)
% plots the trajectories for each selected condition
    h = guidata(handles.DataHighFig);
    
    if (get(hObject, 'Value') == 0)
        h.selected_feats(1) = 0;
    else
        h.selected_feats(1) = 1;
    end
    guidata(handles.DataHighFig, h);
    
    update_axesMain(handles);
end

function avg_traj_button_Callback(hObject, eventdata, handles)
%  plots the average trajectory for each condition
    h = guidata(handles.DataHighFig);

    if (get(hObject, 'Value') == 0)
        h.selected_feats(6) = 0;
    else
        h.selected_feats(6) = 1;
    end
    guidata(handles.DataHighFig, h);
    
    update_axesMain(handles);
end

function cues_button_Callback(hObject, eventdata, handles)
% plot the cues for specific times in the experiment (every start time)
    
    h = guidata(handles.DataHighFig);
    
    if (get(hObject, 'Value') == 0) % check togglebutton status
        h.selected_feats(2) = 0;
    else
        h.selected_feats(2) = 1;
    end
    guidata(handles.DataHighFig, h);
    
    update_axesMain(handles);
end





%%%  Neural state Features  %%%


function traj1_anns_button_Callback(hObject, eventdata, handles)
% switches to activate the traj features panel
    activate_panel(hObject, handles, 'traj_anns');
end

function state1_anns_togbutton_Callback(hObject, eventdata, handles)
% this is disabled...you are already looking at State annotations
    set(handles.state1_anns_togbutton, 'Value', 1);
end


function datapoints_button_Callback(hObject, eventdata, handles)
% displays the datapoints for each cluster

    h = guidata(handles.DataHighFig);
    h.selected_feats(3) = get(hObject, 'Value');
    
    guidata(handles.DataHighFig, h);
    update_axesMain(handles);
end

function cov_ellipses_button_Callback(hObject, eventdata, handles)
% displays the covariance ellipse for each cluster

    h = guidata(handles.DataHighFig);
    h.selected_feats(4) = get(hObject, 'Value');  % change cov_ellipse
    
    guidata(handles.DataHighFig, h);
    update_axesMain(handles);
end

function first_pc_button_Callback(hObject, eventdata, handles)
%  enables the first principal component plotted for each cluster
%  (for available conditions)

    h = guidata(handles.DataHighFig);
    h.selected_feats(5) = get(hObject, 'Value');  % change first pc
    guidata(handles.DataHighFig, h);  
    update_axesMain(handles);
end

function origin_button_Callback(hObject, eventdata, handles)
% enables the original origin to be shown in the lower-d space
    
    h = guidata(handles.DataHighFig);
    h.selected_feats(7) = get(hObject, 'Value');
    guidata(handles.DataHighFig, h);
    update_axesMain(handles);
end

function cluster_means_button_Callback(hObject, eventdata, handles)
% displays the cluster means

    h = guidata(handles.DataHighFig);
    h.selected_feats(8) = get(hObject, 'Value');
    guidata(handles.DataHighFig, h);
    update_axesMain(handles);
end

function depth_percept_button_Callback(hObject, eventdata, handles)
% resizes datapoints to make closer points bigger and plotted last

    h = guidata(handles.DataHighFig);
    h.selected_feats(9) = get(hObject, 'Value');
    guidata(handles.DataHighFig, h);
    update_axesMain(handles);
end

function update_axesMain(handles)
% helper function to replot DataHigh with the new conditions
    hd = guidata(handles.DataHighFig);
    
    figure(handles.DataHighFig);   % make DataHigh the active figure to plot
    handles.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);  % replot everything
    figure(handles.ToolboxFig);     %make the Toolbox the active figure
end





%%%  Analysis Tools  %%%


function pop_figure_button_Callback(hObject, eventdata, handles)
%  pops out a figure for the user, who can then save/edit the projection

    h = guidata(handles.DataHighFig);
    handles.functions.Pop_Figure_Callback(handles.DataHighFig, [], h);

end

function project_threed_button_Callback(hObject, eventdata, handles)
%  Used projection 3d scatter
    Projection3D(handles.DataHighFig);
end

function desired_proj_button_Callback(hObject, eventdata, handles)
% opens up a new figure to show some desired, pre-defined projections
    FindProjection(handles.DataHighFig, handles.functions);
end

function proj_weights_button_Callback(hObject, eventdata, handles)
% opens a figure that displays a bargraph of the projection vector
% weightings
% future use:  allow user to manipulate the weightings by dragging the bars
% bigger or smaller
    Weights(handles.DataHighFig);
end

function smoother_button_Callback(hObject, eventdata, handles)
%  user may smooth the data with a Gaussian
    Smoother(handles.DataHighFig, handles.functions);
end

function drag_trajectory_button_Callback(hObject, eventdata, handles)
%  Drag dimensions to change the selected trajectory
%  Pops up DragDimensions

    types = unique({handles.D.type});
    if (~ismember('traj', types))  % disable if there are no trajectories
        return;
    end
    DragTrajectory(handles.DataHighFig, handles.functions);
end

function zoom_rotate_button_Callback(hObject, eventdata, handles)
% allows user to instantly zoom or rotate the current mainDisplay
% with scroll bars
    ZoomRotate(handles.DataHighFig);

end

function genetic_search_button_Callback(hObject, eventdata, handles)
% loads the human genetic algorithm to find an optimal projection

    GeneticSearch(handles.DataHighFig);
end


function dim_reduce_button_Callback(hObject, eventdata, handles)
% opens up the Dimensionality Reduction tool for raw data
    hd = guidata(handles.DataHighFig);
    
    % check if raw_data exists...then use that

    if isfield(hd, 'raw_data')
        DimReduce(hd.raw_data);
    else
        DimReduce(hd.orig_data);
    end
end

function single_dim_button_Callback(hObject, eventdata, handles)
% opens up the single dimension viewer
    SingleDim(handles.DataHighFig);
end

function load_proj_vecs_button_Callback(hObject, eventdata, handles)
% prompts the user to load particular projection vectors

    uiopen('load');
    hd = guidata(handles.DataHighFig); 
    
    if (exist('proj_vecs', 'var'))
        if (size(proj_vecs,2) ~= size(hd.proj_vecs,2))
            disp('Unable to load projection vectors.');
            disp('Projection vectors are of a different dimensionality than the data.');
            return;
        end
        
        % allow the user to see the projection description of the particular
        % projection they just loaded, if it exists
        % makes use of where also the click instructions are
        if (exist('proj_vecs_description', 'var'))
            set(hd.txtInstructions, 'String', proj_vecs_description, 'Visible', 'On');
            handles.instructions = 1;
        end

        hd.proj_vecs = proj_vecs;
        % update the Q matrices, since you are changing the vectors
        [hd.Q1 hd.Q2] = hd.functions.calculateQ(handles.DataHighFig, hd); 
        guidata(hd.DataHighFig, hd);
        figure(handles.DataHighFig);
        
        
        handles.functions.choose_conditions(hd.DataHighFig, hd.selected_conds);
        figure(handles.ToolboxFig);
    end
end

function save_proj_vecs_button_Callback(hObject, eventdata, handles)
% prompts the user to save the current projection vectors in a particular
% file
    hd = guidata(handles.DataHighFig);
    proj_vecs = hd.proj_vecs;
    proj_vecs_description = inputdlg('Projection description:', 'Proj Vec Description', [1 100], {''}, 'on');
    uisave({'proj_vecs', 'proj_vecs_description'}, 'proj_vecs.mat');
    
end

function load_data_button_Callback(hObject, eventdata, handles)
%  open up a new dataset (must have a struct named 'D' with appropriate
%  fieldnames)
    uiopen('load');
    
    if (exist('D', 'var'))  % close this DataHigh and restart a new one
        hd = guidata(handles.DataHighFig);
        assignin('base', 'D', D);
        if (exist('proj_vecs', 'var'))
            assignin('base', 'proj_vecs', proj_vecs);
        end
        close(handles.DataHighFig);
        data = evalin('base', 'D');
        DataHigh(data);
    end
end
   

function update_colors_button_Callback(hObject, eventdata, handles)
%  user can change epochColors, epochStarts, etc. of the data

    UpdateColors(handles.DataHighFig);
end


function about_datahigh_button_Callback(hObject, eventdata, handles)
% launches the about section
    AboutDataHigh();
end






%%%%%%% Helper functions

function conds_listbox_Callback(hObject, eventdata, handles)
%  allows user to toggle on/off conditions
%       idea:  the listbox's value with give which items were selected
%         thus, just change the boolean in selected_conds

% Hints: contents = cellstr(get(hObject,'String')) returns conds_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from conds_listbox

    hd = guidata(handles.DataHighFig);

    changed_conds = get(hObject, 'Value');
    hd.selected_conds(changed_conds) = ~hd.selected_conds(changed_conds);

    set(hObject, 'Value', find(hd.selected_conds));
    
    figure(handles.DataHighFig);
    handles.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);
    figure(handles.ToolboxFig);
    
    guidata(hObject, handles);

end


function conds_listbox_CreateFcn(hObject, eventdata, handles)
% set with actual conditions not in here, but in place_conditions
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function place_conditions(hObject, handles)
% prepares the Conditions panel with the listbox

    hd = guidata(handles.DataHighFig);
    
    conditions = unique({hd.D.condition});
    
    set(handles.conds_listbox, 'String', conditions);
    set(handles.conds_listbox, 'Value', find(hd.selected_conds==1));
    guidata(hObject, handles);
end



function activate_panel(hObject, handles, panel)
% sets selected panel to visible, and toggles the selected button
% panel:  'cond', 'anns', 'opt', 'saved_projs'

    set(handles.cond_panel, 'Visible', 'off');
    set(handles.traj_anns_panel, 'Visible', 'off');
    set(handles.state_anns_panel, 'Visible', 'off');
    set(handles.opt_panel, 'Visible', 'off');
    set(handles.saved_projs_panel, 'Visible', 'off');
    
    set(handles.cond_button, 'Value', 0);
    set(handles.anns_button, 'Value', 0);
    set(handles.opt_button, 'Value', 0);
    set(handles.saved_projs_button, 'Value', 0);
    
    if (strcmp(panel, 'cond'))
        set(handles.cond_panel, 'Visible', 'on');
        set(handles.cond_button, 'Value', 1);
    elseif strcmp(panel, 'traj_anns')
        set(handles.traj_anns_panel, 'Visible', 'on');
        set(handles.anns_button, 'Value', 1);
    elseif strcmp(panel, 'state_anns')
        set(handles.state_anns_panel, 'Visible', 'on');
        set(handles.anns_button, 'Value', 1);
    elseif strcmp(panel, 'opt')
        set(handles.opt_panel, 'Visible', 'on');
        set(handles.opt_button, 'Value', 1);
    elseif strcmp(panel, 'saved_projs')
        set(handles.saved_projs_panel, 'Visible', 'on');
        set(handles.saved_projs_button, 'Value', 1);
    end
    
    guidata(hObject,handles);
end


function disable_buttons(hObject, handles)
% disable buttons if data is all traj/states
% note that the user may use both trajs and states
    hd = guidata(handles.DataHighFig);
    
    if (all(ismember({hd.D.type}, 'traj'))) % D only has trajs
        set(handles.state2_anns_button, 'Enable', 'off');     
    elseif (all(ismember({hd.D.type}, 'state'))) % D only has states
        set(handles.traj1_anns_button, 'Enable', 'off');
        set(handles.smoother_button, 'Enable', 'off');
        set(handles.drag_trajectory_button, 'Enable', 'off');
    end
    
    
    % if user has input into DataHigh directly (no raw data),
    % we assume dim reduction has already been performed
    % DimReduce button should be active if the user wants to
    % go back to DimReduce
    if (~isfield(hd, 'raw_data'))  %if no raw_data, DimReduce never called
        set(handles.dim_reduce_button, 'Enable', 'off');
    end
    
    guidata(hObject, handles);

end










%%%%%%%%  Capture projection functions

function Saved_Proj_ButtonDownFcn(hObject, eventdata)
% if user selects a saved projection, upload that to DataHigh
%  (so, we are returning to the exact state when the user was viewing that
%  projection)

    handles = guidata(hObject);

    
    if (isempty(get(hObject, 'Children')))
        return;    % there is nothing there, so just return (nothing to upload)
    end

    
    % find out which axes was clicked
    selected_axes_index = find(hObject == handles.saved_proj_axes);
    

    figure(handles.DataHighFig);
    
    % call the DataHigh restoring function
    handles.functions.saved_proj_restore(handles.DataHighFig, guidata(handles.DataHighFig), handles.saved_projs(selected_axes_index).proj_vecs, ...
                handles.saved_projs(selected_axes_index).selected_conds, handles.saved_projs(selected_axes_index).selected_feats, ...
                handles.saved_projs(selected_axes_index).max_limit);
            
    dh_handles = guidata(handles.DataHighFig);
    % reset the buttons in toolbox
    handles.functions.set_annotations_tools(dh_handles, handles);
            
    figure(handles.ToolboxFig);
end


function capture_proj_button_Callback(hObject, eventdata, handles)
% pushbutton that will capture the current projection into memory
%  Capture Projection is a queue that keeps an index of the most-recently
%  captured projection.  After six projections are added, the oldest 
%  projection will be overwritten.
%
%  save external global variables to recreate projections
%  saved_projs:
%       proj_vecs
%       selected_conds
%       selected_feats
%       max_limit
%  saved_projs_index:  identifies which projection was most-recently added
    
    h = guidata(handles.DataHighFig);
    slot_to_fill = handles.saved_projs_index + 1;
    if (slot_to_fill > 6)
        slot_to_fill = 1;
    end
    
    % identify which struct field axes to change
    proj_field_string = sprintf('saved_proj%d', slot_to_fill);
    
    if (~isempty(handles.saved_projs(slot_to_fill).proj_vecs))  % if there already exists a projection in the slot
        cla(handles.(proj_field_string));
    end
    
    % update the parameters of the slot
    handles.functions.capture_projection(handles.DataHighFig, handles.(proj_field_string));
    handles.saved_projs(slot_to_fill).proj_vecs = h.proj_vecs;
    handles.saved_projs(slot_to_fill).selected_conds = h.selected_conds;  % which data to show that have the same selected 'condition' field
    handles.saved_projs(slot_to_fill).selected_feats = h.selected_feats; % which annotations to plot on the main axes
    handles.saved_projs(slot_to_fill).max_limit = h.max_limit;

    handles.saved_projs_index = slot_to_fill;
    guidata(hObject, handles);
end






%%%%%%% Initialization functions


function initialize_handles(hObject, handles, DataHighFig, funcs)
% initializes the handles for Toolbox

    DHhandles = guidata(DataHighFig);
    
    handles.DataHighFig = DataHighFig;
    handles.ToolboxFig = hObject;
    handles.D = DHhandles.D;
    handles.saved_projs = [];   %struct that keeps track of proj_vecs + selected_cond
    handles.max_limit = DHhandles.max_limit;
    handles.functions = funcs;
    handles.selected_feats = DHhandles.selected_feats;
    guidata(hObject, handles);
end
