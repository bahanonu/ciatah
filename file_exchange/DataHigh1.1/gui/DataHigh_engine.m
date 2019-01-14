function varargout = DataHigh_engine(varargin)
% Usage: DataHigh_engine(D, ...)
%
%  INPUT:
%
%  D: struct 1 x numTrials
%     data  [neurons/latent variables x data points]
%     type ['traj', 'state']  (optional field for DimReduce)
%     condition  [condition identifier in String format] (optional)
%     epochStarts [indices x 1] (optional)
%     epochColors [indices x 3] (optional)
%
%  'DimReduce' (optional)
%     - perform dimensionality reduction before starting DataHigh
%     - suggested if user is inputting raw data (spike trains)
%
%  'rawData', rawData  (optional)
%     internal option for DataHigh to keep original data available for
%     DimReduce
%
%  Description:
%       Does the heavy-lifting for the main DataHigh interface.
%
%  Authors:
%       Benjamin Cowley, Carnegie Mellon University, 2012
%       Matthew Kaufman, Stanford University
%  Contributors:
%       Byron Yu, Carnegie Mellon University
%  Contact:
%       datahigh@gmail.com
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
                       'gui_OpeningFcn', @DataHigh_engine_OpeningFcn, ...
                       'gui_OutputFcn',  @DataHigh_engine_OutputFcn, ...
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


