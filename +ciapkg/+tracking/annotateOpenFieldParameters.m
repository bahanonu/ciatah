function [mainTbl] = annotateOpenFieldParameters(inputFilePath,varargin)
	% [mainTbl] = annotateOpenFieldParameters(inputFilePath,varargin)
	% 
	% Requests information on arena size and center area for open field analysis from circular or square arenas.
	% 
	% Biafra Ahanonu
	% started: 2022.10.27 [13:38:36]
	% 
	% Inputs
	% 	inputFilePath - Str: path to location of movie files to analyze.
	% 
	% Outputs
	% 	mainTbl - Table consisting of session information, center time, center location, etc.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2022.12.13 [09:41:48] - add FPS override for cases in which camera metadata is incorrect.
		% 2023.04.29 [18:47:02] - Arena size automatically calculated from reference distance size. Add GUI font size option.
	% TODO
		% Clean up code to make into more nested and sub functions
		% Extend to elevated plus maze

	% ========================
	% Str: regular expression of files to find if inputFilePath is a folder.
	options.fileRegExp = '.avi$';
	% Int: frame number to read from each movie
	options.readFrame = 100;
	% Float: length (in cm) of landmark used for px/cm estimate.
	options.lenLandmark = 60.96;
	% Float: conversion unit between cm and inches.
	options.cmToIn = 2.54;
	% Str: type of open field: 'circle' or 'rectangle'
	options.typeField = 'circle';
	% Str: path to database csv file. This will be loaded and updated if it already exists.
	options.databasePath = '';
	% Str: path to folder containing DeepLabCut or other paths. Will look for 
	options.trackingPath = '';
	% Str: regular expression used to further filter for which tracking file to load.
	options.trackingRegExp = 'filtered.*.csv';
	% Str: name of body part to use for tracking overlay.
	options.trackingPart = 'body_center';
	% Float: fraction of the circle radius that will indicate animal is in the center.
	options.centerTimeRadiusFraction = 0.5;
	% Int: frames per second.
	options.fps = 15;
	% Binary: 1 = override video FPS with custom FPS.
	options.fpsOverride = 1;
	% Int: The moving mean sliding window width.
	options.movmeanWindowSize = 100;
	% Binary: 1 = bypass already analyzed videos.
	options.bypassAlreadyAnalyzed = 1;
	% Binary: 1 = bypass current user interaction.
	options.bypassFlag = 0;
	% Binary: 1 = automatically calculate diameter of arena from reference distance length.
	options.arenaFromRefDistance = 1;
	% Int: font size in interface
	options.fontSize = 14;
	% Int vector: layout of subplot with {row,col,subplotsOpenField,subplotSpeed}
	options.subplotLayout = {10,1,[1:9],10};
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
	    subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.005, 'Padding', 0.05, 'PaddingTop', 0.02, 'MarginTop', 0.05,'MarginBottom', 0.03,'MarginLeft', 0.01,'MarginRight', 0.01);

		figure;
		subplotTmp(options.subplotLayout{1},options.subplotLayout{2},options.subplotLayout{3})
		subplotTmp(options.subplotLayout{1},options.subplotLayout{2},options.subplotLayout{4})
		set(gcf,'Color','k')
		ciapkg.view.changeFont(options.fontSize,'fontColor','w');
		drawnow

		mainTbl = table;

		% GUIs for selecting folders if user did not put them into the function.
		[inputFilePath,options] = localfxn_getFoldersFiles(inputFilePath,options)
		cellfun(@disp,inputFilePath);
		nFiles = length(inputFilePath);

		% Check if database exists and load
		if isempty(options.databasePath)|isfile(options.databasePath)==0
			fprintf('No database at %s.\n',options.databasePath);
			disp('Creating database.');
			mainTbl = localfxn_createTable();
		else
			mainTbl = readtable(options.databasePath);
		end
		% openvar('mainTbl')
		scnsize = get(0,'ScreenSize');

		% Create table showing parameters
		fig = uifigure;
		tmpPos = get(fig,'Position');
		tmpPos(3) = scnsize(3)*0.9;
		tmpPos(1) = scnsize(3)*0.05;
		tmpPos(4) = scnsize(4)*0.2;
		tmpPos(2) = scnsize(4)*(0.98-0.2);
		set(fig,'Position',tmpPos);
		uit = uitable(fig,'Data',mainTbl);
		uit.Units = 'normalized'
		uit.Position = [0.05 0.05 0.9 0.9];
		colFmt1 = uit.ColumnFormat;
		mainTbl
		colFmt1
		colFmt1{7} = 'long';
		uit.ColumnFormat = colFmt1;
		% pause

		% Ask the user
		if isempty(options.lenLandmark)
			options.lenLandmark = inputdlg('Size of open field?');
			options.lenLandmark = num2str(options.lenLandmark{1});
		else
			
		end

		priorFileIdx = 1;

		for fileNo = 1:nFiles
			disp(repmat('=',1,7))
			thisPath = inputFilePath{fileNo};
			[~,thisFileName,~] = fileparts(thisPath);


			if options.fpsOverride==1
				framesPerSec = options.fps;
			else
				try
					vidInfo = VideoReader(thisPath);
					framesPerSec = vidInfo.FrameRate;
				catch
					framesPerSec = options.fps;
				end
			end

			titleStr = sprintf('%d/%d: %s | ',fileNo,nFiles,thisFileName);
			titleStr = [titleStr num2str(framesPerSec) ' frames/sec'];
			disp(titleStr)

			% Load tracking if available
			if ~isempty(options.trackingPath)
				trackingFilePath = ciapkg.io.getFileList(options.trackingPath,[thisFileName '.*' options.trackingRegExp]);
				disp(trackingFilePath)
				disp([thisFileName '.*' options.trackingRegExp])
				[trackingTbl] = ciapkg.behavior.importDeepLabCutData(trackingFilePath);
				% Format: [likelihood x y]
				trackingCoords = trackingTbl.(options.trackingPart);
			else
				trackingCoords = [];
			end

			% Check if already in database
			fileIdx = find(strcmp(mainTbl.filename,thisFileName));

			if isempty(fileIdx)
				options.bypassFlag = 0;
			else
				options.bypassFlag = 1;
			end

			% Setup the image
			thisFrame = ciapkg.io.readFrame(thisPath,options.readFrame);
			size(thisFrame)
			clf
			subplotTmp(options.subplotLayout{1},options.subplotLayout{2},options.subplotLayout{3})
			imagesc(thisFrame)

			box off;
			localfxn_fixAxesAspectRatio(thisFrame);
			box off

			colormap gray
			title(strrep(thisFileName,'_','\_'))

			% Get the px to cm conversion
			set(gcf,'Color','k')
			title([strrep(titleStr,'_','\_') 10 'Draw reference distance ('  num2str(options.lenLandmark) ' cm | ' num2str(options.lenLandmark/options.cmToIn) ' in).' 10 'Double-click to continue.'])
			ciapkg.view.changeFont(options.fontSize,'fontColor','w');

			if ~isempty(trackingCoords)
				% Remove dataTip interactivity, causes issues with tracking plotting
				disableDefaultInteractivity(gca);
				try
					hold on;
					p2 = plot(trackingCoords(options.readFrame,[2]),trackingCoords(options.readFrame,[3]),'r.','MarkerSize',30);
					p1 = plot(trackingCoords(:,[2]),trackingCoords(:,[3]),'Color',[1 1 1]*0.3,'LineWidth',0.5);
					% set(gca,'Children',[p1; p2]);
					% uistack(p1,'bottom');
					% uistack(p2,'top');
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			end

			% Ask user to indicate the conversion line
			if isempty(fileIdx)
				if fileNo==1
					hline = drawline('Color','b','DrawingArea','unlimited');
				else
					landMarkCoordsTmp = str2num(mainTbl.landMarkCoords{priorFileIdx});
					% If any prior coordinates larger than current frame, use default line draw
					if any([landMarkCoordsTmp(2,1)>size(thisFrame,2) landMarkCoordsTmp(2,2)>size(thisFrame,1)])
						hline = drawline('Color','b','DrawingArea','unlimited');
					else
						hline = drawline('Color','b',...
							'Position',landMarkCoordsTmp,'DrawingArea','unlimited');
					end
				end
			else
				hline = drawline('Color','b',...
					'Position',str2num(mainTbl.landMarkCoords{fileIdx}),...
					'DrawingArea','unlimited');
			end
			localfxn_confirmUserInput(options);

			xD = hline.Position(:,1);
			yD = hline.Position(:,2);;
			pxDistance = sqrt((xD(1)-xD(2))^2+(yD(1)-yD(2))^2);
			landMarkCoords = ['[' num2str(xD(1)) ' ' num2str(yD(1)) '; ' num2str(xD(2)) ' ' num2str(yD(2)) ']'];
			disp([num2str(options.lenLandmark) ' cm is ' num2str(pxDistance) ' px']);

			if ~isempty(trackingCoords)
				try
					pxToCm = pxDistance/options.lenLandmark;
					subplotTmp(options.subplotLayout{1},options.subplotLayout{2},options.subplotLayout{4})
						speedVec = localfxn_calcSpeed(trackingCoords);
						% Convert px/frame to cm/frames
						speedVec = speedVec/pxToCm;
						% Convert cm/frames to cm/sec
						speedVec = speedVec*framesPerSec;
						timeVec = ([1:length(speedVec)]/framesPerSec)/60;

						plot(timeVec,speedVec,'k-');
						hold on;
						plot(timeVec,movmean(speedVec,options.movmeanWindowSize,'omitnan'),'r-');
						meanSpeedCmPerSecTmp = mean(speedVec(:));
						plot([timeVec(1) timeVec(end)],[meanSpeedCmPerSecTmp meanSpeedCmPerSecTmp],'-','Color',[42 242 242]/255,'LineWidth',3);
						hold off;
						box off
						ylabel('cm/s')
						xlabel('Time (min)')
						ylim([0 prctile(speedVec(:),99)])
						drawnow
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
				subplotTmp(options.subplotLayout{1},options.subplotLayout{2},options.subplotLayout{3})
			end
			ciapkg.view.changeFont(options.fontSize,'fontColor','w');

			switch options.typeField
				case 'circle'
					set(gcf,'Color','k')
					title([strrep(titleStr,'_','\_') 10 'Draw circle around arena edge.' 10 'Double-click to continue.'])
					if isempty(fileIdx)
						tblRows = size(mainTbl,1);
						if tblRows==0
							defaultFlag = 1;
						else
							tmpRadius = mainTbl.arenaRadius(priorFileIdx);
							tmpDiam = tmpRadius*2;
							tmpCenterX = mainTbl.arenaCenterX(priorFileIdx);
							tmpCenterY = mainTbl.arenaCenterY(priorFileIdx);
							% Base the location and size of the arena on reference distance by user
							if options.arenaFromRefDistance==1
								tmpRadius = pxDistance/2;
								tmpCenterX = mean(xD,"all",'omitnan');
								tmpCenterY = mean(yD,"all",'omitnan');
							end
							sizeFlag = any([tmpDiam>size(thisFrame,2) tmpDiam>size(thisFrame,1)]);
							if isfinite(tmpRadius)&~isnan(tmpRadius)&tmpRadius~=0&sizeFlag==0
								defaultFlag = 0;
								try
									roi = drawcircle('Color','r','Label','Arena',...
										'Radius',tmpRadius,...
										'Center',[tmpCenterX tmpCenterY]);
								catch err
									disp(repmat('@',1,7))
									disp(getReport(err,'extended','hyperlinks','on'));
									disp(repmat('@',1,7))
								end
							else
								defaultFlag = 1;
							end
						end
						if defaultFlag==1
							tmpRadius = min(size(thisFrame,[1 2]))*0.3;
							tmpCenterX = size(thisFrame,2)/2;
							tmpCenterY = size(thisFrame,1)/2;
							if options.arenaFromRefDistance==1
								tmpRadius = pxDistance/2;
								tmpCenterX = mean(xD,"all",'omitnan');
								tmpCenterY = mean(yD,"all",'omitnan');
							end
							roi = drawcircle('Color','r','Label','Arena',...
								'Radius',tmpRadius,...
								'Center',[tmpCenterX tmpCenterY]);
						end
					else
						roi = drawcircle('Color','r','Label','Arena',...
							'Radius',mainTbl.arenaRadius(fileIdx),...
							'Center',[mainTbl.arenaCenterX(fileIdx) mainTbl.arenaCenterY(fileIdx)]);
					end

					localfxn_fixAxesAspectRatio(thisFrame);
					box off
					localfxn_confirmUserInput(options);
					arenaCenterX = roi.Center(1);
					arenaCenterY = roi.Center(2);
					arenaRadius = roi.Radius;

					set(gcf,'Color','k')
					roi = drawcircle('Color','g','Label','Center',...
						'Radius',arenaRadius*options.centerTimeRadiusFraction,...
						'Center',[arenaCenterX arenaCenterY]);
					title([strrep(titleStr,'_','\_') 10 'Automatically calculated arena center.' 10 'Double-click to continue.'])
					localfxn_confirmUserInput(options);
				case 'rectangle'
					set(gcf,'Color','k')
					title([strrep(titleStr,'_','\_') 10 'Confirm arena center.' 10 'Double-click to continue.'])
					if isempty(fileIdx)
						roi = drawrectangle('Color','r');
					else
						roi = drawrectangle('Color','r','Position',...
							[mainTbl.arenaXmin(fileIdx);
							mainTbl.arenaYmin(fileIdx);
							mainTbl.arenaWidth(fileIdx);
							mainTbl.arenaHeight(fileIdx)]);
					end
					localfxn_confirmUserInput(options);

					arenaXmin = roi.Position(1);
					arenaYmin = roi.Position(2);
					arenaWidth = roi.Position(3);
					arenaHeight = roi.Position(4);
				otherwise
					% body
			end

			% Get information about this movie
			fileInfo = ciapkg.io.getFileInfo(thisFileName);

			% Replace existing row if movie has already been analyzed
			if isempty(fileIdx)
				thisRow = size(mainTbl,1)+1;
			else
				thisRow = fileIdx;
			end
			pxToCm = pxDistance/options.lenLandmark;

			mainTbl.filename{thisRow,1} = thisFileName;
			mainTbl.subjectName{thisRow,1} = fileInfo.subjectStr;
			mainTbl.dateAnnotated{thisRow,1} = datestr(now,'yyyy.mm.dd HH:MM.SS','local');
			mainTbl.arenaType{thisRow,1} = options.typeField;
			mainTbl.framesPerSec(thisRow,1) = framesPerSec;
			mainTbl.centerTimeRadiusFraction(thisRow,1) = options.centerTimeRadiusFraction;
			mainTbl.landMarkCoords{thisRow,1} = landMarkCoords;
			mainTbl.lenLandMarkCm(thisRow,1) = options.lenLandmark;
			mainTbl.lenLandMarkPx(thisRow,1) = pxDistance;
			mainTbl.pxToCm(thisRow,1) = pxToCm;

			switch options.typeField
				case 'circle'
					mainTbl.arenaCenterX(thisRow,1) = arenaCenterX;
					mainTbl.arenaCenterY(thisRow,1) = arenaCenterY;
					mainTbl.arenaRadius(thisRow,1) = arenaRadius;
					
					mainTbl.arenaXmin(thisRow,1) = NaN;
					mainTbl.arenaYmin(thisRow,1) = NaN;
					mainTbl.arenaWidth(thisRow,1) = NaN;
					mainTbl.arenaHeight(thisRow,1) = NaN;
				case 'rectangle'
					mainTbl.arenaCenterX(thisRow,1) = NaN;
					mainTbl.arenaCenterY(thisRow,1) = NaN;
					mainTbl.arenaRadius(thisRow,1) = NaN;
					
					mainTbl.arenaXmin(thisRow,1) = arenaXmin;
					mainTbl.arenaYmin(thisRow,1) = arenaYmin;
					mainTbl.arenaWidth(thisRow,1) = arenaWidth;
					mainTbl.arenaHeight(thisRow,1) = arenaHeight;
				otherwise
					% body
			end

			if ~isempty(trackingCoords)
				title([strrep(titleStr,'_','\_') 10 'Automatically subject center points.' 10 'Double-click to continue.'])
				pctTimeCenter = localfxn_pctTimeCenter_cirle(trackingCoords,arenaCenterX,arenaCenterY,arenaRadius,options);
				speedVec = localfxn_calcSpeed(trackingCoords/pxToCm);
				% Convert cm/frames to cm/sec
				speedVec = speedVec*framesPerSec;

				meanSpeedCmPerSec = mean(speedVec(:));
				distanceTraveledCm = sum(speedVec(:));

				mainTbl.pctTimeCenter(thisRow,1) = pctTimeCenter;
				% distanceTraveledCm = sprintf('%.3f',single(distanceTraveledCm));
				mainTbl.distanceTraveledCm(thisRow,1) = distanceTraveledCm;
				mainTbl.meanSpeedCmPerSec(thisRow,1) = meanSpeedCmPerSec;
			end

			% disp(mainTbl)

			% uit = uitable(fig,'Data',mainTbl);
			uit.Data = mainTbl;

			if ~isempty(options.databasePath)
				fprintf('saving %s\n',options.databasePath);
				writetable(mainTbl,options.databasePath,'FileType','text','Delimiter',',');
			end
			priorFileIdx = thisRow;
		end

		success = 1;
	catch err
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [outputs] = nestedfxn_exampleFxn(arg)
		% Always start nested functions with "nestedfxn_" prefix.
		% outputs = ;
	end	
