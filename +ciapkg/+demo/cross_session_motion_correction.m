% Cross-session motion correction method (CS-MCM)
%   Run each cell in succession to process data.
%	Assumes that all the imaging data has near equivalent µm/pixel.
%   https://doi.org/10.1101/2023.05.22.541477
% Biafra Ahanonu
% started: 2021.04.16 [14:16:27]

%% ========================================== 
% Load parameters
% Str: path to output data
outputMovieFolder = 'PATH';
% Str: Path to root folder containing all sub-folders with imaging data.
rootPathHere = 'PATH';
% [OPTIONAL] Str: if all imaging sessions are in the same folder
rootPathLoad = '';

% Str: name of the animal subject whose data is being analyzed
subjectName = 'mouse01';
% Str: regular expression used to identify folders
folderMatchStr = 'day';
% Str: regular expression used to find files in each imaging session folder.
fileRegExpHere = 'epi01.*.tif'; 

% Int: Reference frame for within session correction
refFrame = 2; 
% Int: Session to use for reference for cross-session alignment
refSession = 102; 
% Int vector: Frames to use in the movies, leave blank to load all frames
frameRange = 100:102; 

% 1 = match the size of the images by upscaling to largest image size
sizeMatchFlag = 1;
% Which file number in the folder to load
fileNoLoadForce = 1;
% Str: '1P' or '2P'
imgType = '1P'; 
% Int vector: List of sessions to flip dimension #1 (rows).
flipDim1 = [];
% Int vector: List of sessions to flip dimension #2 (columns).
flipDim2 = []; 
% Int vector: List of sessions to rotate 90 degrees.
rot90Dim = []; 
% Int vector: List of sessions to skip
skipSessions = []; 

% Get the current date-time string for file saving
currentDateTimeStr = datestr(now,'yyyy_mm_dd_HHMMSS','local');
outputMovieNameStart = [currentDateTimeStr '_' subjectName '_crossDay_day'];

%% ========================================== 
% Start parallel pool
ciapkg.io.manageParallelWorkers(20,'forceParpoolStart',1);

%% ========================================== 
% Load all the session information where each folder contains a different imaging session
try
	folderList = cellfun(@(x) ciapkg.io.getFileList(x,folderMatchStr),rootPathLoad,'UniformOutput',0);
	folderList = [folderList{:}];
catch
	folderList = ciapkg.io.getFileList(rootPathLoad,folderMatchStr);
end
nFolders = length(folderList);
dayList = [];
folderNoList = [];
runList = [];
runListNew = [];
folderListNew = {};
for folderNo = 1:nFolders
	folderPath = folderList{folderNo};   
	movieLoadPath = ciapkg.io.getFileList(folderPath,fileRegExpHere);
	% Get the "day" number, e.g. day01 or day04 will yield 1 and 4 for later identification.
	dayNum = str2num(cell2mat(strrep(regexp(folderPath,[folderMatchStr '\d+'],'match'),folderMatchStr,'')));
	if ~isempty(movieLoadPath)&&any(skipSessions==dayNum)==0
		dayList(end+1) = dayNum;
		folderListNew{end+1} = folderPath;
		fprintf('ADDING Day %d | \n',dayList(end))
		runList(folderNo) = 1;
		runListNew(end+1) = 1;
	else
		fprintf('SKIPPING Day %d | \n',dayNum)
		runList(folderNo) = 0;
	end
end
dayList = dayList';
fprintf('\n');

