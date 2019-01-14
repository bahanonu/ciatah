% JointEntropy: Returns joint entropy (in bits) of each column of 'X'
% by Will Dwinnell
%
% H = JointEntropy(X)
%
% H = calculated joint entropy (in bits)
% X = data to be analyzed
%
% Last modified: Aug-29-2006
% biafra ahanonu - 2015.09.17 - changed shorting to make faster

function H = JointEntropy(X)

% Sort to get identical records together
%X = sortrows(X);
[~,idx]=sort(X(:,1)); 
X=X(idx,:);  

% Find elemental differences from predecessors
DeltaRow = (X(2:end,:) ~= X(1:end-1,:));

% Summarize by record
Delta = [1; any(DeltaRow')'];

% Generate vector symbol indices
VectorX = cumsum(Delta);

% Calculate entropy the usual way on the vector symbols
H = Entropy(VectorX);


% God bless Claude Shannon.

% EOF


