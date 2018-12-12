function obj = modelModifyRegionAnalysis(obj,varargin)
	% Remove PCAs in a particular region or exclude from preprocessing, etc.
	% Biafra Ahanonu
	% started: 2015.09.14 14:46:02
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%
	%========================
	options.defaultOption = 'loadPreviousSelections';

	% get options
	options = getOptions(options,varargin);
	%========================

	if obj.guiEnabled==1
		scnsize = get(0,'ScreenSize');
		[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

		% [fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
		scnsize = get(0,'ScreenSize');
		dlgSize = [scnsize(3)*0.7 scnsize(4)*0.8];
		usrIdxChoiceStr = {'selectRegions','modifyExistingRegions','runAlreadySelectedRegions','loadPreviousSelections'};
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',dlgSize);
		analysisToRun = usrIdxChoiceStr{sel};
	else
		if isempty(obj.foldersToAnalyze)
			fileIdxArray = 1:length(obj.fileIDNameArray);
		else
			fileIdxArray = obj.foldersToAnalyze;
		end
		analysisToRun = options.defaultOption;
	end
	nFolders = length(fileIdxArray);


	framesPerSecond = obj.FRAMES_PER_SECOND;
	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);

			if strcmp(analysisToRun,'loadPreviousSelections')
				regionFile = getFileList(obj.inputFolders{obj.fileNum},obj.regionModSaveStr);
				% if no file, skip
				if isempty(regionFile)
					display('No region analysis to load!')
					continue;
				end
				regionFile = regionFile{1};
				fprintf('loading: %s',regionFile)
				loadFile = load(regionFile,'roipolyRegion','roipolyCoords')
				obj.analysisROIArray{obj.fileNum} = loadFile.roipolyRegion;
				obj.validRegionModPoly{obj.fileNum} = loadFile.roipolyCoords;
				% NOT DONE!!!!!!!!
			end
			if strcmp(analysisToRun,'modifyExistingRegions')
				regionFile = getFileList(obj.inputFolders{obj.fileNum},obj.regionModSaveStr);
				% if no file, skip
				if isempty(regionFile)
					display('No region analysis to load!')
					continue;
				end
				loadFile = load(regionFile,'roipolyRegion','roipolyCoords')
				obj.analysisROIArray{obj.fileNum} = loadFile.roipolyRegion;
				obj.validRegionModPoly{obj.fileNum} = loadFile.roipolyCoords;
			end
			[inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
			% inputImages = thresholdImages(inputImages,'binary',0)/3;
			% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);

			% display cellmap and ask user to select a region
			[~, ~] = openFigure(obj.figNoAll, '');
			clf
			colormap gray
			subX = 3; subY = 3;
			if sum(strcmp(analysisToRun,{'selectRegions','modifyExistingRegions','runAlreadySelectedRegions','loadPreviousSelections'}))
				subplot(subX,subY,3);
					numPeakEvents = sum(signalPeaks,2);
					numPeakEvents = numPeakEvents/size(signalPeaks,2)*framesPerSecond;
					size(numPeakEvents)
					size(signalPeaks)
					[groupedImagesRates] = groupImagesByColor(inputImages,numPeakEvents);
					thisCellmap = createObjMap(groupedImagesRates);
					imagesc(thisCellmap);
					title('firing rate cell map')
					% colormap(obj.colormap);
				subplot(subX,subY,6);
					movieList = getFileList(obj.inputFolders{obj.fileNum}, 'concat');
					if ~isempty(movieList)
						movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:2);
						movieFrame = squeeze(movieFrame(:,:,1));
						% movieFrameMean = mean(movieFrame(:));
						% imagesc(imadjust(movieFrame+cast(thisCellmap*10000,class(movieFrame))));
						E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
						% Comb = E;
						I = cast(normalizeVector(thisCellmap,'normRange','zeroToOne')*mean(movieFrame(:)),class(movieFrame));
						I = normalizeVector(double(I),'normRange','zeroToOne')/3;
						Comb(:,:,1) = E; % red
						Comb(:,:,2) = E+I; % green
						Comb(:,:,3) = E; % blue
						imagesc(Comb)
						% inputImagesThresholded = thresholdImages(inputImages,'binary',0)/3;
						% zeroMap = zeros(size(movieFrame));
						% oneMap = ones(size(movieFrame));
						% warning off
						% colorOverlay = imshow(cat(3, zeroMap, oneMap, zeroMap));
						% warning on
						% thisCellmap = createObjMap(inputImagesThresholded);
						% set(colorOverlay, 'AlphaData', thisCellmap);
					end
					title('movie frame + cell map')
				subplot(subX,subY,[1 2 4 5 7 8]);
					try obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual;check.manual=1; catch check.manual=0; end
					% if isfield(obj.valid,obj.signalExtractionMethod)&isfield(obj.valid.(obj.signalExtractionMethod),'manual')
					if check.manual==1
						[groupedImagesRates] = groupImagesByColor(inputImages,obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual);
					else
						[groupedImagesRates] = groupImagesByColor(inputImages,obj.validAuto{obj.fileNum});
					end
					thisCellmap = createObjMap(groupedImagesRates);
					% obj.rawImagesFiltered{obj.fileNum} = thisCellmap;
					imagesc(thisCellmap+0.1);
					% imagesc(obj.rawImagesFiltered{obj.fileNum}+0.1);
					title('draw selection on this image')
					% colormap(obj.colormap)
					suptitle(strrep(obj.folderBaseSaveStr{obj.fileNum},'_',' | '))
					if ~sum(strcmp(analysisToRun,{'runAlreadySelectedRegions','loadPreviousSelections'}))
						% [polyCoords] = obj.validRegionModPoly{obj.fileNum};
						if strcmp(analysisToRun,'modifyExistingRegions')
							[polyCoords] = obj.validRegionModPoly{obj.fileNum};
							h = impoly(gca,polyCoords);
							h.wait
							polyCoords = h.getPosition;
							[obj.analysisROIArray{obj.fileNum} xpoly ypoly] = roipoly(thisCellmap+0.1,polyCoords(:,1),polyCoords(:,2));
						else
							[obj.analysisROIArray{obj.fileNum} xpoly ypoly] = roipoly;
						end
						obj.validRegionModPoly{obj.fileNum} = [xpoly ypoly];
					end
					% imagesc(obj.rawImagesFiltered{obj.fileNum}.*obj.analysisROIArray{obj.fileNum})
					imagesc(thisCellmap.*obj.analysisROIArray{obj.fileNum})
					drawnow;
			end
			if strcmp(analysisToRun,'runAlreadySelectedRegions')
				display('Using previous ROI')
			end
			inputImagesROI = obj.analysisROIArray{obj.fileNum};
			inputImagesThres = thresholdImages(inputImages,'waitbarOn',1,'binary',1);
			% signalInROI = squeeze(nansum(nansum(bsxfun(@times,inputImages,permute(inputImages,[2 3 1])),1),2));
			display('finding ROIs inside region...')
			signalInROI = squeeze(nansum(nansum(bsxfun(@times,inputImagesThres,inputImagesROI),1),2));

			% signalInROI = applyImagesToMovie(inputImages,permute(inputImages,[2 3 1]), 'alreadyThreshold',1);
			signalsToKeep = signalInROI~=0;

			if isempty(obj.validManual{obj.fileNum})
				validRegionModHere = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).auto(:)&signalsToKeep(:);
			else
				validRegionModHere = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).manual(:)&signalsToKeep(:);
				% if ~isempty(obj.validManual{obj.fileNum})
				% 	obj.validRegionMod{obj.fileNum} = obj.validAuto{obj.fileNum}(:)&signalsToKeep(:);
				% end
			end
			obj.validRegionMod{obj.fileNum} = validRegionModHere;
			obj.valid{obj.fileNum}.(obj.signalExtractionMethod).regionMod = validRegionModHere;

			[~, ~] = openFigure(obj.figNoAll, '');
				subplot(subX,subY,9);
				[filterImageGroups] = createObjMap(groupImagesByColor(inputImages,obj.validRegionMod{obj.fileNum}+1));
				% size(filterImageGroups)
				imagesc(filterImageGroups)
				title(sprintf('new cell map | %d cells',sum(validRegionModHere)))
				% colormap(obj.colormap)

			roipolyRegion = obj.analysisROIArray{obj.fileNum};
			roipolyCoords = obj.validRegionModPoly{obj.fileNum};

			thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.folderBaseSaveStr{obj.fileNum}];
			savestring = [thisDirSaveStr obj.regionModSaveStr];
			display(['saving: ' savestring])
			save(savestring,'roipolyRegion','-v7.3','roipolyCoords');

			if sum(strcmp(analysisToRun,{'runAlreadySelectedRegions','loadPreviousSelections'}))
			else
				uiwait(msgbox('press OK to move onto next folder','Success','modal'));
			end

		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end