% OPENING FUNCTION
function DataHigh_engine_OpeningFcn(hObject, eventdata, handles, varargin)


    % if no input, output a warning
    if (nargin < 4 || nargin > 6)
        disp(char(10));
        disp('Incorrect number of arguments, try: DataHigh(D) or DataHigh(D, ''DimReduce'').');
        disp('Please see "help DataHigh" or consult the User''s Manual for further information.');
        close(hObject);
        return;
    end
    
    handles.orig_data = varargin{1};

    % check for incorrect D structure
    [check msg modified_orig_data] = performChecks(handles.orig_data);
    if (~check) % the check failed tests
        disp(char(10));
        disp(['Incorrect D struct format: ' msg]);
        disp('Please see "help DataHigh" or consult the User''s Manual for further information.');
        close(hObject);
        return;
    else
        handles.orig_data = modified_orig_data;
        guidata(hObject, handles);
    end
    
    

    
    % check for options (if the user called 'DimReduce')
    if (nargin > 4)
        for iput = 1:length(varargin)
            if isa(varargin{iput},'char')
                if (strcmp(varargin{iput}, 'rawData'))
                    % DataHigh was called from DimReduce, in which case we
                    % need to keep the raw data
                    if iput+1 <= length(varargin)
                        handles.raw_data = varargin{iput+1};
                    end
                elseif (strcmp(varargin{iput}, 'DimReduce'))
                    % automatically call DimReduce before DataHigh
                    close(hObject);

                    DimReduce(handles.orig_data);
                    return;
                end
            end
        end
    end
       

                    
    if (isfield(handles, 'proj_vecs'))
        % There should be no proj_vecs there, under no circumstances.  This is
        % an extraneous call.  Just start a new DataHigh_engine with the given data.

        close(handles.DataHighFig); 
        DataHigh_engine(varargin{:});  %passes all arguments to new DataHigh
        
        return;
    end


    initialize_handles(hObject, handles);
    handles = guidata(hObject);

    handles.DataHighFig = hObject;

    set(handles.DataHighFig, 'Name', 'DataHigh');
   
    handles.selected_conds = true(1, length(unique({handles.orig_data.condition})));
    handles.selected_feats = [0 0 0 0 0 0 0 0 0];   % [trajectory cues datapoints cov_ellipse first_pc avg_traj origin cluster_means depth_percept]
    % update selected feats to display trajectories and datapoints
    if (ismember('traj', {handles.orig_data.type})) % there are trajs
        handles.selected_feats(1) = 1;
    end
    if (ismember('state', {handles.orig_data.type}))  % there are states
        handles.selected_feats(3) = 1;
    end
    
    handles.num_dims = size(handles.orig_data(1).data,1);
    
    % prepare the space

    project_onto_new_space(hObject, handles);
    handles = guidata(hObject);

    
    % put all the panels' axes into an array
    handles.panels = define_panels_from_axes(handles, 30);

    % find the max limit
    [u sc lat] = princomp([handles.D.data]');
    handles.max_limit = 2*sqrt(lat(1));
    guidata(hObject, handles);
    
    % set properties for panels
    for i = 1:length(handles.panels)
      setUpPanel(handles.panels(i), handles.max_limit);
      set(handles.panels(i), 'ButtonDownFcn', @Panel_ButtonDownFcn);
    end
    setUpPanel(handles.axesMain, handles.max_limit);
    
    
    % make panels not being used invisible
    used_panels = [1:(handles.num_dims-2) 16:15+(handles.num_dims-2)];

    for ipanel = find(~ismember(1:30, used_panels))
        set(handles.panels(ipanel), 'Visible', 'off');
    end

    
    
    % Nothing is shown yet. Need to use axes to force the panels to be
    % shown so that we can create the 'back' hotspots
    axes(handles.axes2); %#ok<MAXES>
    
    % Create 'back' hotspots
    handles.backs = zeros(1, length(handles.panels));
    for i = 1:length(handles.panels)
        if (strcmp(get(handles.panels(i), 'Visible'), 'off'))
            continue;
        end
        handles.backs(i) = createBackHotspot(handles, i, handles.max_limit);
    end
    

    %set the intially selected trial trajectory (bolding) to zero
    handles.current_trial_selected = 0;
    
    
    % if user input had proj_vecs, use them; otherwise randomize proj vecs
    ws = evalin('base', 'who');
    handles.proj_vecs = zeros(2,handles.num_dims);
    
    for i = 1:length(ws)
        if (strcmp(ws(i), 'proj_vecs'))
            handles.proj_vecs = evalin('base', 'proj_vecs');
        end
    end

    
    if (size(handles.proj_vecs, 2) == handles.num_dims && sum(handles.proj_vecs(1,:) ~= 0))  %some proj_vec exists in workspace
        % make sure proj_vecs are orthonormal
        handles.proj_vecs(1,:) = handles.proj_vecs(1,:) ./ norm(handles.proj_vecs(1,:));  % make sure 
        handles.proj_vecs(2,:) = handles.proj_vecs(2,:) ./ norm(handles.proj_vecs(2,:));
        if (handles.proj_vecs(1,:) * handles.proj_vecs(2,:)' > 1e-10) %the two vectors are not orthogonal
            handles.proj_vecs = orth(handles.proj_vecs')';
        end
        
        [handles.Q1 handles.Q2] = calculateQ(hObject, handles);

        guidata(hObject, handles);
        plot_all_big_traj(hObject, handles);
        update_panels(hObject, handles);
        handles = guidata(hObject);
    else
        % call randomize_button_callback  to initiate all the plots (no
        % input proj_vecs

        randomize_button_Callback(hObject, eventdata, handles);
        handles = guidata(hObject);

    end
        
        
     
    handles.instructions = 1;
    
    
    funcs = get_function_handles();
    handles.ToolboxFig = Toolbox(hObject, funcs);

    
    % set the closing function to close both DataHigh_engine and Toolbox_button
    set(handles.DataHighFig, 'CloseRequestFcn', @Close_All_Callback);

    guidata(hObject,handles);
end
    
    
    
% OUTPUT FUNCTION
function varargout = DataHigh_engine_OutputFcn(hObject, eventdata, handles) 
    
    % move the DataHighFig to correct size (must be in OutputFcn, else
    % Matlab will override it)
    if (isfield(handles, 'DataHighFig'))

        set(handles.DataHighFig, 'Units', 'normalized', 'OuterPosition', [0 0 .85 1]);

        assignin('base', 'proj_vecs', handles.proj_vecs);
    
        guidata(hObject, handles);
    end
    
end
    
    

%  randomize Button press
%   randomizes the projection vectors, calculates new Q1 and Q2
function randomize_button_Callback(hObject, eventdata, handles)

    handles = randomize_vectors(hObject, handles);

    %update all the plots
    plot_all_big_traj(hObject, handles);

    update_panels(hObject, handles);

    
end
    
    
function return_handles = randomize_vectors(hObject, handles)
% randomize projection vectors (and Q matrices) to start fresh
    
    % set up the initial projection vecs
    handles.proj_vecs = randn(handles.num_dims,2);
    handles.proj_vecs = orth(handles.proj_vecs)';
    
    [handles.Q1 handles.Q2] = calculateQ(hObject, handles);
    
    guidata(hObject, handles);
    return_handles = handles;
end



% panel axis button released
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)



    handles = guidata(hObject);
    
    if (get(handles.axesMain, 'UserData') == 1)
        return;  % do nothing if the user just clicked randomly in the figure
    end
    
    
    % we need to stop execution of the continuous rotation by changing the
    % flag
    set(handles.axesMain, 'UserData', 1);
    
    % freeroll has now ended if user clicked somewhere else, so the toggle
    % button needs to be off
    set(handles.freeroll_button, 'Value', 0);
    
    
    %  with the updated projection vectors, give previews for all the
    %  panels
    %   Update: This is now done in continuously_rotating, since
    %           there was a concurrency issue (it was updating the panels
    %           before it had a chance to change Q1 or Q2.  Now, if the
    %           loop is broken, it will automatically update the panels
    %           (which is still the desired functionality).
    
    guidata(hObject,handles);
end
    
    
    
    
 
function Panel_ButtonDownFcn(hObject, eventdata, handles)
% PANEL background click


    handles = guidata(hObject);
    
    % Make sure user hasn't disabled all the conditions
    if isempty(get(handles.axesMain, 'children'))
      return;
    end
    
    if handles.instructions == 1
      set(handles.txtInstructions, 'Visible', 'off');
      handles.instructions = 0;
    end
    
    % find out which panel it is
    panel_index = find(handles.panels == hObject);
    
    
    % if user has less than 15 dims, some panels won't be used
    if (~checkPanel(panel_index, handles.num_dims))
        return;
    end

    % panels 1 to 15 are on the left, 16 to 30 are on the right
    % which side depends on which fixed vector
    
    % set the flag to keep the while loop running
    set(handles.axesMain, 'UserData', 0);
    
    % continuously rotate the object
    if (panel_index <= 15)  % it is on the left
        Continuously_Rotate_BigTraj(hObject, handles, 'forward', 'left', handles.Q1, panel_index);
    else
        Continuously_Rotate_BigTraj(hObject, handles, 'forward', 'right', handles.Q2, panel_index - 15);
    end

 %   guidata(hObject,guidata(hObject));
end
    
    
    
% BACK panel background click
function Back_ButtonDownFcn(hObject, eventdata)
    % backs are much like panels, except with backward rotation. They are
    % also called by rectangles, not axes.
    
    handles = guidata(hObject);

    % Make sure user hasn't disabled all the conditions
    if isempty(get(handles.axesMain, 'children'))
      return;
    end
    
    % find out which panel it is
    back_index = find(handles.backs == hObject);

    
    % if user has less than 15 dims, some panels won't be used
    if (~checkPanel(back_index, handles.num_dims))
        return;
    end
     
    % panels 1 to 15 are on the left, 16 to 30 are on the right
    % which side depends on which fixed vector
    
    % set the flag to keep the while loop running
    set(handles.axesMain, 'UserData', 0);
    
    % continuously rotate the object
    if (back_index <= 15)  % it is on the left
        Continuously_Rotate_BigTraj(hObject, handles, 'backward', 'left', handles.Q1, back_index);
    else
        Continuously_Rotate_BigTraj(hObject, handles, 'backward', 'right', handles.Q2, back_index - 15);
    end
    
%    guidata(hObject, handles);
end
    
    
    
% if selecting a particular trajectory in big_traj, you can make it bold
function Make_Line_Bold_ButtonDownFcn(hObject, eventdata, handles)

    handles = guidata(hObject);
    
    [children trials epochs] = get_update_children(handles.axesMain, 'traj');
    
    set(children, 'LineWidth', 1); % set all lines to normal size
    
    % find which trial the traj corresponded to
    if (strcmp(get(hObject, 'Type'), 'axes'))  % axes was selected
        % already deselected all, so just set current_trial to zero
        handles.current_trial_selected = 0;
        set(handles.SelectedTrialText, 'String', []);
    else
        % UserData has [type trial epoch] information
        
        typetrialepoch  = get(hObject, 'UserData');
        trial = typetrialepoch(2);

        set(children(trials == trial), 'LineWidth', 3);  %set all epochs of trial to bold linewidth

        handles.current_trial_selected = trial;
        
        % update text to show which trial was selected
        set(handles.SelectedTrialText, 'String', ['Trial ', num2str(trial)]);
        
    end
    
    guidata(hObject, handles);
end



% rotates the trajectory in big_traj
%  idea:  given a fixed projection vector, we will rotate the other
%  projection vector in the null space only on the angle given by the panel

function Continuously_Rotate_BigTraj(hObject, handles, direction, side, Q, angle_number) 

    % direction: string, 'forward' 'backward', which direction to rotate
    % side: string, 'left', 'right', which side the panel is on
    %       determines which vector is fixed (if left, proj_vec(1,:) is
    %       fixed, proj_vec(2,:) is fixed if right)
    % Q: matrix 15x14, previously calculated
    % angle_number: scalar, which angle to rotate by (determines R)
    %         note angle numbers repeat depending on left or right
    
    
    
    % you can change any of these variables to influence the rate
    pause_length = .1;
    
    if (strcmp(direction, 'backward'))
        alpha = -handles.alpha;
    else
        alpha = handles.alpha;
    end

    
    while (get(handles.axesMain, 'UserData') == 0)
        R = get_rotation_matrix(alpha, angle_number, handles.num_dims);

        % update the proj_vecsThe d
        if (strcmp(side, 'left'))
            handles.proj_vecs(1,:) = (Q * R * Q' * handles.proj_vecs(1,:)')';
        else
            handles.proj_vecs(2,:) = (Q * R * Q' * handles.proj_vecs(2,:)')';
        end

        guidata(hObject, handles);  
        
        % compute the projections and plot the trajectories and clusters
        plot_all_big_traj(hObject, handles);

        
        drawnow;   % clear the queue, in case the mouse button was released (might be a Mac bug)

    end
    

    % loop is exited, but now we need to update Q1 and Q2 (depending on
    % which vector changed
    %  need to keep the same Q1/Q2 if user wants to go backwards
    if (strcmp(side, 'left'))  %v2 didn't change, so Q1 shouldn't change
                                %but v1 did change, so Q2 needs to change
        [temp handles.Q2] = calculateQ(hObject, handles); 

    else
        [handles.Q1 temp] = calculateQ(hObject, handles);
    end

    % you're done rotating, so update all the panels with the new previews
    % (done here to avoid concurrency issues)
    update_panels(hObject, handles);
end
    

    
    
    
function R = get_rotation_matrix(alpha, angle_number, num_dims)
% return the rotation matrix based on the angle_number
    
    R = eye(num_dims - 1, num_dims - 1);
    R(angle_number, angle_number) = cos(alpha);
    R(angle_number, angle_number+1) = -sin(alpha);
    R(angle_number+1, angle_number) = sin(alpha);
    R(angle_number+1, angle_number+1) = cos(alpha);
end
    
    
function update_panels(hObject, handles)
% update all the outer panels with the new projection vectors 
%  update_panels calls guidata(hObject, handles)... so be sure *not* to
%  call guidata after calling update_panels!  call 
%  handles = guidata(hObject)

    if (~any(handles.selected_conds)) %if no selected conds, don't update
        return;
    end
    
    preview_alpha = pi;   %%% can change the preview alpha
   


    % for each panel, plot all the trajs with particular angles
    for panel = 1:length(handles.panels)
       
        % first check that the panel is ok to update
        if (~checkPanel(panel, handles.num_dims))
            continue;
        end
        
        
        if (panel <= 15) %panel is on left side
            
            % fix v2, change v1
            R = get_rotation_matrix(preview_alpha, panel, handles.num_dims);
            v1 = handles.Q1 * R * handles.Q1' * handles.proj_vecs(1,:)';
            v2 = handles.proj_vecs(2,:)';

            plot_panel(hObject, handles, handles.panels(panel), [v1 v2]');

        else  %panel is on right side
            % fix v1, change v2
            
            R = get_rotation_matrix(preview_alpha, panel - 15, handles.num_dims);
            v2 = handles.Q2 * R * handles.Q2' * handles.proj_vecs(2,:)';
            v1 = handles.proj_vecs(1,:)';
            
            plot_panel(hObject, handles, handles.panels(panel), [v1 v2]');
            
        end
    end
    
    % Need to bring the 'back' hotspots to the front, or they may be
    % occluded by plots
    for h = handles.backs
        if (h > 0)  % some backs may be deleted for removed panels
            uistack(h, 'top');
        end
    end
    
    
    % Plot the percent variance as seen by the main display
    conditions = unique({handles.D.condition});
%     [u sc lat] = princomp([handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data]');
%     [up scp latp] = princomp((handles.proj_vecs*[handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data])');
%     percVar = sum(latp)/sum(lat)*100;
    Sigma_highd = cov([handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data]');
    Sigma_projected = handles.proj_vecs * Sigma_highd * handles.proj_vecs';
    percVar = trace(Sigma_projected)/trace(Sigma_highd) * 100;

    set(handles.PercentVarianceText, 'String', [sprintf('%.2f', percVar) '% var']);


    guidata(hObject, handles);
end

    

    

% user may use less than 15 dims...
% returns 1 if panel is ok, 0 else
function panelIsOk = checkPanel(panel_index, num_dims)
    
    if (panel_index <= 15 && panel_index <= num_dims - 2)
        panelIsOk = 1;
    elseif (panel_index >= 16 && panel_index - 15 <= num_dims - 2)
        panelIsOk = 1;
    else
        panelIsOk = 0;
    end
end


function [Q1 Q2] = calculateQ(hObject, handles)
% calculates Q1 and Q2, the null spaces of v2 and v1, respectively
%  proj_vecs 2x#numdims

    Q = randn(handles.num_dims,handles.num_dims - 1);  % 15x14 matrix, concatenate vecs now
    Q1 = [handles.proj_vecs(2,:)' Q]; 
    Q = randn(handles.num_dims,handles.num_dims - 1);  % re-randomize Q
    Q2 = [handles.proj_vecs(1,:)' Q];
    
    % perform gram-schmidt to make it a null space
    [Q1 R] = qr(Q1);
    [Q2 R] = qr(Q2);
    
    % now take out v2 and v1 (we just want the null space)
    Q1 = Q1(:, 2:handles.num_dims);
    Q2 = Q2(:, 2:handles.num_dims);
end
    

    


% assigns all the axes into a panels array
function panelHs = define_panels_from_axes(handles, nPanels)
    panelHs = zeros(1, nPanels);
    for ax = 1:nPanels
      panelHs(ax) = handles.(sprintf('axes%d', ax+1));
    end

end


% clear all the ticks and set axis limits for panels
function setUpPanel(ha, max_limit)
    set(ha, 'NextPlot', 'replacechildren');
    set(ha, 'XTick', []);
    set(ha, 'YTick', []);
    set(ha, 'Box', 'on');
    set(ha, 'XLim', [-max_limit max_limit]);
    set(ha, 'YLim', [-max_limit max_limit]);
    
    setupAxesForFastDraw(ha);
end
    

function hr = createBackHotspot(handles, panel, max_limit)

    set(handles.DataHighFig, 'CurrentAxes', handles.panels(panel));
    % Turn HandleVisibility off so they don't get cleared
    percent = .25*max_limit;
    hr = rectangle('Position', [-(handles.max_limit - 1/5*percent) -(handles.max_limit - 1/20*percent) percent percent], 'LineStyle', 'none', ...
      'FaceColor', [0.8 0.8 0.8], 'HandleVisibility', 'off');
    % Set callbacks so they can cause rotation
    set(hr, 'ButtonDownFcn', @Back_ButtonDownFcn);
    
end
    





      
% Plot the panels

function plot_panel(hObject, handles, ha, vecs)  
% plot trajs on given axes for panel
    
    children = get(ha, 'Children');
    if isempty(children)
        createLines(hObject, handles, ha, vecs);
    else
        updateLines(hObject, handles, ha, vecs);
    end
end
  
    
% Main plot function

function plot_all_big_traj(hObject, handles)
% plot all particular features, given selected feats

    if (handles.selected_feats(1) == 1) %trajectories
        plot_panel(hObject, handles, handles.axesMain,handles.proj_vecs);
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(6) == 1) % plot average trajectory
        plot_average_traj(hObject, handles);
        handles = guidata(hObject);
    end
        
    
    if (handles.selected_feats(2) == 1) % show_cues
        show_cues(hObject, handles);
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(3) == 1 && handles.selected_feats(9) == 0) % plot datapoints (don't if you are also plotting depth perception)
        plot_cluster_feature(hObject, handles, 'datapoints');
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(4) == 1) % plot covariance ellipses
        plot_cluster_feature(hObject, handles, 'cov_ellipse');
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(5) == 1) % plot first pc
        plot_cluster_feature(hObject, handles, 'first_pc');
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(7) == 1) % plot origin
        plot_cluster_feature(hObject, handles, 'origin');
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(8) == 1) % plot cluster_mean
        plot_cluster_feature(hObject, handles, 'cluster_mean');
        handles = guidata(hObject);
    end
    
    if (handles.selected_feats(9) == 1) % plot depth_perception
        plot_cluster_feature(hObject, handles, 'depth_percept');
        handles = guidata(hObject);
    end
    

end


    

    
function createLines(hObject, handles, panel, vecs)
% create lines on the plot (lines are much faster)

    set(get(panel, 'Parent'), 'CurrentAxes', panel);
    hold(panel, 'on');
    
    conditions = unique({handles.D.condition});
    
    for cond = find(handles.selected_conds)

        % the trajectory must be in the currently selected conditions and
        % be a trajectory (not a cluster)
        for trial = find(ismember({handles.D.condition}, conditions(cond)))
            
            % plot either trajectory or cluster
            if (strcmp(handles.D(trial).type, 'traj'))
                p = vecs * handles.D(trial).data;
                starts = [handles.D(trial).epochStarts size(handles.D(trial).data,2)];
                plotTrajectory(trial, p, starts, handles, panel);
            elseif (strcmp(handles.D(trial).type, 'state') && panel ~= handles.axesMain)
                p = ellipse(vecs, cov(handles.D(trial).data'), mean(handles.D(trial).data,2));
                plotClusterEllipse(trial, p, handles);
            end
        end
    end
    
end

function plotTrajectory(traj, p, starts, handles, panel)
% helper function, specifically plot one trajectory 

    for i = 1:length(starts)-1
        hp = line(p(1,starts(i):starts(i+1)), p(2,starts(i):starts(i+1)), 'Color', handles.D(traj).epochColors(i,:), ...
            'UserData', [1 traj i]);  %trajectory is denoted by 1

        %  set up callback function for make_line_bold
        if (panel == handles.axesMain)
            set(hp, 'ButtonDownFcn', @Make_Line_Bold_ButtonDownFcn);

            if (traj == handles.current_trial_selected)  % if currently selected trial, make it bold
                set(hp, 'LineWidth', 5);
            end
        else
            set(hp, 'HitTest', 'off');  % so you can select the panel (without just hitting the white background)
        end
    end
end

function plotClusterEllipse(cluster, p, handles)
% helper function, specifically plot one cluster 

    hp = line(p(1,:), p(2,:), 'Color', handles.D(cluster).epochColors(1,:),...
            'UserData', [2 cluster 0], 'HitTest', 'off');  % [2 cluster epoch] denotes ellipse
end



    
function updateLines(hObject, handles, panel, vecs)
% update the data points for the lines (eliminates clearing)

    set(get(panel, 'Parent'), 'CurrentAxes', panel);
    
    [trajChildren trajTrials trajEpochs] = get_update_children(panel, 'traj');
    [clusterChildren clusterTrials clusterEpochs] = get_update_children(panel, 'cov_ellipse');
    
    conditions = unique({handles.D.condition});
    
    for cond = find(handles.selected_conds)

        for trial = find(ismember({handles.D.condition}, conditions(cond)))

            if (strcmp(handles.D(trial).type, 'traj'))
                p = vecs * handles.D(trial).data;
                starts = [handles.D(trial).epochStarts size(handles.D(trial).data,2)];
                updateTrajectory(trajChildren, p, trial, trajTrials, trajEpochs, starts, panel, handles);
            elseif (strcmp(handles.D(trial).type, 'state') && panel ~= handles.axesMain)
                p = ellipse(vecs, cov(handles.D(trial).data'), mean(handles.D(trial).data,2));
                updateClusterEllipse(clusterChildren, p, trial, clusterTrials);
            end
        end 
    end
    

end
    
function updateTrajectory(children, p, traj, trials, epochs, starts, panel, handles)
% update a specific trajectory

    for i = 1:length(starts)-1
        
        correctLineIndex = (trials == traj) & (epochs == i);
        set(children(correctLineIndex), 'XData', p(1, starts(i):starts(i+1)), 'YData', p(2,starts(i):starts(i+1)));

        % make line bold if it is currently selected
        if (panel == handles.axesMain && handles.current_trial_selected == traj)
            set(children(correctLineIndex), 'LineWidth', 3);
        end
    end 
end

function updateClusterEllipse(children, p, cluster, clusters)
% update a specific cluster ellipse

        set(children(clusters == cluster), 'XData', p(1, :), 'YData', p(2,:));
end






    
function [children trials epochs] = get_update_children(panel, type)
%  helper function that gets the children/trials/epochs for
%  updateTrajectories and updateClusters

    % get the particular type from the children
    %  using naming system [type trial epoch]
    
    children = get(panel, 'Children');
    if (isempty(children))
        children = [];
        trials = [];
        epochs = [];
        return;
    end
    typesTrialsEpochs = get(children, 'UserData');
    if (iscell(typesTrialsEpochs))
        typesTrialsEpochs = cell2mat(typesTrialsEpochs);
    end

    if (strcmp(type, 'traj'))
        types = typesTrialsEpochs(:,1) == 1;
    elseif (strcmp(type, 'cov_ellipse'))
        types = typesTrialsEpochs(:,1) == 2;
    elseif (strcmp(type, 'cues'))
        types = typesTrialsEpochs(:,1) == 3;
    elseif (strcmp(type, 'datapoints'))
        types = typesTrialsEpochs(:,1) == 4;
    elseif (strcmp(type, 'first_pc'))
        types = typesTrialsEpochs(:,1) == 5;
    elseif (strcmp(type, 'avg_traj'))
        types = typesTrialsEpochs(:,1) == 6;
    elseif (strcmp(type, 'origin'))
        types = typesTrialsEpochs(:,1) == 7;
    elseif (strcmp(type, 'cluster_mean'))
        types = typesTrialsEpochs(:,1) == 8;
    elseif (strcmp(type, 'depth_percept'))
        types = typesTrialsEpochs(:,1) == 9;
    else
        types = zeros(length(children),1);
    end
    
    children = children(types);
    trials = typesTrialsEpochs(types,2);
    epochs = typesTrialsEpochs(types,3);
    
end
    
    
function clearAllPanels(hObject, handles)
% clear all the panels (not including big_traj)

   
    for p = 1:length(handles.panels) 
        childrun = get(handles.panels(p), 'Children');
        for i = 1:length(childrun)
            if (strcmp(get(childrun(i), 'Type'), 'line'))
                delete(childrun(i));
            end
        end

    end
    
    cla(handles.axesMain);
    guidata(hObject,handles);
end
  

function choose_conditions(hObject, selected_conds)
% changes which clusters/trajectories (based on condition) are to be displayed on
% the screen----chosen from Toolbox
%
%  function needs to be renamed, just replots data and big_traj -BRC
%  11/15/2013
 
    handles = guidata(hObject);
    handles.selected_conds = selected_conds;
    clearAllPanels(hObject, handles);
    handles = guidata(hObject);
    
    conditions = unique({handles.D.condition});
    trajs = cell2mat({handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data});
    

    xlimit = get(handles.axesMain, 'XLim');
    if (handles.max_limit ~= xlimit(2)) % the limit has changed
        set(handles.axesMain, 'XLim', [-handles.max_limit handles.max_limit]);
        set(handles.axesMain, 'YLim', [-handles.max_limit handles.max_limit]);
    end
    
    update_panels(hObject, handles);
    handles = guidata(hObject);
    
    plot_all_big_traj(hObject, handles);

end
  
  



function freeroll_button_Callback(hObject, eventdata, handles)
% freerollin'!  Will continuously rotate the main display in random
% directions until turned off
%
% axesMain, 'UserData' = 1 if rotating is off
% axesMain, 'UserData' = 0 if rotating is on


    set(handles.axesMain, 'UserData', ~get(hObject, 'Value'));
    guidata(hObject, handles);
    
    if (get(handles.axesMain, 'UserData') == 0)  % the axes is not rotating, so you can freeroll
        freeroll(hObject, handles);
    end
end


function freeroll(hObject, handles)
% Freeroll, continuously rotate in random directions

    index = randi(32);
    angle_number = randi(handles.num_dims-1);
    alpha = handles.alpha;

    while (get(handles.axesMain, 'UserData') == 0)

        if (index > 32)
            angle_number = randi(handles.num_dims-1);
            index = randi(32);
        end
        
        R = get_rotation_matrix(alpha, angle_number, handles.num_dims + 1);
        handles.proj_vecs = (R * handles.proj_vecs')';
        
        guidata(hObject, handles);
        
        plot_all_big_traj(handles.DataHighFig, handles);
        drawnow;
        
        
        index = index + 1;

        if (ishandle(handles.DataHighFig))  %if user closes DataHigh
            handles = guidata(hObject);
        else
            return;
        end
        
        
        if (gcf ~= handles.DataHighFig) %if user clicks outside the DataHigh figure
            set(handles.freeroll_button, 'Value', 0);
            break;
        end
        

    end
    
    %finished freerollin', so update Q1 and Q2 with new proj vecs
    [handles.Q1 handles.Q2] = calculateQ(hObject, handles);

    update_panels(hObject, handles);

end


function Toolbox_Callback(hObject, eventdata, handles)
%  calls a new figure of Toolbox

    if (ishandle(handles.ToolboxFig))
        figure(handles.ToolboxFig);
    else
        funcs = get_function_handles();
        handles.ToolboxFig = Toolbox(handles.DataHighFig, funcs);
    end
    
    guidata(hObject,handles);
end


    

    
    
% --- Change Space create function
function Change_Space_CreateFcn(hObject, eventdata, handles)

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


    set(hObject, 'BackgroundColor', [.9 .9 .9]);
    set(hObject, 'String', {'Original Space', '17-D Space'});
end
    





function Pop_Figure_Callback(hObject, eventdata, handles)
% pop new figure with the current big_axis
    
    f = figure;
    a = axes;
    setUpPanel(a, handles.max_limit);
    
    % copy the children over
    childrun = copyobj(get(handles.axesMain, 'Children'), a);
    for i = 1:length(childrun)
        set(childrun(i), 'HitTest', 'off');
    end
    
end




function capture_projection(hObject, saved_proj_axes)
%  plot the current big_traj into one of the saved_proj_panels
    handles = guidata(hObject);
    
    children = get(handles.axesMain, 'Children');
    
    for i = length(children):-1:1
        newChild = copyobj(children(i), saved_proj_axes);
        set(newChild, 'HitTest', 'off');
    end
    
    set(saved_proj_axes, 'XLim', [-handles.max_limit handles.max_limit]);
    set(saved_proj_axes, 'YLim', [-handles.max_limit handles.max_limit]);
    
end


function project_onto_new_space(hObject, handles)
% makes sure that the input data has at most 17 dimensions
% performs pca down to 17 dims if data is higher
% only used for intial data, but could be extended for different spaces

    handles.D = handles.orig_data;
    
    if (handles.num_dims > 17) % project onto 17 d space
        handles.origin = -mean([handles.orig_data.data],2);
        [u sc lat] = princomp([handles.orig_data.data]');
        next_interval_start = 1;
        for trial = 1:length(handles.orig_data)
            handles.D(trial).data = sc(next_interval_start:next_interval_start+size(handles.orig_data(trial).data,2)-1, 1:17)';
            next_interval_start = next_interval_start + size(handles.orig_data(trial).data,2);
        end 

        handles.num_dims = 17;  %now 17-d space
        handles.origin = u(:,1:17)' * handles.origin; %update origin to the change
        randomize_vectors(hObject, handles);
        
        
    else  % original data smaller than 17 dims, so no need for dim reduction
   
        handles.origin = -mean([handles.orig_data.data],2);
        
        for trial = 1:length(handles.orig_data)     % add the origin to recenter the data
            handles.D(trial).data = handles.orig_data(trial).data + repmat(handles.origin, 1, size(handles.orig_data(trial).data,2));
        end

        handles.num_dims = size(handles.D(1).data,1);

        randomize_vectors(hObject, handles);
    end
    

    guidata(hObject, handles);
end
    



function saved_proj_restore(hObject, handles, saved_proj_vecs, saved_selected_conds, saved_selected_feats, max_limit)
% returns DataHigh_engine to a previous state, given the saved proj_vecs and
% selected conds

    % update the proj_vecs and selected_conds
    handles.proj_vecs = saved_proj_vecs;
    [handles.Q1 handles.Q2] = calculateQ(hObject, handles);
    handles.selected_conds = saved_selected_conds;
    handles.selected_feats = saved_selected_feats;
    
    handles.max_limit = max_limit;
    clearAllPanels(hObject, handles);


    set(handles.axesMain, 'XLim', [-handles.max_limit handles.max_limit]);
    set(handles.axesMain, 'YLim', [-handles.max_limit handles.max_limit]);
    
    update_panels(hObject, handles);
    handles = guidata(hObject);
    
    plot_all_big_traj(hObject, handles);

end
    

    
    
    
function recenter_data(hObject, handles)
% recenters the data based on which stims are selected
% also updates origin
% updates all panels
% and plots the result on the bigAxes
    
    % find indices to calculate mean
    conditions = unique({handles.D.condition});
    concat_data = [];
    for cond = find(handles.selected_conds)  
        for trial = find(ismember({handles.D.condition},conditions(cond)))
            concat_data = [concat_data handles.D(trial).data];
        end
    end
    
    center = mean(concat_data,2);

    %now recenter the data
    for trial = 1:length(handles.D)
        handles.D(trial).data = handles.D(trial).data - repmat(center, 1, size(handles.D(trial).data,2));
    end
    handles.origin = handles.origin - center;
    handles.avg_traj = [];  % the avg traj will also need to be shifted, so reset
    guidata(hObject, handles);
    
    % plot the result on the big_traj
    plot_all_big_traj(hObject, handles);
    handles = guidata(hObject);
    
    update_panels(hObject, handles);
    

end
    
    

% Trajectory features

function show_cues(hObject, handles)
% add cues to the current axesMain
%  cues (and any other extraneous features than just lines) will be deleted
%  and replotted each time on the axesMain
%  show_cues handles will have UserData [0 0]
%
    set(handles.DataHighFig, 'CurrentAxes', handles.axesMain);
    
    
    [children trials epochs] = get_update_children(handles.axesMain, 'cues');
    delete(children);

    hold(handles.axesMain, 'on');

    conditions = unique({handles.D.condition});
    
    for cond = find(handles.selected_conds)

        for traj = find(ismember({handles.D.condition}, conditions(cond)))
            
            if (strcmp(handles.D(traj).type, 'state'))  %skip if cluster
                continue;
            end
            
            p = handles.proj_vecs * handles.D(traj).data;
            starts = [handles.D(traj).epochStarts size(handles.D(traj).data,2)];

            for i = 1:length(starts)-1

            % plot time series cues (as dots)

                if (i == 1 && i == length(starts)-1)  %only one trajectory,  set UserData to [trial epoch] = [0 0] so ignored by BoldLine
                    line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
                elseif (i==1)
                    line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
                elseif (i < length(starts)-1)
                    line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
                else
                    line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
                    line(p(1,starts(i+1)), p(2,starts(i+1)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
                end
                
%                 %   cue colors for DataHigh paper, for trajs D([5:9 15:19]) in
%                 %   ReachData
%                 if (i == 1 && i == length(starts)-1)  %only one trajectory,  set UserData to [trial epoch] = [0 0] so ignored by BoldLine
%                     line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.data(traj).epochColors(i,:), 'UserData', [3 traj i]);
%                 elseif (i==1)
%                  %   line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', handles.data(traj).epochColors(i,:), 'UserData', [3 traj i]);
%                 elseif (i == 2)
%                     line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0 0], 'UserData', [3 traj i]);
%                 elseif (i == 3)
%                     line(p(1,starts(i)), p(2,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0 1 1], 'UserData', [3 traj i]);
%                %     line(p(1,starts(i+1)), p(2,starts(i+1)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', [0 0 1], 'UserData', [3 traj i]);
%                 end
                
                                
            end
        end
    end
    
    guidata(hObject, handles);
end

function plot_average_traj(hObject, handles)
% plots the average trajectory for each condition
%  avg traj computed by linear interpolation
%
%  a feature for each condition, not each trajectory

    set(handles.DataHighFig, 'CurrentAxes', handles.axesMain);
    
    
    [children trials epochs] = get_update_children(handles.axesMain, 'avg_traj');
    delete(children);

    hold(handles.axesMain, 'on');

    %  if no avg_traj, go ahead and fit it
    if (isempty(handles.avg_traj))
        handles.avg_traj = find_avg_trajs(handles);
        guidata(hObject, handles);
        
        if (isempty(handles.avg_traj))  % just all clusters
            return;
        end
    end
    
    for cond = find(handles.selected_conds)

        if (isempty(handles.avg_traj(cond).traj))
            continue;  % condition only has clusters
        end
        
        %plot the already existing average trajectory
        p = handles.proj_vecs * handles.avg_traj(cond).traj;
        starts = [handles.avg_traj(cond).epochStarts size(handles.avg_traj(cond).traj,2)];

        for i = 1:length(starts)-1
            line(p(1,starts(i):starts(i+1)), p(2,starts(i):starts(i+1)), 'LineWidth', 5, 'Color', ...
                handles.avg_traj(cond).epochColors(i,:), 'UserData', [6 cond i]);
        end
        
    end
    
    guidata(hObject, handles);
    
end

function avg_traj = find_avg_trajs(handles)
%  find all the average trajectories by linear interpolation
%
%  Algorithm:
%  For each condition
%   For each epoch
%     1. Compute average number of timepoints in epoch
%     For each traj
%      1. Find marker placement
%      2. Keep running sum over trials
%     2. Divide the running sum by the number of trials
%     3. Encode with epoch's color

    avg_traj = [];
    
    for cond = 1:length(handles.selected_conds)
        
        conditions = unique({handles.D.condition});
        indices = find(ismember({handles.D.condition}, conditions(cond)) & ismember({handles.D.type}, 'traj'));
        
        if (~any(indices))  %if no trajectories, skip
            continue;
        end
        
      
        % find max number of epochs for the condition
        trajs_num_epochs = []; % contains the number of epochs for each trial
        for itrial = 1:length(indices) % if trials in condition do not have same number of epochs, continue
            trajs_num_epochs = [trajs_num_epochs length(handles.D(indices(itrial)).epochStarts)];
        end
        [num_epochs index_max_epochs] = max(trajs_num_epochs);
        
        % for each epoch, compute the average trajectory
        temp_traj = [];  % contains average traj
        avg_epochs = []; % contains epochs of average traj
        
        for iepoch = 1:num_epochs
            
            % compute the number of markers needed ( = number of average
            % timepoints in the epoch)
            num_markers = 0;
            num_trajs = 0;
            for itrial = 1:length(indices)
                if (iepoch == trajs_num_epochs(itrial))  % last epoch of the trial
                    initial_ind = handles.D(indices(itrial)).epochStarts(iepoch);
                    final_ind = size(handles.D(indices(itrial)).data, 2);
                    num_markers = num_markers + final_ind - initial_ind + 1;
                elseif (iepoch < trajs_num_epochs(itrial))  % epoch exists in trial
                    initial_ind = handles.D(indices(itrial)).epochStarts(iepoch);
                    final_ind = handles.D(indices(itrial)).epochStarts(iepoch + 1);
                    num_markers = num_markers + final_ind - initial_ind + 1;
                else
                    continue;  % trial does not have epoch
                end
                num_trajs = num_trajs + 1;
            end
            num_markers = ceil(num_markers / num_trajs);

            % for each trial, keep running sum
            temp_epoch = zeros(size(handles.D(1).data,1), num_markers);  
                                % contains segment of average traj for running sum
            num_trajs = 0;
            
            for itrial = 1:length(indices)
                if (iepoch == trajs_num_epochs(itrial))  % last epoch of the trial
                    initial_ind = handles.D(indices(itrial)).epochStarts(iepoch);
                    final_ind = size(handles.D(indices(itrial)).data, 2);
                    traj_data = handles.D(indices(itrial)).data(:, initial_ind:final_ind);
                elseif (iepoch < trajs_num_epochs(itrial))  % epoch exists in trial
                    initial_ind = handles.D(indices(itrial)).epochStarts(iepoch);
                    final_ind = handles.D(indices(itrial)).epochStarts(iepoch + 1);
                    traj_data = handles.D(indices(itrial)).data(:, initial_ind:final_ind);
                else
                    continue;  % trial does not have epoch
                end

                ip_data = interpolate_trajs(traj_data, num_markers);
                temp_epoch = temp_epoch + ip_data;
                num_trajs = num_trajs + 1;
            end
            
            temp_epoch = temp_epoch / num_trajs;
            
            avg_epochs = [avg_epochs num_markers-1];
            
            if (iepoch == 1)
                temp_traj = [temp_traj temp_epoch];
            else
                temp_traj = [temp_traj temp_epoch(:,2:end)];
            end
        end
        
        % avg_epochs right now only contains number of markers between
        % epochs
        avg_epochs = [1 avg_epochs(1:end-1)]; % last element was the number of datapoints
        avg_epochs = cumsum(avg_epochs);

        % format into output struct
        avg_traj(cond).traj = temp_traj;
        avg_traj(cond).epochStarts = avg_epochs;
        avg_traj(cond).epochColors = handles.D(indices(index_max_epochs)).epochColors;
        
    end
end

function ip_data = interpolate_trajs(traj_data, num_markers)
% helper function to find_avg_traj
% returns matrix where each column is a marker on the traj which is
% uniformly distributed along the traj (based on distance)
%
% ip_data -- interpolated data

    % compute path length
    path_length = 0;
    segment_dists = [0];
    for itime = 1:size(traj_data,2)-1
        diff_vec = traj_data(:,itime+1) - traj_data(:,itime);
        segment_dists = [segment_dists norm(diff_vec)+segment_dists(itime)];
    end
    
    % compute unit length for each marker
    path_length = segment_dists(end);
    unit_length = path_length / num_markers;
    
    % find interpolated distances of markers
    marker_dists = linspace(0, path_length, num_markers);
    
    % for each marker, find which timepoints surround it and interpolate
    % the marker position
    ip_data(:,1) = traj_data(:,1);
    ip_data(:,num_markers) = traj_data(:,end);
    

    for imarker = 2:num_markers-1  

        % find which timepoints border the marker
        [chugs marker_ind_lesser] = min(segment_dists <= marker_dists(imarker));
        marker_ind_lesser = marker_ind_lesser - 1;  % decrement to find point to the left
        [chugs marker_ind_greater] = max(segment_dists > marker_dists(imarker));


        % compute vector between greater timepoint - lesser timepoint
        vec_between = traj_data(:, marker_ind_greater) - traj_data(:, marker_ind_lesser);

        % find fraction of vector (which will be the interpolation point)
        frac = (marker_dists(imarker) - segment_dists(marker_ind_lesser)) / norm(vec_between);

        % find marker's position
        ip_data(:, imarker) = frac * vec_between + traj_data(:, marker_ind_lesser);
        
    end


end





% Cluster plotting functions

function plot_cluster_feature(hObject, handles, feature)
% plots a particulare feature for clusters

    set(handles.DataHighFig, 'CurrentAxes', handles.axesMain);
    
    % delete the old features (if any)
    [children trials epochs] = get_update_children(handles.axesMain, feature);
    delete(children);
    
    hold(handles.axesMain, 'on');
    conditions = unique({handles.D.condition});

    if strcmp(feature, 'origin')
        %plot the origin---does not require other clusters
        plot_origin(hObject, handles);
    end
    
    if (all(~handles.selected_conds))
        % there are no selected conditions, so plot nothing
        return;
    end
    
    if strcmp(feature, 'depth_percept')
        % plot the datapoints as if coming out of the screen
        % where closer datapoints are bigger
        plot_depth_perception(hObject, handles);
    end
    
    for cond = find(handles.selected_conds)
        for cluster = find(ismember({handles.D.condition}, conditions(cond)) & ismember({handles.D.type}, 'state'))
            
            if strcmp(feature, 'datapoints')
                plot_cluster_datapoints(hObject, handles, cluster);
            elseif strcmp(feature, 'cov_ellipse')
                plot_cov_ellipse(hObject, handles, cluster);
            elseif strcmp(feature, 'first_pc')
                plot_first_pc(hObject, handles, cluster);
            elseif strcmp(feature, 'cluster_mean')
                plot_cluster_mean(hObject, handles, cluster);
            end
        end
    end
    

end

function plot_cluster_datapoints(hObject, handles, cluster)
%  plots the datapoints for each cluster
%  deleted each time and replotted


    starts = [handles.D(cluster).epochStarts size(handles.D(cluster).data,2)+1];
    for i = 1:length(starts)-1
        p = handles.proj_vecs * handles.D(cluster).data;
        hp = line(p(1,starts(i):starts(i+1)-1), p(2,starts(i):starts(i+1)-1), 'Color', handles.D(cluster).epochColors(i,:),...
            'LineStyle', 'none', 'Marker', 'o', 'UserData', [4 cluster i], 'HitTest', 'off');  % [4 cluster epoch] denotes datapoints
    end
end

function plot_cov_ellipse(hObject, handles, cluster)
%  plots the covariance ellipse for each cluster
%  deleted each time and replotted 

    p = ellipse(handles.proj_vecs, cov(handles.D(cluster).data'), mean(handles.D(cluster).data,2));
    line(p(1,:), p(2,:), 'Color', handles.D(cluster).epochColors(1,:), 'UserData', [2 cluster 0]);
end

function plot_first_pc(hObject, handles, cluster)
%  plots the first principal component for each cluster (condition)
%  deleted each time and replotted
%  the length of the first PC is at most 2 (one for -u, one for u), so it's
%  kept at unit scale...could make length bigger (but equal scalar) for all
%  conditions if needed

    % find scalar to extend first PC, which is the average of the sqrt of the first
    % eigenvalue for each condition
    conditions = unique({handles.D.condition});
    avg = 0;
    for icond = 1:length(conditions)
        indices = find(ismember({handles.D.condition}, conditions(icond)) & ismember({handles.D.type}, 'state'));
        [u sc lat] = princomp([handles.D(indices).data]');
        avg = avg + sqrt(lat(1));
    end
    avg = avg / length(conditions);
    
    
    [u sc lat] = princomp(handles.D(cluster).data');
    p = handles.proj_vecs * (avg*[-u(:,1) u(:,1)] + mean(handles.D(cluster).data,2) * ones(1,2));

    line(p(1,:), p(2,:), 'Color', handles.D(cluster).epochColors(1,:), 'LineWidth', 5, 'UserData', [5 cluster 0]);
end

function plot_origin(hObject, handles)
% helper function that will plot the origin

    p = handles.proj_vecs * handles.origin;
    p = plot(handles.axesMain, p(1,:), p(2,:), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', [0 0 0], 'MarkerSize', 15);
    set(p, 'UserData', [7 0 0]);
end

function plot_cluster_mean(hObject, handles, cluster)
%  plots the cluster mean for given cluster

    m = mean(handles.D(cluster).data, 2);
    p = handles.proj_vecs * m;

    p = plot(handles.axesMain, p(1), p(2), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', handles.D(cluster).epochColors(1,:), ...
        'MarkerEdgeColor', handles.D(cluster).epochColors(1,:), 'MarkerSize', 10);

    set(p, 'UserData', [8 cluster 0]);
end

function plot_depth_perception(hObject, handles)
%  plots the datapoints for each cluster
%  such that closer points are bigger and are plotted in front

% idea:
% Find the orthogonal space of the two projection vectors.  Take the
% first PC in that orthogonal space, which leaves one
% vector in the orthogonal space.  Project each point onto that vector.
% Sort the points based on the values.  If a point is most negative, it is
% plotted first, and will have a smaller MarkerSize.
%
%  I would like to have the markers transparent, but this can't be done in
%  Matlab (markers do not have an alpha value, and marker patches do not
%  have an alpha either)

    % find the orthogonal space of the current projection vectors
    Q = randn(handles.num_dims, handles.num_dims);
    Q(:,1:2) = handles.proj_vecs';
    [Q r] = qr(Q);
    Q = Q(:,3:end); % take the orthogonal space
    
    % get vector from orthogonal space by first projecting data into
    % orthogonal space, performing PCA, and choosing the first PC
    conditions = unique({handles.D.condition});
    proj_data = Q' * [handles.D(ismember({handles.D.condition},conditions(handles.selected_conds))).data];
    u = princomp(proj_data');
    vec = u(:,1);
    vec = Q * vec; %project vec back into n-dimension space
    
    % project all points onto vec
    data_proj = [];
    cluster_epoch_trial = [];  %keeps track of which cluster (D(cluster)) and epoch (D(cluster).epochStarts(epoch)) the point is from
    conditions = unique({handles.D.condition});
    for icond = find(handles.selected_conds)
        for icluster = find(ismember({handles.D.condition}, conditions(icond)) & ismember({handles.D.type}, 'state'))
            data_proj = [data_proj vec' * handles.D(icluster).data];
            cluster = icluster * ones(size(handles.D(icluster).data,2),1);
            epoch = [];
            starts = [handles.D(icluster).epochStarts size(handles.D(icluster).data,2)+1];
            for iepoch = 1:length(starts)-1  % epochs in UserData is saved as the index in ColorEpochs (not the starting index)
                epoch = [epoch; iepoch * ones(starts(iepoch+1)-starts(iepoch),1)];
            end
            trial = (1:size(handles.D(icluster).data,2))';
            cluster_epoch_trial = [cluster_epoch_trial; cluster epoch trial];
        end
    end
        
    if (isempty(data_proj)) % if there are no clusters, return
        return;
    end
    
    data_proj = data_proj - min(data_proj);  %make all projections positive, with the minimum at zero
    
    % sort the points in ascending order of projection
    [chugs sorted_indices] = sort(data_proj);
    
    % designate the linear scale factor for the MarkerSize (max 15 min 5)
    % d_proj - min(d_proj) then scaled and added to 5 to make markersize
    size_scale_factor = (30-5)/(max(data_proj)-min(data_proj));
    color_scale_factor = 1/(max(data_proj) - min(data_proj));
    % iterate through the sorted datapoints, correctly plotting its color,
    % with increased size based on scale factor
    for ipoint = 1:length(sorted_indices)
        index = sorted_indices(ipoint);
        p = handles.proj_vecs * handles.D(cluster_epoch_trial(index,1)).data(:,cluster_epoch_trial(index,3));
%         hp = line(p(1), p(2), 'Color', handles.D(cluster_epoch_trial(index,1)).epochColors(cluster_epoch_trial(index,2),:),...
%             'LineStyle', 'none', 'Marker', 'o', 'UserData', [9 cluster_epoch_trial(index,1) cluster_epoch_trial(index,2)],...
%             'MarkerSize', size_scale_factor * data_proj(index) + 5, 'HitTest', 'off', ...
%             'MarkerFaceColor', 0.5*handles.D(cluster_epoch_trial(index,1)).epochColors(cluster_epoch_trial(index,2),:));

        hp = line(p(1), p(2), 'Color', [1 1 1],...
            'LineStyle', 'none', 'Marker', 'o', 'UserData', [9 cluster_epoch_trial(index,1) cluster_epoch_trial(index,2)],...
            'MarkerSize', size_scale_factor * data_proj(index) + 5, 'HitTest', 'off', ...
            'MarkerFaceColor', sqrt(max(color_scale_factor * data_proj(index),.2)) * handles.D(cluster_epoch_trial(index,1)).epochColors(cluster_epoch_trial(index,2),:));


    end

end


% Helper functions

function main_display_helpbutton_Callback(hObject, eventdata, handles)
% displays help message for the main display

    helpbox(['The central panel displays a 2-d projection defined\n' ...
        'by a projection plane in the high-d space.\n\n' ...
        'Click and hold on the preview panels to the right and left\n' ...
        'of the central panel to rotate the projection plane\n' ...
        'in the high-d space.\n\n' ...
        'Randomize rotates the projection plane to a random orientation.\n\n' ...
        'Freeroll autonomously rotates the projection plane,\n' ...
        'like a screensaver.\n\n' ...
        'Toolbox relaunches the Toolbox Figure.']);
end



function Close_All_Callback(hObject, handles)
% closes all open figures 

    figHandles = findobj('Type', 'figure');
    
    for i=1:length(figHandles)
        delete(figHandles(i));
    end
end

function [structOk msg modified_orig_data] = performChecks(D)
% performs checks on the input struct D to make sure it has the right
% format

    structOk = true;
    msg = [];
    modified_orig_data = D;
    
    % not empty
    if (isempty(D))
        msg = 'D is empty.';
        structOk = false; return;
    end

    % proper fields exist


    fields = isfield(D, {'data', 'type', 'condition', 'epochStarts', 'epochColors'});

    if (~fields(1)) % data was not included
        msg = 'D is missing a ''data'' field.';
        structOk = false; return;
    end
    
    if (~fields(2))  % type was not included, so default is traj
        for itrial = 1:length(D)
            D(itrial).type = 'traj';
        end
    end
        
    if (fields(3) ~= 1) % give trials ordered conditions
        for itrial = 1:length(D)
            if (floor(length(D)/10) == 0)
                D(itrial).condition = num2str(itrial);
            else
                D(itrial).condition = sprintf(['%0' num2str(ceil(log10(length(D)))) 'd'], itrial);
            end
        end
        fields(3) = 1;
    end
   

    
    if (~fields(4)) % if no epochStarts, add the field
        % it will be filled by [1]'s in the empty check
        D(1).epochStarts = [];  
    end
    
    if (~fields(5)) %if no epochColors, add the field
        % it will be filled by random colors in the empty check
        D(1).epochColors = [];
    end
    
    
    % empty check
    % check that none of the fields are empty
    % if epochStarts is empty, take it as whole trial
    % if epochColors is empty, fill it with the number of epochs
    %    where the same conditions have the same colors
    for itrial = 1:length(D)
        if (isempty(D(itrial).data) || isempty(D(itrial).type) || isempty(D(itrial).condition))
            msg = ['D has a field that is empty. trial ' num2str(itrial)];
            structOk = false; return;
        end
        if (isempty(D(itrial).epochStarts))
            D(itrial).epochStarts = 1;
        end
    end
    if (isempty(D(itrial).epochColors))
        conds = unique({D.condition});
        for icond = 1:length(conds)
            random_color = rand(1,3);
            for itrial = find(ismember({D.condition}, conds(icond)))
                D(itrial).epochColors = ones(length(D(itrial).epochStarts),1) * random_color;
            end
        end
    end
    

    % check to make sure each trial has same number of dimensions
    numDims = size(D(1).data,1);
    for itrial = 1:length(D)
        if (size(D(itrial).data,1) ~= numDims)
            msg = 'D does not have the same number of dimensions for each data element.';
            structOk = false; return;
        end
    end
    
    % check to make sure dimensionality is greater than 2
    if (size(D(1).data,1) <= 2)
        msg = 'D has dimensionality less than 3.  There''s no need for DataHigh!';
        structOk = false; return;
    end
    
    % check type is only either 'traj' or 'state'
    for itrial = 1:length(D)
        if (~strcmp(D(itrial).type, 'traj') && ~strcmp(D(itrial).type, 'state'))
            msg = 'D has type that is neither ''traj'' or ''state''.  Modify the type field to these strings.';
            structOk = false; return;
        end
    end
    
    
    % check epochStarts and epochColors values
    for itrial = 1:length(D)
        if (any(D(itrial).epochStarts ~= round(D(itrial).epochStarts)))
            msg = ['epochStarts must contain integer values, trial ' num2str(itrial)];
            structOk = false; return;
        end
        if (size(D(itrial).epochStarts,1) ~= 1 && size(D(trial).epochStarts,2) ~= 1)
            msg = ['epochStarts must be a row vector. trial ' num2str(itrial)];
            structOk = false; return;  % epochStarts is not a row vector
        end
        if (size(D(itrial).epochColors,1) ~= length(D(itrial).epochStarts) || size(D(itrial).epochColors,2) ~= 3)
            msg = ['epochColors must be numEpochStarts x 3, trial ' num2str(itrial)];
            structOk = false; return;  % epochColors does not conform to epochStarts
        end
        if (~issorted(D(itrial).epochStarts))
            msg = ['epochStarts is not in ascending order, trial ' num2str(itrial)];
            structOk = false; return;   %epochStarts not in ascending order
        end
        if (D(itrial).epochStarts(1) < 1 || D(itrial).epochStarts(end) > size(D(itrial).data,2))
            msg = ['epochStarts accesses indices outside data''s bounds, trial ' num2str(itrial)];
            structOk = false; return;
        end
        if (any(D(itrial).epochColors < 0 | D(itrial).epochColors > 1))
            msg = ['epochColors contains RGB are not between 0 and 1. trial ' num2str(itrial)];
            structOk = false; return;
        end
    end
    
    modified_orig_data = D;

end


function set_annotations_tools(dh_handles, tb_handles)
% sets selected_feats which controls which annotations are displayed
% only changes state, does not replot
% dh_handles -- datahigh handles
% tb_handles -- toolbox handles
% assumes handles.selected_feats has been set to the desired set of
%   annotations
% calls guidata(hObject, handles)
 
%  fields of handles.selected_feats
%       [trajectory cues datapoints cov_ellipse first_pc avg_traj origin cluster_means depth_percept]
    
    if (dh_handles.selected_feats(1)) % trajectories
        set(tb_handles.trajectories_button, 'Value', 1);
    else
        set(tb_handles.trajectories_button, 'Value', 0);
    end
    if (dh_handles.selected_feats(2)) % cues
        set(tb_handles.cues_button, 'Value', 1);
    else
        set(tb_handles.cues_button, 'Value', 0);
    end
    if (dh_handles.selected_feats(3)) % datapoints
        set(tb_handles.datapoints_button, 'Value', 1);
    else
        set(tb_handles.datapoints_button, 'Value', 0);
    end
    if (dh_handles.selected_feats(4)) % cov_ellipse
        set(tb_handles.cov_ellipses_button, 'Value', 1);
    else
        set(tb_handles.cov_ellipses_button, 'Value', 0);
    end
    if (dh_handles.selected_feats(5)) % first_pc
        set(tb_handles.first_pc_button, 'Value', 1);
    else
        set(tb_handles.first_pc_button, 'Value', 0);
    end
    
    if (dh_handles.selected_feats(6)) % avg_traj
        % need to reset avg_traj
        % since colors, epochs may change
        set(tb_handles.avg_traj_button, 'Value', 1);
        dh_handles.avg_traj = [];
    else
        dh_handles.avg_traj = [];
        set(tb_handles.avg_traj_button, 'Value', 0);
    end
    
    if (dh_handles.selected_feats(7)) % origin
        set(tb_handles.origin_button, 'Value', 1);
    else
        set(tb_handles.origin_button, 'Value', 0);
    end
    
    if (dh_handles.selected_feats(8)) % cluster_means
        set(tb_handles.cluster_means_button, 'Value', 1);
    else
        set(tb_handles.cluster_means_button, 'Value', 0);
    end
    
    if (dh_handles.selected_feats(9)) % depth_percept
        set(tb_handles.depth_percept_button, 'Value', 1);
    else
        set(tb_handles.depth_percept_button, 'Value', 0);
    end

    guidata(dh_handles.DataHighFig, dh_handles);
end




function functions = get_function_handles()
% get function handles for the Toolbox
   
    functions.recenter_data = @recenter_data;
    functions.choose_conditions = @choose_conditions;
    functions.Pop_Figure_Callback = @Pop_Figure_Callback;
    functions.capture_projection = @capture_projection;
    functions.setUpPanel = @setUpPanel;
    functions.saved_proj_restore = @saved_proj_restore;
    functions.plot_panel = @plot_panel;
    functions.get_rotation_matrix = @get_rotation_matrix;
    functions.calculateQ = @calculateQ;
    functions.set_annotations_tools = @set_annotations_tools;
end
    
function initialize_handles(hObject, handles)
%  this is just for book-keeping...a list of all the variables of handles

    handles.panels = [];  % holds all panel handles
    % handles.axesMain = [];  % the main displaying axis (replaces
    % big_traj)
    handles.DataHighFig = []; % figure handle to DataHigh
    handles.ToolboxFig = [];  % figure handle to ToolboxFig
    %handles.SelectedTrialText = [];  % which trial was selected in text
    handles.num_dims = [];  % number of dimensions for data
    handles.D = [];  % the actual datapoints
    handles.backs = []; % back hotspots
    handles.current_trial_selected  = [];  % which trial in bold
    handles.selected_conds = []; % which conditions to be displayed

    handles.instructions = [];   % instructions at top left
    handles.orig_data = handles.orig_data;  % original data that was given for input
    handles.functions = get_function_handles();  %struct that holds handles to all functions in DataHigh (for Toolbox)
    handles.avg_traj = [];  %struct that will contain the average trajectory for conditions
    
    handles.selected_feats = [];    % which features to display
    handles.origin = [];
    
    handles.max_limit = []; %  the max_limit for the projection
    handles.alpha = 0.2;  % beginning rotation alpha...user can change it
    
    handles.proj_vecs = [];  % the current projection vectors
    handles.Q1 = [];  %  Q1, the rotation matrix for vec1
    handles.Q2 = [];  % Q2, the rotation matrix for vec2
    
    guidata(hObject, handles);
    
end






