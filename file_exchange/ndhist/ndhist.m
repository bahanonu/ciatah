% Add logx,logy,loglog
% 

% Displays a 2d histogram for your data, it will set the bins appropriately
% 
% NDHIST(x,y); where x and y are equal length vectors. It will choose
%              reasonable axis bounds and bins to present your data. The
%              default parameters may leave some data off the chart.
% 
% NDHIST(XY);  where XY = [x y] and x,y are vectors
% 
% NDHIST(z);   where z is a vector of complex numbers, (x+1i*y) or amplitude*exp(1i*theta)
% 
% NDHIST(y);   where y is a vector of real numbers will plot a 2d histogram
%              of the points, as if it were a line-chart. It is equivalent
%              to calling ndhist(1:length(y),y);
%  
% N = NDHIST(x,y); returns a matrix N containing the counts for each bin
%              determined by the histogram.
% 
% [edgesX2,edgesY2,N,h] = NDHIST(x,y); which returns a matrix N containing
%              the counts for each bin determined by the histogram. You can
%              plot it with sanePColor(edgesX2,edgesY2,N); (from Matlabcentral)
%              h is the plot handle.
% 
% NDHIST(...,'param','value','param','value', ... ); Run ndhist with specific
%              parameters
%           
% List of special parameters: 
% 
%  'filter' : This will apply a gaussian filter to the final histogram data.
%             The default filter width is 5 bins wide. If you pass a number
%             then that will be used. Even numbered filter parameters will be
%             changed to odd numbers to keep the filter perfectly symetrical.
%             'filt','filtering','smooth'
% 
%    'log' : Change the colormap to be on a log scale to represent data
%            over a large dynamic range. 
%            'logplot'
% 
%   'bins' : Change the size of the bins. For example '2' will create a
%            plot with twice the default number of bins; 0.5 will have half
%            the default number of bins. The default uses Scott's normal
%            reference rule. Unclear if it is ideal for 2d histograms...
%            If you are looking for a histogram with specific bins, use the
%            subfunction hist3. Feel free to implement it as an additional
%            parameter 'edgdes','edgesx' or 'edgesy'
%            'f','numbins'
% 
%  'binsx' : Change the size of only the x bins. 'fx'
%  'binsy' : Change the size of only the y bins. 'fy'
%            
%     axis : This is to set the range of the plot, [xmin xmax ymin ymax]
%            The default range is set to 3*std(x) and 3*std(y) where the
%            parameter stdTimes=3 is hard-coded in this version and
%            potentially added as a parameter in a later version.
% 
%      max : This is to set the range of the plot to be such that every
%            point will be contained within the plot.
%            'themax'
%  
%  intbins : Set the bins to be intiger widths. For both x and y
%            'int'
% 
% intbinsx : Set the x bins to be intiger widths. 'intx'
% intbinsy : Set the y bins to be intiger widths. 'inty'
% 
%normalizex: Normalize the plot so that the sum of all the y values in each
%            x bin sum to one.
%            'normx','nx' 
% 
%normalizey: Normalize the plot so that the sum of all the x values in each
%            y bin sum to one.
%            'normy','ny'
% 
%normalizeR: Normalize the plot so that the you can clearly see how the
%            distribution vary's over angle. It weights points in the outer
%            radius by the diameter at that radius.
%            'nr'
%    points: Plot the points on top of the colored histogram.
% 
%        3D: Use a 3D column graph instead of a colored heatmap
%            'threeD','3d','columns'
%     
% PARTIALLY IMPLEMENTED
%   radial : Set the axis to be equal and add a polar grid 'r'
% 
% NOT IMPLEMENTED YET
%'samebins': NOT IMPLEMENTED YET. Would set the width of the x and y bins
%            to be equal to each other and the axis equal too.

% 
% user parameters:
% filter: This will filter the data, you may choose to follow it with a
%         number. This number will represent the radius of the circular
%         gaussian filter. Other ways to call it: 'filt','filtering','f'
%  
% 
% examples
% 
% To test the function you may use this example:
% z=2*randn(1,100000)+1i*(randn(1,100000));
% 
% If you have amplitude and angle measures then pass this:
% z = amp*exp(1i*ang);
% 
% NDHIST(z)
% NDHIST(z,'lansey')
% NDHIST(z,'filter')
% 
% % Note
% The name of this function comes because really its a 2d hist, but since I
% already have an 'nhist' I thought I might name it this.
% 
% SEE ALSO: HIST, HIST3
%%
function [edgesX2,edgesY2,N,h] = ndhist(z,varargin)

