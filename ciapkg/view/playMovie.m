function [exitSignal, ostruct] = playMovie(inputMovie, varargin)
	% Plays a 3D matrix as a movie, additional inputs to view multiple movies or sync'd signal data; can also save the resulting figure as a movie.
	% Biafra Ahanonu
	% started 2013.11.09 [10:39:50]
	%
	% inputs
		% inputMovie - [X Y Z] matrix of X,Y height/width and Z frames
	% options
		% fps -
		% extraMovie - extra movie to play, [X Y Z] matrix of X,Y height/width and Z frames
		% extraLinePlot - add a line-plot that is synced with the movie, [S Z] with S signals and Z frames
		% windowLength - length of the window over which to show the line-plot
		% recordMovie - whether to record the current movie or not
		% nFrames - number of frames to analyze
	%
	% changelog
		% 2013.11.13 [21:30:53] can now pre-maturely exit the movie, 21st century stuff
		% 2014.01.18 [19:09:14] several improvements to how extraLinePlot is displayed, now loops correctly
		% 2014.02.19 [12:13:36] added dfof and normalization to list of movie modifications
		% 2014.03.21 [00:43:22] can now label
		% 2019.05.21 [22:23:42] Major changes to display of images and line plots by updating underlying graphics handle data instead of calling imagesc, plot, etc. Several other plotting changes to make faster and avoid non-responsive keyboard inputs. Changed how line plot is made so loops signal without skips in the plot.
		% 2019.08.30 [13:44:09] - Updated contrast adjustment selection to also allow use of imcontrast and improved display of two movies contrast.
		% 2020.06.14 [13:59:50] - Check if inputMovie is sparse and adjust display accordingly.
		% 2020.09.01 [13:48:13] - Add support for read from disk for major filetypes, e.g. hdf5, tiff, avi, and isxd. User just needs to input filename. Added frameList to support only looping over specific sequences in the movie.
		% 2020.10.12 [13:00:05] - Updated slider and pause movie callbacks to reduce probability that slider starts to move erratically, move focus away from slider after use (so keyboard callbacks work), and improve pause handling. Made angle optional for options.primaryTrackingPoint. Refactored code to make easier to manage. Middle and right-click of mouse now lead to pausing.
		% 2020.10.12 [22:16:37] - Check for NWB input file and change dataset name to accomodate. Create a shortcut menu for easier navigation.
		% 2020.10.17 [20:12:18] - Add support for displaying in RGB when reading from AVI movies.
		% 2020.10.19 [12:51:00] - Switch read from disk support to using ciapkg.io.readFrame so that playMovie uses the new standard interface for fast reading from disk.

	% ========================
	% options
	% Int: figure number to open
	options.figNo = 42;
	% Int: set the frame rate to display the movie.
	options.fps = 20;
	% Int: set the min/max frames per second to display the movie.
		% To get around issues with Matlab drawing too fast to detect key strokes, set to 60 or below.
	options.fpsMax = 80;
	options.fpsMin = 1/10;
	% Matrix: [X Y Z], additional movie to show. X,Y height/width and Z frames.
	options.extraMovie = [];
	% 2D matrix: [signals frames] signals related to inputMovie.
	options.extraLinePlot = [];
	% Cell array: cell array of character strings for any legends to match lines in options.extraLinePlot.
	options.extraLinePlotLegend = {};
	% Cell array: cell array of character strings to label any values overlayed on the inputMovie.
	options.labelLegend = [];
	% Binary: whether lineplot should be colored.
	options.colorLinePlot = 0;
	% Int: length of the window over which to view the line plot (options.extraLinePlot).
	options.windowLength = 30;
	% Binary: whether to save the figure as a movie, put a string for the movie location.
	options.recordMovie = 0;
	% Int: number of frames to show, set to 0 to show all frames.
	options.nFrames = 0;
	% Default colormap
		% options.colormapColor = 'whiteRed';
	options.colormapColor = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
	% Int: colormap index to start at;
	options.colormapIdx = 1;
	% Cell array: cell array of strings with a list of different built-in colormaps to cycle through.
	options.colormapColorList = {'gray','jet','hot','hsv','copper'};
	% String: extra text to put as a title above movie, leave blank to ignore.
	options.extraTitleText = [];
	% String: extra text to put as a title above extra movie, leave blank to ignore.
	options.extraMovieTitleText = [];
	% Vector: [xpos ypos] add a point to the main movie.
	options.primaryPoint = [];
	% Vector: [xpos ypos-] add a point to the secondary movie.
	options.secondaryPoint = [];
	% Matrix: columns = [xpos ypos angle(degrees) magnitude], rows = frames. Both angle and magnitude are optional.
	options.primaryTrackingPoint = [];
	% Str: color of primary pointer tracker
	options.primaryTrackingPointColor = 'r';
	% Matrix: columns = [xpos ypos angle(degrees) magnitude], rows = frames. Both angle and magnitude are optional.
	options.secondaryTrackingPoint = [];
	% Str: color of secondary pointer tracker.
	options.secondaryTrackingPointColor = 'k';
	% Int: what factor to downsample movie if user ask to downsample movie.
	options.downsampleFactor = 4;
	% Vector: [min max] vector to set the min/max for movie display instead of estimating from the movie.
	options.movieMinMax = [];
	% Binary: 1 = directly run ImageJ.
	options.runImageJ = 0;
	% Str: hierarchy name in hdf5 where movie data is located.
	options.inputDatasetName = '/1';
	% Str: default NWB hierarchy names in HDF5 file where movie data is located, will look in the order indicates
	options.defaultNwbDatasetName = {'/acquisition/TwoPhotonSeries/data'};
	% Int: [] = do nothing, 1-3 indicates R,G,B channels to take from multicolor RGB AVI
	options.rgbChannel = [];
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% Binary: allow RGB display, e.g. for AVI
	options.rgbDisplay = 0;
	% get options
	options = getOptions(options,varargin);
	% options
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	% if ~isempty(options.extraMovie)|~isempty(options.extraLinePlot)
		% options.fpsMax = 30;
	% end

	% Obtain movie information and connect to file if user gives a path to a movie.
	if ischar(inputMovie)==1
		inputMovieIsChar = 1;
		% inputMovieName = inputMovie;
		inputMovieDims = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'displayInfo',1,'getMovieDims',1,'displayWarnings',0);
		inputMovieDims = [inputMovieDims.one inputMovieDims.two inputMovieDims.three];
		options.nFrames = inputMovieDims(3);
		nFramesOriginal = options.nFrames;

		readMovieChunks = 1;

		[movieType, supported, movieTypeSpecific] = ciapkg.io.getMovieFileType(inputMovie);
		if ~isempty(options.extraMovie)
			[movieTypeExtra, supported, movieTypeSpecificExtra] = ciapkg.io.getMovieFileType(options.extraMovie);
		end

		if supported==0
			disp('Unsupported movie type provided.')
			return;
		end

		% Setup connection to file to reduce I/O for file types that need it.
		[~,movieFileID,inputMovieDims] = ciapkg.io.readFrame(inputMovie,1);

		if ~isempty(options.extraMovie)
			[~,movieFileIDExtra,inputMovieDimsExtra] = ciapkg.io.readFrame(options.extraMovie,1);
		end
	else
		inputMovieIsChar = 0;
		inputMovieDims = size(inputMovie);
		nFramesOriginal = inputMovieDims(3);
		readMovieChunks = 0;
	end

	if issparse(inputMovie)==1
		sparseInputMovie = 1;
	else
		sparseInputMovie = 0;
	end

	% ==========================================
	% COLORMAP SETUP
	colorbarsOn = 0;
	options.colormapColorList = subfxn_colormapCreate(options);

	% ==========================================
	if options.nFrames==0
		nFrames = size(inputMovie,3);
	else
		nFrames = options.nFrames;
	end

	if ~isempty(options.frameList)
		nFrames = length(options.frameList);
	end

	% setup subplots
	subplotNumPlots = sum([~isempty(options.extraMovie) ~isempty(options.extraLinePlot)])+1;
	subplotRows = 1;
	if ~isempty(options.extraLinePlot)
		subplotRows = 2;
	end
	subplotCols = 2;

	% pass to calling functions, in case you want to exit an upper-level loop
	exitSignal = 0;

    try
        close(options.figNo)
    catch
    end
	fig1 = figure(options.figNo);
	% fig = figure(42,'KeyPressFcn',@detectKeyPress);

	clf
	set(findobj(gcf,'type','axes'),'hittest','off')

	% ==========================================
	if ~isempty(options.extraMovie)
		subplotNum = 2;
		if ischar(options.extraMovie)==1
			% extraMovieFrame = subfxn_readMovieDisk(options.extraMovie,1,movieTypeExtra,1);
			[extraMovieFrame] = ciapkg.io.readFrame(options.extraMovie,1,'movieFileID',movieFileIDExtra,'inputMovieDims',inputMovieDimsExtra);
			% tmpFrame = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'displayInfo',0,'displayDiagnosticInfo',0,'displayWarnings',0,'frameList',1);
		else
			extraMovieFrame = squeeze(options.extraMovie(:,:,1));
		end
		if sparseInputMovie==1
			extraMovieFrame = full(extraMovieFrame);
		else
		end

		subplot(subplotRows,subplotCols,subplotNum);
		imagesc(extraMovieFrame);
		extraTitleHandle = title(options.extraMovieTitleText);
		axHandle2 = gca;

		% axHandle2.Toolbar.Visible = 'off';
		if colorbarsOn==1
			set(gcf,'SizeChangedFcn',@(hObject,event) resizeui(hObject,event,axHandle2,colorbarsOn));
		end
		box off;
		axis equal tight
	end

	if ~isempty(options.extraLinePlot)
		% increment subplot
		% subplotNum = subplotNum+1;
		subplotNum = [4];
		plotAxisHandle = subplot(subplotRows,subplotCols,subplotNum);
		xval = 0;
		x=[xval,xval];
		% y=[-0.05 max(max(options.extraLinePlot))];
		y=[nanmin(options.extraLinePlot(:)) nanmax(options.extraLinePlot(:))];
		h1 = plot(x,y,'r','LineWidth',2);
		% uistack(h1,'bottom');

		hold on;
		plotHandle = plot(options.extraLinePlot');
		box off;
		xAxisHandleLine = xlabel('frame');
		ylim([nanmin(options.extraLinePlot(:)) nanmax(options.extraLinePlot(:))]);
	end

	if ~isempty(options.extraMovie)
		subplotNum = [1];
		subplot(subplotRows,subplotCols,subplotNum);
	end
	if ~isempty(options.extraLinePlot)
		subplotNum = [1 3];
		subplot(subplotRows,subplotCols,subplotNum);
		% set(gca, 'Position', get(gca, 'OuterPosition') - ...
			% get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
		% axHandle = fig1;
	end

	if ischar(inputMovie)==1
		% tmpFrame = subfxn_readMovieDisk(inputMovie,1,movieType);
		[tmpFrame] = ciapkg.io.readFrame(inputMovie,1,'movieFileID',movieFileID,'inputMovieDims',inputMovieDims);
		% tmpFrame = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'displayInfo',0,'displayDiagnosticInfo',0,'displayWarnings',0,'frameList',1);
	else
		tmpFrame = squeeze(inputMovie(:,:,1));
	end
	if sparseInputMovie==1
		tmpFrame = full(tmpFrame);
	else
	end

	imagesc(tmpFrame)
	axHandle = gca;
    mainTitleHandle = title(options.extraTitleText);
	% axHandle.Toolbar.Visible = 'off';
	box off;
	if ~isempty(options.extraLinePlot)
		axis equal tight
	else
		axis equal tight
	end

	xAxisHandle = xlabel(['frame: 1/' num2str(nFrames) '    fps: ' num2str(options.fps)]);

	if colorbarsOn==1
		set(gcf,'SizeChangedFcn',@(hObject,event) resizeui(hObject,event,axHandle,colorbarsOn));
	end

	% =================================================
	% GUI ELEMENTS
	if nFrames<11
		sliderStepF = [1/(nFrames) 0.05];
	else
		sliderStepF = [1/(nFrames*0.1) 0.2];
	end
	frameSlider = uicontrol('style','slider','Units', 'normalized','position',[15 1 80 3]/100,...
		'min',1,'max',nFrames,'Value',1,'SliderStep',sliderStepF,'callback',@frameCallback,'Enable','inactive','ButtonDownFcn',@pauseLoopCallback);
	% set(gcf,'WindowButtonDownFcn',@pauseLoopCallback);
	% addlistener(frameSlider,'Value','PostSet',@pauseLoopCallback);
	% waitfor(source,'Value')
	% addlistener(frameSlider, 'Value', 'PostSet',@frameCallback);
	frameText = uicontrol('style','edit','Units', 'normalized','position',[1 1 14 3]/100,'FontSize',9);

	% ==========================================
	% TITLE AND COMMANDS
	% close(fig1);fig1 = figure(42);
	[supTitleStr, suptitleHandle, conMenu] = subfxn_createShortcutInfo()

	% ==========================================
	% SETUP FIGURE STATES
	thisKey=1;
	% set(fig1,'keypress','thisKey=get(gcf,''CurrentCharacter'');');
	% set(fig1,'KeyPressFcn','keydown=1;');
	% keydown = 0;
	% set(fig1,'KeyPressFcn', '1;');
	set(fig1,'KeyPressFcn', @detectKeyPress);
    set(gcf, 'WindowScrollWheelFcn', @mouseWheelChange);
	set(gcf,'currentch','3');
	keyIn = get(gcf,'CurrentCharacter');
	set(gcf,'SelectionType','normal');

	% ==========================================
	% Setup
	% change colormap
	options.colormapColor = options.colormapColorList{options.colormapIdx};
	colormap(options.colormapColor);

	% open object to record movie if set
	if options.recordMovie~=0
		writerObj = VideoWriter(options.recordMovie);
		open(writerObj);
	end

	% ==========================================
	% CONSTANTS
	% while loop to allow forward, back, skipping around
	dirChange = 1;
	frame = 1;
	nFramesStr = num2str(nFrames);
	loopSignal = 1;
	loopCounter = 1;
	labelCounter = 1;
	% set(fig1,'doublebuffer','off');
	ostruct.labelArray.time = {};
	ostruct.labelArray.id = {};
	labelID = '';

	% ==========================================
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
	if ~isempty(options.movieMinMax)
		minMovie(1) = double(options.movieMinMax(1));
		maxMovie(1) = double(options.movieMinMax(2));
		minMovie(2) = double(options.movieMinMax(1));
		maxMovie(2) = double(options.movieMinMax(2));
	else
		if sparseInputMovie
			inputMovieFrame = inputMovie(find(inputMovie));
			if ~isempty(options.extraMovie)
				extraMovieFrame = inputMovie(find(options.extraMovie));
			end
		else
			if ischar(inputMovie)==1
				% tmpFrame = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'displayInfo',0,'displayDiagnosticInfo',0,'displayWarnings',0,'frameList',1:100);
				% inputMovieFrame = subfxn_readMovieDisk(inputMovie,1,movieType);
				% if ~isempty(options.extraMovie)
				% 	extraMovieFrame = subfxn_readMovieDisk(options.extraMovie,1,movieType,1);
				% end

				[inputMovieFrame] = ciapkg.io.readFrame(inputMovie,1,'movieFileID',movieFileID,'inputMovieDims',inputMovieDims);
				if ~isempty(options.extraMovie)
					extraMovieFrame = ciapkg.io.readFrame(options.extraMovie,1,'movieFileID',movieFileIDExtra,'inputMovieDims',inputMovieDimsExtra);
				end
			else
				inputMovieFrame = inputMovie(:);
				if ~isempty(options.extraMovie)
					extraMovieFrame = options.extraMovie(:);
				end
			end
		end

		maxMovie(1) = double(nanmax(inputMovieFrame(:)));
		minMovie(1) = double(nanmin(inputMovieFrame(:)));
		if ~isempty(options.extraMovie)
			maxMovie(2) = double(nanmax(extraMovieFrame(:)));
			minMovie(2) = double(nanmin(extraMovieFrame(:)));
		end
		clear inputMovieFrame extraMovieFrame;
		options.movieMinMax = [maxMovie(1) minMovie(1)];
	end

	colorbarSwitch = 1;
	colorbarSwitchTwo = 1;
	pauseLoop = 0;

	try
		while loopSignal==1
			% [figHandle figNo] = openFigure(42, '');

			% set(frameSlider,'Value',frame)
			% set(frameText,'string',['Frame ' num2str(frame) '/' num2str(nFrames)])

			% =====================
			if options.runImageJ==1&~ischar(inputMovie)
				subfxn_imageJ(inputMovie);
				% Run once else loops without exit
				options.runImageJ = 0;
			end
			if ~isempty(options.extraMovie)
				subplotNum = [1];
			end
			if ~isempty(options.extraLinePlot)
				subplotNum = [1 3];
			end

			% Display an image from the movie
			if readMovieChunks==1
				%
				% thisFrame = subfxn_readMovieDisk(inputMovie,frame,movieType);
				[thisFrame] = ciapkg.io.readFrame(inputMovie,frame,'movieFileID',movieFileID,'inputMovieDims',inputMovieDims);
			else
				thisFrame = squeeze(inputMovie(:,:,frame));
			end
			if sparseInputMovie==1
				thisFrame = full(thisFrame);
			end
			if frame==1
				% set(gca, 'xlimmode','manual',...
				% 	   'ylimmode','manual',...
				% 	   'zlimmode','manual',...
				% 	   'climmode','manual',...
				% 	   'alimmode','manual');
			end

			% keep contrast stable across frames.
			% thisFrame = imadjust(I,[0 1],[0 1]);
			thisFrame(1,1) = maxMovie(1)*maxAdjFactor;
			thisFrame(1,2) = minMovie(1);

			if options.rgbDisplay==1
				thisFrameTmp2 = max(thisFrame,[],3);
				imAlpha = ones(size(thisFrameTmp2));
				imAlpha(isnan(thisFrameTmp2))=0;
			else
				imAlpha = ones(size(thisFrame));
				imAlpha(isnan(thisFrame))=0;
			end

			if ~isempty(options.extraMovie)
				% subplotNum = subplotNum+1;
				subplotNum = 2;
				% subplot(subplotRows,subplotCols,subplotNum)
				% set(gca, 'Position', get(gca, 'OuterPosition') - ...
					% get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
				% imagesc(imcomplement(squeeze(options.extraMovie(:,:,frame))));
				% extraMovieFrame = squeeze(options.extraMovie(:,:,frame));

				% Display an image from the movie
				if readMovieChunks==1
					% extraMovieFrame = subfxn_readMovieDisk(options.extraMovie,frame,movieTypeExtra,1);
					extraMovieFrame = ciapkg.io.readFrame(options.extraMovie,frame,'movieFileID',movieFileIDExtra,'inputMovieDims',inputMovieDimsExtra);
				else
					extraMovieFrame = squeeze(options.extraMovie(:,:,frame));
				end
				if sparseInputMovie==1
					extraMovieFrame = full(extraMovieFrame);
				end

				if options.rgbDisplay==1
					thisFrameTmp2 = max(extraMovieFrame,[],3);
					imAlphaExtra = ones(size(thisFrameTmp2));
					imAlphaExtra(isnan(thisFrameTmp2))=0;
				else
					% normalize contrast across frames
					extraMovieFrame(1,1) = maxMovie(2)*maxAdjFactor;
					extraMovieFrame(1,2) = minMovie(2);

					imAlphaExtra = ones(size(extraMovieFrame));
					imAlphaExtra(isnan(extraMovieFrame))=0;
				end
			end

			montageHandle = findobj(axHandle,'Type','image');
			set(montageHandle,'Cdata',thisFrame,'AlphaData',imAlpha);
			if strcmp(options.colormapColor,'gray')
				set(axHandle,'color',[1 0 0]);
			else
				set(axHandle,'color',[0 0 0]);
			end

			if ~isempty(options.extraMovie)
				montageHandle2 = findobj(axHandle2,'Type','image');
				set(montageHandle2,'Cdata',extraMovieFrame,'AlphaData',imAlphaExtra);
				set(axHandle2,'color',[0 0 0]);
			end

			if frame==1
				try
					caxis(axHandle,[minMovie(1) maxMovie(1)]);
				catch
					caxis(axHandle,[-0.05 0.1]);
				end
				% disableDefaultInteractivity(axHandle)
			end

			if colorbarSwitch==1&&colorbarsOn==1
				% s2Pos = get(gca,'position');
				s2Pos = plotboxpos(axHandle);
				cbh = colorbar(axHandle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)],'LimitsMode','manual');
				ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)');
				colorbarSwitch = 0;
			end
			try
				movieDimStr = ['movie dims: ' num2str(inputMovieDims)];
				pauseLoopStr = '        ';
				if pauseLoop==1
					pauseLoopStr = 'Paused! ';
				end
				if isempty(options.frameList)
					tmpStrH = sprintf('%sframe: %d/%d fps: %d %s',pauseLoopStr,frame,nFrames,options.fps,movieDimStr);
					set(xAxisHandle,'String',tmpStrH);
				else
					tmpStrH = sprintf('%sframe: %d/%d (%d/%d) fps: %d %d',pauseLoopStr,frame,nFrames,options.frameList(frame),nFramesOriginal,options.fps,movieDimStr);
					set(xAxisHandle,'String',tmpStrH);
				end
			catch
			end

			if ~isempty(options.primaryPoint)||~isempty(options.primaryTrackingPoint)||~isempty(options.secondaryTrackingPoint)
				hold on;
			end
			if ~isempty(options.primaryPoint)
				if length(options.primaryPoint(:,1))==1
					xpt1 = options.primaryPoint(:,1);
					ypt1 = options.primaryPoint(:,2);
					offSet = 5;
					% horizontal
					line([1 xpt1-offSet],[ypt1 ypt1],'Color','k','LineWidth',1)
					line([xpt1+offSet inputMovieDims(2)],[ypt1 ypt1],'Color','k','LineWidth',1)
					% vertical
					line([xpt1 xpt1],[1 ypt1-offSet],'Color','k','LineWidth',1)
					line([xpt1 xpt1],[ypt1+offSet inputMovieDims(1)],'Color','k','LineWidth',1)

					% plot(options.primaryPoint(:,1), options.primaryPoint(:,2), 'k+', 'Markersize', 10)
				else
					plot(options.primaryPoint(:,1), options.primaryPoint(:,2), 'k.', 'Markersize', 10)
				end
			end
			if ~isempty(options.primaryTrackingPoint)
				plot(options.primaryTrackingPoint(frame,1), options.primaryTrackingPoint(frame,2), [options.primaryTrackingPointColor '+'], 'Markersize', 17)

				if size(options.primaryTrackingPoint,2)>2
					if size(options.primaryTrackingPoint,2)>3
						r = options.primaryTrackingPoint(frame,4);
					else
						r = 30; % magnitude (length) of arrow to plot
					end
					u = -r*cos(options.primaryTrackingPoint(frame,3)*(pi/180));
					v = r*sin(options.primaryTrackingPoint(frame,3)*(pi/180));

					quiver(options.primaryTrackingPoint(frame,1), options.primaryTrackingPoint(frame,2), u, v,'MaxHeadSize',10,'AutoScaleFactor',1,'AutoScale','off','color',options.primaryTrackingPointColor,'linewidth',2)
				end
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
			if ~isempty(options.primaryPoint)||~isempty(options.primaryTrackingPoint)||~isempty(options.secondaryTrackingPoint)
				hold off
			end
			% =====================
			% if user has an extra movie
			if ~isempty(options.extraMovie)
				% subplotNum = subplotNum+1;
				subplotNum = 2;
				% subplot(subplotRows,subplotCols,subplotNum)
				% set(gca, 'Position', get(gca, 'OuterPosition') - ...
					% get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
				% imagesc(imcomplement(squeeze(options.extraMovie(:,:,frame))));
				% extraMovieFrame = squeeze(options.extraMovie(:,:,frame));

				% imagesc(extraMovieFrame);
				% montageHandle2 = findobj(axHandle2,'Type','image');
				% set(montageHandle2,'Cdata',extraMovieFrame,'AlphaData',imAlphaExtra);
				% set(axHandle2,'color',[0 0 0]);
				% axis square;
				% axis equal tight;

				if frame==1
					try
						caxis(axHandle2,[minMovie(2) maxMovie(2)]);
					catch
						caxis(axHandle2,[-0.05 0.1]);
					end
					% disableDefaultInteractivity(axHandle2)
				end

				if colorbarSwitchTwo==1&&colorbarsOn==1
					% s2Pos = get(gca,'position');
					s2Pos = plotboxpos(axHandle2);
					cbh = colorbar(axHandle2,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)],'LimitsMode','manual');
					ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)');
					colorbarSwitchTwo = 0;
				end

				if ~isempty(options.secondaryPoint)
					hold on;
					if length(options.secondaryPoint(:,1))==1
						plot(options.secondaryPoint(:,1), options.secondaryPoint(:,2), 'k+', 'Markersize', 42)
					else
						plot(options.secondaryPoint(:,1), options.secondaryPoint(:,2), 'k.', 'Markersize', 10)
					end
					hold off
				end
			end
			% =====================
			% if user wants a lineplot to also be shown
			if ~isempty(options.extraLinePlot)
				% increment subplot
				% subplotNum = subplotNum+1;
				subplotNum = [4];
				% subplot(subplotRows,subplotCols,subplotNum);
				% axes(plotAxisHandle)
				indexVector = 1:nFrames;
				indexVectorAll = repmat(indexVector,[1 10]);
				frameIdx = find(indexVectorAll==frame);
				frameIdx = frameIdx(round(end/2));

				linewindowIdx = frameIdx+[-options.windowLength:options.windowLength];
				linewindow = indexVectorAll(linewindowIdx);
				linewindowX = linspace(-options.windowLength,options.windowLength,length(linewindow));
				try
					% Update X and Y data
					if options.colorLinePlot==1
						if length(plotHandle)==1
							set(plotHandle,'XData',linewindowX,'YData',options.extraLinePlot(:,linewindow)')
						else
							for iii = 1:length(plotHandle)
								set(plotHandle(iii),'XData',linewindowX,'YData',options.extraLinePlot(iii,linewindow)')
							end
						end
					else
						if length(plotHandle)==1
							set(plotHandle,'XData',linewindowX,'YData',options.extraLinePlot(:,linewindow)')
						else
							for iii = 1:length(plotHandle)
								set(plotHandle(iii),'XData',linewindowX,'YData',options.extraLinePlot(iii,linewindow)')
							end
						end
					end
				catch
					try

					catch
						display('out of range!');
					end
				end
				if ~isempty(options.extraLinePlotLegend)
					try
						legend(options.extraLinePlotLegend);
						% set(gca,'LegendColorbarListeners',[]);
						% setappdata(gca,'LegendColorbarManualSpace',1);
						% setappdata(gca,'LegendColorbarReclaimSpace',1);
					catch
					end
				end
			end
			% =====================
			if options.recordMovie~=0
				writeVideo(writerObj,getframe(fig1));
			end
			% =====================
			clearKey = 1;

			% Pause, to ensure frame rate set by user.
			if pauseLoop==1
				% pause
				% waitfor(frameSlider,'Enable');
			else
				pause(1/options.fps);
			end
			drawnow
			% uiwait(gcf, 1/options.fps)

			if options.fps>options.fpsMax
				options.fps = options.fpsMax;
			end
			if options.fps<options.fpsMin
				options.fps = options.fpsMin;
			end

			% =====================
			% GET USER INPUT
			subfxn_respondUserInput();

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
            % [frame pauseLoop]
			if pauseLoop==0
				frame = frame+round(dirChange);
                subfxn_updateSliderInfo();
            elseif pauseLoop==1
			end
			if frame>nFrames
				if options.recordMovie~=0
					loopSignal = 0;
				else
					frame = 1;
				end
			elseif frame<1
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
		% drawnow
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	function detectKeyPress(H,E)
		keyIn = get(H,'CurrentCharacter');
		% drawnow
		% keyIn
        % if double(keyIn)==112&pauseLoop==1
            % pauseLoop = 0;
        % end
	end
	function pauseLoopCallback(source,eventdata)
		% disp([num2str(frame) ' - pause loop'])
        % keyIn = get(gcf,'CurrentCharacter');
        % disp(keyIn)
		set(frameSlider,'Enable','on')
		addlistener(frameSlider,'Value','PostSet',@frameCallbackChange);
		% pauseLoop = 1;
		% pauseLoop = 0;
		% if pauseLoop==1
		%     pauseLoop = 0;
		% else
		%     pauseLoop = 1;
		% end
	end
	function blankCallback(source,eventdata)
	end
	function frameCallbackChange(source,eventdata)
		frame = max(1,round(get(frameSlider,'value')));
		set(frameText,'visible','on','string',['Frame ' num2str(frame) '/' num2str(nFrames)])
    end
    function mouseWheelChange(hObject, callbackdata, handles)
        if callbackdata.VerticalScrollCount > 0
            frame = frame + 1;
            dirChange = 1;
        elseif callbackdata.VerticalScrollCount < 0
            frame = frame - 1;
            dirChange = -1;
        end
        subfxn_updateSliderInfo();
    end
	function frameCallback(source,eventdata)
        originalPauseState = pauseLoop;
		pauseLoop = 1;
		frame = max(1,round(get(frameSlider,'value')));
		% disp(num2str(frame))
		% signalNo = max(1,round(get(signalSlider,'value')));
		% set(frameSlider,'value',frame);
		set(frameText,'visible','on','string',['Frame ' num2str(frame) '/' num2str(nFrames)])
		% pauseLoop
		addlistener(frameSlider,'Value','PostSet',@blankCallback);
        set(frameSlider,'Enable','off')
        drawnow update;
		set(frameSlider,'Enable','inactive')
        pauseLoop = originalPauseState;

		% breakLoop = 1;

		% Update the frame line indicator
		% set(mainFig,'CurrentAxes',signalAxes)
			% frameLineHandle.XData = [frameNo frameNo];
    end
    function subfxn_updateSliderInfo()
    	if frame<=0
    		frame = nFrames;
    	elseif frame>nFrames
    		frame = 1;
    	end
        set(frameSlider,'Value',frame)
		set(frameText,'string',['Frame ' num2str(frame) '/' num2str(nFrames)])
    end
	function thisFrame = subfxn_readMovieDisk(inputMoviePath,frameNo,movieTypeT,extraMovieSwitch)
		% Fast reading of frame from disk, bypass loadMovieList if possible due to overhead.
		if nargin==4

		else
			extraMovieSwitch = 0;
		end

		if ~isempty(options.frameList)
			frameNo = options.frameList(frameNo);
		end

		switch movieTypeT
			case 'hdf5'
				thisFrame = h5read(inputMoviePath,options.inputDatasetName,[1 1 frameNo],[inputMovieDims(1) inputMovieDims(2) 1]);
			case 'tiff'
				warning off;
				try
					tiffID.setDirectory(frameNo);
					thisFrame = read(tiffID);
				catch
				end
				warning on;
			case 'avi'
				if extraMovieSwitch==1
					thisFrame = read(xyloObjExtra, frameNo);
				else
					thisFrame = read(xyloObj, frameNo);
				end

				if options.rgbDisplay==0
					if size(thisFrame,3)==3&isempty(options.rgbChannel)
						thisFrame = squeeze(thisFrame(:,:,1));
					elseif ~isempty(options.rgbChannel)
						thisFrame = squeeze(thisFrame(:,:,options.rgbChannel));
					end
				end
			case 'isxd'
				thisFrame = inputMovieIsx.get_frame_data(frameNo-1);
			otherwise
				thisFrame = loadMovieList(inputMoviePath,'inputDatasetName',options.inputDatasetName,'displayInfo',0,'displayDiagnosticInfo',0,'displayWarnings',0,'frameList',frameNo);
		end
	end
	function subfxn_respondUserInput(keyInTmp)
        if nargin>0
            keyIn = keyInTmp;
        else
            keyIn = get(gcf,'CurrentCharacter');
            if isempty(double(keyIn))
                keyIn = '/';
            elseif double(keyIn)~=51
                figure(fig1)
                set(gcf,'CurrentCharacter','3');
                pause(1/options.fps);
                drawnow
            else
                % double(keyIn)
            end
        end

        % inputdlgcol options
        AddOpts.Resize='on';
        AddOpts.WindowStyle='normal';
        AddOpts.Interpreter='tex';

		mousePressState = get(gcf,'SelectionType');
		switch mousePressState
			case 'normal'
				% Do nothing
			case 'extend'
				keyIn = 112;
				set(gcf,'SelectionType','normal');
			case 'open'
				% keyIn = 112;
				% set(gcf,'SelectionType','normal');
			case 'alt'
				% keyIn = 112;
				set(gcf,'SelectionType','normal');
			otherwise
				% Do nothing
				% disp('111')
		end

		% Ignore these commands if input movie is character
		if inputMovieIsChar&any(double(keyIn)==[105 100 97 110 99])
			disp([keyIn ' not valid for movies input as path.'])
			return;
		end

		switch double(keyIn)
			case 105
				subfxn_imageJ(inputMovie)
			case 119 %'w' %set frame rate
				% if user clicks 'g' for goto
				try
					% fpsTmp = inputdlg('enter fps (frames per second)','',1,{num2str(options.fps)});
					fpsTmp = inputdlgcol('Enter fps (frames per second) to display movie at:','',1,{num2str(options.fps)},AddOpts,2);
					options.fps = str2num(fpsTmp{1});
				catch
				end
			case 101 %'e' %user wants to exit
				set(gcf,'currentch','3');
				% set(gcf,'CurrentCharacter','');

				movieDecision = questdlg('Are you sure you want to exit?', ...
					'Exit movie', ...
					'yes','no','yes');
				if strcmp(movieDecision,'yes')
					loopSignal = 0;
				end

				% break;
			case 48 %0 %user wants to exit
				set(gcf,'currentch','3');
				% set(gcf,'CurrentCharacter','');
				loopSignal = 0;
				% break;
			case 113 %'q' %user wants to send a kill signal up
				set(gcf,'currentch','3');

				movieDecision = questdlg('Are you sure you want to exit?', ...
					'Exit movie', ...
					'yes','no','yes');
				if strcmp(movieDecision,'yes')
					exitSignal = 1;
					loopSignal = 0;
				end

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
	            if pauseLoop==1
	                pauseLoop = 0;
	            else
	                pauseLoop = 1;
	            end
	            %ginput(1);
				% while waitforbuttonpress~=0
				% end
			case 31 % down arrow
				subfxn_displayShortcuts(1,1);
			case 29 % backarrow
				dirChange = 1;
				clearKey = 0;
				% ginput(1);
				% waitforbuttonpress
				pauseLoop = 1;
				frame = frame+round(dirChange);
				if double(get(gcf,'CurrentCharacter'))==28
					dirChange = -1;
				end
			case 28 % forward arrow
				dirChange = -1;
				clearKey = 0;
				% waitforbuttonpress
				pauseLoop = 1;
				frame = frame+round(dirChange);
				% ginput(1);
				if double(get(gcf,'CurrentCharacter'))==29
					dirChange = 1;
				end
			case 114 %'r' %rewind
				dirChange = -1;
			case 102 %'f' %forward
				dirChange = 1;
			case 106 %'j' %change contrast

				[usrIdxChoice, ok] = getUserMovieChoice({'Adjust 1st movie contrast','Adjust 2nd movie contrast','optimal dF/F','Copy contrast from 1st->2nd','Copy contrast from 2nd->1st'});
                if ok==0; return; end

				if usrIdxChoice==4
					maxMovie(2) = maxMovie(1);
					minMovie(2) = minMovie(1);
				elseif usrIdxChoice==5
					maxMovie(1) = maxMovie(2);
					minMovie(1) = minMovie(2);
				elseif usrIdxChoice==3
					maxMovie(1) = 0.15;
					minMovie(1) = -0.01;
				else
					[sel, ok] = listdlg('ListString',{'Adjustable contrast GUI','Contrast input dialog'},'ListSize',[300 300]);
                    if ok==0; return; end
					fixMultiplier = 1e5;

					if usrIdxChoice==1
						thisFrameTmp = double(thisFrame);
						thisHandle = axHandle;
					elseif usrIdxChoice==2&&exist('axHandle2','var')
						thisFrameTmp = double(extraMovieFrame);
						thisHandle = axHandle2;
					else
						thisFrameTmp = double(thisFrame);
						thisHandle = axHandle;
						usrIdxChoice = 1;
					end
					if sel==1
						try
							% since optimal is first, adjust to be correct
							% usrIdxChoice = usrIdxChoice-1;
							warning off

							montageHandle = findobj(thisHandle,'Type','image');
							set(montageHandle,'Cdata',thisFrameTmp*fixMultiplier,'AlphaData',imAlpha);
							% minCurr = nanmin(thisFrameTmp(:)*fixMultiplier);
							% maxCurr = nanmax(thisFrameTmp(:)*fixMultiplier);
							minCurr = minMovie(usrIdxChoice)*fixMultiplier;
							maxCurr = maxMovie(usrIdxChoice)*fixMultiplier;
							caxis(thisHandle,[minCurr maxCurr]);

							htool = imcontrast(thisHandle);
							set(htool,'WindowStyle','normal');
							caxis(thisHandle,[minCurr maxCurr]);

							% htoolMan = htool.Children(1).Children(2).Children.Children;
							% % Change max
							% htoolMan(2).Vertices(:,1) = htoolMan(2).Vertices(:,1)-10;
							% htoolMan(5).XData = htoolMan(5).XData-10;
							% htoolMan(7).Vertices(3:4,1) = htoolMan(7).Vertices(3:4,1)-10;
							% htoolMinMax(2).String = num2str(str2num(htoolMinMax(2).String)-10);

							% % Change min
							% htoolMinMax = htool.Children(1).Children(3).Children.Children(2).Children.Children(2).Children;


							warning on
							uiwait(msgbox('Adjust the contrast then hit OK','Contrast'));
							maxMovie(usrIdxChoice) = str2num(htool.Children(1).Children(3).Children.Children(2).Children.Children(2).Children(2).String)/fixMultiplier;
							minMovie(usrIdxChoice) = str2num(htool.Children(1).Children(3).Children.Children(2).Children.Children(2).Children(5).String)/fixMultiplier;
							disp(['New max: ' num2str(maxMovie(usrIdxChoice)) ' and min: ' num2str(minMovie(usrIdxChoice))])

							% montageHandle = findobj(axHandle,'Type','image');
							% set(montageHandle,'Cdata',thisFrame,'AlphaData',imAlpha);
							caxis(thisHandle,[minMovie(usrIdxChoice) maxMovie(usrIdxChoice)]);
							close(htool);
						catch err
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
					else
						try
							% answer = inputdlg({'max','min'},'Movie min/max for contrast',1,{num2str(maxMovie(usrIdxChoice)),num2str(minMovie(usrIdxChoice))});
							answer = inputdlgcol({'max','min'},'Movie min/max for contrast',1,{num2str(maxMovie(usrIdxChoice)),num2str(minMovie(usrIdxChoice))},AddOpts,2);

							maxMovie(usrIdxChoice) = str2num(answer{1});
							minMovie(usrIdxChoice) = str2num(answer{2});
							caxis(thisHandle,[minMovie(usrIdxChoice) maxMovie(usrIdxChoice)]);
						catch err
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
					end

				end
				colorbarSwitch = 1;
				colorbarSwitchTwo = 1;

			case 108 %'l' %label frame
				if ~isempty(options.labelLegend)
					[labelID, ok] = listdlg('ListString',options.labelLegend,'PromptString','toggle label(s), can select multiple to switch','ListSize' ,[400 350]);
                    if ok==0; return; end
					[impulseState, ok] = listdlg('ListString',{'continuous','single frame'},'PromptString','continuous state or single frame?','ListSize' ,[400 350]);
                    if ok==0; return; end
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
				[usrIdxChoice, ok] = getUserMovieChoice({'1st movie','2nd movie'});
                if ok==0; return; end
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
				[usrIdxChoice , ok] = getUserMovieChoice({'1st movie','2nd movie'});
                if ok==0; return; end
				[usrExtraChoice, ok] = getUserMovieChoice({'keep original','duplicate'});
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
						rowLen = inputMovieDims(1);
						colLen = inputMovieDims(2);
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
				frameChange = inputdlgcol('goto | Enter frame # to skip to:','',1,{''},AddOpts,2);
				if ~isempty(frameChange)
					frameChange = str2num(frameChange{1});
					if frameChange>nFrames|frameChange<1
						% do nothing, invalid command
					else
						frame = frameChange;
						% dirChange = 0;
					end
					subfxn_updateSliderInfo()
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
	end
	function subfxn_displayShortcuts(src,event)
		conMenu.Visible = 1;
		originalUnits = get(gcf,'Units');
		set(gcf,'Units','pixels')
		pos1 = get(gcf,'Position');
		set(gcf,'Units',originalUnits)
		conMenu.Position = [0 pos1(4)*0.97];
	end
	function [supTitleStr, suptitleHandle, conMenu] = subfxn_createShortcutInfo()
		titleSep = '\hspace{1em}';
		sepVar = ['}' 10 '\texttt{'];
		if isempty(options.extraTitleText)|1
			options.extraTitleText = '';
		else
		    options.extraTitleText = strrep(options.extraTitleText,'\','\char`\\');
		    options.extraTitleText = strrep(options.extraTitleText,'#','\char`\#');
			options.extraTitleText = [10 '\texttt{' options.extraTitleText '}'];
		end

		% S.fh = figure;
		shortcutMenuHandle = uicontrol('style','pushbutton','Units','normalized','position',[0 97 50 3]/100,'FontSize',9,'string','Shortcuts menu (or right-click GUI)','callback',@subfxn_displayShortcuts);

		sepMenuLins = {'','',''};
		menuListInfo = {...
		{'Mouse scroll wheel','','Forward/back frame'},...
		{'Mouse middle-click','','pause/play movie'},...
		{'+','','speed'},...
		{'-','','slow'},...
		{'right arrow','','+1 frame'},...
		{'left arrow','','-1 frame'},...
		sepMenuLins,...
		{'Note','','Click below LETTER commands to run or use the keyboard shortcut in main UI.'},...
		{'E','e','exit'},...
		{'Q','q','exit all'},...
		{'G','g','goto frame'},...
		{'P','p','pause/play'},...
		{'R','r','rewind'},...
		{'F','f','forward'},...
		{'J','j','adjust contrast'},...
		{'L','l','label'},...
		{'I','i','imagej'},...
		{'C','c','crop'},...
		{'D','d','$\Delta$F/F'},...
		{'A','a','downsample'},...
		{'N','n','normalize'},...
		{'M','m','change colormap'},...
		sepMenuLins,...
		};

		conMenu = uicontextmenu;
		mitemAll = {};
		for mNo = 1:length(menuListInfo)
			if isempty([menuListInfo{mNo}{1}])
		    	labelStr = [''];
			else
		    	labelStr = ['<HTML><PRE>' menuListInfo{mNo}{1} ':   ' menuListInfo{mNo}{3} '</PRE>'];
			end
			mitemAll{mNo} = uimenu(conMenu,'label',labelStr,'MenuSelectedFcn',@(src,evnt) subfxn_respondUserInput(menuListInfo{mNo}{2}));
		end
		uimenu(conMenu,'label',' ','MenuSelectedFcn',@subfxn_displayShortcuts,'Accelerator','T');

		set(gcf,'uicontextmenu',conMenu);

		supTitleStr = ['\texttt{',sepVar,...
			'\underline{Mouse scroll wheel}: Forward/back frame',titleSep,...
			'\underline{Mouse middle-click}: pause/play movie',sepVar,...
			'\underline{+}:speed',titleSep,...
			'\underline{-}:slow',titleSep,...
			'\underline{right arrow}:+1 frame',titleSep,...
			'\underline{left arrow}:-1 frame',sepVar,...
			'\underline{E}: Exit}',...
			options.extraTitleText,...
			''];
		% supTitleStr = ['\texttt{',sepVar,...
		% 	'\underline{Mouse scroll wheel}: Forward/back frame',titleSep,...
		% 	'\underline{Mouse middle/right-click}: pause/play movie',sepVar,...
		% 	'\underline{E}:exit',titleSep,...
		% 	'\underline{Q}:exit all',titleSep,...
		% 	'\underline{G}:goto frame',titleSep,...
		% 	'\underline{P}:pause/play',titleSep,...
		% 	'\underline{R}:rewind',sepVar,...
		% 	'\underline{F}:forward',titleSep,...
		% 	'\underline{J}:adjust contrast',titleSep,...
		% 	'\underline{L}:label',titleSep,...
		% 	'\underline{I}:imagej',titleSep,...
		% 	'\underline{C}:crop',sepVar,...
		% 	'\underline{D}:$\Delta$F/F',titleSep,...
		% 	'\underline{A}:downsample',titleSep,...
		% 	'\underline{N}:normalize',titleSep,...
		% 	'\underline{M}:change colormap',sepVar,...
		% 	'\underline{+}:speed',titleSep,...
		% 	'\underline{-}:slow',titleSep,...
		% 	'\underline{right arrow}:+1 frame',titleSep,...
		% 	'\underline{left arrow}:-1 frame','}',...
		% 	options.extraTitleText,...
		% 	''];
			% 'movie dims: ' num2str(inputMovieDims),'',titleSep,...
		if isempty(options.extraTitleText)
			supTitleStr = [supTitleStr 10];
		end
		disp(strrep(supTitleStr,titleSep, 10))
		% suptitleHandle = suptitle(strrep(strrep('/','\',supTitleStr),'_','\_'));
		suptitleHandle = suptitle(supTitleStr,'titleypos',0.93);
		set(suptitleHandle,'FontName',get(0,'DefaultAxesFontName'));
		set(suptitleHandle,'FontSize',12,'FontWeight','normal')
		hold off;
		% imcontrast
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
function [usrIdxChoice, ok] = getUserMovieChoice(usrIdxChoiceStr)
	% usrIdxChoiceStr = {'1st movie','2nd movie'};
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[300 300]);
	usrIdxChoiceList = 1:length(usrIdxChoiceStr);
	usrIdxChoice = usrIdxChoiceList(sel);
end
function subfxn_imageJ(inputMovie)
	modelAddOutsideDependencies('miji');

	manageMiji('startStop','start');

	MIJ.createImage('result', inputMovie, true);

	uiwait(msgbox('press OK to move onto next movie','Success','modal'));
	MIJ.run('Close');

	manageMiji('startStop','exit');
end
function resizeui(hObject,event,axHandle,colorbarsOn)
	if colorbarsOn==0
		return;
	end
	warning off;
	% inputMoviePlotLoc2Handle = subplotTmp(rowSubP,colSubP,2)
	% disp('Check')
	colorbar(axHandle,'off')
	% s2Pos = get(axHandle,'position');
	s2Pos = plotboxpos(axHandle);
	% s2Pos
	% [s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]
	cbh = colorbar(axHandle,'Location','eastoutside','Position',[s2Pos(1)+s2Pos(3)+0.005 s2Pos(2) 0.01 s2Pos(4)]);
	ylabel(cbh,'Fluorescence (e.g. \DeltaF/F or \DeltaF/\sigma)');
	% ylabel(cbh,'Raw extraction image value','FontSize',15);
	warning on;
end
function colormapColorList = subfxn_colormapCreate(options)
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
	colormapColorList = [...
		options.colormapColor,...
		outputColormap2,...
		{'gray'},...
		redWhiteMap,...
		grayRed,...
		outputColormap4,...
		outputColormap3,...
		options.colormapColorList];
		% options.colormapColor,...
	% options.colormapColorList
end