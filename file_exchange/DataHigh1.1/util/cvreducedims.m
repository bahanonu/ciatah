function [projs mse like lat] = cvreducedims(D, alg, dims, handles)  
%  [projs mse like] = cvreducedims(D,alg, dims, handles)
%
% CVREDUCEDIMS a dimensionality reduction tool
%
% Input:
%   D (struct) --- high-d data to be reduced
%   alg (integer) --- which red. algorithm is used
%   dims (array) --- array (ascending sorted) of which dimensions to use
%   handles --- struct that contains handles to DimReduce, specifically
%   with fields:
%   handles.binWidth (integer, seconds) --- bins the data (assuming 1ms time steps)
%   handles.use_sqrt (boolean) --- use square root transform
%   handles.kern (integer) --- smooth data if necessary
%   handles.keep_neurons --- boolean vector of which neurons to keep for
%       dim reduction
%
%   ALG can range from 1 to 4, with the following meanings:
%     1: PCA (Principal Component Analysis)
%     2: PPCA (Probabilistic Principal Component Analysis)
%     3: FA (Factor Analysis)
%     4: GPFA (Gaussian Process Factor Analysis) OR
%        LDA (Linear Discriminant Analysis) depending on the value of
%        CLUSTERS.
%
%   CLUSTERS is either 0 (traj) or 1 (clusters). If CLUSTERS is 0, then
%   ALG=4 corresponds to GPFA. Else, ALG=4 corresponds to LDA. If
%   CLUSTERS=0 and ALG~=4, then the data is smoothed with a Gaussian kernel
%   KERN before reduction.
%
%   See also: DIMENSIONREDUCE, DATAHIGH
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



    
    % Remove low firing rate neurons

    for itrial = 1:length(D)
        D(itrial).data = D(itrial).data(handles.keep_neurons,:);
    end
    
    
    % Bin the spikes and use square root transform (use gpfa's pack)
    if (handles.binWidth ~= 1 || handles.use_sqrt)
        [d(1:length(D)).spikes] = deal(D.data);
        for itrial = 1:length(D)
            d(itrial).trialId = itrial;
        end

        s = getSeq(d, handles.binWidth, 'useSqrt', handles.use_sqrt);

        [D.data] = deal(s.y);
    end

    % Trial-average neural trajectories
    if (handles.trial_average)
        D = trial_average(D);
    end

    
    % Check to make sure cross validation will work
    if (any(ismember({D.type}, 'state')))
        if (size([D.data],2) <= 3) % there are less than three trials
            fprintf('\n\nCross-validation error.  Three or more trials/conditions are required.\n');
            projs = [];
            mse = [];
            like = [];
            lat = [];
            return;
        end
    else
        if (length(D) <= 3)  % there less than three trials
            fprintf('\n\nCross-validation error.  Three or more trials/conditions are required.\n');
            projs = [];
            mse = [];
            like = [];
            lat = [];
            return;
        end
    end


    % Smooth data if necessary (automatically zero if GPFA selected)
    if get(handles.kern_slider,'Value') ~= 0
disp('should not be here');
        for i = 1:length(D)
            D(i).data = smoother(D(i).data, get(handles.kern_slider,'Value'), handles.binWidth);
        end
    end
    
    lat   = [];

    like_fold = 0;
    mse_fold = 0;  % these store the likelihood and mse for one fold
    like  = zeros(1,length(dims));
    mse   = zeros(1,length(dims)); % keeps a running total of likelihood and mse
    projs = cell(1,length(dims));

    % prepare cross-validation technique
    % break up into folds
    if (strcmp(D(1).type, 'traj')) % data is trajectories, so randomize trials
        cv_trials = randperm(length(D));
        mask = false(1, length(D));
        fold_indices = floor(linspace(1,length(D)+1, 4));  %splits it up into three chunks
    else  % data is clusters, so randomize datapoints
        cv_trials = randperm(size([D.data],2));
        fold_indices = floor(linspace(1,length(cv_trials)+1, 4));  %splits it up into three chunks
        mask = false(size(cv_trials));
    end


    % Check all dimensionns and perform cross-validation
    wbar = waitbar(0,'Cross Validating...', ...
                'CreateCancelBtn', ...
                'setappdata(gcbf, ''canceling'', 1)');
    setappdata(wbar, 'canceling',0);
    
    for idim=1:length(dims)
        
        if getappdata(wbar, 'canceling') % the user has canceled cv dim reduction
            % so break out of outer loop
            break;
        end
        
        for ifold = 1:3  % three-fold cross-validation
            
            if getappdata(wbar, 'canceling') % the user has canceled cv dim reduction
                fprintf('You have pre-maturely stopped dimensionality reduction.\n');
                projs = [];
                break;
            end
            
            waitbar((idim-1)/length(dims) + (ifold-1)/3/length(dims), wbar, ['Cross validating... dim ' ...
                num2str(dims(idim)) ' fold ' num2str(ifold)]);
            
            % prepare masks:
            % test_mask isolates a single fold, train_mask takes the rest
            test_mask = mask;
            test_mask(cv_trials(fold_indices(ifold):fold_indices(ifold+1)-1)) = true;
            train_mask = ~test_mask;
            
            switch alg   
                case 1 
                    [mse_fold p] = PCACV(D, dims(idim), ifold, train_mask, test_mask);
                case 2
                    [like_fold mse_fold p] = FACV(D, dims(idim), ifold, train_mask, test_mask, 'ppca');
                case 3
                    [like_fold mse_fold p] = FACV(D, dims(idim), ifold, train_mask, test_mask, 'fa');
                case 4
                    [mse_fold p] = LDACV(D, dims(idim), ifold, train_mask, test_mask);
                case 5
                    % give the waitbar handle and the progress to GPFA in
                    % case the user wants to kill it...
                    % matlab is really stupid about event handlers, so you
                    % have to call waitbar in the loop that you are
                    % executing for it to get the current appdata
                    bar_time = (idim-1)/length(dims) + (ifold-1)/3/length(dims);
                    [like_fold mse_fold p] = GPFACV(D, dims(idim), ifold, handles.binWidth, ...
                        train_mask, test_mask, wbar, bar_time);
            end
           
            
            if (isnan(mse_fold)) % mse was not computed, so there was a dimred error
                fprintf(['The LNO could not be computed.  This may be from\n ' ...
                    'estimation error of the covariance matrix because\n' ...
                    'too few trials.  Eliminate the largest candidate dimensionalities\n' ...
                    'from the analysis.\n']);
                projs = [];
                delete(wbar);
                return;
            end
            
            % add up the likelihood and LNO errors across folds
            mse(idim) = mse(idim) + mse_fold;
            like(idim) = like(idim) + like_fold;
            

            
            if (ifold == 1)
                projs{idim} = p;
            end

        end
    end
    
    % need to recalculate lat for PCA, since that is on all data
    [u sc lat] = princomp([D.data]');

    delete(wbar);
end



function [mse projs lat] = PCACV(D, dim, fold, train_mask, test_mask)

    [train_data test_data forProj] = prepare_cv_data(D, train_mask, test_mask);
    [u sc lat] = princomp(train_data');
    params.L = u(:,1:dim);
    params.d = mean(train_data,2);
    projs = [];
    
    if (fold == 1 && dim > 1) % keep the projections of first fold
        % All of the data projected into low-D space
        allprojs = sc(:,1:dim)';

        if (isstruct(forProj)) % trajectories
            index = 1;
            for itrial=1:length(forProj)
                projs(itrial).data = allprojs(:,index:index+size(forProj(itrial).data,2)-1);
                index = index + size(forProj(itrial).data,2);
            end
            [projs(1:end).type] = deal('traj');
        else   %clusters
            projs(1).data = allprojs;
            projs(1).type = 'state';
        end
    end

    cvdata = cosmoother_pca(test_data,params);
    mse = sum(sum((cvdata-test_data).^2));

end



function [like mse projs] = FACV(D, dim, fold, train_mask, test_mask,typ)

    [train_data test_data forProj] = prepare_cv_data(D, train_mask, test_mask);

    params = fastfa(train_data,dim,'typ',typ);

    if (isempty(params)) %an error occurred, so quit cross-validation
        like = NaN; mse = NaN; projs = [];
        return;
    end
    
    % compute likelihood on test data
    [chugs like] = fastfa_estep(test_data,params); 
    

    projs = [];   
    if (fold == 1)
        
        if (isstruct(forProj)) % trajectories
            
            % project to reduced dimensions
            [Z chugs] = fastfa_estep([forProj.data], params);
            [allprojs loadings] = orthogonalize(Z.mean,params.L);
            
            index = 1;
            for itrial=1:length(forProj)
                projs(itrial).data = allprojs(:,index:index+size(forProj(itrial).data,2)-1);
                index = index + size(forProj(itrial).data,2);
            end
            [projs(1:end).type] = deal('traj');
        else   % neural states
            % project to reduced dimensions
            [Z chugs] = fastfa_estep(forProj, params);
            [allprojs loadings] = orthogonalize(Z.mean,params.L);
            projs(1).data = allprojs;
            projs(1).type = 'state';
        end
    end

    cvdata = cosmoother_fa(test_data,params);
    mse = sum(sum((cvdata-test_data).^2));
end


function [mse projs] = LDACV(D, dim, fold, train_mask, test_mask)
    conds = length(unique({D.condition}));
    if dim > conds  % make sure the candidate dimensionality is not greater than the number of conditions
        mse = [];
        projs = [];
        fprintf('\n\nLDA Error: Candidate dimensionality cannot exceed number of conditions.\n\n');
        return;
    end
    
    % make sure there are enough trials for each condition
    conditions = unique({D.condition});
    for icond = 1:length(conds)
        if (size([D(ismember({D.condition}, conditions{icond})).data], 2) < 2) %only one trial per condition
            mse = [];
            projs = [];
            fprintf('\n\nLDA Error: Each condition must contain more than one datapoint.\n\n');
        end
    end
            
    
    % CV for LDA is a little different for clusters but same for
    % trajectories (as GPFA)
    if (strcmp(D(1).type, 'traj'))
        train_data = D(train_mask);
        test_data = D(test_mask);
    else
        % we need to keep only training datapoints, iterate through each
        % condition
        index = 0;
        train_data = D;
        for icond = 1:length(D)
            numTrials = size(D(icond).data,2);
            train_data(icond).data = train_data(icond).data(:,train_mask((1:numTrials)+index));
            index = index + numTrials;
        end
        test_d = [D.data];
        test_d = test_d(:,test_mask);
        test_data(1).data = test_d;
    end
            
    try
        [lda_data lda_eigs] = lda_engineDH(train_data,dim);
        params.L = lda_eigs(:,1:dim);
        params.d = mean([train_data.data],2);
        projs = []; 
        if (fold == 1)
            if (strcmp(D(1).type, 'traj'))
                projs = lda_data;
            else
                projs(1).data = [lda_data.data];
                projs(1).type = 'state';
            end
        end
        cvdata = cosmoother_pca([test_data.data],params); %this does the same projection as LDA would
        mse = sum(sum((cvdata-[test_data.data]).^2));
    catch err
        fprintf(['\n\nLDA failed.  Check to make sure you have more than\n' ...
            'condition and more than one trial per condition.\n\n']);
    end
end


function [like mse projs] = GPFACV(D, dim, fold, binWidth, train_mask, test_mask, wbar, bar_time)

    % Add fields to conform to GPFA's interface
    [D.y] = D.data;
    for i=1:length(D);
        D(i).trialId = i;
        D(i).T = size(D(i).data,2);
    end
    
    train_data = D(train_mask);
    test_data = D(test_mask);

    [params gpfa_traj chugsLL] = gpfa_engineDH(train_data,dim, 'binWidth', binWidth, 'wbar', wbar, 'bar_time', bar_time);
    
    if (isempty(params)) % user exited dim reduction
        like = 0; mse = 0; projs = [];
        return;
    end
    
    [chugs, like] = exactInferenceWithLL(test_data, params,'getLL',1);
    
    projs = []; 
    if (fold == 1 && dim > 1)
        % project to reduced dimensions
        for itrial=1:length(gpfa_traj)
            % orthogonalize the trajectories
            projs(itrial).data = gpfa_traj(itrial).data;
            projs(itrial).type = 'traj';
        end
    end
    
    cv_gpfa_cell = struct2cell(cosmoother_gpfa_viaOrth_fast(test_data,params,dim));
    cvdata = cell2mat(cv_gpfa_cell(9,:));
    mse = sum(sum((cvdata-[test_data.data]).^2));
end




% -------- Helper Functions

function [train_data test_data forProj] = prepare_cv_data(D, train_mask, test_mask)
% helper function to prepare the cv data
% finds the train and test data, as well as the struct for forProjs
% This is useful to handle both trajs and states

    train_data = [];
    test_data = [];
    if (strcmp(D(1).type, 'traj')) % data is trajectories
        train_data = [D(train_mask).data];
        test_data = [D(test_mask).data];
        forProj = D(train_mask);
    else  % data is clusters
        data = [D.data];
        train_data = data(:,train_mask);
        test_data = data(:,test_mask);
        forProj = data(:,train_mask);
    end
end


function newD = trial_average(D)
% Helper function
% Compute trial-averaged neural trajectories

        conditions = unique({D.condition});  % D.condition should exist
                                    % if not given by user, it makes each
                                    % traj its own condition
        if (length(conditions) == length(D)) % each traj is its own cond
              % this means user input trajs without defining cond
              % if every traj had its own condition, the same dim red
              % results would come from single-trials...
              % so make all trials same cond (which is probably what they
              % want to do)
              [D.condition] = deal('1');
              conditions = {'1'};
        end
              
        newD = [];
        for icond = 1:length(conditions)

            % find smallest trial length
            trial_lengths = [];
            trials = find(ismember({D.condition}, conditions{icond}));
            % need to keep track of which trials are in the condition
            
            for itrial = 1:length(trials)
                trial_lengths = [trial_lengths size(D(trials(itrial)).data,2)];
            end
            smallest_trial_length = min(trial_lengths);

            % truncate all trials to smallest trial length
            for itrial = 1:length(trials)
                D(trials(itrial)).data = D(trials(itrial)).data(:,1:smallest_trial_length);
            end

            % average across trials
            m = zeros(size(D(trials(1)).data));
            for itrial = 1:length(trials)
                m = m + D(trials(itrial)).data;
            end
            m = m ./ length(trials);
            
            % place into new struct
            newD(icond).data = m;
            newD(icond).type = D(trials(1)).type;
            newD(icond).condition = D(trials(1)).condition;
            newD(icond).epochStarts = D(trials(1)).epochStarts;
            newD(icond).epochColors = D(trials(1)).epochColors;
        end

end