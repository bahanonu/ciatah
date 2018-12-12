function obj = viewMovieRegistrationTest(obj)
	% Allow the user to test image registration over a variety of parameters to set the optimal for later motion correction
	% Biafra Ahanonu
	% started: 2016.02.03
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	try
		[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

		% check that Miji exists, if not, have user enter information
		if exist('Miji.m','file')==2
			display(['Miji located in: ' which('Miji.m')]);
			% Miji is loaded, continue
		else
			% pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
			%              'Miji path', [1 100]);
			% pathToMiji = pathToMiji{1};
			pathToMiji = uigetdir('\.','Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts)');
			if ischar(pathToMiji)
				privateLoadBatchFxnsPath = 'private\privateLoadBatchFxns.m';
				if exist(privateLoadBatchFxnsPath,'file')~=0
					fid = fopen(privateLoadBatchFxnsPath,'at')
					fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
					fclose(fid);
				end
				addpath(pathToMiji);
			end
		end

		movieSettings = inputdlg({...
				'start:end frames (leave blank for all)',...
				'number of turboreg test to run',...
				'movie regular expression',...
				'HDF5 dataset name',...
				'Treat movie as continuous (1 = yes, 0 = no)',...
			},...
			'Settings for testing movie registration',1,...
			{...
				'1:500',...
				'3',...
				'concat',...
				'/1',...
				'1',...
			}...
		);
		% And so the kings battle in the darkness
		frameList = str2num(movieSettings{1});
		nTestToRun = str2num(movieSettings{2});
		fileFilterRegexp = movieSettings{3};
		inputDatasetName = movieSettings{4};
		treatMoviesAsContinuousSwitch = str2num(movieSettings{5});

		% Get registration settings for each run
		registrationStruct = {};
		for testNo = 1:nTestToRun
			[registrationStruct{testNo}] = obj.getRegistrationSettings(['test settings: ' num2str(testNo) '/' num2str(nTestToRun)]);
		end

		% get information to ask user to select coordinates to use later
		folderList = obj.inputFolders(fileIdxArray);
		toptions.turboregType = 'preselect';
		toptions.fileFilterRegexp = fileFilterRegexp;
		toptions.processMoviesSeparately = registrationStruct{1}.processMoviesSeparately;
		toptions.refCropFrame = registrationStruct{1}.refCropFrame;
		toptions.datasetName = registrationStruct{1}.inputDatasetName;
		toptions.loadMovieInEqualParts = registrationStruct{1}.loadMovieInEqualParts;
		[registrationCoords] = subfxnCropSelection(toptions,folderList);

		% loop over all directories and copy over a specified chunk of the movie file
		savedMovieList = {};
		for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum} 10 obj.inputFolders{obj.fileNum}]);
			movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			%movieList = movieList{1};

			if toptions.loadMovieInEqualParts~=0
				movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',treatMoviesAsContinuousSwitch,'loadSpecificImgClass','single','getMovieDims',1);
				thisFrameList = frameList;
				if isempty(thisFrameList)
					tmpList = round(linspace(1,sum(movieDims.z)-100,toptions.loadMovieInEqualParts));
					display(['tmpList: ' num2str(tmpList)])
					tmpList = bsxfun(@plus,tmpList,[1:100]');
				else
					tmpList = round(linspace(1,sum(movieDims.z)-length(thisFrameList),toptions.loadMovieInEqualParts));
					display(['tmpList: ' num2str(tmpList)])
					tmpList = bsxfun(@plus,tmpList,thisFrameList(:));
				end
				frameListTmp = tmpList(:);
				frameListTmp(frameListTmp<1) = [];
				frameListTmp(frameListTmp>sum(movieDims.z)) = [];
			else
				frameListTmp = [];
			end

			% get list of frames and correct for user input
			if isempty(frameListTmp)
				if isempty(frameList)
					frameListTmp = frameList;
				else
					movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName,'getMovieDims',1,'treatMoviesAsContinuous',treatMoviesAsContinuousSwitch);
					nMovieFrames = sum(movieDims.z);
					display(['movie frames: ' num2str(nMovieFrames)]);
					if nMovieFrames<nanmax(frameList)
						frameListTmp = frameList;
						frameListTmp(frameListTmp>nMovieFrames) = [];
					else
						frameListTmp = frameList;
					end
	            end
	        end
            % frameList

			% crop coords for this folder
			cropCoords = registrationCoords{thisFileNumIdx}{1};

			for testNo = 1:nTestToRun
				display(repmat('*',1,14))
				display([num2str(testNo) '/' num2str(nTestToRun)]);
				thisRegistrationSettings = registrationStruct{testNo};
				inputMovie = [];
				% run turboreg multiple times
				numTurboregIterations = thisRegistrationSettings.numTurboregIterations;
				for regIternationNo = 1:numTurboregIterations
					[inputMovie] = subfxnRunTurboreg(thisRegistrationSettings,movieList,inputDatasetName,cropCoords,frameListTmp);
				end
				% [inputMovie] = cropInputMovie(inputMovie);

		    	newDir = [obj.inputFolders{obj.fileNum} filesep 'tregRun0' num2str(testNo)];
		    	savePathStr = [newDir filesep obj.folderBaseSaveStr{obj.fileNum} '_turboreg.h5'];
		    	if (~exist(newDir,'dir')) mkdir(newDir); end;
		    	movieSaved = writeHDF5Data(inputMovie,savePathStr);

		    	savedMovieList{thisFileNumIdx}{testNo} = savePathStr;

		    	% save the options used
		    	savestring = [newDir filesep 'settings.mat'];
		    	display(['saving: ' savestring])
		    	% save(savestring,saveVariable{i},'-v7.3','emOptions');
		    	save(savestring,'thisRegistrationSettings','cropCoords','movieList','frameListTmp');
			end
		end

		% view the movies
		Miji
		for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			%movieList = movieList{1};
			[inputMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',frameListTmp(:),'inputDatasetName',inputDatasetName,'treatMoviesAsContinuous',treatMoviesAsContinuousSwitch);
			inputMovie = single(inputMovie);
			for testNo = 1:nTestToRun
				movieListTest = savedMovieList{thisFileNumIdx}{testNo};
				[inputMovieReg] = loadMovieList(movieListTest,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName);
                if testNo==1
                    inputMovieRegAll{thisFileNumIdx}{1} = createSideBySide(inputMovie,inputMovieReg);
                else
                    inputMovieRegAll{thisFileNumIdx}{1} = createSideBySide(inputMovieRegAll{thisFileNumIdx}{1},inputMovieReg);
                end
			end
		end
		for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum} 10 obj.inputFolders{obj.fileNum}]);
            nTestToRun = 1;
			for testNo = 1:nTestToRun
				display(repmat('*',1,14))
				display([num2str(testNo) '/' num2str(nTestToRun)]);
				MIJ.createImage([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ', ' num2str(testNo) '/' num2str(nTestToRun) ': ' obj.folderBaseSaveStr{obj.fileNum}],inputMovieRegAll{thisFileNumIdx}{testNo}, true);
				MIJ.run('In [+]');
				MIJ.run('In [+]');
				MIJ.run('Start Animation [\]');
				uiwait(msgbox('press OK to move onto next movie','Success','modal'));
				MIJ.run('Close All Without Saving');
			end
		end
		MIJ.exit;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end
