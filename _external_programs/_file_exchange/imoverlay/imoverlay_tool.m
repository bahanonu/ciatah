function imoverlay_tool
% IMOVERLAY_TOOL Interface to overlay one image on top of another. 
%
% - Allows independent control of both images
% - Workspace variables are selected via a dropdown menu
% - Easily adjust colormap
% - Adjustable transparency
% - Load 3D or 4D datasets
% - Export figure for saving
% - Accelerator keys for quick selections
%
% Author: Matthew Smith / University of Wisconsin / Department of Radiology
% Date created:  February 6, 2013
% Last modified: July 30, 2013

clc;

% VARIABLE DECLARATION
b_data = [];
f_data = [];
b_im = [];
f_im = [];
b_clim_low = [];
b_clim_high = [];
f_clim_low = [];
f_clim_high = [];
b_slice = 1;
f_slice = 1;
b_frame = 1;
f_frame = 1;
b_var_name = [];
f_var_name = [];


cmap = 0;
cmap_name = [];
alphaVal = 0.6;
alphadata = [];

buttonH = 0.06;
buttonW = 0.22;
deltaX = 0.01;
bottonRowY = 0.03;
topRowY = 0.77;


himFront = [];

export_flag = 0;


%  Create and then hide the GUI as it is being constructed.
wwidth = 900;
wheight = 450;

f = figure('Visible','off',...
    'Position',[200,200,wwidth,wheight],...
    'Resize','on',...
    'Color',[0,0,0],...
    'Renderer','opengl',...
    'NumberTitle','off',...
    'MenuBar','none');

if ispc, opengl software;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONSTRUCT THE COMPONENTS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PANELS
panelW = (1-4*deltaX)/3;
panelH = (1-2*deltaX);
b_panel = uipanel('Units','Pixels',...
    'BackgroundColor',[0,0,0],...
    'BorderType','etchedin',...
    'Title','Background',...
    'ForegroundColor','w',...
    'Units','normalized',...
    'FontSize',14,...
    'Position',[deltaX,deltaX,panelW,panelH]);
o_panel = uipanel('Units','pixels',...
    'BackgroundColor',[0,0,0],...
    'BorderType','etchedin',...
    'Title','Overlay',...
    'Units','normalized',...
    'FontSize',14,...
    'ForegroundColor','w',...
    'Position',get(b_panel,'Position')+[2*deltaX+2*panelW,0,0,0]);

% AXES
b_axes = axes('Parent',b_panel,...
    'Units','normalized',...
    'Position',[deltaX,0.15,(1-2*deltaX),0.60],...
    'Color',[1,1,1]);
h_b_im = imagesc(magic(10));
o_axes = axes('Parent',o_panel,...
    'Units','normalized',...
    'Position',[deltaX,0.15,(1-2*deltaX),0.60],...
    'Color',[1,1,1]);

% DROP-DOWN
b_var = uicontrol('Parent',b_panel,...
    'Style','popupmenu',...
    'Callback',@variable_Callback,...
    'BackgroundColor',[1,1,1],...
    'String','Variables',...
    'Units','normalized',...
    'FontSize',12,...
    'Tag','variable',...
    'UserData',1,...
    'Position',[0.2,0.92,2*buttonW,buttonH]);
cmap_selection = uicontrol('Parent',o_panel,...
    'Style','popupmenu',...
    'BackgroundColor',[1,1,1],...
    'Callback',@colormap_selection_Callback,...
    'FontSize',12,...
    'String',{'jet','jet2','jet3','gray','autumn','bone',...
    'colorcube','cool','copper','flag','hot','hsv','hsv2','hsv3',...
    'hsv4','lines','pink','prism','spring','summer','white','winter'},...
    'Units','normalized',...
    'Position',[0.3,0.92,2*buttonW,buttonH]);

% BUTTONS
tmpX = (0.5-deltaX-2*buttonW)/2;
if ~ismac
    buttonColor = [161 188 251]/255;
else
    buttonColor = 'k';
end
buttonFontSize = 12;
b_slice_down = uicontrol('Parent',b_panel,...
    'Style','pushbutton',...
    'Callback',@image_change_Callback,...
    'BackgroundColor',buttonColor,...
    'String','<',...
    'FontSize',buttonFontSize,...
    'Units','normalized',...
    'Tag','slice',...
    'UserData',-1,...
    'Position',[tmpX,topRowY,buttonW,buttonH]);
