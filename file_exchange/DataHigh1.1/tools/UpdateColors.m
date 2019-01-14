function varargout = UpdateColors(varargin)
% UpdateColors(DataHighFig, functions)
% 
%  Allows the user to manipulate values of the data struct, including
%  colors and names.
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
                       'gui_OpeningFcn', @UpdateColors_OpeningFcn, ...
                       'gui_OutputFcn',  @UpdateColors_OutputFcn, ...
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


function UpdateColors_OpeningFcn(hObject, eventdata, handles, varargin)
% Opening function

    % initialize handles parameters from DataHigh
    handles.DataHighFig = varargin{1};
    handles.UpdateDataFig = gcf;
    hd = guidata(handles.DataHighFig);
    handles.functions = hd.functions;
    handles.D = hd.D;
    handles.proj_vecs = hd.proj_vecs;
    
    handles.functions.setUpPanel(handles.mainAxes, hd.max_limit);


    guidata(hObject, handles);

    % start with the condition panel
    update_cond_button_Callback(handles.update_cond_button, [], handles);

end



function varargout = UpdateColors_OutputFcn(hObject, eventdata, handles) 
% Output function

    

end


% top buttons

function update_cond_button_Callback(hObject, eventdata, handles)
% prepares cond_panel by loading it with the first condition

    set(handles.trial_panel, 'Visible', 'off');
    set(handles.cond_panel, 'Visible', 'on');
    
    set(handles.update_cond_button, 'value', 1);
    set(handles.update_trial_button, 'value', 0);

    load_cond_panel(handles, 1);  % sets everything to the first condition

end

function update_trial_button_Callback(hObject, eventdata, handles)
% prepares trial_panel by loading it with the first trial

    set(handles.trial_panel, 'Visible', 'on');
    set(handles.cond_panel, 'Visible', 'off');
    
    set(handles.update_cond_button, 'value', 0);
    set(handles.update_trial_button, 'value', 1);
    
    % set the load_trial panel to 1 selected
    load_trial_panel(handles, 1);
    
end



% condition change panel functions

function cond_name_edit_Callback(hObject, eventdata, handles)
% changes the condition name
    
    % get the old condition name
    contents = cellstr(get(handles.conditions_list, 'String'));
    old_cond = contents{get(handles.conditions_list, 'Value')};
    
    % change the names
    for itrial = find(ismember({handles.D.condition}, old_cond))
        handles.D(itrial).condition = get(hObject, 'String');
    end
     
    guidata(hObject, handles);
    
    % find the correct new index
    conditions = unique({handles.D.condition});

    load_cond_panel(handles, find(ismember(conditions, get(hObject, 'String'))));

end

function cond_name_edit_CreateFcn(hObject, eventdata, handles)

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function conditions_list_Callback(hObject, eventdata, handles)
% updates which condition the user selected
    load_cond_panel(handles, get(hObject, 'Value'));
end

