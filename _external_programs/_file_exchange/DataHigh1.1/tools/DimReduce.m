function varargout = DimReduce(varargin)
%  DimReduce 
%
%  Future work:
%   -  Change the handles.alg number.  It's confusing when LDA is included or
%   not included. (right now, LDA alg==4, and GPFA alg==5) with noLDA flag
%   -  Allow modular functions to be added.  Need to make sure added
%   functions conform to cross-validation and the toggle buttons, etc.
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
                   'gui_OpeningFcn', @DimReduce_OpeningFcn, ...
                   'gui_OutputFcn',  @DimReduce_OutputFcn, ...
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




function DimReduce_OpeningFcn(hObject, eventdata, handles, varargin)
%  DimReduce opening function


    % Update handles structure
    guidata(hObject, handles);

    
    % Constants for CV data structures
    alg_num = 5; % total number of dimensionality reduction algorithms
    total_dims = 17; % maximum number of dimensions allowed in DataHigh
    if (nargin < 4)
        fprintf('DimReduce requires a data matrix as input. Exiting...');
        close(hObject);
        return;
    end

    % Get data from input parameter
    handles.orig_data = varargin{1};

    handles.raw_data = handles.orig_data;  %orig_data can change for neural states,
            % so now use a raw one which is the true original
    handles.num_dims = size(handles.orig_data(1).data,1);

   
    % Check if any of the data values are less than zero 
    %  since DimReduce requires spike trains
    if (any(any([handles.orig_data.data] < 0)))
        fprintf('DimReduce handles only spike trains.  The values in the data field\n');
        fprintf('must be nonnegative.\n');
        close(hObject);
        return; 
    end
    
    
    % set title to 'DimReduce'
    set(hObject, 'Name', 'DimReduce');
  
    
    % Set initial kernel text
    set(handles.kern_text,'String',['Smoothing kernel width: '...
        num2str(get(handles.kern_slider,'Value')) 'ms']);

    
    % Set up Next Step button configuration
    set(handles.next_step_button, 'UserData', 2); %point to the next step
    set(handles.next_step_text, 'String', '1. Choose time bin width.');

    % Check if LDA is a valid algorithm (i.e., if the data has enough
    % conditions)
    conds = unique({handles.orig_data.condition});
    if (strcmp(handles.orig_data(1).type, 'state'))
        if (length(conds) == 1)
        % if only one condition, can't perform LDA
            handles.noLDA = 1;
        else
            handles.noLDA = 0;
        end
    else  %dealing with trajs
        if (length(conds) == length(handles.orig_data))
            % each trial is a different condition, so LDA is undefined
            handles.noLDA = 1;
        else
            handles.noLDA = 0;
        end
    end

    % Initially set up for trajectories. If we have clusters, set up that way.
    % if a mix between clusters and trajectories, do not do dim reduction
    if (any(ismember({handles.orig_data.type}, 'state')) && any(ismember({handles.orig_data.type}, 'traj'))) %check if both types exists
        fprintf('DimReduce handles only one type (either state or traj); it cannot have a mix.\n');
        close(hObject);
        return;
    end
    
    
    % find minimum trial length
    min_trial_length = inf;
    for itrial = 1:length(handles.orig_data)
        if (size(handles.orig_data(itrial).data,2) < min_trial_length)
            min_trial_length = size(handles.orig_data(itrial).data,2);
        end
    end
    handles.min_trial_length = min_trial_length;
    
    % Set up the sliders and menus properly before displaying GUI
    set(handles.dims_slider,'Value',2);
    set(handles.time_bin_edit, 'String', sprintf('%d', min(20, min_trial_length))); %set initial time bin width to 20ms
    set(handles.time_bin_text, 'String', 'Time bin width: ');
    handles.binWidth = min(20, min_trial_length);
    set(handles.max_time_bin_text, 'String', sprintf('max: %dms', min_trial_length));
    set(handles.mean_thresh_edit, 'String', 0.0);
    handles.mean_thresh = 0.0;
    set(handles.neurons_removed_text, 'String', '0 neurons removed');
    handles.trial_average = false;
    set(handles.orig_dims_text, 'String', sprintf('Original number of dimensions: %d', handles.num_dims));
    handles.dims = 1:handles.num_dims;
    set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
    set(handles.plot_panel, 'Visible', 'off');
    


    % Initialize cross-validation data structures
    handles.proj_data = cell(alg_num,total_dims-1);
    handles.mse_data = cell(1,alg_num);
    handles.like_data = cell(1,alg_num);
    handles.use_sqrt = false;
    
    
    if any(ismember({handles.orig_data.type}, 'state'))
        % user entered in spike counts, not spike trains, so don't allow
        % binning options
        set(handles.time_bin_edit, 'Enable', 'off');
        set(handles.max_time_bin_text, 'Visible', 'off');
        handles.binWidth = 1;
        guidata(hObject, handles);
        set(handles.mean_thresh_edit, 'Enable', 'off');
        set_for_clusters(handles);
    else  % for neural trajectories
        set_for_trajectories(handles);
    end
    
    % make step texts invisible
    for istep = 2:8
        set(handles.(sprintf('step%d_text', istep)), 'Visible', 'off');
    end
    
    % initialize mean threshold edit box and dimensionality slider
    guidata(hObject, handles);
    mean_thresh_edit_Callback(handles.mean_thresh_edit, eventdata, handles);
    handles = guidata(hObject);
    dims_slider_Callback(handles.dims_slider,eventdata,handles);
    handles = guidata(hObject);
    
    % add which_alg function so that PostDimReduce has access to it
    functions.which_alg = @which_alg;
    handles.functions = functions;
