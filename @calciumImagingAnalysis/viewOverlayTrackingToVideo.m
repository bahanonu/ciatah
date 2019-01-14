function obj = viewOverlayTrackingToVideo(obj)
	% Creates overlay video of mouse location tracking.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.15 [00:54:35] - updated naming scheme inputImages/inputSignals
	% TODO
		%

	%========================
	% continuous variables to analyze
	options.var1 = 'XM';%XM_cm
	options.var2 = 'YM';%YM_cm
	options.var3 = 'Angle';
	options.framesPerSecond = 20;
	% cutoff value for velocity in open field analysis
	options.STIM_CUTOFF = 5;
	% options.STIM_CUTOFF = 0.05;
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try

		[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
        if iscell(obj.videoDir); videoDir = strjoin(obj.videoDir,','); else videoDir = obj.videoDir; end;
		trackingSettings = inputdlg({...
					'video folder(s), separate multiple folders by a comma:',...
					'side-by-side save folder:',...
					'frames per second',...
					'frames to use for video (blank = all)',...
					'stimulus cutoff in cm/s',...
				},...
				'tracking clean-up settings',1,...
				{...
					videoDir,......
					obj.videoSaveDir,...
					num2str(options.framesPerSecond),...
					'1:400',...
					num2str(options.STIM_CUTOFF),...
				}...
			);
        obj.videoDir = strsplit(trackingSettings{1},','); videoDir = obj.videoDir;
		obj.videoSaveDir = trackingSettings{2}; videoSaveDir = obj.videoSaveDir;
		options.framesPerSecond = str2num(trackingSettings{3});
		options.nFramesUse = str2num(trackingSettings{4});
		options.STIM_CUTOFF = str2num(trackingSettings{5});

		videoTrialRegExp = '';
		videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','yymmdd_mNNN_assayNN','subject_assay','yymmdd_mNNN'};
				scnsize = get(0,'ScreenSize');
		[videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
		local_getVideoRegexp();

		for thisFileNumIdx = 1:length(fileIdxArray)
			thisFileNum = fileIdxArray(thisFileNumIdx);
			fileNum = thisFileNum;
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);

			% compareTrackingToMovie = 0;
			% if compareTrackingToMovie==1
			nameArray = obj.continuousStimulusNameArray;
			saveNameArray = obj.continuousStimulusSaveNameArray;
			idArray = obj.continuousStimulusIdArray;
			% obtain stimulus information
			class(idArray(find(ismember(nameArray,options.var1))))
			iioptions.array = 'continuousStimulusArray';
			iioptions.nameArray = 'continuousStimulusNameArray';
			iioptions.idArray = 'continuousStimulusIdArray';
			iioptions.stimFramesOnly = 1;
			XM = obj.modelGetStim(idArray(find(ismember(nameArray,'XM'))),'options',iioptions);
			YM = obj.modelGetStim(idArray(find(ismember(nameArray,'YM'))),'options',iioptions);
			if isempty(YM); continue; end;
			% movement.Angle = obj.modelGetStim(idArray(find(ismember(nameArray,options.var3))),'options',iioptions);
			xdiff = [0; diff(XM)];
			ydiff = [0; diff(YM)];
			thisVel = sqrt(xdiff.^2 + ydiff.^2)*options.framesPerSecond;
			% XM(thisVel>30) = NaN;
			% YM(thisVel>30) = NaN;
			% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
			% if isempty(inputSignals); continue; end;
			% outputData = compareSignalToMovement(inputSignals,movement,'makePlots',0);
			% thisVel = outputData.downsampledVelocity*obj.FRAMES_PER_SECOND;
			thisVel = thisVel*options.framesPerSecond;
			% thisVel = interp1(1:length(thisVel),thisVel,linspace(1,length(thisVel),length(thisVel)*4));
			velocity = (thisVel'>options.STIM_CUTOFF);

			% options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			local_getVideoRegexp();
			vidList = getFileList(obj.videoDir,videoTrialRegExp);

			% plot
			% if ~isempty(idNumIdxArray)
			[xPlot yPlot] = getSubplotDimensions(length(idNumIdxArray)+1);
			behaviorMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',50:51,'treatMoviesAsContinuous',1);
			figure(thisFileNumIdx)
			% subplot(xPlot,yPlot,1)
				imagesc(squeeze(behaviorMovie(:,:,1)))
				title(obj.folderBaseSaveStr{obj.fileNum})
				colormap gray;
				axis image;
				hold on;
				box off; axis off;
				viewColorLinePlot(XM,YM,'nPoints',200,'colors',customColormap({[0 0 0],[0 1 0],[1 0 0]}));
				% downsampleFactor = 4;
			obj.modelSaveImgToFile([],'viewOverlayTrackingToVideo_overlay','current',[]);
			% end

			% =====================
			saveTrackingVideo = 1;
			if saveTrackingVideo==1

				% movieFilePath = getFileList(obj.videoDir,obj.folderBaseSaveStr{obj.fileNum});
				% saveMoviePath = [obj.videoSaveDir filesep obj.folderBaseSaveStr{obj.fileNum}];

				movieFilePath = getFileList(obj.videoDir,videoTrialRegExp);
				saveMoviePath = [obj.videoSaveDir filesep videoTrialRegExp];

				XM_cm = obj.modelGetStim(idArray(find(ismember(nameArray,'XM_cm'))),'options',iioptions);
				YM_cm = obj.modelGetStim(idArray(find(ismember(nameArray,'YM_cm'))),'options',iioptions);
				xdiff = [0; diff(XM_cm)];
				ydiff = [0; diff(YM_cm)];
				thisVel = sqrt(xdiff.^2 + ydiff.^2);
				thisVel = tsmovavg(thisVel*options.framesPerSecond,'s',options.framesPerSecond,1);

				stimVector = thisVel>options.STIM_CUTOFF;
				figure;plot(thisVel);hold on;plot(stimVector);
				movTmp.initiation = find([0 diff(stimVector(:))']==1);
				framesRestMoving = 20;
				for movNo = 1:length(movTmp.initiation)
					try
						movIdx = movTmp.initiation(movNo);
						thisVelPre = thisVel(movIdx-framesRestMoving:movIdx);
						thisVelPost = thisVel(movIdx:movIdx+framesRestMoving);
						if nanmean(thisVelPre)>STIM_CUTOFF|nanmean(thisVelPost)<STIM_CUTOFF
							movTmp.initiation(movNo) = NaN;
						end
					catch
					end
				end
				movTmp.initiation = movTmp.initiation(~isnan(movTmp.initiation));

				XM_px = obj.modelGetStim(idArray(find(ismember(nameArray,'XM'))),'options',iioptions);
				YM_px = obj.modelGetStim(idArray(find(ismember(nameArray,'YM'))),'options',iioptions);

				nFramesUse = options.nFramesUse;
				[inputTrackingVideo] = createTrackingOverlayVideo(movieFilePath{1},XM_px(nFramesUse),YM_px(nFramesUse),'saveMoviePath',saveMoviePath,'frameList',nFramesUse,'STIM_CUTOFF',options.STIM_CUTOFF,'framesPerSecond',options.framesPerSecond,'velocity',stimVector(nFramesUse));
				size(inputTrackingVideo)
				continue

				% nPtsVector2 = size(inputSignals,2);
				% XM_px = interp1(1:length(XM_px),XM_px,linspace(1,length(XM_px),nPtsVector2));
				% YM_px = interp1(1:length(YM_px),YM_px,linspace(1,length(YM_px),nPtsVector2));

				timeVector = [-framesRestMoving:framesRestMoving]';
				peakIdxs = movTmp.initiation(:)';
				try
					peakIdxs = peakIdxs(2:15);
				catch
					peakIdxs = peakIdxs(2:end);
				end
				peakIdxs = bsxfun(@plus,timeVector,peakIdxs);
				peakIdxs = peakIdxs(:);
				peakIdxs(peakIdxs<1) = [];

				peakIdxs

				% peakIdxs(peakIdxs>nPtsVector2) = [];
				tmpMovie = loadMovieList(getFileList(obj.inputFolders{obj.fileNum},obj.fileFilterRegexp),'frameList',peakIdxs);
				[inputTrackingVideo] = createTrackingOverlayVideo(movieFilePath{1},XM_px(peakIdxs),YM_px(peakIdxs),'saveMoviePath',saveMoviePath,'frameList',peakIdxs,'STIM_CUTOFF',options.STIM_CUTOFF,'framesPerSecond',options.framesPerSecond);
				% pause
			end
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function local_getVideoRegexp()
		switch videoTrialRegExpIdx
			case 1
				videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			case 2
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
			case 3
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'_',obj.subjectStr{obj.fileNum},'_',obj.assay{obj.fileNum});
			case 4
				videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
			case 5
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'_',obj.subjectStr{obj.fileNum});
			otherwise
				videoTrialRegExp = fileFilterRegexp
		end
	end
end