b_slice_up = uicontrol('Parent',b_panel,...
    'Style','pushbutton',...
    'Callback',@image_change_Callback,...
    'BackgroundColor',buttonColor,...
    'String','>',...
    'FontSize',buttonFontSize,...
    'Units','normalized',...
    'Tag','slice',...
    'UserData',+1,...
    'Position',get(b_slice_down,'Position')+[deltaX+buttonW,0,0,0]);
b_frame_down = uicontrol('Parent',b_panel,...
    'Style','pushbutton',...
    'Callback',@image_change_Callback,...
    'BackgroundColor',buttonColor,...
    'String','<',...
    'FontSize',buttonFontSize,...
    'Units','normalized',...
    'Tag','frame',...
    'UserData',-1,...
    'Position',get(b_slice_down,'Position')+[0.5,0,0,0]);
b_frame_up = uicontrol('Parent',b_panel,...
    'Style','pushbutton',...
    'Callback',@image_change_Callback,...
    'BackgroundColor',buttonColor,...
    'String','>',...
    'FontSize',buttonFontSize,...
    'Units','normalized',...
    'Tag','frame',...
    'UserData',+1,...
    'Position',get(b_slice_up,'Position')+[0.5,0,0,0]);
export_overlay_button = uicontrol('Parent',o_panel,...
    'Style','pushbutton',...
    'Callback',@export_overlay_Callback,...
    'BackgroundColor',buttonColor,...
    'FontSize',buttonFontSize,...
    'String','Export Figure',...
    'Units','normalized',...
    'Position',[tmpX,topRowY,2*buttonW,buttonH]);
display_syntax_button = uicontrol('Parent',o_panel,...
    'Style','pushbutton',...
    'Callback',@display_syntax_Callback,...
    'BackgroundColor',buttonColor,...
    'FontSize',buttonFontSize,...
    'String','Display Syntax',...
    'Units','normalized',...
    'Position',[0.5+tmpX,topRowY,2*buttonW,buttonH]);

% TEXT
textFontSize = 12;
uicontrol('Parent',b_panel,...
    'Style','text',...
    'String','Slice',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.13,0.85,buttonW,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',b_panel,...
    'Style','text',...
    'String','Frame',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.59,0.85,buttonW,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',b_panel,...
    'Style','text',...
    'String','low',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.10,bottonRowY,0.15,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',b_panel,...
    'Style','text',...
    'String','high',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.40,bottonRowY,0.18,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',b_panel,...
    'Style','text',...
    'String','Load',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[.05,0.93,buttonW*.6,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',o_panel,...
    'Style','text',...
    'String','Colormap',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.05,0.93,buttonW,0.04],...
    'HorizontalAlignment','left');
uicontrol('Parent',o_panel,...
    'Style','text',...
    'String','Alpha',...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Position',[0.04,bottonRowY,buttonW,0.04],...
    'HorizontalAlignment','left');


% EDIT BOXES
b_slice_edit = uicontrol('Parent',b_panel,...
    'Style','edit',...
    'Callback',@slice_edit_Callback,...
    'String','1',...
    'BackgroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Tag','slice_edit',...
    'Position',[0.27,0.85,buttonW*.8,buttonH]);
b_frame_edit = uicontrol('Parent',b_panel,...
    'Style','edit',...
    'Callback',@frame_edit_Callback,...
    'String','1',...
    'BackgroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Tag','frame_edit',...
    'Position',[0.77,0.85,buttonW*.8,buttonH]);
b_clim_low_edit = uicontrol('Parent',b_panel,...
    'Style','edit',...
    'Callback',@update_clim_Callback,...
    'String','0',...
    'BackgroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Tag','clim_low_edit',...
    'Position',[0.20,bottonRowY,buttonW*.8,buttonH]);
b_clim_high_edit = uicontrol('Parent',b_panel,...
    'Style','edit',...
    'Callback',@update_clim_Callback,...
    'String','1',...
    'BackgroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Tag','clim_high_edit',...
    'Position',[0.53,bottonRowY,buttonW*.8,buttonH]);