%     guidata(hObject, handles);
    alg_menu_Callback(handles.alg_menu,eventdata,handles);
end

% --- Outputs from this function are returned to the command line.
function varargout = DimReduce_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure

    if (ishandle(hObject))
        set(gcf, 'units', 'normalized');
        p = get(gcf, 'OuterPosition');
        set(gcf, 'OuterPosition', [0.1 0.1 p(3) p(4)]);
    end
end

% "4" always refers to LDA. If LDA isn't a valid method, make sure to jump
% over it.
%
% This seems like a confusing way to do this.  Should restructure. -BRC
function alg = which_alg(handles)
    alg = get(handles.alg_menu,'Value');
    if handles.noLDA
        if alg == 4
            alg = 5;
        end
    end
end

% If we have cluster data, make sure that we don't give the option to smooth
% with a Gaussian Kernel, or give GPFA as an option.
function set_for_clusters(handles)
    
    set(handles.type_text,'String','Type: States');
    
    % neural states, so don't allow user to average
    set(handles.trial_average_check, 'Visible', 'off');
    set(handles.trial_average_help, 'Visible', 'off');
    
    % No smoothing, so hide kernel slider
    set(handles.kern_slider,'Visible','Off');
    set(handles.kern_text,'Visible','Off');
    set(handles.kern_helpbutton,'Visible','Off');
    
    % hide sqrt transform
    set(handles.sqrt_transform_check, 'Visible', 'off');
    set(handles.sqrt_transform_help, 'Visible', 'off');
    
    % Get rid of GPFA option
    newString{1} = 'PCA';
    newString{2} = 'PPCA';
    newString{3} = 'FA';
    if(~(handles.noLDA))
        newString{4} = 'LDA';
    end
    set(handles.alg_menu,'String',newString);
    % set the initial method to be FA
    set(handles.alg_menu,'Value', 3);
    alg_menu_Callback(handles.alg_menu, [], handles);
end



% If we have trajectory data, make sure that we give the option to smooth
% with a Gaussian Kernel and give GPFA as an option.
function set_for_trajectories(handles)

    set(handles.type_text,'String','Type: Trajs');
    
    % neural trajs, so allow user to trial-average
    set(handles.trial_average_check, 'Visible', 'on');
    set(handles.trial_average_help, 'Visible', 'on');
    
    % No smoothing, so hide kernel slider
    set(handles.kern_slider,'Visible','On');
    set(handles.kern_text,'Visible','On');
    set(handles.kern_helpbutton,'Visible','On');
    
    % hide sqrt transform
    set(handles.sqrt_transform_check, 'Visible', 'on');
    set(handles.sqrt_transform_help, 'Visible', 'on');
    
    % Add GPFA option
    %  Note the alg_menu already starts with {'PCA', 'PPCA', 'FA', 'LDA',
    %  'GPFA'}
    newString{1} = 'PCA';
    newString{2} = 'PPCA';
    newString{3} = 'FA';
    if(handles.noLDA)
        newString{4} = 'GPFA';
        set(handles.alg_menu,'String',newString);
        set(handles.alg_menu, 'Value', 4);
    else
        newString{4} = 'LDA';
        newString{5} = 'GPFA';
        set(handles.alg_menu,'String',newString);
        set(handles.alg_menu, 'Value', 5);
    end
    
end




function away_from_cv(handles)
% If we are moving from an algorithm from which we have already 
% calculated cross-validation to one in which we have not, we
% want to remove the cross-validation graphs, as we have not
% yet calculated the information necessary to produce them

    set(handles.plot_panel, 'visible', 'off');
    
    guidata(handles.DimReduceFig, handles);

end


function update_cv_plots(dim,alg,handles,new_proj_data,new_mse,new_likelihood)
% When a cross validation parameter is changed (algorithm, kernel width, etc),
% update the CV plots. Also, if the number of dimensions used chnaged, change
% the 2 dimensional plot

    % Input the new projection data for each dimension

    handles.proj_data{alg} = new_proj_data;

    % Input the new MSE vector
    handles.mse_data{alg} = new_mse;
    % If there is likelihood data, add it
    if nargin == 6
        handles.like_data{alg} = new_likelihood;
    end

    % Now, switch the CV plots to the algorithm and dimension requested.
    switch_proj_plots(dim,alg,handles);
end


function switch_proj_plots(dim,alg,handles)
% Switches the projection to that of a given dimension

    % Set up the figure to display CV info
    % Make the CV plots

    set(handles.optimum_text,'Visible','On');
    set(handles.optimum_text,'String',sprintf('Optimal # of dims: %d',...
        best_dimension(handles,alg)));
    set(handles.dims_slider, 'Value', best_dimension(handles, alg));
    set(handles.dims_text, 'String', sprintf('Select dimensionality: %d', best_dimension(handles,alg)));

    % set up the Plot Panel
    set(handles.plot_panel, 'Visible', 'on');
	set(handles.button1_toggle, 'Value', 1);
    button1_toggle_Callback(handles.button1_toggle, [], handles);
    
    % Update the handles structure
    guidata(handles.DimReduceFig,handles);
end


