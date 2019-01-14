function [gpfa_params gpfa_traj LL] = gpfa_engineDH(D,dims,varargin)
% GPFA_ENGINEDH A modified GPFA_ENGINE for the DataHigh program
%
%  Inputs:
%   D -- struct of trajectories, make sure it conforms to gpfa's format
%   dims --- the dimension you choose for the number of latent variables
%   emMaxIters (optional) --- number of iterations GPFA will go to
%   wb (optional) --- updates waitbar
%   binWidth (optional, default:20) --- if you want to change binWidth
%  Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, John Cunningham, 2012-2013

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

    startup_gpfa;  % run the script to set up MEX environment
    emMaxIters = 200;  % shown to work for most cases...add functionality to be changed by user?
    wbar = -1;  % waitbar handle...if not a handle, the user has interrupted and stopped dimreduction
    binWidth = 20; % in msec
    extra_opts = assignopts(who,varargin);

    % Set maxIters option
    if nargin < 3
        emMaxIters = 500;
    end
    gpfa_params = [];
    gpfa_traj = [];
    LL = [];

    
    % Add fields to conform to GPFA's interface
    [D.y] = D.data;
    for i=1:length(D);
        D(i).trialId = i;
        D(i).T = size(D(i).data,2);
    end

  startTau      = 100; % in msec
  startEps      = 1e-3;
   
  % For compute efficiency, train on equal-length segments of trials
  seqTrainCut = cutTrials(D);
  if isempty(seqTrainCut)
    fprintf('WARNING: no segments extracted for training.  Defaulting to segLength=Inf.\n');
    seqTrainCut = cutTrials(D, 'segLength', Inf);
  end
  
  % ==================================
  % Initialize state model parameters
  % ==================================
  startParams.covType = 'rbf';
  % GP timescale
  % Assume binWidth is the time step size.
  startParams.gamma = (binWidth / startTau)^2 * ones(1, dims);
  % GP noise variance
  startParams.eps   = startEps * ones(1, dims);

  % ========================================
  % Initialize observation model parameters
  % ========================================
  yAll             = [seqTrainCut.y];
  [faParams, faLL] = fastfa(yAll, dims);
  
  startParams.d = mean(yAll, 2);
  startParams.C = faParams.L;
  startParams.R = diag(faParams.Ph);

  % Define parameter constraints
  startParams.notes.learnKernelParams = true;
  startParams.notes.learnGPNoise      = false;
  startParams.notes.RforceDiagonal    = true;

  currentParams = startParams;

  % =====================
  % Fit model parameters
  % =====================


  [gpfa_params, seqTrainCut, LL] =... 
    myem(currentParams, seqTrainCut,'emMaxIters',emMaxIters, 'wbar', wbar, extra_opts{:});


  if (isempty(gpfa_params)) % the user interrupted dim reduction
      return;
  end
    
  if(nargout > 1)
    % Extract orthonormalized neural trajectories for original, unsegmented trials
    % using learned parameters

    [gpfa_traj, LL] = exactInferenceWithLL(D, gpfa_params,'getLL',1, 'wbar', wbar, extra_opts{:});

    
    % orthogonalize the trajectories
    [Xorth, Corth] = orthogonalize([gpfa_traj.xsm], gpfa_params.C);
    gpfa_traj = segmentByTrial(gpfa_traj, Xorth, 'data');
    gpfa_traj = rmfield(gpfa_traj, {'Vsm', 'VsmGP', 'xsm'});
    gpfa_params.Corth = Corth;
  end
  

end