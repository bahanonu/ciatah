function proj = ellipse(proj_vecs, cov_matrix, mean)
% Usage: proj = ellipse(proj_vecs, cov_matrix, mean)
%  Given the mean and covariance matrix, this function returns the ellipse
%  that arises from the given projection vectors (should only be two)
%
%  proj_vecs: 2 x numDims
%  cov_matrix: numDims x numDims
%  mean: numDims x 1
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


    %proj_vecs: 2xN, where N=num dims

    %  y = u * x, so cov(y) = u*cov(x)*u'
    
    cov_y = proj_vecs * cov_matrix * proj_vecs';
    
    

    % find the eigenvectors (should be only two)
    [u lam] = pcacov(cov_y);
    
    % find ellipse that'd go on that plane (the two principal comps)
    theta = 0:.01:2*pi;

    r = sqrt(diag(lam(1:2))) * [cos(theta); sin(theta)];
    
    % project onto the 2d space 
    
    proj = u(:,1:2) * r;
    
    
    % add on the cluster's mean (note this isn't the total mean of all
    % stim)
    
    proj = proj + proj_vecs * mean * ones(1,size(proj,2));