function dim = best_dimension(handles, alg)
% Determine the best dimensionality based on cross-validation info

    
% If we are using a method with cross-validated likelihood, return
% the dimension with the highest cross-validated likelihood
    if ~isempty(handles.like_data{alg})
        [irrel dim] = max(handles.like_data{alg});
    % Else return the dimension with the lowest cross-validated
    % leave-neuron-out prediction error
    else
        [irrel dim] = min(handles.mse_data{alg});
    end
    dim = handles.dims(dim);  %index the dimension set
end



function approx_time(handles)
% Give a rough approximation of how long cross-validation will take. Currently, this
% function is not in use, as it was determined that it took too long and did not give
% accurate enough approximations.
    tic;
    % Run GPFA on this data for each dimension for three iterations, and project how
    % long it will take to run 100 iterations of each (which is what cross-validation does)
    for i=2:min(17,handles.num_dims)
        [dont_care] = gpfa_engineDH(handles.orig_data,handles.num_dims,'emMaxIters',3);
    end
    approx_time = toc*100;
    if approx_time < 60
        handles.GPFAtime = sprintf('Approx runtime: %d sec',round(approx_time));
    elseif approx_time < 3600
        handles.GPFAtime = sprintf('Approx runtime: %d min',round(approx_time / 60));
    else
        handles.GPFAtime = sprintf('Approx runtime: %d hours',round(approx_time / 3600));
    end
    guidata(handles.DimReduceFig,handles);
end




%%%%%%%%%%%%%%%%% CALLBACK AND CREATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%



function alg_menu_Callback(hObject, eventdata, handles)

    % set dimension slider
    set(handles.dims_slider,'Min',1,'Max', handles.num_dims, 'SliderStep',...
        [(1/(handles.num_dims-1)) (2/(handles.num_dims-2))]);


    % Determine which algorithm we are using
    val = get(hObject,'Value');
    
    % reset the edit dimensions box
    set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
    
    % set kernel buttons to visible
    if (strcmp(handles.orig_data(1).type, 'traj'))
        set(handles.kern_slider,'Visible','on');
        set(handles.kern_text,'Visible','on');
        set(handles.kern_helpbutton,'Visible','on');
    end
    
    if (handles.noLDA == 1)
        % no LDA possible, so if val == 4, it should really be GPFA
        if (val == 4)
            val = 5;  % val points to GPFA method
        end
    end
    
    
    switch val
        case 1
            %PCA
            
            set(handles.approx_text,'String','Fast, takes seconds');
            set_button(1, 'Scree', 'scree', handles);
            set_button(2, 'LNO', 'prederr', handles);
            set_button(3, 'Proj', 'proj', handles);
        case 2
            %PPCA
            set(handles.approx_text,'String','Semi-fast, takes minutes');
            set_button(1, 'LL', 'loglikelihood', handles);
            set_button(2, 'LNO', 'prederr', handles);
            set_button(3, 'Proj', 'proj', handles);
        case 3
            %FA
            set(handles.approx_text,'String','Semi-fast, takes minutes');
            set_button(1, 'LL', 'loglikelihood', handles);
            set_button(2, 'LNO', 'prederr', handles);
            set_button(3, 'Proj', 'proj', handles);
        case 4
            %LDA
            set(handles.approx_text,'String','Fast, takes seconds');
            % Set LDA-specific parameters
            % LDA can only work with up to C-1 dimensions, where C is
            % the number of conditions
            conditions = unique({handles.orig_data.condition});
            new_dims = min(size(handles.orig_data(1).data,1),length(conditions)-1);  %if C >> n, can only go up to n
            handles.dims = 1:new_dims;
            if (new_dims == 1)
                set(handles.dims_slider, 'Max', 1.1, 'Value', 1, 'SliderStep', [.001 .01]);
            elseif (new_dims == 2)
                set(handles.dims_slider, 'Max', 2, 'Value', 1, 'SliderStep', [1 1]);
            else
                set(handles.dims_slider,'Max',new_dims,'Value',1,...
                    'SliderStep',[1/(handles.num_dims-1) 2/(handles.num_dims-1)]);
            end
            set(handles.dims_text, 'String', sprintf('Select dimensionality: %d', 1));
            set(handles.dim_set_edit, 'String', sprintf('1:%d', new_dims));
        
            set_button(1, 'LNO', 'prederr', handles);
            set_button(2, 'Proj', 'proj', handles);
            set_button(3, 'none', 'none', handles);
        case 5
            %GPFA

            set(handles.kern_slider,'Visible','Off');
            set(handles.kern_text,'Visible','Off');
            set(handles.kern_helpbutton,'Visible','Off');
            set(handles.approx_text,'String','Slow, minutes to hours');
            set_button(1, 'LL', 'loglikelihood', handles);
            set_button(2, 'Proj', 'proj', handles);
            set_button(3, 'LNO', 'prederr', handles);
    end
   
    
    handles.alg = val;
    guidata(hObject, handles);
    
    % If we don't have CV data yet, hide CV plots
    if isempty(handles.mse_data{val})
        away_from_cv(handles);
    else
        switch_proj_plots(round(get(handles.dims_slider,'Value')),val,handles);
    end
end


function alg_menu_CreateFcn(hObject, eventdata, handles)
%  Not particularly useful function
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end






%--- Parameters panel buttons ---