end

function speedVec = localfxn_calcSpeed(trackingCoords)
	x = trackingCoords(:,2);
	y = trackingCoords(:,3);
	xdiff = [0; diff(x)];
	ydiff = [0; diff(y)];
	speedVec = sqrt(xdiff.^2 + ydiff.^2);
end
function pctTimeCenter = localfxn_pctTimeCenter_cirle(trackingCoords,arenaCenterX,arenaCenterY,arenaRadius,options)
	x = trackingCoords(:,2);
	y = trackingCoords(:,3);
	xC = arenaCenterX;
	yC = arenaCenterY;
	rC = arenaRadius*options.centerTimeRadiusFraction;
	pointsInCircle = rC >= sqrt((x-xC).^2 + (y-yC).^2); % 1 = point is inside circle
	% pointsInCircle = ((x-xC).^2 + (y-yC).^2) <= rC^2; % 1 = point is inside circle
	pctTimeCenter = mean(pointsInCircle(:));

	set(gcf,'Color','k')
	plot(x(pointsInCircle),y(pointsInCircle),'.','Color','r','MarkerSize',10);
	localfxn_confirmUserInput(options);
end

function localfxn_fixAxesAspectRatio(thisFrame)
	% axis equal
	% return
	ax = gca;
	% Correct aspect ratio but allow drawline and related to work properly (allow resizing).
	mod(size(thisFrame,1),120)
	mod(size(thisFrame,2),120)
	if mod(size(thisFrame,1),120)==0||mod(size(thisFrame,2),120)==0
		thisFrame = thisFrame(1:end-2,1:end-2);
	end
	frameDims = size(thisFrame,[1 2]);
	frameDims = [772   680];
	maxDim = max(frameDims(:));
	% ax.PlotBoxAspectRatio = [frameDims(2)/maxDim frameDims(1)/maxDim 0.5];
	ax.PlotBoxAspectRatio = [1 1 0.5];
	ax.DataAspectRatio = [120 120 1];
	ax.DataAspectRatioMode = 'auto';
	ax.PlotBoxAspectRatio = [frameDims(2)/maxDim frameDims(1)/maxDim 1];
	ax.PlotBoxAspectRatioMode = 'manual';