%% ========================================== 
% Load all the session data
nFolders = length(folderListNew);
gMovieRaw = cell([nFolders 1]);
errorLog = zeros([1 nFolders]);
cNum = 1;
WaitMessage = parfor_wait(nFolders, 'Waitbar', true);
parfor folderNo = 1:nFolders
	try
		WaitMessage.Send;
		disp('==========================================')
		fprintf('Loading day %d/%d (%d/%d).\n',folderNo,dayList(end),folderNo,nFolders);
		if runListNew(folderNo)==0
			disp('No data for this day, skipping...')
			continue;
		end
		folderPath = folderListNew{folderNo};
		
		if ~isempty(rootPathHere)
			dayCheck = dayList(folderNo);
			if dayCheck<10
				dayCheck = ['0' num2str(dayCheck)];
			else
				dayCheck = num2str(dayCheck);
			end
			movieLoadPath = ciapkg.io.getFileList(rootPathHere,[folderMatchStr dayCheck]);
		else
			movieLoadPath = [];
		end
		
		% Priority to manually selected TIF else use from raw folder
		if isempty(movieLoadPath)
			movieLoadPath = ciapkg.io.getFileList(folderPath,fileRegExpHere);
			frameRangeTmp = frameRange;
		else
			frameRangeTmp = 1:length(frameRange);
		end
			
		% Load imaging data if avaliable in folder
		if ~isempty(movieLoadPath)
			warning off
			fileNoLoad = 1;
			if ~isempty(fileNoLoadForce)
				fileNoLoad = fileNoLoadForce;
			end
			disp(fileNoLoad)
			if length(frameRangeTmp)>1
				gMovieRaw{folderNo} = ciapkg.io.loadMovieList(movieLoadPath{fileNoLoad},'frameList',frameRangeTmp);
			else
				gMovieRaw{folderNo} = ciapkg.io.readFrame(movieLoadPath{fileNoLoad},frameRangeTmp);
			end
			warning on
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
		try
			errorLog(folderNo) = 1;
		catch
		end
	end
end

WaitMessage.Destroy;

% Save a backup of original data in case need to go back to it
gMovieRawOriginal = gMovieRaw;
nSessions = length(gMovieRaw);
disp('Done loading movies')

%% ==========================================
% Plot to make sure loaded data is usable
localfun_plotInputMovies(gMovieRaw,nSessions,refSession,refFrame,dayList,6,0,1,0);

%% ==========================================
% Match size of all images across all movies
gMovieRaw = ciapkg.image.matchImageDimensions(gMovieRaw,'modType','pad');
disp('Done!')

%% ==========================================
% Prepare for run, copy raw data to a new matrix
nSessions = length(gMovieRaw);
gMovie = gMovieRaw;
disp('Done gMovie = gMovieRaw')

%% ==========================================
% Plot a frame from each to confirm data loaded properly
cmapRange = [100 200]; % [min max], pixel intensity range to plot data.
cmapRange = 1; % Plot the 15th and 99th percentile for min and max.
localfun_plotInputMovies(gMovie,nSessions,refSession,refFrame,dayList,10,0,cmapRange,0);

%% ==========================================
% [OPTIONAL] For certain datasets, rotate all images
rot90Dim = 1:length(dayList);
disp('Done assigning files to rotate')

%% ==========================================
% [OPTIONAL] For certain datasets, flip all images in dimension #1 (rows)
flipDim1 = 1:length(dayList);
disp('Done assigning files to rotate')

%% ==========================================
% [OPTIONAL] For certain datasets, flip all images in dimension #2 (columns)
flipDim2 = 1:length(dayList);
disp('Done assigning files to rotate')

%% ==========================================
% [OPTIONAL] Flip movies in x or y as needed due to camera or other changes
% Index of session to flip in each dimension
for i = 1:nSessions
	fprintf('Checking %d/%d\n',i,nSessions);
	if any(flipDim1==i)
		fprintf('Flip dim1 %d/%d\n',i,nSessions);
		gMovie{i} = flip(gMovie{i},1);
	end
	if any(flipDim2==i)
		fprintf('Flip dim2 %d/%d\n',i,nSessions);
		gMovie{i} = flip(gMovie{i},2);
	end
	if any(rot90Dim==i)
		fprintf('Rotate -90 deg %d/%d\n',i,nSessions);
		gMovie{i} = rot90(gMovie{i},1);
	end
end

%% ==========================================
% Convert all input data to single-precision (32-bit) arrays.
gMovie = cellfun(@single,gMovie,'UniformOutput',0);

