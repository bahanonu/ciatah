function varargout = Projection3D(varargin)
% Projection3D
% Given two projection vectors and data, creates a random orthogonal projection
% vector, and projects the data onto that space (in scatter for points)
% 
% Evolve: Shows timecourse of the data.  Can be saved as movie (.avi).
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
                       'gui_OpeningFcn', @Projection3D_OpeningFcn, ...
                       'gui_OutputFcn',  @Projection3D_OutputFcn, ...
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

% --- Executes just before Projection3D is made visible.
function Projection3D_OpeningFcn(hObject, eventdata, handles, varargin)
    
    % pass the DataHighFigs handles onto the Projection3dFig
    initialize_handles(hObject, handles, varargin{1});
    handles = guidata(hObject);
    
    
   	set(hObject, 'toolbar', 'figure');
    % handles.mainAxes is the main display for big_traj_3d
    rotate3d(handles.mainAxes);  % matlab function that enables 3d rotation of axes
    
    
    set(handles.mainAxes, 'NextPlot', 'replacechildren');
    set(handles.mainAxes, 'XTick', []);
    set(handles.mainAxes, 'YTick', []);
    set(handles.mainAxes, 'ZTick', []);
    mL = [-handles.max_limit handles.max_limit];
    set(handles.mainAxes, 'XLim', mL);
    set(handles.mainAxes, 'YLim', mL);
    set(handles.mainAxes, 'ZLim', mL);
    
    if (all(ismember({handles.D.type}, 'state'))) % if all clusters, do not allow evolve
        set(handles.evolve_button, 'Enable', 'off');
        set(handles.save_movie_button, 'Enable', 'off');
    end
    
    guidata(hObject,handles);
    
    randomize_Callback(hObject, eventdata, handles);
    
    
end
    


function varargout = Projection3D_OutputFcn(hObject, eventdata, handles) 

    set(handles.Projection3dFig, 'Units', 'normalized', 'OuterPosition', [.1 .1 .6 .8]);
    guidata(hObject, handles);

end



function create_projection(hObject, handles)
%  creates a new randomized projection vector orthogonal to the given two
%  and then plots it in 3D

    set(gcf, 'CurrentAxes', handles.mainAxes);
    hold(handles.mainAxes, 'on');
    
    conditions = unique({handles.D.condition});
    
    if (handles.selected_feats(7) == 1)  % plot the origin, if selected
        plot_origin(handles);
    end
    
    for cond = find(handles.selected_conds)
        

        if (handles.selected_feats(6) == 1 && ~isempty(handles.avg_traj)) % plot average trajectory
            plot_avg_traj(handles, cond);
        end
        
        for trial = find(ismember({handles.D.condition}, conditions(cond)))
            
            if (strcmp(handles.D(trial).type, 'traj')) %check if trial is a trajectory
                if (handles.selected_feats(1) == 1)  % original trajectory selected
                    plot_trajectory(handles, trial);
                end
                
                if (trial == handles.current_trial_selected) % make selected trajectory bold
                    plot_selected_traj(handles, trial);
                end
                
                if (handles.selected_feats(2) == 1) % cues is selected
                    plot_cues(handles, trial);
                end
                
            end
            
            if (strcmp(handles.D(trial).type, 'state')) %check if it is a cluster
                if (handles.selected_feats(3) == 1) % datapoints
                    plot_datapoints(handles, trial);
                end
                if (handles.selected_feats(4) == 1) % cov ellipse
                    plot_cov_ellipse(handles, trial);
                end
                if (handles.selected_feats(5) == 1) % firstPC
                    plot_first_pc(handles,trial);
                end
                if (handles.selected_feats(8) == 1) % cluster mean
                    plot_cluster_mean(handles,trial);
                end
            end

        end
        
    end
  
    hold(handles.mainAxes, 'off');
    guidata(hObject,handles);
    
end

    

% functions to plot selected conditions