end
function mainTbl = localfxn_createTable()
	mainTbl = table(...
		{'BLANK'},...
		{'BLANK'},...
		{'BLANK'},...
		{'BLANK'},...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		{'BLANK'},...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		NaN,...
		'VariableNames',{...
		'filename';
		'subjectName';
		'dateAnnotated';
		'arenaType';
		'framesPerSec';
		'centerTimeRadiusFraction';
		'pctTimeCenter';
		'distanceTraveledCm';
		'meanSpeedCmPerSec';
		'landMarkCoords';
		'lenLandMarkCm';
		'lenLandMarkPx';
		'pxToCm';
		'arenaCenterX';
		'arenaCenterY';
		'arenaRadius';
		'arenaXmin';
		'arenaYmin';
		'arenaWidth';
		'arenaHeight';})
	mainTbl(1,:) = [];
end
function localfxn_confirmUserInput(options)
	% options
	if options.bypassAlreadyAnalyzed==1
		if options.bypassFlag==0
			waitfordoubleclick
		end
	else
		waitfordoubleclick
	end
	set(gcf,'Color',[0.1 0.3 0.1])
	pause(0.2)
end
function [outputs] = localfxn_getCircleValues(thisFrame)
	movieDims = size(thisFrame);
	xH = movieDims(2);
	yW = movieDims(1);
	handle01 = imellipse(gca,round([min(xH,yW)/2 min(xH,yW)/2 min(xH,yW)/4 min(xH,yW)/4]));
	setColor(handle01,'g');
	addNewPositionCallback(handle01,@(p) title(sprintf('Select a region covering one cell (best to select one near another cell).\nDouble-click region to continue.\nEnable zoom with crtl+Z = zoom on, ctrl+x = zoom off. Turn off to re-enable cell size selection\nDiameter = %d px.',round(p(3)))));
	setFixedAspectRatioMode(handle01,true);
	fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
	setPositionConstraintFcn(handle01,fcn);
	wait(handle01);
	handle01
	pos1 = getPosition(handle01);
	gridWidthTmp = round(pos1(3));