%% ==========================================
% [OPTIONAL] Manually correct motion across movies to a reference frame
% If there is significant motion (e.g. translation or rotation) or the field of view is flipped, can improve automated registration.
[gMovieTmp, outStructTmp] = ciapkg.motion_correction.computeManualMotionCorrection(gMovie,...
	'registerUseOutlines',0,'cellCombineType','mean','gammaCorrection',1.6,'refFrame',refSession,'translationAmt',1,'includeImgsOutputStruct',0);
disp('Done!')

%% [OPTIONAL] Save output
outputMoviePath = fullfile(outputMovieFolder,[outputMovieNameStart num2str(dayList(1)) '-' num2str(dayList(nSessions)) '_postManual.mat']);
disp(['Saving: ' outputMoviePath])
save(outputMoviePath,'gMovieTmp',"outStructTmp");
disp('DONE!')

%% Transfer over, safer in case manual exists early.
gMovie = gMovieTmp;
clear gMovieTmp;
clear outStructTmp
disp('DONE!')

%% ==========================================
% Register each movie to itself to reduce complexity of cross-session motion correction
[~,cropCoordsInSession] = ciapkg.image.cropMatrix(gMovie{refSession},'cropOrNaN','crop','inputCoords',[]); 
parfor i = 1:nSessions
	disp('=====================')
	fprintf('Session %d/%d:\n',i,nSessions);
	gMovie{i} = ciapkg.motion_correction.turboregMovie(gMovie{i},'refFrame',refFrame,...
		'RegisType',1,'normalizeType','matlabDisk','cropCoords',cropCoordsInSession,...
		'SmoothX',10,'SmoothY',10,'meanSubtract',1,'showFigs',0);
end
disp('Done within-session motion correction')

%% ==========================================
% Automatic handling of large shifts in the movies across days, to be followed by motion correction to handle smaller shifts.
% First take mean image for each session to conduct initial motion correction.

try close(9); catch; end

% =======
% TurboReg settings
ioptions.SmoothX = 30;%10
ioptions.SmoothY = 30;%10
ioptions.minGain = 0.0;
ioptions.Levels = 6;
ioptions.Lastlevels = 1;
ioptions.Epsilon = 1.192092896E-07;
ioptions.zapMean = 0;
%
ioptions.turboregRotation =  1;
ioptions.parallel =  1;
ioptions.closeMatlabPool = 0;
ioptions.meanSubtract =  1;
% ioptions.normalizeType = 'divideByLowpass';
ioptions.normalizeType = 'matlabDisk';
ioptions.matlabdiskR1 = 20;
ioptions.matlabdiskR2 = 10;
ioptions.registrationFxn = 'transfturboreg';
ioptions.removeEdges = 0;
ioptions.complementMatrix = 1; % Switch to 0 for 2P data
% =======

% Manually get area to use for registration.
[~,inputCoords] = ciapkg.image.cropMatrix(gMovie{refSession},'cropOrNaN','crop','inputCoords',[]); 
ioptions.cropCoords = inputCoords;

% Store the motion correction coordinates.
registrationCoords = {};

% Reference frame is the average of the entire reference session, less sensitive to peculiarities of a single frame.
refMovieFrame = cast(mean(gMovie{refSession},3),'double');

inputImagesTranslated = {};
inputImagesTranslated{refSession} = gMovie{refSession};
gMovieTmp = gMovie;
for i = 2:nSessions
	disp('=====================')
	sessionStr = sprintf('Session %d/%d:\n',i,nSessions);
	disp(sessionStr);
	title(sessionStr);
	for roundNo = 1:2
		fprintf('Registration round %d/%d:\n',roundNo,2);
		if roundNo==2
			ioptions.RegisType =  2; % 2 - affine,     rotation,    no skew
		else
			ioptions.RegisType =  1; % 1 - affine,     no rotation, no skew
		end
		ioptions.altMovieRegister = gMovieTmp{i};
		thisSessionFrame = cast(mean(gMovieTmp{i},3),'double');
		objMapsToTurboreg = cat(3,refMovieFrame,thisSessionFrame);
		[gMovieTmp{i}, registrationCoords{i}] = ciapkg.motion_correction.turboregMovie(objMapsToTurboreg,'options',ioptions);
		drawnow
	end
end
inputImagesTranslated = gMovieTmp;
clear gMovieTmp;
disp('Done correcting large shifts motion correction')