function dim_set_edit_Callback(hObject, eventdata, handles)
% get the dimension set from the user
% can be up to the data's full dimensionality

    str = get(hObject, 'String');
    if any(~ismember(str, ' []1234567890:')) % for security, only allow arrays
        disp('Entered dimension set is not a well-defined row vector.  Only use  " []1234567890:" characters. Using 1:num_dims instead.');
        handles.dims = 1:handles.num_dims;
        set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
        guidata(hObject, handles);
        return;
    end
    
    try
        handles.dims = eval(str); % evaluate the string to make it an array
    catch exception
        disp('Entered dimension set is not a well-defined row vector.  Using 1:num_dims instead.');
        handles.dims = 1:handles.num_dims;
        set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
        guidata(hObject, handles);
        return;
    end


    if (iscolumn(handles.dims))
        handles.dims = handles.dims';
    end
    
    if (isrow(handles.dims))
        if (any(handles.dims <= 0 | handles.dims > handles.num_dims)) %if incorrect dimensions, reset
            set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
            handles.dims = 1:handles.num_dims;
        end
    else
        disp('Entered dimension set is not a row vector.  Only use  " []1234567890:" characters. Using 1:num_dims instead.');
        handles.dims = 1:handles.num_dims;
        set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
        guidata(hObject, handles);
        return;
    end
    
    handles.dims = sort(handles.dims); % sort the array
    handles.dims = handles.dims(handles.dims > 0 & handles.dims <= handles.num_dims); %set boundaries for dims
    guidata(hObject, handles);
end
    

function dim_set_edit_CreateFcn(hObject, eventdata, handles)
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    guidata(hObject, handles);
end



function time_bin_edit_Callback(hObject, eventdata, handles)
%  Allows user to input a particular time bin.  
%  If time bin width equals the minimum trial length, data is prepared for neural states.
%  Else, data will be taken as neural trajectories.
    
    if (~all(ismember(get(hObject, 'String'), '0123456789')))
        % user did not input any numbers
        set(hObject, 'String', sprintf('%d', min(20, handles.min_trial_length)));
        return;
    end
    
    time_bin = str2double(get(hObject, 'String'));  % returns contents of time_bin_edit
    time_bin = round(time_bin); 
    
    
    
    % make sure time bin width is in range
    if (time_bin < 1)
        set(hObject, 'String', '1');
        disp(sprintf('Time bin width: must be between 1 and %d ms.', handles.min_trial_length));
        time_bin = 1;
    elseif (time_bin > handles.min_trial_length)
        set(hObject, 'String', sprintf('%d', min(20, handles.min_trial_length)));
        disp(sprintf('Time bin width: must be between 1 and %d ms.', handles.min_trial_length));
        return;
    end
    
    % if time bin width would only allow one datapoint per trial, make neural states
    if (time_bin >= handles.min_trial_length/2)
        [handles.orig_data.type] = deal('state');
        set_for_clusters(handles);  %set up for neural states
    else
        [handles.orig_data.type] = deal('traj');
        set_for_trajectories(handles); % set up for neural trajectories
    end
    
    handles.binWidth = time_bin;
    guidata(hObject, handles);
end

function time_bin_edit_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function mean_thresh_edit_Callback(hObject, eventdata, handles)
% Removes neurons from the dataset that have a mean firing rate less than
% the requested threshold

    if (~all(ismember(get(hObject, 'String'), '0123456789.-')))
        % user did not input any numbers
        set(hObject, 'String', '0.0');
    end
    
    mean_thresh = str2double(get(hObject, 'String'));  % returns contents of mean_thresh_edit

    if (mean_thresh < 0)
        fprintf('\n\n');
        disp('Mean spikes/sec threshold must be nonnegative.');
        mean_thresh = 0.0;
        set(hObject, 'String', '0.0');
    end
    
    % find which neurons should be kept
    m = mean([handles.orig_data.data],2) * 1000;
    handles.keep_neurons = m >= mean_thresh;

    if (sum(handles.keep_neurons) < 3)  % Only two neurons would be kept...
        fprintf(['\n\nDimReduce: Too many neurons were removed from high threshold.\n' ...
            'Mean spikes/sec threshold set to default.\n']);
        mean_thresh = 0.0;  % so set to zero

        handles.keep_neurons = m >= mean_thresh;
        set(hObject, 'String', '0.0');
    end
    
    % update how many neurons will be removed
    set(handles.neurons_removed_text, 'String', sprintf('%d neurons removed', sum(~handles.keep_neurons)));
    handles.num_dims = sum(handles.keep_neurons);
    set(handles.orig_dims_text, 'String', sprintf('Original number of dimensions: %d', handles.num_dims));
    handles.dims = 1:handles.num_dims;
    set(handles.dim_set_edit, 'String', sprintf('1:%d', handles.num_dims));
    set(handles.dims_slider, 'Max', handles.num_dims);
    guidata(hObject, handles);
    
end

function mean_thresh_edit_CreateFcn(hObject, eventdata, handles)
    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function trial_average_check_Callback(hObject, eventdata, handles)
% Trial-averages data
% If a condition's trials are different length, average takes the interval [1
% smallest_trial_length_of_condition].  It dynamically replaces (i.e., keeps orig_data
% but makes changes when performing dim reduction) single trials with
% trial-averaged neural trajectories.  The number of trajectories will
% equal the number of conditions.

    handles.trial_average = get(hObject, 'Value'); % if on, true
    guidata(hObject, handles);
end