end	
function waitfordoubleclick
	% Calculate whether user double-clicked with a certain speed.
	clickDelta = 0.2;
	tStart = 0;
	waitforbuttonpress;
	tCurr = cputime;
	while tCurr-tStart>clickDelta
		tStart = tCurr;
		waitforbuttonpress;
		tCurr = cputime;
	end
end 
function [inputFilePath,options] = localfxn_getFoldersFiles(inputFilePath,options)
	% Convert into cell array if string is not present
	if isempty(inputFilePath)
		thisFileNumIdx = 1;
		inputFilePath = {};
		pathToAdd = '';
		while ~isempty(pathToAdd)|length(inputFilePath)<1
			try
				if ischar(pathToAdd)
					uiStr = 'Select a folder to add with movie files. Press cancel to stop adding folders.';
					disp(uiStr)
					pathToAdd = uigetdir(pathToAdd,uiStr);
					% If user cancels, do not add folder.
					if pathToAdd~=0
						fprintf('Adding folder #%d: %s.\n',thisFileNumIdx,pathToAdd);
						inputFilePath{thisFileNumIdx} = pathToAdd;
						thisFileNumIdx = thisFileNumIdx+1;
					end
				else
					% Force exit
					pathToAdd = [];
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	else
	end

	if isstr(inputFilePath)
		if isfolder(inputFilePath)
			inputFilePath = ciapkg.io.getFileList(inputFilePath,options.fileRegExp);
		else
			inputFilePath = {inputFilePath};
		end
	elseif iscell(inputFilePath)
		inputFilePath = ciapkg.io.getFileList(inputFilePath,options.fileRegExp);
	end

	if isempty(options.trackingPath)
		uiStr = 'Select database CSV file.';
		disp(uiStr)
		[fileX,pathX] = uigetfile('',uiStr);
		if fileX==0
			[fileX,pathX] = uiputfile
			options.databasePath = fullfile(pathX,fileX);
		else
			options.databasePath = fullfile(pathX,fileX);
			fprintf('Database path: %s.\n',options.databasePath);
		end
	end

	if isempty(options.trackingPath)
		uiStr = 'TRACKING: Select a folder to add containing tracking data. Press cancel to stop adding folders.';

		thisFileNumIdx = 1;
		options.trackingPath = {};
		pathToAdd = '';
		while ~isempty(pathToAdd)|length(options.trackingPath)<1
			try
				if ischar(pathToAdd)
					disp(uiStr)
					pathToAdd = uigetdir(pathToAdd,uiStr);
					% If user cancels, do not add folder.
					if pathToAdd~=0
						fprintf('Adding folder #%d: %s.\n',thisFileNumIdx,pathToAdd);
						options.trackingPath{thisFileNumIdx} = pathToAdd;
						thisFileNumIdx = thisFileNumIdx+1;
					end
				else
					% Force exit
					pathToAdd = [];
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end

	end
end