function conditions_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to conditions_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes when entered data in editable cell(s) in cond_colors_table.
function cond_colors_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to cond_colors_table (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    colors = get(hObject, 'Data');

    if (isnan(eventdata.NewData))
        colors(eventdata.Indices(1),eventdata.Indices(2)) = eventdata.PreviousData;
        set(hObject, 'Data', colors);
        return;
    end
    
    if (eventdata.NewData < 0)
        colors(eventdata.Indices(1), eventdata.Indices(2)) = 0;
    elseif (eventdata.NewData > 1)
        colors(eventdata.Indices(1), eventdata.Indices(2)) = 1;
    end

    cond_index = get(handles.conditions_list, 'Value');
    conditions = cellstr(get(handles.conditions_list, 'String'));
    % need to iterate through each trial in condition, as they may have
    % different number of epochs
    for itrial = find(ismember({handles.D.condition}, conditions(cond_index)))
        for icolor = 1:size(handles.D(itrial).epochColors,1)
            handles.D(itrial).epochColors(icolor,:) = colors(icolor,:);
        end
    end
    
    % update condition panel
    load_cond_panel(handles, cond_index);
end







% trial change panel functions

function trials_list_Callback(hObject, eventdata, handles)
% updates which trial the user sees
    load_trial_panel(handles, get(hObject, 'Value'));
end

function trials_list_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function condition_name_edit_Callback(hObject, eventdata, handles)
% changes the condition name for that trial
    
    trial_index = get(handles.trials_list, 'Value');
    handles.D(trial_index).condition = get(hObject, 'String');
     
    guidata(hObject, handles);

    load_trial_panel(handles, trial_index);
end

function condition_name_edit_CreateFcn(hObject, eventdata, handles)

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function traj_radio_Callback(hObject, eventdata, handles)
% change trial type to traj

    cluster_radio = get(handles.cluster_radio, 'Value');
    trial_index = get(handles.trials_list, 'Value');
    
    if (cluster_radio == 1)
        handles.D(trial_index).type = 'traj';
        load_trial_panel(handles, trial_index);
    else
        set(hObject, 'Value', 1);
    end
% Hint: get(hObject,'Value') returns toggle state of traj_radio
end

function cluster_radio_Callback(hObject, eventdata, handles)
% change to a cluster
    traj_radio = get(handles.traj_radio, 'Value');
    trial_index = get(handles.trials_list, 'Value');
    
    if (traj_radio == 1)
        handles.D(trial_index).type = 'cluster';
        load_trial_panel(handles, trial_index);
    else
        set(hObject, 'Value', 1);
    end
        
% Hint: get(hObject,'Value') returns toggle state of cluster_radio
end

function epoch_starts_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to epoch_starts_table (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    % epoch starts should only be one row
    

    starts = get(hObject, 'Data');
    trial_index = get(handles.trials_list, 'Value');
    
    if (isnan(eventdata.NewData))
        starts(eventdata.Indices(1), eventdata.Indices(2)) = eventdata.PreviousData;
        set(hObject, 'Data', starts);
        return;
    end

    % check if user puts in an incorrect value
    if (eventdata.Indices(2) == 1 && eventdata.NewData < 1)
            starts(eventdata.Indices(2)) = 1;
    elseif (eventdata.Indices(2) == length(starts) && eventdata.NewData > size(handles.D(trial_index).data,2))
        starts(eventdata.Indices(2)) = size(handles.D(trial_index).data,2);
    end
    
    if (eventdata.Indices(2) > 1 && starts(eventdata.Indices(2)-1) >= eventdata.NewData)
        starts(eventdata.Indices(2)) = starts(eventdata.Indices(2)-1)+1;
    elseif (eventdata.Indices(2) < length(starts) && starts(eventdata.Indices(2)+1) <= eventdata.NewData)
        starts(eventdata.Indices(2)) = starts(eventdata.Indices(2)+1)-1;
    end
    
    handles.D(trial_index).epochStarts = starts;
    load_trial_panel(handles, trial_index);
end

function epoch_colors_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to epoch_colors_table (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    colors = get(hObject, 'Data');
    
    if (isnan(eventdata.NewData))
        colors(eventdata.Indices(1),eventdata.Indices(2)) = eventdata.PreviousData;
        set(hObject, 'Data', colors);
        return;
    end
    
    if (eventdata.NewData < 0)
        colors(eventdata.Indices(1), eventdata.Indices(2)) = 0;
    elseif (eventdata.NewData > 1)
        colors(eventdata.Indices(1), eventdata.Indices(2)) = 1;
    end

    cond_index = get(handles.conditions_list, 'Value');
    conditions = cellstr(get(handles.conditions_list, 'String'));
    
    % get selected trial
    trial_index = get(handles.trials_list, 'Value');
    
    % change the epoch colors
    handles.D(trial_index).epochColors = colors;
    load_trial_panel(handles, trial_index);
end







% DataHigh Options, bottom right

function reset_data_button_Callback(hObject, eventdata, handles)
% resets all the data, but keeps it on the active panel
    
    % reset the data
    hd = guidata(handles.DataHighFig);
    handles.D = hd.D;
    
    % find if cond_panel is visible
    cond_panel_visible = get(handles.cond_panel, 'Visible');

    if (strcmp(cond_panel_visible, 'on'))
        load_cond_panel(handles, get(handles.conditions_list, 'Value'));
    else

        load_trial_panel(handles, get(handles.trials_list, 'Value'));
    end

end

function upload_button_Callback(hObject, eventdata, handles)
% uploads the changed data to DataHigh and then closes
    
    hd = guidata(handles.DataHighFig);
    
    % if number of conditions changed, clear saved projections
    conditions_old = unique({hd.D.condition});
    conditions = unique({handles.D.condition});
    if (length(conditions_old) ~= length(conditions))
        tb_handles = guidata(hd.ToolboxFig);
        for islot = 1:6
            proj_field_string = sprintf('saved_proj%d', islot);
            cla(tb_handles.(proj_field_string));
            tb_handles.saved_projs(islot).proj_vecs = [];
            tb_handles.saved_projs(islot).selected_conds = [];
            tb_handles.saved_projs(islot).selected_feats = [];
            tb_handles.saved_projs(islot).max_limit = [];
        end
        tb_handles.saved_projs_index = 0;
        guidata(hd.ToolboxFig, tb_handles);
    end
    hd.D = handles.D;

    % also need to change selected_conds
    hd.selected_conds = true(1,length(conditions));
    
    % need to reset the conditions (for example, avg_traj color could
    % change)
    handles.functions.set_annotations_tools(hd, guidata(hd.ToolboxFig));
    

    

    guidata(handles.DataHighFig, hd);
    
    close(handles.UpdateDataFig);
    
    figure(handles.DataHighFig);
    hd.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);
end

function save_file_button_Callback(hObject, eventdata, handles)
% allows the user to save the current data
    D = handles.D;
    uisave('D', 'data.mat');
end



% Helper functions

function load_cond_panel(handles, cond_index)
%  helper function to load the editable and table when a condition is
%  selected
    
    % initialize values for panels, boxes, axes, etc.
    conditions = unique({handles.D.condition});  % sets cond listbox
    set(handles.conditions_list, 'String', conditions);
    set(handles.conditions_list, 'Value', cond_index);
    
    set(handles.cond_colors_table, 'ColumnWidth', 'auto');

    % find the max epoch length in the conditions
    d = handles.D(ismember({handles.D.condition},conditions(cond_index)));
    [maxer index] = max(cellfun(@length, {d.epochStarts}));

    % set the epochColors table
    set(handles.cond_name_edit, 'String', conditions{cond_index});
    set(handles.cond_colors_table, 'Data', d(index).epochColors);
    set(handles.cond_colors_table, 'ColumnEditable', true(1,size(d(index).epochColors,2)));
    set(handles.cond_colors_table, 'ColumnWidth', 'auto');

    % plot all condition's traj/clusters on the mainAxes
    cla(handles.mainAxes);
    data = handles.D(ismember({handles.D.condition}, conditions(cond_index)));
    hold(handles.mainAxes, 'on');
    for itrial = 1:length(data)
        if (strcmp(data(itrial).type, 'traj')) % trial is a trajectory
            starts = [data(itrial).epochStarts size(data(itrial).data,2)];
            p = handles.proj_vecs * data(itrial).data;
            for iepoch = 1:length(starts)-1
                plot(handles.mainAxes, p(1,starts(iepoch):starts(iepoch+1)), p(2,starts(iepoch):starts(iepoch+1)), ...
                    'Color', data(itrial).epochColors(iepoch,:));
            end
        else   %  trial is a cluster
            starts = [data(itrial).epochStarts size(data(itrial).data,2)+1];
            p = handles.proj_vecs * data(itrial).data;
            for iepoch = 1:length(starts)-1
                plot(handles.mainAxes, p(1, starts(iepoch):starts(iepoch+1)-1), p(2,starts(iepoch):starts(iepoch+1)-1), ...
                    'LineStyle', 'none', 'Marker', 'o', 'Color', data(itrial).epochColors(iepoch,:));
            end
        end
    end
    
    guidata(handles.UpdateDataFig, handles);
end


function load_trial_panel(handles, trial_index)
% helper function to load the editable, radios, table, etc. when a trial is
% selected

    % set trials listbox
    set(handles.trials_list, 'String', cellstr(num2str((1:length(handles.D)).')).');
    set(handles.trials_list, 'Value', trial_index);
    
    set(handles.condition_name_edit, 'String', handles.D(trial_index).condition);
    
    if (strcmp(handles.D(trial_index).type, 'traj'))
        set(handles.traj_radio, 'Value', 1);
        set(handles.cluster_radio, 'Value', 0);
    else
        set(handles.traj_radio, 'Value', 0);
        set(handles.cluster_radio, 'Value', 1);
    end

    set(handles.epoch_starts_table, 'Data', handles.D(trial_index).epochStarts);
    set(handles.epoch_starts_table, 'ColumnEditable', true(1,length(handles.D(trial_index).epochStarts)));
    set(handles.epoch_colors_table, 'Data', handles.D(trial_index).epochColors);
    set(handles.epoch_colors_table, 'ColumnEditable', true(1, size(handles.D(trial_index).epochColors,2)));
    
    % plot the trial on mainAxes
    cla(handles.mainAxes);
    if (strcmp(handles.D(trial_index).type, 'traj')) % trial is a trajectory
        starts = [handles.D(trial_index).epochStarts size(handles.D(trial_index).data,2)];
        p = handles.proj_vecs * handles.D(trial_index).data;
        for iepoch = 1:length(starts)-1
            plot(handles.mainAxes, p(1,starts(iepoch):starts(iepoch+1)), p(2,starts(iepoch):starts(iepoch+1)), ...
                'Color', handles.D(trial_index).epochColors(iepoch,:));
        end
    else   %  trial is a cluster
        starts = [handles.D(trial_index).epochStarts size(handles.D(trial_index).data,2)+1];
        p = handles.proj_vecs * handles.D(trial_index).data;
        for iepoch = 1:length(starts)-1
            plot(handles.mainAxes, p(1, starts(iepoch):starts(iepoch+1)-1), p(2,starts(iepoch):starts(iepoch+1)-1), ...
                'LineStyle', 'none', 'Marker', 'o', 'Color', handles.D(trial_index).epochColors(iepoch,:));
        end
    end
    
    guidata(handles.UpdateDataFig, handles);
end



function update_colors_helpbutton_Callback(hObject, eventdata, handles)
% help button for update colors

    helpbox(['Update Colors allows the user to change color attributes for\n' ...
        'epochs and conditions.\n\n' ...
        'To update condition attributes, click the Update Condition button\n' ...
        'and choose a condition.  The user can modify the condition''s name\n' ...
        'and change the epoch colors.\n\n' ...
        'To update trial attributes, click the Update Trial button and\n' ...
        'choose a trial.  The user can modify a trial''s condition name\n' ...
        '(and thereby create a new condition), epoch start timesteps, \n' ...
        'and epoch colors.\n\n' ...
        'The user can reset the attributes, upload the colors to DataHigh,\n' ...
        'or save the file with the color changes.']);
end
