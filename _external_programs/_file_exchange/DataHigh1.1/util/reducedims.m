function [newD C lat] = reducedims(D,alg, dims, handles)
% REDUCEDIMS a dimensionality reduction tool
%   REDUCEDIMS(D,DIMS,ALG,DATATYPE), where D is the high dimensional data to be
%   reduced, DIMS is the number of dimensions to reduce to, ALG is an
%   integer representing the reduction algorithm to be used, and CLUSTERS
%   is an integer representing whether the data is a set of clusters or
%   neural trajectories.
%   
%  INPUTS:
%   handles --- struct that contains handles to DimReduce, specifically
%   with fields:
%   handles.binWidth (integer, seconds) --- bins the data (assuming 1ms time steps)
%   handles.use_sqrt (boolean) --- use square root transform
%   handles.kern (integer) --- smooth data if necessary
%   handles.keep_neurons --- boolean vector of which neurons to keep for
%       dim reduction
%
%   If using PPCA,FA, or GPFA, DIMS can be set to -1. In this case,
%   cross-validated likelihoods are used to determine the optimal
%   dimensionality.
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
%
%   C is the projection matrix.  e.g. For PCA, each column of C is a principal
%   component.  For FA and GPFA, each column is a factor.  
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
    
    % Smooth data if necessary (automatically zero if GPFA selected)
    if get(handles.kern_slider,'Value') ~= 0
        for i = 1:length(D)
            D(i).data = smoother(D(i).data, get(handles.kern_slider,'Value'), handles.binWidth);
        end
    end

    lat = [];
    switch alg
        case 1
            [newD C lat] = PCAreduce(D,dims);
        case 2
            [newD C lat] = PPCAreduce(D,dims);
        case 3
            [newD C lat] = FAreduce(D,dims);
        case 4
            [newD C] = LDAreduce(D,dims);
        case 5
            [newD C lat] = GPFAreduce(D,dims, handles.binWidth);
        otherwise
            fprintf('Method is not implemented.'); 
    end
    
    
end

function [newD C lat] = PCAreduce(D,dims)
% PCAREDUCE Internal function for PCA
%   PCAREDUCE(D,DIMS) returns a structure of the same form as D, except
%   the data has been reduced with PCA. All conditions and trials are
%   considered together to get the best joint reduction.

    % Agglomerate all of the conditions, and perform PCA
    alldata = [D.data];
    [u sc lat] = princomp(alldata');

    % For each condition, store the reduced version of each data vector
    index = 0;
    for i=1:length(D)
        D(i).data = sc(index + (1:size(D(i).data,2)),1:dims)';
        index = index + size(D(i).data,2);
    end
    newD = D;
    C = u(:,1:dims);
    lat = cumsum(lat(1:dims)) ./ sum(lat(1:dims));  % eigenvalues
end

function [newD C lat] = PPCAreduce(D,dims)
% PPCAREDUCE Internal function for PPCA
%   PPCAREDUCE(D,DIMS) returns a structure of the same form as D, except
%   the data has been reduced with PPCA. All conditions and trials are
%   considered together to get the best joint reduction.
    alldata = cat(2,D.data);
    [params LL] = fastfa(alldata,dims,'typ','ppca');
    [Z LL] = fastfa_estep(alldata,params);

    [allprojs loadings] = orthogonalize(Z.mean,params.L);

    index = 1;
    for itrial = 1:length(D)
        D(itrial).data = allprojs(:,index:index+size(D(itrial).data,2)-1);
        index = index + size(D(itrial).data,2);
    end
    
    newD = D;
    C = loadings;
    [chugs lat] = pcacov(params.L * params.L');
    lat = cumsum(lat(1:dims))./sum(lat(1:dims));
end

function [newD C lat] = FAreduce(D,dims)
% FAREDUCE Internal function for FA
%   FAREDUCE(D,DIMS) returns a structure of the same form as D, except
%   the data has been reduced with FA. All conditions and trials are
%   considered together.
    alldata = [D.data];
    [params LL] = fastfa(alldata,dims,'typ','fa');
    [Z LL] = fastfa_estep(alldata,params);

    [allprojs loadings] = orthogonalize(Z.mean,params.L);

    index = 1;
    for itrial = 1:length(D)
        D(itrial).data = allprojs(:,index:index+size(D(itrial).data,2)-1);
        index = index + size(D(itrial).data,2);
    end

    newD = D;
    C = loadings;
    [chugs lat] = pcacov(params.L * params.L');
    lat = cumsum(lat(1:dims))./sum(lat(1:dims));
end

function [newD C] = LDAreduce(D,dims)
%LDAREDUCE Internal function for LDA
%   LDAREDUCE(D,DIMS) returns a structure of the same form as D, except the
%   data has been reduced with LDA. All conditions and trials are
%   considered together to get the best joint reduction.
    conds = length(unique({D.condition}));
    if dims > conds
        return;
    end
    
    try
        [newD lda_eigs] = lda_engineDH(D,dims);
        C = lda_eigs(:,1:dims);
        params.d = mean([D.data],2);
    catch err
        fprintf(['\n\nLDA failed.  Check to make sure you have more than\n' ...
            'condition and more than one trial per condition.\n\n']);
    end

end


function [newD C lat] = GPFAreduce(D,dims, binWidth)
% GPFAREDUCE Internal function for GPFA
%   GPFAreduce(D,DIMS) returns a structure of the same form as D, except
%   the data has been reduced with GPFA. All conditions and trials are
%   considered together to get the best joint reduction. Code is based off
%   of GPFAENGINE, by Byron Yu and John Cunningham.

    wb = waitbar(0, 'Performing dim reduction with GPFA');
    [params newD] = gpfa_engineDH(D,dims,'dimreduce_wb',wb, 'binWidth', binWidth);
    delete(wb);
    C = params.Corth;
    [chugs lat] = pcacov(params.C * params.C');
    lat = cumsum(lat(1:dims))./sum(lat(1:dims));
end





% -------- Helper functions

function newD = trial_average(D)
% Helper function
% Compute trial-averaged neural trajectories

        conditions = unique({D.condition});  % D.condition should exist
                                    % if not given by user, it makes each
                                    % traj its own condition
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