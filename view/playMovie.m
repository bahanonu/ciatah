function [exitSignal ostruct] = playMovie(inputMovie, varargin)
	% Plays a 3D matrix as a movie, additional inputs to view multiple movies or sync'd signal data; can also save the resulting figure as a movie.
	% Biafra Ahanonu
	% started 2013.11.09 [10:39:50]
	% inputs
		% inputMovie - [X Y Z] matrix of X,Y height/width and Z frames
	% options
		% fps -
		% extraMovie - extra movie to play, [X Y Z] matrix of X,Y height/width and Z frames
		% extraLinePlot - add a line-plot that is synced with the movie, [S Z] with S signals and Z frames
		% windowLength - length of the window over which to show the line-plot
		% recordMovie - whether to record the current movie or not
		% nFrames - number of frames to analyze

	% changelog
		% 2013.11.13 [21:30:53] can now pre-maturely exit the movie, 21st century stuff
		% 2014.01.18 [19:09:14] several improvements to how extraLinePlot is displayed, now loops correctly
		% 2014.02.19 [12:13:36] added dfof and normalization to list of movie modifications
		% 2014.03.21 [00:43:22] can now label

	% ========================
	% options
	% frame frame
	options.fps = 20;
	% Set the min/max FPS
	% To get around issues with Matlab drawing too fast to detect key strokes, set to 60 or below.
	options.fpsMax = 60;
	options.fpsMin = 1/10;
	% additional movie to show
	options.extraMovie = [];
	% 2D matrix of [signals frames] signals
	options.extraLinePlot = [];
	% legend for the lineplot
	options.extraLinePlotLegend = [];
	% cell of strings input this to label an inputMovie based on
	options.labelLegend = [];
	% whetner lineplot should be colored
	options.colorLinePlot = 0;
	% length of the window over which to view the line plot
	options.windowLength = 30;
	% whether to save the figure as a movie, put a string for the movie location
	options.recordMovie = 0;
	% number of frames to show
	options.nFrames = 0;
	% default colormap
	options.colormapColor = 'whiteRed';
	% colormap indx
	options.colormapIdx = 1;
	% list of different colormaps
	options.colormapColorList = {'gray','jet','hot','hsv','copper'};
	% extra text
	options.extraTitleText = [];
	% add a point to the main movie, [xpos ypos]
	options.primaryPoint = [];
	% add a point to the secondary movie, [xpos ypos-]
	options.secondaryPoint = [];
	% [xpos ypos angle(degrees) magnitude] matrix with rows = frames, magnitude is optional
	options.primaryTrackingPoint = [];
	%
	options.primaryTrackingPointColor = 'r';
	% [xpos ypos angle(degrees) magnitude] matrix with rows = frames, magnitude is optional
	options.secondaryTrackingPoint = [];
	%
	options.secondaryTrackingPointColor = 'k';
	%
	options.downsampleFactor = 4;
	% pre-set the min/max for movie display
	options.movieMinMax = [];
	% Binary: 1 = directly run imagej
	options.runImageJ = 0;
	% get options
	options = getOptions(options,varargin);
	% options
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	if ~isempty(options.extraMovie)|~isempty(options.extraLinePlot)
		options.fpsMax = 30;
	end
	% clc
	% add custom colormap
	t = [255, 0, 0]./255;
	color1 = [1 1 1];
	color2 = [0 0 1];
	% color1 = [0 0 0];
	R = [linspace(color1(1),color2(1),50) linspace(color2(1),t(1),50)];
	G = [linspace(color1(2),color2(2),50) linspace(color2(2),t(2),50)];
	B = [linspace(color1(3),color2(3),50) linspace(color2(3),t(3),50)];
	redWhiteMap = [R', G', B'];
	[outputColormap2] = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
	outputColormap3 = diverging_map([0:0.01:1],[0 0 0.7],[0.7 0 0]);
	outputColormap4 = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
	if strcmp(options.colormapColor,'whiteRed')
		% outputColormap2 = customColormap([]);
		outputColormap = diverging_map([0:0.01:1],[0 0 1],[1 0 0]);
		options.colormapColor = outputColormap;
		% options.colormapIdx = 0;
	end
	% grayRed = customColormap({[0 0 0],[0.5 0.5 0.5],[1 1 1],[0.7 0.4 0.4],[0.7 0.3 0.3],[0.7 0.2 0.2],[0.7 0.1 0.1],[0.7 0 0],[1 0 0]});
	grayRed = customColormap({[0 0 0],[0.5 0.5 0.5],[1 1 1],[0.7 0.2 0.2],[1 0 0]});
	options.colormapColorList = [...
		outputColormap2,...
		grayRed,...
		options.colormapColor,...
		outputColormap4,...
		outputColormap3,...
		{'gray'},...
		options.colormapColor,...
		redWhiteMap,...
		options.colormapColorList];
	% options.colormapColorList
	% ========================
	if options.nFrames==0
		nFrames = size(inputMovie,3);
	else
		nFrames = options.nFrames;
	end

	% pass to calling functions, in case you want to exit an upper-level loop
	exitSignal = 0;

	fig1 = figure(42);
	clf
	set(findobj(gcf,'type','axes'),'hittest','off')

	% close(fig1);fig1 = figure(42);
	if isempty(options.extraTitleText)
		options.extraTitleText = '';
	else
		options.extraTitleText = [10,options.extraTitleText];
	end
	supTitleStr = [10,10,10,10,'e:exit    q:exit all    g:goto frame    p:pause/play    r:rewind    f:forward    j:contrast    l:label    i:imagej',10,'c:crop    d:\DeltaF/F    a:downsample    n:normalize    m:\Deltacolormap    +:speed    -:slow    ]:+1 frame    [:-1 frame    dims: ' num2str(size(inputMovie)),'    ',strrep(options.extraTitleText,'\','/'),10,repmat(' ',1,7),10,10];
	display(strrep(supTitleStr,'    ', 10 ))
	% supTitleStr
	% suptitleHandle = suptitle(strrep(strrep('/','\',supTitleStr),'_','\_'));
	suptitleHandle = suptitle(supTitleStr);
	set(suptitleHandle,'FontSize',10,'FontWeight','normal')
	hold off;
	imagesc(squeeze(inputMovie(:,:,1)))
	% imcontrast

	% get current key information
	thisKey=1;
	% set(fig1,'keypress','thisKey=get(gcf,''CurrentCharacter'');');
	% set(fig1,'KeyPressFcn','keydown=1;');
	% keydown = 0;
	% set(fig1,'KeyPressFcn', '1;');
	set(fig1,'KeyPressFcn', @detectKeyPress);
	set(gcf,'currentch','3');
	keyIn = get(gcf,'CurrentCharacter');

    % change colormap
    options.colormapColor = options.colormapColorList{options.colormapIdx};
    colormap(options.colormapColor);

    % setup subplots
	subplotNumPlots = sum([~isempty(options.extraMovie) ~isempty(options.extraLinePlot)])+1;
	subplotRows = 1;
	if ~isempty(options.extraLinePlot)
		subplotRows = 2;
	end
	subplotCols = 2;

	% open object to record movie if set
	if options.recordMovie~=0
		writerObj = VideoWriter(options.recordMovie);
		open(writerObj);
	end

	% while loop to allow forward, back, skipping around
	dirChange = 1;
	frame=1;
	loopSignal = 1;
	loopCounter = 1;
	labelCounter = 1;
	% set(fig1,'doublebuffer','off');
	ostruct.labelArray.time = {};
	ostruct.labelArray.id = {};


	nLabels = length(options.labelLegend);
	if ~isempty(options.labelLegend)&~any(strcmp('labelMatrix',fieldnames(ostruct)))
	    ostruct.labelMatrix = zeros([nLabels nFrames]);
	    options.extraLinePlot = zeros([nLabels nFrames]);
	    toggleState = zeros([nLabels 1]);
	    subplotRows = 2;
	    options.colorLinePlot=1;
	    impulseState = 1;
	    subplot(subplotRows,subplotCols,2)
	    plot(options.extraLinePlot(:,1:10)'); box off;
	    legend(options.labelLegend);
	    % options.extraLinePlotLegend = options.labelLegend;
	end
	% use for references to keep contrast stable across frames
	firstFrame = squeeze(inputMovie(:,:,1));
	maxAdjFactor = 1;
	maxMovie(1) = nanmax(inputMovie(:));
	minMovie(1) = nanmin(inputMovie(:));
	if ~isempty(options.extraMovie)
		maxMovie(2) = nanmax(options.extraMovie(:));
		minMovie(2) = nanmin(options.extraMovie(:));
	end
	if ~isempty(options.movieMinMax)
		minMovie(1) = options.movieMinMax(1);
		maxMovie(1) = options.movieMinMax(2);
		minMovie(2) = options.movieMinMax(1);
		maxMovie(2) = options.movieMinMax(2);
	end
	try
		while loopSignal==1
			% [figHandle figNo] = openFigure(42, '');
			% =====================
			if options.runImageJ==1;
				subfxn_imageJ(inputMovie);
				% Run once else loops without exit
				options.runImageJ = 0;
			end
		    if ~isempty(options.extraMovie)
		    	subplotNum = [1];
		    	subplot(subplotRows,subplotCols,subplotNum)
		    end
		    if ~isempty(options.extraLinePlot)
				subplotNum = [1 3];
		    	subplot(subplotRows,subplotCols,subplotNum)
		    	% set(gca, 'Position', get(gca, 'OuterPosition') - ...
		    	    % get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
		    end
		    % display an image from the movie
		    thisFrame = squeeze(inputMovie(:,:,frame));
		 %    if frame==1
		 %    	set(gca, 'xlimmode','manual',...
		 %               'ylimmode','manual',...
		 %               'zlimmode','manual',...
		 %               'climmode','manual',...
		 %               'alimmode','manual');
			% end
		    % thisFrame = imadjust(I,[0 1],[0 1]);
		    % keep contrast stable across frames.
		    thisFrame(1,1) = maxMovie(1)*maxAdjFactor;
		    thisFrame(1,2) = minMovie(1);
		    imagesc(thisFrame);
		    try
		        caxis([minMovie(1) maxMovie(1)]);
		    catch
		        caxis([-0.05 0.1]);
		    end
		    % imagesc(imhistmatch(thisFrame,firstFrame));
		    % imagesc(imadjust(thisFrame));
		    % text(15, 15, 'hello','color','w',...
		        % 'HorizontalAlignment','center','VerticalAlignment','middle');
		    % toc
		    % axis off;
		    axis square;
		    % axis image;
		    xlabel(['skip: ' num2str(options.fps*dirChange), ' frames    frame: ' num2str(frame) '/' num2str(size(inputMovie,3)) '    fps: ' num2str(options.fps*dirChange)])
		    % title(['skip: ' num2str(options.fps*dirChange), ' frames    frame: ' num2str(frame) '/' num2str(size(inputMovie,3)) '    fps: ' num2str(options.fps*dirChange)]);
		    % colorbar
		    hold on;
		    if ~isempty(options.primaryPoint)


		    	if length(options.primaryPoint(:,1))==1
		    		xpt1 = options.primaryPoint(:,1);
		    		ypt1 = options.primaryPoint(:,2);
		    		offSet = 5;
		    		% horizontal
					line([1 xpt1-offSet],[ypt1 ypt1],'Color','k','LineWidth',1)
		    		line([xpt1+offSet size(inputMovie,2)],[ypt1 ypt1],'Color','k','LineWidth',1)
		    		% vertical
		    		line([xpt1 xpt1],[1 ypt1-offSet],'Color','k','LineWidth',1)
		    		line([xpt1 xpt1],[ypt1+offSet size(inputMovie,1)],'Color','k','LineWidth',1)

		    		% plot(options.primaryPoint(:,1), options.primaryPoint(:,2), 'k+', 'Markersize', 10)
		    	else
		    		plot(options.primaryPoint(:,1), options.primaryPoint(:,2), 'k.', 'Markersize', 10)
		    	end
		    end
		    if ~isempty(options.primaryTrackingPoint)
		    	plot(options.primaryTrackingPoint(frame,1), options.primaryTrackingPoint(frame,2), [options.primaryTrackingPointColor '+'], 'Markersize', 17)
		    	if size(options.primaryTrackingPoint,2)>3
		    		r = options.primaryTrackingPoint(frame,4);
		    	else
		    		r = 30; % magnitude (length) of arrow to plot
		    	end
		    	u = -r*cos(options.primaryTrackingPoint(frame,3)*(pi/180));
		    	v = r*sin(options.primaryTrackingPoint(frame,3)*(pi/180));

		    	quiver(options.primaryTrackingPoint(frame,1), options.primaryTrackingPoint(frame,2), u, v,'MaxHeadSize',10,'AutoScaleFactor',1,'AutoScale','off','color',options.primaryTrackingPointColor,'linewidth',2)
		    end
		    if ~isempty(options.secondaryTrackingPoint)
		    	plot(options.secondaryTrackingPoint(frame,1), options.secondaryTrackingPoint(frame,2), [options.secondaryTrackingPointColor '+'], 'Markersize', 17)

		    	if size(options.secondaryTrackingPoint,2)>3
		    		r = options.secondaryTrackingPoint(frame,4);
		    	else
		    		r = 30; % magnitude (length) of arrow to plot
		    	end
		    	u = -r*cos(options.secondaryTrackingPoint(frame,3)*(pi/180));
		    	v = r*sin(options.secondaryTrackingPoint(frame,3)*(pi/180));

		    	quiver(options.secondaryTrackingPoint(frame,1), options.secondaryTrackingPoint(frame,2), u, v,'MaxHeadSize',10,'AutoScaleFactor',1,'AutoScale','off','color',options.secondaryTrackingPointColor,'linewidth',2)
		    end
		    hold off
			% =====================
		    % if user has an extra movie
		    if ~isempty(options.extraMovie)
		    	% subplotNum = subplotNum+1;
		    	subplotNum = 2;
		    	subplot(subplotRows,subplotCols,subplotNum)
		    	% set(gca, 'Position', get(gca, 'OuterPosition') - ...
		    	    % get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
		    	% imagesc(imcomplement(squeeze(options.extraMovie(:,:,frame))));
		    	extraMovieFrame = squeeze(options.extraMovie(:,:,frame));
		    	% normalize contrast across frames
		    	extraMovieFrame(1,1) = maxMovie(2)*maxAdjFactor;
		    	extraMovieFrame(1,2) = minMovie(2);
		    	imagesc(extraMovieFrame);
		    	try
		    	    caxis([minMovie(2) maxMovie(2)]);
		    	catch
		    	    caxis([-0.05 0.1]);
		    	end
		    	% axis off;
		    	axis square;
		    	xlabel(['frame: ' num2str(frame) '/' num2str(size(options.extraMovie,3)) ' | fps: ' num2str(options.fps*dirChange)])
		    	% title(['frame: ' num2str(frame) '/' num2str(size(options.extraMovie,3)) ' | fps: ' num2str(options.fps*dirChange)]);
		    	% plot(x,y,'r'); box off; hold off;
		    	% axis image;
		    	hold on;
		    	if ~isempty(options.secondaryPoint)
		    		if length(options.secondaryPoint(:,1))==1
		    			plot(options.secondaryPoint(:,1), options.secondaryPoint(:,2), 'k+', 'Markersize', 42)
		    		else
		    			plot(options.secondaryPoint(:,1), options.secondaryPoint(:,2), 'k.', 'Markersize', 10)
		    		end
		    	end
		    	hold off
		    end
		    % =====================
		    % if user wants a lineplot to also be shown
		    if ~isempty(options.extraLinePlot)
		    	% increment subplot
		    	% subplotNum = subplotNum+1;
		    	subplotNum = [4];
		    	subplot(subplotRows,subplotCols,subplotNum);cla
		    	% set(gca, 'Position', get(gca, 'OuterPosition') - ...
		    	    % get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
		    	if frame<options.windowLength
		    		% frame = options.windowLength;
		    		linewindow = [(nFrames-options.windowLength+frame):nFrames 1:(1+options.windowLength+frame)];
		    	elseif frame>=(nFrames-options.windowLength)
		    		% frame=nFrames;
		    		% linewindow = frame:nFrames;
		    		linewindow = [(frame-options.windowLength):nFrames 1:(1+options.windowLength-(nFrames-frame))];
		    	else
			    	linewindow = (frame-options.windowLength):(frame+options.windowLength);
		    	end
		    	linewindow = linewindow(find(linewindow>0));
		    	linewindowX = linspace(-options.windowLength,options.windowLength,length(linewindow));

		    	try
			    	if options.colorLinePlot==1
			    		plot(linewindowX,options.extraLinePlot(:,linewindow)'); hold on;
			    	else
			    		plot(linewindowX,options.extraLinePlot(:,linewindow)','k'); hold on;
			    	end
			    catch
			    	display('out of range!');
		    		% err
					% display(repmat('@',1,7))
					% disp(getReport(err,'extended','hyperlinks','on'));
					% display(repmat('@',1,7))
			    end

		    	% colormap gray
		    	ylim([-0.05 max(max(options.extraLinePlot))]);
		    	xval = 0;
		    	x=[xval,xval];
		    	y=[-0.05 max(max(options.extraLinePlot))];
		    	plot(x,y,'r'); box off; hold on
		    	% hold off;
		    	if ~isempty(options.extraLinePlotLegend)
		    		try
		    			legend(options.extraLinePlotLegend);
		    			% set(gca,'LegendColorbarListeners',[]);
		    			% setappdata(gca,'LegendColorbarManualSpace',1);
		    			% setappdata(gca,'LegendColorbarReclaimSpace',1);
		    		catch
		    		end
		    	end
		    	hold off;
		    	% grid on
		    	xlabel('frames');
		    end
		    % =====================
		    if options.recordMovie~=0
		    	% j = getframe(fig1);
		    	writeVideo(writerObj,getframe(fig1));
		    	% outputMovie(frame) = getframe(fig1);
			end
			% =====================
			% [x,y,reply]=ginput(1);
			clearKey = 1;
		    pause(1/options.fps);
		    if options.fps>options.fpsMax
		    	options.fps = options.fpsMax;
		    end
		    if options.fps<options.fpsMin
		    	options.fps = options.fpsMin;
		    end
			keyIn = get(gcf,'CurrentCharacter');
			if isempty(double(keyIn))
				keyIn = '/';
			else
				% double(keyIn)
			end
			% =====================
			switch double(keyIn)
				case 105
					subfxn_imageJ(inputMovie)
				case 101 %'e' %user wants to exit
					set(gcf,'currentch','3');
					% set(gcf,'CurrentCharacter','');
					loopSignal = 0;
					% break;
				case 48 %0 %user wants to exit
					set(gcf,'currentch','3');
					% set(gcf,'CurrentCharacter','');
					loopSignal = 0;
					% break;
				case 113 %'q' %user wants to send a kill signal up
					set(gcf,'currentch','3');
					exitSignal = 1;
					loopSignal = 0;
					% break;
				case 49 %'1' %skip
					if options.fps==1
						options.fps = 60;
					else
						options.fps = 1;
					end

				case 115 %'s' %skip
					frame = frame+dirChange*round(options.fps);
				case 112 %'p' %pause
					% dirChange = 0;
					ginput(1);
				case 29 %backarrow
					dirChange = 1;
					clearKey = 0;
					ginput(1);
				case 28 %forward arrow
					dirChange = -1;
					clearKey = 0;
					ginput(1);
				case 114 %'r' %rewind
					dirChange = -1;
				case 102 %'f' %forward
					dirChange = 1;
				case 106 %'j' %change contrast
					[usrIdxChoice ok] = getUserMovieChoice({'optimal','1st movie','2nd movie','1st->2nd','2nd->1st'});
					if usrIdxChoice==4
						maxMovie(2) = maxMovie(1);
						minMovie(2) = minMovie(1);
					elseif usrIdxChoice==5
						maxMovie(1) = maxMovie(2);
						minMovie(1) = minMovie(2);
					elseif usrIdxChoice==1
						maxMovie(1) = 0.1;
						minMovie(1) = -0.03;
					else
						% since optimal is first, adjust to be correct
						usrIdxChoice = usrIdxChoice-1;
						answer = inputdlg({'max','min'},'Movie min/max for contrast',1,{num2str(maxMovie(usrIdxChoice)),num2str(minMovie(usrIdxChoice))})
						maxMovie(usrIdxChoice) = str2num(answer{1});
						minMovie(usrIdxChoice) = str2num(answer{2});
					end
				case 108 %'l' %label frame
					if ~isempty(options.labelLegend)
						[labelID, ok] = listdlg('ListString',options.labelLegend,'PromptString','toggle label(s), can select multiple to switch','ListSize' ,[400 350]);
						[impulseState, ok] = listdlg('ListString',{'continuous','single frame'},'PromptString','continuous state or single frame?','ListSize' ,[400 350]);
						% usrIdxChoice = options.labelLegend{sel};
						% labelID = inputdlg('enter label');labelID = labelID{1};
						% labelID = num2str(labelID{1});
						% create array if not already present
						toggleState(labelID) = xor(toggleState(labelID),1);
					end
					% ostruct.labelArray.time(labelCounter,1) = frame;
					% ostruct.labelArray.id(labelCounter,1) = labelID;
					labelCounter = labelCounter + 1;
				case 109 %'m' %change colormap
					%colorIdx = strmatch(options.colormapColor,options.colormapColorList)+1;
					% colorIdx = mod(strmatch(options.colormapColor,options.colormapColorList)+1,length(options.colormapColorList));
					options.colormapColor = options.colormapColorList{options.colormapIdx};
					options.colormapIdx = options.colormapIdx+1;
					if options.colormapIdx>length(options.colormapColorList)
						options.colormapIdx = 1;
					end
					figure(42);
					colormap(options.colormapColor);
				case 100 %'d' %dfof
					[usrIdxChoice ok] = getUserMovieChoice({'1st movie','2nd movie'});
					% make sure selection chosen, else return
					if ok~=0
						switch usrIdxChoice
							case 1
								inputMovie = dfofMovie(inputMovie);
								maxMovie(1) = nanmax(inputMovie(:));
								minMovie(1) = nanmin(inputMovie(:));
							case 2
								options.extraMovie = dfofMovie(options.extraMovie);
								maxMovie(2) = nanmax(options.extraMovie(:));
								minMovie(2) = nanmin(options.extraMovie(:));
							otherwise
								% nothing
						end
					end
				case 97 %'a' %downsample
					% [usrIdxChoice ok] = getUserMovieChoice({'1st movie','2nd movie'});
					% make sure selection chosen, else return
					inputMovie = downsampleMovie(inputMovie,'downsampleFactor',options.downsampleFactor);
					if ~isempty(options.extraMovie)
						options.extraMovie = downsampleMovie(options.extraMovie,'downsampleFactor',options.downsampleFactor);
					end
					nFrames = size(inputMovie,3);
				case 110 %'n' %normalize
					[usrIdxChoice ok] = getUserMovieChoice({'1st movie','2nd movie'});
					[usrExtraChoice ok] = getUserMovieChoice({'keep original','duplicate'});
					% make sure selection chosen, else return
					if ok~=0
						% inputOptions.normalizationType = 'imfilter';
						ioptions.freqLow = 7;
						ioptions.freqHigh = 500;
						ioptions.normalizationType = 'fft';
						ioptions.bandpassType = 'highpass';
						ioptions.showImages = 0;
						switch usrIdxChoice
							case 1
								if usrExtraChoice==2
									options.extraMovie = normalizeMovie(inputMovie,'options',ioptions);
									maxMovie(2) = nanmax(inputMovie(:));
									minMovie(2) = nanmin(inputMovie(:));
								else
									inputMovie = normalizeMovie(inputMovie,'options',ioptions);
								end
							case 2
								extraMovie = normalizeMovie(options.extraMovie,'options',ioptions);
							otherwise
								% nothing
						end
					end
				case 99 %'c' %crop
					[movieChoice ok] = getUserMovieChoice({'1st movie','2nd movie'});
					[cropChoice] = getUserMovieChoice({'NaN border crop','full crop'});

					dirChange = 1;
					[coords] = getCropCoords(thisFrame)
					sp = coords;
					switch movieChoice
						case 1
							rowLen = size(inputMovie,1);
							colLen = size(inputMovie,2);
						case 2
							rowLen = size(options.extraMovie,1);
							colLen = size(options.extraMovie,2);
						otherwise
							body
					end
					% a,b are left/right column values
					a = sp(1);
					b = sp(3);
					% c,d are top/bottom row values
					c = sp(2);
					d = sp(4);
					switch cropChoice
						case 1
							switch movieChoice
								case 1
									inputMovie(1:rowLen,1:a,:) = NaN;
									inputMovie(1:rowLen,b:colLen,:) = NaN;
									inputMovie(1:c,1:colLen,:) = NaN;
									inputMovie(d:rowLen,1:colLen,:) = NaN;
								case 2
									options.extraMovie(1:rowLen,1:a,:) = NaN;
									options.extraMovie(1:rowLen,b:colLen,:) = NaN;
									options.extraMovie(1:c,1:colLen,:) = NaN;
									options.extraMovie(d:rowLen,1:colLen,:) = NaN;
								otherwise
							end
						case 2
							switch movieChoice
								case 1
									inputMovie = inputMovie(sp(2):sp(4), sp(1): sp(3),:);
								case 2
									options.extraMovie = options.extraMovie(sp(2):sp(4), sp(1): sp(3),:);
								otherwise
							end
						otherwise
					end
					switch movieChoice
						case 1
							maxMovie(1) = nanmax(inputMovie(:));
							minMovie(1) = nanmin(inputMovie(:));
						case 2
							maxMovie(2) = nanmax(options.extraMovie(:));
							minMovie(2) = nanmin(options.extraMovie(:));
						otherwise
					end
					figure(42);
				case 103 %'g' %goto
					% if user clicks 'g' for goto
					frameChange = inputdlg('goto: enter frame #');
					if ~isempty(frameChange)
						frameChange = str2num(frameChange{1});
						if frameChange>nFrames|frameChange<1
						    % do nothing, invalid command
						else
						    frame = frameChange;
						    % dirChange = 0;
						end
					end
				case 43 %'+' %increase speed
					options.fps = options.fps*2;
					clearKey = 1;
					% dirChange = dirChange*2;
				case 45 %'-' %decrease speed
					options.fps = options.fps/2;
					clearKey = 1;
					% dirChange = dirChange/2;
				otherwise
			end

			if clearKey==1
				% reset the current key
				set(gcf,'currentch','3');
				keyIn = get(gcf,'CurrentCharacter');
			end

			% end positive feed loop
			if dirChange>100
				dirChange = 100;
			end
	    	% set(fig1,'keypress','keyboard');
			% if ~isempty(thisKey)
			% 	if strcmp(thisKey,'f'); break; end;
			% 	if strcmp(thisKey,'p'); pause; thisKey=[]; end;
			% end
		    frame = frame+round(dirChange);
		    if frame>nFrames
		    	if options.recordMovie~=0
		    		loopSignal = 0;
		    	else
		    		frame = 1;
		    	end
		    elseif frame<1;
		    	frame = nFrames;
		    end
		    % if frame==1
		    	% colorbar
		    % end
		    loopCounter = loopCounter + 1;
		    %
		    if any(strcmp('labelMatrix',fieldnames(ostruct)))
		    	ostruct.labelMatrix(:,frame) = toggleState.*[1:nLabels]';
		    	options.extraLinePlot(:,frame) = toggleState.*[1:nLabels]';
			    if impulseState==2
			    	toggleState(labelID) = 0;
			    	impulseState = 1;
			    end
		    end
		    % toc(startLoopTime)
		    % pause(1/options.fps);
		end
		if options.recordMovie~=0
			close(writerObj);
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function detectKeyPress(H,E)
		keyIn = get(H,'CurrentCharacter');
		% drawnow
		% keyIn
	end
end
function [coords] = getCropCoords(thisFrame)
	% figure(9);
	% subplot(1,2,1);
	% imagesc(thisFrame); axis image; colormap gray; title('select region')

	% Use ginput to select corner points of a rectangular
	% region by pointing and clicking the subject twice
	p = ginput(2);

	% Get the x and y corner coordinates as integers
	coords(1) = min(floor(p(1)), floor(p(2))); %xmin
	coords(2) = min(floor(p(3)), floor(p(4))); %ymin
	coords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
	coords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

	% Index into the original image to create the new image
	% sp = turboRegCoords;
	% thisFrameCropped = thisFrame(sp(2):sp(4), sp(1): sp(3));

	% Display the subsetted image with appropriate axis ratio
	% figure(9);subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
end
function [usrIdxChoice ok] = getUserMovieChoice(usrIdxChoiceStr)
	% usrIdxChoiceStr = {'1st movie','2nd movie'};
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
	usrIdxChoiceList = 1:length(usrIdxChoiceStr);
	usrIdxChoice = usrIdxChoiceList(sel);
end
function subfxn_imageJ(inputMovie)
	if exist('Miji.m','file')==2
		display(['Miji located in: ' which('Miji.m')]);
		% Miji is loaded, continue
	else
		% pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
		%              'Miji path', [1 100]);
		% pathToMiji = pathToMiji{1};
		pathToMiji = uigetdir('\.','Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts)');
		if ischar(pathToMiji)
			% privateLoadBatchFxnsPath = 'private\privateLoadBatchFxns.m';
			% if exist(privateLoadBatchFxnsPath,'file')~=0
			% 	fid = fopen(privateLoadBatchFxnsPath,'at')
			% 	fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
			% 	fclose(fid);
			% end
			addpath(pathToMiji);
		end
	end

	% Miji;
	% MIJ.start;
	manageMiji('startStop','start');

	MIJ.createImage('result', inputMovie, true);
	% clear primaryMovie;
	uiwait(msgbox('press OK to move onto next movie','Success','modal'));
	MIJ.run('Close');
	% MIJ.exit;
	manageMiji('startStop','exit');
end