function [OutStruct] = matchObjBtwnTrials(inputImages,varargin)
	% Registers images to a set imaging session then matches objs between sessions to one another and outputs the alignment indicies for a single global cell across sessions. All images cropped to the minimum x,y dimension among all the input imaging session datasets.
	% Biafra Ahanonu
	% started: 2013.10.31
	% inputs
		% inputImages - cell array of [x y nFilters] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}
	% options
		% inputSignals - cell array of [nFilters frames] matrices containing each set of filter traces
	% outputs
		% OutStruct - structure containing
		% .globalIDs, [M N] matrix with M = number of global IDs and N = each session. Each m,n pair specifies the index of that global obj m in the data of session n. If .globalIDs(m,n)==0, means no match was found.
		% .trialIDs, a cell array that matches each column n in the matrix to a particular id, either automatic or input a cell array of strings specifying what each session is.
		% .coords, a [M C] matrix with M = number of global ID and C = 2 (1st column is x, 2nd column is y coordinates),

	% changelog
		% 2014.01.30 - finished the function, outputs a structure containing a matrix of global IDs and the corresponding indicies for each trial.
		% 2014.01.31 - now binary threshold the input images before turboreging, makes it less prone to errors due to differences in IC intensity
		% 2014.01.31 [22:57:01] - added second stage turboreg that turboregs using the point object maps (even less noise to mess with alignment, ostensibly like control points)
		% 2014.02.18 - added back clustering method, still WIP.
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2017.06 - added in option to ensure that duplicate cells are not found.
		% should the global ID coordinate be averaged when a match is found for the next iteration? - IMPLEMENTED
		% 2018.08.27 [18:02:11] - Modified how global coordinates calculated so most recent match isn't given equal weight to all older matches.
		% 2019.07.03 [11:11:20] (early 2019) - Finished adding image correlation check for matched objects to be within matchObjBtwnTrials function.
		% 2019.07.11 [20:46:23] - Add support for additional image correlation comparison metrics.
	% notes
		% the cell array of traces allows us to have arbitrary numbers of trials to align automatically,
	% TODO
		% detect if the input images are not all of the same size, if that is the case, ask the user to specify a crop area equal to the dimensions of the smallest input image.

	%========================
	% 'pairwise' or 'clustering'
	options.analysisType = 'pairwise';
	% which session to start alignment on, just make it
	options.trialToAlign = 1;
	% distance in pixels between centroids for them to be grouped
	% options.maxDistance = 2.5126;%6um
	options.maxDistance = 5;
	% number of rounds to register image.
	options.nCorrections = 1;
	% what level of the max for an image to threshold, values 0 to 1
	options.threshold = 0.5;
	%
	options.inputSignals = [];
	% cell array of cell arrays with matrices [x y nFilters] containing each set of filters, e.g. {imageSet1, imageSet2,...}
	options.additionalAlignmentImages = [];
	%
	options.trialIDs = [];
	% 1 = run motion correct, 0 = no motion correction (e.g. within day movies)
	options.runMotionCorrection = 1;
	% images to register that are not the main ones
	options.altInputImagesToRegister = [];
	% 3 = rotation/translation and iso scaling; 2 = rotation/translation, no iso scaling
	options.RegisTypeFinal = 2;
	% Float: between 0 to 1, must have an image correlation above this value to be a match.
	options.imageCorr = 0.6;
	% Binary: 1 = run image correlation check using options.imageCorr.
	options.runImageCorr = 1;
	% Str: type of image correlation to run
	options.imageCorrType = 'corr2';
	% Float: fraction of max value to use when binarizing image
	options.imageCorrThres = 0.3;
	% Float: turboreg shift will lead to slight offsets from zero, fix that.
	options.turboregZeroThres = 1e-6;
	% Binary: 1 = check correlation matches visually
	options.checkImageCorr = 0;
	options = getOptions(options,varargin);
	%========================
	% obtain trial stats
	OutStruct.null = 0;
	try
		% if want to load images within the function
		nSessions = length(inputImages);
		% inputMovieClass = class(inputImages{1});
		% if strcmp(inputMovieClass,'char')
		%     for trialNo = 1:nSessions
		%         inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
		%     end
		%     % [pathstr,name,ext] = fileparts(inputFilePath);
		%     % options.newFilename = [pathstr '\concat_' name '.h5'];
		% end
		% get dimensions
		xDim = size(inputImages{1},2);
		yDim = size(inputImages{1},1);

		% check that alignment trial is within bounds
		if options.trialToAlign>nSessions return; end

		% verify that the input filters are all of the same size
		% just get the dimensions then do a pairwise difference between each dimension
		% get a list of dimensions
		[inputImages] = checkImageDimensions(inputImages);
		if ~isempty(options.additionalAlignmentImages)
			for addIdx=1:length(options.additionalAlignmentImages)
				[options.additionalAlignmentImages{addIdx}] = checkImageDimensions(options.additionalAlignmentImages{addIdx});
			end
		end

		% get object maps for each trial
		inputImagesOriginal = inputImages;
		for i = 1:nSessions
			inputImages{i} = thresholdImages(inputImages{i},'binary',0,'waitbarOn',1,'threshold',options.threshold);
			objectMapBinary{i} = createObjMap(inputImages{i}>0);
			% figure(90);imagesc(objectMapBinary{i})
			objectMap{i} = createObjMap(inputImages{i});
			% figure(90);imagesc(objectMap{i})
			if ~isempty(options.additionalAlignmentImages)
				for addIdx=1:length(options.additionalAlignmentImages)
					% objectMapAdditional{addIdx}{i} = createObjMap(options.additionalAlignmentImages{addIdx}{i});
					objectMapAdditional{addIdx}{i} = squeeze(options.additionalAlignmentImages{addIdx}{i});
					% checkImageDimensions(options.additionalAlignmentImages{addIdx}{i});
				end
			end
		end
		plotObjectMap(objectMapBinary,342);drawnow;
		plotObjectMap(objectMap,343);drawnow;

		% =======
		RegisTypeFinal = options.RegisTypeFinal;
		% turboreg options.
		ioptions.meanSubtract = 0;
		ioptions.complementMatrix = 0;
		ioptions.normalizeType = [];
		% turboreg c-function options
		ioptions.RegisType=RegisTypeFinal;
		ioptions.SmoothX=5;%10
		ioptions.SmoothY=5;%10
		ioptions.minGain=0.2;
		ioptions.Levels=6;
		ioptions.Lastlevels=1;
		ioptions.Epsilon=1.192092896E-07;
		ioptions.zapMean=0;
		% additional options
		ioptions.parallel = 1;
		ioptions.cropCoords = [];
		ioptions.closeMatlabPool = 0;
		ioptions.removeEdges = 0;
		% ioptions.registrationFxn = 'imtransform';
		ioptions.registrationFxn = 'transfturboreg';
		% =======
		% turboreg all object maps to particular trial's map
		referenceObjMap(:,:,1) = objectMap{options.trialToAlign};
		% for binary alignment
		referenceObjMapBinary(:,:,1) = objectMapBinary{options.trialToAlign};
		if ~isempty(options.additionalAlignmentImages)
			for addIdx=1:length(options.additionalAlignmentImages)
				referenceObjMapAdditional{addIdx}(:,:,1) = objectMapAdditional{addIdx}{options.trialToAlign};
			end
		end
		% for centroid
		[xCoords, yCoords] = findCentroid(inputImages{options.trialToAlign},'roundCentroidPosition',0);
		referenceObjMapCentroid = zeros(size(referenceObjMap(:,:,1)));
		refIdx = sub2ind(size(referenceObjMapCentroid),round(yCoords),round(xCoords));
		referenceObjMapCentroid(refIdx) = 1;

		nCorrections = options.nCorrections;

		registrationCoords = {};

		if options.runMotionCorrection==1
			for trialNo=1:nSessions
				if options.trialToAlign==trialNo
					continue
				end
				disp(repmat('#',1,7))
				for correctionNo=1:nCorrections
					disp(['trial ' num2str(trialNo) '/' num2str(nSessions) ' | correction ' num2str(correctionNo) '/' num2str(nCorrections)]);
					% inputImagesTurboreg = permute(inputImages{trialNo},[2 3 1]);
					inputImagesTurboreg = inputImages{trialNo};
					% attach the reference cellMap to the current images to be analyzed
					nImages = size(inputImages{trialNo},1);
					switchStrArray = {'centroid','normal'};
					% now align with additional inputs
					if ~isempty(options.additionalAlignmentImages)
						switchStrArray{end+1} = 'optional';
					end
					options.alignWithCentroids = 1;
					if options.alignWithCentroids==1
						% switchStrArray{end+1} = 'centroid';
					end
					%
					ioptions.RegisType =  RegisTypeFinal;
					ioptions.SmoothX=2;%10
					ioptions.SmoothY=2;%10
					ioptions.minGain=0.0;
					ioptions.Levels=6;
					ioptions.Lastlevels=1;
					ioptions.Epsilon=1.192092896E-07;
					ioptions.zapMean=0;
					%
					ioptions.turboregRotation =  1;
					ioptions.parallel =  1;
					ioptions.closeMatlabPool = 0;
					ioptions.meanSubtract =  0;
					ioptions.normalizeType = 'divideByLowpass';
					ioptions.registrationFxn = 'transfturboreg';
					ioptions.removeEdges = 0;
					ioptions.cropCoords = [];

					for switchNo = 1:length(switchStrArray)
						switch switchStrArray{switchNo}
							case 'optional'
								disp('+++++aligning optional images...')
								for addIdx=1:length(options.additionalAlignmentImages)
									disp(['+++++additional set ' num2str(addIdx)])
									size(referenceObjMapAdditional{addIdx})
									size(objectMapAdditional{addIdx}{trialNo})
									objMapsToTurboreg = cat(3,referenceObjMapAdditional{addIdx},objectMapAdditional{addIdx}{trialNo});
									clear ioptions;
									objectMapAdditionalTmp = turboregMovie(objMapsToTurboreg,'options',ioptions);
									objectMapAdditional{addIdx}{trialNo} = objectMapAdditionalTmp(:,:,2);
									ioptions.altMovieRegister = inputImagesTurboreg;
									[inputImagesTurboreg, registrationCoords{trialNo}{correctionNo}.(switchStrArray{switchNo})] = turboregMovie(objMapsToTurboreg,'options',ioptions);
									% (:,:,1) = objectMapAdditional{options.trialToAlign};
								end
							case 'centroid'
								% % now re-run the turboreg instead aligning the points, should produce an improved turboreg
								disp('+++++centroid align...')
								% [xCoords yCoords] = findCentroid(permute(inputImagesTurboreg,[3 1 2]));
								[xCoords, yCoords] = findCentroid(inputImagesTurboreg,'roundCentroidPosition',0);
								newLocalObjMap = zeros(size(referenceObjMap(:,:,1)));
								refIdx = sub2ind(size(newLocalObjMap),round(yCoords),round(xCoords));
								newLocalObjMap(refIdx) = 1;
								% se = strel('disk',2,8);
								se = strel('ball',10,5,0);
								referenceObjMapCentroidTmp = imdilate(referenceObjMapCentroid,se);
								newLocalObjMap = imdilate(newLocalObjMap,se);
								% new maps to turboreg

								objMapsToTurboreg = cat(3,referenceObjMapCentroidTmp,newLocalObjMap);
								%
								ioptions.altMovieRegister = inputImagesTurboreg;
								[inputImagesTurboreg, registrationCoords{trialNo}{correctionNo}.(switchStrArray{switchNo})] = turboregMovie(objMapsToTurboreg,'options',ioptions);

								if ~isempty(options.altInputImagesToRegister)
									[options.altInputImagesToRegister{trialNo}, ~] = turboregMovie(options.altInputImagesToRegister{trialNo},'precomputedRegistrationCooords',registrationCoords{trialNo}{correctionNo}.(switchStrArray{switchNo}));
								end
								% inputImagesTurboreg = manualMotionCorrection(referenceObjMapCentroidTmp,newLocalObjMap,'altMovieRegister',inputImagesTurboreg,'altImgDisplayRegister',{referenceObjMap,objectMap{trialNo}});
							case 'normal'
								disp('+++++normal align...')
									% objectMap{trialNo} = createObjMap(permute(inputImagesTurboreg,[3 1 2]));
									objectMap{trialNo} = createObjMap(inputImagesTurboreg);
									objMapsToTurboreg = cat(3,referenceObjMap,objectMap{trialNo});
									% turboreg the entire image, register the movie, leave matlab pool open for speed (don't need to start-up each run)
									ioptions.altMovieRegister = inputImagesTurboreg;
									ioptions.turboregRotation =  1;
									ioptions.RegisType =  RegisTypeFinal;
									ioptions.parallel =  1;
									ioptions.closeMatlabPool = 0;
									[inputImagesTurboreg registrationCoords{trialNo}{correctionNo}.(switchStrArray{switchNo})] = turboregMovie(objMapsToTurboreg,'options',ioptions);

									if ~isempty(options.altInputImagesToRegister)
										[options.altInputImagesToRegister{trialNo}, ~] = turboregMovie(options.altInputImagesToRegister{trialNo},'precomputedRegistrationCooords',registrationCoords{trialNo}{correctionNo}.(switchStrArray{switchNo}));
									end
							case 'binary'
								% now align with binary
								% disp('+++++binary align...')
									% objMapsToTurboreg = cat(3,referenceObjMapBinary,objectMapBinary{trialNo});
									% ioptions.altMovieRegister = inputImagesTurboreg;
									% ioptions.parallel = 1;
									% ioptions.closeMatlabPool = 0;
									% inputImagesTurboreg = turboregMovie(objMapsToTurboreg,'options',ioptions);
							otherwise
								% body
						end
					end

					% replace non-turboreged images
					% inputImages{trialNo} = permute(inputImagesTurboreg,[3 1 2]);
					inputImagesTurboreg(inputImagesTurboreg<options.turboregZeroThres) = 0;
					inputImages{trialNo} = inputImagesTurboreg;
					% thresholdInputImages{trialNo} = thresholdImages(inputImages{trialNo},'binary',0,'waitbarOn',1);
					objectMapBinary{trialNo} = createObjMap(inputImages{trialNo}>0);
					objectMap{trialNo} = createObjMap(inputImages{trialNo});
					[~, ~] = openFigure(59857, '');
					xplot = 4;
					yplot = 2;
					subplotNo = 1;
					subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(referenceObjMapBinary); title('reference');
					subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(objectMapBinary{trialNo}); title('current');
					subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(referenceObjMap); title('reference');
					subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(objectMap{trialNo}); title('current');
					% [figHandle figNo] = openFigure(59857, '');
					if ~isempty(options.additionalAlignmentImages)
						subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(referenceObjMapAdditional{addIdx}); title('reference');
						subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(objectMapAdditional{addIdx}{trialNo}); title('current');
					end
					if options.alignWithCentroids==1
						subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(referenceObjMapCentroidTmp); title('reference');
						subplot(xplot,yplot,subplotNo);subplotNo = subplotNo+1; imagesc(newLocalObjMap); title('current');
					end
				end
			end
		end

		% get new obj maps for each trial
		for i=1:nSessions
			size(inputImages{i});
			objectMapsTurboreg{i} = createObjMap(inputImages{i});
		end
		plotObjectMap(objectMapsTurboreg,344);

		% get the centroid locations of all objects
		for i=1:nSessions
			[xCoords, yCoords] = findCentroid(inputImages{i},'roundCentroidPosition',0);
			coords{i} = [xCoords; yCoords]';
		end

		% plot object coords for all trials in various colors
		plotCoords(coords,65,-1);

		% find matching objects across days
		switch options.analysisType
			case 'pairwise'
				[OutStruct] = computeGlobalIdsPairwise(OutStruct,coords,options,nSessions,inputImages,inputImagesOriginal);
			case 'clustering'
				[OutStruct] = computeGlobalIdsClustering(OutStruct,coords,options,nSessions);
			otherwise
				warning('Incorrect analysis type option!');
				% error
		end

		% get turboreged object maps
		for i=1:nSessions
			% thresholdedInput = thresholdImages(inputImages{i},'binary',1,'waitbarOn',1);
			objectMapTurboreg{i} = createObjMap(inputImages{i});
		end
		OutStruct.objectMapTurboreg = cat(3,objectMapTurboreg{:});

		OutStruct.registrationCoords = registrationCoords;
		OutStruct.coords = coords;
		OutStruct.inputImages = inputImages;
		if ~isempty(options.inputSignals)
			OutStruct.inputSignals = options.inputSignals;
		end
		if ~isempty(options.additionalAlignmentImages)
			OutStruct.objectMapAdditional = cat(3,objectMapAdditional{1});
		else
			OutStruct.objectMapAdditional = [];
		end

		coords{end+1} = OutStruct.coordsGlobal;
		plotCoords(coords,66,length(coords));

		% get 3D matrix of each global IDs matched objs in a single image, for checking how good alignment is
		% OutStruct.matchedObjMaps = displayMatchingObjs(inputImages,OutStruct)

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end

function [OutStruct] = computeGlobalIdsClustering(OutStruct,coords,options,nSessions)
		% computes the global ids via clustering, avoid some of the pairwise analysis problems

		% initialize the global centroid
		coordsGlobal = coords{options.trialToAlign};
		listOfTrialLengths(1) = size(coordsGlobal,1);

		% initialize global ref matrix
		OutStruct.globalIDs(:,1) = 1:size(coordsGlobal,1);

		% variables with 'local' in them are those for the current trial being compared to global
		for trial=1:nSessions
			if trial==options.trialToAlign
				continue
			end
			localCoords = coords{trial};
			listOfTrialLengths(trial) = size(localCoords,1);
			coordsGlobal = [coordsGlobal; localCoords];
		end
		distanceMatrix = squareform(pdist(coordsGlobal));
		OutStruct.originalDistanceMatrix = distanceMatrix;
		distanceMatrix(1:listOfTrialLengths(1), 1:listOfTrialLengths(1))=1e3;
		% avoid matching objects to themselves
		distanceMatrix.*~diag(ones(1,sum(listOfTrialLengths)));
		for trial=2:nSessions
			offSetIdx = sum(listOfTrialLengths(1:(trial-1)));
			nLocalCentroids = listOfTrialLengths(trial);
			% avoid matching objects from the same set
			distanceMatrix(offSetIdx+(1:nLocalCentroids), offSetIdx+(1:nLocalCentroids))=1e3;
		end
		figNo = 888;
		[~, ~] = openFigure(figNo, '');imagesc(log10(distanceMatrix));
		[~, ~] = openFigure(figNo, '');hist(distanceMatrix(:),1e2);zoom on
		OutStruct.distanceMatrix = distanceMatrix;

		% get clusters
		hClustTree=linkage(distanceMatrix, 'complete');
		% hClustTree=linkage(distanceMatrix, 'ward');
		[~, ~] = openFigure(figNo, '');
		dendrogram(hClustTree); zoom on
		% clusters=cluster(hClustTree,'criterion','distance','cutoff',options.maxDistance);
		clusters=cluster(hClustTree,'maxclust',round(size(distanceMatrix,1)/3));

		% group clusters and add to globalID matrix
		clusterList = unique(clusters);

		% initialize global ref matrix
		OutStruct.globalIDs = zeros([length(clusterList) nSessions]);
		OutStruct.coordsGlobal = NaN([length(clusterList) 2]);
		try
			% for each cluster, find object # for each trial and add to global ID matrix
			% also, get the mean coordinates for the global ID
			for clusterNo = 1:length(clusterList)
				iCluster = clusterList(clusterNo);
				% iGlobalIdx = find(clusters==iCluster);
				iGlobalIdx = [];

				% loop over each trial, find the idx and add it to the global ID list
				for trial=1:nSessions
					if trial==1
						offSetIdx = 0;
					else
						offSetIdx = sum(listOfTrialLengths(1:(trial-1)));
					end
					nLocalCentroids = listOfTrialLengths(trial);
					localClusters = clusters(offSetIdx+(1:nLocalCentroids));
					iLocalIdx = find(localClusters==iCluster);
					if length(iLocalIdx)>1
						disp('same objects matched within trial, skipping...');
					end
					if ~isempty(iLocalIdx)&length(iLocalIdx)==1
						OutStruct.globalIDs(clusterNo,trial) = iLocalIdx;
						iGlobalIdx(trial) = offSetIdx+iLocalIdx;
					end
				end

				iGlobalIdx = iGlobalIdx(iGlobalIdx~=0);
				% average the location of the global ID coordinates
				if ~isempty(iGlobalIdx)
					OutStruct.coordsGlobal(clusterNo,1) = mean(coordsGlobal(iGlobalIdx,1));
					OutStruct.coordsGlobal(clusterNo,2) = mean(coordsGlobal(iGlobalIdx,2));
				end
			end
			[~,~] = openFigure(figNo, '');imagesc(OutStruct.globalIDs);
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
end

function [OutStruct] = computeGlobalIdsPairwise(OutStruct,coords,options,nSessions,inputImages,inputImagesOriginal)
	% matches obj coordinates across trials, assigns them a global ID or creates a new one if no global ID is found

	% Make binary masts

	% inputImagesBinary = inputImages;
	% for ii = 1:length(inputImagesBinary)
	%     inputImagesBinary{i} = thresholdImages(inputImagesBinary{i},'binary',0,'waitbarOn',1,'threshold',options.threshold);
	% end

	% initialize the global centroid
	coordsGlobal = coords{options.trialToAlign};
	coordsGlobalCell = {};
	for kkk = 1:size(coords{options.trialToAlign},1)
		coordsGlobalCell{kkk} = coords{options.trialToAlign}(kkk,:);
	end

	% initialize global ref matrix
	% OutStruct.globalIDs(:,1) = 1:size(coordsGlobal,1);
	OutStruct.globalIDs(:,options.trialToAlign) = 1:length(coords{options.trialToAlign});

	ignoreDistanceReplace = 1e7;

	% variables with 'local' in them are those for the current trial being compared to global
	for i = 1:nSessions
		if i==options.trialToAlign
			OutStruct.globalIDs(1:length(coords{options.trialToAlign}),i) = 1:length(coords{options.trialToAlign});
			if isempty(options.trialIDs)
				OutStruct.trialIDs{i} = i;
			else
				OutStruct.trialIDs{i} = options.trialIDs{i};
			end
			continue
		end
		localCoords = coords{i};
		nGlobalCentroids = size(coordsGlobal,1);
		nLocalCentroids = size(localCoords,1);

		% obtain distance matrix of the centroid
		distanceMatrix = squareform(pdist([coordsGlobal; localCoords],'euclidean'));

		% obtain cell image correlation matrix
		% [R] = corr(a',b','Type','pearson')
		% inputImageSetGlobal =
		% inputImageSet2 =
		% [RHO,PVAL] = corr(allCellSignals(:,:)',allCellSignals(:,:)','type','Pearson');
		% ImgRho = diag(NaN(1,size(RHO,1)))+RHO;

		% [RHO,PVAL] = corr(allCellSignals(:,:)',allCellSignals(:,:)','type','Pearson');
		% RHO = diag(NaN(1,size(RHO,1)))+RHO;
		% RHOtmp = RHO;

		% avoid matching objects from the same set
		distanceMatrix(1:nGlobalCentroids, 1:nGlobalCentroids)=ignoreDistanceReplace;
		distanceMatrix(nGlobalCentroids+(1:nLocalCentroids), nGlobalCentroids+(1:nLocalCentroids))=ignoreDistanceReplace;
		% avoid matching objects to themselves
		distanceMatrix(logical(eye(size(distanceMatrix)))) = ignoreDistanceReplace;
		% distanceMatrix.*~diag(ones(1,nLocalCentroids+nGlobalCentroids));
		% figure(888+i);imagesc(distanceMatrix);

		% global are in rows, local in columns
		distanceMatrixCut = distanceMatrix(1:nGlobalCentroids,(nGlobalCentroids+1):end);
		% figure(999+i);imagesc(distanceMatrixCut);
		% find the minimum for the index
		[minDistances, minLocalIdx] = min(distanceMatrixCut,[],2);

		% remove duplicate minimum matching values
		minLocalIdxUnique = unique(minLocalIdx);
		for uniqueIdx = 1:length(minLocalIdxUnique)
			duplicateIdx = find(minLocalIdx==minLocalIdxUnique(uniqueIdx));
			distanceIdx = minDistances(duplicateIdx);
			[minDistDup, minLocalIdxDup] = min(distanceIdx);
			ignoreIdx = duplicateIdx;
			ignoreIdx(minLocalIdxDup) = [];
			% ignoreIdx = duplicateIdx(duplicateIdx~=minLocalIdxDup);
			% disp([num2str(duplicateIdx(:)') ' | ' num2str(ignoreIdx(:)') ' | ' num2str(distanceIdx(:)') '| ' num2str(minLocalIdxDup(:)')])
			minDistances(ignoreIdx) = ignoreDistanceReplace;
		end

		% find the global and local indexes for distances that meet criteria
		matchedGlobalIdx = find(minDistances<options.maxDistance);
		% only take the nearest cell
		% matchedGlobalIdx = matchedGlobalIdx(1);
		matchedLocalIdx = minLocalIdx(matchedGlobalIdx);
		% remove extra indicies that exceed the local index number
		matchedLocalIdx(matchedLocalIdx>nLocalCentroids) = [];

		% find objs from current trials that don't match
		newGlobalIdx = setdiff(1:nLocalCentroids,matchedLocalIdx);

		% remove extra indicies that aren't in matched that are beyond local index size
		% matchedLocalIdx>nLocalCentroids
		% matchedLocalIdx
		% nLocalCentroids
		% matchedLocalIdx(matchedLocalIdx>nLocalCentroids) = 0;

		% add the indicies from the current trial to the global idx matrix
		OutStruct.globalIDs(matchedGlobalIdx,i) = matchedLocalIdx;

		% extend
		OutStruct.globalIDs(end+1:end+length(newGlobalIdx),i) = newGlobalIdx;

		% UNMATCHED: add unmatched local coords to the global coordinates list
		coordsGlobal(end+1:end+length(newGlobalIdx),:) = localCoords(newGlobalIdx,:);
		coordsGlobalCellOld1 = coordsGlobalCell;
		if length(newGlobalIdx)>=1
			for globalNo = 1:length(newGlobalIdx)
				coordsGlobalCell{end+1} = localCoords(newGlobalIdx(globalNo),:);
			end
		end

		% Create anonymous function for correlation depending on user input
		ictH = options.imageCorrThres;
		fprintf('Using %s distance metric.\n',options.imageCorrType)
		switch options.imageCorrType
			case 'corr2'
				imageCorrFxn = @(x,y) corr2(x,y);
			case 'jaccard'
				imageCorrFxn = @(x,y) 1-simbin(x>ictH,y>ictH,'jaccard');
			case 'ochiai'
				imageCorrFxn = @(x,y) simbin(x>ictH,y>ictH,'ochiai');
			otherwise
				imageCorrFxn = @(x,y) simbin(x,y,options.imageCorrType);
		end

		% MATCHED: add matched objects to the global coordinates list
		if length(matchedGlobalIdx)>=1
			coordsGlobalCellOld = coordsGlobalCell;
			for globalNo = 1:length(matchedGlobalIdx)
				xGlobal = matchedGlobalIdx(globalNo);
				xLocal = matchedLocalIdx(globalNo);

				% coordsGlobalCell{xGlobal}(end+1,:) = localCoords(xLocal,:);

				if options.runImageCorr==0
					coordsGlobalCell{xGlobal}(end+1,:) = localCoords(xLocal,:);
				else
					% Get list of local IDs and session #s
					checkSessionList = find(OutStruct.globalIDs(xGlobal,:));
					checkIds = OutStruct.globalIDs(xGlobal,checkSessionList);

					% Check that it is highly correlated with existing images, else make a new global cell
					rhoH = NaN([1 length(checkIds)]);
					thisImg = inputImages{i}(:,:,xLocal);
					if options.checkImageCorr==1
						rhoH = NaN([2 length(checkIds)]);
						thisImg2 = inputImagesOriginal{i}(:,:,xLocal);
						figure(23232); linkAx = [];
						linkAx(end+1) = subplot(2,length(checkIds),1);imagesc(thisImg);;axis equal tight;
						linkAx(end+1) = subplot(2,length(checkIds),length(checkIds)+1);imagesc(thisImg2);;axis equal tight;
					end

					for jjj = 1:length(checkIds)
						% Do not compare image to itself
						if i==checkSessionList(jjj)
							continue;
						end
						testImg = inputImages{checkSessionList(jjj)}(:,:,checkIds(jjj));
						% rhoH(1,jjj) = imageCorrFxn(testImg,thisImg);
						% Make sure images are normalized to maximum = 1 to allow quick thresholding
						rhoH(1,jjj) = imageCorrFxn(testImg/nanmax(testImg(:)),thisImg/nanmax(thisImg(:)));

						if options.checkImageCorr==1
							testImg2 = inputImagesOriginal{checkSessionList(jjj)}(:,:,checkIds(jjj));
							rhoH(2,jjj) = imageCorrFxn(testImg2/nanmax(testImg2(:)),thisImg2/nanmax(thisImg2(:)));
							linkAx(end+1) = subplot(2,length(checkIds),jjj);imagesc(testImg);axis equal tight;
							linkAx(end+1) = subplot(2,length(checkIds),length(checkIds)+jjj);imagesc(testImg2);axis equal tight;
						end
					end
					if options.checkImageCorr==1
						linkaxes(linkAx); zoom on;
						display(rhoH)
						pause
					end
					rhoH = nanmean(rhoH);

					% Create a new global cell if fails image correlation test
					if rhoH>options.imageCorr
						fprintf('Passed image correlation test! Session %d, Global %d, Local %d: %0.2f.\n',i,xGlobal,xLocal,rhoH);
						coordsGlobalCell{xGlobal}(end+1,:) = localCoords(xLocal,:);
					else
						fprintf('Failed image correlation test! Session %d, Global %d, Local %d: %0.2f.\n',i,xGlobal,xLocal,rhoH);
						coordsGlobalCell{end+1} = localCoords(xLocal,:);
						OutStruct.globalIDs(end+1,i) = xLocal;
						coordsGlobal(end+1,:) = localCoords(xLocal,:);

						% Remove from global ID match list
						OutStruct.globalIDs(xGlobal,i) = 0;
					end
				end
			end

			% average the global and matched local coordinates to get a new global coordinate for that global obj
			for globalNo = 1:length(matchedGlobalIdx)
				xGlobal = matchedGlobalIdx(globalNo);
				coords1 = coordsGlobalCell{xGlobal}(:,1);
				coords2 = coordsGlobalCell{xGlobal}(:,2);
				coordsGlobal(xGlobal,1) = mean(coords1(:));
				coordsGlobal(xGlobal,2) = mean(coords2(:));
			end
		end
		% coordsGlobal(matchedGlobalIdx,1) = mean([coordsGlobal(matchedGlobalIdx,1) localCoords(matchedLocalIdx,1)],2);
		% coordsGlobal(matchedGlobalIdx,2) = mean([coordsGlobal(matchedGlobalIdx,2) localCoords(matchedLocalIdx,2)],2);

		if isempty(options.trialIDs)
			OutStruct.trialIDs{i} = i;
		else
			OutStruct.trialIDs{i} = options.trialIDs{i};
		end
	end
	OutStruct.coordsGlobal = coordsGlobal;
end

function plotCoords(coords,figNo,specialID)
	[~, ~] = openFigure(figNo, '');clf
	zoom on
	nCoords = length(coords);
	colorMatrix = hsv(nCoords);
	for objNo=1:nCoords
		if objNo==specialID
			legendArray{objNo} = 'global';
		else
			legendArray{objNo} = num2str(objNo);
		end
	end
	groupColorLegend(legendArray,colorMatrix);
	for objNo = [nCoords 1:(nCoords-1)]
		iCoords = coords{objNo};
		if objNo==specialID
			% plot(iCoords(:,2),iCoords(:,1),'Color',colorMatrix(objNo,:),'Marker','.','LineStyle','none','MarkerSize',10);
			plot(iCoords(:,2),iCoords(:,1),'Color','k','Marker','.','LineStyle','none','MarkerSize',10);
		else
			plot(iCoords(:,2),iCoords(:,1),'Color',colorMatrix(objNo,:),'Marker','.','LineStyle','none','MarkerSize',5);
		end
		hold on;
	end
	box off; axis off;
end

function plotObjectMap(objectMap,figNo)
	[~, ~] = openFigure(figNo, '');colormap jet;
	zoom on
	nSessions = length(objectMap);
	for i=1:nSessions
		subplot(3,ceil(nSessions/3),i);
		imagesc(objectMap{i});
		colormap(customColormap([]));
		box off; axis off;
	end
end

%% functionname: function description
function [inputImages] = checkImageDimensions(inputImages)
	nSessions = length(inputImages);
	dimsList = reshape(cell2mat(arrayfun(@(x){size(x{1})},inputImages))',3,length(inputImages))'
	minY = min(dimsList(:,1));
	minX = min(dimsList(:,2));
	for i=1:nSessions
		% iDims = size(inputImages{i});
		dimCheck = sum([minY minX] == dimsList(i,1:2));
		if dimCheck<2
			% [left-column top-row right-column bottom-row]
			inputCoords = [1 1 minX minY];
			% crop movie
			% inputImages{i} = cropMatrix(permute(inputImages{i},[2 3 1]),'inputCoords',inputCoords,'cropOrNaN','crop');
			inputImages{i} = cropMatrix(inputImages{i},'inputCoords',inputCoords,'cropOrNaN','crop');
			% inputImages{i} = permute(inputImages{i},[3 1 2]);
			% inputImages{i} = inputImages{i};
			disp(['trial ' num2str(i) '/' num2str(nSessions) ' cropped!']);
			% disp('not all images have the same dimensions! option to crop not implemented yet.');
			% return;
		else
			disp(['trial ' num2str(i) '/' num2str(nSessions) ' passed dimension checks!']);
		end
	end
end