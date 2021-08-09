function P = smc_oopsi_m_step(V,S,M,P,F)
% this function finds the mle of the parameters
%
% Input---
% V:  simulation parameters
% R:    real data
% S:    simulation results
% M:    moments and sufficient stats
% P:    old parameter estimates
%
% Output is 'Enew', a structure with a field for each parameter, plus some
% additional fields for various likelihoods

Eold= P;                           % store most recent parameter structure
P   = update_params(V,S,M,P,F); % update parameters
i   = length(P.lik);
fprintf('\n\nIteration #%g, lik=%g, dlik=%g\n',i,P.lik(end),P.lik(end)-Eold.lik(end))

% when estimating calcium parameters, display param estimates and lik
if V.est_c==1
    dtheta  = norm([P.tau_c; P.A; P.C_0]-...
        [Eold.tau_c; Eold.A; Eold.C_0])/norm([Eold.tau_c; Eold.A; Eold.C_0; P.sigma_c]);
    fprintf('\ndtheta = %.2f',dtheta);
    fprintf('\ntau    = %.2f',P.tau_c)
    fprintf('\nA      = %.2f',P.A)
    fprintf('\nC_0    = %.2f',P.C_0)
    fprintf('\nsig    = %.2f',P.sigma_c)
    fprintf('\nalpha  = %.2f',P.alpha)
    fprintf('\nbeta   = %.2f',P.beta)
    fprintf('\ngamma  = %.2g\n',P.gamma)
end
if V.est_n == true
    fprintf('\nk      = %.2f\n',P.k)
end

% plot lik and inferrence
if V.smc_plot
    figure(100)
    subplot(4,1,1), hold off, plot(P.lik,'o'), axis('tight')
    subplot(4,1,2), plot(F,'k'), hold on,
    plot(P.alpha*Hill_v1(P,sum(S.w_b.*S.C,1))+P.beta,'b'), hold off, axis('tight')

    % plot spike train estimate
    subplot(4,1,3), cla, hold on,
    if isfield(V,'n'),
        stem(V.n,'Marker','.','MarkerSize',20,'LineWidth',2,...
            'Color',[.75 .75 .75],'MarkerFaceColor','k','MarkerEdgeColor','k');
        axis('tight'),
    end
    stem(M.nbar,'Marker','none','LineWidth',2,'Color',[0 .5 0])
    ylabel('current n')
    axis([0 V.T 0 1]),

    % plot "best" spike train estimate
    subplot(4,1,4), cla,hold on,
    if isfield(V,'n'), stem(V.n,'Marker','.',...
            'MarkerSize',20,'LineWidth',2,'Color',[.75 .75 .75]); end
    stem(M.nbar,'Marker','none','LineWidth',2,'Color',[0 .5 0])
    ylabel('best n')
    axis([0 V.T 0 1]),


    drawnow
end

if i>=V.smc_iter_max
    P.conv=true;
end



    function Enew = update_params(V,S,M,E,F)
        Enew = E;   % initialize parameters
        lik = [];   % initialize likelihood

        optionsQP   = optimset('Display','off');
        optionsGLM  = optimset('Display','off','GradObj','off','TolFun',1e-6);

        %% MLE for spiking parameters
        if V.est_n == true
            % MLE for spike rate parameters: baseline (b), linear filter (k), and spike history weights (omega)
            fprintf('\nestimating spike rate params\n')
            RateParams=E.k;                                     % vector of parameters to estimate (changes depending on user input of which parameters to estimate)
            sp      = S.n==1;                                   % find (particles,time step) pairs that spike
            nosp    = S.n==0;                                   % don't spike
%             x       = repmat(V.x,1,V.Nparticles);                        % generate matrix for gradinent
            zeroy   = zeros(V.Nparticles,V.T);                           % make matrix of zeros for evaluating lik

            if V.est_h == true
                if V.Nspikehist>0                                        % if spike history terms are present
                    RateParams=[RateParams; E.omega];           % also estimate omega
