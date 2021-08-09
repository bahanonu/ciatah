function varargout = run_oopsi(F,V,P)
% this function runs our various oopsi filters, saves the results, and
% plots the inferred spike trains.  make sure that fast-oopsi and
% smc-oopsi repository are in your path if you intend to use them.
%
% to use the code, simply provide F, a vector of fluorescence observations,
% for each cell.  the fast-oopsi code can handle a matrix input,
% corresponding to a set of pixels, for each time bin. smc-oopsi expects a
% 1D fluorescence trace.
%
% see documentation for fast-oopsi and smc-oopsi to determine how to set
% variables
%
% input
%   F: fluorescence from a single neuron
%   V: Variables necessary to define for code to function properly (optional)
%   P: Parameters of the model (optional)
%
% possible outputs
%   fast:   fast-oopsi MAP estimate of spike train, argmax_{n\geq 0} P[n|F], (fast.n),  parameter estimate (fast.P), and structure of  variables for algorithm (fast.V)
%   smc:    smc-oopsi estimate of {P[X_t|F]}_{t<T}, where X={n,C} or {n,C,h}, (smc.E), parameter estimates (smc.P), and structure of variables for algorithm (fast.V)

%% set code Variables

if nargin < 2, V = struct;   end         % create structure for algorithmic variables, if none provided
if ~isfield(V,'fast_iter_max')
    V.fast_iter_max = input('\nhow many iterations of fast-oopsi would you like to do [0,1,2,...]: ');
end
if ~isfield(V,'smc_iter_max')
    V.smc_iter_max = input('\how many iterations of smc-oopsi would you like to do [0,1,2,...]: ');
end

if ~isfield(V,'dt'),                                    % frame duration
    fr = input('\nwhat was the frame rate for this movie (in Hz)?: ');
    V.dt = 1/fr;
end

if ~isfield(V,'preprocess'),
    V.preprocess = input('\ndo you want to high-pass filter [0=no, 1=yes]?: ');
end

if ~isfield(V,'n_max'),     V.n_max     = 2;        end
if nargin < 3,              P           = struct;   end         % create structure for parameters, if none provided
if ~isfield(V,'plot'),      V.plot      = 1;        end         % whether to plot the fluorescence and spike trains
if ~isfield(V,'name'),                                          % give data a unique, time-stamped name, if there is not one specified
    lic     = str2num(license);                                 % jovo's license #
    if lic == 273165,                                           % if using jovo's computer, set data and fig folders
        fdat = '~/Research/oopsi/meta-oopsi/data/jovo';
        ffig = '~/Research/oopsi/meta-oopsi/figs/jovo';
    else                                                        % else just use current dir
        fdat = pwd;
        ffig = pwd;
    end
    V.name  = ['/oopsi_' datestr(clock,30)];
else
    fdat = pwd;
    ffig = pwd;
end

if ~isfield(V,'save'),      V.save      = 0;        end         % whether to save results and figs
if V.save == 1
    if isfield(V,'dat_dir'), fdat=V.dat_dir; end
    V.name_dat = [fdat V.name];                                 % filename for data
    save(V.name_dat,'V')
end

%% preprocess - remove the lowest 10 frequencies

if V.preprocess==1
    V.T     = length(F);
    f       = detrend(F);
    nfft    = 2^nextpow2(V.T);
    y       = fft(f,nfft);
    bw      = 3;
    y(1:bw) = 0; y(end-bw+1:end)=0;
    iy      = ifft(y,nfft);
    F       = z1(real(iy(1:V.T)));
end

%% infer spikes and estimate parameters

% infer spikes using fast-oopsi
if V.fast_iter_max > 0
    fprintf('\nfast-oopsi\n')
    [fast.n fast.P fast.V]= fast_oopsi(F,V,P);
    if V.save, save(V.name_dat,'fast','-append'); end
end