function sqrt_transform_check_Callback(hObject, eventdata, handles)
% Checkbox allows user to use sqrt transform in GPFA code pack
    handles.use_sqrt = get(hObject, 'Value');  % if on, true
    guidata(hObject, handles);
end


function kern_slider_Callback(hObject, eventdata, handles)
% fix the sliders for integer intervals

    value = get(hObject, 'Value');
    value = round(value);
    set(handles.kern_text,'String',['Smoothing kernel width: '...
        num2str(value) 'ms']);
    set(hObject, 'Value', value);
    guidata(hObject, handles);
end


function kern_slider_CreateFcn(hObject, eventdata, handles)

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    set(hObject,'Min',0,'Max',100,'Value',0);
    set(hObject,'SliderStep',[1/100 5/100]);

end


function perform_crossval_button_Callback(hObject, eventdata, handles)
% show cv info after computing the dimensionality reduction algorithm
    alg = which_alg(handles);

    [projs mse like lat] = cvreducedims(handles.orig_data,alg,...
        handles.dims, handles);
    
    if (isempty(projs) || isempty(mse))
        fprintf(['\nCross-validation failed.  Please refer to the\n' ...
            'User''s Guide to troubleshoot.\n\n']);
        return;
    end

    handles.lat = lat;
    
    % show uploading slider and buttons
    set(handles.dims_text, 'Visible', 'on');
    set(handles.dims_slider, 'Visible', 'on');
    set(handles.dims_helpbutton, 'Visible', 'on');
    set(handles.optimum_text, 'Visible', 'on');
    set(handles.upload_to_datahigh_button, 'Visible', 'on');
    set(handles.upload_to_datahigh_helpbutton, 'Visible', 'on');
    
    
    guidata(hObject, handles);
    
    % Update cv plots
    dims = round(get(handles.dims_slider,'Value'));
    if (alg == 1 || alg == 4)  % if PCA or LDA, no like
        update_cv_plots(dims,alg,handles,projs,mse);
    else
        update_cv_plots(dims,alg,handles,projs,mse,like);
    end
end








%--- Next Step Instructions ---

function next_step_button_Callback(hObject, eventdata, handles)
% Shows the next step in dimensionality reduction
    
    value = get(hObject, 'UserData');

    switch value
        case 1
            set(handles.next_step_text, 'String', '1. Choose time bin width.');
            set(hObject, 'UserData', 2);
            set(handles.step8_text, 'Visible', 'off');
            set(handles.step1_text, 'Visible', 'on');
        case 2
            set(handles.next_step_text, 'String', '2.  Choose a dimensionality reduction algorithm.');
            set(hObject, 'UserData', 3);
            set(handles.step1_text, 'Visible', 'off');
            set(handles.step2_text, 'Visible', 'on');
        case 3
            set(handles.next_step_text, 'String', '3. Choose which candidate dimensionalities to test.');
            set(hObject, 'UserData', 4);
            set(handles.step2_text, 'Visible', 'off');
            set(handles.step3_text, 'Visible', 'on');
        case 4
            set(handles.next_step_text, 'String', '4. (If traj) Choose pre-processing parameters.');
            set(hObject, 'UserData', 5);
            set(handles.step3_text, 'Visible', 'off');
            if (strcmp(get(handles.type_text, 'String'), 'Type: Trajs')) %if traj, show 4
                set(handles.step4_text, 'Visible', 'on');
            end
        case 5
            set(handles.next_step_text, 'String', '5. Perform cross-validated dimensionality reduction.');
            set(hObject, 'UserData', 6);
            set(handles.step4_text, 'Visible', 'off');
            set(handles.step5_text, 'Visible', 'on');
        case 6
            set(handles.next_step_text, 'String', '6. View plots to decide number of latent variables.');
            set(hObject, 'UserData', 7);
            set(handles.step5_text, 'Visible', 'off');
            if (isempty(handles.mse_data{handles.alg})) % if perform dim. has not been called, don't show these steps
                set(handles.step6_text, 'Visible', 'off');
            else
                set(handles.step6_text, 'Visible', 'on');
            end
        case 7
            set(handles.next_step_text, 'String', '7. Choose dimensionality of latent space.');
            set(hObject, 'UserData', 8);
            set(handles.step6_text, 'Visible', 'off');
            if (isempty(handles.mse_data{handles.alg})) % if perform dim. has not been called, don't show these steps
                set(handles.step7_text, 'Visible', 'off');
            else
                set(handles.step7_text, 'Visible', 'on');
            end
        case 8
            set(handles.next_step_text, 'String', '8. Upload to DataHigh.');
            set(hObject, 'UserData', 1);
            set(handles.step7_text, 'Visible', 'off');
            if (isempty(handles.mse_data{handles.alg})) % if perform dim. has not been called, don't show these steps
                set(handles.step8_text, 'Visible', 'off');
            else
                set(handles.step8_text, 'Visible', 'on');
            end
    end
    guidata(handles.DimReduceFig, handles);
end



%--- Dimensionality Plots Panel functions ---

