function handles = distributionPlot(varargin)
%DISTRIBUTIONPLOT creates violin plots for convenient visualization of multiple distributions
% 2019.03.28 [13:29:26] - Biafra fix % # issue
% SYNOPSIS: handles = distributionPlot(data,propertyName,propertyValue,...)
%           handles = distributionPlot(ah,...)
%
% INPUT data : m-by-nData array of values, or vector of grouped data (use
%           the 'groups' property to specify the grouping variable), or
%           cell array of length nData.
%           The cell array can either contain vectors with values, or
%           m-by-2 arrays with [bins,counts] if you want to determine the
%           histograms by yourself (m can be different between cell
%           elements). Note that arrays inside cells with any
%           other shape than m-by-2 are reshaped to vector an a warning is
%           thrown (DISTRIBUTIONPLOT:AUTORESHAPE).
%
%       DISTRIBUTIONPLOT accepts the following propertyName/propertyValue
%           pairs (all are optional):
%
%       distWidth :  width of distributions; ideally between 0 and 1.
%           1 means that adjacent distributions might touch. Default: 0.9
%       variableWidth : If true, the width of the distribution changes,
%           reflecting the shape of the histogram of the data. If false,
%           the distribution is only encoded by color levels. Default: true
%       color : uniform coloring of histograms. Supply either a color
%           string ('r'), or a truecolor vector ([1 0 0]). Use a
%           cell array of length nData to specify one color per
%           distribution. Default: 'k'
%           If variableWidth is set to false, a colormap is generated that
%           goes from white to the chose color (or from black, if
%           invert==true).
%           If both 'color', and 'colormap' are specified, 'colormap' takes
%           precedence.
%       colormap : colormap used to describe the distribution (first row
%           corresponds to bins with least data, last row corresponds to
%           bins with most data (invert the grayscale colormap to have
%           black indicate the most data).
%           Supply a cell array of length nData to color distributions
%           individually. Note that using multiple colormaps means that
%           the colorbar doesn't contain much useful information.
%           Default: []
%           Colormap will index into the figure colormap, which will be
%           modified by distributionPlot. This is done to allow editing the
%           distributions in e.g. Adobe Illustrator.
%           If both 'color', and 'colormap' are specified, 'colormap' takes
%           precedence.
%       globalNorm : normalization for bin width (x-direction)
%           0 : every histogram is normalized individually so that the
%               maximum bin width is equal to distWidth. This is best
%               suited to comparing distribution shapes. Default.
%           1 : histograms are normalized such that equal bin width
%               reports equal numbers of counts per bin.
%           2 : histograms are normalized so that the relative areas
%               covered by the histograms reflect the relative total number
%               of data points.
%           3 : histograms areas are normalized so that relative densities
%               are the same across histograms. Thus, if
%               data = {rand(100,1),rand(500,1)},
%               then
%               distributionPlot(data,'globalNorm',2,'histOpt',0,'divFactor',10)
%               shows the left histogram 5x as wide as the right, while
%               distributionPlot(data,'globalNorm',3,'histOpt',0,'divFactor',10)
%               displays both histograms equally wide, since each bin
%               contains ~10% of the data.
%           Options 1 and 2 produce similar results if the bins are spaced
%           equally for the distributions. Options 0 and 3 produce similar
%           results if the data are drawn from the same distributions.
%           Note that colormaps currently always report the number of data
%           points per bin; 'globalNorm' only applies to the distribution
%           shape.
%
%       groups : grouping variable for grouped data. Grouping will be
%                   resolved by calling grp2idx, and unless xNames have
%                   been supplied, group names determine the x-labels.
%                   If the grouping variable is numeric, group labels also
%                   determine x-values, unless the parameter xValues has
%                   been specified.
%       histOpt : histogram type to plot
%                   0 : use hist command (no smoothing, fixed number of
%                       bins)
%                   1 : smoothened histogram using ksdensity with
%                       Normal kernel. Default.
%                   1.1: smoothened histogram using ksdensity where the
%                       kernel is robustly estimated via histogram.m.
%                       Normal kernel.
%                   2 : histogram command (no smoothing, automatic
%                       determination of thickness (y-direction) of bins)
%       divFactor : Parameter dependent on histOpt. If...
%                   histOpt == 0: divFactor = # of bins. Default: 25.
%                       Alternatively, pass a vector which will be
%                       interpreted as bin centers.
%                   histOpt == 1: divFactor decides by how much the default
%                       kernel-width is multiplied in order to avoid an
%                       overly smooth histogram. Default: 1/2
%                   histOpt == 2: divFactor decides by how much the
%                       automatic bin width is multiplied in order to have
%                       more (<1) or less (>1) detail. Default: 1
%       addSpread : if 1, data points are plotted with plotSpread.
%                   distWidth is ideally set to 0.95
%                   This option is not available if the data is supplied as
%                   histograms.
%                   Please download plotSpread.m separately from the File
%                   Exchange using the link in the remarks
%       showMM : if 1, mean and median are shown as red crosses and
%                green squares, respectively. This is the default
%                2: only mean
%                3: only median
%                4: mean +/- standard error of the mean (no median)
%                5: mean +/- standard deviation (no median)
%                6: draw lines at the 25,50,75 percentiles (no mean)
%                0: plot neither mean nor median
%       xValues: x-coordinate where the data should be plotted.
%                If xValues are given, "distWidth" is scaled by the median
%                difference between adjacent (sorted) x-values. Note that
%                this may lead to overlapping distributions. Default:
%                1:nData
%       xNames : cell array of length nData containing x-tick names
%               (instead of the default '1,2,3')
%       xMode  : if 'auto', x-ticks are spaced automatically. If 'manual',
%                there is a tick for each distribution. If xNames is
%                provided as input, xMode is forced to 'manual'. Default:
%                'manual'.
%          NOTE: SPECIFYING XNAMES OR XVALUES OR XMODE WILL ERASE PREVIOUS
%                LABELS IF PLOTTING INTO EXISTING AXES
%       yLabel : string with label for y-axis. Default : ''
%                If empty and data is histograms, ylabel is set to 'counts'
%       invert : if 1, axes color is changed to black, and colormap is
%                   inverted.
%       histOri: Orientation of histogram. Either 'center', 'left', or
%                'right'. With 'left' or 'right', the left or right half of
%                the standard violin plot is shown. Has no effect if
%                variableWidth is false. Default: center
%       xyOri  : orientation of axes. Either 'normal' (=default), or
%                'flipped'. If 'flipped', the x-and y-axes are switched, so
%                that violin plots are horizontal. Consequently,
%                axes-specific properties, such as 'yLabel' are applied to
%                the other axis.
%       widthDiv : 1-by-2 array with [numberOfDivisions,currentDivision]
%                widthDiv allows cutting the stripe dedicated to a single
%                distribution into multible bands, which can be filled with
%                sequential calls to distributionPlot. This is one way
%                to compare two (or more) sequences of distributions. See
%                example below.
%       ah : axes handle to plot the distributions. Default: gca
%
% OUTPUT handles : 1-by-4 cell array with patch-handles for the
%                  distributions, plot handles for mean/median, the
%                  axes handle, and the plotSpread-points handle
%
%
% EXAMPLES
%         %--Distributions contain more information than boxplot can capture
%         r = rand(1000,1);
%         rn = randn(1000,1)*0.38+0.5;
%         rn2 = [randn(500,1)*0.1+0.27;randn(500,1)*0.1+0.73];
%         rn2=min(rn2,1);rn2=max(rn2,0);
%         figure
%         ah(1)=subplot(3,4,1:2);
%         boxplot([r,rn,rn2])
%         ah(2)=subplot(3,4,3:4);
%         distributionPlot([r,rn,rn2],'histOpt',2); % histOpt=2 works better for uniform distributions than the default
%         set(ah,'ylim',[-1 2])
%
%         %--- additional options
%
%         data = [randn(100,1);randn(50,1)+4;randn(25,1)+8];
%         subplot(3,4,5)
%
%         %--- defaults
%         distributionPlot(data);
%         subplot(3,4,6)
%
%         %--- show density via custom colormap only, show mean/std,
%         distributionPlot(data,'colormap',copper,'showMM',5,'variableWidth',false)
%         subplot(3,4,7:8)
%
%         %--- auto-binwidth depends on # of datapoints; for small n, plotting the data is useful
%         % note that this option requires the additional installation
%         % of plotSpread from the File Exchange (link below)
%         distributionPlot({data(1:5:end),repmat(data,2,1)},'addSpread',true,'showMM',false,'histOpt',2)
%
%         %--- show quantiles
%         subplot(3,4,9),distributionPlot(randn(100,1),'showMM',6)
%
%         %--- horizontal orientation
%         subplot(3,4,10:11),
%         distributionPlot({chi2rnd(3,1000,1),chi2rnd(5,1000,1)},'xyOri','flipped','histOri','right','showMM',0),
%         xlim([-3 13])
%
%         %--- compare distributions side-by-side (see also example below)
%         % plotting into specified axes will throw a warning that you can
%         % turn off using " warning off DISTRIBUTIONPLOT:ERASINGLABELS "
%         ah = subplot(3,4,12);
%         subplot(3,4,12),distributionPlot(chi2rnd(3,1000,1),'histOri','right','color','r','widthDiv',[2 2],'showMM',0)
%         subplot(3,4,12),distributionPlot(chi2rnd(5,1000,1),'histOri','left','color','b','widthDiv',[2 1],'showMM',0)
%
%         %--Use globalNorm to generate meaningful colorbar
%         data = {randn(100,1),randn(500,1)};
%         figure
%         distributionPlot(data,'globalNorm',true,'colormap',1-gray(64),'histOpt',0,'divFactor',[-5:0.5:5])
%         colorbar
%
%         %--Use widthDiv to compare two series of distributions
%         data1 = randn(500,5);
%         data2 = bsxfun(@plus,randn(500,5),0:0.1:0.4);
%         figure
%         distributionPlot(data1,'widthDiv',[2 1],'histOri','left','color','b','showMM',4)
%         distributionPlot(gca,data2,'widthDiv',[2 2],'histOri','right','color','k','showMM',4)
%
%         %--Christmas trees!
%           x=meshgrid(1:10,1:10);
%           xx = tril(x);
%           xx = xx(xx>0);
%           figure
%           hh=distributionPlot({xx,xx,xx},'color','g','addSpread',1,'histOpt',2,'showMM',0);
%           set(hh{4}{1},'color','r','marker','o')
% END
%
% REMARKS To show distributions as clouds of points (~beeswarm plot),
%         and/or to use the option "addSpread", please download the
%         additional function plotSpread.m from the File Exchange
%         http://www.mathworks.com/matlabcentral/fileexchange/37105-plot-spread-points-beeswarm-plot
%
%         I used to run ksdensity with the Epanechnikov kernel. However,
%         for integer data, the shape of the kernel can produce peaks
%         between the integers, which is not ideal (use histOpt=2 for
%         integer valued data).
%
%         A previous iteration of distributionPlot used the input
%         specifications below. They still work to ensure backward
%         compatibility, but are no longer supported or updated.
%           handles = distributionPlot(data,distWidth,showMM,xNames,histOpt,divFactor,invert,addSpread,globalNorm)
%           where distWidth of 1 means that the maxima
%           of  two adjacent distributions might touch. Negative numbers
%           indicate that the distributions should have constant width, i.e
%           the density is only expressed through greylevels.
%           Values between 1 and 2 are like values between 0 and 1, except
%           that densities are not expressed via graylevels. Default: 1.9
%
%
% SEE ALSO histogram, ksdensity, plotSpread, boxplot, grp2idx
%

% created with MATLAB ver.: 7.6.0.324 (R2008a) on Windows_NT
%
% created by: Jonas Dorn; jonas.dorn@gmail.com
% DATE: 08-Jul-2008
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%====================================
%% TEST INPUT
%====================================

% set defaults
def.xNames = [];
def.showMM = 1;
def.distWidth = 0.9;
def.histOpt = 1;
def.divFactor = [25,2,1];
def.invert = false;
def.colormap = [];
def.color = 'k';
def.addSpread = false;
def.globalNorm = false;
def.variableWidth = true;
def.groups = [];
def.yLabel = '';
def.xValues = '';
def.xMode = 'manual';
def.histOri = 'center';
def.xyOri = 'normal';
def.widthDiv = [1 1];
isHistogram = false; % # this parameter is not set by input


if nargin == 0 || isempty(varargin{1})
    error('not enough input arguments')
end

% check for axes handle
if ~iscell(varargin{1}) && isscalar(varargin{1}) == 1 && ...
        ishandle(varargin{1}) && strcmp(get(varargin{1},'Type'),'axes')
    ah = varargin{1};
    data = varargin{2};
    varargin(1:2) = [];
    newAx = false;


else
    ah = gca;
    data = varargin{1};
    varargin(1) = [];
    newAx = true;
end

% check for current axes limits. Set NaN if the axes have no children
% yet - we need that in case we're building a complicated set of
% distributions
if ~isempty(get(ah,'children'))
    xAxLim = xlim;
    yAxLim = ylim;
else
    [xAxLim,yAxLim] = deal([NaN NaN]);
end

fh = get(ah,'Parent');

% check data. If not cell, convert
if ~iscell(data)
    [nPoints,nData] = size(data);
    data = mat2cell(data,nPoints,ones(nData,1));
else
    % get nData
    data = data(:);
    nData = length(data);
    % make sure all are vectors
    badCol = ~cellfun(@isvector,data) & ~cellfun(@isempty,data);
    if any(badCol)
        nCols = cellfun(@(x)(size(x,2)),data(badCol));
        if all(nCols==2)
            % bins,counts
            isHistogram = true;
        else
            warning('DISTRIBUTIONPLOT:AUTORESHAPE',...
                'Elements %s of the cell array are not vectors. They will be reshaped automatically',...
                num2str(find(badCol)'));
            data(badCol) = cellfun(@(x)(x(:)),data(badCol),'UniformOutput',false);
        end
    end
end

parserObj = inputParser;
parserObj.FunctionName = 'distributionPlot';
stdWidth = 1; % scaling parameter for variableWidth with uneven x-values
% check whether we're dealing with pN/pV or straight arguments
if ~isempty(varargin) && ~ischar(varargin{1}) && ~isstruct(varargin{1})
    % use old format
    % distWidth,showMM,xNames,histOpt,divFactor,invert,addSpread,globalNorm
    def.distWidth = 1.9;
    parserObj.addOptional('distWidth',def.distWidth);
    parserObj.addOptional('showMM',def.showMM);
    parserObj.addOptional('xNames',def.xNames);
    parserObj.addOptional('histOpt',def.histOpt);
    parserObj.addOptional('divFactor',def.divFactor);
    parserObj.addOptional('invert',def.invert);
    parserObj.addOptional('addSpread',def.addSpread);
    parserObj.addOptional('globalNorm',def.globalNorm);
    parserObj.addOptional('groups',def.groups);
    parserObj.addOptional('yLabel',def.yLabel);
    parserObj.addOptional('color',def.color);


    parserObj.parse(varargin{:});
    opt = parserObj.Results;
    % fill in defaults that are not supported in the old version of the
    % code
    opt.colormap = [];
    opt.variableWidth = true;
    opt.histOri = 'center';
    opt.xValues = [];
    opt.xMode = 'auto';
    opt.xyOri = 'normal';
    opt.widthDiv = [1 1];

    % overwrite empties with defaults - inputParser considers empty to be a
    % valid input.
    fnList = fieldnames(opt);
    for fn = fnList'
        if isempty(opt.(fn{1}))
            opt.(fn{1}) = def.(fn{1});
        end
    end


    % fix a few parameters
    if opt.distWidth > 1
        opt.distWidth = opt.distWidth - 1;
    else
        opt.colormap = 1-gray(128);
    end
    if opt.distWidth < 0
        opt.variableWidth = false;
        opt.distWidth = abs(opt.distWidth);
    end

    if ~isempty(opt.xNames)
        opt.xMode = 'manual';
    end


else
    defNames = fieldnames(def);
    for dn = defNames(:)'
        parserObj.addParamValue(dn{1},def.(dn{1}));
    end


    parserObj.parse(varargin{:});
    opt = parserObj.Results;

    % if groups: deal with data
    if ~isempty(opt.groups)
        [idx,labels,vals] = grp2idx(opt.groups);
        % convert data to cell array
        data = accumarray(idx,data{1},[],@(x){x});
        nData = length(data);
        % if not otherwise provided, use group labels for xnames
        if isempty(opt.xNames)
            opt.xNames = labels;
            if ~iscell(opt.xNames)
                opt.xNames = num2cell(opt.xNames);
            end
        end
        if isnumeric(vals) && isempty(opt.xValues)
            opt.xValues = vals;
        end

    end

    if ~ischar(opt.xyOri) || ~any(ismember(opt.xyOri,{'normal','flipped'}))
        error('option xyOri must be either ''normal'' or ''flipped'' (is ''%s'')',opt.xyOri);
    end




end
% common checks

% default x-values: 1:n
if isempty(opt.xValues)
    opt.xValues = 1:nData;
elseif length(opt.xValues) ~= nData
    error('please supply as many x-data values as there are data entries')
elseif length(opt.xValues) > 1 % only check for scale if more than 1 value
    % scale width
    stdWidth = median(diff(sort(opt.xValues)));
    opt.distWidth = opt.distWidth * stdWidth;
end

if ~isscalar(opt.divFactor) && length(opt.divFactor) == 3 && all(opt.divFactor==def.divFactor)
    opt.divFactor = opt.divFactor(floor(opt.histOpt)+1);
end
if isHistogram
    opt.histOpt = 99;
    if isempty(opt.yLabel)
        opt.yLabel = 'counts';
    end
end



% check colors/colormaps: do we need to expand colormap?
if ~iscell(opt.colormap)
    opt.colormap = {opt.colormap};
end
if ~iscell(opt.color)
    opt.color = {opt.color};
end
for iColor = 1:length(opt.color)
    if ischar(opt.color{iColor})
        opt.color{iColor} = colorCode2rgb(opt.color{iColor});
    end
end

% expand - if only single colormap specified, we expand only once
if ~opt.variableWidth
    missingColormaps = find(cellfun(@isempty,opt.colormap));
    for iMissing = missingColormaps(:)'

        endColor = opt.color{max(iMissing,length(opt.color))};
        % normally, we go from white to color
        cmap = zeros(128,3);
        for rgb = 1:3
            cmap(:,rgb) = linspace(1,endColor(rgb),128);
        end
        opt.colormap{iMissing} = cmap;

    end
end

% if we have colormaps, we need to create a master which we add to the
% figure. Invert if necessary, and expand the cell array to nData
colormapLength = cellfun(@(x)size(x,1),opt.colormap);
if any(colormapLength>0)

    colormap = cat(1,opt.colormap{:});
    if opt.invert
        colormap = 1-colormap;
    end
    set(fh,'Colormap',colormap)
    if length(opt.colormap) == 1
        opt.colormap = repmat(opt.colormap,nData,1);
        colormapLength = repmat(colormapLength,nData,1);
        colormapOffset = zeros(nData,1);
        singleMap = true;
    else
        colormapOffset = [0;cumsum(colormapLength(1:end-1))];
        singleMap = false;
    end

else

    colormapLength = zeros(nData,1);
    if length(opt.color) == 1
        opt.color = repmat(opt.color,nData,1);
    end
    if opt.invert
        opt.color = cellfun(@(x)1-x,opt.color,'uniformOutput',false);
    end
end


% set hold on
holdState = get(ah,'NextPlot');
set(ah,'NextPlot','add');

% if new axes: invert
if newAx && opt.invert
    set(ah,'Color','k')
end

%===================================



%===================================
%% PLOT DISTRIBUTIONS
%===================================

% assign output
hh = NaN(nData,1);
[m,md,sem,sd] = deal(nan(nData,1));
if opt.showMM == 6
    md = nan(nData,3,3); % md/q1/q3, third dim is y/xmin/xmax
end

% get base x-array
% widthDiv is a 1-by-2 array with
% #ofDivs, whichDiv
% The full width (distWidth) is split into
% #ofDivs; whichDiv says which "stripe" is active
xWidth = opt.distWidth/opt.widthDiv(1);
xMin = -opt.distWidth/2;
xLow = xMin + xWidth * (opt.widthDiv(2)-1);
xBase = [-xWidth;xWidth;xWidth;-xWidth]/2;
xOffset = xLow + xWidth/2;

% b/c of global norm: loop twice
plotData = cell(nData,2);

% loop through data. Prepare patch input, then draw patch into gca
for iData = 1:nData
    currentData = data{iData};
    % only plot if there is some finite data
    if ~isempty(currentData(:)) && any(isfinite(currentData(:)))

        switch floor(opt.histOpt)
            case 0
                % use hist
                [xHist,yHist] = hist(currentData,opt.divFactor);

            case 1
                % use ksdensity

                if opt.histOpt == 1.1
                    % use histogram to estimate kernel
                    [dummy,x] = histogramDistributionPlot(currentData); %#ok<ASGLU>
                    if length(x) == 1
                        % only one value. Make fixed distribution
                        dx = 0.1;
                        yHist = x;
                        xHist = sum(isfinite(currentData));
                    else
                        dx = x(2) - x(1);

                    % make sure we sample frequently enough
                    x = min(x)-dx:dx/3:max(x)+dx;
                    [xHist,yHist] = ksdensity(currentData,x,'kernel','normal','width',dx/(1.5*opt.divFactor));
                    end
                else

                    % x,y are switched relative to normal histogram
                    [xHist,yHist,u] = ksdensity(currentData,'kernel','normal');
                    % take smaller kernel to avoid over-smoothing
                    if opt.divFactor ~= 1
                        [xHist,yHist] = ksdensity(currentData,'kernel','normal','width',u/opt.divFactor);
                    end
                end

                % modify histogram such that the sum of bins (not the
                % integral under the curve!) equals the total number of
                % observations, in order to be comparable to hist
                xHist = xHist/sum(xHist)*sum(isfinite(currentData));

            case 2
                % use histogram - bar heights are counts as in hist
                [xHist,yHist] = histogramDistributionPlot(currentData,opt.divFactor,0);
            case 99
                % bins,counts already supplied
                xHist = currentData(:,2)';
                yHist = currentData(:,1)';
        end
        plotData{iData,1} = xHist;
        plotData{iData,2} = yHist;
    end
end

goodData = find(~cellfun(@isempty,plotData(:,1)));
% get norm
switch opt.globalNorm
    case 3
        % #3 normalizes relative densities
        xNorm(goodData) = cellfun(@(x)min(diff(x)),plotData(goodData,2));
        xNorm(goodData) = xNorm(goodData) .* cellfun(@sum,plotData(goodData,1))';
        maxNorm(goodData) = cellfun(@max,plotData(goodData,1));
        xNorm(goodData) = xNorm(goodData)*max(maxNorm(goodData)./xNorm(goodData));

    case 2
        % #2 should normalize so that the integral of the
        % different histograms (i.e. area covered) scale with the
        % respective sum of counts across all bins. Requires evenly spaced
        % histograms at the moment
        xNorm(goodData) = cellfun(@(x)min(diff(x)),plotData(goodData,2));
        maxNorm(goodData) = cellfun(@max,plotData(goodData,1));
        xNorm(goodData) = xNorm(goodData)*max(maxNorm(goodData)./xNorm(goodData));
    case 1
        xNorm(goodData) = max(cat(2,plotData{:,1}));
    case 0
        xNorm(goodData) = cellfun(@max,plotData(goodData,1));
end


for iData = goodData'

    % find current data again
    currentData = data{iData};

    xHist = plotData{iData,1};
    yHist = plotData{iData,2};

    % find y-step
    dy = min(diff(yHist));
    if isempty(dy)
        dy = 0.1;
    end

    % create x,y arrays
    nPoints = length(xHist);
    xArray = repmat(xBase,1,nPoints);
    yArray = repmat([-0.5;-0.5;0.5;0.5],1,nPoints);


    % x is iData +/- almost 0.5, multiplied with the height of the
    % histogram
    if opt.variableWidth


        tmp = xArray.*repmat(xHist,4,1)./xNorm(iData);

        switch opt.histOri
            case 'center'
                % we can simply use xArray
                xArray = tmp;
            case 'right'
                % shift everything to the left
                delta = tmp(1,:) - xArray(1,:);
                xArray = bsxfun(@minus,tmp,delta);
            case 'left'
                % shift everything to the right
                delta = tmp(1,:) - xArray(1,:);
                xArray = bsxfun(@plus,tmp,delta);
        end

        xArray = xArray + opt.xValues(iData);

    else
        xArray = xArray + iData;
    end

    % add offset (in case we have multiple widthDiv)
    xArray = xArray + xOffset;


    % yData is simply the bin locations
    yArray = repmat(yHist,4,1) + dy*yArray;

    % add patch
    vertices = [xArray(:),yArray(:)];
    faces = reshape(1:numel(yArray),4,[])';

    if colormapLength(iData) == 0
        colorOpt = {'FaceColor',opt.color{iData}};
    else
        % calculate index into colormap
        if singleMap
            % use scaled mapping so that colorbar is meaningful
            if opt.globalNorm > 0
                colorOpt = {'FaceVertexCData',xHist','CDataMapping','scaled','FaceColor','flat'};
            else
                colorOpt = {'FaceVertexCData',xHist'/xNorm(iData),'CDataMapping','scaled','FaceColor','flat'};
            end

        else
            idx = round((xHist/xNorm(iData))*(colormapLength(iData)-1))+1;
            colorOpt = {'FaceVertexCData',idx'+colormapOffset(iData),'CDataMapping','direct','FaceColor','flat'};
        end
    end


    switch opt.xyOri
        case 'normal'
            hh(iData)= patch('Vertices',vertices,'Faces',faces,'Parent',ah,colorOpt{:},'EdgeColor','none');
        case 'flipped'
            hh(iData)= patch('Vertices',vertices(:,[2,1]),'Faces',faces,'Parent',ah,colorOpt{:},'EdgeColor','none');
    end

    if opt.showMM > 0
        if isHistogram
            [m(iData),sem(iData)] = weightedStats(currentData(:,1),currentData(:,2),'w');
            sd(iData) = sem(iData) * sqrt(sum(currentData(:,2)));
            % weighted median: where we're at middle weight
            % may need some tweaking
            goodCurrentData = sortrows(currentData(all(isfinite(currentData),2),:),1);
            weightList = cumsum(goodCurrentData(:,2));
            weightList = weightList / weightList(end);
            md(iData) = goodCurrentData(find(weightList>0.5,1,'first'),1);
        else
            m(iData) = nanmean(currentData);
            md(iData) = nanmedian(currentData);
            sd(iData) = nanstd(currentData);
            sem(iData) = sd(iData)/sqrt(sum(isfinite(currentData)));
        end

        if opt.showMM == 6
            % read quantiles - "y"-value, plus x-start-stop
            % re-use md array which allows using a loop below instead of
            % lots of copy-paste
            % md array is md/q1/q3, with third dimension y/xmin/xmax

            md(iData,2,1) = prctile(currentData,25);
            md(iData,3,1) = prctile(currentData,75);

            for qq = 1:3
                % find corresponding y-bin
                yLoc =  repmat(...
                    any(yArray>md(iData,qq,1),1) & any(yArray<=md(iData,qq,1),1),...
                    [4 1]);
                % look up corresponding x-values. Note that there is a bit
                % of a risk that the line will be exactly between two very
                % different bins - but if we make the line longer, it will
                % be ugly almost all the time
                md(iData,qq,2) = min( xArray( yLoc ) );
                md(iData,qq,3) = max( xArray( yLoc ) );
            end

        end
    end
end % loop

sh = [];
if opt.addSpread
    if isHistogram
        disp('Option addSpread is unavailable if data is supplied as histograms. Call plotSpread separately')
    else
        % add spread
        try
            sh = plotSpread(ah,data,'xValues',opt.xValues,'xyOri',opt.xyOri);
            set(sh{1},'color',[0,128,255]/255);
        catch me
            if strcmp(me.identifier,'MATLAB:UndefinedFunction')
                error('plotSpread not found. Please download it from the Matlab File Exchange')
            else
                rethrow(me)
            end
        end
    end
end

mh = [];mdh=[];
if opt.showMM
    % plot mean, median. Mean is filled red circle, median is green square
    % I don't know of a very clever way to flip xy and keep everything
    % readable, thus it'll be copy-paste
    switch opt.xyOri
        case 'normal'
            if any(opt.showMM==[1,2])
                mh = plot(ah,opt.xValues+xOffset,m,'+r','Color','r','MarkerSize',12);
            end
            if any(opt.showMM==[1,3])
                mdh = plot(ah,opt.xValues+xOffset,md,'sg','MarkerSize',12);
            end
            if opt.showMM == 4
                mh = plot(ah,opt.xValues+xOffset,m,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,opt.xValues+xOffset,m,sem);
            end
            if opt.showMM == 5
                mh = plot(ah,opt.xValues+xOffset,m,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,opt.xValues+xOffset,m,sd);
            end
            if opt.showMM == 6
                mdh(1,:) = plot(ah,squeeze(md(:,1,2:3))',repmat(md(:,1,1)',2,1),'color','r','lineWidth',2);%,'lineStyle','--');
                mdh(2,:) = plot(ah,squeeze(md(:,2,2:3))',repmat(md(:,2,1)',2,1),'color','r','lineWidth',1);%,'lineStyle','--');
                mdh(3,:) = plot(ah,squeeze(md(:,3,2:3))',repmat(md(:,3,1)',2,1),'color','r','lineWidth',1);%,'lineStyle','--');
            end
        case 'flipped'
            if any(opt.showMM==[1,2])
                mh = plot(ah,m,opt.xValues+xOffset,'+r','Color','r','MarkerSize',12);
            end
            if any(opt.showMM==[1,3])
                mdh = plot(ah,md,opt.xValues+xOffset,'sg','MarkerSize',12);
            end
            if opt.showMM == 4
                mh = plot(ah,m,opt.xValues+xOffset,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,m,opt.xValues+xOffset,[sem,NaN(size(sem))]);
            end
            if opt.showMM == 5
                mh = plot(ah,m,opt.xValues+xOffset,'+r','Color','r','MarkerSize',12);
                mdh = myErrorbar(ah,m,opt.xValues+xOffset,[sd,NaN(size(sd))]);
            end
            if opt.showMM == 6
                mdh(1,:) = plot(ah,repmat(md(:,1,1)',2,1),squeeze(md(:,1,2:3))','color','r','lineWidth',2);%,'lineStyle','--');
                mdh(2,:) = plot(ah,repmat(md(:,2,1)',2,1),squeeze(md(:,2,2:3))','color','r','lineWidth',1);%,'lineStyle','--');
                mdh(3,:) = plot(ah,repmat(md(:,3,1)',2,1),squeeze(md(:,3,2:3))','color','r','lineWidth',1);%,'lineStyle','--');
            end
    end
