function varargout = GeneticSearch(varargin)
% GeneticSearch(DataHighFig)
%
%  Allows the human to perform a supervised genetic algorithm to search for
%  a desired projection.
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
                       'gui_OpeningFcn', @GeneticSearch_OpeningFcn, ...
                       'gui_OutputFcn',  @GeneticSearch_OutputFcn, ...
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


function GeneticSearch_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.DataHighFig = varargin{1};
    handles.GeneticSearchFig = hObject;
    guidata(hObject, handles);
    

    initialize_variables(handles);
    handles = guidata(handles.GeneticSearchFig);
    initialize_plots(handles);
    handles = guidata(handles.GeneticSearchFig);
    
    hd = guidata(handles.DataHighFig);

    randomly_initialize_proj_vecs(handles);
    handles = guidata(handles.GeneticSearchFig);
    plot_all_axes(handles);
    
    % set initial instructions for GeneticSearch
    set(handles.instructions_text, 'Visible', 'on');
end



function varargout = GeneticSearch_OutputFcn(hObject, eventdata, handles) 
    
end




% Menu callback functions


function nextgen_button_Callback(hObject, eventdata, handles)
% mutate the good and bad peasants, update plots

    
    mutate_bad_peasants(handles);
    handles = guidata(handles.GeneticSearchFig);
    mutate_good_peasants(handles);
    handles = guidata(handles.GeneticSearchFig);
    
    plot_all_axes(handles);
    
end


function rand_button_Callback(hObject, eventdata, handles)
% Randomize all current projections
%  i.e. start the search over
   
    randomly_initialize_proj_vecs(handles);
    handles = guidata(handles.GeneticSearchFig);
    
    plot_all_axes(handles);
end


function upload2datahigh_button_Callback(hObject, eventdata, handles)
% upload the selected projection vectors back to DataHigh
%  if multiple plots are selected, do nothing and ask user to select only
%  one
   
    hd = guidata(handles.DataHighFig);
    
    if (sum(handles.selected_projs) ~= 1) %the user has more than one selected or none at all
        set(handles.instructions_text, 'Visible', 'on');
        set(handles.instructions_text, 'String', 'Select only one projection to upload to DataHigh.');
        return;
    end
    

    hd.proj_vecs = handles.population_projvecs{handles.selected_projs==1};
    
    % update the Q matrices, since you are changing the vectors
    [hd.Q1 hd.Q2] = hd.functions.calculateQ(handles.DataHighFig, hd); 
    guidata(handles.DataHighFig, hd);
   
    close(handles.GeneticSearchFig);

    figure(handles.DataHighFig);   % make DataHigh the active figure to plot
    hd.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);  % replot everything
end






%%% Helper functions %%%

function initialize_plots(handles)
%  set up all axes to display projections on them

    hd = guidata(handles.DataHighFig);
    
    % find max
    handles.max_limit = hd.max_limit;
    
    % set up axes
    handles.axis_handles = zeros(1,15);
    for ax = 1:15
        handles.axis_handles(ax) = handles.(sprintf('axes%d', ax));
        set(handles.axis_handles(ax), 'NextPlot', 'replacechildren');
        set(handles.axis_handles(ax), 'XTick', []);
        set(handles.axis_handles(ax), 'YTick', []);
        set(handles.axis_handles(ax), 'Box', 'on'); 
        set(handles.axis_handles(ax), 'YLim', [-handles.max_limit handles.max_limit]);
        set(handles.axis_handles(ax), 'XLim', [-handles.max_limit handles.max_limit]);
        set(handles.axis_handles(ax), 'ButtonDownFcn', @Axis_Callback);

    end
    
    guidata(handles.GeneticSearchFig, handles);
end

function initialize_variables(handles)
% keeps track of what variables are added to handles
    handles.selected_projs = zeros(1,15);
    handles.population_projvecs = cell(1,15);
    handles.axis_handles = zeros(1,15);
    guidata(handles.GeneticSearchFig, handles);
end




