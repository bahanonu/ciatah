function M = smc_oopsi_backward(S,V,P)
% this function iterates backward one step computing P[H_t | H_{t+1},O_{0:T}]
% Input---
% Sim:  simulation metadata
% S:    particle positions and weights
% P:    parameters
% Z:    a bunch of stuff initialized for speed
% t:    current time step
%
% Output is a single structure Z with the following fields
% n1:   vector of spikes or no spike for each particle at time t
% C0:   calcium positions at t-1
% C1:   calcium positions at t (technically, this need not be output)
% C1mat:matrix from C1
% C0mat:matrix from C0
% w_b:  backwards weights


fprintf('\nbackward step:       ')
Z.oney  = ones(V.Nparticles,1);                 % initialize stuff for speed
Z.zeroy = zeros(V.Nparticles);
Z.C0    = S.C(:,V.T);
Z.C0mat = Z.C0(:,Z.oney)';

if V.est_c==false                               % if not maximizing the calcium parameters, then the backward step is simple
    if V.use_true_n                             % when spike train is provided, backwards is not necessary
        S.w_b=S.w_f;
    else
        for t=V.T-V.freq-1:-1:V.freq+1          % actually recurse backwards for each time step
            Z = step_backward(V,S,P,Z,t);
            S.w_b(:,t-1) = Z.w_b;               % update forward-backward weights
        end
    end