% hold_state = ishold;
colormap(linspecer);
%% Errors and warning for bad data
if ~isnumeric(z)
    error('you must take the histogram of numeric data silly');
end
if numel(z)<10
    warning(['you have only ' num2str(numel(z)) ' being plotted, are you sure a histogram is such a good idea?']);
end
if isempty(z)
    warning('no data, returnting');
    return;
end

% Also re-call the function in case of things
if isreal(z)
    if size(z,2)==2 % we have a [x y] case
        [edgesX2,edgesY2,N] = ndhist(z(:,1)+1i*z(:,2),varargin{:});
    else % we've got either 
        if isempty(varargin) % just one value passed
            display('your data are all ''real'' so we intepreted it as a timeseries');
            idx = (1:length(z))';
            [edgesX2,edgesY2,N] = ndhist(idx+1i*z(:),'fx',4,'fy',2);
            colormap(linspecer('blue'));
        else% at least two values passed
            y = varargin{1};
            if isnumeric(y) % we've got the (x,y) case
                %                 if do something about nargout here
                if length(y)~=length(z)
                    error('x and y must be the same length');
                end
                [edgesX2,edgesY2,N] = ndhist(z(:)+1i*y(:),varargin{2:end});
            else % we've got just one value, but with special arguments passed
%                 display('your data are all ''real'' so we intepreted it as a timeseries');
                idx = (1:length(z))';
                [edgesX2,edgesY2,N] = ndhist(idx+1i*z(:),'fx',4,'fy',1,varargin{:});
            end
        end
    end
    if nargout==1
        edgesX2 = N;
    end
    if nargout==2
        warning('you are being passed out ''edgesX2,edgesY2'' is that really what you want from this function?');
    end
    
    return;
end
% great we can continue


%% Standardize the data
% Pcolor does not work with 'single' type so this makes it is a double.
% Making it into a vertical vector is also important (see below).
z=double(z(:));

% remove nan data
I=isnan(z);
if sum(I)>0
    warning([num2str(sum(I)) ' NaN data points were ignored']);
    z = z(~I);
end

% separate x and y
x = real(z); y = imag(z);

%% Set program defaults
filtering=0;
userParam=0;
stdTimes=3; % the number of times the standard deviation to set the upper end of the axis to be.
minBins=10;
maxBins=1000;
binFactorX = 1;
binFactorY = 1;
intbinsFlagX = isdiscrete(x);
intbinsFlagY = isdiscrete(y);

normalizeFlagX = 0;
normalizeFlagY = 0;

pointsFlag = 0; % to plot the points also
threeDFlag = 0;

maxisFlag = 0; % If you choose this then no data will fall off the screen
logColorFlag = 0; % plot the logarithm of the counts instead to get more contrast

%% calculate some defaults
% for a radial plot use this: ... maybe use the same bounds for even a
% radial plot!
% rangeR=max(abs(z))*1.05; % padds the bound by 1/20th the maximum

S = length(x);

stdX = std(x); meanX = mean(x);
stdY = std(y); meanY = mean(y);

if stdX>(10*eps) % just checking there are more than two different points to the data, checking for rounding errors.
%   we include some padding in here
    leftEdge = max(meanX-stdX*stdTimes,min(x));
    riteEdge = min(meanX+stdX*stdTimes,max(x));
else % stdV==0, wow, all your data points are equal
    leftEdge=min(x)-1000*eps; % padd it by 100, seems reasonable
    riteEdge=max(x)+1000*eps;
end

if stdY>(10*eps) % just checking there are more than two different points to the data, checking for rounding errors.
    botEdge = max(meanY-stdY*stdTimes,min(y));
    topEdge = min(meanY+stdY*stdTimes,max(y));
else % stdV==0, wow, all your data points are equal
    botEdge=min(y)-1000*eps; % padd it by 100, seems reasonable
    topEdge=max(y)+1000*eps;
end

% for a non radial plot with unequal axes use this:
% padX = (max(x)-min(x))*.05;
% padY = (max(y)-min(y))*.05;

padX = (riteEdge - leftEdge)*.01;
padY = (topEdge - botEdge)*.01;

axisXY = [leftEdge riteEdge botEdge topEdge]+[-padX padX -padY padY]; % do we need this much padding really?
rangeX = riteEdge-leftEdge;
rangeY =  topEdge -botEdge;

