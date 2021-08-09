function [M P V] = smc_oopsi(F,V,P)
% this function runs the SMC-EM on a fluorescence time-series, and outputs the inferred
% distributions and parameter estimates
%
% Inputs
% F: fluorescence time series
% V: structure of stuff necessary to run smc-em code
% P: structure of initial parameter estimates
%
% Outputs
% M: structure containing mean, variance, and percentiles of inferred distributions
% P: structure containing the final parameter estimates
% V: structure Variables for algorithm to run

if nargin < 2,          V       = struct;       end
if ~isfield(V,'T'),     V.T     = length(F);    end     % # of observations
if ~isfield(V,'freq'),  V.freq  = 1;            end     % # time steps between observations
if ~isfield(V,'T_o'),   V.T_o   = V.T;          end     % # of observations
if ~isfield(V,'x'),     V.x     = ones(1,V.T);  end     % stimulus
if ~isfield(V,'scan'),  V.scan  = 0;            end     % epi or scan
if ~isfield(V,'name'),  V.name  ='oopsi';       end     % name for output and figure
if ~isfield(V,'Nparticles'),	V.Nparticles    = 99; 	end % # particles
if ~isfield(V,'Nspikehist'),    V.Nspikehist	= 0; 	end % # of spike history terms
if ~isfield(V,'condsamp'),    	V.condsamp 		= 1;    end % whether to use conditional sampler
if ~isfield(V,'ignorelik'),  	V.ignorelik		= 1; 	end % epi or scan
if ~isfield(V,'true_n'),                        % if true spikes are not available
    V.use_true_n = 0;                           % don't use them for anything
else
    V.use_true_n = 1;
end
if ~isfield(V,'smc_iter_max'),                          % max # of iterations before convergence
    reply = str2double(input('\nhow many EM iterations would you like to perform \nto estimate parameters (0 means use default parameters): ', 's'));
    V.smc_iter_max = reply;
end
if ~isfield(V,'dt'),
    fr = input('what was the frame rate for this movie (in Hz)? ');
    V.dt = 1/fr;
end

% set which parameters to estimate
if ~isfield(V,'est_c'),     V.est_c     = 1;    end     % tau_c, A, C_0
if ~isfield(V,'est_t'),     V.est_t     = 1;    end     % tau_c (useful when data is poor)
if ~isfield(V,'est_n'),     V.est_n     = 1;    end     % b,k
if ~isfield(V,'est_h'),     V.est_h     = 0;    end     % w
if ~isfield(V,'est_F'),     V.est_F     = 1;    end     % alpha, beta
if ~isfield(V,'smc_plot'),  V.smc_plot  = 1;    end     % plot results with each iteration

%% initialize model Parameters

if nargin < 3,          P       = struct;       end
if ~isfield(P,'tau_c'), P.tau_c = 1;            end     % calcium decay time constant (sec)
if ~isfield(P,'A'),     P.A     = 50;           end     % change ins [Ca++] after a spike (\mu M)
if ~isfield(P,'C_0'),   P.C_0   = 0;            end     % baseline [Ca++] (\mu M)
if ~isfield(P,'C_init'),P.C_init= 0;            end     % initial [Ca++] (\mu M)
if ~isfield(P,'sigma_c'),P.sigma_c= 0.1;        end     % standard deviation of noise (\mu M)
if ~isfield(P,'n'),     P.n     = 1;            end     % hill equation exponent
if ~isfield(P,'k_d'),   P.k_d   = 200;          end     % hill coefficient
if ~isfield(P,'k'),                                     % linear filter
    k   = str2double(input('approx. how many spikes underly this trace: ', 's'));
    P.k = log(-log(1-k/V.T)/V.dt);
end
if ~isfield(P,'alpha'), P.alpha = mean(F);      end     % scale of F
if ~isfield(P,'beta'),  P.beta  = min(F);       end     % offset of F
if ~isfield(P,'zeta'),  P.zeta  = P.alpha/5;    end     % constant variance
if ~isfield(P,'gamma'), P.gamma = P.zeta/5;     end     % scaled variance
if V.Nspikehist==1                                               % if there are spike history terms
    if ~isfield(P,'omega'),     P.omega     = -1;   end     % weight
    if ~isfield(P,'tau_h'),     P.tau_h     = 0.02; end     % time constant
    if ~isfield(P,'sigma_h'),   P.sigma_h   = 0;    end     % stan dev of noise
    if ~isfield(P,'g'),         P.g         = V.dt/P.tau_h; end     % for brevity
    if ~isfield(P,'sig2_h'),    P.sig2_h    = P.sigma_h^2*V.dt; end % for brevity
end
if ~isfield(P,'a'),     P.a     = V.dt/P.tau_c; end     % for brevity
if ~isfield(P,'sig2_c'),P.sig2_c= P.sigma_c^2*V.dt; end % for brevity

%% initialize other stuff
starttime   = cputime;
P.lik       = -inf;                                     % we are trying to maximize the likelihood here
F           = max(F,eps);                               % in case there are any zeros in the F time series

S = smc_oopsi_forward(F,V,P);                           % forward step
M = smc_oopsi_backward(S,V,P);                          % backward step
if V.smc_iter_max>1, P.conv=false; else P.conv=true; end

while P.conv==false;
    P = smc_oopsi_m_step(V,S,M,P,F);                    % m step
    S = smc_oopsi_forward(F,V,P);                       % forward step
    M = smc_oopsi_backward(S,V,P);                      % backward step
end
fprintf('\n')

V.smc_iter_tot  = length(P.lik);
V.smc_time      = cputime-starttime;
V               = orderfields(V);