function precomp = causalInferencePrecomp(params, Tmax, varargin)
%
% precomp = causalInferencePrecomp(params,...)
%
% Perform precomputations for causalInference.m.
%
% INPUT:
%
% params  - GPFA model parameters 
%  
% Tmax    - number of timesteps of the longest trial in dataset
%
% OUTPUT:
%
% precomp - data structure with fields
%              filt(t).M (xDim x xDim*t) -- filter to obtain posterior mean 
%                                           for x_t given y_1,...,y_t
%              CRinv                     -- precomputation of C' * inv(R)
%
% OPTIONAL ARGUMENT:
%
% Tstar   - number of timesteps of the longest filter to precompute
%           (default: Tmax)
%
% @ 2011 Byron Yu         byronyu@cmu.edu

  Tstar = Tmax;
  assignopts(who, varargin);
  
  [yDim, xDim] = size(params.C);

  if params.notes.RforceDiagonal     
    Rinv     = diag(1./diag(params.R));
  else
    Rinv     = inv(params.R);
    Rinv     = (Rinv+Rinv') / 2; % ensure symmetry
  end
  CRinv  = params.C' * Rinv;
  CRinvC = CRinv * params.C;
  
  for T = 1:Tstar
    [K_big, K_big_inv] = make_K_big(params, T);        
    K_big = sparse(K_big);

    blah        = cell(1, T);
    [blah{:}]   = deal(CRinvC);
    invM        = invPerSymm(K_big_inv + blkdiag(blah{:}), xDim,... 
			     'offDiagSparse', true);
    
    % Compute blkProd = CRinvC_big * invM efficiently
    % blkProd is block persymmetric, so just compute top half
    Thalf   = ceil(T/2);
    blkProd = zeros(xDim*Thalf, xDim*T);
    idx     = 1: xDim : (xDim*Thalf + 1);
    for t = 1:Thalf
      bIdx            = idx(t):idx(t+1)-1;
      blkProd(bIdx,:) = CRinvC * invM(bIdx,:);
    end
    % Compute just the first block row of blkProd
    blkProd = K_big(1:xDim, :) *... 
                fillPerSymm(speye(xDim*Thalf, xDim*T) - blkProd, xDim, T);

    % Last block row of blkProf is just block-reversal of first block row
    horzIdx = bsxfun(@plus, (1:xDim)', ((T-1):-1:0)*xDim);
    M       = blkProd(:, horzIdx(:));

    precomp.filt(T).M = M;
  end

  precomp.CRinv = CRinv;