%%
radialFlag = 0;

%% interperet user parameters
k=1;
while k <= nargin-1
    if ischar(varargin{k})
    switch lower(varargin{k})
        case {'filter','filt','filtering','smooth'}
            filtering=5; % default filter radius
            if k<=nargin-2% -1+1, lol
                if ~ischar(varargin{k+1})
                    filtering=varargin{k+1};
                    k = k + 1;
                end
            end
        case {'axis'}
            axisXY=varargin{k+1};
            k = k + 1;
        case {'themax','max'} % make it so all of your data are plotted
            maxisFlag = 1;

%         case 'maxx'
%             Should I add all those puppies in?
        case {'range'} % Note: this feature does nothing yet.
            rangeR=varargin{k+1};
            k = k + 1;
        case {'radial','r'}
            radialFlag=1;
        case {'bins','numbins','f'} % 'f' comes from the binfactor of nhist
            binFactorY=varargin{k+1};
            binFactorX=varargin{k+1};
            k = k + 1;           
        case {'binsx','fx'} % 'f' comes from the binfactor of nhist
            binFactorX=varargin{k+1};
            k = k + 1;           
        case {'binsy','fy'} % 'f' comes from the binfactor of nhist
            binFactorY=varargin{k+1};
            k = k + 1;           
        case {'intbins','int'} % 'f' comes from the binfactor of nhist
            intbinsFlagX = 1;
            intbinsFlagY = 1;
            if k+1<= length(varargin)
                temp = varargin{k + 1};
                if ~ischar(temp) % if its a number then we want to use it.
                    intbinsFlagX = temp;
                    intbinsFlagY = temp;
                    k = k+1;
                end
            end
        case {'intbinsx','intx'} % 'f' comes from the binfactor of nhist
            intbinsFlagX = 1;
            if k+1<= length(varargin)
                temp = varargin{k + 1};
                if ~ischar(temp) % if its a number then we want to use it.
                    intbinsFlagX = temp;
                    k = k+1;
                end
            end
        case {'intbinsy','inty'} % 'f' comes from the binfactor of nhist
            intbinsFlagY = 1;
            if k+1<= length(varargin)
                temp = varargin{k + 1};
                if ~ischar(temp) % if its a number then we want to use it.
                    intbinsFlagY = temp;
                    k = k+1;
                end
            end
        case {'lansey','normalizer','nr'} % this guy weights the values based on radius
            userParam=1;       
        case {'log','logplot'}
            logColorFlag = 1;
        case {'normalizex','normx','nx'}
            normalizeFlagX = 1;
        case {'normalizey','normy','ny'}
            normalizeFlagY = 1;
        case {'points','.'}
            pointsFlag = 1;
        case {'3d','threed','columns'}
            threeDFlag = 1;
        case 'stdtimes' % the number of times the standard deviation to set the upper end of the axis to be.