end

% find extents of x-axis (or y-axis, if flipped)
minX = min(opt.xValues)-stdWidth;
maxX = max(opt.xValues)+stdWidth;

if ~isnan(xAxLim(1))
    % we have previous limits
    switch opt.xyOri
        case 'normal'
            minX = min(minX,xAxLim(1));
            maxX = max(maxX,xAxLim(2));
        case 'flipped'
            minX = min(minX,yAxLim(1));
            maxX = max(maxX,yAxLim(2));
    end
end


% if ~empty, use xNames
switch opt.xyOri
    case 'normal'
        switch opt.xMode
            case 'manual'
                if newAx == false
                    warning('DISTRIBUTIONPLOT:ERASINGLABELS','Plotting into an existing axes and specifying labels will erase previous labels')
                end
                set(ah,'XTick',opt.xValues);
                if ~isempty(opt.xNames)
                    set(ah,'XTickLabel',opt.xNames)
                end
            case 'auto'
                % no need to do anything
        end
        if ~isempty(opt.yLabel)
            ylabel(ah,opt.yLabel);
        end
        % have plot start/end properly
        xlim([minX,maxX])
    case 'flipped'
        switch opt.xMode
            case 'manual'
                if newAx == false
                    warning('DISTRIBUTIONPLOT:ERASINGLABELS','Plotting into an existing axes and specifying labels will erase previous labels')
                end
                set(ah,'YTick',opt.xValues);
                if ~isempty(opt.xNames)
                    set(ah,'YTickLabel',opt.xNames)
                end
            case 'auto'
                % no need to do anything
        end
        if ~isempty(opt.yLabel)
            xlabel(ah,opt.yLabel);
        end
        % have plot start/end properly
        ylim([minX,maxX])
end


%==========================


%==========================
%% CLEANUP & ASSIGN OUTPUT
%==========================

if nargout > 0
    handles{1} = hh;
    handles{2} = [mh;mdh];
    handles{3} = ah;
    handles{4} = sh;
end

set(ah,'NextPlot',holdState);