function [inputMovie] = subfxnRunTurboreg(regSettings,movieList,inputDatasetName,cropCoords,frameListTmp)
	% get movie, normalize, and display
	[inputMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',frameListTmp(:),'inputDatasetName',inputDatasetName,'treatMoviesAsContinuous',1);
	inputMovie = single(inputMovie);
	inputMovieRefFrame = squeeze(inputMovie(:,:,regSettings.refCropFrame));

	ioptions.turboregRotation = regSettings.turboregRotation;
	ioptions.RegisType = regSettings.RegisType;
	ioptions.parallel = regSettings.parallel;
	ioptions.meanSubtract = regSettings.normalizeMeanSubtract;
	ioptions.meanSubtractNormalize = regSettings.normalizeMeanSubtractNormalize;
	ioptions.complementMatrix = regSettings.normalizeComplementMatrix;
	ioptions.normalizeType = regSettings.normalizeType;
	ioptions.registrationFxn = regSettings.registrationFxn;
	ioptions.freqLow = regSettings.filterBeforeRegFreqLow;
	ioptions.freqHigh = regSettings.filterBeforeRegFreqHigh;
	ioptions.normalizeBeforeRegister = regSettings.filterBeforeRegister;
	ioptions.imagejFFTLarge = regSettings.filterBeforeRegImagejFFTLarge;
	ioptions.imagejFFTSmall = regSettings.filterBeforeRegImagejFFTSmall;
	ioptions.SmoothX = regSettings.SmoothX;
	ioptions.SmoothY = regSettings.SmoothY;
	ioptions.zapMean = regSettings.zapMean;

	if ~isempty(regSettings.saveFilterBeforeRegister)
		regSettings.saveFilterBeforeRegister = [thisDirSaveStr saveStr '_lowpass.h5']
	end
	ioptions.saveNormalizeBeforeRegister = regSettings.saveFilterBeforeRegister;
	ioptions.cropCoords = cropCoords;
	ioptions.closeMatlabPool = 0;
	ioptions.refFrame = regSettings.refCropFrame;
	ioptions.refFrameMatrix = inputMovieRefFrame;

    j = whos('inputMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
	[inputMovie] = turboregMovie(inputMovie,'options',ioptions);
end
function [regCoords] = subfxnCropSelection(options,folderList)
	% Biafra Ahanonu
	% 2013.11.10 [19:28:53]
	usrIdxChoiceStr = {'NO | do not duplicate coords across multiple folders','YES | duplicate coords across multiple folders','YES | duplicate coords if subject the same'};
	scnsize = get(0,'ScreenSize');
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','use coordinates over multiple folders?');
	usrIdxChoiceList = {-1,0,-2};
	applyPreviousTurboreg = usrIdxChoiceList{sel};

	folderListMinusComments = find(cellfun(@(x) isempty(x),strfind(folderList,'#')));
	nFilesToRun = length(folderListMinusComments);
	nFiles = length(folderList);
	class(folderListMinusComments)

	coordsStructure.test = [];
	for fileNumIdx = 1:nFilesToRun
		fileNum = folderListMinusComments(fileNumIdx);

		movieList = regexp(folderList{fileNum},',','split');
		% movieList = movieList{1};
		movieList = getFileList(movieList, options.fileFilterRegexp);
		if options.processMoviesSeparately==1
			nMovies = length(movieList);
		else
			nMovies = 1;
		end
		for movieNo = 1:nMovies
			switch options.turboregType
				case 'preselect'
					if strfind(folderList{fileNum},'#')==1
					    % display('skipping...')
					    continue;
					end
					% opens frame n in each movie and asks the user to pre-select a region
					% thisDir = folderList{fileNum};
					dirInfo = regexp(folderList{fileNum},',','split');
					thisDir = dirInfo{1};
					display([num2str(fileNumIdx) '/' num2str(nFilesToRun) ': ' thisDir])
					options.fileFilterRegexp
					movieList = getFileList(thisDir, options.fileFilterRegexp);
					movieList
					inputFilePath = movieList{movieNo};

					[pathstr,name,ext] = fileparts(inputFilePath);
					if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
						hinfo = hdf5info(inputFilePath);
						hReadInfo = hinfo.GroupHierarchy.Datasets(1);
						xDim = hReadInfo.Dims(1);
						yDim = hReadInfo.Dims(2);
						% select the first frame from the dataset
						thisFrame = readHDF5Subset(inputFilePath,[0 0 options.refCropFrame],[xDim yDim 1],'datasetName',options.datasetName);
					elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
						TifLink = Tiff(inputFilePath, 'r'); %Create the Tiff object
						thisFrame = TifLink.read();%Read in one picture to get the image size and data type
						TifLink.close(); clear TifLink
					end

					[figHandle figNo] = openFigure(9, '');
					subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('click, drag-n-draw region')
					set(0,'DefaultTextInterpreter','none');
					suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' 10 strrep(thisDir,'\','/')]);
					set(0,'DefaultTextInterpreter','latex');

					% Use ginput to select corner points of a rectangular
					% region by pointing and clicking the subject twice
					fileInfo = getFileInfo(thisDir);
					switch applyPreviousTurboreg
						case -1 %'NO | do not duplicate coords across multiple folders'
							% p = round(getrect);
							p = round(wait(imrect));
						case 0 %'YES | duplicate coords across multiple folders'
							% p = round(getrect);
							p = round(wait(imrect));
							coordsStructure.(fileInfo.subject) = p;
						case -2 %'YES | duplicate coords if subject the same'
							if ~any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
								% p = round(getrect);
								p = round(wait(imrect));
								coordsStructure.(fileInfo.subject) = p;
							else
								p = coordsStructure.(fileInfo.subject);
							end
						otherwise
							% body
					end

					% Get the x and y corner coordinates as integers
					regCoords{fileNum}{movieNo}(1) = p(1); %xmin
					regCoords{fileNum}{movieNo}(2) = p(2); %ymin
					regCoords{fileNum}{movieNo}(3) = p(1)+p(3); %xmax
					regCoords{fileNum}{movieNo}(4) = p(2)+p(4); %ymax

					% Index into the original image to create the new image
					pts = regCoords{fileNum}{movieNo};
					thisFrameCropped = thisFrame(pts(2):pts(4), pts(1):pts(3));

					% Display the subsetted image with appropriate axis ratio
					[figHandle figNo] = openFigure(9, '');
					subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;

					if applyPreviousTurboreg==0
						answer = inputdlg({'enter number of next folders to re-use coordinates on, click cancel if none'},'',1)
						if isempty(answer)
							applyPreviousTurboreg = 0;
						else
							applyPreviousTurboreg = str2num(answer{1});
						end
					elseif applyPreviousTurboreg>0
						applyPreviousTurboreg = applyPreviousTurboreg - 1;
						pause(0.15)
					end
					if any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
						pause(0.15)
						coordsStructure
					end
				case 'coordinates'
					% gets the coordinates of the turboreg from the filelist
					display('not implemented')
				otherwise
					% if no option selected, uses the entire FOV for each image
					display('not implemented')
					regCoords{fileNum}{movieNo}=[];
			end
		end
	end
end
function [inputMovie] = cropInputMovie(inputMovie)
	% turboreg outputs 0s where movement goes off the screen
	thisMovieMinMask = zeros([size(thisMovie,1) size(thisMovie,2)]);
	options.turboreg.registrationFxn
	switch options.turboreg.registrationFxn
		case 'imtransform'
			reverseStr = '';
			for row=1:size(thisMovie,1)
				thisMovieMinMask(row,:) = logical(nanmax(isnan(squeeze(thisMovie(3,:,:))),[],2));
				reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
			end
		case 'transfturboreg'
			reverseStr = '';
			for row=1:size(thisMovie,1)
				thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:))~=0,[],2)==0);
				reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
			end
		otherwise
			% do nothing
	end
	topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
	bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
	leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
	rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
	tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
	display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])
	if tmpPxToCrop~=0
    	if tmpPxToCrop<options.pxToCrop
    		cropMatrixPreProcess(tmpPxToCrop);
    	else
    		cropMatrixPreProcess(options.pxToCrop);
    	end
    end
