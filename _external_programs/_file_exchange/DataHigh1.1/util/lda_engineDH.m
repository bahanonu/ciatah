function varargout = lda_engineDH(D,dims)
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


    if nargin < 3
        forceTraj = 0;
    end


    % Data on which we will perform LDA (might not be the same as our original
    % D in the case of trajectories)
    if (strcmp(D(1).type, 'state'))
        newData = D;
        conditions = unique({newData.condition});
        if (length(conditions) == 1)
            fprintf('\n\nLDA error: Data must have more than one condition.\n\n');
            return;
        end
    else
        % Split up based on trajectories as well as conditions selected in
        % splitEpochs
        newData = D;
        conditions = unique({newData.condition});
        if (length(conditions) == 1)
            fprintf('\n\nLDA error: Data must have more than one condition.\n\n');
            return;
        end
    end 

    if isempty(dims)
        dims = min(size(newData(1).data,1),length(conditions)-1);
    end
    sigma = zeros(size(newData(1).data,1));
    m = [];

    for cond = 1:length(conditions)
        if (size([newData(ismember({newData.condition}, conditions(cond))).data], 2) == 1) % not enough trials
            fprintf('\n\nLDA error: Data must have more than one trial per condition.\n\n');
            return;
        end
        sigma = sigma + cov([newData(ismember({newData.condition}, conditions(cond))).data]',1);
        m(:,cond) = mean([newData(ismember({newData.condition}, conditions(cond))).data],2);
    end

    Sigma_within = sigma ./ length(conditions);
    Sigma_between = cov(m',1);

    [eigvec eigval] = eigsort(Sigma_within \ Sigma_between);
    if nargout > 1
        varargout{2} = eigvec(:,1:dims);
    end
    if nargout > 2
        varargout{3} = eigval(1:dims);
    end
    % For each condition, store the reduced version of each data vector
    % Though we may determine LDA directions from newData, we want to store the
    % reduced versions of the original data, which contains information about
    % the trajectories.
    for i=1:length(D)
        repmean = repmat(mean(m,2),1,size(D(i).data,2));
        % Reduce data
        D(i).data = ((D(i).data - repmean)'*eigvec(:,1:dims))';

    end
    if isfield(D,'newEpochStarts');
        D = rmfield(D,'newEpochStarts');
    end;
    varargout{1} = D;
end