%             Note, this is non-functional in this NDHist
            stdTimes = varargin{k + 1};
            k = k + 1;
            if ischar(stdTimes)
                fprintf(['\nstdTimes set to: ' stdTimes]);
                error('stdTimes must be a number')
            end

        otherwise 
            warning(['you have passed a strange parameter: ''' varargin{k} ''' please roll again']);
    end
    else
        warning(['input parameter ''' num2str(varargin{k}) ''' not understood, please use ''param'',''value'' pairs']);
    end
  k = k + 1; % increment it so it goes to the next one
end
%%

if normalizeFlagX && normalizeFlagY
    warning('Only normalize X was used');
    normalizeFlagY = 0;
end
    

%% set the bin widths
% Using Scott's normal reference rule, unclear if it is ideal for 2D histograms ...
binWidthX=3.5*stdX/(binFactorX*S^(1/3));
binWidthY=3.5*stdY/(binFactorY*S^(1/3));

% Instate a mininum and maximum number of bins
numBinsX = rangeX/binWidthX; % Approx number of bins
numBinsY = rangeY/binWidthY; % Approx number of bins

if numBinsX<minBins % if this will imply less than 10 bins
    binWidthX=rangeX/(minBins); % set so there are ten bins
end
if numBinsX>maxBins % if there would be more than the max bins
    binWidthX=rangeX/maxBins;
end

if numBinsY<minBins % if this will imply less than 10 bins
    binWidthY=rangeY/(minBins); % set so there are ten bins
end
if numBinsY>maxBins % if there would be more than the max bins
    binWidthY=rangeY/maxBins;
end

% check for maxis
if maxisFlag
    temp = [max(x)-min(x), max(y)-min(y)]*[-1 1 0 0 ; 0 0 -1 1]*.05;
    axisXY = [min(x) max(x) min(y) max(y)]+temp; % do some padding with one matrix equation woo!
end

% round the edges if intbins are a thing
if intbinsFlagX
    axisXY(1)=round(axisXY(1))-.5; % subtract 1/2 to make the bin peaks appear on the numbers.
    axisXY(2)=round(axisXY(2))+.5;
    binWidthX=max(round(binWidthX),1);
    
%     numBinsX = rangeX/binWidthX; % Approx number of bins
    
    
end
if intbinsFlagY
    axisXY(3)=round(axisXY(3))-.5; % subtract 1/2 to make the bin peaks appear on the numbers.
    axisXY(4)=round(axisXY(4))+.5;
    binWidthY=max(round(binWidthY),1);
    
%     numBinsY = rangeY/binWidthY; % Approx number of bins


    
end

% finally set the bins
edgesX=axisXY(1):binWidthX:axisXY(2);
edgesY=axisXY(3):binWidthY:axisXY(4);

%% start the real histogram computation

N =  hist3(x,y,edgesX,edgesY);

[X,Y]=meshgrid(edgesX,edgesY);

%% user parameters to adjust the results
if filtering
    N2 = smooth2(N,filtering);
    N = N2;
    
%     % if you have the image processing toolbox then you could use this:
%     H = fspecial('disk',filtering);
%     filtN = imfilter(N,H,'replicate');
%     N=filtN;
end

if 0 % IMPLEMENTATION NOT TESTED if you wanted real probabilities instead of counts then you would use this one.
%     what exactly is 'x' here?
    N=N/(binWidthX*binWidthY*length(x)); % normalize by area to get probability distribution
end

if userParam % to do the radial normalizing
    R2=X.^2+Y.^2; % R.^2
    R=sqrt(R2); % R.^2
    N = N.*R;
end

if logColorFlag
%   Note: we are safe from negative numbers because nothing can be less than zero here
    N = log10(N+1);
end

if normalizeFlagX
%     N = N./repmat(sum(N,1)+eps,size(N,1),1);
    N = N./repmat(max(N,[],1)+eps,size(N,1),1);
end
if normalizeFlagY
%     N = N./repmat(sum(N,2)+eps,1,size(N,2));
    N = N./repmat(max(N,[],2)+eps,1,size(N,2));
end

%%
edgesX2 = edgesX+binWidthX/2;
edgesY2 = edgesY+binWidthY/2;

% sanePColor(edgesX2,edgesY2,N);
if ~threeDFlag
    h = spcolor(edgesX2,edgesY2,N);
    axis('tight');
    axis([min(edgesX) max(edgesX) min(edgesY) max(edgesY)]);
    shading('flat');
else % plot with 3D columns thanks Josh G for this! (fileexchange/authors/484807)
    h=bar3(edgesY2,N,1.0);
    % bar3 reversed y-axis, set it back to normal
    set(gca, 'YDir', 'normal');
    % Used to shift x data x = m*x+b
    m = (edgesX2(end)-edgesX2(1))/(numel(edgesX2)-1);
    b = edgesX2(1)-m;
    for ii = 1:length(h)
        % Rebuild zdata and remove NaN, determined by looking at zdata, this
        % removes the uncolored faces that appear if you just set Cdata to
        % Zdata.
        zdata = get(h(ii),'Zdata');
        cdata = repmat(reshape(repmat(zdata(2:6:end,2)',6,1),[],1),1,4);
        % Shift data in X to get correct axis, set color data
        set(h(ii), 'XData', get(h(ii),'XData')*m+b, 'Cdata',cdata);
    end
    axis('tight');
end

if nargout==1
    edgesX2 = N;
end
if nargout==2
    warning('you are being passed out ''edgesX2,edgesY2'' is that really what you want from this function?');
end




if radialFlag
    myPolar3;
end

%% tweak the colormap to be lighter
% colormap((2*jet(64)/3+1/3));
% colormap(linspecer(128))
% C = colormap;

%% plot the points if we need to
if pointsFlag
    hold on;
    plot(real(z),imag(z),'k.');
end

% if ~hold_state, hold off; end;

end % ndhist function over 


%%
% 2D histogram which is actually kind of fast making use of matlab's histc
function allN = hist3(x,y,edgesX,edgesY)
    allN = zeros(length(edgesY),length(edgesX));
    [~,binX] = histc(x,edgesX);
    for ii=1:length(edgesX)
        I = (binX==ii);
        N = histc(y(I),edgesY);
        allN(:,ii) = N';
    end
end % BAM how small is this function? sweet peas!

%%


% This function accomodates the crazy 'pcolor' thing where it isn't
% centered and cuts off the edges.
function h = spcolor(x,y,A)

%%

[S1, S2] = size(A);

A2 = [A zeros(S1,1);
    zeros(1,S2) 0];

xx = [x 2*x(end)-x(end-1)]-(x(end)-x(end-1))/2;
yy = [y 2*y(end)-y(end-1)]-(y(end)-y(end-1))/2;

h = pcolor(xx,yy,A2);

end




%%
% This will tell if the data is an integer or not.
% first it will check if matlab says they are integers, but even so, they
% might be integers stored as doubles!
function L = isdiscrete(x,varargin) % L stands for logical
minError=eps*100; % the minimum average difference from integers they can be.
L=0; % double until proven integer
if ~isempty(varargin)
    minError=varargin{1};
end 
if isinteger(x)||islogical(x) % your done, duh, its an int.
    L=1;
    return; 
else
    if sum(abs(x-round(x)))/length(x)<minError
        L=1;
    end
end

end




%%
% This version is for plotting a certain figure.
% 
%   myPolar: Polar coordinate plot, draws a polar grid onto the axis
% 
%  myPolar(); % just adds the grid to the axis
%  myPolar(theta,rho) % makes a plot using polar coordinates of
%        the angle THETA, in radians, versus the radius RHO
%  myPolar(z) same as obove for z complex
%  myPolar(THETA,RHO,S) uses the linestyle specified in string, like 'z'
%  myPolar(THETA,RHO,'linespec','parameter',...) uses the linestyle
%                  specified by the linspec functions of plot
% 
% 
% Here are the specific list of improvements from Matlab's function:
% The ability to add a polar grid to any other plot you make
% the ability to use all linspec parameters, like 'linewidth' and 'color'
% the ability to plot complex data
% The plot is still square, it does not gray out anything.
% Grid axis ticks go to two decimal places
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Jonathan Lansey May 2009,     questions to Lansey at gmail.com          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function myPolar3(varargin)
% find hold state so we can put it back when we are done
hold_state = ishold;

nCircles=3;
nDegrees=30;
    
if nargin==0 % plot the grid now!

    addPolarGrid(nCircles,nDegrees);
    addPolarText(nCircles,nDegrees);
    
else
    if ~isreal(varargin{1})% if its complex
%       we just get x and y from the complex data
        z=varargin{1};
        x=real(z);
        y=imag(z);
        curArg=2;
    else % there must be theta and rho parameters passed
        [x,y] = pol2cart(varargin{1},varargin{2});
        curArg=3;
    end
%     k=curArg;
%     while k <= nargin && ischar(varargin{k})
%         switch (lower(varargin{k}))
%           case 'xlabel'
%             SXLabel = varargin{k + 1};
%             k = k + 1;
%           case 'ylabel'
%         end
%     end
    plot(x,y,varargin{curArg:end}); % plots the curves, but just to get the axis to where it will stay.
    hold on;
    addPolarGrid(nCircles,nDegrees); %add the grid with no parameters so it adds the grid!
    plot(x,y,varargin{curArg:end}); % adds the plot again, this time above the grid
    addPolarText(nCircles,nDegrees); %add the text to the grid on top of the curves
end

if ~hold_state
    hold off;
    set(gca,'xtick',[],'ytick',[]);
end

%------------------------------------------------------------------%

        % This function adds a polar grid, nested in myPolar
        function addPolarGrid(nCircles,nDegrees)
            hold_state = ishold; hold on;

            p=axis;
            p=max(abs(p));
            axis([-p p -p p]);

            axis equal;  axis manual;
            dTheta=nDegrees*pi/180;
            axiss=abs(axis);
            maxR=max(axiss);
            max2R=min(max([axiss(1:2) axiss(3:4)]));
            drawlines(max2R,dTheta);
            drawcircle(maxR,nCircles);
        %     axis auto; % bring it back to the normal mode
            if ~hold_state % if hold is off, then you can also remove the axis labels
                hold off;
            end
        end

        %------------------------------------------------------------------%
        function drawlines(R,dTheta) % nested in myPolar
            % This draws circles of the radius
            % dTheta is equal to the angular distance between the lines
            offset_angle = 0:dTheta:2*pi;
            for n=1:length(offset_angle)-1
                x=real([0 R]*exp(1i*offset_angle(n)));
                y=imag([0 R]*exp(1i*offset_angle(n)));
                plot(x,y,'--k','linewidth',2);
            end

        end % drawlines over

        %------------------------------------------------------------------%
        function drawcircle(R,nCircles) % nested in myPolar
            r=linspace(0,R,nCircles+1);
            w=0:.01:2*pi;
            for n=2:length(r)
                x=real(r(n)*exp(1i*w));
                y=imag(r(n)*exp(1i*w));
                plot(x,y,'--k','linewidth',2)
            end
        end
        %------------------------------------------------------------------%
        % This function adds the polar text, nested in myPolar
        function addPolarText(nCircles,nDegrees)
            hold_state = ishold; hold on;
            axiss=abs(axis); maxR=max(axiss); maxTextR=axiss(4);
            r=linspace(0,maxR,nCircles+1);
            for n=2:length(r)
                thetaForText=pi/2.1;
                zTextSpot=1.2*r(n)*exp(1i*thetaForText);
                if abs(zTextSpot)<maxTextR
                    textHandle  = text(real(zTextSpot),imag(zTextSpot),num2str(r(n),'%.0f'),'fontSize',18,'fontweight','bold');
                    uistack(textHandle, 'top');
                end
            end
            if ~hold_state, hold off; end;
        end
        %------------------------------------------------------------------%
end % myPolar over

%%







% function lineStyles = linspecer(N)
% This function creates an Nx3 array of N [R B G] colors
% These can be used to plot lots of lines with distinguishable and nice
% looking colors.
% 
% lineStyles = linspecer(N);  makes N colors for you to use: lineStyles(ii,:)
% 
% colormap(linspecer); set your colormap to have easily distinguishable 
%                      colors and a pleasing aesthetic
% 
% lineStyles = linspecer(N,'qualitative'); forces the colors to all be distinguishable (up to 12)
% lineStyles = linspecer(N,'sequential'); forces the colors to vary along a spectrum 
% 
% % Examples demonstrating the colors.
% 
% LINE COLORS
% N=6;
% X = linspace(0,pi*3,1000); 
% Y = bsxfun(@(x,n)sin(x+2*n*pi/N), X.', 1:N); 
% C = linspecer(N);
% axes('NextPlot','replacechildren', 'ColorOrder',C);
% plot(X,Y,'linewidth',5)
% ylim([-1.1 1.1]);
% 
% SIMPLER LINE COLOR EXAMPLE
% N = 6; X = linspace(0,pi*3,1000);
% C = linspecer(N)
% hold off;
% for ii=1:N
%     Y = sin(X+2*ii*pi/N);
%     plot(X,Y,'color',C(ii,:),'linewidth',3);
%     hold on;
% end
% 
% COLORMAP EXAMPLE
% A = rand(15);
% figure; imagesc(A); % default colormap
% figure; imagesc(A); colormap(linspecer); % linspecer colormap
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% by Jonathan Lansey, March 2009-2013 – Lansey at gmail.com               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%% credits and where the function came from
% The colors are largely taken from:
% http://colorbrewer2.org and Cynthia Brewer, Mark Harrower and The Pennsylvania State University
% 
% 
% She studied this from a phsychometric perspective and crafted the colors
% beautifully.
% 
% I made choices from the many there to decide the nicest once for plotting
% lines in Matlab. I also made a small change to one of the colors I
% thought was a bit too bright. In addition some interpolation is going on
% for the sequential line styles.
% 
% 
%%

function lineStyles=linspecer(N,varargin)

if nargin==0 % return a colormap
    lineStyles = linspecer(128);
    return;
end

if ischar(N)
    lineStyles = linspecer(128,N);
    return;
end

if N<=0 % its empty, nothing else to do here
    lineStyles=[];
    return;
end

% interperet varagin
qualFlag = 0;

if ~isempty(varargin)>0 % you set a parameter?
    switch lower(varargin{1})
        case {'qualitative','qua'}
            if N>12 % go home, you just can't get this.
                warning('qualitiative is not possible for greater than 12 items, please reconsider');
            else
                if N>9
                    warning(['Default may be nicer for ' num2str(N) ' for clearer colors use: whitebg(''black''); ']);
                end
            end
            qualFlag = 1;
        case {'sequential','seq'}
            lineStyles = colorm(N);
            return;
        case {'white','whitefade'}
            lineStyles = whiteFade(N);return;
        case 'red'
            lineStyles = whiteFade(N,'red');return;
        case 'blue'
            lineStyles = whiteFade(N,'blue');return;
        case 'green'
            lineStyles = whiteFade(N,'green');return;
        case {'gray','grey'}
            lineStyles = whiteFade(N,'gray');return;
        otherwise
            warning(['parameter ''' varargin{1} ''' not recognized']);
    end
end      
      
% predefine some colormaps
  set3 = colorBrew2mat({[141, 211, 199];[ 255, 237, 111];[ 190, 186, 218];[ 251, 128, 114];[ 128, 177, 211];[ 253, 180, 98];[ 179, 222, 105];[ 188, 128, 189];[ 217, 217, 217];[ 204, 235, 197];[ 252, 205, 229];[ 255, 255, 179]}');
set1JL = brighten(colorBrew2mat({[228, 26, 28];[ 55, 126, 184];[ 77, 175, 74];[ 255, 127, 0];[ 255, 237, 111]*.95;[ 166, 86, 40];[ 247, 129, 191];[ 153, 153, 153];[ 152, 78, 163]}'));
set1 = brighten(colorBrew2mat({[ 55, 126, 184]*.95;[228, 26, 28];[ 77, 175, 74];[ 255, 127, 0];[ 152, 78, 163]}),.8);

set3 = dim(set3,.93);

switch N
    case 1
        lineStyles = { [  55, 126, 184]/255};
    case {2, 3, 4, 5 }
        lineStyles = set1(1:N);
    case {6 , 7, 8, 9}
        lineStyles = set1JL(1:N)';
    case {10, 11, 12}
        if qualFlag % force qualitative graphs
            lineStyles = set3(1:N)';
        else % 10 is a good number to start with the sequential ones.
            lineStyles = cmap2linspecer(colorm(N));
        end
otherwise % any old case where I need a quick job done.
    lineStyles = cmap2linspecer(colorm(N));
end
lineStyles = cell2mat(lineStyles);
end

% extra functions
function varIn = colorBrew2mat(varIn)
for ii=1:length(varIn) % just divide by 255
    varIn{ii}=varIn{ii}/255;
end        
end

function varIn = brighten(varIn,varargin) % increase the brightness

if isempty(varargin),
    frac = .9; 
else
    frac = varargin{1}; 
end

for ii=1:length(varIn)
    varIn{ii}=varIn{ii}*frac+(1-frac);
end        
end

function varIn = dim(varIn,f)
    for ii=1:length(varIn)
        varIn{ii} = f*varIn{ii};
    end
end

function vOut = cmap2linspecer(vIn) % changes the format from a double array to a cell array with the right format
vOut = cell(size(vIn,1),1);
for ii=1:size(vIn,1)
    vOut{ii} = vIn(ii,:);
end
end
%%

% colorm returns a colormap which is really good for creating informative
% heatmap style figures.
% No particular color stands out and it doesn't do too badly for colorblind people either.
% It works by interpolating the data from the
% 'spectral' setting on http://colorbrewer2.org/ set to 11 colors
% It is modified a little to make the brightest yellow a little less bright.
function cmap = colorm(varargin)
n = 100;
if ~isempty(varargin)
    n = varargin{1};
end

if n==1
    cmap =  [0.2005    0.5593    0.7380];
    return;
end
if n==2
     cmap =  [0.2005    0.5593    0.7380;
              0.9684    0.4799    0.2723];
          return;
end

frac=.95; % Slight modification from colorbrewer here to make the yellows in the center just a bit darker
cmapp = [158, 1, 66; 213, 62, 79; 244, 109, 67; 253, 174, 97; 254, 224, 139; 255*frac, 255*frac, 191*frac; 230, 245, 152; 171, 221, 164; 102, 194, 165; 50, 136, 189; 94, 79, 162];
x = linspace(1,n,size(cmapp,1));
xi = 1:n;
cmap = zeros(n,3);
for ii=1:3
    cmap(:,ii) = pchip(x,cmapp(:,ii),xi);
end
cmap = flipud(cmap/255);
end

function cmap = whiteFade(varargin)
n = 100;
if nargin>0
    n = varargin{1};
end

thisColor = 'blue';

if nargin>1
    thisColor = varargin{2};
end
switch thisColor
    case {'gray','grey'}
        cmapp = [255,255,255;240,240,240;217,217,217;189,189,189;150,150,150;115,115,115;82,82,82;37,37,37;0,0,0];
    case 'green'
        cmapp = [247,252,245;229,245,224;199,233,192;161,217,155;116,196,118;65,171,93;35,139,69;0,109,44;0,68,27];
    case 'blue'
        cmapp = [247,251,255;222,235,247;198,219,239;158,202,225;107,174,214;66,146,198;33,113,181;8,81,156;8,48,107];
    case 'red'
        cmapp = [255,245,240;254,224,210;252,187,161;252,146,114;251,106,74;239,59,44;203,24,29;165,15,21;103,0,13];
    otherwise
        warning(['sorry your color argument ' thisColor ' was not recognized']);
end

cmap = interpomap(n,cmapp);
end

% Eat a approximate colormap, then interpolate the rest of it up.
function cmap = interpomap(n,cmapp)
    x = linspace(1,n,size(cmapp,1));
    xi = 1:n;
    cmap = zeros(n,3);
    for ii=1:3
        cmap(:,ii) = pchip(x,cmapp(:,ii),xi);
    end
    cmap = (cmap/255); % flipud??
end




% This is a fast smooth function that will return a smoothed
% version of the original that you pass it.
% 
% Hey now the default is actually going to be a gaussian filter not a
% moving average filter
% 
% It will be the same length as the original, and it will be centered on
% the original function. To padd the edges it extends the average of the
% last 'n' values on the end out further.
% 
% Note that it uses a convolution which uses the
% cool fft trick to do it effeciently.
%% set things up if you want to test it as a script 
% N=301;
% % y = rand(N,1);
% y=-1./[1:N];
% y=sin(linspace(1,5*pi,N));
% n=10;

% This guys is going to smooth it for 2 dimensions I hope;

function yout = smooth2(A,n)
if length(A)<3
    warning('Sorry bud, you can''t smooth less than 3 points, thats silly');
    yout = A;
    return;
end

if length(n)==1
    if n<2
        yout = A;
        return;
    end
    
%     forcing you to have an odd 'n'
    if double(~logical(round(n/2)-n/2));
        n = n+1;
    end
    
    bee = linspace(-1.96,1.96,n); % normal distribution with 95% confidence bounds
    [BX, BY] = meshgrid(bee);
    R2 = BX.^2+BY.^2;
    toConvolve = exp(-R2)/sum(exp(-R2(:)));
    
%     toConvolve = exp(-bee.^2)/sum(exp(-bee.^2));
%     old moving average computation: 
% toConvolve = ones(n,1)/n;
else
    toConvolve = n;
    if round(sum(toConvolve)*100000)/100000~=1
        warning('the sum here does not equal to one.');
    end
    n = length(toConvolve);
end

if min(size(A))<=n
    warning('Sorry bud, you can''t smooth that, pick a smaller n or use more points');
    yout = A;
    return;
end



% isVertical = size(y,1)>size(y,2);

% y=y(:)';

% padding on the left
padLeft = repmat(mean(A(:,1:n),2),1,n);
padRite = repmat(mean(A(:,end-n:end),2),1,n);
A = [padLeft A padRite];

padTop = repmat(mean(A(1:n,:),1),n,1);
padBot = repmat(mean(A(end-n:end,:),1),n,1);

A = [padTop; A; padBot];

% the main event
As=conv2(A,toConvolve);
% % % % % % % % % % % % % 
% clf;

% sanePColor(As);

% outputting a centered subset
isEven = double(~logical(round(n/2)-n/2));
if isEven
    yout = As(n+(n/2):end-n-(n/2),n+(n/2):end-n-(n/2));
else % it is odd then
    yout = As(n+(n/2)+.5:end-n-(n/2)+.5,n+(n/2)+.5:end-n-(n/2)+.5);
end

end

%% This is the function for calculating the quantiles for the bplot.
function yi = prctile(X,p)
x=X(:);
if length(x)~=length(X)
    error('please pass a vector only');
end
n = length(x);
x = sort(x);
Y = 100*(.5 :1:n-.5)/n;
x=[min(x); x; max(x)];
Y = [0 Y 100];
yi = interp1(Y,x,p);

end