function randomly_initialize_proj_vecs(handles)
% generates random orthonormal projection vectors for each axis
    hd = guidata(handles.DataHighFig);
    
    % iterate through each axis, producing new proj_vecs
    for iaxis = 1:length(handles.axis_handles)
       r = randn(hd.num_dims,2);
       handles.population_projvecs{iaxis} = orth(r)';
    end
    guidata(handles.GeneticSearchFig, handles);
end


function plot_all_axes(handles)
% plots all datapoints onto each axis' projection vectors

    % remove the initial instructions if re-plotted
    set(handles.instructions_text, 'Visible', 'off');
    
    hd = guidata(handles.DataHighFig);
    for iaxis = 1:length(handles.axis_handles)
        hd.functions.plot_panel(handles.DataHighFig, hd, handles.axis_handles(iaxis), handles.population_projvecs{iaxis});
        handles.selected_projs(iaxis) = 0;
        set(handles.axis_handles(iaxis), 'LineWidth', 0.5);
        set(handles.axis_handles(iaxis), 'XColor', 'k');
        set(handles.axis_handles(iaxis), 'YColor', 'k');
    end
    guidata(handles.GeneticSearchFig, handles);
end

function Axis_Callback(hObject, eventdata)
% find which axis was selected (or de-selected), and change selected_projs
% accordingly
    handles = guidata(hObject);


    axis_selected = ismember(handles.axis_handles, hObject);
    handles.selected_projs(axis_selected) = ~handles.selected_projs(axis_selected);
    
    if (handles.selected_projs(axis_selected)) %make border bold and red
        set(handles.axis_handles(axis_selected), 'LineWidth', 5);
        set(handles.axis_handles(axis_selected), 'XColor', [0.5 0 0]);
        set(handles.axis_handles(axis_selected), 'YColor', [0.5 0 0]);
    else
        set(handles.axis_handles(axis_selected), 'LineWidth', 0.5);
        set(handles.axis_handles(axis_selected), 'XColor', 'k');
        set(handles.axis_handles(axis_selected), 'YColor', 'k');
    end
        
    guidata(handles.GeneticSearchFig, handles);
end

function bold_axis(h)
    set(handles.axis_handles(ax), 'LineWidth', 5);
    set(handles.axis_handles(ax), 'XColor', [0.5 0 0]);
end

function mutate_bad_peasants(handles)
%  for each unselected peasant, mutate it
%  this will only change the projection vectors in population_proj_vecs

    good_peasants = find(handles.selected_projs);
    bad_peasants = find(~handles.selected_projs);
    for ipeasant = bad_peasants
        u = rand;  % draw random number to try different things
        
        if (~any(handles.selected_projs) || u < 0.1)  % get a new random projection (if no good peasants)
            handles.population_projvecs{ipeasant} = get_random_projvecs(handles);
        else     % rotate towards a random good peasant
            random_good_peasant = good_peasants(randi(length(good_peasants)));
            handles.population_projvecs{ipeasant} = get_closer_projvecs(handles.population_projvecs{ipeasant}, handles.population_projvecs{random_good_peasant}, 0.5);
        end
    end
    guidata(handles.GeneticSearchFig, handles);
end

function mutate_good_peasants(handles)
%  for each selected peasant, mutate it
%  this will only change the projection vectors in population_proj_vecs

    good_peasants = find(handles.selected_projs);
    bad_peasants = find(~handles.selected_projs);
    for ipeasant = good_peasants
        u = rand;
        if (u < 0.1)
            % no change
        elseif (u < 0.55) % rotate a small amount from the current projection
             handles.population_projvecs{ipeasant} = get_smallalpha_rotated_projvecs(handles.population_projvecs{ipeasant}, pi/3);

        else  % pick proj vecs from the range of currently chosen projection vectors
            handles.population_projvecs{ipeasant} = get_inrange_projvecs(handles);

        end
        
    end
    guidata(handles.GeneticSearchFig, handles);
end


%%% helper mutate functions %%%

function r = get_random_projvecs(handles)
% return random projection vectors
    hd = guidata(handles.DataHighFig);
    r = randn(hd.num_dims,2);
    r = orth(r)';
end