stupid=1;
% infer spikes using smc-oopsi
if V.smc_iter_max > 0
    fprintf('\nsmc-oopsi\n')
    siz=size(F); if siz(1)>1, F=F'; end
    if V.fast_iter_max > 0;
        if ~isfield(P,'A'),     P.A     = 50;   end             % initialize jump in [Ca++] after spike
        if ~isfield(P,'n'),     P.n     = 1;    end             % Hill coefficient
        if ~isfield(P,'k_d'),   P.k_d   = 200;  end             % dissociation constant
        if ~isfield(V,'T'),     V.T     = fast.V.T; end         % number of time steps
        if ~isfield(V,'dt'),    V.dt    = fast.V.dt; end        % frame duration, aka, 1/(framte rate)

        if ~exist('stupid')
            bign1=find(fast.n>0.1);
            bign0=bign1-1;
            df=max((F(bign1)-F(bign0))./(F(bign0)));

            P.C_init= P.C_0;
            S0      = Hill_v1(P,P.C_0);
            arg     = S0 + df*(S0 + 1/13);
            P.A     = ((arg*P.k_d)./(1-arg)).^(1/P.n)-P.C_0;
        end
        P.C_0   = 0;
        P.tau_c = fast.V.dt/(1-fast.P.gam);                     % time constant
        nnorm   = V.n_max*fast.n/max(fast.n);                           % normalize inferred spike train
        C       = filter(1,[1 -fast.P.gam],P.A*nnorm)'+P.C_0;         % calcium concentration
        C1      = [Hill_v1(P,C); ones(1,V.T)];                  % for brevity
        ab      = C1'\F';                                       % estimate scalse and offset
        P.alpha = ab(1);                                        % fluorescence scale
        P.beta  = ab(2);                                        % fluorescence offset
        P.zeta  = (mad(F-ab'*C1,1)*1.4785)^2;
        P.gamma = P.zeta/5;                                     % signal dependent noise
        P.k = V.spikegen.EFGinv(0.01, P, V);

    end
    [smc.E smc.P smc.V] = smc_oopsi(F,V,P);
    if V.save, save(V.name_dat,'smc','-append'); end
end

%% provide outputs for later analysis

if nargout == 1
    if V.fast_iter_max > 0
        varargout{1} = fast;
    else
        varargout{1} = smc;
    end
elseif nargout == 2
    if V.fast_iter_max>0 && V.smc_iter_max>0
        varargout{1} = fast;
        varargout{2} = smc;
    else
        if V.fast_iter_max>0
            varargout{1} = fast;
            varargout{2} = V;
        else
            varargout{1}  = smc;
            varargout{2} = V;
        end
    end
elseif nargout == 3
    varargout{1} = fast;
    varargout{2} = smc;
    varargout{3} = V;
end

%% plot results

if V.plot
    if isfield(V,'fig_dir'), ffig=V.fig_dir; end
    V.name_fig = [ffig V.name];                                 % filename for figure
    fig = figure(3);
    clf,
    V.T     = length(F);
    nrows   = 1;
    if V.fast_iter_max>0,    nrows=nrows+1; end
    if V.smc_iter_max>0,     nrows=nrows+1; end
    gray    = [.75 .75 .75];            % define gray color
    inter   = 'tex';                    % interpreter for axis labels
    xlims   = [1 V.T];               % xmin and xmax for current plot
    fs      = 12;                       % font size
    ms      = 5;                        % marker size for real spike
    sw      = 2;                        % spike width
    lw      = 1;                        % line width
    xticks  = 0:1/V.dt:V.T;             % XTick positions
    skip    = round(length(xticks)/5);
    xticks  = xticks(1:skip:end);
    tvec_o  = xlims(1):xlims(2);        % only plot stuff within xlims
    if isfield(V,'true_n'), V.n=V.true_n; end
    if isfield(V,'n'), spt=find(V.n); end

    % plot fluorescence data
    i=1; h(i)=subplot(nrows,1,i); hold on
    plot(tvec_o,z1(F(tvec_o)),'-k','LineWidth',lw);
    ylab=ylabel([{'Fluorescence'}],'Interpreter',inter,'FontSize',fs);
    set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
    set(gca,'YTick',[],'YTickLabel',[])
    set(gca,'XTick',xticks,'XTickLabel',[])
    axis([xlims 0 1.1])

    % plot fast-oopsi output
    if V.fast_iter_max>0
        i=i+1; h(i)=subplot(nrows,1,i); hold on,
        n_fast=fast.n/max(fast.n);
        spts=find(n_fast>1e-3);
        stem(spts,n_fast(spts),'Marker','none','LineWidth',sw,'Color','k')
        if isfield(V,'n'),
            stem(spt,V.n(spt)/max(V.n(spt))+0.1,'Marker','v','MarkerSize',ms,'LineStyle','none','MarkerFaceColor',gray,'MarkerEdgeColor',gray)
        end
        axis([xlims 0 1.1])
        hold off,
        ylab=ylabel([{'fast'}; {'filter'}],'Interpreter',inter,'FontSize',fs);
        set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
        set(gca,'YTick',0:2,'YTickLabel',[])
        set(gca,'XTick',xticks,'XTickLabel',[])
        box off
    end

    % plot smc-oopsi output
    if V.smc_iter_max>0
        i=i+1; h(i)=subplot(nrows,1,i); hold on,
        spts=find(smc.E.nbar>1e-3);
        stem(spts,smc.E.nbar(spts),'Marker','none','LineWidth',sw,'Color','k')
        if isfield(V,'n'),
            stem(spt,V.n(spt)+0.1,'Marker','v','MarkerSize',ms,'LineStyle','none','MarkerFaceColor',gray,'MarkerEdgeColor',gray)
        end
        axis([xlims 0 1.1])
        hold off,
        ylab=ylabel([{'smc'}; {'filter'}],'Interpreter',inter,'FontSize',fs);
        set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
        set(gca,'YTick',0:2,'YTickLabel',[])
        set(gca,'XTick',xticks,'XTickLabel',[])
        box off
    end

    % label last subplot
    set(gca,'XTick',xticks,'XTickLabel',round(xticks*V.dt*100)/100)
    xlabel('Time (sec)','FontSize',fs)
    linkaxes(h,'x')

    % print fig
    if V.save
        wh=[7 3];   %width and height
        set(gcf,'PaperSize',wh,'PaperPosition',[0 0 wh],'Color','w');
        print('-depsc',V.name_fig)
        print('-dpdf',V.name_fig)
        saveas(fig,V.name_fig)
    end
end