alpha_edit = uicontrol('Parent',o_panel,...
    'Style','edit',...
    'Callback',@update_alpha_edit_Callback,...
    'String','0.6',...
    'BackgroundColor',[1,1,1],...
    'FontSize',textFontSize,...
    'Units','normalized',...
    'Tag','alpha_edit',...
    'Position',[0.74,bottonRowY,buttonW*.8,buttonH]);

% SLIDERS
alpha_slider = uicontrol('Parent',o_panel,...
    'Style','slider',...
    'Callback',@update_alpha_slider_Callback,...
    'BackgroundColor',[1,1,1],...
    'Value',0.6,...
    'Min',0.0001,...
    'SliderStep',[0.05,0.1],...
    'Units','normalized',...
    'Tag','colormap_slider',...
    'Position',[0.2+0.04,bottonRowY,2*buttonW,0.04]);
% addlistener(alpha_slider,'Value','PostSet',@(src,evnt)update_alpha_slider_Callback(src,evnt));
addlistener(alpha_slider,'Value','PostSet',@(src,evnt)update_alpha_slider_edit(src,evnt));


% CHECKBOXES
b_clim_lock = uicontrol('Parent',b_panel,...
    'Style','checkbox',...
    'String','Lock',...
    'Value',0,...
    'BackgroundColor',[0,0,0],...
    'ForegroundColor',[1,1,1],...
    'Units','normalized',...
    'Tag','clim_checkbox',...
    'Position',[0.72 0.03 0.20 0.05]);
% x_stretch_checkbox = uicontrol('Parent',o_panel,...
%     'Style','checkbox',...
%     'String','Stretch (X)',...
%     'Value',1,...
%     'BackgroundColor',[0,0,0],...
%     'ForegroundColor',[1,1,1],...
%     'Units','normalized',...
%     'Tag','x_stretch_checkbox',...
%     'Position',[0.5+deltaX,topRowY+buttonH+deltaX,2*buttonW,buttonH]);
% y_stretch_checkbox = uicontrol('Parent',o_panel,...
%     'Style','checkbox',...
%     'String','Stretch (Y)',...
%     'Value',1,...
%     'BackgroundColor',[0,0,0],...
%     'ForegroundColor',[1,1,1],...
%     'Units','normalized',...
%     'Tag','x_stretch_checkbox',...
%     'Position',[0.5+deltaX,topRowY,2*buttonW,buttonH]);

% MAKE FOREGROUND PANEL BY COPYING BACKGROUND
f_panel = copyobj(b_panel,f);
set(f_panel,...
    'Title','Foreground',...
    'Position',get(b_panel,'Position')+[deltaX+panelW,0,0,0]);
f_axes = findobj(f,'Type','axes','Parent',f_panel);
f_var = findobj(f_panel,'Tag','variable');
f_slice_edit = findobj(f_panel,'Tag','slice_edit');
f_frame_edit = findobj(f_panel,'Tag','frame_edit');
f_clim_low_edit = findobj(f_panel,'Tag','clim_low_edit');
f_clim_high_edit = findobj(f_panel,'Tag','clim_high_edit');
f_clim_lock = findobj(f_panel,'Tag','clim_checkbox');
h_f_im = findobj(f_panel,'Type','image');



% MENU ADDITIONS
hFileMenu = uimenu('Parent',f,...
    'Label','File');
uimenu('Parent',hFileMenu,...
    'Label','Export Figure','Accelerator','E',...
    'Callback',@exportFigure_Callback);
hOptionsMenu = uimenu('Parent',f,...
    'HandleVisibility','callback', ...
    'Label','Options');
uimenu('Parent',hOptionsMenu,...
    'Label','Update Variables From Workspace',...
    'HandleVisibility','callback', ...
    'Accelerator','U',...
    'Callback', @menu_update_variables_Callback);