end
% function [regSettingStruct] = getRegistrationSettings(inputTitleStr)
% 	regSettingDefaults = struct(...
% 	    'registrationFxn', {{'transfturboreg','imtransform'}},...
% 	    'turboregRotation',  {{0,1}},...
% 	    'RegisType', {{1,3}},...
% 	    'parallel', {{1,0}},...
% 	    'numTurboregIterations',{{1,2,3,4,5}},...
% 	    'turboregNumFramesSubset',{{15000,500,1000,2000,3000,5000,10000,15000}},...
% 	    'normalizeMeanSubtract', {{1,0}},...
% 	    'normalizeMeanSubtractNormalize', {{1,0}},...
% 	    'normalizeComplementMatrix', {{1,0}},...
% 	    'normalizeType', {{'bandpass','divideByLowpass','imagejFFT','highpass'}},...
% 	    'normalizeFreqLow',{{70,10,20,30,40,50,60,70,80,90}},...
% 	    'normalizeFreqHigh',{{100,80,90,100,110}},...
% 	    'normalizeBandpassType',{{'bandpass','lowpass','highpass'}},...
% 	    'normalizeBandpassMask',{{'gaussian','binary'}},...
% 	    'filterBeforeRegister', {{[],'divideByLowpass','imagejFFT','bandpass'}},...
% 	    'saveFilterBeforeRegister', {{[],'save'}},...
% 	    'filterBeforeRegImagejFFTLarge',{{10000,100,500,1000,5000,8000}},...
% 	    'filterBeforeRegImagejFFTSmall',{{80,10,20,30,40,50,60,70,90,100}},...
% 	    'filterBeforeRegFreqLow',{{1,3,7,30,50,70}},...
% 	    'filterBeforeRegFreqHigh',{{4,2,3,4,5,7,10,15,20,50,80,100}},...
% 	    'SmoothX',{{10,1,5,10,20,30,40,50,60,70,80,90}},...
% 	    'SmoothY',{{10,1,5,10,20,30,40,50,60,70,80,90}},...
% 	    'zapMean',{{0,1}},...
% 	    'downsampleFactorTime',{{4,2,4,6,8,10,20}},...
% 	    'datasetName',{{'/1','/Movie','/movie','/images'}},...
% 	    'fileFilterRegexp',{{'concat_.*.h5','concatenated_.*.h5','crop.*.h5','recording.*.tif','concat.*.tif'}},...
% 	    'processMoviesSeparately',{{0,1}},...
% 	    'loadMoviesFrameByFrame',{{0,1}},...
% 	    'treatMoviesAsContinuousSwitch',{{1,0}},...
% 	    'refCropFrame',{{100,1,10,100,1000}},...
% 	    'pxToCrop',{{14,15,16,17,18,19,20,21,22,23,24,25}}...
% 	);
% 	regSettingStr = struct(...
% 	    'registrationFxn', {{'transfturboreg','imtransform'}},...
% 	    'turboregRotation', {{'DO NOT turboreg rotation','DO turboreg rotation'}},...
% 	    'RegisType', {{'affine','projective'}},...
% 	    'parallel', {{'parallel processing','NO parallel processing'}},...
% 	    'numTurboregIterations',{{'1','2','3','4','5'}},...
% 	    'turboregNumFramesSubset',{{'15000','500','1000','2000','3000','5000','10000','15000'}},...
% 	    'normalizeMeanSubtract', {{'normalize movie before turboreg','do not normalize movie before turboreg'}},...
% 	    'normalizeMeanSubtractNormalize', {{'subtract mean per frame','do not subtract mean per frame'}},...
% 	    'normalizeComplementMatrix', {{'invert movie before turboreg','DO NOT invert movie before turboreg'}},...
% 	    'normalizeType', {{'bandpass','divideByLowpass','imagejFFT','highpass'}},...
% 	    'normalizeFreqLow',{{'70','10','20','30','40','50','60','70','80','90'}},...
% 	    'normalizeFreqHigh',{{'100','80','90','100','110'}},...
% 	    'normalizeBandpassType',{{'bandpass','lowpass','highpass'}},...
% 	    'normalizeBandpassMask',{{'gaussian','binary'}},...
% 	    'filterBeforeRegister', {{'NO filtering before registering','matlab divide by lowpass before registering','imageJ divide by lowpass (requires Miji!)','matlab bandpass before registering'}},...
% 	    'saveFilterBeforeRegister', {{'NO not save lowpass','DO save lowpass'}},...
% 	    'filterBeforeRegImagejFFTLarge',{{'10000','100','500','1000','5000','8000'}},...
% 	    'filterBeforeRegImagejFFTSmall',{{'80','10','20','30','40','50','60','70','90','100'}},...
% 	    'filterBeforeRegFreqLow',{{'1','3','7','30','50','70'}},...
% 	    'filterBeforeRegFreqHigh',{{'4','2','3','4','5','7','10','15','20','50','80','100'}},...
% 	    'SmoothX',{{'10','1','5','10','20','30','40','50','60','70','80','90'}},...
% 	    'SmoothY',{{'10','1','5','10','20','30','40','50','60','70','80','90'}},...
% 	    'zapMean',{{'0','1'}},...
% 	    'downsampleFactorTime',{{'4','2','4','6','8','10','20'}},...
% 	    'datasetName',{{'/1','/Movie','/movie','/images'}},...
% 	    'fileFilterRegexp',{{'concat_.*.h5','concatenated_.*.h5','crop.*.h5','recording.*.tif','concat.*.tif'}},...
% 	    'processMoviesSeparately',{{'no','yes'}},...
% 	    'loadMoviesFrameByFrame',{{'no','yes'}},...
% 	    'treatMoviesAsContinuousSwitch',{{'yes','no'}},...
% 	    'refCropFrame',{{'100','1','10','100','1000'}},...
% 	    'pxToCrop',{{14,15,16,17,18,19,20,21,22,23,24,25}}...
% 	);

