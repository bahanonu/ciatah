function hh = myErrorbar(varargin)
%MYERRORBAR Adds errorbars to existing plot (unlike errorbar.m, which creates a new plot, and allows only bars for y values)
%   MYERRORBAR(X,Y,L,U) adds error bars to the graph of vector X vs. vector Y with
%   error bars specified by the vectors L and U.  L and U contain the
%   lower and upper error ranges for each point in Y.  Each error bar
%   is L(i) + U(i) long and is drawn a distance of U(i) above and L(i)
%   below the points in (X,Y). If X,Y,L and U are matrices then each column
%   produces a separate line.
%   If L,U are the same size as X, Y, only error bars for Y will be plotted.
%   If L,U are twice the size of X,Y (or have twice the number of columns for
%   matrices), the first half of L, U specifies error bar lengths for X and the
%   second half specifies error bars for Y
%
%   MYERRORBAR(X,Y,E) or MYERRORBAR(Y,E) plots error bars [Y-E Y+E].
%
%   MYERRORBAR(AX,...), where AX is an axis handle, plots errorbars into
%                       axes AX
%
%   H = MYERRORBAR(...) returns a vector of line handles.
%
%   The tag of the errorbar-lines is: errorBar
%
%   For example,
%      x = 1:10;
%      y = sin(x);
%      e = std(y)*ones(size(x));
%      myErrorbar(x,y,e)
%   draws symmetric error bars of unit standard deviation for y values.
%      myErrorbar(x,y,[e,e])
%   draws symmetric error bars of unit standard deviation for x and y
%   values.
%
%   Based on the matlab-function errorbar as revised by Claude Berney
%   c: jonas, 06-03
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%==================
% check input
%==================

if nargin < 2
    error('not enough input arguments!')
end

% check if the first input argument is a handle
if length(varargin{1}) == 1 && ishandle(varargin{1}) && strcmpi(get(varargin{1},'Type'),'axes')
    axesH = varargin{1};
    % remove axis handle
    varargin(1) = [];
else
    axesH = gca;
end

% there could be
% y,e
% x,y,e
% x,y,l,u

switch length(varargin)
    case 2
        % y, e
        y = varargin{1};
        y = y(:);
        lengthY = length(y);
        x = [1:lengthY]';
        
        e = varargin{2};
        % check for 2 dimension errorbars
        e = e(:);
        if length(e) == 2*lengthY
            e = reshape(e,lengthY,2);
        end
        [l,u] = deal(e);
        
    case 3
        % x,y,e
        x = varargin{1};
        x = x(:);
        y = varargin{2};
        y = y(:);
        lengthY = length(y);
        
        e = varargin{3};
        % check for 2 dimension errorbars
        e = e(:);
        if length(e) == 2*lengthY
            e = reshape(e,lengthY,2);
        end
        [l,u] = deal(e);
        
    case 4
        % x,y,l,u
        % x,y,e
        x = varargin{1};
        x = x(:);
        y = varargin{2};
        y = y(:);
        lengthY = length(y);
        
        l = varargin{3};
        % check for 2 dimension errorbars
        l = l(:);
        if length(l) == 2*lengthY
            l = reshape(l,lengthY,2);
        end
        u = varargin{4};
        % check for 2 dimension errorbars
        u = u(:);
        if length(u) == 2*lengthY
            u = reshape(u,lengthY,2);
        end
        
        if ~all(size(u)==size(l))
            error('l, u have to be the same size!')
        end
        
end % switch number of inputs


u = abs(u);
l = abs(l);

if ischar(x) || ischar(y) || ischar(u) || ischar(l)
    error('Arguments must be numeric.')
end

if ~isequal(size(x),size(y))
    error('The sizes of X and Y must be the same.');
end

if isequal([1 2].*size(x),size(l)) && isequal([1 2].*size(x),size(u))
    xyBars = 1;
elseif isequal(size(x),size(l)) && isequal(size(x),size(u))
    xyBars = 0;
else
    error('The sizes of L and U must be equal to or twice the size of X, Y')
end

%=======================


% Plot graph and bars
hold_state = ishold;
hold on;


