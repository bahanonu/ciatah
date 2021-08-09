function [hF,hB] = imoverlay(B,F,climF,climB,cmap,alpha,haxes)
% IMOVERLAY(B,F) displays the image F transparently over the image B.
%    If the image sizes are unequal, image F will be scaled to the aspect
%    ratio of B.
% 
%    [hF,hB] = imoverlay(B,F,[low,high]) limits the displayed range of data
%    values in F. These values map to the full range of values in the
%    current colormap.
% 
%    [hF,hB] = imoverlay(B,F,[],[low,high]) limits the displayed range of
%    data values in B.
% 
%    [hF,hB] = imoverlay(B,F,[],[],map) applies the colormap to the figure.
%    This can be an array of color values or a preset MATLAB colormaps
%    (e.g. 'jet' or 'hot').
% 
%    [hF,hB] = imoverlay(B,F,[],[],[],alpha) sets the transparency level to
%    alpha with the range 0.0 <= alpha <= 1.0, where 0.0 is fully
%    transparent and 1.0 is fully opaque.
% 
%    [hF,hB] = imoverlay(B,F,[],[],[],[],ha) displays the overlay in the
%    axes with handle ha.
%
%    [hF,hB] = imoverlay(...) returns the handles to the front and back
%    images.
%
%
% Author: Matthew Smith / University of Wisconsin / Department of Radiology
% Date created:  February 6, 2013
% Last modified: July 30, 2013
%
%  
%  Examples:
%     
%     % Overlay one image transparently onto another
%     imB = phantom(256);                       % Background image
%     imF = rgb2gray(imread('ngc6543a.jpg'));   % Foreground image
%     [hf,hb] = imoverlay(imB,imF,[40,180],[0,0.6],'jet',0.6);
%     colormap('hot'); % figure colormap still applies
%
%
%     % Use the interface for flexibility
%     imoverlay_tool;
%
% 
% See also IMOVERLAY_TOOL, IMAGESC, HOLD, CAXIS.



ALPHADEFAULT = 0.4; % Default transparency value
CMAPDEFAULT = 'jet';

if nargin == 0,
    try
        imoverlay_tool;
        return;
    catch
        errordlg('Cannot find imoverlay_tool.', 'Error');
    end
end


% Check image sizes
if size(B,3) > 1
    error('Back image has %d dimensions!\n',length(size(B)));
end
if size(F,3) > 1
    error('Front image has %d dimensions!\n',length(size(F)));
end
if ~isequal(size(B),size(F))
    fprintf('Warning! Image sizes unequal. Undesired scaling may occur.\n');
end

% Check arguments
if nargin < 7
    haxes = [];          
end

if nargin < 6 || isempty(alpha)
    alpha = ALPHADEFAULT;
end

if nargin < 5 || isempty(cmap)
    cmap = CMAPDEFAULT;    
end

if nargin < 4 || isempty(climB)
    climB = [min(B(:)), max(B(:))];
end

if nargin < 3 || isempty(climF)
    climF = [min(F(:)), max(F(:))];
end

if abs(alpha) > 1
    error('Alpha must be between 0.0 and 1.0!');
end


% Create a figure unless axes is provided
if isempty(haxes) || ~ishandle(haxes)
    f=figure('Visible','off',...
        'Units','pixels','Renderer','opengl');
    pos = get(f,'Position');
    set(f,'Position',[pos(1),pos(2),size(B,2),size(B,1)]);
    haxes = axes;
    set(haxes,'Position',[0,0,1,1]);
    movegui(f,'center');
    
    % Create colormap
    cmapSize = 100; % default size of 60 shows visible discretization
    if ischar(cmap)
        
        try
            cmap = eval([cmap '(' num2str(cmapSize) ');']);
        catch
            fprintf('Colormap ''%s'' is not supported. Using ''jet''.\n',cmapName);
            cmap = jet(cmapSize);
        end
    end
    colormap(cmap);
end

% To have a grayscale background, replicate image to 3-channels
B = repmat(mat2gray(double(B),double(climB)),[1,1,3]);

% Display the back image
axes(haxes);
hB = imagesc(B);axis image off;
% set(gca,'Position',[0,0,1,1]);

% Add the front image on top of the back image
hold on;
hF = imagesc(F,climF);

% If images are different sizes, map the front image to back coordinates
set(hF,'XData',get(hB,'XData'),...
    'YData',get(hB,'YData'))

% Make the foreground image transparent
alphadata = alpha.*(F >= climF(1));
set(hF,'AlphaData',alphadata);

if exist('f')
    set(f,'Visible','on');
end


    % Novel colormaps
    %
    % JET2 is the same as jet but with black base
    function J = jet2(m)
        if nargin < 1
            m = size(get(gcf,'colormap'),1);
            J = jet; J(1,:) = [0,0,0];
        end
        J = jet(m); J(1,:) = [0,0,0];
    end

    % JET3 is the same as jet but with white base
    function J = jet3(m)
        if nargin < 1
            m = size(get(gcf,'colormap'),1);
            J = jet; J(1,:) = [1,1,1];
        end
        J = jet(m); J(1,:) = [1,1,1];
    end


    % HSV2 is the same as HSV but with black base
    function map = hsv2(m)
        map =hsv;
        map(1,:) = [0,0,0];
    end

    % HSV3 is the same as HSV but with white base
    function map = hsv3(m)
        map =hsv;
        map(1,:) = [1,1,1];
    end

    % HSV4 a slight modification of hsv (Hue-saturation-value color map)
    function map = hsv4(m)
        if nargin < 1, m = size(get(gcf,'colormap'),1); end
        h = (0:m-1)'/max(m,1);
        if isempty(h)
            map = [];
        else
            map = hsv2rgb([h h ones(m,1)]);
        end
    end
end