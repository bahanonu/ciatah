function varargout = SingleDim(varargin)
% HELP NEEDS TO BE EDITED
%
% SINGLEDIM M-file for SingleDim.fig
%      SINGLEDIM, by itself, creates a new SINGLEDIM or raises the existing
%      singleton*.
%
%      H = SINGLEDIM returns the handle to a new SINGLEDIM or the handle to
%      the existing singleton*.
%
%      SINGLEDIM('Property','Value',...) creates a new SINGLEDIM using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to SingleDim_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      SINGLEDIM('CALLBACK') and SINGLEDIM('CALLBACK',hObject,...) call the
%      local function named CALLBACK in SINGLEDIM.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
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

% Edit the above text to modify the response to help SingleDim

% Last Modified by GUIDE v2.5 22-Apr-2013 15:59:38

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @SingleDim_OpeningFcn, ...
                       'gui_OutputFcn',  @SingleDim_OutputFcn, ...
                       'gui_LayoutFcn',  [], ...
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



function SingleDim_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.DataHighFig = varargin{1};
    hd = guidata(handles.DataHighFig);
    
    % if all states, plot histograms (each axis becomes 
    % if any trajectories, plot timecourses for each dimension
    %    (just like in Yu et al., 2009)
    

    num_dims = size(hd.D(1).data,1);

    % prepare axes
    for iaxes = 1:17
        setup_axes(handles, iaxes, num_dims);
    end
    
    if (~any(hd.selected_conds))
        close(hObject);
        disp('SingleDim:  There are no selected conditions.');
        return;   % there are no selected conditions
    elseif (all(ismember({hd.D.type}, 'state'))) % plot hists of all clusters/states
        
        % compute the maximum value
        max_limit = max(max(abs([hd.D.data])));
        set_limit(handles, 'XLim', [-max_limit max_limit]);
        max_y_limit = 0;
        
        
        % generate histograms for each dimension, ensuring normalization
        % and equal axis scaling
        conds = unique({hd.D.condition});
        for icond = find(hd.selected_conds) % for selected conds
            for idim = 1:num_dims  % for each single dim
                for icluster = find(ismember({hd.D.condition}, conds{icond}))  % for each cluster
                    [bins centers] = hist(hd.D(icluster).data(idim,:));
                    bins = bins ./ sum(bins);
                    if (max(bins) > max_y_limit)  % to scale the YLim
                        max_y_limit = max(bins);
                    end
                    bar(handles.(sprintf('axes%d', idim)), centers, bins, 'FaceColor', ...
                        hd.D(icluster).epochColors(1,:));
                end
            end
        end
        

        % set the max_limit for the y-axis
        set_limit(handles, 'YLim', [0 10/9 * max_y_limit]);
        
        % make all patches transparent
        for iaxes = 1:17
            h = findobj(handles.(sprintf('axes%d', idim)), 'Type', 'patch');
            if (~isempty(h))
                for ih = 1:length(h)
                    set(h, 'FaceAlpha', 0.5);
                end
            end
        end

    else  % plot only the trajs
        Dtraj = hd.D(ismember({hd.D.type}, 'traj'));
        
        % compute the maximum value
        max_limit = 10/9 * max(max(abs([Dtraj.data])));
        set_limit(handles, 'YLim', [-max_limit max_limit]);


        conds = unique({Dtraj.condition});
        for icond = find(hd.selected_conds) % for selected conds
            for idim = 1:num_dims  % for each single dim
                for itrial = find(ismember({Dtraj.condition}, conds{icond}))  % for each trial
                    epochs = [Dtraj(itrial).epochStarts size(Dtraj(itrial).data,2)];
                    for iepoch = 1:length(epochs)-1
                        indices = epochs(iepoch):(epochs(iepoch+1));
                        plot(handles.(sprintf('axes%d', idim)), indices, Dtraj(itrial).data(idim,indices), ...
                            'Color', Dtraj(itrial).epochColors(iepoch,:));
                    end
                end
            end
        end
    end
    
    guidata(hObject, handles);
end


function varargout = SingleDim_OutputFcn(hObject, eventdata, handles)

end



function setup_axes(handles, iaxes, num_dims)
% setups the axes for plotting
% if the axes number is greater than the data's dimensionality,
% that plot is made invisible

    axes_handle = handles.(sprintf('axes%d', iaxes));
    if (iaxes > num_dims)
        set(axes_handle, 'Visible', 'off');
        set(handles.(sprintf('label%d', iaxes')), 'Visible', 'off');
    else
        set(axes_handle, 'XTick', []);
        set(axes_handle, 'YTick', []);
        set(axes_handle, 'Box', 'on');
        set(axes_handle, 'NextPlot', 'add');
    end
end


function set_limit(handles, axes_str, max_limit)
% set the limits for each axes
%  axes_str = {'XLim', 'YLim'}
%  max_limit = [lower_lim upper_lim]

    for iaxes = 1:17
            set(handles.(sprintf('axes%d',iaxes)), axes_str, max_limit);
            set(handles.(sprintf('axes%d',iaxes)), axes_str, max_limit);
    end

end


function single_dim_help_button_Callback(hObject, eventdata, handles)
% pops up a help button to explain SingleDim

    hd = guidata(handles.DataHighFig);

    % if neural states, explain histograms
    % if neural trajs, explain timecourse of each dimension
    
    if (all(ismember({hd.D.type}, 'state'))) % all clusters
        helpbox(['SingleDim displays histograms of the data for each latent variable.\n' ...
            'For example, the axes labelled ''1'' plots the normalized frequency\n' ...
            'of occurrence versus the value of the first latent variable.  Each\n' ...
            'condition''s cluster is color-coded as in the main DataHigh interface.\n\n' ...
            'These plots help to gain insight into how the data is distributed\n' ...
            'for each latent dimension.\n']);
    else   % trajectories
        helpbox(['SingleDim displays the timecourse of the data for each latent\n' ...
            'variable.  For example, the axes labelled ''1'' plots the value\n' ...
            'of the first latent variable versus time (whose units depend on\n' ...
            'the user-defined bin width).  These plots help to gain insight into' ...
            'how each latent variable contributes to the neural trajectories.']);
    end
end