function button1_toggle_Callback(hObject, eventdata, handles)
% first toggle button in plots panel
    

    toggle_status = get(hObject, 'Value');
    
    if (toggle_status == 1) % button was not on
        % raise the other tabs
        set(handles.button2_toggle, 'Value', 0);
        set(handles.button3_toggle, 'Value', 0);
        
        % need to change the plot to the UserData's function
        button_function = get(hObject, 'UserData');
        if (strcmp(button_function, 'proj'))
            plot_proj(handles);
        elseif (strcmp(button_function, 'loglikelihood'))
            plot_loglikelihood(handles);
        elseif (strcmp(button_function, 'prederr'))
            plot_prederr(handles);
        elseif (strcmp(button_function, 'scree'))
            plot_scree(handles);
        elseif (strcmp(button_function, 'none'))
            % do nothing; should be invisible
        end

    else  % button was on before, so do nothing
        set(hObject, 'Value', 1);
    end
    
end

function button2_toggle_Callback(hObject, eventdata, handles)
% second toggle button in plots panel

    toggle_status = get(hObject, 'Value');
    
    if (toggle_status == 1) % button was not on
        % raise the other tabs
        set(handles.button1_toggle, 'Value', 0);
        set(handles.button3_toggle, 'Value', 0);
        
        % need to change the plot to the UserData's function
        button_function = get(hObject, 'UserData');
        if (strcmp(button_function, 'proj'))
            plot_proj(handles);
        elseif (strcmp(button_function, 'loglikelihood'))
            plot_loglikelihood(handles);
        elseif (strcmp(button_function, 'prederr'))
            plot_prederr(handles);
        elseif (strcmp(button_function, 'scree'))
            plot_scree(handles);
        elseif (strcmp(button_function, 'none'))
            % do nothing; should be invisible
        end

    else  % button was on before, so do nothing
        set(hObject, 'Value', 1);
    end
end

function button3_toggle_Callback(hObject, eventdata, handles)
% third toggle button in plots panel

    toggle_status = get(hObject, 'Value');
    
    if (toggle_status == 1) % button was not on
        % raise the other tabs
        set(handles.button1_toggle, 'Value', 0);
        set(handles.button2_toggle, 'Value', 0);
        
        % need to change the plot to the UserData's function
        button_function = get(hObject, 'UserData');
        if (strcmp(button_function, 'proj'))
            plot_proj(handles);
        elseif (strcmp(button_function, 'loglikelihood'))
            plot_loglikelihood(handles);
        elseif (strcmp(button_function, 'prederr'))
            plot_prederr(handles);
        elseif (strcmp(button_function, 'scree'))
            plot_scree(handles);
        elseif (strcmp(button_function, 'none'))
            % do nothing; should be invisible
        end

    else  % button was on before, so do nothing
        set(hObject, 'Value', 1);
    end
end

function set_button(button_num, button_string, button_function, handles)
% sets up the toggle button to view a certain plot
% button_num: which button to put the plot function
% button_string: what the button will say
% button function = {'proj', 'loglikelihood', 'mse', 'scree', 'none'}

    h_b = handles.(sprintf('button%d_toggle', button_num));
    
    if (strcmp(button_function, 'none'))
        set(h_b, 'Visible', 'off');
    else
        set(h_b, 'Visible', 'on');
    end

    set(h_b, 'String', button_string);
    set(h_b, 'UserData', button_function);
    guidata(handles.DimReduceFig, handles);
end


function plot_proj(handles)
% plot the 2-d projection on the plot
% uses optimal dimensionality (and first two components); if one, uses 2

    cla(handles.plot_axes);
    
    alg = which_alg(handles);
    
    % plot the 2-d projection of the data
    opt_dim = best_dimension(handles, alg);

    if (opt_dim == 1 && length(handles.dims) > 1)
        opt_dim = handles.dims(2); % if opt_dim is one, can't have 2d projection, so choose next highest in dims (1 is the smallest)
    elseif (opt_dim == 1)
        return; % cannot plot 1-d data
    end
    
    % set up the title and axes bars
    set(handles.plot_xtext, 'String', '1st dim');
    set(handles.plot_ytext, 'String', '2nd dim');
    set(handles.plot_titletext, 'String', '2-d Projection of Data');
    set(handles.plot_axes, 'XLimMode', 'auto');
    hold(handles.plot_axes, 'on');

    data = handles.proj_data{alg}{handles.dims==opt_dim};

    if (strcmp(data(1).type, 'traj'))  % plot trajectories, all blue
        for itrial = 1:length(data)
            p = data(itrial).data;
            plot(handles.plot_axes, p(1,:), p(2,:), 'Color', [0 0 1]);
        end
    else  % plot clusters, all blue (should just be one matrix)
        p = data(1).data;
        plot(handles.plot_axes, p(1,:), p(2,:), '.');
    end
    
end


function plot_loglikelihood(handles)
% plot log likelihood

    cla(handles.plot_axes);
    alg = which_alg(handles);

    % set up the title and axes bars
    set(handles.plot_xtext, 'String', 'Dimensionality');
    set(handles.plot_ytext, 'String', 'LL');
    set(handles.plot_titletext, 'String', 'Cross-Validated Log Likelihood');
    
    % plot the likelihood plot
    plot(handles.plot_axes,handles.dims,...
        handles.like_data{alg}, '.-');
    set(handles.plot_axes, 'XLim', [0 size(handles.orig_data(1).data,1)]);
    
    % plot the optimal dimension as a star
    [max_like opt_like_index] = max(handles.like_data{alg});
    hold(handles.plot_axes, 'on');
    plot(handles.plot_axes, handles.dims(opt_like_index), max_like, '*', 'MarkerSize', 15);

end