%% Save output
savePostStr = '_postCrossSessionMotionCorrect.mat';
outputMoviePath = fullfile(outputMovieFolder,[outputMovieNameStart num2str(dayList(1)) '-' num2str(dayList(nSessions)) savePostStr]);
disp(['Saving...' outputMoviePath])
save(outputMoviePath,'gMovie','inputImagesTranslated','dayList','registrationCoords');
disp('DONE!')

%% ==========================================
% [OPTIONAL] If need to go back to gMovie before cross-session motion correction
inputImagesTranslated = gMovie;

%% ==========================================
% Plot frames from the motion corrected movie, check that there are not large errors in motion correction
localfun_plotInputMovies(inputImagesTranslated,nSessions,refSession,refFrame,dayList,22,0,1,0);
colormap gray

%% ==========================================
% [OPTIONAL] Backup motion corrected data
inputImagesTranslatedTmp = inputImagesTranslated;

%% ==========================================
% [OPTIONAL] Further manual correction to quickly correct any remaining shifts
[inputImagesTranslated, outputStruct] = ciapkg.motion_correction.computeManualMotionCorrection(inputImagesTranslated,...
	'registerUseOutlines',0,'cellCombineType','mean','gammaCorrection',1.6,'refFrame',refSession);

%% ==========================================
% [OPTIONAL] Normalize the movie to reduce issues with cross-session displays due to background intensity variations
disp('Start normalizing movies!')
inputImagesTranslated = cellfun(@(x) ciapkg.signal_processing.normalizeVector(x,'normRange','zeroToOneSoft','prctileMax',99.5,'prctileMin',0.1),inputImagesTranslated,'UniformOutput',false);
disp('Done normalizing movies!')

%% ==========================================
% Conduct fine and final motion correction now that large shifts have been made

% Get location to use for rigid motion correction of the movie
[~,inputCoords] = ciapkg.image.cropMatrix(inputImagesTranslated{:},'cropOrNaN','crop','inputCoords',[]); 

% Perform the motion correction with all movies combined
gStackCorrected = ciapkg.motion_correction.turboregMovie(cat(3,inputImagesTranslated{:}),...
	'refFrame',(refSession-1)*length(frameRange)+1,'RegisType',1,'normalizeType','matlabDisk','cropCoords',inputCoords,...
	'SmoothX',50,'SmoothY',50,'meanSubtract',1);
disp('Done registering.');

%% ==========================================
% Play motion corrected movie
ciapkg.view.playMovie(gStackCorrected);

%% Save output as a MAT file
savePostStr = '_gStackCorrected.mat';
outputMoviePath = fullfile(outputMovieFolder,[outputMovieNameStart num2str(dayList(1)) '-' num2str(dayList(nSessions)) savePostStr]);
disp(['Saving...' outputMoviePath])
save(outputMoviePath,'gStackCorrected','dayList','folderList');
disp('DONE!')

%% Save output as a TIFF file
savePostStr = '_gStackCorrected_.tif';
outputMoviePath = fullfile(outputMovieFolder,[outputMovieNameStart num2str(dayList(1)) '-' num2str(dayList(nSessions)) savePostStr]);
disp(['Saving...' outputMoviePath])
ciapkg.io.saveMatrixToFile(gStackCorrected,outputMoviePath);
disp('DONE!')

