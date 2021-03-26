function obj = computeMatchObjBtwnTrials(obj,varargin)
	% Match cells across imaging sessions.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.07.03 [16:36:32] - Updated to call viewMatchObjBtwnSessions afterwards as an option
	% TODO
		%

	%========================
	% DESCRIPTION
	options.exampleOption = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% scnsize = get(0,'ScreenSize');
	% [fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','choose which trial to align to?');

	nFiles = length(obj.rawSignals);
	subjectList = unique(obj.subjectStr);

	% if obj.guiEnabled==1
	% 	scnsize = get(0,'ScreenSize');
	% 	[subjIdxArray, ok] = listdlg('ListString',subjectList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which subjects to analyze?');
	% 	subjectList = {subjectList{subjIdxArray}}
	% else
	% 	% idNumIdxArray = 1:length(obj.stimulusNameArray);
	% 	% fileIdxArray = 1:length(obj.fileIDNameArray);
	% end
	[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = obj.getAnalysisSubsetsToAnalyze();

	for thisFileNumIdx = [342 343 344 9019 59857 65 66]
		[~, ~] = openFigure(thisFileNumIdx, '');
	end
	drawnow

	% if obj.guiEnabled~=1
	% else
	% 	usrIdxChoice = userDefaults;
	% end
	scnsize = get(0,'ScreenSize');
	userDefaults = {'1','5','0.4','','2','1','corr2','0.6','0.3','1e-6','0','1'};
	usrIdxChoice = inputdlg({...
		'Number of rounds to register images (integer)',...
		'Distance threshold to match cells cross-session (in pixels)',...
		'Image binarization threshold (0 to 1, fraction each image''s max value)',...
		'Session to align to (leave blank to auto-calculate middle session to use for alignment)',...
		'Registration type (3 = rotation and iso scaling, 2 = rotation no iso scaling)',...
		'Run image correlation threshold? (1 = yes, 0 = no)',...
		'Image correlation type (e.g. "corr2","jaccard")',...
		'Image correlation threshold for matched cells (0 to 1)',...
		'Image correlation binarization threshold (0 to 1, fraction each image''s max value)',...
		'Threshold below which registered image values set to zero',...
		'Visually compare image correlation values and matched images (1 = yes, 0 = no)',...
		'View full results after [viewMatchObjBtwnSessions] (1 = yes, 0 = no)',...
		},'Cross-session cell alignment options',1,...
		userDefaults);

	% options.frameList = [1:500];
	s1 = 1;
	nCorrections = str2num(usrIdxChoice{s1});s1=s1+1;
	maxDistance = str2num(usrIdxChoice{s1});s1=s1+1;
	imageThreshold = str2num(usrIdxChoice{s1});s1=s1+1;
	trialToAlignUserOption = str2num(usrIdxChoice{s1});s1=s1+1;
	RegisTypeFinal = str2num(usrIdxChoice{s1});s1=s1+1;
	runImageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	imageCorrType = usrIdxChoice{s1};s1=s1+1;
	imageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	imageCorrThres = str2num(usrIdxChoice{s1});s1=s1+1;
	checkImageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	turboregZeroThres = str2num(usrIdxChoice{s1});s1=s1+1;
	runViewMatchObjBtwnSessions = str2num(usrIdxChoice{s1});s1=s1+1;

	for thisSubjectStr=subjectList
		try
			display(repmat('=',1,21))
			thisSubjectStr = thisSubjectStr{1};
			display([thisSubjectStr]);
			validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
			% filter for folders chosen by the user
			validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
			if isempty(validFoldersIdx)
				continue;
			end
			rawSignals = {};
			rawImages = {};
			for idx = 1:length(validFoldersIdx)
			% for idx = 1:2
				obj.fileNum = validFoldersIdx(idx);
				display(repmat('*',1,7))
				display([num2str(idx) '/' num2str(length(validFoldersIdx)) ': ' obj.fileIDNameArray{obj.fileNum}]);
				% obj.folderBaseSaveStr{obj.fileNum}
				% [rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
				[rawSignalsTmp, rawImagesTmp, signalPeaks, signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered');
				if ~isempty(rawSignalsTmp)
					display('adding to alignment...')
					rawSignals{end+1} = rawSignalsTmp;
					rawImages{end+1} = rawImagesTmp;
				else
					display('removing from alignment...')
					validFoldersIdx(idx) = -1;
				end
				% % ======
				% validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				% % validManualIdx = find(arrayfun(@(x) isempty(x{1}),obj.validManual));
				% % classifyFoldersIdx = intersect(validFoldersIdx,validManualIdx);
				% movieList = getFileList({obj.inputFolders{validFoldersIdx}}, fileFilterRegexp);
				% movieList
				% subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',1:2);
				% % movieFrame = squeeze(movieFrame(:,:,1));
				% subjectMovieFrames = subjectMovieFrames(:,:,1:2:end);
				% ======
				% % max projection of DFOF
				% movieList = getFileList({obj.inputFolders{obj.fileNum}}, 'dfof');
				% movieList
				% subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',1:1000);
				% subjectMovieFrames = nanmax(subjectMovieFrames,[],3);
				% movieFrames(1,:,:) = subjectMovieFrames;
				% size(subjectMovieFrames)
				% additionalAlignmentImages{1}{idx} = movieFrames;
				% ======
				% average of normal movie
				% movieList = getFileList({obj.inputFolders{validFoldersIdx}}, 'concat');
				useAdditionalImages = 0;
				if useAdditionalImages == 1
					movieList = getFileList({obj.inputFolders{obj.fileNum}}, 'concat');
					movieList
					subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',1:50);
					subjectMovieFrames = nanmean(subjectMovieFrames,3);
					movieFrames(1,:,:) = subjectMovieFrames;
					size(subjectMovieFrames)
					additionalAlignmentImages{1}{idx} = movieFrames;
					clear movieFrames;
				end
				% ======
			end

			validFoldersIdx(validFoldersIdx==-1) = [];
			display(['validFoldersIdx: ' num2str(size(validFoldersIdx))])
			display(['rawSignals: ' num2str(size(rawSignals))])
			display(['rawImages: ' num2str(size(rawImages))])

			if isempty(trialToAlignUserOption)
				trialToAlign = floor(quantile(1:length(validFoldersIdx),0.5));
			else
				trialToAlign = trialToAlignUserOption;
			end
			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',trialToAlign,'additionalAlignmentImages',additionalAlignmentImages,'nCorrections',nCorrections);

			clear mOpts;

			mOpts.inputSignals = rawSignals;
			mOpts.trialToAlign = trialToAlign;
			mOpts.additionalAlignmentImages = [];
			mOpts.nCorrections = nCorrections;
			mOpts.maxDistance = maxDistance;
			mOpts.threshold = imageThreshold;
			mOpts.RegisTypeFinal = RegisTypeFinal;
			mOpts.imageCorr = imageCorr;
			mOpts.runImageCorr = runImageCorr;
			mOpts.checkImageCorr = checkImageCorr;
			mOpts.turboregZeroThres = turboregZeroThres;
			mOpts.imageCorrType = imageCorrType;
			mOpts.imageCorrThres = imageCorrThres;

			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',trialToAlign,'additionalAlignmentImages',[],'nCorrections',nCorrections,'maxDistance',maxDistance,'threshold',imageThreshold,'RegisTypeFinal',RegisTypeFinal);
			alignmentStruct = matchObjBtwnTrials(rawImages,'options',mOpts);

			obj.globalIDStruct.(thisSubjectStr) = alignmentStruct;
			obj.globalIDs.(thisSubjectStr) = alignmentStruct.globalIDs;
			obj.globalIDs.alignmentStruct.(thisSubjectStr) = alignmentStruct;
			obj.globalIDCoords.(thisSubjectStr).localCoords = alignmentStruct.coords;
			obj.globalIDCoords.(thisSubjectStr).globalCoords = alignmentStruct.coordsGlobal;
			obj.globalRegistrationCoords.(thisSubjectStr) = alignmentStruct.registrationCoords;
			% enter assay names into globalIDFolders for later retrieval
			convertTrialNumbersToAssayStr();
			% obj.globalIDFolders.(thisSubjectStr) = alignmentStruct.trialIDs;
			% obj.globalIDImages.(thisSubjectStr) = alignmentStruct.inputImages;
			obj.globalObjectMapTurboreg.(thisSubjectStr).turboreg = alignmentStruct.objectMapTurboreg;
			obj.globalObjectMapTurboreg.(thisSubjectStr).additional = alignmentStruct.objectMapAdditional;
			[figHandle figNo] = openFigure(65, '');
			obj.modelSaveImgToFile([],'matchObjsAll_','current',thisSubjectStr);
			[figHandle figNo] = openFigure(66, '');
			obj.modelSaveImgToFile([],'matchObjsAllGlobal_','current',thisSubjectStr);
			% close all;
			saveDirPath = [obj.videoSaveDir filesep 'matchObjsGlobal\'];
			mkdir(saveDirPath);
			[output] = writeHDF5Data(obj.globalObjectMapTurboreg.(thisSubjectStr).turboreg,[saveDirPath thisSubjectStr '_cellmap_turboreg.h5']);
			% options.comp = 'no';
			% saveastiff(obj.globalObjectMapTurboreg.(thisSubjectStr).turboreg, [saveDirPath thisSubjectStr '_cellmap_turboreg.tif'], options);
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	if runViewMatchObjBtwnSessions==1
		for thisSubjectStr=subjectList
			try
				display(repmat('=',1,21))
				thisSubjectStr = thisSubjectStr{1};
				display([thisSubjectStr]);
				obj.viewMatchObjBtwnSessions('runGui',0);
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
	end
	function convertTrialNumbersToAssayStr()
		% thisSubjectStr = thisSubjectStr{1};
		% display([thisSubjectStr]);
		% validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
		% % filter for folders chosen by the user
		% validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
		% if isempty(validFoldersIdx)
		% 	continue;
		% end
		% [obj.globalIDFolders.(thisSubjectStr){:}].
		trialIDsTmp = alignmentStruct.trialIDs;
		trialIDsTmp
		validFoldersIdx
		validFoldersIdx = validFoldersIdx([trialIDsTmp{:}]);
		validFoldersIdx
		% globalAssayStr = obj.folderBaseSaveStr(validFoldersIdx);
		globalAssayStr = obj.folderBaseSaveStrUnique(validFoldersIdx);
		obj.globalIDFolders.(thisSubjectStr) = globalAssayStr;
	end
end