function [n_best P_best V C]=fast_oopsi(F,V,P)
% this function solves the following optimization problem:
% (*) n_best = argmax_{n >= 0} P(n | F)
% which is a MAP estimate for the most likely spike train given the
% fluorescence signal.  given the model:
%
% <latex>
% \begin{align}
% C_t &= \gamma*C_{t-1} + n_t, \qquad & n_t & \sim \text{Poisson}(n_t; \lamda_t \Delta)
% F_t &= \alpha(C_t + \beta) + \sigma \varepsilon_t, &\varepsilon_t &\sim \mathcal{N}(0,1)
% \end{align}
% </latex>
%
% if F_t is a vector, then 'a' is a vector as well
% we approx the Poisson with an Exponential (which means we don't require integer numbers of spikes).
% we take an "interior-point" approach to impose the nonnegative contraint on (*).
% each step is solved in O(T)
% time by utilizing gaussian elimination on the tridiagonal hessian, as
% opposed to the O(T^3) time typically required for non-negative
% deconvolution.
%
% Input---- only F is REQUIRED.  the others are optional
% F:        fluorescence time series (can be a vector (1 x T) or a matrix (Np x T)
%
% V.        structure of algorithm Variables
%   Ncells: # of cells within ROI
%   T:      # of time steps
%   Npixels:# of pixels in ROI
%   dt:     time step size, ie, frame duration, ie, 1/(imaging rate)
%   n:      if true spike train is known, and we are plotting, plot it (only required is est_a==1)
%   h:      height of ROI (assumes square ROI) (# of pixels) (only required if est_a==1 and we are plotting)
%   w:      width of ROI (assumes square ROI) (# of pixels) (only required if est_a==1 and we are plotting)
%
%   THE FOLLOWING FIELDS CORRESPOND TO CHOICES THAT THE USER MAKE
%
%   fast_poiss:     1 if F_t ~ Poisson, 0 if F_t ~ Gaussian
%   fast_nonlin:    1 if F_t is a nonlinear f(C_t), and 0 if F_t is a linear f(C_t)
%   fast_plot:      1 to plot results after each pseudo-EM iteration, 0 otherwise
%   fast_thr:       1 if thresholding inferred spike train before estiamting {a,b}
%   fast_iter_max:  max # of iterations of pseudo-EM  (1 to use default initial parameters)
%   fast_ignore_post: 1 to keep iterating pseudo-EM even if posterior is not increasing, 0 otherwise
%
%   THE BELOW FIELDS INDICATE WHETHER ONE WANTS TO ESTIMATE EACH OF THE
%   PARAMETERS. IF ANY IS SET TO ZERO, THEN WE DO NOT TRY TO UPDATE THE
%   ORIGINAL ESTIMATE, GIVEN EITHER BY THE USER, OR THE INITIAL ESTIMATE
%   FROM THE CODE
%
%   est_sig:    1 to estimate sig
%   est_lam:    1 to estimate lam
%   est_gam:    1 to estimate gam
%   est_b:      1 to estimate b
%   est_a:      1 to estimate a
%
% P.        structure of neuron model Parameters
%
%   a:      spatial filter
%   b:      background fluorescence
%   sig:    standard deviation of observation noise
%   gam:    decayish, ie, tau=dt/(1-gam)
%   lam:    firing rate-ish, ie, expected # of spikes per frame
%
% Output---
% n_best:   inferred spike train
% P_best:   inferred parameter structure
% V:        structure of Variables for algorithm to run

%% initialize algorithm Variables
starttime   = cputime;
siz         = size(F);      if siz(2)==1, F=F'; siz=size(F); end
j=0;
% variables determined by the data
if nargin < 2,              V   = struct;       end
if ~isfield(V,'Ncells'),    V.Ncells = 1;       end     % # of cells in image
if ~isfield(V,'T'),         V.T = siz(2);       end     % # of time steps
if ~isfield(V,'Npixels'),   V.Npixels = siz(1); end     % # of pixels in ROI
if ~isfield(V,'dt'),                                    % frame duration
    fr = input('\nwhat was the frame rate for this movie (in Hz)?: ');
    V.dt = 1/fr;
end

% variables determined by the user
if ~isfield(V,'fast_poiss'),V.fast_poiss = 0;   end     % whether observations are Poisson
if ~isfield(V,'fast_nonlin'),   V.fast_nonlin   = 0; end
if V.fast_poiss && V.fast_nonlin,
    reply = input('\ncan be nonlinear observations and poisson, \ntype 1 for nonlin, 2 for poisson, anything else for neither: ');
    if reply==1,        V.fast_poiss = 0;   V.fast_nonlin = 1;
    elseif reply==2,    V.fast_poiss = 1;   V.fast_nonlin = 0;
    else                V.fast_poiss = 0;   V.fast_nonlin = 0;
    end
end
if ~isfield(V,'fast_iter_max'), V.fast_iter_max=1; end % max # of iterations before convergence

% things that matter if we are iterating to estimate parameters
if V.fast_iter_max>1;
    if V.fast_poiss || V.fast_nonlin,
        disp('\ncode does not currrently support estimating parameters for \npoisson or nonlinear observations');
        V.fast_iter_max=1;
    end
    
    if ~isfield(V,'fast_plot'), V.fast_plot = 0; end
    if V.fast_plot==1
        FigNum = 400;
        if V.Npixels>1, figure(FigNum), clf, end        % figure showing estimated spatial filter
        figure(FigNum+1), clf                           % figure showing estimated spike trains
        if isfield(V,'n'), siz=size(V.n); V.n(V.n==0)=NaN; if siz(1)<siz(2), V.n=V.n'; end; end
    end
    
    if ~isfield(V,'est_sig'),   V.est_sig   = 0; end    % whether to estimate sig
    if ~isfield(V,'est_lam'),   V.est_lam   = 0; end    % whether to estimate lam
    if ~isfield(V,'est_gam'),   V.est_gam   = 0; end    % whether to estimate gam
    if ~isfield(V,'est_a'),     V.est_a     = 0; end    % whether to estimate a
    if ~isfield(V,'est_b'),     V.est_b     = 1; end    % whether to estimate b
    if ~isfield(V,'fast_plot'), V.fast_plot = 1; end    % whether to plot results from each iteration
    if ~isfield(V,'fast_thr'),  V.fast_thr  = 0; end    % whether to threshold spike train before estimating 'a' and 'b'
    if ~isfield(V,'fast_ignore_post'), V.fast_ignore_post=0; end % whether to ignore the posterior, and just keep the last iteration
end

% normalize F if it is only a trace
if V.Npixels==1
    F=detrend(F);
    F=F-min(F)+eps;
end

%% set default model Parameters



if nargin < 3,          P       = struct;                       end
if ~isfield(P,'sig'),   P.sig   = mean(mad(F',1)*1.4826);       end
if ~isfield(P,'gam'),   P.gam   = (1-V.dt/1)*ones(V.Ncells,1);  end
if ~isfield(P,'lam'),   P.lam   = 10*ones(V.Ncells,1);          end
if ~isfield(P,'a'),     P.a     = median(F,2);                  end

if ~isfield(P,'b'),
    if V.Npixels==1, P.b = quantile(F,0.05);
    else P.b=median(F,2);
    end
end    
    
%% define some stuff needed for est_MAP function

% for brevity and expediency
Z   = zeros(V.Ncells*V.T,1);                    % zero vector
M   = spdiags([repmat(-P.gam,V.T,1) repmat(Z,1,V.Ncells-1) (1+Z)], -V.Ncells:0,V.Ncells*V.T,V.Ncells*V.T);  % matrix transforming calcium into spikes, ie n=M*C
I   = speye(V.Ncells*V.T);                      % create out here cuz it must be reused
H1  = I;                                        % initialize memory for Hessian matrix
H2  = I;                                        % initialize memory for other part of Hessian matrix
d0  = 1:V.Ncells*V.T+1:(V.Ncells*V.T)^2;        % index of diagonal elements of TxT matrices
d1  = 1+V.Ncells:V.Ncells*V.T+1:(V.Ncells*V.T)*(V.Ncells*(V.T-1)); % index of off-diagonal elements of TxT matrices
posts = Z(1:V.fast_iter_max);                   % initialize likelihood
if numel(P.lam)==V.Ncells
    lam = V.dt*repmat(P.lam,V.T,1);             % for lik
elseif numel(P.lam)==V.Ncells*V.T
    lam = V.dt*P.lam;
else
    error('lam must either be length V.T or 1');
end

if V.fast_poiss==1
    H       = I;                                % initialize memory for Hessian matrix
    gamlnF  = gammaln(F+1);                     % for lik
    sumF    = sum(F,1)';                        % for grad & Hess
end

%% if not iterating to estimate parameters, only this is necessary
[n C posts(1)] = est_MAP(F,P);
n_best = n;
P_best = P;
V.fast_iter_tot = 1;
V.post = posts(1);
post_max = posts(1);

if V.fast_iter_max>1
    options = optimset('Display','off');        % don't show warnings for parameter estimation
    i       = 1;                                % iteration #
    i_best  = i;                                % iteration with highest likelihood
    conv    = 0;                                % whether algorithm has converged yet
else
    conv    = 1;
end

%%  if parameters are unknown, do pseudo-EM iterations
while conv == 0
    if V.fast_plot == 1, MakePlot(n,F,P,V); end % plot results from previous iteration
    i               = i+1;                      % update iteratation number
    V.fast_iter_tot = i;                        % record of total # of iterations
    P               = est_params(n,C,F,P,b);    % update parameters based on previous iteration
    [n C posts(i)]  = est_MAP(F,P);             % update inferred spike train based on new parameters
    
    if posts(i)>post_max || V.fast_ignore_post==1% if this is the best one, keep n and P
        n_best  = n;                            % keep n
        P_best  = P;                            % keep P
        i_best  = i;                            % keep track of which was best
        post_max= posts(i);                     % keep max posterior
    end
    
    % if lik doesn't change much (relatively), or returns to some previous state, stop iterating
    if  i>=V.fast_iter_max || (abs((posts(i)-posts(i-1))/posts(i))<1e-3 || any(posts(1:i-1)-posts(i))<1e-5)% abs((posts(i)-posts(i-1))/posts(i))<1e-5 || posts(i-1)-posts(i)>1e5;
        MakePlot(n,F,P,V);
        disp('convergence criteria met')
        V.post  = posts(1:i);
        conv    = 1;
    end
    sound(3*sin(linspace(0,90*pi,2000)))        % play sound to indicate iteration is over
end

V.fast_time = cputime-starttime;                % time to run code
V           = orderfields(V);                   % order fields alphabetically to they are easier to read
P_best      = orderfields(P_best);
% n_best      = n_best./repmat(max(n_best),V.T,1);

P_best.j=j;

%% fast filter function
    function [n C post] = est_MAP(F,P)
        
        % initialize n and C
        z = 1;                                  % weight on barrier function
        llam = reshape(1./lam',1,V.Ncells*V.T)';
        if V.fast_nonlin==1
            n = V.gauss_n;
        else
            n = 0.01+0*llam;                    % initialize spike train
        end
        C = 0*n;                                % initialize calcium
        for j=1:V.Ncells
            C(j:V.Ncells:end) = filter(1,[1, -P.gam(j)],n(j:V.Ncells:end)); %(1-P.gam(j))*P.b(j);
        end
        
        % precompute parameters required for evaluating and maximizing likelihood
        b           = repmat(P.b,1,V.T);       % for lik
        if V.fast_poiss==1
            suma    = sum(P.a);                 % for grad
        else
            M(d1)   = -repmat(P.gam,V.T-1,1);   % matrix transforming calcium into spikes, ie n=M*C
            ba      = P.a'*b; ba=ba(:);         % for grad
            aa      = repmat(diag(P.a'*P.a),V.T,1);% for grad
            aF      = P.a'*F; aF=aF(:);         % for grad
            e       = 1/(2*P.sig^2);            % scale of variance
            H1(d0)  = -2*e*aa;                   % for Hess
        end
        grad_lnprior  = M'*llam;                  % for grad
        
        
        % find C = argmin_{C_z} lik + prior + barrier_z
        while z>1e-13                           % this is an arbitrary threshold
            
            if V.fast_poiss==1
                Fexpect = P.a*(C+b')';          % expected poisson observation rate
                lik = -sum(sum(-Fexpect+ F.*log(Fexpect) - gamlnF)); % lik
            else
                if V.fast_nonlin==1
                    S = C./(C+P.k_d);
                else
                    S = C;
                end
                D = F-P.a*(reshape(S,V.Ncells,V.T))-b; % difference vector to be used in likelihood computation
                lik = e*D(:)'*D(:);             % lik
            end
            post = lik + llam'*n - z*sum(log(n));
            s    = 1;                           % step size
            d    = 1;                           % direction
            while norm(d)>5e-2 && s > 1e-3      % converge for this z (again, these thresholds are arbitrary)
                if V.fast_poiss==1
                    glik    = suma - sumF./(C+b');
                    H1(d0)  = sumF.*(C+b').^(-2); % lik contribution to Hessian
                elseif V.fast_nonlin==1
                    glik    = -2*P.a*P.k_d*D'.*(C+P.k_d).^-2;
                    H1diag  = (-P.a*P.k_d-2*(C+P.k_d).*D').*((C+P.k_d).^-4);
                    H1(d0)  = H1diag;
                else
                    glik    = -2*e*(aF-aa.*C-ba);  % gradient
                end
                g       = glik + grad_lnprior - z*M'*(n.^-1);
                H2(d0)  = n.^-2;                % log barrier part of the Hessian
                H       = H1 - z*(M'*H2*M);     % Hessian
                d   = H\g;                     % direction to step using newton-raphson
                hit = -n./(M*d);                % step within constraint boundaries
                hit=hit(hit>0);
                if any(hit<1)
                    s = min(1,0.99*min(hit));
                else
                    s = 1;
                end
                post1 = post+1;
                while post1>=post+1e-7          % make sure newton step doesn't increase objective
                    C1  = C+s*d;
                    n   = M*C1;
                    if V.fast_poiss==1
                        Fexpect = P.a*(C1+b')';
                        lik1    = -sum(sum(-Fexpect+ F.*log(Fexpect) - gamlnF));
                    else
                        if V.fast_nonlin==1
                            S1 = C1./(C1+P.k_d);
                        else
                            S1 = C1;
                        end
                        D = F-P.a*(reshape(S1,V.Ncells,V.T))-b; % difference vector to be used in likelihood computation
                        lik1 = e*D(:)'*D(:);             % lik
                    end
                    post1 = lik1 + llam'*n - z*sum(log(n));
                    s   = s/5;                  % if step increases objective function, decrease step size

                    if s<1e-20; disp('reducing s further did not increase likelihood'), break; end      % if decreasing step size just doesn't do it
                end
                C    = C1;                      % update C
                post = post1;                   % update post
            end
            z=z/10;                             % reduce z (sequence of z reductions is arbitrary)
        end
        
        % reshape things in the case of multiple neurons within the ROI
        n=reshape(n,V.Ncells,V.T)';
        C=reshape(C,V.Ncells,V.T)';
    end

%% Parameter Update
    function P = est_params(n,C,F,P,b)
        
        % generate regressor for spatial filter
        if V.est_a==1 || V.est_b==1
            if V.fast_thr==1
                CC=0*C;
                for j=1:V.Ncells
                    nsort   = sort(n(:,j));
                    nthr    = nsort(round(0.98*V.T));
                    nn      = Z(1:V.T);
                    nn(n(:,j)<=nthr)=0;
                    nn(n(:,j)>nthr)=1;
                    CC(:,j) = filter(1,[1 -P.gam(j)],nn) + (1-P.gam(j))*P.b(j);
                end
            else
                CC      = C;
            end
            
            if V.est_b==1
                A = [CC -1+Z(1:V.T)];
            else
                A=CC;
            end
            X = A\F';
            
            P.a = X(1:V.Ncells,:)';
            if V.est_b==1
                P.b = X(end,:)';
                b   = repmat(P.b,1,V.T);
            end
            
            D   = F-P.a*(reshape(C,V.Ncells,V.T)) - b;
            
            mse = D(:)'*D(:);
        end
        
        if V.est_a==0 && V.est_b==0 && (V.est_sig==1 || V.est_lam==1),
            D   = F-P.a*(reshape(C,V.Ncells,V.T)+b);
            mse = D(:)'*D(:);
        end
        
        % estimate other parameters
        if V.est_sig==1,
            P.sig = sqrt(mse)/V.T;
        end
        if V.est_lam==1,
            nnorm   = n./repmat(max(n),V.T,1);
            if numel(P.lam)==V.Ncells
                P.lam   = sum(nnorm)'/(V.T*V.dt);
                lam     = repmat(P.lam,V.T,1)*V.dt;
            else
                P.lam   = nnorm/(V.T*V.dt);
                lam     = P.lam*V.dt;
            end
            
        end
    end

%% MakePlot
    function MakePlot(n,F,P,V)
        if V.fast_plot == 1
            if V.Npixels>1                                     % plot spatial filter
                figure(FigNum), nrows=V.Ncells;
                for j=1:V.Ncells, subplot(1,nrows,j),
                    imagesc(reshape(P.a(:,j),V.w,V.h)),
                    title('a')
                end
            end
            
            figure(FigNum+1),  ncols=V.Ncells; nrows=3; END=V.T; h=zeros(V.Ncells,2);
            for j=1:V.Ncells                                  % plot inferred spike train
                h(j,1)=subplot(nrows,ncols,(j-1)*ncols+1); cla
                if V.Npixels>1, Ftemp=mean(F); else Ftemp=F; end
                plot(z1(Ftemp(2:END))+1), hold on,
                bar(z1(n_best(2:END,j)))
                title(['best iteration ' num2str(i_best)]),
                axis('tight')
                set(gca,'XTickLabel',[],'YTickLabel',[])
                
                h(j,2)=subplot(nrows,ncols,(j-1)*ncols+2); cla
                bar(z1(n(2:END,j)))
                if isfield(V,'n'), hold on,
                    for k=1:V.Ncells
                        stem(V.n(2:END,k)+k/10,'LineStyle','none','Marker','v','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',2)
                    end
                end
                set(gca,'XTickLabel',[],'YTickLabel',[])
                title(['current iteration ' num2str(i)]),
                axis('tight')
            end
            
            subplot(nrows,ncols,j*nrows),
            plot(1:i,posts(1:i))    % plot record of likelihoods
            title(['max lik ' num2str(post_max,4), ',   lik ' num2str(posts(i),4)])
            set(gca,'XTick',2:i,'XTickLabel',2:i)
            drawnow
        end
    end
end