%%%%%%%%%%%%%%% INITIALIZE THE GUI %%%%%%%%%%%%%%%%%%%
% Initialize the GUI.
init( );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Functions and Callbacks %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function init()
        
        cmap_name = 'jet2';
        set(cmap_selection,'Value',2); % jet2
        cmap = eval(['colormap(' cmap_name ')']);
        colormap(f_axes,cmap);
        
        update_variables( );
        update_b_data( );
        update_f_data( );
        alphaVal = 0.6;
        set(alpha_edit,'String',num2str(alphaVal));
        set(alpha_slider,'Value',alphaVal);        
        
        % Assign the GUI a name to appear in the window title.
        set(f,'Name','IMOVERLAY Tool');
        
        % Make the GUI visible.
        set(f,'Visible','on');
        
        
    end

    function update_variables( )
        vars = evalin('base','who');
        if isempty(vars)
            vars = {'variables'};
        else
            vars = [{'variables'};vars];
        end
        set(b_var,'String',vars);
        set(f_var,'String',vars);
    end

    function menu_update_variables_Callback(source,eventdata)
        update_variables();
    end

    function exportFigure_Callback(source,eventdata)
        export_flag = 1;
        update_o_image;
    end

    function update_b_data( )
        contents = get(b_var,'String');
        b_var_name = contents{get(b_var,'Value')};
        
        if strcmp(b_var_name,'variables')
            b_data = phantom(256);
            b_clim_low = 0;
            b_clim_high = 0.6;
            b_slice = 1;
            b_frame = 1;
            set(b_clim_lock,'Value',1);
        else
            b_data = evalin('base',b_var_name);
            b_data = double(b_data); % for mat2gray( )
            
            if length(size(b_data)) < 2
                errordlg('Back image needs to be at least 2D!');
            end
            b_slice = str2num(get(b_slice_edit,'String'));
            b_frame = str2num(get(b_frame_edit,'String'));
            
            if size(b_data,3) < b_slice
                b_slice = 1;
            end
            if size(b_data,4) < b_frame
                b_frame = 1;
            end  
            
            b_im = b_data(:,:,b_slice,b_frame);
            b_clim_low = min(b_im(:));
            b_clim_high = max(b_im(:));
            set(b_clim_lock,'Value',0);
        end
        set(b_slice_edit,'String',num2str(b_slice));
        set(b_frame_edit,'String',num2str(b_frame));
        set(b_clim_low_edit,'String',num2str(b_clim_low));
        set(b_clim_high_edit,'String',num2str(b_clim_high));
        
        % Init so changes to slice or frame just changes CData
        im = repmat(mat2gray(b_data(:,:,b_slice,b_frame),[b_clim_low,b_clim_high]),[1,1,3]);
        set(h_b_im,'CData',im);
        axis(b_axes,'image','off');
        
        update_b_image( );
    end

    function update_b_image( )        
        % Update the back image 
        b_slice = str2num(get(b_slice_edit,'String'));
        b_frame = str2num(get(b_frame_edit,'String'));
        
        b_im = double(b_data(:,:,b_slice,b_frame));
        
        if get(b_clim_lock,'Value') == 0
            b_clim_low = min(b_im(:));
            b_clim_high = max(b_im(:));
            set(b_clim_low_edit,'String',num2str(b_clim_low));
            set(b_clim_high_edit,'String',num2str(b_clim_high));
        end
        
        im = repmat(mat2gray(b_im,[b_clim_low,b_clim_high]),[1,1,3]);
        set(h_b_im,'CData',im);
        update_o_image( );
    end

    function update_f_data( )
        contents = get(f_var,'String');
        f_var_name = contents{get(f_var,'Value')};
        
        if strcmp(f_var_name,'variables')
            f_data = rgb2gray(imread('ngc6543a.jpg'));
            f_clim_low = 40;
            f_clim_high = 180; 
            f_slice = 1;
            f_frame = 1; 
            set(f_clim_lock,'Value',1);
        else
            f_data = evalin('base',f_var_name);
            
            if length(size(f_data)) < 2
                errordlg('Front image needs to be at least 2D!');
            end
            f_slice = str2num(get(f_slice_edit,'String'));
            f_frame = str2num(get(f_frame_edit,'String'));
            
            if size(f_data,3) < f_slice
                f_slice = 1;
            end
            if size(f_data,4) < f_frame
                f_frame = 1;
            end
            
            f_im = f_data(:,:,f_slice,f_frame);
            f_clim_low = min(f_im(:));
            f_clim_high = max(f_im(:));
            set(f_clim_lock,'Value',0);
        end
        set(f_slice_edit,'String',num2str(f_slice));
        set(f_frame_edit,'String',num2str(f_frame));
        set(f_clim_low_edit,'String',num2str(f_clim_low));
        set(f_clim_high_edit,'String',num2str(f_clim_high));
        
        % Init so changes to slice or frame just changes CData
        set(h_f_im,'CData',f_data(:,:,f_slice,f_frame));
        set(f_axes,'Clim',[f_clim_low,f_clim_high]);
        axis(f_axes,'image','off');
        
        update_f_image( );
    end

    function update_f_image( )
        % Update the front image   
        
        f_slice = str2num(get(f_slice_edit,'String'));
        f_frame = str2num(get(f_frame_edit,'String'));
        
        f_im = f_data(:,:,f_slice,f_frame);

        if get(f_clim_lock,'Value') == 0
            f_clim_low = min(f_im(:));
            f_clim_high = max(f_im(:));
            set(f_clim_low_edit,'String',num2str(f_clim_low));
            set(f_clim_high_edit,'String',num2str(f_clim_high));
            set(f_axes,'Clim',[f_clim_low,f_clim_high]);
        end
        set(h_f_im,'CData',f_im);
        update_o_image( );
        
    end

    function update_o_image( )               
        if isempty(b_data) || isempty(f_data), return; end
        
        b_im = b_data(:,:,b_slice,b_frame);
        f_im = f_data(:,:,f_slice,f_frame);
        b_clim = [b_clim_low,b_clim_high];
        f_clim = [f_clim_low,f_clim_high];
                
        if export_flag            
            imoverlay(b_im,f_im,f_clim,b_clim,cmap_name,alphaVal,[]);
            export_flag = 0;
        else
            [himFront,himBack] = imoverlay(...
                b_im,f_im,f_clim,b_clim,cmap_name,alphaVal,o_axes);
            
            alphadata = single(get(himFront,'AlphaData')~=0);            
            axis(o_axes,'image','off');
        end
              
    end

    function colormap_selection_Callback(source, eventdata)
        contents = get(source,'String');
        cmap_name = contents{get(source,'Value')};
        cmap = eval(cmap_name);
        colormap(f_axes,cmap);
    end


    function update_clim_Callback(source,eventdata)
        
        if get(source,'Parent') == b_panel           
            newlow = str2num(get(b_clim_low_edit,'String'));
            if isempty(newlow)
                set(b_clim_low_edit,'String',num2str(b_clim_low));
            else
                b_clim_low = newlow;
            end
            
            newhigh = str2num(get(b_clim_high_edit,'String'));
            if isempty(newhigh)
                set(b_clim_high_edit,'String',num2str(b_clim_high));
            else
                b_clim_high = newhigh;
            end
            
            b_im = double(b_data(:,:,b_slice,b_frame));
            im = repmat(mat2gray(b_im,[b_clim_low,b_clim_high]),[1,1,3]);
            set(h_b_im,'CData',im);
        else
            newlow = str2num(get(f_clim_low_edit,'String'));
            if isempty(newlow)
                set(f_clim_low_edit,'String',num2str(f_clim_low));
            else
                f_clim_low = newlow;
            end
            
            newhigh = str2num(get(f_clim_high_edit,'String'));
            if isempty(newhigh)
                set(f_clim_high_edit,'String',num2str(f_clim_high));
            else
                f_clim_high = newhigh;
            end
            set(f_axes,'CLim',[f_clim_low,f_clim_high]);
        end
        update_o_image( );
    end


    function variable_Callback(source, eventdata)
        
              
        % Check if real
        contents = get(source,'String');
        var_name = contents{get(source,'Value')};
        if evalin('base',['isreal(',var_name,')']) && ...
                evalin('base',['isnumeric(',var_name,')']) && ...
                evalin('base',['size(',var_name,',2)']) >=2 || ...
                strcmp(var_name,'variables')
            cla(o_axes);
            if get(source,'Parent')==b_panel, update_b_data( );end
            if get(source,'Parent')==f_panel, update_f_data( );end
            set(source,'UserData',get(source,'Value'));
        else            
            errordlg('Images must be numeric, real, and at least 2D.', 'Error', 'modal');
            set(source,'Value',get(source,'UserData'));            
        end  
                 
    end

    function slice_edit_Callback(source, eventdata)
        
        new = round(str2num(get(source,'String')));
        
        if get(source,'Parent') == b_panel
            if isempty(new) || new > size(b_data,3) || new < 1
                set(source,'String',num2str(b_slice));
            else
                set(source,'String',num2str(new)); % ensure integer
                update_b_image( );
            end            
        elseif get(source,'Parent') == f_panel            
            if isempty(new) || new > size(f_data,3) || new < 1
                set(source,'String',num2str(f_slice));
            else
                set(source,'String',num2str(new)); % ensure integer
                update_f_image( );
            end            
        end
        
    end

    function frame_edit_Callback(source, eventdata)
        
        new = round(str2num(get(source,'String')));
        
        if get(source,'Parent') == b_panel
            if isempty(new) || new > size(b_data,4) || new < 1
                set(source,'String',num2str(b_frame));
            else
                set(source,'String',num2str(new)); % ensure integer
                update_b_image( );
            end            
        elseif get(source,'Parent') == f_panel            
            if isempty(new) || new > size(f_data,4) || new < 1
                set(source,'String',num2str(f_frame));
            else
                set(source,'String',num2str(new)); % ensure integer
                update_f_image( );
            end            
        end
        
    end


    function image_change_Callback(source, eventdata)

        if get(source,'Parent') == b_panel && strcmp(get(source,'Tag'),'slice')
            h_edit = b_slice_edit;
            maxSize = size(b_data,3);
        elseif get(source,'Parent') == b_panel && strcmp(get(source,'Tag'),'frame')
            h_edit = b_frame_edit;
            maxSize = size(b_data,4);
        elseif get(source,'Parent') == f_panel && strcmp(get(source,'Tag'),'slice')
            h_edit = f_slice_edit;
            maxSize = size(f_data,3);
        elseif get(source,'Parent') == f_panel && strcmp(get(source,'Tag'),'frame')
            h_edit = f_frame_edit;
            maxSize = size(f_data,4);
        end            
           
        cur = str2num(get(h_edit,'String'));
        new = cur + get(source,'UserData');
        
        if new > maxSize || new < 1, return; end
        
        set(h_edit,'String',num2str(new));
              
        if get(source,'Parent') == b_panel
            update_b_image( );
        else
            update_f_image( );
        end
        
    end

    function update_alpha_slider_Callback(source, eventdata)               
        alphaVal = get(alpha_slider,'Value');    
        set(alpha_edit,'String',sprintf('%0.3f',alphaVal));
        
        if ishandle(himFront) 
            set(himFront,'AlphaData',alphadata.*alphaVal);
        end
    end

    function update_alpha_slider_edit(source, eventdata)
        set(alpha_edit,'String',sprintf('%0.3f',get(alpha_slider,'Value')));
    end

    function update_alpha_edit_Callback(source, eventdata)
        newalpha = str2num(get(source,'String'));
        if isempty(newalpha)
            set(source,'String',num2str(alphaVal));
        else
            alphaVal = max(newalpha,0.001);
            set(alpha_slider,'Value',alphaVal);
            if ishandle(himFront), set(himFront,'AlphaData',alphadata.*alphaVal);end
        end
    end

    function export_overlay_Callback(source, eventdata)
        export_flag = 1;
        update_o_image( );
    end

    function display_syntax_Callback(source, eventdata)
        % Print command one would use to replicate the overlay in
        % command line
        if strcmp(b_var_name,'variables')
            tmp_b_var_name = 'phantom(256)';
        else
            tmp_b_var_name = sprintf('%s(:,:,%d,%d)',b_var_name,b_slice,b_frame);
        end
        
        if strcmp(f_var_name,'variables')
            tmp_f_var_name = 'rgb2gray(imread(''ngc6543a.jpg''))';
        else
            tmp_f_var_name = sprintf('%s(:,:,%d,%d)',f_var_name,f_slice,f_frame);
        end
        
        
        cmd = sprintf('[hFront,hBack] = imoverlay(%s,%s,[%s,%s],[%s,%s],''%s'',%s);\n',...
            tmp_b_var_name,tmp_f_var_name,num2str(f_clim_low),num2str(f_clim_high),num2str(b_clim_low),...
            num2str(b_clim_high),cmap_name,num2str(alphaVal));
                
        fprintf('\nCommand line syntax:\n%s',cmd);
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


% HSV2    is the same as HSV but with black base
    function map = hsv2(m)
        map =hsv;
        map(1,:) = [0,0,0];
    end

% HSV3     is the same as HSV but with white base
    function map = hsv3(m)
        map =hsv;
        map(1,:) = [1,1,1];
    end

% HSV4    a slight modification of hsv (Hue-saturation-value color map)
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