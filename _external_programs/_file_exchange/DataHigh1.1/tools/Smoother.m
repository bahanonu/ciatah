function varargout = Smoother(varargin)
%  Smoother
%   Allows the user to decide on different levels of smoothness for the
%   trajectories
%   Uses the convolution of the trajectory with a Gaussian
%
%   11/15/2013 BRC
%   -corrected the ability to re-smooth the original data (and not
%   re-smooth an already smoothed version of the data
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
                       'gui_OpeningFcn', @Smoother_OpeningFcn, ...
                       'gui_OutputFcn',  @Smoother_OutputFcn, ...
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


function Smoother_OpeningFcn(hObject, eventdata, handles, varargin)
% Opening function

    handles.DataHighFig = varargin{1};
    handles.functions = varargin{2};
    set(handles.smooth_slider, 'Min', 1);
    set(handles.smooth_slider, 'Max', 5);
    set(handles.smooth_slider, 'Value', 1);
    h = guidata(handles.DataHighFig);  


    set(handles.scale_factor_text, 'String', num2str(1));
    handles.functions.setUpPanel(handles.axes1, h.max_limit);
    guidata(hObject, handles);
    
    h = get_D_from_original_data(handles.DataHighFig);

size(h.D(1).data)
size(h.proj_vecs)
    handles.functions.plot_panel(handles.DataHighFig, h, handles.axes1, h.proj_vecs);
end



function varargout = Smoother_OutputFcn(hObject, eventdata, handles) 
% Closing function
end



function smooth_slider_Callback(hObject, eventdata, handles)
%  Once slider is released, updates trajectories with updated variance
    hd = get_D_from_original_data(handles.DataHighFig);
    
    D = hd.D;
    
    std_dev = get(hObject, 'Value');
    set(handles.scale_factor_text, 'String', num2str(std_dev));
    guidata(hObject, handles);
    
    for i = 1:length(D)
        if (strcmp(D(i).type, 'traj'))
            g_filt = gaussian_smooth_filter(std_dev, size(D(i).data,2));
            D(i).data = (g_filt * D(i).data')';
        end
    end
    
    % update temp hd and keep D in handles for saving the smoothing 
    hd.D = D;
    handles.D = D;
    guidata(hObject, handles);
    
    handles.functions.plot_panel(handles.DataHighFig, hd, handles.axes1, hd.proj_vecs);
    
end

function g_filter = gaussian_smooth_filter(std_deviation, vector_length)
%  helper function, this provides a matrix in which you can multiply
%  the vector, same as convolution; however, the ends are not corrupted by
%  zero padding from the filter

    g_filter = zeros(vector_length, vector_length);

    halfwindow = floor(vector_length/2);
    gauss = normpdf(-halfwindow:halfwindow, 0, std_deviation);
    
    % shift gaussian for each row
    % conv with delta function, then trim at edges
    for i=1:vector_length
        v = zeros(1, vector_length);
        v(i) = 1;
        g_filter(i,:) = conv(v, gauss, 'same');
    end

    % normalize each row
    for i=1:vector_length
        g_filter(i,:) = g_filter(i,:) / sum(g_filter(i,:));
    end
end



function smooth_slider_CreateFcn(hObject, eventdata, handles)
% Create smooth_slider function

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end    
    guidata(hObject, handles);
    
end



function save_smoothing_button_Callback(hObject, eventdata, handles)
% Upload the current data to DataHigh
    
    guidata(hObject, handles);
    smooth_slider_Callback(handles.smooth_slider, [], handles);
    handles = guidata(hObject);
    
    % update D with the smoothed D
    h = guidata(handles.DataHighFig);
    h.D = handles.D;
    guidata(handles.DataHighFig, h);
    
    close(gcf);
    figure(handles.DataHighFig);
    handles.functions.choose_conditions(handles.DataHighFig, h.selected_conds);
end


function handles = get_D_from_original_data(DataHighFig)
% Let Smoother start with the original data.  This is not D,
% since D could have been changed with previous smoothing.
% This also ensures the data has at most 17 dimensions.
%
% DataHighFig is the handle of the DataHigh figure
% returns new D with the DataHighFig handles

    handles = guidata(DataHighFig);
    handles.D = handles.orig_data;
    handles.num_dims = size(handles.D(1).data,1);
    
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
        
        
    else  % original data smaller than 17 dims, so no need for dim reduction
   
        handles.origin = -mean([handles.orig_data.data],2);
        
        for trial = 1:length(handles.orig_data)     % add the origin to recenter the data
            handles.D(trial).data = handles.orig_data(trial).data + repmat(handles.origin, 1, size(handles.orig_data(trial).data,2));
        end

        handles.num_dims = size(handles.D(1).data,1);

    end
    
    
end




function smoother_helpbutton_Callback(hObject, eventdata, handles)
% help button for smoother
    helpbox(['Smoother will convolve each latent variable with a Gaussian\n' ...
        'kernel whose st. dev. is determined by the scale factor slider.\n\n' ...
        'Note that smoothing should almost always be done before\n' ...
        'dimensionality reduction for neural data.  However, this tool may\n' ...
        'be useful for timeseries data that are not neural trajectories.\n\n' ...
        'Any changes that are saved cannot be undone by\n' ...
        'coming back to Smoother.  Instead, reload the data\n' ...
        'with Load Data in Analysis Tools.']);
end
