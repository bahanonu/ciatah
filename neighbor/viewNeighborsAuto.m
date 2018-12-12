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

    % instructions
    instructionStr =  ['forward/back | e:exit | g:(goto cell #) | cell #s low-high from top to bottom | top trace = this cell' 10];

    while exitLoop==0
        directionOfNextChoice = 0;
        thisFilt = squeeze(inputImages(:,:,cellnum));

        % montage of nearby cells
        subplot(2,3,3)
            rgbImage = [];
            nImgs = inputImages(:,:,[cellnum; neighborsCell{cellnum,1}(:)]);

            objCutMovie = getObjCutMovie(nImgs,thisFilt,'createMontage',0,'extendedCrosshairs',1,'crossHairVal',NaN,'outlines',1,'waitbarOn',0,'cropSize',cropSizeLength,'addPadding',usePadding,'xCoords',xCoords,'yCoords',yCoords,'outlineVal',NaN);
            objCutMovie = vertcat(objCutMovie{:});
            [thresholdedImages boundaryIndices] = thresholdImages(objCutMovie(:,:,1),'binary',1,'getBoundaryIndex',1,'threshold',0.35,'imageFilter','','waitbarOn',0);
            for zz = 1:size(nImgs,3)
                tmpImg = squeeze(objCutMovie(:,:,zz));
                tmpImg([boundaryIndices{:}]) = NaN;
                objCutMovie(:,:,zz) = tmpImg;
            end
            clear objCutMovie2;
            objCutMovie2(:,:,1,:) = objCutMovie;
            montage(objCutMovie2)
            colormap(gca,customColormap([]))

            croppedPeakImages2 = getimage;
            imAlpha = ones(size(croppedPeakImages2));
            imAlpha(isnan(croppedPeakImages2))=0;
            imagesc(croppedPeakImages2,'AlphaData',imAlpha);
            set(gca,'color',[0 0 0]);
            title(['#' num2str(cellnum) '/' num2str(nCells) ' | neighboring cells | top-left = this cell'])

        % plot the traces
        subplot(2,3,[1:2 4:5])
            nList = [cellnum neighborsCell{cellnum,1}(:)'];
            plotSignalsGraph(inputSignals, 'plotList', flipdim(nList(:),1),'newAxisColorOrder','','minAdd',0,'maxIncrementPercent',1.1);
            axis tight
            xlabel('Time (frames)')
            ylabel('Cell activity')
            title(instructionStr);

        % plot correlations
        subplot(2,3,6)
            z0 = corr(inputSignals(nList(:),:)');
            imagesc(z0)
            colorbar
            colormap(gca,jet)
            % colorbar; colormap jet;
            % colormap hot

            % imagesc(l);
            xlabel('cells');
            ylabel('cells');
            title(['cell-cell trace correlations | cell #1 = this cell']);


        set(findall(gcf,'-property','FontSize'),'FontSize',13);
        [x,y,reply]=ginput(1);
        [valid directionOfNextChoice exitLoop cellnum] = respondToUserInput(reply,cellnum,valid,directionOfNextChoice,exitLoop,nCells);

        cellnum=cellnum+directionOfNextChoice;
        % loop if user gets to either end
        if cellnum<=0
            cellnum = nCells;
        elseif i>nCells;
            cellnum = 1;
        end
    end

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
        icChange = inputdlg('enter IC #'); icChange = str2num(icChange{1});
        if icChange>nCells|icChange<1
            % do nothing, invalid command
        else
            i = icChange;
            directionOfNextChoice = 0;
        end
    elseif isequal(reply, 115)
        % 's' if user wants to get ride of the rest of the ICs
        display(['classifying the following ICs as bad: ' num2str(i) ':' num2str(nCells)])
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