%find color of current plot
dataH = get(axesH,'Children');
myLineH = dataH(1);
% support also bar plots
if strcmp(get(myLineH,'Type'),'hggroup')
    latestColor = get(myLineH,'EdgeColor'); %new children are added on top!
else
    latestColor = get(myLineH,'Color'); %new children are added on top!
end

tee=0;
if ~strcmp('log',get(axesH,'XScale'))
    tee = (max(x(:))-min(x(:)))/100;  % make tee .02 x-distance for error bars
    tee = min(tee,0.3*nanmedian(diff(unique(x(:))))); % or at most 0.3*deltaX
    xl = x - tee;
    xr = x + tee;
end
if strcmp('log',get(axesH,'XScale'))
    tee = (max(log(x(:)))-min(log(x(:))))/100;  % make tee .02 x-distance for error bars
    tee = min(tee,0.3*nanmedian(diff(unique(log(x(:)))))); % or at most 0.3*deltaX
    
    xl = x *exp(tee);
    xr = x *exp(-tee);
end

if xyBars
    if ~strcmp('log',get(axesH,'YScale'))
        tee = (max(y(:))-min(y(:)))/100;  % make tee .02 y-distance for error bars
        tee = min(tee,0.3*nanmedian(diff(unique(y(:))))); % or at most 0.3*deltaY
        
        yl = y - tee;
        yr = y + tee;
    end
    if strcmp('log',get(axesH,'YScale'))
        tee = (max(log(y(:)))-min(log(y(:))))/100;  % make tee .02 y-distance for error bars
        tee = min(tee,0.3*nanmedian(diff(unique(log(y(:)))))); % or at most 0.3*deltaX
        
        yl = y *exp(tee);
        yr = y *exp(-tee);
    end
end

%specify coordinates to plot error bars
if xyBars
    xtop = x + u(:,1:size(x,2));
    xbot = x - l(:,1:size(x,2));
    ytop = y + u(:,size(x,2)+1:end);
    ybot = y - l(:,size(x,2)+1:end);
else
    ytop = y + u;
    ybot = y - l;
end
n = size(y,2);

% build up nan-separated vector for bars
xb = zeros(lengthY*9,n);
xb(1:9:end,:) = x;
xb(2:9:end,:) = x;
xb(3:9:end,:) = NaN;
xb(4:9:end,:) = xl;
xb(5:9:end,:) = xr;
xb(6:9:end,:) = NaN;
xb(7:9:end,:) = xl;
xb(8:9:end,:) = xr;
xb(9:9:end,:) = NaN;

yb = zeros(lengthY*9,n);
yb(1:9:end,:) = ytop;
yb(2:9:end,:) = ybot;
yb(3:9:end,:) = NaN;
yb(4:9:end,:) = ytop;
yb(5:9:end,:) = ytop;
yb(6:9:end,:) = NaN;
yb(7:9:end,:) = ybot;
yb(8:9:end,:) = ybot;
yb(9:9:end,:) = NaN;

h = [line(xb,yb,'parent',axesH,'Color',latestColor)];

if xyBars
    
    xb(1:9:end,:) = xtop;
    xb(2:9:end,:) = xbot;
    xb(3:9:end,:) = NaN;
    xb(4:9:end,:) = xtop;
    xb(5:9:end,:) = xtop;
    xb(6:9:end,:) = NaN;
    xb(7:9:end,:) = xbot;
    xb(8:9:end,:) = xbot;
    xb(9:9:end,:) = NaN;
    
    yb(1:9:end,:) = y;
    yb(2:9:end,:) = y;
    yb(3:9:end,:) = NaN;
    yb(4:9:end,:) = yl;
    yb(5:9:end,:) = yr;
    yb(6:9:end,:) = NaN;
    yb(7:9:end,:) = yl;
    yb(8:9:end,:) = yr;
    yb(9:9:end,:) = NaN;
    
    h = [h;line(xb,yb,'parent',axesH,'Color',latestColor)];
    
end

%set the tag of all errorBar-objects to 'errorBar'
set(h,'Tag','errorBar');

% make sure errorbar doesn't produce a legend entry
for lineH = h'
    set(get(get(lineH,'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off');
end


if ~hold_state, hold off; end

if nargout>0, hh = h; end