%% ==========================================
function localfun_plotInputMovies(inputImagesTranslated,nSessions,refSession,refFrameHere,dayList,yplot,run2ndPlot,sameLookupTable,cropMovieFlag)
	% Plots all input sessions as a movie montage with different methods of displaying intensity.
	if cropMovieFlag==1
		[~,cropCoordsInSession] = ciapkg.image.cropMatrix(inputImagesTranslated{refSession},'cropOrNaN','crop','inputCoords',[]); 
		for k = 1:length(inputImagesTranslated)
			inputImagesTranslated{k} = ciapkg.image.cropMatrix(inputImagesTranslated{k},'cropOrNaN','crop','inputCoords',cropCoordsInSession);
		end
	else
	end
	
	subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.005, 'Padding', 0.00, 'PaddingTop', 0.02, 'MarginTop', 0.02,'MarginBottom', 0.02,'MarginLeft', 0.01,'MarginRight', 0.01);

	xplot = ceil(nSessions/yplot);
	figure;
	allCaxis = [];
	if length(sameLookupTable)>1
		allCaxis = sameLookupTable;
	elseif sameLookupTable==1
		tmpI = cat(3,inputImagesTranslated{:});
		allCaxis = [prctile(tmpI(:),15) prctile(tmpI(:),99)];
		clear tmpI;
	elseif sameLookupTable==2
		allCaxis = [115 275];
	end
	linkAxesList = [];
	for i = 1:nSessions
		thisImg = inputImagesTranslated{i}(:,:,1);
		thisImg = imresize(thisImg,0.5);
		linkAxesList(i) = subplotTmp(xplot,yplot,i);
			imAlpha = thisImg>1e-6|thisImg~=0;
			imagesc(thisImg,'AlphaData',imAlpha);
			title([num2str(dayList(i)) ' (' num2str(i) ')'])
			axis image
			linkAxesList(i) = gca;
			box off;
			axis off;
			hold on;
			plot(round(size(thisImg,1)/2),round(size(thisImg,2)/2),'r+')
			tmpFrame = thisImg;
			tmpFrame = tmpFrame(tmpFrame>1e-6);
			if sameLookupTable~=0
				caxis(allCaxis);
			else
				caxis([prctile(tmpFrame(:),15) prctile(tmpFrame(:),99)]);
			end
			if mod(i,yplot)==0
				drawnow
			end
			drawnow
	end
	if sameLookupTable~=0
		disp('Linking axes')
		linkaxes(linkAxesList);
		hlinkHere = linkprop(linkAxesList,'CLim');
		KEY_SAVE = 'graphics_linkCLim';
		for zz = 1:length(linkAxesList)
			setappdata(linkAxesList(zz),KEY_SAVE,hlinkHere);
		end
	end
	tmpPos = get(gca,'Position');
		h=colorbar('southoutside');
		tmpPosH = get(h,'Position');
		tmpPosH = [tmpPosH(1) tmpPosH(2)-0.1 tmpPosH(3) tmpPosH(4)];
		tmpPosH(2) = 0+tmpPosH(4)++tmpPosH(4)*0.2;
		disp(tmpPosH)
		set(h,'Position',tmpPosH);
		set(gca,'Position',tmpPos);
	
	set(gcf,'color',[0 0 0]);
	ciapkg.view.changeFont(8,'fontColor','w')
	colormap([ciapkg.view.customColormap()]);

	if run2ndPlot==0
		return;
	end
	% Plot ref (green) and comparison (purple) with shift
	figure
	refFrameHere = inputImagesTranslated{refSession}(:,:,1);
	refFrameHere = ciapkg.signal_processing.normalizeVector(single(refFrameHere),'normRange','zeroToOne');
	gammaCorrectionRef = 1.5;
	rgbImage = zeros([size(refFrameHere,1) size(refFrameHere,2) 3]);
	
	refFrameHere = imadjust(refFrameHere,[],[],gammaCorrectionRef);
	for i = 1:nSessions
	
		mainFrameHere = inputImagesTranslated{i}(:,:,1);
		mainFrameHere = ciapkg.signal_processing.normalizeVector(single(mainFrameHere),'normRange','zeroToOne');
	
		mainFrameHere = imadjust(mainFrameHere,[],[],gammaCorrectionRef);
	
		rgbImage(:,:,1) = mainFrameHere; %red
		rgbImage(:,:,2) = refFrameHere; %green
		rgbImage(:,:,3) = mainFrameHere; %blue
	
		subplotTmp(xplot,yplot,i)
			imagesc(rgbImage)
			title([num2str(dayList(i)) ' (' num2str(i) ')'])
			axis image
			axis off;
			box off;
		if mod(i,yplot)==0
			drawnow
		end
	end
	set(gcf,'color',[0 0 0]);
	ciapkg.view.changeFont(10,'fontColor','w')
	suptitle('Green = reference | ')
end