function plot_prederr(handles)
% plot mean squared error

    cla(handles.plot_axes);
    alg = which_alg(handles);
    
    % set up the title and axes bars
    set(handles.plot_xtext, 'String', 'Dimensionality');
    set(handles.plot_ytext, 'String', 'LNO Error');
    set(handles.plot_titletext, 'String', 'CV Leave-Neuron-Out Prediction Error');
    
    % plot the MSE information
    plot(handles.plot_axes,handles.dims,...
        handles.mse_data{alg}, '.-');
    set(handles.plot_axes, 'XLim', [0 size(handles.orig_data(1).data,1)]);
    
    % plot the optimal dimension as a star
    [min_mse opt_mse_index] = min(handles.mse_data{alg});
    hold(handles.plot_axes, 'on');
    plot(handles.plot_axes, handles.dims(opt_mse_index), min_mse, '*', 'MarkerSize', 15);
end


function plot_scree(handles)
% plot the scree plot for PCA

    cla(handles.plot_axes);

    % set up the title and axes bars
    set(handles.plot_xtext, 'String', 'Principal component');
    set(handles.plot_ytext, 'String', {'%var', 'explained'});
    set(handles.plot_titletext, 'String', 'Scree plot');
    
    lat = handles.lat ./ sum(handles.lat);  % the %var explained
    plot(handles.plot_axes, lat, '.-');
    set(handles.plot_axes, 'XLim', [0 size(handles.orig_data(1).data,1)]);

    
end







%--- Upload to DataHigh ---

function dims_slider_Callback(hObject, eventdata, handles)
    slideVal = round(get(hObject,'Value'));

    set(handles.dims_text,'String',sprintf(['Select dimensionality: ' num2str(slideVal)])); ...
    %    '\n Total variance explained: %.2f'...
    %     '%%'],100*sum(myeigs(1:slideVal))/sum(myeigs)));

    set(hObject, 'Value', slideVal);
    guidata(hObject, handles);
end


function dims_slider_CreateFcn(hObject, eventdata, handles)

    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end


function upload_to_datahigh_button_Callback(hObject, eventdata, handles)
% Uploads the data to DataHigh

    % Call the reduction engine and close this window, opening the confirm GUI
    kern = get(handles.kern_slider,'Value');
    if ~strcmp(handles.orig_data(1).type,'traj')
        kern = 0;
    end
    if which_alg(handles) == 5
        kern = 0;
    end
    chosen_dim = round(get(handles.dims_slider,'Value'));

    % Actually do the dimensionality reduction
    [ReduceD C lat] = reducedims(handles.orig_data,which_alg(handles),...
        chosen_dim, handles);
    
    if (isempty(ReduceD) || isempty(C))
        fprintf(['\nDimensionality reduction failed.  Please refer to the\n' ...
            'User''s Guide to troubleshoot.']);
    end
    
    % need to reformat epochStarts to match the binWidth
    if (isfield(handles.orig_data, 'epochStarts'))
        for itrial = 1:length(ReduceD)
            if (~isempty(handles.orig_data(itrial).epochStarts))
                ReduceD(itrial).epochStarts = ceil(handles.orig_data(itrial).epochStarts / handles.binWidth);
            end
        end
    end
    
    
    % Open up the post dimensionality reduction options menu
    PostDimReduce(handles.raw_data,ReduceD, handles.DimReduceFig, C, lat);

end



%--- Help button functions ---



function time_bin_help_Callback(hObject, eventdata, handles)

    helpbox(['To change the data type, change the time bin width.\n\n'...
        'If raw data is in 1ms timepoints, choose window size (in ms)\n' ...
        'to bin data.\n' ...
        'To extract neural trajectories, suggested width is 20ms.\n' ...
        'To extract neural states, suggested is max bin length, which\n' ...
        'is displayed to the right.\n\n' ...
        'If already binned, keep 1ms (no binning).']);
end

function mean_thresh_help_Callback(hObject, eventdata, handles)

        helpbox(['Assumes timesteps are 1ms (if not, don''t use).\n\n' ...
            'Neurons with a mean firing rate (across all trials)\n' ...
            'lower than the user-given threshold will be removed from\n' ...
            'subsequent analyses.  If less than three neurons are left\n' ...
            'after thresholding, the threshold is reset to the default\n' ...
            'zero spike/sec.\n\n' ...
            'Dimensionality reduction methods may also remove neurons that\n' ...
            'have no observation variability.']);
end

function trial_average_help_Callback(hObject, eventdata, handles)

        helpbox(['Averages across trials for each condition.  If each trial has\n' ...
            'a unique condition name, this averages across all trials.\n' ...
            'To avoid confusion, ensure that the data is properly aligned, and\n' ...
            'that each trial has the same length.\n\n' ...
            'If you input trial-averaged population activity, uncheck\n' ...
            'this box.\n' ...
            ]);
end