function r = get_closer_projvecs(orig_projvecs, desired_projvecs, angle_fraction)
%  move the orig_projvecs closer to desired proj_vecs by rotating the
%  orig_projvecs a certain angle
%  angle_fraction will move the orig_projvecs a fraction of the angle that
%  separates them, angle_fraction \in [0 1]

    % rotate first proj_vecs
    angle = acos(orig_projvecs(1,:) * desired_projvecs(1,:)');
    R = find_rotation_matrix(orig_projvecs(1,:), desired_projvecs(1,:), angle * angle_fraction);
    pv = (R * orig_projvecs')';
    angle = acos(pv(2,:) * desired_projvecs(2,:)');
    R = find_rotation_matrix(pv(2,:), desired_projvecs(2,:), angle * angle_fraction);
    r = (R * pv')';
end

function r = get_smallalpha_rotated_projvecs(orig_projvecs, alpha)
%  rotates orig_projvecs a small, random angle
    r = orig_projvecs';
    for i = 1:5
        R = get_rotation_matrix(alpha, randi(size(orig_projvecs,2)-1), size(orig_projvecs,2));
        r = R * r;
    end
    r = r';
end

function r = get_inrange_projvecs(handles)
% uses the column space of currently selected projection vectors to come up
% with two inside the range
    
    % there must be some selected projections, so no need for empty case
    
    columnspace = [];
    for iselected = find(handles.selected_projs)
        columnspace = [columnspace handles.population_projvecs{iselected}'];
    end

    % find orthogonal range of the space
    range = orth(columnspace);

    % return two random orthogonal projection vectors in that space
    rp = randperm(size(range,2));
    r = range(:,rp(1:2))';
    
end

function R = get_rotation_matrix(alpha, angle_number, num_dims)
% return the rotation matrix based on the angle_number
    
    R = eye(num_dims, num_dims);
    R(angle_number, angle_number) = cos(alpha);
    R(angle_number, angle_number+1) = -sin(alpha);
    R(angle_number+1, angle_number) = sin(alpha);
    R(angle_number+1, angle_number+1) = cos(alpha);
end

function R = find_rotation_matrix(v1, v2, alpha)
% R = find_rotation_matrix(v1, v2)
%
% v1: Nx1, v2: Nx1
% alpha is the dot product
%
% given two vectors, find the rotation matrix that could transform v1 to v2
%
% in other words, find R such that v2 = R * v1
%
%  Thus, if you have a point that also needs to be rotated by the same
%  angle, use x_new = R * x_old.
%
% Author: bcowley 2012


    % Idea:  
    %
    %  find w1 and w2, such that W = [w1 w2 : : :] is the Gram-Schmidt matrix found
    %  by performing Gram-Schmidt on V = [v1 v2 : : :]
    %
    %  then, find the angle between v1 and v2, alpha
    %
    %  R = W * [rotation_matrix_1_1(alpha)] * W' 

    if (size(v1,1)==1)  % if row, change to column
        v1 = v1';
    end
    if (size(v2,1)==1)
        v2 = v2';
    end
    
    v1 = v1 / norm(v1);
    v2 = v2 / norm(v2);
    
    % find bases
    V = randn(length(v1), length(v1));
    V(:,1) = v1;
    V(:,2) = v2;

    [W r] = qr(V);
    W(:,1) = sign(W(:,1)'*V(:,1))*W(:,1);  % QR may change the signs...
    W(:,2) = sign(W(:,2)'*V(:,2))*W(:,2);

    
    % get rotation matrix

    Rmatrix = eye(length(v2));
    Rmatrix(1,1) = cos(alpha);
    Rmatrix(1,2) = -sin(alpha);
    Rmatrix(2,1) = sin(alpha);
    Rmatrix(2,2) = cos(alpha);
    
    R = W * Rmatrix * W';

end


function genetic_search_helpbutton_Callback(hObject, eventdata, handles)
% help button for genetic search






    helpbox(['Select the most interesting projections from the displayed\n' ...
        '15 random projections. Click Next Generation for GeneticSearch\n' ...
        'to choose 15 new projections that are similar to the selected\n' ...
        'ones.  Proceed with a few generations.\n\n' ...
        'Randomize Projections displays 15 new random projections.\n\n' ...
        'After the Search, select only one projection and upload it\n' ...
        'to DataHigh.']);


end