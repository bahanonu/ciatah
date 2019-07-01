function obj = viewMatchObjBtwnSessions(obj)
	% Plots various metrics to visualize goodness of cross-session cell alignment.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2019.04.23 [19:53:21] - a couple Windows specific path separators, switch to filesep
	% TODO
		%

		% for folderNo = 1:length(obj.dataPath)
		% 	filesToLoad = getFileList(obj.dataPath{folderNo},'_ICfilters.mat');
		% 	if isempty(filesToLoad)
		% 		display(['missing ICs: ' obj.dataPath{folderNo}])
		% 	end
		% 	filesToLoad = getFileList(obj.dataPath{folderNo},'crop');
		% 	if isempty(filesToLoad)
		% 		display(['missing dfof: ' obj.dataPath{folderNo}])
		% 	end
		% end
		% return

	movieSettings = inputdlg({...
			'directory to save pictures: ',...
			'subject alignment set # (e.g. if need multiple separate alignments): ',...
			'Sort global IDs in GUI (1 = yes, 0 = no): '
		},...
		'view movie settings',1,...
		{...
			obj.picsSavePath,...
			'1',...
			'0'
		}...
	);
	obj.picsSavePath = movieSettings{1};
	options.alignmentSetNum = str2num(movieSettings{2});
	sortGlobalIDs = str2num(movieSettings{3});

	scnsize = get(0,'ScreenSize');
	viewMatchSessionsStr = {'view cross session matches','make cross session color cellmaps'};
	[signalIdxArray, ok] = listdlg('ListString',viewMatchSessionsStr,'ListSize',[scnsize(3)*0.4 scnsize(4)*0.4],'Name','Which cross-day analysis to run?','InitialValue',2);
		% signalIdxArray
	viewMatchSessionsStr = viewMatchSessionsStr(signalIdxArray);

	nFiles = length(obj.rawSignals);
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	subjectList = unique(obj.subjectStr(fileIdxArray));
	[xPlot yPlot] = getSubplotDimensions(length(subjectList));
	length(subjectList)
	thisFigNo = 42;
	for thisSubjectStr=subjectList
		thisSubjectStr = thisSubjectStr{1};
		[~, ~] = openFigure(thisFigNo, '');
			subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
			title(thisSubjectStr)
	end
	drawnow

	if isfield(obj.globalIDs,'matchCoords')==0
		obj.globalIDs.matchCoords.null = 1;
		obj.globalIDs.distances.null = 1;
	end

	obj.detailStats.matchedGlobalCellsOverlap = {};

	manageParallelWorkers();

	nSubjects = length(subjectList);
	for subjectNo = 1:nSubjects
		try
			display(repmat('=',1,21))
			thisSubjectStr = subjectList{subjectNo};
			% thisSubjectStr = thisSubjectStr{1};
			display(thisSubjectStr);
			%
			[~, ~] = openFigure(thisFigNo, '');
				subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
				title(thisSubjectStr)
			%
			%
			inputSignals = {};
			inputImages = {};
			globalIDsTmp = obj.globalIDs.(thisSubjectStr);
			% obj.globalIDFolders.(thisSubjectStr) = obj.date;
			globalIDFolders = obj.globalIDFolders.(thisSubjectStr);
			globalIDs = [];
			validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
			% filter for folders chosen by the user
			validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
			% % remove folders that were not in alignment
			% validAssayIdx = find(strcmp(assayTypeList{assayTypeNo},obj.assayType));
			% % filter for folders chosen by the user
			% validAssayIdx = intersect(validFoldersIdx,validAssayIdx);
			%
			if isempty(validFoldersIdx)
				continue;
			end

			addNo = 1;
			parfor idx = 1:length(validFoldersIdx)
				thisFileNum = validFoldersIdx(idx);
				display(repmat('*',1,7))
				display([num2str(idx) '/' num2str(length(validFoldersIdx)) ': ' obj.fileIDNameArray{thisFileNum}]);
				% folderGlobalIdx = find(strcmp(obj.assay(thisFileNum),globalIDFolders));

				% folderGlobalIdx = find(strcmp(obj.folderBaseSaveStr(thisFileNum),globalIDFolders));
				folderGlobalIdx = find(strcmp(obj.folderBaseSaveStrUnique(thisFileNum),globalIDFolders));
				if isempty(folderGlobalIdx)
					display('skipping...')
					continue
				end
				try
					[rawSignalsTmp, rawImagesTmp , ~, ~] = modelGetSignalsImages(obj,'returnType','filteredAndRegistered','fileNum',thisFileNum);
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
					continue
				end
				inputSignals{idx} = rawSignalsTmp;
				inputImages{idx} = rawImagesTmp;
			end
			for idx = 1:length(validFoldersIdx)
			% for idx = 1:2
				% obj.fileNum = validFoldersIdx(idx);
				thisFileNum = validFoldersIdx(idx);
				display(repmat('*',1,7))
				display([num2str(idx) '/' num2str(length(validFoldersIdx)) ': ' obj.fileIDNameArray{thisFileNum}]);
				% folderGlobalIdx = find(strcmp(obj.assay(thisFileNum),globalIDFolders));

				folderGlobalIdx = find(strcmp(obj.folderBaseSaveStrUnique(thisFileNum),globalIDFolders));
				% folderGlobalIdx = find(strcmp(obj.folderBaseSaveStr(thisFileNum),globalIDFolders));
				%folderGlobalIdx = idx;
				if isempty(folderGlobalIdx)
					display('skipping...')
					continue
				end
				% obj.folderBaseSaveStr{obj.fileNum}
				% [rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
				%try
				%	[rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filteredAndRegistered');
				%catch err
				%	display(repmat('@',1,7))
				%	disp(getReport(err,'extended','hyperlinks','on'));
				%	display(repmat('@',1,7))
				%	continue
				%end
				%if ~isempty(rawSignalsTmp)
				%	inputSignals{end+1} = rawSignalsTmp;
				%	inputImages{end+1} = rawImagesTmp;
				%end

				% globalIDFolders
				% obj.assay(obj.fileNum)
				display(['folderGlobalIdx: ' num2str(folderGlobalIdx)])
				globalIDs(:,addNo) = globalIDsTmp(:,folderGlobalIdx);
				% globalIDCoords{idx} = obj.globalIDCoords.(thisSubjectStr){folderGlobalIdx};
				addNo = addNo + 1;
			end
			strcmp('view cross session matches',viewMatchSessionsStr)
			if sum(strcmp('view cross session matches',viewMatchSessionsStr))>0
				[matchedObjMaps euclideanStruct] = displayMatchingObjs(inputImages,globalIDs,'inputSignals',inputSignals,'globalIDCoords',obj.globalIDCoords.(thisSubjectStr).globalCoords,'sortGlobalIDs',sortGlobalIDs);
				% write out summary statistics
				savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_' obj.subjectStr{obj.fileNum} '_crossDayEucledian.tab'];
				display(['saving data to: ' savePath])
				writetable(struct2table(euclideanStruct),savePath,'FileType','text','Delimiter','\t');
			end

			display('making global maps')
			% nMatchGlobalIDs = sum(globalIDs~=0);
			nMatchGlobalIDs = sum(globalIDs~=0,2);

			nGlobalIDs = size(globalIDsTmp,1);
			nSessions = length(inputImages);
			size(inputImages)
			% globalColors = hsv(nGlobalIDs);
			globalIDFolders = obj.globalIDFolders.(thisSubjectStr);
			for sessionNo = 1:nSessions
				globalToSessionIDs{sessionNo} = zeros([size(inputImages{sessionNo},3) 1]);
			end
			for sessionNo = 1:nSessions
				obj.fileNum = validFoldersIdx(sessionNo);
				% folderGlobalIdx = find(strcmp(obj.assay(obj.fileNum),globalIDFolders));

				folderGlobalIdx = find(strcmp(obj.folderBaseSaveStrUnique(obj.fileNum),globalIDFolders));
				% folderGlobalIdx = find(strcmp(obj.folderBaseSaveStr(obj.fileNum),globalIDFolders));
				for globalNo = 1:nGlobalIDs
					sessionIdx = globalIDsTmp(globalNo,folderGlobalIdx);
					if sessionIdx~=0
						globalToSessionIDs{sessionNo}(sessionIdx) = globalNo;
					end
				end
			end
			for sessionNo = 1:nSessions
				[~, ~] = openFigure(sessionNo, '');
			end

			% globalIDsImageList = cell([sum(nMatchGlobalIDs(globalNo)>=2) 1]);
			globalIDsImageList = cell([nGlobalIDs 1]);
			for sessionNo = 1:nSessions
				try
					obj.fileNum = validFoldersIdx(sessionNo);
					thisFileID = obj.fileIDArray{obj.fileNum};
					folderGlobalIdx = find(strcmp(obj.folderBaseSaveStrUnique(obj.fileNum),globalIDFolders));
					% folderGlobalIdx = find(strcmp(obj.folderBaseSaveStr(obj.fileNum),globalIDFolders));
					% globalToSessionIDsTmp = globalToSessionIDs{sessionNo};
					% keepIDIdx = globalIDs(nMatchGlobalIDs>=2,sessionNo);
					% keepIDIdx(keepIDIdx<1) = [];
					% keepIDIdx(keepIDIdx>length(globalToSessionIDsTmp)) = [];
					% if isempty(keepIDIdx)
					% 	continue;
					% end
					% display('++++++++')
					% globalToSessionIDsTmp(setdiff(1:length(globalToSessionIDsTmp),keepIDIdx)) = 0;
					% globalToSessionIDsTmp(keepIDIdx) = globalToSessionIDsTmp(keepIDIdx)+10;
					% [groupedImagesRates] = groupImagesByColor(inputImages{sessionNo},globalToSessionIDsTmp);
					tmpSessionImgs = inputImages{sessionNo};
					for globalNo = 1:nGlobalIDs
						sessionIdx = globalIDsTmp(globalNo,folderGlobalIdx);
						try
							globalIDsImageList{globalNo};
						catch
							globalIDsImageList{globalNo} = [];
						end
						% disp([globalNo sessionIdx nMatchGlobalIDs(globalNo)>=2 NaN size(globalIDsImageList) NaN size(tmpSessionImgs)])
						if sessionIdx~=0&nMatchGlobalIDs(globalNo)>=2
							tmpImg = tmpSessionImgs(:,:,sessionIdx);
							globalIDsImageList{globalNo} = cat(3,globalIDsImageList{globalNo},tmpImg);
							% globalToSessionIDs{sessionNo}(sessionIdx) = globalNo;
						end
					end
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end

			options.cellmapZoomPx = 10;
			options.maxDistAccept = 10;
			zzz = 1;
			zzz2 = 1;
			outputCutMovie = {};
			outputCutMovieThres = {};
			nGlobalIDsView = nGlobalIDs;
			% nGlobalIDsView = 20;
			[xPlot yPlot] = getSubplotDimensions(nGlobalIDsView);
			allCentroids = [];
			allDistances = [];
			for globalNo = 1:nGlobalIDsView
				try
					tmpGlobalImg = globalIDsImageList{globalNo};
					if isempty(tmpGlobalImg)|size(tmpGlobalImg,3)==1
						continue;
					end

					% globalCoordHere = obj.globalIDCoords.(thisSubjectStr).globalCoords(globalNo,:);
					tmpCentroids = [];
					% for 1:nSessions
					for sessionNo = 1:nSessions
						obj.fileNum = validFoldersIdx(sessionNo);
						thisFileID = obj.fileIDArray{obj.fileNum};
						% folderGlobalIdx = find(strcmp(obj.folderBaseSaveStr(obj.fileNum),globalIDFolders));
						folderGlobalIdx = find(strcmp(obj.folderBaseSaveStrUnique(obj.fileNum),globalIDFolders));

						sessionIdx = globalIDsTmp(globalNo,folderGlobalIdx);
						if sessionIdx~=0
							tt = obj.globalIDCoords.(thisSubjectStr).localCoords{sessionNo}(sessionIdx,:);
							tmpCentroids = cat(1,tmpCentroids,tt);
						end
					end
					% [~,~,tmpCentroids] = findCentroid(tmpGlobalImg,'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
					% tmpCentroids
					globalCoordHere = mean(tmpCentroids,1);
					tmpCentroids(:,1) = tmpCentroids(:,1) - globalCoordHere(1);
					tmpCentroids(:,2) = tmpCentroids(:,2) - globalCoordHere(2);
					% globalCoordHere

					xCoords = tmpCentroids(:,1);
					yCoords = tmpCentroids(:,2);
					distMatrix = pdist([xCoords(:)*obj.MICRON_PER_PIXEL yCoords(:)*obj.	MICRON_PER_PIXEL]);
					distMatrix(logical(eye(size(distMatrix)))) = NaN;
					distMatrixPairs = distMatrix(:);
					distMatrixPairs(~isnan(distMatrixPairs));
					if sum(distMatrixPairs>options.maxDistAccept)>1
						[xPlot2 yPlot2] = getSubplotDimensions(size(tmpGlobalImg,3));
						figure(10000+globalNo)
							for sss = 1:size(tmpGlobalImg,3)
								subplot(xPlot2,yPlot2,sss)
								imagesc(tmpGlobalImg(:,:,sss))
								hold on;
								plot(globalCoordHere(:,1),globalCoordHere(:,2),'k.');
							end
							suptitle(num2str(globalNo))
							% montage()
							% globalNo
							% globalNo
					end

					if sum(distMatrixPairs>options.maxDistAccept)<1
						allDistances = [allDistances(:); distMatrixPairs(:)];
						% size(allCentroids)
						% size(tmpCentroids)
						if isempty(allCentroids)
							allCentroids = tmpCentroids;
						else
							allCentroids = cat(1,allCentroids,tmpCentroids);
						end
					end

					% openFigure(885);
					% 	clf
					% 	imagesc(tmpGlobalImg(:,:,1))
					% 	hold on;
					% 	% plot(globalCoordHere(:,2),globalCoordHere(:,1),'k.');
					% 	plot(globalCoordHere(:,1),globalCoordHere(:,2),'k+');
					% pause

					% show all the centroid positions relative to the zero of the matched day
					openFigure(1112);
						subplot(1,2,1)
						% [~,~,tmpCentroids] = findCentroid(outputCutMovie{globalNo},'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
						plot(tmpCentroids(:,1),tmpCentroids(:,2),'k.');
						% ylim([0 options.cellmapZoomPx*2+1])
						% xlim([0 options.cellmapZoomPx*2+1])
						axis equal
						hold on;

					% openFigure(1113);
						subplot(1,2,2)
						hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
						colorbar
						axis equal
						% ylim([0 options.cellmapZoomPx*2+1])
						% xlim([0 options.cellmapZoomPx*2+1])


					if zzz2<10&size(tmpGlobalImg,3)>=(nSessions-1)
						[outputCutMovie{globalNo}] = getObjCutMovie(tmpGlobalImg,tmpGlobalImg(:,:,1),'waitbarOn',0,'cropSize',options.cellmapZoomPx,'addPaddingForce',1,'createMontage',0,'xCoords',round(globalCoordHere(1)),'yCoords',round(globalCoordHere(2)),'crossHairsOn',0);
						outputCutMovie{globalNo} = outputCutMovie{globalNo}{1};

						openFigure(1110);
							subplot(4,4,zzz2);
							% outputCutMovie{globalNo} = thresholdImages(tmpGlobalImg,'binary',1,'waitbarOn',0,'threshold',0.5);
							outputCutMovieThres{globalNo} = thresholdImages(outputCutMovie{globalNo},'binary',1,'waitbarOn',0,'threshold',0.5);
							outputCutMovieThres{globalNo} = nanmean(outputCutMovieThres{globalNo},3);
							imagesc(outputCutMovieThres{globalNo})
							axis off; axis equal tight;
						[~,~,tmpCentroids] = findCentroid(outputCutMovie{globalNo},'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
						openFigure(1114);
							colormap gray
							tmpVar = outputCutMovie{globalNo};
							for hh = 1:size(tmpVar,3)
								% subplot(10,nSessions,(globalNo-1)*nSessions+hh)
								subplot(10,nSessions,(zzz2-1)*nSessions+hh)
									hhhTmp = thresholdImages(tmpVar(:,:,hh),'binary',0,'waitbarOn',0,'threshold',0.4);
									imagesc(hhhTmp);
									hold on;
									plot(tmpCentroids(hh,1),tmpCentroids(hh,2),'r+');
									axis equal tight;
							end
							hold on;
							% axis off; axis equal tight;
						zzz2 = zzz2 + 1;
					end

					% openFigure(1111);
					% 	tmpVar = outputCutMovie{globalNo};
					% 	plot(tmpVar(:));
					% 	hold on;
					% pause
					zzz = zzz + 1;
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
			newSubjStr = sprintf('%s_%d',thisSubjectStr,options.alignmentSetNum);
			obj.globalIDs.matchCoords.(newSubjStr) = allCentroids;
			obj.globalIDs.distances.(newSubjStr) = allDistances;
			drawnow
			% return;
			% pause

			try
				figure;
					imagesc(nanmean(cat(3,obj_p435_p700.detailStats.outputCutMovie{:}),3));
					colorbar;
					axis equal tight;
					title('m597 aligned sessions match cells');
			catch
			end
			try
				obj.detailStats.matchedGlobalCellsOverlap{subjectNo} = outputCutMovie;
			catch
			end
			% return;
			% figure(90)
			% plot(nMatchGlobalIDs)
			% round(nSessions*0.6)
			for matchingNumbers = [2 1]
				folderSaveName = {'matchObjColorMapAllMatched','matchObjColorMap70percentMatched'};
				for sessionNo = 1:nSessions
					try
						obj.fileNum = validFoldersIdx(sessionNo);
						thisFileID = obj.fileIDArray{obj.fileNum};
						globalToSessionIDsTmp = globalToSessionIDs{sessionNo};
						% get
						% figure;plot(nMatchGlobalIDs==nSessions);
						if matchingNumbers==1
							keepIDIdx = globalIDs(nMatchGlobalIDs>=round(nSessions*0.7),sessionNo);
						else
							keepIDIdx = globalIDs(nMatchGlobalIDs==nSessions,sessionNo);
						end
						keepIDIdx(keepIDIdx<1) = [];
						keepIDIdx(keepIDIdx>length(globalToSessionIDsTmp)) = [];
						% keepIDIdx
						if isempty(keepIDIdx)
							keepIDIdx = 1;
						end
						display('++++++++')
						% keepIDIdx
						% keepIDIdx = globalIDs(nMatchGlobalIDs>3,sessionNo);
						% globalToSessionIDs{sessionNo}(keepIDIdx)
						globalToSessionIDsTmp(setdiff(1:length(globalToSessionIDsTmp),keepIDIdx)) = 1;
						globalToSessionIDsTmp(keepIDIdx) = globalToSessionIDsTmp(keepIDIdx)+10;
						[groupedImagesRates] = groupImagesByColor(inputImages{sessionNo},globalToSessionIDsTmp);
						% [groupedImagesRates] = groupImagesByColor(inputImages{sessionNo}(keepIDIdx,:,:),globalToSessionIDs{sessionNo}(keepIDIdx));
						% [groupedImagesRates] = groupImagesByColor(inputImages{sessionNo},globalToSessionIDs{sessionNo});
						% size(inputImages{sessionNo}(,:,:))
						% size(globalToSessionIDs{sessionNo}(nMatchGlobalIDs==nSessions))
						thisCellmap = createObjMap(groupedImagesRates);
						thisCellmap(1,1) = 1;
						thisCellmap(1,2) = nGlobalIDs;
						[~, ~] = openFigure(sessionNo, '');
							clf
							imagesc(thisCellmap+1);box off;axis off
							% title(strrep(strcat(obj.subjectStr(obj.fileNum),{' '},obj.assay(obj.fileNum)),'_',' '),'FontSize', 35)
							% title(strrep(obj.folderBaseSaveStr(obj.fileNum),'_',' '))
							colormap([1 1 1; 0.9 0.9 0.9; hsv(nGlobalIDs)]);
							set(sessionNo,'PaperUnits','inches','PaperPosition',[0 0 9 9])
							obj.modelSaveImgToFile([],[folderSaveName{matchingNumbers} 'Session' filesep thisSubjectStr],sessionNo,strcat(thisFileID));
						[~, ~] = openFigure(thisFigNo, '');
						subplot(1,nSessions,sessionNo)
							% imagesc(globalToSessionIDs{sessionNo})
							imagesc(thisCellmap+1);box off;axis off;
							% title(strrep(obj.assay(obj.fileNum),'_',' '))

							title(strrep(obj.folderBaseSaveStrUnique(obj.fileNum),'_',' '))
							% title(strrep(obj.folderBaseSaveStr(obj.fileNum),'_',' '))
							% colormap(customColormap([]))
							% colormap([1 1 1; hsv(nGlobalIDs)]);
							colormap([1 1 1; 0.9 0.9 0.9; hsv(nGlobalIDs)]);
							% drawnow;
							obj.modelSaveImgToFile([],[folderSaveName{matchingNumbers} 'All'],thisFigNo,obj.subjectStr{obj.fileNum});
					catch err
						display(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
					end
				end

				saveVideoFile = [obj.picsSavePath filesep folderSaveName{matchingNumbers} 'Session' filesep thisSubjectStr '_matchedCells.avi'];
				display(['save video: ' saveVideoFile])
				writerObj = VideoWriter(saveVideoFile,'Motion JPEG AVI');
				writerObj.FrameRate = 4;
				writerObj.Quality = 100;
				% writerObj.LosslessCompression = true;
				open(writerObj);
				for sessionNo = 1:nSessions
					obj.fileNum = validFoldersIdx(sessionNo);
					thisFileID = obj.fileIDArray{obj.fileNum};
					obj.modelSaveImgToFile([],['matchObjColorMapSession' filesep thisSubjectStr],sessionNo,strcat(thisFileID));
					set(sessionNo,'PaperUnits','inches','PaperPosition',[0 0 9 9])

					frame = getframe(sessionNo);
					[frameImg,map] = frame2im(frame);
					frameImg = imresize(frameImg,[1000 1000],'bilinear');
					writeVideo(writerObj,frameImg);
				end
				close(writerObj);
			end
			display('finished making global maps')
			continue

			display(['global: ' num2str(size(globalIDs))])

			[~, ~] = openFigure(thisFigNo, '');
			% [xPlot yPlot] = getSubplotDimensions(length(subjectList));
			subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
				plotGlobalOverlap(inputImages,inputSignals,globalIDs,obj.globalIDCoords.(thisSubjectStr).globalCoords);
				title(thisSubjectStr)
				% box off
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
			obj.modelSaveImgToFile([],'globalOverlap','current',[]);
			continue;

			[matchedObjMaps euclideanStruct] = displayMatchingObjs(inputImages,globalIDs,'inputSignals',inputSignals,'globalIDCoords',obj.globalIDCoords.(thisSubjectStr).globalCoords);

			% % fileIdxArray = round(quantile(1:length(validFoldersIdx),0.5));
			% fileIdxArray = 1;
			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',fileIdxArray,'additionalAlignmentImages',additionalAlignmentImages);
			% obj.globalIDs.(thisSubjectStr) = alignmentStruct.globalIDs;
			% obj.globalIDCoords.(thisSubjectStr) = alignmentStruct.coords;
			% % obj.globalIDImages.(thisSubjectStr) = alignmentStruct.inputImages;
			% obj.objectMapTurboreg.(thisSubjectStr) = alignmentStruct.objectMapTurboreg;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function plotGlobalOverlap(inputImages,inputSignals,globalIDs,globalIDCoords)
		if ~isempty(globalIDCoords)
			% globalIDCoords = options.globalIDCoords;
			nGlobals = size(globalIDs,1);
			nObjPerGlobal = sum(globalIDs>0,2);
			cropSize = 10;
			globalOverlapImages = [];
			reverseStr = '';
			% thresholdImages(inputImages,'binary',1,'waitbarOn',0);
			for globalNo = 1:nGlobals
				nMatchedIDs = sum(globalIDs(globalNo,:)~=0);
				if nMatchedIDs<2
					globalOverlapImages(:,:,globalNo) = NaN([2*cropSize+1 2*cropSize+1]);
					continue;
				end
				coords = globalIDCoords(globalNo,:);
				xCoords = coords(1);
				yCoords = coords(2);
				[groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,inputSignals,globalNo);
				groupImages = squeeze(nansum(thresholdImages(groupImages,'binary',1,'waitbarOn',0),1))/nMatchedIDs*100;
				% movieDims = size(inputMovie);
				xLow = floor(xCoords - cropSize);
				xHigh = floor(xCoords + cropSize);
				yLow = floor(yCoords - cropSize);
				yHigh = floor(yCoords + cropSize);
				% % check that not outside movie dimensions
				% xMin = 0;
				% xMax = movieDims(2);
				% yMin = 0;
				% yMax = movieDims(1);
				% % adjust for the difference in centroid location if movie is cropped
				% xDiff = 0;
				% yDiff = 0;
				% if xLow<xMin xDiff = xLow-xMin; xLow = xMin; end
				% if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
				% if yLow<yMin yDiff = yLow-yMin; yLow = yMin; end
				% if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end
				try
					globalOverlapImages(:,:,globalNo) = groupImages(yLow:yHigh,xLow:xHigh);
				catch
					globalOverlapImages(:,:,globalNo) = NaN([2*cropSize+1 2*cropSize+1]);
				end
				reverseStr = cmdWaitbar(globalNo,nGlobals,reverseStr,'inputStr','getting global overlaps','displayEvery',5);
			end
			% playMovie(globalOverlapImages);
			% [~, ~] = openFigure(thisFigNo, '');
				globalOverlapImages = squeeze(nanmean(globalOverlapImages,3));
				globalOverlapImages(1,1) = 0;
				globalOverlapImages(1,2) = 100;
				imagesc(globalOverlapImages);
				colormap(customColormap([]));
				% title('heatmap of percent overlap object maps')
				colorbar
		end
	end
end
function [groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,inputSignals,globalNo)
	matchIDList = globalIDs(globalNo,:);
	matchIDIdx = matchIDList~=0;
	nMatchGlobalIDs = sum(matchIDIdx);
	if ~isempty(inputSignals)
		% get max length
		[nrows, ncols] = cellfun(@size, inputSignals);
		maxCols = max(ncols);
		matchedSignals = zeros(length(inputSignals),maxCols);
	end

	idxNo = 1;
	for j=1:length(inputImages)
		iIdx = globalIDs(globalNo,j);
		if iIdx==0
			nullImage = NaN(size(squeeze(inputImages{1}(:,:,1))));
			nullImage(1,1) = 1;
			groupImages(j,:,:) = nullImage;
		else
			% size(inputImages{j})
			% iIdx
			try
				groupImages(j,:,:) = squeeze(inputImages{j}(:,:,iIdx));
			catch
				display([num2str(j) ',' num2str(iIdx)])
			end
			if ~isempty(inputSignals)
				iSignal = inputSignals{j}(iIdx,:);
				matchedSignals(j,1:length(iSignal)) = iSignal;
			end
			idxNo = idxNo + 1;
		end
	end
end
function [] = creatObjMapGlobalOverlay()

	inputImages = inputImages(:,:,valid);
	% register images based on cross session alignment
	globalRegCoords = obj.globalRegistrationCoords.(obj.subjectStr{obj.fileNum});
	if ~isempty(globalRegCoords)
		display('registering images')
		% get the global coordinate number based
		globalRegCoords = globalRegCoords{strcmp(obj.assay{obj.fileNum},obj.globalIDFolders.(obj.subjectStr{obj.fileNum}))};
		if ~isempty(globalRegCoords)
			% inputImages = permute(inputImages,[2 3 1]);
			for iterationNo = 1:length(globalRegCoords)
				fn=fieldnames(globalRegCoords{iterationNo});
				for i=1:length(fn)
					localCoords = globalRegCoords{iterationNo}.(fn{i});
					[inputImages localCoords] = turboregMovie(inputImages,'precomputedRegistrationCooords',localCoords);
				end
			end
			% inputImages = permute(inputImages,[3 1 2]);
		end
	end

	movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:2);
	movieFrame = squeeze(movieFrame(:,:,1));



	validAuto = obj.validAuto{obj.fileNum};
	display('==============')
	if isempty(obj.validRegionMod)
		validRegionMod = ones(size(validAuto));
	else
		validRegionMod = obj.validRegionMod{obj.fileNum};
	end
	validRegionMod = validRegionMod(logical(validAuto));
	inputImagesThresholded = thresholdImages(inputImages(:,:,validAuto),'binary',0)/3;
	% inputImagesThresholded = inputImagesThresholded(validAuto);
	display(['inputImagesThresholded: ' num2str(size(inputImagesThresholded))])
	colorObjMaps{1} = createObjMap(inputImagesThresholded(validRegionMod==0,:,:));
	colorObjMaps{2} = createObjMap(inputImagesThresholded(validRegionMod==1,:,:));
	display(['colorObjMaps{1}: ' num2str(size(colorObjMaps{1}))])
	E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
	if isempty(colorObjMaps{1})
		Comb(:,:,1) = E;
	else
		Comb(:,:,1) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % red
	end
	Comb(:,:,2) = E+normalizeVector(double(colorObjMaps{2}),'normRange','zeroToOne')/4; % green
	Comb(:,:,3) = E; % blue
	% Comb(:,:,3) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % blue
	imagesc(Comb)
end