%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following code checks for the relevant MEX files (such as .mexa64
% or .mexglx, depending on the machine architecture), and it creates the
% mex file if it can not find the right one.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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




% Toeplitz Inversion

% Create the mex file if necessary.
if ~exist(sprintf('gpfa/util/invToeplitz/invToeplitzFastZohar.%s',mexext),'file')
  try
    eval(sprintf('mex -outdir gpfa/util/invToeplitz gpfa/util/invToeplitz/invToeplitzFastZohar.c'));
    fprintf('NOTE: the relevant invToeplitz mex files were not found.  They have been created.\n');
  catch
    fprintf('NOTE: the relevant invToeplitz mex files were not found, and your machine failed to create them.\n');
    fprintf('      This usually means that you do not have the proper C/MEX compiler setup.\n');
    fprintf('      The code will still run identically, albeit slower (perhaps considerably).\n');
    fprintf('      Please read the README file, section Notes on the Use of C/MEX.\n');
  end
end
  
% Posterior Covariance Precomputation  

% Create the mex file if necessary.
if ~exist(sprintf('gpfa/util/precomp/makePautoSumFast.%s',mexext),'file')
  try
    eval(sprintf('mex -outdir gpfa/util/precomp gpfa/util/precomp/makePautoSumFast.c'));
    fprintf('NOTE: the relevant precomp mex files were not found.  They have been created.\n');
  catch
    fprintf('NOTE: the relevant precomp mex files were not found, and your machine failed to create them.\n');
    fprintf('      This usually means that you do not have the proper C/MEX compiler setup.\n');
    fprintf('      The code will still run identically, albeit slower (perhaps considerably).\n');
    fprintf('      Please read the README file, section Notes on the Use of C/MEX.\n');
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  