function seq = causalInference(seq, params, varargin)
%
% seq = causalInference(seq, params,...)
%
% Extracts latent trajectories using only *current and past* neural
% activity given GPFA model parameters.
%
% INPUTS:
%
% seq         - data structure, whose nth entry (corresponding to the nth 
%               experimental trial) has fields
%                 y (yDim x T) -- neural data
%                 T (1 x 1)    -- number of timesteps
% params      - GPFA model parameters 
%  
% OUTPUT:
%
% seq         - data structure with new field
%                 xfi (xDim x T) -- posterior mean at each timepoint
%                                   E[x_t | y_1,...,y_t]
%
% @ 2011 Byron Yu         byronyu@cmu.edu
%
% Note: To minimize compute time, this function does not compute the
% posterior covariance of the neural trajectories.  If the posterior
% covariance is desired, call exactInferenceWithLL.m.

  extraOpts = assignopts(who, varargin);

  % This function does most of the heavy lifting
  Tmax    = max([seq.T]);
  precomp = causalInferencePrecomp(params, Tmax, extraOpts{:});

  [yDim, xDim] = size(params.C);
  Tstar        = length(precomp.filt);

  % GPFA makes the approximation that x_t does not depend on y_{t-s}
  % for s >= Tstar.
  fprintf('Tstar = %d, Tmax = %d\n', Tstar, Tmax);
  fprintf('GPFA is making an approximation if Tstar < Tmax.\n'); 
  
  for n = 1:length(seq)
    T   = seq(n).T;
    xfi = nan(xDim, T);
    
    dif   = bsxfun(@minus, seq(n).y, params.d); % yDim x T
    term1 = reshape(precomp.CRinv * dif, xDim*T, 1); 
    
    for t = 1:min(T, Tstar)
      xfi(:,t) = precomp.filt(t).M * term1(1:xDim*t);
    end
    
    if T > Tstar
      for t = Tstar+1:T
	idx = (xDim*(t-Tstar)+1) : xDim*t; 
	xfi(:,t) = precomp.filt(end).M * term1(idx);    
      end
    end
    
    seq(n).xfi = xfi;
  end
  