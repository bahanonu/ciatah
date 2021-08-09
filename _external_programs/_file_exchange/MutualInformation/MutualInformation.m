function I = MutualInformation(X,Y);
% MutualInformation: returns mutual information (in bits) of the 'X' and 'Y'
% by Will Dwinnell
% biafra ahanonu, updating on 2013.12.27
%
% I = MutualInformation(X,Y);
% I(X;Y) = H(X) + H(Y) - H(X,Y)
%
% I  = calculated mutual information (in bits)
% X  = variable(s) to be analyzed (column vector)
% Y  = variable to be analyzed (column vector)
%
% Note: Multiple variables may be handled jointly as columns in matrix 'X'.
% Note: Requires the 'Entropy' and 'JointEntropy' functions.
%
% Last modified: Nov-12-2006
% changelog
	% 2013.12.27 - allow it to calculate the mutual information between X and multiple Ys (instead of just 1). also added a try/catch statement
	% 2014.04.13 [12:16:43] - added waitbar
    % 2015.09.17 - moved all X calculations out of the loop to speed up
    % calculations since they don't change

% i'd rather deal in row vector inputs
X = X';
Y = Y';
numY = size(Y,2);
I = nan(numY,1);

try
	% reverseStr = '';
    jointEntropyX = JointEntropy(X);
    entropyX = Entropy(X);
	for ny = 1:numY
		thisY = Y(:,ny);
		if (size(X,2) > 1)  % More than one predictor?
		    % Axiom of information theory
		    I(ny) = jointEntropyX + Entropy(thisY) - JointEntropy([X thisY]);
		else
		    % Axiom of information theory
	    	I(ny) = entropyX + Entropy(thisY) - JointEntropy([X thisY]);
		end
		% reverseStr = cmdWaitbar(ny,numY,reverseStr,'inputStr','calculating mutual information','waitbarOn',1,'displayEvery',5);
	end
catch err
	display(repmat('@',1,7))
	disp(getReport(err,'extended','hyperlinks','on'));
	display(repmat('@',1,7))
end

% God bless Claude Shannon.

% EOF