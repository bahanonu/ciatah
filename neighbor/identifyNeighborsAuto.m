function neighborsCell = identifyNeighborsAuto(inputImages, inputSignals, varargin)
    % This code automatically sorts through to find all obj neighbors within a certain distance of the target (boundary to boundary). The output is a cell array with vectors of the neighbor indices to each obj.
    % Biafra Ahanonu
    % started: 2013.11.01
    % based on code by laurie burns, started: sept 2010.
    % inputs
        % inputImages - [x y nCells] matrices containing each set of filters
        % inputSignals - [nFilters frames] matrices containing each set of filter traces
    % options
        % _
    % outputs
        % _
    % changelog
        % 2013.11.01 refactored so accepts ICA filters and traces as input, also changed display to it matches ICAchooser, e.g. it applies a cellmap along with the identified and new cells
        % 2017.06.29 - change to using centroids since faster than imdilate and more accurate.
    % TODO
        %

    %========================
    options.plottingOn = 0;
    options.overlapradius = 10;
    % overlap radius in pixels (so convert properly)
    options.overlapDistance = 10;
    % 'centroid', 'imdilate'
    options.neighborMethod = 'centroid';
    %
    options.waitbarOn = 1;
    % Input pre-computed x,y coordinates for objects in images
    options.xCoords = [];
    options.yCoords = [];

    options.inputImagesThres = [];;

    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    % cell vector info
    cellvec(1) = 1;
    cellvec(2) = size(inputImages,3);

    %% look for overlap of IC and dilated IC
    neighborsCell=cell(cellvec(2),1);
    % reshape to (x,y,z) indexing for compatibility
    % inputImages = permute(inputImages, [2 3 1]);

    reverseStr = '';
    nSignals = cellvec(2);
    if options.plottingOn==1
        figure(222)
    end

    ignoreDistanceReplace = 1e7;


    % [xCoords yCoords] = findCentroid(signalImages,'thresholdValue',0.8,'imageThreshold',0.3);
    % coordsGlobal = [xCoords; yCoords]';
    % distanceMatrix = squareform(pdist(coordsGlobal));
    switch options.neighborMethod
        case 'centroid'
            % body
            % find all cells below distance threshold
            distanceThreshold = options.overlapDistance; % 1px = 1um, 20 um per Jesse's procedures
            nCells = size(inputImages,3);

            % get the centroids and other info for movie
            if isempty(options.xCoords)
                % [xCoords, yCoords] = findCentroid(inputImagesThres,'waitbarOn',options.waitbarOn,'runImageThreshold',0);
                [thresholdedImages boundaryIndices] = thresholdImages(inputImages,'binary',1,'getBoundaryIndex',1,'threshold',0.35,'imageFilter','');
                [xCoords yCoords] = findCentroid(thresholdedImages,'runImageThreshold',0);
            else
                xCoords = options.xCoords(:)';
                yCoords = options.yCoords(:)';
            end

            coordsGlobal = [xCoords; yCoords]';
            % size(coordsGlobal)
            % nCells
            distanceMatrix = squareform(pdist(coordsGlobal));
            % distanceMatrix = distanceMatrix.*~diag(1e5*ones(1,nCells));
            distanceMatrix(logical(eye(size(distanceMatrix)))) = ignoreDistanceReplace;

            distanceMatrixThres = distanceMatrix<distanceThreshold;
            neighborsCell = {};
            reverseStr = '';
            for cellNo = 1:nCells
                neighborIdx = find(distanceMatrixThres(cellNo,:));
                neighborsCell{cellNo,1} = neighborIdx;
                % if mod(cellNo,50)==1
                %     fprintf('up to cell number %d of %d \n',cellNo,nCells)
                % end
                if (cellNo==1||mod(cellNo,50)==0||cellNo==nCells)&options.waitbarOn==1
                    reverseStr = cmdWaitbar(cellNo,nCells,reverseStr,'inputStr','Finding cell neighbors');
                end
            end
            fprintf('Done assigning neighbor IDs ...')
        case 'imdilate'
            % do nothing
        otherwise
            for c = 1:nSignals
                se = strel('disk',overlapradius,0);
                % threshold ICs
                inputImages = thresholdImages(inputImages);
                % get a dilated version of the thresholded image
                thisCellDilateCopy = repmat(imdilate(squeeze(inputImages(:,:,c)),se),[1 1 size(inputImages,3)]);
                % thisCellDilateCopy = permute(thisCellDilateCopy, [3 1 2]);
                % matrix multiple, any overlap will be labeled
                res = inputImages.*thisCellDilateCopy;
                res = squeeze(sum(sum(res,2),1));
                % all cells above threshold are neighbors
                res = find(res>1);
                neighborsCell{c,1} = setdiff(res,c);
                % reduce waitbar access
                if c==1||mod(c,7)==0|c==nSignals
                    reverseStr = cmdWaitbar(c,nSignals,reverseStr,'inputStr','identifying neighboring cells');
                end
                if options.plottingOn==1
                    keyIn = get(gcf,'CurrentCharacter');
                    if strcmp(keyIn,'f')%user wants to exit
                        set(gcf,'currentch','3');drawnow;
                        keyIn = get(gcf,'CurrentCharacter');
                        break
                    end
                end
            end
    end
    if plottingOn
        viewNeighborsAuto(inputImages, inputSignals, neighborsCell);
    end
end