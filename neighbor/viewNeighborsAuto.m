function viewNeighborsAuto(inputImages, inputSignals, neighborsCell, varargin)
	% View the neighboring cells, their traces and trace correlations.
	% Biafra Ahanonu
	% started 2013.11.01
	% inputs
		% inputImages - [x y nCells] matrices containing each set of filters
		% inputSignals - [nFilters frames] matrices containing each set of filter traces
		% neighborsCell - {nCells 1} cell array of [nNeighborId 1] vectors of neighbor IDs for each cell matching indices in inputImages
	% outputs
		%
	% changelog
		% 2018 - updated interface, speed improvements.
		% 2019.05.28 [13:49:31] - No longer use montage to create montage, use loops plus cat and cell arrays to improve speed, reduce use of montage(), and make outlines crisp (on 2018b they would become expanded with montage).
		% 2019.05.28 [15:15:43] - General improvements to GUI clarity.
		% 2019.06.18 [14:54:34] - Added support for spatial correlations
	% TODO
		%

	%========================
	options.plottingOn = 0;
	options.overlapradius = 10;
	% overlap radius in pixels (so convert properly)
	options.overlapDistance = 10;
	% 'centroid', 'imdilate'
	options.neighborMethod = 'centroid';
	% Input pre-computed x,y coordinates for objects in images
	options.xCoords = [];
	options.yCoords = [];
	%
	options.inputImagesThres = [];
	%
	options.startCellNo = 1;
	%
	options.cropSizeLength = 20;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(neighborsCell)
		copts = options;
		neighborsCell = identifyNeighborsAuto(inputImages, inputSignals,'options',copts);
	end

	% cell vector info
	cellvec(1) = 1;
	cellvec(2) = size(inputImages,3);
	valid = zeros(1,cellvec(2));

	openFigure(21,'full');
		clf

	exitLoop = 0;
	nCells = cellvec(2);
	cellnum = options.startCellNo;
	cropSizeLength = options.cropSizeLength;
	usePadding = 1;
	xCoords = [];
	yCoords = [];

	rowP = 3;
	colP = 3;

	% instructions
	instructionStr =  ['Controls: left/right arrow:forward/back | e:exit | g:(goto cell #)' 10 ' cell #s low-high from top to bottom | top trace = this cell' 10];


	set(21, 'KeyPressFcn', @(source,eventdata) figure(21));
	while exitLoop==0
		directionOfNextChoice = 0;
		thisFilt = squeeze(inputImages(:,:,cellnum));
		if issparse(thisFilt)
			thisFilt = full(thisFilt);
		end
		nList = [cellnum neighborsCell{cellnum,1}(:)'];
		% nList
		% montage of nearby cells
		subplot(rowP,colP,1)
			rgbImage = [];
			nImgs = inputImages(:,:,nList);
			if issparse(nImgs)
				nImgs = full(nImgs);
			end
			nMatchCells = size(nImgs,3);

			objCutMovie = getObjCutMovie(nImgs,thisFilt,'createMontage',0,'extendedCrosshairs',0,'crossHairVal',NaN,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN);
			objCutMovie = vertcat(objCutMovie{:});
			[thresholdedImages boundaryIndices] = thresholdImages(objCutMovie(:,:,1),'binary',1,'getBoundaryIndex',1,'threshold',0.35,'imageFilter','','waitbarOn',0,'normalizationType','zeroToOne','removeUnconnected',1,'boundaryHoles','noholes');

			for zz = 1:size(nImgs,3)
				tmpImg = squeeze(objCutMovie(:,:,zz));
				tmpImg([boundaryIndices{:}]) = NaN;

				% tmpImg = squeeze(nanmean(...
				%     insertText(tmpImg,[0 0],num2str(nList(zz)),...
				%     'BoxColor',[0 0 0],...
				%     'TextColor',[1e10 1e10 1e10],...
				%     'AnchorPoint','LeftTop',...
				%     'FontSize',8,...
				%     'BoxOpacity',0)...
				% ,3));
				% tmpImg(tmpImg>1e7) = NaN;
				% figure;imagesc(tmpImg)
				objCutMovie(:,:,zz) = tmpImg;
			end
			clear objCutMovie2;
			objCutMovie2(:,:,1,:) = objCutMovie;
			% montage(objCutMovie2)

			croppedPeakImagesCell = {};
			[xPlot yPlot] = getSubplotDimensions(size(objCutMovie,3));
			for iii = 1:xPlot*yPlot
				if iii>size(objCutMovie,3)
					croppedPeakImagesCell{iii} = NaN(size(objCutMovie(:,:,1)));
				else
					croppedPeakImagesCell{iii} = objCutMovie(:,:,iii);
				end
			end
			mNum = 1;
			g = cell([xPlot 1]);
			rowNum = 1;

			xyLoc = ones([nMatchCells 2]);
			xyLoc(:,2) = [3];
			xyLoc(:,1) = [2];

			cellNoHere = 1;
			for xNo = 1:xPlot
				for yNo = 1:yPlot
					g{rowNum} = cat(2,g{rowNum},croppedPeakImagesCell{mNum});

					if sum(isnan(croppedPeakImagesCell{mNum}(:)))~=numel(croppedPeakImagesCell{mNum}(:))&&cellNoHere>1&&yNo>1
						xyLoc(cellNoHere,:) = [xyLoc(cellNoHere-1,1)+options.cropSizeLength*2+1 xyLoc(cellNoHere,2)];
					end
					cellNoHere = cellNoHere+1;
					mNum = mNum + 1;
				end

				xyLoc(cellNoHere:end,2) = [xyLoc(cellNoHere:end,2)+options.cropSizeLength*2+1];
				xyLoc(cellNoHere:end,1) = [2];
				rowNum = rowNum + 1;
			end
			croppedPeakImages2 = cat(1,g{:});

			% croppedPeakImages2 = getimage;
			imAlpha = ones(size(croppedPeakImages2));
			imAlpha(isnan(croppedPeakImages2))=0;
			imagesc(croppedPeakImages2,'AlphaData',imAlpha);
			set(gca,'color',[0 0 0]);
			colormap(gca,customColormap([]))
			title(['neighboring cell ID #s (white)' 10 'top-left = selected cell' 10 '#s increase L->R and T->B'])
			% title(['neighboring cells | top-left = selected cell, #s increase L->R and T->B'])
			axis equal tight
			box off

			% xyLoc
			for zz = 1:size(nImgs,3)
				text(xyLoc(zz,1),xyLoc(zz,2),num2str(nList(zz)),'Color',[1 1 1],'FontSize',options.cropSizeLength/2)
			end

		% plot the traces
		subplot(rowP,colP,[2:3 5:6 8:9])
			% nList = [cellnum neighborsCell{cellnum,1}(:)'];
			% plotSignalsGraph(inputSignals, 'plotList', flipdim(nList(:),1),'newAxisColorOrder','','minAdd',0,'maxIncrementPercent',1.1);
			plotSignalsGraph(inputSignals, 'plotList', flipdim(nList(:),1),'newAxisColorOrder','lines','minAdd',0,'maxIncrementPercent',1.1);
			axis tight
			xlabel('Time (frames)')
			ylabel('Cell activity')
			title('Activity traces for selected and neighboring cells (Zoom enabled)')
			legend(strsplit(num2str(nList),' '),'Location','southoutside','Orientation','horizontal')
			% suptitle(instructionStr);
			zoom on

		% plot temporal correlations
		subplot(rowP,colP,4)
			z0 = corr(inputSignals(nList(:),:)');
			imagesc(z0)
			colorbar
			colormap(gca,customColormap([]))
			% colorbar; colormap jet;
			% colormap hot

			% imagesc(l);
			xlabel('Cell ID #s');
			ylabel('Cell ID #s');
			xticks(1:length(nList))
			xticklabels(nList)
			yticks(1:length(nList))
			yticklabels(nList)
			title(['cell-cell activity trace correlations' 10 'cell #' num2str(nList(1)) ' = this cell']);
			box off; axis equal tight
			caxis([0 1])
			% datacursormode on

		% plot spatial correlations
		subplot(rowP,colP,7)

			nCellsH = length(nList);
			fracMaxVal = 0.2;
			tmpImgs = inputImages(:,:,nList);
			if issparse(tmpImgs)
				tmpImgs = full(tmpImgs);
			end
			for cInd1 = 1:nCellsH
				tmpImgs1 = tmpImgs(:,:,cInd1);
				tmpImgs1(tmpImgs1<(nanmax(tmpImgs1(:))*fracMaxVal)) = 0;
				tmpImgs(:,:,cInd1) = tmpImgs1;
			end

			cEst = permute(tmpImgs, [3 1 2]);
			cEst = reshape(cEst, [size(cEst,1), numel(inputImages(:,:,1))]);
			% figure;imagesc(cEst);pause
			corrImgMatrix = 1-squareform(pdist(single(cEst>0),'jaccard'));

			spatialCorr = z0*0;
			spatialCorr2 = z0*0;
			for cInd1 = 1:nCellsH
				cImg1 = tmpImgs(:,:,cInd1);
				cImg1_2 = inputImages(:,:,nList(cInd1));
				for cInd2 = 1:nCellsH
					if cInd2==cInd1
						spatialCorr(cInd1,cInd2) = 1;
					end
					if cInd2>cInd1
						continue;
					end
					cImg2 = tmpImgs(:,:,cInd2);
					cImg2_2 = inputImages(:,:,nList(cInd2));

					% cImg1(cImg1<(nanmax(cImg1(:))*fracMaxVal)) = 0;
					% cImg2(cImg2<(nanmax(cImg2(:))*fracMaxVal)) = 0;

					c1Pixels = find(cImg1>0);
					c2Pixels = find(cImg2>0);
					thisOverlap=length(intersect(c1Pixels,c2Pixels));
					thisOverlap1=thisOverlap/length(c1Pixels);
					thisOverlap2=thisOverlap/length(c2Pixels);

					spatialCorr(cInd1,cInd2) = thisOverlap1;
					spatialCorr(cInd2,cInd1) = thisOverlap2;

					c1Pixels = find(cImg1_2>0);
					c2Pixels = find(cImg2_2>0);
					thisOverlap=length(intersect(c1Pixels,c2Pixels));
					thisOverlap1=thisOverlap/length(c1Pixels);
					thisOverlap2=thisOverlap/length(c2Pixels);

					spatialCorr2(cInd1,cInd2) = thisOverlap1;
					spatialCorr2(cInd2,cInd1) = thisOverlap2;
				end
			end
			imagesc(cat(2,spatialCorr,corrImgMatrix,spatialCorr2));
			colorbar
			colormap(gca,customColormap([]))
			% colorbar; colormap jet;
			% colormap hot

			% imagesc(l);
			xlabel('Cell ID #s');
			ylabel('Cell ID #s');
			nListLen = length(nList);
			xticks(1:(nListLen*3))
			xticklabels([nList; nList; nList])
			yticks(1:length(nList))
			yticklabels(nList)
			title(['cell-cell image correlations']);
			box off; axis equal tight
			hold on;
			% plot([nListLen+0.5 nListLen+0.5],get(gca,'YLim'),'k-','LineWidth',1);
			% plot([nListLen*2+0.5 nListLen*2+0.5],get(gca,'YLim'),'k-','LineWidth',1);
			hold off;
			% datacursormode on
			caxis([0 1])

		suptitle([sprintf('cell # %d/%d',cellnum,nCells) 10 instructionStr],'plotregion',0.9);
		set(findall(gcf,'-property','FontSize'),'FontSize',13);
		% [x,y,reply]=ginput(1);

		set(gcf,'currentch','3');
		keyIn = get(gcf,'CurrentCharacter');
		figure(21)

		while strcmp(keyIn,'3')
			keyIn = get(gcf,'CurrentCharacter');
			pause(0.05);
		end
		reply = double(keyIn);
		set(gcf,'currentch','3');

		[valid directionOfNextChoice exitLoop cellnum] = respondToUserInput(reply,cellnum,valid,directionOfNextChoice,exitLoop,nCells);

		cellnum=cellnum+directionOfNextChoice;
		% loop if user gets to either end
		if cellnum<=0
			cellnum = nCells;
		elseif i>nCells;
			cellnum = 1;
		end
	end
	close(21)

end

function [valid directionOfNextChoice exitLoop i] = respondToUserInput(reply,i,valid,directionOfNextChoice,exitLoop,nCells)
	% decide what to do based on input (not a switch due to multiple comparisons)
	if isequal(reply, 3)|isequal(reply, 110)|isequal(reply, 31)
		% n key or right click
		directionOfNextChoice=1;
		% display('invalid IC');
		% set(fig1,'Color',[0.8 0 0]);
		valid(i) = 0;
	elseif isequal(reply, 28)
		% go back, left
		directionOfNextChoice=-1;
	elseif isequal(reply, 29)
		% go forward, right
		directionOfNextChoice=1;
	elseif isequal(reply, 101)
		exitLoop=1;
		% user clicked 'f' for finished, exit loop
		% i=nCells+1;
	elseif isequal(reply, 103)
		% if user clicks 'g' for goto, ask for which IC they want to see
		icChange = inputdlg('enter signal #'); icChange = str2num(icChange{1});
		if icChange>nCells|icChange<1
			% do nothing, invalid command
		else
			i = icChange;
			directionOfNextChoice = 0;
		end
	elseif isequal(reply, 115)
		% 's' if user wants to get ride of the rest of the ICs
		display(['classifying the following signals as bad: ' num2str(i) ':' num2str(nCells)])
		valid(i:nCells) = 0;
		exitLoop=1;
	elseif isequal(reply, 121)|isequal(reply, 1)|isequal(reply, 30)
		% y key or left click
		directionOfNextChoice=1;
		% display('valid IC');
		% set(fig1,'Color',[0 0.8 0]);
		valid(i) = 1;
	else
		% forward=1;
		% valid(i) = 1;
	end
end