%                     for i=1:V.Nspikehist                                 % and modify stimulus matrix for gradient
%                         x(V.StimDim+i,:)=reshape(S.h(:,:,i),1,V.Nparticles*V.T);
%                     end
                end

                %[bko lik_r] = fminunc(@f_bko,RateParams,optionsGLM);% find MLE
                Z=ones(size(RateParams));
                [bko lik_r]=fmincon(@f_bko,RateParams,[],[],[],[],-10*Z,10*Z,[],optionsGLM);%fix for h-problem
                Enew.k      = bko(1:end-V.Nspikehist);                   % set new parameter estimes
                if V.Nspikehist>0, Enew.omega = bko(end-V.Nspikehist+1:end); end  % for omega too
            else
                if V.Nspikehist>0                                        % if spike history terms are present
                    for i=1:V.Nspikehist                                 % and modify stimulus matrix for gradient
                        x(V.StimDim+i,:)=reshape(S.h(:,:,i),1,V.Nparticles*V.T);
                    end
                end

                [bk lik_r]  = fminunc(@f_bk,RateParams,optionsGLM); % find MLE
                Enew.k      = bk(1:end);                        % set new parameter estimes
            end
            Enew.lik_r   = -lik_r;
            lik = [lik Enew.lik_r];
        end

        function [lik dlik]= f_bko(RateParams)                  % get lik and grad

            xk      = RateParams(1:end-V.Nspikehist)'*V.x;               % filtered stimulus
            hs      = zeroy;                                    % incorporate spike history terms
            for l=1:V.Nspikehist, hs  = hs+RateParams(end-V.Nspikehist+l)*S.h(:,:,l); end
            s       = repmat(xk,V.Nparticles,1) + hs;

            f_kdt   = exp(s)*V.dt;                              % shorthand
            ef      = exp(f_kdt);                               % shorthand
            lik     = -sum(S.w_b(sp).*log(1-1./ef(sp)))...      % liklihood
                +sum(S.w_b(nosp).*f_kdt(nosp));

            if nargout > 1                                      % if gradobj=on
                dlik      = -x(:,sp)*(S.w_b(sp).*f_kdt(sp)./(ef(sp)-1))... %gradient of lik
                    + x(:,nosp)*(S.w_b(nosp).*f_kdt(nosp));
            end
        end %function f_bko

        function [lik dlik]= f_bk(RateParams)                   % get lik and grad

            xk      = RateParams'*V.x;                          % filtered stimulus
            hs      = zeroy;                                    % incorporate spike history terms
            for l=1:V.Nspikehist, hs  = hs+E.omega*S.h(:,:,l); end
            s       = repmat(xk,V.Nparticles,1) + hs;

            f_kdt   = exp(s)*V.dt;                              % shorthand
            ef      = exp(f_kdt);                               % shorthand
            lik     = -sum(S.w_b(sp).*log(1-1./ef(sp)))...      % liklihood
                +sum(S.w_b(nosp).*f_kdt(nosp));

            if nargout > 1                                      % if gradobj=on
                dlik      = -x(:,sp)*(S.w_b(sp).*f_kdt(sp)./( ef(sp)-1))... % gradient of lik
                    + x(:,nosp)*(S.w_b(nosp).*f_kdt(nosp));
            end
        end %function f_bko

        %% MLE for calcium parameters
        if V.est_c == true
            fprintf('estimating calcium parammeters\n')
            if V.est_t == 0
                [ve_x fval] = quadprog(M.Q(2:3,2:3), M.L(2:3),[],[],[],[],[0 0],[inf inf],[E.A E.C_0/E.tau_c]+eps,optionsQP);
                Enew.tau_c  = E.tau_c;
                Enew.A      = ve_x(1);
                Enew.C_0    = ve_x(2)/E.tau_c;
            else
                [ve_x fval] = quadprog(M.Q, M.L,[],[],[],[],[0 0 0],[inf inf inf],[1/E.tau_c E.A E.C_0/E.tau_c]+eps,optionsQP);
                Enew.tau_c  = 1/ve_x(1);
                Enew.A      = ve_x(2);
                Enew.C_0    = ve_x(3)/ve_x(1);
            end
            fval        = M.K/2 + fval;                         % variance
            Enew.sigma_c= sqrt(fval/(M.J*V.dt));                % factor in dt
            Enew.lik_c  = - fval/(Enew.sigma_c*sqrt(V.dt)) - M.J*log(Enew.sigma_c);
            lik = [lik Enew.lik_c];
            
            Enew.a         = V.dt/E.tau_c;                      % for brevity
            Enew.sig2_c    = E.sigma_c^2*V.dt;                  % for brevity
        end

        % % %% MLE for spike history parameters
        % % for m=1:V.Nspikehist
        % %     Enew.sigma_h(m)= sum(M.v{m})/V.T;
        % % end

        %% MLE for observation parameters

        if V.est_F == true
            fprintf('estimating observation parammeters\n')
            ab_0            = [E.alpha E.beta];
            [Enew.lik_o ab] = f1_ab(ab_0);
            Enew.alpha = ab(1);
            Enew.beta  = ab(2);
            Enew.zeta=E.zeta*ab(3);
            Enew.gamma = E.gamma*ab(3);
            lik = [lik Enew.lik_o];
        end

        function [lik x] = f1_ab(ab_o)
            %find MLE for {alpha, beta and gamma/zeta}
            %THIS EXPLICITLY ASSUMES WEIGHTS w_b ARE SUM=1 NORMALIZED (!)
            pfS=Hill_v1(E,S.C);
            pfV=E.gamma*pfS+E.zeta;
            % minimize quadratic form of E[(F - ab(1)*pfS - ab(2))^2/pfV]
            % taken as weighted average over all particles (Fmean)
            f1_abn=sum(sum(S.w_b,2));       % normalization

            f1_abH(1,1) = sum(sum(pfS.^2./pfV.*S.w_b,2));% QF
            f1_abH(2,2) = sum(sum(S.w_b./pfV,2));
            f1_abH(1,2) = sum(sum(pfS./pfV.*S.w_b,2));
            f1_abH(2,1) = f1_abH(1,2);

            f1_abf=[0;0]; f1_abc=0;         % LF and offset
            for i=1:size(pfS,1)             % over particles
                f1_abf(1) = f1_abf(1) - sum(F(:)'.*pfS(i,:)./pfV(i,:).*S.w_b(i,:));
                f1_abf(2) = f1_abf(2) - sum(F(:)'./pfV(i,:).*S.w_b(i,:));

                f1_abc = f1_abc + sum(F(:)'.^2./pfV(i,:).*S.w_b(i,:));
            end

            % solve QP given ab(1)>0, no bound on ab(2)
            [x lik] = quadprog(f1_abH,f1_abf,[],[],[],[],[0 -inf],[inf inf],[],optionsQP);

            lik=(lik+f1_abc/2);             % variance
            x(3)=lik/f1_abn;                % estimate gamma_new/gamma

            lik=-lik-sum(sum(log(x(3)*pfV).*S.w_b,2))/2;
        end %function f_ab

        Enew.lik=[E.lik sum(lik)];

    end

end