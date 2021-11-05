function [inputTrackingVideo] = createTrackingOverlayVideo(inputTrackingVideo,inputX,inputY,varargin)
	% Takes tracking data and makes an overlay on a behavioral movie.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputTrackingVideo - [x y frames] movie or path to AVI file
		% inputX - [1 frames] vector or path to csv table
		% inputY - [1 frames] vector or blank of inputX is a path
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.extraVideo = '';
	% velocity cutoff to say if object is moving
	options.STIM_CUTOFF = 25;
	% speed for middle cutoff
	options.midCutoff = 10;
	% frames per second
	options.framesPerSecond = 5;
	% speed for high cutoff
	options.highCutoff = 20;
	% frame list if loading movie
	options.frameList= [];
	% how much is input movie downsampled, used if only loaded every nth frame.
	options.downsampleFactor = 1;
	% amount to downsample the movie before saving
	options.downsampleMovieFactor = 2;
	% path to save movie
	options.saveMoviePath = [];
	% input velocity vector
	options.velocity = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		% load table and get coordinates if path input.
		inputXClass = class(inputX);
		if strcmp(inputXClass,'char')
			[trackingTableFilteredCell] = removeIncorrectObjs(inputX);
            if iscell(trackingTableFilteredCell)
                inputX = trackingTableFilteredCell{1}.XM;
                inputY = trackingTableFilteredCell{1}.YM;
            else
                inputX = trackingTableFilteredCell.XM;
                inputY = trackingTableFilteredCell.YM;
            end
		    % [pathstr,name,ext] = fileparts(inputFilePath);
		    % options.newFilename = [pathstr '\concat_' name '.h5'];
		end

		xdiff = [0; diff(inputX(:))];
		ydiff = [0; diff(inputY(:))];
		thisVel = sqrt(xdiff.^2 + ydiff.^2)*options.framesPerSecond;
		if isempty(options.velocity)
			velocity = (thisVel'>options.STIM_CUTOFF);
		else
			velocity = options.velocity;
		end

		XM = inputX;
		YM = inputY;

		downsampleFactor = options.downsampleFactor;
		% adjIdx = 0;
		% frameListIdx = (1+adjIdx):(adjIdx+1500);
		% options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		% vidList = getFileList(obj.videoDir,options.videoTrialRegExp);
		% vidList(:)
		inputMovieClass = class(inputTrackingVideo);
		if strcmp(inputMovieClass,'char')
		    inputTrackingVideo = loadMovieList(inputTrackingVideo,'frameList',options.frameList);
		    % [pathstr,name,ext] = fileparts(inputFilePath);
		    % options.newFilename = [pathstr '\concat_' name '.h5'];
		end
		% inputTrackingVideo = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListIdx*downsampleFactor,'treatMoviesAsContinuous',1);
		% obj.videoDir
		% signalBasedSuffix = 'openfield_tracking.avi';
		% savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} signalBasedSuffix]

		nFrames = size(inputTrackingVideo,3)
		% magnitudeVector = round(thisVel*10);
		magnitudeVector = round(thisVel);
		% magnitudeVector = magnitudeVector/max(magnitudeVector);
		% magnitudeVector = magnitudeVector*20;
		midCutoff = options.midCutoff;
		highCutoff = options.highCutoff;
		reverseStr = '';
		inputTrackingVideoY = size(inputTrackingVideo,1);
		inputTrackingVideoX = size(inputTrackingVideo,2);
		% inputY = inputTrackingVideoY - inputY;
		% inputX = inputTrackingVideoX - inputX;
		frameListIdx = 1:nFrames;
		for frameNoIdx=1:nFrames
			% frameNo = frameListIdx(frameNoIdx);
			frameNo = frameNoIdx;
			frameNoTrue = downsampleFactor*frameListIdx(frameNoIdx);
			% frameNo
			% frameNoTrue
			try
				if isnan(inputX(frameNoTrue))|isnan(inputY(frameNoTrue))
					continue
				end
				thisXM = ceil(inputX(frameNoTrue));
				thisYM = ceil(inputY(frameNoTrue));
				thisMagnitudeVector = magnitudeVector(frameNoTrue);
				% [thisXM thisYM thisMagnitudeVector]
				subValue = Inf;
				inputTrackingVideo(thisYM,thisXM,frameNo) = subValue;
				% add cross-hairs
				inputTrackingVideo(thisYM-3,(thisXM-2:thisXM+2),frameNo) = subValue;
				inputTrackingVideo(thisYM+3,(thisXM-2:thisXM+2),frameNo) = subValue;
				inputTrackingVideo((thisYM-2:thisYM+2),thisXM-3,frameNo) = subValue;
				inputTrackingVideo((thisYM-2:thisYM+2),thisXM+3,frameNo) = subValue;
				% add cutoff values
				widthLines = 3;
				inputTrackingVideo(thisYM-midCutoff,(thisXM-widthLines:thisXM+widthLines),frameNo) = subValue;
				inputTrackingVideo(thisYM-highCutoff,(thisXM-widthLines:thisXM+widthLines),frameNo) = subValue;
				inputTrackingVideo((thisYM-widthLines:thisYM+widthLines),thisXM-midCutoff,frameNo) = subValue;
				inputTrackingVideo((thisYM-widthLines:thisYM+widthLines),thisXM-highCutoff,frameNo) = subValue;
				% add vector for moving/nonmoving and velocity
				if velocity(frameNoTrue)==1
					if (thisYM-thisMagnitudeVector)<1
						thisYM = 1:thisYM;
					else
						thisYM = (thisYM-thisMagnitudeVector):thisYM;
					end
					inputTrackingVideo(thisYM,(thisXM-1:thisXM+1),frameNo) = subValue;
				else
					if (thisXM-thisMagnitudeVector)<1
						thisXM = 1:thisXM;
					else
						thisXM = (thisXM-thisMagnitudeVector):thisXM;
					end
					inputTrackingVideo((thisYM-1:thisYM+1),thisXM,frameNo) = subValue;
				end
				reverseStr = cmdWaitbar(frameNoIdx,nFrames,reverseStr,'inputStr','adding tracking to behavior video','waitbarOn',1,'displayEvery',5);
			catch
				[thisXM thisYM thisMagnitudeVector]
			end
		end

		if ~isempty(options.saveMoviePath)
			% signalBasedSuffix = 'openfield_tracking_lzw.tif';
			% savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_' signalBasedSuffix]
			savePathName = options.saveMoviePath;

			inputTrackingVideo = downsampleMovie(inputTrackingVideo,'downsampleFactor',options.downsampleMovieFactor,'downsampleDimension','space');

			% movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
			% size(unique(ceil(frameListIdx/4)))
			% size(inputTrackingVideo)

			if isempty(options.extraVideo)
			else
				inputMovieClass = class(options.extraVideo);
				if strcmp(inputMovieClass,'char')
					% [options.extraVideo] = loadMovieList(movieList{1},'convertToDouble',0,'frameList',frameListIdx);
				else
				end
				[inputTrackingVideo] = createSideBySide(inputTrackingVideo,options.extraVideo,'pxToCrop',[]);
			end

			fprintf('saving to %s',savePathName)
			% saveastiff(inputTrackingVideo, savePathName, options);
			movieSaved = writeHDF5Data(inputTrackingVideo,[savePathName '.h5']);
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
function [downsampledVector1] = downsampleVector(vector1,vector2)
	% dowmsamples vector1 to have the same length as vector 2
	nPtsVector2 = length(vector2);
	downsampledVector1 = interp1(1:length(vector1),vector1,linspace(1,length(vector1),nPtsVector2));
end