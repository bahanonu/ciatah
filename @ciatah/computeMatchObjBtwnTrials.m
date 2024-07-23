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
		% 2021.06.18 [21:41:07] - added modelVarsFromFilesCheck() to check and load signals if user hasn't already.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.11.05 [14:13:36] - Added manual alignment option before automated for cases in which there are large shifts or rotations along with changes in bulk cells identified that might be hard for automated to align.
		% 2023.05.08 [18:55:36] - Added the option to only keep cells within a specific region of the FOV, useful for when want to register cells in a single region and don't want other cells affecting alignment.
		% 2023.05.09 [11:52:23] - Add support for normcorre and imregdemons for registration.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

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

	% Check for prior user inputs
	if isfield(obj.functionSettings,'computeMatchObjBtwnTrials')
		uOpts = obj.functionSettings.computeMatchObjBtwnTrials;
		userDefaults = {
			uOpts.nCorrections;
			uOpts.maxDistance;
			uOpts.imageThreshold;
			uOpts.trialToAlignUserOption;
			uOpts.RegisTypeFinal;
			uOpts.runImageCorr;
			uOpts.imageCorrType;
			uOpts.imageCorr;
			uOpts.imageCorrThres;
			uOpts.checkImageCorr;
			uOpts.turboregZeroThres;
			uOpts.runViewMatchObjBtwnSessions;
			uOpts.imagesType;
			uOpts.runManualAlign;
			uOpts.runRemoveRegion;
			uOpts.sizeThresMax;
			uOpts.mcMethod;
			uOpts.registrationFxn;
		};
		userDefaults = cellfun(@num2str,userDefaults,'UniformOutput',false);
	else
		% userDefaults = {'1','5','0.4','','2','1','corr2','0.6','0.3','1e-6','0','1','filtered','0','0','','turboreg','transfturboreg'};
		userDefaults = {
			'1';
			'5';
			'0.4';
			'';
			'2';
			'1';
			'corr2';
			'0.6';
			'0.3';
			'1e-6';
			'0';
			'1';
			'filtered';
			'0';
			'0';
			'';
			'turboreg';
			'transfturboreg';
		};
	end

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
		'Type of image to use for cross-session alignment? (filtered, raw)',...
		'Manual cross-session alignment? (1 = yes, 0 = no)'...
		'Only keep cells in user defined region of FOV? (1 = yes, 0 = no)',...
		'Int: Maximum size of cell? (leave blank to skip)'...
		'Registration method? "turboreg", normcorre", or "imregdemons"'...
		'Registration function? "imtransform", "imwarp", "transfturboreg"'...
		},'Cross-session cell alignment options',1,...
		userDefaults);

	% options.frameList = [1:500];
	s1 = 1;
	uOpts = struct;
	uOpts.nCorrections = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.maxDistance = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.imageThreshold = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.trialToAlignUserOption = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.RegisTypeFinal = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.runImageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.imageCorrType = usrIdxChoice{s1};s1=s1+1;
	uOpts.imageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.imageCorrThres = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.checkImageCorr = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.turboregZeroThres = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.runViewMatchObjBtwnSessions = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.imagesType = usrIdxChoice{s1};s1=s1+1;
	uOpts.runManualAlign = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.runRemoveRegion = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.sizeThresMax = str2num(usrIdxChoice{s1});s1=s1+1;
	uOpts.mcMethod = usrIdxChoice{s1};s1=s1+1;
	uOpts.registrationFxn = usrIdxChoice{s1};s1=s1+1;

	% Save user settings to object
	if isfield(obj.functionSettings,'computeMatchObjBtwnTrials')
		% Do nothing
	else
		obj.functionSettings.computeMatchObjBtwnTrials = struct;
	end
	obj.functionSettings.computeMatchObjBtwnTrials = uOpts;

	for thisSubjectStr = subjectList
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

				% Check that signal extraction information is loaded.
				obj.modelVarsFromFilesCheck(obj.fileNum);

				% obj.folderBaseSaveStr{obj.fileNum}
				% [rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
				[rawSignalsTmp, rawImagesTmp, signalPeaks, signalPeaksArray] = modelGetSignalsImages(obj,'returnType',uOpts.imagesType);
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

			if isempty(uOpts.trialToAlignUserOption)
				trialToAlign = floor(quantile(1:length(validFoldersIdx),0.5));
			else
				trialToAlign = uOpts.trialToAlignUserOption;
			end

			% Automatically remove 
			if ~isempty(uOpts.sizeThresMax)
				disp('Filtering cell inputs')
				filterImageOptions = struct(...
					'minNumPixels', 10,...
					'maxNumPixels', 100,...
					'SNRthreshold', 1.45,...
					'minPerimeter', 5,...
					'maxPerimeter', 50,...
					'minSolidity', 0.8,...
					'maxSolidity', 1.0,...
					'minEquivDiameter', 3,...
					'maxEquivDiameter', 30,...
					'slopeRatioThreshold', 0.04...
				);
				nSessions = length(rawImages);
				for sessionNo = 1:nSessions
					disp('===')
					disp(sessionNo)
					[~, ~, validAuto, imageSizes, imgFeatures] = ciapkg.image.filterImages(rawImages{sessionNo}, [],'featureList',{'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity'},'options',filterImageOptions);
					signalsToKeep = imageSizes<uOpts.sizeThresMax & imgFeatures(:,1)<0.95;
					rawImages{sessionNo} = rawImages{sessionNo}(:,:,signalsToKeep);
					rawSignals{sessionNo} = rawSignals{sessionNo}(signalsToKeep,:);
				end
			end

			% Align manually if user requests.
			if uOpts.runManualAlign==1
				[rawImages, outputStruct] = computeManualMotionCorrection(rawImages,'registerUseOutlines',0,'cellCombineType','max','gammaCorrection',1.6,'refFrame',trialToAlign);
			end

			% GUI for user to select a region to keep
			if uOpts.runRemoveRegion
				figure;
				% if exist('inputMovieFrame','var')
				% 	subplot(2,2,2)
				% 	imagesc(inputMovieFrame)
				% 	axis image
				% 	box off;
				% end
				nSessions = length(rawImages);
				[xplot,yplot] = ciapkg.view.getSubplotDimensions(nSessions+1);

				subplot(xplot,yplot,1)
				try
					% imagesc(max(rawImages{trialToAlign},[],3))
					% Show all cells, since aligned session might not cover location of all cells
					rawImagesAll = cat(3,rawImages{:});
					imagesc(max(rawImagesAll,[],3))
				catch
					imagesc(max(rawImages{trialToAlign},[],3))
				end
					axis image
					box off;
				rightSignals = [];
				leftSignals = [];
				inputImagesROI = cell([2 1]);
				for iz2 = 1
					[inputImagesROI{iz2}, xpoly, ypoly] = roipoly;
					
					for sessionNo = 1:nSessions
						disp('===')
						disp(sessionNo)
						inputImagesTmp = rawImages{sessionNo};
						inputImagesThres = ciapkg.image.thresholdImages(inputImagesTmp,'waitbarOn',1,'binary',1,'fastThresholding',1);
						disp('Finding ROIs inside region...')
						signalInROI = squeeze(sum(logical(inputImagesThres).*inputImagesROI{iz2},[1 2],'omitnan'));

						signalsToKeep = signalInROI~=0;
						maxTmp = @(x) max(x,[],3);
						% subplot(2,2,3+(iz2-1))
						subplot(xplot,yplot,1+sessionNo)
							imagesc(maxTmp(inputImagesTmp(:,:,signalsToKeep)))
							axis image
							box off

						rawImages{sessionNo} = rawImages{sessionNo}(:,:,signalsToKeep);
						rawSignals{sessionNo} = rawSignals{sessionNo}(signalsToKeep,:);
						drawnow
						disp('Done!')
					end
				end
			end

			
			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',trialToAlign,'additionalAlignmentImages',additionalAlignmentImages,'nCorrections',nCorrections);

			clear mOpts;

			mOpts.inputSignals = rawSignals;
			mOpts.trialToAlign = trialToAlign;
			mOpts.additionalAlignmentImages = [];
			mOpts.nCorrections = uOpts.nCorrections;
			mOpts.maxDistance = uOpts.maxDistance;
			mOpts.threshold = uOpts.imageThreshold;
			mOpts.RegisTypeFinal = uOpts.RegisTypeFinal;
			mOpts.imageCorr = uOpts.imageCorr;
			mOpts.runImageCorr = uOpts.runImageCorr;
			mOpts.checkImageCorr = uOpts.checkImageCorr;
			mOpts.turboregZeroThres = uOpts.turboregZeroThres;
			mOpts.imageCorrType = uOpts.imageCorrType;
			mOpts.imageCorrThres = uOpts.imageCorrThres;

			mOpts.mcMethod = uOpts.mcMethod;
			mOpts.registrationFxn = uOpts.registrationFxn;


			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',trialToAlign,'additionalAlignmentImages',[],'nCorrections',uOpts.nCorrections,'maxDistance',uOpts.maxDistance,'threshold',uOpts.imageThreshold,'RegisTypeFinal',uOpts.RegisTypeFinal);
			alignmentStruct = matchObjBtwnTrials(rawImages,'options',mOpts);

			obj.globalIDStruct.(thisSubjectStr) = alignmentStruct;
			obj.globalIDStruct.(thisSubjectStr).inputOptions = mOpts;

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
			currentDateTimeStr = datestr(now,'yyyy-mm-dd-HHMMSS','local');
			[output] = writeHDF5Data(obj.globalObjectMapTurboreg.(thisSubjectStr).turboreg,[saveDirPath thisSubjectStr '_' currentDateTimeStr '_cellmap_turboreg.h5']);
			% options.comp = 'no';
			% saveastiff(obj.globalObjectMapTurboreg.(thisSubjectStr).turboreg, [saveDirPath thisSubjectStr '_cellmap_turboreg.tif'], options);
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	if uOpts.runViewMatchObjBtwnSessions==1
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