function plot_trajectory(handles, trial)
% plot each trajectory
    p = handles.orths * handles.D(trial).data;
    starts = [handles.D(trial).epochStarts size(handles.D(trial).data,2)];

    for i = 1:length(starts)-1
        plot3(handles.mainAxes, p(1,starts(i):starts(i+1)), p(2,starts(i):starts(i+1)), p(3,starts(i):starts(i+1)), ...
            'Color', handles.D(trial).epochColors(i,:));
    end
end

 
function plot_selected_traj(handles, trial)
% make selected traj bold
    p = handles.orths * handles.D(trial).data;
    starts = [handles.D(trial).epochStarts size(handles.D(trial).data,2)];

    for i = 1:length(starts)-1
        plot3(handles.mainAxes, p(1,starts(i):starts(i+1)), p(2,starts(i):starts(i+1)), p(3,starts(i):starts(i+1)), ...
            'Color', handles.D(trial).epochColors(i,:), 'LineWidth', 3);
    end

end

function plot_avg_traj(handles, cond)
% plot average trajectories
        
    if (isempty(handles.avg_traj(cond).traj)) % if no avg_traj for condition, return
        return;
    end

    %plot the already existing average trajectory
    p = handles.orths * handles.avg_traj(cond).traj;
    starts = [handles.avg_traj(cond).epochStarts size(handles.avg_traj(cond).traj,2)];

    for i = 1:length(starts)-1
        line(p(1,starts(i):starts(i+1)), p(2,starts(i):starts(i+1)), p(3,starts(i):starts(i+1)), 'LineWidth', 5, 'Color', ...
            handles.avg_traj(cond).epochColors(i,:), 'UserData', [6 cond i]);
    end
end

