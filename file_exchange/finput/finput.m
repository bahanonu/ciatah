function [out1,out2,out3] = finput(N)
% finput is a faster-than-ginput graphical input from mouse. This function
% temporarily creates a duplicate set of axes atop the current axes, then
% calls ginput. Temporary axes are deleted upon termination of finput. 
% 
% 
%% Syntax 
% 
% [x,y] = finput(N)
% [x,y] = finput
% [x,y,BUTTON] = finput(N)
% 
%% Description 
% 
% [x,y] = finput(N) gets N points from the current axes and returns
% the X- and Y-coordinates in length N vectors X and Y.  The cursor
% can be positioned using a mouse.  Data points are entered by pressing
% a mouse button or any key on the keyboard except carriage return,
% which terminates the input before N points are entered.
% 
% [x,y] = finput gathers an unlimited number of points until the
% return key is pressed.
% 
% [x,y,BUTTON] = finput(N) returns a third result, BUTTON, that
% contains a vector of integers specifying which mouse button was
% used (1,2,3 from left) or ASCII numbers if a key on the keyboard
% was used.
%
%% Example
% If a set of axes contains only simple graphics objects, finput may offer
% no advantage over ginput. However, if you're trying to use ginput over a
% surface made of many elements, you may find that ginput is too slow. Here's 
% a case where ginput is terribly slow on my machine, but finput performs well: 
% 
%   pcolor(repmat(peaks,50,50))
%   shading interp
%   finput
%
%% Author Info
% This function was written by Chad A. Greene of the University of Texas
% at Austin's Institute for Geophysics (UTIG). February 2015. 
% http://www.chadagreene.com. 
% 
%
% See also GINPUT, WAITFORBUTTONPRESS.


%% 

% Ensure 0 or 1 inputs:
narginchk(0,1); 

% Get limits and settings of current axes: 
xl = get(gca,'xlim'); 
yl = get(gca,'ylim'); 
pos = get(gca,'pos'); 
xc = get(gca,'xcolor'); 
yc = get(gca,'ycolor'); 
xsc = get(gca,'xscale'); 
ysc = get(gca,'yscale'); 
xdir = get(gca,'xdir'); 
ydir = get(gca,'ydir'); 

% Create temporary axes in exactly the same position as gca, and
% make the color 'none' so user can see the underlying gca: 
tmpax = axes('pos',pos,...
    'xlim',xl,'ylim',yl,...
    'color','none',...
    'xcolor',xc,'ycolor',yc,...
    'xtick',[],'xticklabel','',...
    'ytick',[],'yticklabel','',...
    'xdir',xdir,'ydir',ydir,...
    'xscale',xsc,'yscale',ysc); 

% Call ginput: 
switch nargout
    case {0,1} 
        if nargin
            out1 = ginput(N); 
        else
            out1 = ginput;
        end
            
    case 2
        if nargin
            [out1,out2] = ginput(N); 
        else
            [out1,out2] = ginput; 
        end
            
    case 3
        if nargin
            [out1,out2,out3] = ginput(N); 
        else
            [out1,out2,out3] = ginput; 
        end
end   

% Delete temporary set of axes: 
delete(tmpax)
