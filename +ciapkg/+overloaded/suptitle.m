function hout=suptitle(str,varargin)
    % biafra ahanonu
    % started updating: 2016.03.10
    % this is an overloaded suptitle to remove focus stealing

    %SUPTITLE puts a title above all subplots.
    %
    %	SUPTITLE('text') adds text to the top of the figure
    %	above all subplots (a "super title"). Use this function
    %	after all subplot commands.
    %
    %   SUPTITLE is a helper function for yeastdemo.

    %   Copyright 2003-2010 The MathWorks, Inc.


    % Warning: If the figure or axis units are non-default, this
    % will break.
	% changelog
		% 2023.08.08 [05:27:57] - Added font name option

    %========================
    % Amount of the figure window devoted to subplots
    options.plotregion = 0.94;
    % Y position of title in normalized coordinates
    options.titleypos = 0.96;
    % font size
    options.fontSize = [];
    % Str or rgb vector: color of suptitle
    options.Color = 'k';
	% Str: interpreter, latex or tex
	options.Interpreter = 'latex';
	% Str: Name of font family, e.g. Consolas.
	options.fontName = [];
    % get options
    options = ciapkg.io.getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % Parameters used to position the supertitle.

    % Amount of the figure window devoted to subplots
    plotregion = options.plotregion;

    % Y position of title in normalized coordinates
    titleypos  = options.titleypos;

    % Fontsize for supertitle
    if isempty(options.fontSize)
        fs = get(gcf,'defaultaxesfontsize')+4;
    else
        fs = options.fontSize;
    end

    % Fudge factor to adjust y spacing between subplots
    fudge=1;

    haold = gca;
    figunits = get(gcf,'units');

    % Get the (approximate) difference between full height (plot + title
    % + xlabel) and bounding rectangle.

    if (~strcmp(figunits,'pixels')),
        set(gcf,'units','pixels');
        pos = get(gcf,'position');
        set(gcf,'units',figunits);
    else
        pos = get(gcf,'position');
    end
    ff = (fs-4)*1.27*5/pos(4)*fudge;

    % The 5 here reflects about 3 characters of height below
    % an axis and 2 above. 1.27 is pixels per point.

    % Determine the bounding rectangle for all the plots

    % h = findobj('Type','axes');

    % findobj is a 4.2 thing.. if you don't have 4.2 comment out
    % the next line and uncomment the following block.

    h = findobj(gcf,'Type','axes');  % Change suggested by Stacy J. Hills

    max_y=0;
    min_y=1;
    oldtitle = NaN;
    numAxes = length(h);
    thePositions = zeros(numAxes,4);
    for i=1:numAxes
        pos=get(h(i),'pos');
        thePositions(i,:) = pos;
        if (~strcmp(get(h(i),'Tag'),'suptitle')),
            if (pos(2) < min_y)
                min_y=pos(2)-ff/5*3;
            end;
            if (pos(4)+pos(2) > max_y)
                max_y=pos(4)+pos(2)+ff/5*2;
            end;
        else
            oldtitle = h(i);
        end
    end
    if max_y > plotregion,
        scale = (plotregion-min_y)/(max_y-min_y);
        for i=1:numAxes
            pos = thePositions(i,:);
            pos(2) = (pos(2)-min_y)*scale+min_y;
            pos(4) = pos(4)*scale-(1-scale)*ff/5*3;
            set(h(i),'position',pos);
        end
    end

    np = get(gcf,'nextplot');
    set(gcf,'nextplot','add');
    if ishghandle(oldtitle)
        delete(oldtitle);
    end
    warning off
    axes('pos',[0 1 1 1],'visible','off','Tag','suptitle','SortMethod','depth');
    warning on
    ht = text('position',[.5 titleypos-1],'Interpreter',options.Interpreter,'String',str);
	set(ht,'horizontalalignment','center','fontsize',fs,'Color',options.Color);
	if ~isempty(options.fontName)
		set(ht,'FontName',options.fontName);
	else
		set(ht,'FontName',get(0,'DefaultAxesFontName'));
	end
    set(gcf,'nextplot',np);
    % focus stealing occurs here, turn off
    set(gcf, 'CurrentAxes', haold)
    % axes(haold); %#ok<MAXES>
    if nargout,
        hout=ht;
    end
end