function plot_cues(handles, traj)
% plot cues for trajectories

    p = handles.orths * handles.D(traj).data;
    starts = [handles.D(traj).epochStarts size(handles.D(traj).data,2)];

    for i = 1:length(starts)-1

        % plot time series cues (as dots)
        if (i == 1 && i == length(starts)-1)  %only one trajectory,  set UserData to [trial epoch] = [0 0] so ignored by BoldLine
            plot3(p(1,starts(i)), p(2,starts(i)), p(3,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
        elseif (i==1)
            plot3(p(1,starts(i)), p(2,starts(i)), p(3,starts(i)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
        elseif (i < length(starts)-1)
            plot3(p(1,starts(i)), p(2,starts(i)), p(3,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
        else
            plot3(p(1,starts(i)), p(2,starts(i)), p(3,starts(i)), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
            plot3(p(1,starts(i+1)), p(2,starts(i+1)), p(3,starts(i+1)), 'LineStyle', 'none', 'Marker', '.', 'MarkerEdgeColor', handles.D(traj).epochColors(i,:), 'UserData', [3 traj i]);
        end
    end

end

function plot_datapoints(handles, trial)
% plot the datapoints
    p = handles.orths * handles.D(trial).data;
    starts = [handles.D(trial).epochStarts size(handles.D(trial).data,2)+1];
    
    for i = 1:length(starts)-1
        plot3(p(1,starts(i):starts(i+1)-1), p(2,starts(i):starts(i+1)-1), p(3,starts(i):starts(i+1)-1), 'LineStyle', 'none', 'Marker', 'o', ...
            'Color', handles.D(trial).epochColors(i,:));
    end
end

function plot_cov_ellipse(handles, trial)
% plot 2d cov ellipses, existing in the first two pc space

    [u sc lat] = princomp(handles.D(trial).data');
    p = ellipse(u(:,1:2)', cov(handles.D(trial).data'), zeros(size(u(:,1))));
    p = u(:,1:2) * p + repmat(mean(handles.D(trial).data,2), 1, size(p,2));
    p = handles.orths * p;
    plot3(p(1,:), p(2,:), p(3,:), 'Color', handles.D(trial).epochColors(1,:));
    

end


function plot_first_pc(handles, trial)
% plot the first pc for each cluster
    [u sc lat] = princomp(handles.D(trial).data');
    p = handles.orths * (sqrt(lat(1))*[-u(:,1) u(:,1)] + mean(handles.D(trial).data,2)*ones(1,2));
    plot3(p(1,:), p(2,:), p(3,:), 'Color', [1 0 0]);
end

function plot_origin(handles)
% plot the origin for all data
    h = guidata(handles.DataHighFig);
    p = handles.orths * h.origin;
    plot3(p(1,:), p(2,:), p(3,:), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'MarkerSize', 15);
end

function plot_cluster_mean(handles, trial)
% plot the cluster mean
    m = mean(handles.D(trial).data,2);
    p = handles.orths * m;
    plot3(p(1), p(2), p(3), 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', handles.D(trial).epochColors(1,:), ...
        'MarkerFaceColor', handles.D(trial).epochColors(1,:), 'MarkerSize', 10);
end


    

function randomize_Callback(hObject, eventdata, handles)
% randomize the last projection vector and replot

    cla(handles.mainAxes);
 
    handles.orths = get_rand_proj_vecs(handles.proj_vecs(1,:), handles.proj_vecs(2,:));
    

    create_projection(hObject, handles);

    guidata(hObject, handles);
end
    
    
    
    
function orths = get_rand_proj_vecs(v1,v2)
% calculates three orthonormal vectors, two given and one random
    % perform gram-schmidt's 
    [q r] = qr([v1' v2' rand(length(v1),1)]);
    orths = [v1' v2' q(:,3)]';
end
    


% --- Executes on button press in pop_figure.
function pop_figure_Callback(hObject, eventdata, handles)
% pops out a figure of the current pic

    
    figure;
    a = axes;
    rotate3d(a);
    set(a, 'NextPlot', 'replacechildren');
    set(a, 'XTick', []);
    set(a, 'YTick', []);
    set(a, 'ZTick', []);

    % copy all the children over
    copyobj(get(handles.mainAxes, 'Children'), a);
end



% --- Executes on button press in evolve_button.
function evolve_button_Callback(hObject, eventdata, handles)
%  shows evolving time series movie of all the trajectories
    
    hold(handles.mainAxes, 'on');
    
    

    if (handles.evolve_in_progress == true && handles.evolve_stopped == false)
        % traj is currently being evolved, so stop it, but still keep it in
        % progress (don't start a new instance)
        handles.evolve_stopped = true;
        set(hObject, 'String', 'Continue Evolve');
        % set other three buttons to be enabled
        set(handles.randomize, 'Enable', 'off');
        set(handles.pop_figure, 'Enable', 'on');
        set(handles.save_movie_button, 'Enable', 'off'); %don't show a movie during Evolve
        guidata(hObject, handles);
        return;
    elseif (handles.evolve_in_progress == true && handles.evolve_stopped == true)
        % traj is currently being evolved, but it's stopped.  so restart it
        handles.evolve_stopped = false;
        set(hObject, 'String', 'Pause Evolve');
        % set other three buttons to be disabled
        set(handles.randomize, 'Enable', 'off');
        set(handles.pop_figure, 'Enable', 'off');
        set(handles.save_movie_button, 'Enable', 'off');
        guidata(hObject, handles);
        return;
    elseif (handles.evolve_in_progress == false)
        % this is new instance for evolve, so just start it up
        handles.evolve_in_progress = true;
        handles.evolve_stopped = false;
        set(hObject, 'String', 'Stop Evolve');
        % set other three buttons to be disabled
        set(handles.randomize, 'Enable', 'off');
        set(handles.pop_figure, 'Enable', 'off');
        set(handles.save_movie_button, 'Enable', 'off');
        guidata(hObject, handles);
    end
        
    
    fading_length = 10;
    
    numPoints = max(cellfun('size',{handles.D.data},2)); %find the longest trajectory

    conditions = unique({handles.D.condition});
    
    for currentPoint=1:numPoints
        
        cla(handles.mainAxes);
        
            
        for icond = find(handles.selected_conds)
            
            if (handles.selected_feats(6) == 1) % if user has selected average trajectories
                plot_fading_average_trajectory(icond, currentPoint, handles, fading_length)
            end
            
            for itraj = find(ismember({handles.D.condition}, conditions(icond)))
                
                % if cluster, just replot the points (no evolve)
                %  user may enter mixed trajs and states

                if (strcmp(handles.D(itraj).type, 'state'))
                    if (handles.selected_feats(3) == 1) % datapoints should be shown
                        starts = [handles.D(itraj).epochStarts size(handles.D(itraj).data, 2)+1];
                        for i=1:length(starts)-1
                            plot3(p(1,starts(i):starts(i+1)-1), p(2,starts(i):starts(i+1)-1), p(3,starts(i):starts(i+1)-1), 'o', ...
                                'MarkerEdgeColor', handles.D(itraj).epochColors(i,:));
                        end
                        continue;  
                    end
                end

                
                % plot the evolving trajectories
                if (handles.selected_feats(1) == 1) % trajectories should be shown
                    plot_fading_trajectory(itraj, currentPoint, handles, fading_length)
                end

            end
            
        end
        
        pause(.05);
        
        if (~ishandle(handles.Projection3dFig))
            % user has closed out of Projection3d during a
            % going evolve, so just return and close figure
            return;
        end   
        
        handles = guidata(hObject);
        
        if (handles.record_movie)
            frame = getframe;
            writeVideo(handles.videowriter, frame);
        end
        
        % pause the display at a certain timepoint until user
        % re-starts evolve
        while (handles.evolve_stopped)
            if (~ishandle(handles.Projection3dFig))
                % user has closed out of Projection3d during a
                % stopped/going evolve, so just return and close figure
                return;
            end
            handles = guidata(hObject);
            pause(.05);
        end
        

    end
    
    % the traj is not being evolved anymore, so set it to false
    handles.evolve_in_progress = false;
    set(hObject, 'String', 'Evolve');
    guidata(hObject, handles);
    
    hold(handles.mainAxes, 'off');
    
    % re-enable the other buttons
    set(handles.randomize, 'Enable', 'on');
    set(handles.pop_figure, 'Enable', 'on');
    set(handles.save_movie_button, 'Enable', 'on');
    
end





function plot_fading_average_trajectory(icond, currentPoint, handles, fading_length)
% plots the fading average trajectories used in Evolve
%
%  as the avg trajectory evolves, the most current points are colored
%  with the line of the epoch's color
%  as the fade continues (up to the starting timepoint), a grey line
%  traces out the avg trajectory

    % project the avg trajectory onto the three proj vecs
    p = handles.orths * handles.avg_traj(icond).traj;

    % find the length of the grey trace
    min_traj_size = min(currentPoint, size(handles.avg_traj(icond).traj,2));
    starting_point = handles.avg_traj(icond).epochStarts(1);

    % plot the grey trace
    line(p(1,starting_point:min_traj_size), p(2,starting_point:min_traj_size), p(3,starting_point:min_traj_size), 'LineWidth', 4, 'Color', [0.7 0.7 0.7]);

    for j = 1:fading_length

        if (currentPoint - j <= 0 || currentPoint - j > size(p,2) - 1)
            continue;
        end


        % find color of traj by finding the epoch the current
        % point is in
        [blah epoch] = histc(currentPoint-j, [handles.avg_traj(icond).epochStarts size(handles.avg_traj(icond).traj,2)+1]); 

        if (epoch == 0) % point is not in a defined epoch (i.e., epochStarts(1) ~= 1)
            % this may not address all possibilities...room for bugs
            continue;
        end

        color = handles.avg_traj(icond).epochColors(epoch,:);

        line([p(1, currentPoint - j) p(1, currentPoint-(j-1))], [p(2, currentPoint - j) p(2, currentPoint-(j-1))], ...
                    [p(3, currentPoint - j) p(3, currentPoint - (j-1))], 'LineWidth', 5 + 2/fading_length*(fading_length-j), 'Color', color);
    end

end


function plot_fading_trajectory(itraj, currentPoint, handles, fading_length)
% plots the fading trajectories used in Evolve
%
%  as the trajectory evolves, the most current points are colored
%  with the line of the epoch's color
%  as the fade continues (up to the starting timepoint), a grey line
%  traces out the trajectory

    % get projection of traj
    p = handles.orths * handles.D(itraj).data;

    % plot a small, gray "trailing" trajectory, to orient
    min_traj_size = min(currentPoint, size(handles.D(itraj).data,2));
    starting_point = handles.D(itraj).epochStarts(1);

    line(p(1,starting_point:min_traj_size), p(2,starting_point:min_traj_size), p(3,starting_point:min_traj_size), 'LineWidth', 1, 'Color', [0.7 0.7 0.7]);

    for j = 1:fading_length

        if (currentPoint - j <= 0 || currentPoint - j > size(p,2) - 1)
            continue;
        end

        % find color of traj by finding the epoch the current
        % point is in
        [blah epoch] = histc(currentPoint-j, [handles.D(itraj).epochStarts size(handles.D(itraj).data,2)+1]); 

        if (epoch == 0) % point is not in a defined epoch (i.e., epochStarts(1) ~= 1)
            continue;
        end

        color = handles.D(itraj).epochColors(epoch,:);

        line([p(1, currentPoint - j) p(1, currentPoint-(j-1))], [p(2, currentPoint - j) p(2, currentPoint-(j-1))], ...
                    [p(3, currentPoint - j) p(3, currentPoint - (j-1))], 'LineWidth', 1 + 2/fading_length*(fading_length-j), 'Color', color);
    end

end







function save_movie_button_Callback(hObject, eventdata, handles)
% call evolve, but this time save it as a movie

    % suggest certain file formats...but user can override it as well
    if (ispc) % user is using Microsoft Windows, so suggest .avi
        defaultName = 'Evolve_movie.avi';
        [fileName pathName] = uiputfile({'*.avi'; '*.mp4'; '*.mj2'; '*.*'}, ...
            'Save Evolve movie as .avi or .mp4', defaultName);
    else  % if user is using mac or linux (although tough to watch movies in linux...)
        defaultName = 'Evolve_movie.mp4';
        [fileName pathName] = uiputfile({'*.mp4'; '*.avi'; '*.mj2'; '*.*'}, ...
            'Save Evolve movie as .mp4 or .avi', defaultName);
    end
    
    

    
    if (fileName == 0)
        % movie was cancelled
        return;
    end

    % for some reason, saving does not show file extension in dialog box,
    % so repeat extension twice
    %  however, if user chooses to overwrite something, only use one ext
    [path file ext] = fileparts([pathName fileName]);

    % check if user used correct extension
    if (~strcmp(ext, '.avi') && ~strcmp(ext, '.mp4') && ~strcmp(ext, '.mj2')) 
        disp(char(10));
        disp('Incorrect movie format extension. Evolve movie only support ''.avi'', ''.mp4'', and ''.mj2''.');
        disp('Please see "help DataHigh" or consult the User''s Manual for further information.');
        return;
    end
    
    % block other button options
    set(handles.randomize, 'Enable', 'off');
    set(handles.evolve_button, 'Enable', 'off');
    set(handles.pop_figure, 'Enable', 'off');
    set(handles.save_movie_button, 'Enable', 'off');
    rotate3d(handles.mainAxes, 'off');  % do not allow user to rotate during movie production
    
    % get the framerate from the user
    framerate = inputdlg('Input framerate: 1/binWidth (default: 30Hz)', 'Framerate', 1, {'30'});
    if (~all(ismember(framerate, '0123456789')))  %a number was not entered
        framerate = 30;
    else
        framerate = str2num(framerate);
    end
    

    if (strcmp(ext, '.avi')) % save as .avi file
        handles.videowriter = VideoWriter(fullfile(path, [file ext]), 'Motion JPEG AVI');
    elseif (strcmp(ext, '.mp4')) % save as .mp4 file
        % sometimes Matlab doesn't allow mp4...check to make sure
        profiles = VideoWriter.getProfiles();
        if (~ismember('MPEG-4', {profiles.Name})) % if .mp4 is not an allowed profile
            disp(char(10));
            disp('Save Movie: This version of Matlab does not support .mp4 files.  Defaulting to ''.avi''.');
            ext = '.avi';
            handles.videowriter = VideoWriter(fullfile(path, [file ext]), 'Motion JPEG AVI');
        else
            handles.videowriter = VideoWriter(fullfile(path, [file ext]), 'MPEG-4');
        end
    elseif (strcmp(ext, '.mj2')) % save as .mj2 file
        handles.videowriter = VideoWriter(fullfile(path, [file ext]), 'Motion JPEG 2000');
    else
        disp(char(10));
        disp('Error occurred saving movie.  Incorrect file extension.');
        return;
    end

    handles.videowriter.FrameRate = framerate;
    
    handles.record_movie = true;
    guidata(hObject, handles);
    open(handles.videowriter);
    evolve_button_Callback(handles.evolve_button, eventdata, handles);
    close(handles.videowriter);
    handles.record_movie = false;

    % re-enable the buttons after movie has been saved
    set(handles.randomize, 'Enable', 'on');
    set(handles.evolve_button, 'Enable', 'on');
    set(handles.pop_figure, 'Enable', 'on');
    set(handles.save_movie_button, 'Enable', 'on');
    rotate3d(handles.mainAxes, 'on');  % do not allow user to rotate during movie production
    
    guidata(hObject, handles);
end



function initialize_handles(hObject, handles, DataHighFig)
% initializes all the values in Project3d's handles, which is isolated from
% the actual DataHighFig handles
    DHhandles = guidata(DataHighFig);
    
    handles.DataHighFig = DataHighFig;
    handles.D = DHhandles.D;
    handles.proj_vecs = DHhandles.proj_vecs;
    handles.selected_conds = DHhandles.selected_conds;  % keeps track of which conditions to plot defined by main program
    handles.selected_feats = DHhandles.selected_feats;  % plots various features of the data
    handles.max_limit = DHhandles.max_limit;
    handles.Projection3dFig = hObject;
    handles.avg_traj = DHhandles.avg_traj;
    handles.current_trial_selected = DHhandles.current_trial_selected;
    handles.evolve_in_progress = false;
    handles.evolve_stopped = false;
    handles.record_movie = false;
    
    guidata(hObject, handles);

end



function threed_proj_helpbutton_Callback(hObject, eventdata, handles)
% help button for 3d projection
    helpbox(['The 3-d projection is displayed, and can be dragged like\n' ...
        'a Matlab 3-d plot.  The 3-d projection is defined by the two\n' ...
        'current projection vectors and a random orthonormalized third one.\n\n' ...
        'The Randomize button randomizes the third projection vector.\n\n' ...
        'The Evolve button plays out the population activity in time.\n' ...
        'Execution can be stopped and then restarted by clicking\n' ...
        'on the Evolve button.\n\n' ...
        'The Pop Figure button pops a Matlab 3-d figure with the current\n' ...
        'projection.\n\n' ...
        'The Save Movie button saves the movie (.avi or .mp4) of Evolve.\n' ...
        'The user may also choose the frame rate (default 30Hz).']);
end