else                                            % if maximizing calcium parameters,
    % need to compute some sufficient statistics
    M.Q = zeros(3);                             % the quadratic term for the calcium par
    M.L = zeros(3,1);                           % the linear term for the calcium par
    M.J = 0;                                    % remaining terms for calcium par
    M.K = 0;
    for t=V.T-V.freq-1:-1:V.freq+1
        if V.use_true_n                         % force true spikes hack
            Z.C0    = S.C(t-1);
            Z.C0mat = Z.C0;
            Z.C1    = S.C(t);
            Z.C1mat = Z.C1;
            Z.PHH   = 1;
            Z.w_b   = 1;
            Z.n1    = S.n(t);
        else
            Z = step_backward(V,S,P,Z,t);
        end
        S.w_b(:,t-1) = Z.w_b;

        % below is code to quickly get sufficient statistics
        C0dt    = Z.C0*V.dt;
        bmat    = Z.C1mat-Z.C0mat';
        bPHH    = Z.PHH.*bmat;

        M.Q(1,1)= M.Q(1,1) + sum(Z.PHH*(C0dt.^2));  % Q-term in QP
        M.Q(1,2)= M.Q(1,2) - Z.n1'*Z.PHH*C0dt;
        M.Q(1,3)= M.Q(1,3) + sum(sum(-Z.PHH.*Z.C0mat'*V.dt^2));
        M.Q(2,2)= M.Q(2,2) + sum(Z.PHH'*(Z.n1.^2));
        M.Q(2,3)= M.Q(2,3) + sum(sum(Z.PHH(:).*repmat(Z.n1,V.Nparticles,1))*V.dt);
        M.Q(3,3)= M.Q(3,3) + sum(Z.PHH(:))*V.dt^2;

        M.L(1)  = M.L(1) + sum(bPHH*C0dt);          % L-term in QP
        M.L(2)  = M.L(2) - sum(bPHH'*Z.n1);
        M.L(3)  = M.L(3) - V.dt*sum(bPHH(:));

        M.J     = M.J + sum(Z.PHH(:));              % J-term in QP /sum J^(i,j)_{t,t-1}/

        M.K     = M.K + sum(Z.PHH(:).*bmat(:).^2);  % K-term in QP /sum J^(i,j)_{t,t-1} (d^(i,j)_t)^2/
    end
    M.Q(2,1) = M.Q(1,2);                            % symmetrize Q
    M.Q(3,1) = M.Q(1,3);
    M.Q(3,2) = M.Q(2,3);
end
fprintf('\n')

% copy particle swarm for later
M.w = S.w_b;
M.n = S.n;
M.C = S.C;
if isfield(S,'h'), M.h=S.h; end

% check failure mode caused by too high P.A (low P.sigma_c)
% fact=1.55;
% if(sum(S.n(:))==0 && cnt<10)                % means no spikes anywhere
%     fprintf(['Failed to find any spikes, likely too high a P.A.\n',...
%         'Attempting to lower by factor %g...\n'],fact);
%     P.A=P.A/fact;
%     P.C_0=P.C_0/fact;
%     P.sigma_c=P.sigma_c/fact;
%     cnt=cnt+1;
% elseif(cnt>=10)
%     M_best=M;
%     E_best=P;
%     fprintf('Warning: there are no spikes in the data. Wrong initialization?');
%     return;
% end
M.nbar = sum(S.w_b.*S.n,1);

end

function Z = step_backward(V,S,P,Z,t)

% compute ln P[n_t^i | h_t^i]
Z.n1            = S.n(:,t);                         % for prettiness sake
ln_Pn           = 0*Z.oney;                         % for fastiness sake
ln_Pn(Z.n1==1)  = log(S.p(Z.n1==1,t));              % P[n=1] for those that spiked
ln_Pn(~Z.n1)    = log(1-S.p(~Z.n1,t));              % P[n=0] for those that did not

% compute ln P[C_t^i | C_{t-1}^j, n_t^i]
Z.C0        = S.C(:,t-1);                           % for prettiness sake
Z.C1        = S.C(:,t);
Z.C1mat     = Z.C1(:,Z.oney);                       % recall from previous time step
Z.C0mat     = Z.C0(:,Z.oney);                       % faster than repamt
mu          = (1-P.a)*S.C(:,t-1)+P.A*Z.n1+P.a*P.C_0;% mean
mumat       = mu(:,Z.oney)';                        % faster than repmat
ln_PC_Cn    = -0.5*(Z.C1mat - mumat).^2/P.sig2_c;   % P[C_t^i | C_{t-1}^j, n_t^i]

% compute ln P[h_t^i | h_{t-1}^j, n_{t-1}^i]
ln_Ph_hn    = Z.zeroy;                              % reset transition prob for h terms
for m=1:V.Nspikehist                                % for each h term
    h1      = S.h(:,t,m);                           % faster than repmat
    h1      = h1(:,Z.oney);
    h0      = P.g(m)*S.h(:,t-1,m)+S.n(:,t-1);
    h0      = h0(:,Z.oney)';
    ln_Ph_hn = ln_Ph_hn - 0.5*(h0 - h1).^2/P.sig2_h(m);
end

% compute P[H_t^i | H_{t-1}^j]
sum_lns = ln_Pn(:,Z.oney)+ln_PC_Cn + ln_Ph_hn;      % in order to ensure this product doesn't have numerical errors
mx      = max(sum_lns,[],1);                        % find max in each of row
mx      = mx(Z.oney,:);                             % make a matrix of maxes
T0      = exp(sum_lns-mx);                          % exponentiate subtracting maxes (so that in each row, the max entry is exp(0)=1
Tn      = sum(T0,1);                                % then normalize
T       = T0.*repmat(1./Tn(:)', V.Nparticles, 1);   % such that each column sums to 1

% compute P[H_t^i, H_{t-1}^j | O]
PHHn    = (T*S.w_f(:,t-1))';                        % denominator
PHHn(PHHn==0) = eps;
PHHn2   = PHHn(Z.oney,:)';                          % faster than repmat
PHH     = T .* (S.w_b(:,t)*S.w_f(:,t-1)')./PHHn2;   % normalize such that sum(PHH)=1
sumPHH  = sum(PHH(:));
if sumPHH==0
    Z.PHH = ones(V.Nparticles)/(V.Nparticles);
else
    Z.PHH   =  PHH/sum(PHH(:));
end
Z.w_b   = sum(Z.PHH,1);                             % marginalize to get P[H_t^i | O]

if any(isnan(Z.w_b))
    return
end

if mod(t,100)==0 && t>=9900
    fprintf('\b\b\b\b\b%d',t)
elseif mod(t,100)==0 && t>=900
    fprintf('\b\b\b\b%d',t)
elseif mod(t,100)==0
    fprintf('\b\b\b%d',t)
end

end