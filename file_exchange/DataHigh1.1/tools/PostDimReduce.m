function varargout = PostDimReduce(varargin)
% PostDimReduce
%
%  Pop-up figure that allows user to upload the reduced dimensions to
%  DataHigh and/or save them.  It also allows to choose the top p
%  dimensions.
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


    % Last Modified by GUIDE v2.5 01-May-2013 18:46:37

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @PostDimReduce_OpeningFcn, ...
                       'gui_OutputFcn',  @PostDimReduce_OutputFcn, ...
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


% --- Executes just before PostDimReduce is made visible.
function PostDimReduce_OpeningFcn(hObject, eventdata, handles, varargin)

    if (nargin ~= 8)
        error('Usage: PostDimReduce(orig_data,ReduceD, DimReduceFig, C, lat);');
    end

    handles.orig_data = varargin{1};
    handles.D = varargin{2};
    handles.DimReduceFig = varargin{3};
    handles.proj_matrix = varargin{4};
    handles.eigenvalues = varargin{5};
    handles.PostDimReduceFig = hObject;
    

    % Choose default command line output for PostDimReduce
    handles.output = 0;

    % if dimensionality is less than three, only save--->can't upload to
    % datahigh
    if (size(handles.D(1).data,1) <= 2)
        set(handles.upload_button, 'Visible', 'off');
    end

    set(handles.dim_text, 'String', sprintf('Select final dimensionality:'));

    % allow user to choose a smaller number of top dimensions
    handles.chosen_dim = size(handles.D(1).data,1);
    dims = cellstr(num2str((handles.chosen_dim:-1:1)'))';
    set(handles.chosen_dim_popup, 'String', dims);
    set(handles.chosen_dim_popup, 'Value', 1);
    
    % if neural states, don't display 'view single dims' because there's no time component
    if (strcmp(handles.D(1).type, 'state'))
        set(handles.view_eachdim_button, 'Visible', 'off');
        set(handles.view_eachdim_help_button, 'Visible', 'off');
    end
    
    % concatenate neural states
    %  (from one neural state per D(i), to one condition per D(i)
    if (all(ismember({handles.D.type}, 'state')))
        D = [];
        
        conds = unique({handles.D.condition});
        
        % if no conds were specified, put all neural states into one
        % condition
        % this occurs if there's only one state per trial and each trial
        % has a different condition

        only_one_state_per_trial = true;
        for itrial = 1:length(handles.D)
            only_one_state_per_trial = only_one_state_per_trial && (size(handles.D(itrial).data,2)==1);
        end
        if (only_one_state_per_trial && length(conds) == length(handles.D))
            conds = {'1'};
            [handles.D.condition] = deal('1');
        end

        % set up DataHigh format
        for icond = 1:length(conds)
            D(icond).data = [];
            D(icond).condition = conds{icond};
            D(icond).type = 'state';
            D(icond).epochStarts = 1;
            % concatenate trials
            % DEVELOPER'S NOTE:  May need to rework this...if the user has
            % different epochStarts for the same condition, how to combine
            % them?  how to color them?
            for itrial = find(ismember({handles.D.condition}, conds{icond})) % select trials with that condition
                D(icond).data = [D(icond).data handles.D(itrial).data];
            end
            if (isfield(handles.D, 'epochColors'))
                trial_indices = find(ismember({handles.D.condition}, conds{icond})); % used to find one trial for the epochColors
                D(icond).epochColors = handles.D(trial_indices(1)).epochColors(1,:);
            else
                D(icond).epochColors = rand(1,3);
            end
        end
        handles.D = D;
    end

    if (isempty(handles.eigenvalues))  % LDA does not estimate the covariance matrix
        set(handles.eigenspectrum_button, 'Visible', 'off');
        set(handles.eigenspectrum_help_button, 'Visible', 'off');
    end
    
    % Update handles structure
    guidata(hObject, handles);

end



function varargout = PostDimReduce_OutputFcn(hObject, eventdata, handles) 

    
end



function savebutton_Callback(hObject, eventdata, handles)
% saves and uploads to DataHigh

    D = keep_top_dimensions(handles);  % keep top chosen dimensions
    
    uisave('D');
    close(handles.DimReduceFig);
    close(handles.PostDimReduceFig);
    if (size(D(1).data,1) >= 3) %only call DataHigh if appropriate number of dims
        DataHigh_engine(handles.D, 'rawData', handles.orig_data);
    end
    if (ishandle(handles.figure1))
        close(handles.figure1);
    end
end


function upload_button_Callback(hObject, eventdata, handles)
% uploads the reduced dimensions to DataHigh
    D = keep_top_dimensions(handles);  % keep top chosen dimensions
    
    close(handles.DimReduceFig);
    close(handles.PostDimReduceFig);

    DataHigh_engine(D, 'rawData', handles.orig_data);
    if(ishandle(handles.figure1))
        close(handles.figure1); 
    end

end


function cancelbutton_Callback(hObject, eventdata, handles)
    close(handles.figure1);
end


function chosen_dim_popup_Callback(hObject, eventdata, handles)
% Implements the trick to choose a high reduced dimensionality, then take
% the top p dimensions.
%  User can choose the original reduced dimensionality, or the top p
%  dimensions.

    contents = cellstr(get(hObject, 'String'));  % get all possible dims
    top_dims = contents{get(hObject, 'Value')};  % get the chosen value
    
    handles.chosen_dim = str2num(top_dims);
    guidata(hObject, handles);
end


function D = keep_top_dimensions(handles)
% Removes the extra dimensions from D.data based on the top dims chosen
% from the popup menu
    for itrial = 1:length(handles.D)
        handles.D(itrial).data = handles.D(itrial).data(1:handles.chosen_dim,:);
    end
    D = handles.D;

end

function chosen_dim_popup_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function view_projmat_button_Callback(hObject, eventdata, handles)
% Shows the projection matrix as an imagesc
    figure;
    imagesc(handles.proj_matrix);
    xlabel('latent variable weights');
    ylabel('neurons');
    title('View Loading Matrix');
    colorbar;
end

function eigenspectrum_button_Callback(hObject, eventdata, handles)
% view eigenspectrum for the dim reduction method
% for PCA, it's the eigenvalues
% for LDA, not an option
% for PPCA, FA, and GPFA: eigenspectrum of CC'

    figure;
    plot(handles.eigenvalues, '.-');
    set(gca, 'XLim', [0 length(handles.eigenvalues)]);
    xlabel('Latent dimensionality');
    
    hd = guidata(handles.DimReduceFig); % get which_alg function from DimReduce

    switch hd.functions.which_alg(hd)
        case 1  % PCA
            title('Eigenspectrum of estimated covariance matrix');
            ylabel('cumulative % variance explained');
        otherwise  % PPCA, FA, GPFA  (LDA should not reach here)
            title('Eigenspectrum of estimated shared covariance matrix');
            ylabel('cumulative % shared variance explained');   
    end


end


function view_eachdim_button_Callback(hObject, eventdata, handles)
% Displays trajectories vs. time for single dimensions much like the 15
% separate plots in (Yu et. al, 2009).

    D = keep_top_dimensions(handles);
    PostDimReduceSingleDim(D);

end




% ----  Help buttons  -----

function view_projmat_help_button_Callback(hObject, eventdata, handles)
    helpbox(['View Loading Matrix displays a heat map of the loading matrix\n' ...
        'for the chosen method.  The first column represents the first latent\n' ...
        'variable''s loadings (or weights), and so on.\n\n' ...
        'If a column of the loading matrix has two or three very red elements\n' ...
        'with the rest blue, the corresponding latent variable only cares\n' ...
        'about two or three neurons.  These neurons are highly-correlated,\n' ...
        'and may be a sign of electrode cross-talk.']);
end


function eigenspectrum_help_button_Callback(hObject, eventdata, handles)

    helpbox(['\nView the eigenspectrum of the estimated shared covariance matrix.\n\n' ...
        'If the optimal dimensionality has not been found, choosing a \n' ...
        'dimensionality that explains most of the variance may be helpful.\n' ...
        'This plot shows the cumulative percent shared variance explained\n' ...
        'by each latent dimensionality.\n\n\n' ...
        'The eigenspectrum is an eigenvalue decomposition of an estimated\n' ...
        'matrix:\n\n' ...
        'for PCA:\n' ...
        '       eigenvalues of the sample covariance matrix\n' ...
        'for PPCA, FA, and GPFA:\n' ...
        '       eigenvalues of the estimated shared covariance matrix CC'',\n' ...
        '       where C is the non-orthonormalized loading matrix.']);
    
end




function view_eachdim_help_button_Callback(hObject, eventdata, handles)

    helpbox(['\nView Each Dim displays each dimension''s timecourse activity for\n' ...
        'all trials.  These contain the same information as in the neural trajectories.\n\n' ...
        'Latent variables that do not vary across time or experimental\n' ...
        'conditions can be removed, as they do not aid in visualization.\n\n' ...
        'If some latent variables have steep peaks in them (i.e., jaggedness)\n' ...
        'even with temporal smoothing, these latent variables may reflect\n' ...
        'implausibly high-correlations between neurons. If so, check for\n' ...
        'electrode cross-talk.\n' ...
        ]);
end


function chosen_dim_help_button_Callback(hObject, eventdata, handles)

    helpbox(['Select Final Dimensionality allows you to choose a subset\n' ...
        'of the top latent variables.  For example, if you performed\n' ...
        'dimensionality reduction with a candidate dimensionality of 50,\n' ...
        'you can choose to keep the 10 top dimensions.  DimReduce will\n' ...
        'remove latent variables 11 through 50 from the analyses.\n\n' ...
        'This is a noted trick in the DataHigh JNE paper:\n' ...
        'Skip cross-validation, and instead select a high number of latent\n' ...
        'dimensions.  Then, choose a subset of the top dimensions.  \n' ...
        'This trick saves in computation time, but does not identify\n' ...
        'the optimal dimensionality, which may miss key features\n' ...
        'of the data.']);
    
end