function alg_helpbutton_Callback(hObject, eventdata, handles)

    val = get(handles.alg_menu, 'Value');
    
    switch val
        case 1
            %PCA     
            helpbox(['Principal Component Analysis (PCA) extracts latent variables\n' ...
                'that explain the variance of the data.\n\n' ...
                'PCA is well-suited for extracting trial-averaged neural trajectories.']);
        case 2
            %PPCA
            helpbox(['Probabilistic Principal Component Analysis (PPCA) extracts\n' ...
                'latent variables that explain the shared variance of the data.  It\n' ...
                'allows each neuron to have the same amount of Poisson-like\n' ...
                'spiking variability.']);
        case 3
            %FA
            helpbox(['Factor Analysis (FA) extracts latent variables that explain\n' ...
                'the shared variance of the data.  It allows each neuron to have\n' ...
                'a different amount of Poisson-like spiking variability.\n\n' ...
                'FA is well-suited for extracting neural states.']);
        case 4
            %LDA
            helpbox(['Linear Discriminant Analysis (LDA) extracts latent variables\n' ...
                'such that within-condition scatter is minimized while\n' ...
                'between-condition scatter is maximized.']);
        case 5
            %GPFA
            helpbox(['Gaussian Process Factor Analysis (GPFA) extracts latent\n' ...
                'variables that explain the shared variance of the data.  Like\n' ...
                'factor analysis, it allows each neuron to have a different amount\n' ...
                'of Poisson-like spiking variability.  It also applies temporal\n' ...
                'smoothing to the latent variables, where the level of smoothness\n' ...
                'is determined by the data.\n\n' ...
                'GPFA is well-suited for extracting single-trial neural trajectories.']);

    end
end



function approx_help_button_Callback(hObject, eventdata, handles)

    helpbox(['The time to perform cross-validation is dependent on the\n' ...
        'number of candidate dimensionalities and cross-validation folds.\n\n' ...
        'Datasets with ~100 trials should be relatively quick for all\n' ...
        'methods.  Larger sets could take hours, since a dimensionality\n' ...
        'reduction method needs to train and test a new model for each\n' ...
        'candidate dimensionality and fold.\n\n' ...
        'TIP: Choose a sparse set of dimensions (e.g., 1:10:50 instead\n' ...
        'of 1:50) to perform cross-validation.\n']);
end


function dim_set_help_Callback(hObject, eventdata, handles)

    helpbox(['Choose which candidate dimensionalities to perform\n' ...
        'dimensionality reduction on. \n\n' ...
        'Write row vector as Matlab code. \n\n' ...
        'Examples: 2:2:20, [5 10 15 20], [5:8 12:14]']);

end




function sqrt_transform_help_Callback(hObject, eventdata, handles)

    helpbox(['This option allows you to use the square root transform\n' ...
        'on binned data.  For most cases, this box can remain unchecked.\n\n' ...
        'The square root transform is known to stabilize the variance \n' ...
        'of Poisson-distributed counts (Kihlberg et al. 1972).']);
end


function kern_helpbutton_Callback(hObject, eventdata, handles)

    helpbox(['Smooth timepoints with Gaussian kernel by choosing the standard\n' ...
        'deviation (in ms) of the kernel.']);
end

function perform_crossval_helpbutton_Callback(hObject, eventdata, handles)

    helpbox(['Perform three-fold cross-validation with the selected dimensionality\n' ...
        'reduction method.  A progress bar will pop up.']);
end


function plot_help_button_Callback(hObject, eventdata, handles)

    val = get(handles.alg_menu, 'Value');
    
    switch val
        case 1
            %PCA
            helpbox(['Scree: Plots the percent variance explained.  The optimal\n' ...
                'dimensionality can be estimated by selecting the candidate\n' ...
                'dimensionality that is at the ''bend of the elbow'' in the plot.\n\n' ...
                'LNO: Plot of cross-validated prediction error for\n' ...
                'leave-one-neuron-out.\n\n' ...
                'Proj: 2-d projection of the first two principal components.']);
        case 2
            %PPCA
            helpbox(['LL: Plot of cross-validated log likelihood.\n\n' ...
                'LNO: Plot of cross-validated prediction error for\n' ...
                'leave-one-neuron-out.\n\n' ...
                'Proj: 2-d projection of the first two principal components.']);
        case 3
            %FA
            helpbox(['LL: Plot of cross-validated log likelihood.\n\n' ...
                'LNO: Plot of cross-validated prediction error for\n' ...
                'leave-one-neuron-out.\n\n' ...
                'Proj: 2-d projection of the first two factors.']);
        case 4
            %LDA
            helpbox(['LNO: Cross-validated prediction error for\n' ...
                'leave-one-neuron-out.\n\n' ...
                'Proj: 2-d projection of the first two latent dimensions.']);
        case 5
            %GPFA
            helpbox(['LL: Plot of cross-validated log likelihood.\n\n' ...
                'LNO: Plot of cross-validated prediction error for\n' ...
                'leave-one-neuron-out.\n\n' ...
                'Proj: 2-d projection of the first two factors.']);

    end
end


function dims_helpbutton_Callback(hObject, eventdata, handles)

    helpbox(['Select the number of latent dimensions to extract.\n\n' ...
        'Unless using the GPFA trick to bypass cross-validation, choose\n' ...
        'the optimal dimensionality.\n\n' ...
        'In general, the cross-validation log-likelihood (LL) and\n' ...
        'cross-validated leave-one-neuron-out prediction error (LNO)\n' ...
        'return similar results.']);

end


function upload_to_datahigh_helpbutton_Callback(hObject, eventdata, handles)

    helpbox(['Perform dimensionality reduction to extract the selected\n' ...
        'number of latent variables.\n\n' ...
        'A progess bar pops up.  Then, the PostDimReduce figure pops up,\n' ...
        'which will provide more detailed information about the extracted\n' ...
        'latent variables.  You can keep the selected dimensionality, or\n' ...
        'return to DimReduce to make a more appropriate selection.']);
end