% 	% propertySettings = regSettingDefaults;

% 	propertyList = fieldnames(regSettingDefaults);
% 	nPropertiesToChange = size(propertyList,1);

% 	% add current property to the top of the list
% 	for propertyNo = 1:nPropertiesToChange
% 		property = char(propertyList(propertyNo));
% 		propertyOptions = regSettingStr.(property);
% 		propertySettingsStr.(property) = propertyOptions;
% 		% propertySettingsStr.(property);
% 	end

% 	uiListHandles = {};
% 	uiTextHandles = {};
% 	uiXOffset = 0.05;
% 	uiXIncrement = 0.025;
% 	uiYOffset = 0.93;
% 	uiTxtSize = 0.5;
% 	uiBoxSize = 0.5;
% 	uiFontSize = 10;
% 	[figHandle figNo] = openFigure(1337, '');
% 	clf
% 	uicontrol('Style','Text','String',inputTitleStr,'Units','normalized','Position',[uiXOffset uiYOffset+0.01 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');

% 	for propertyNo = 1:nPropertiesToChange
% 		property = char(propertyList(propertyNo));
% 		uiTextHandles{propertyNo} = uicontrol('Style','text','String',[property ': ' 10],'Units','normalized','Position',[uiXOffset uiYOffset-uiXIncrement*propertyNo+0.027 uiTxtSize 0.0225],'BackgroundColor',[0.9 0.9 0.9],'ForegroundColor','black','HorizontalAlignment','Left','FontSize',uiFontSize);
% 		% jEdit = findjobj(uiTextHandles{propertyNo});
% 		% lineColor = java.awt.Color(1,0,0);  % =red
% 		% thickness = 3;  % pixels
% 		% roundedCorners = true;
% 		% newBorder = javax.swing.border.LineBorder(lineColor,thickness,roundedCorners);
% 		% jEdit.Border = newBorder;
% 		% jEdit.repaint;  % redraw the modified control
% 		% uiTextHandles{propertyNo}.Enable = 'Inactive';
% 		% optionCallback = ['set(uiListHandles{propertyNo}, ''Backgroundcolor'', ''g'')'];
% 		uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiXOffset+uiTxtSize uiYOffset-uiXIncrement*propertyNo uiBoxSize 0.05],'Callback',@(hObject,callbackdata){set(hObject, 'Backgroundcolor', [208,229,180]/255)},'FontSize',uiFontSize);
% 	end
% 	uicontrol('Style','Text','String','press enter to continue','Units','normalized','Position',[uiXOffset uiYOffset-uiXIncrement*(nPropertiesToChange+2) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
% 	% uicontrol('Style','Text','String',inputTitleStr,'Units','normalized','Position',[0.0 uiYOffset 0.15 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
% 	pause

% 	for propertyNo = 1:nPropertiesToChange
% 		property = char(propertyList(propertyNo));
% 		uiListHandleData = get(uiListHandles{propertyNo});
% 		regSettingStruct.(property) = regSettingDefaults.(property){uiListHandleData.Value};
% 	end
% 	close(1337)

% 	% ensure rotation setting matches appropriate registration type
% 	if regSettingStruct.turboregRotation==1
% 		regSettingStruct.RegisType = 3;
% 	end
% end