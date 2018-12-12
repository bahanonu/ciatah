function [matchIndsReal, matchIndsEst, meanDist] = computeCentroidMatches(realCellParams, estCellParams, varargin)
    % Matches real and estimates cells based on centroid location
    % Lacey Kitsch & Biafra Ahanonu
    % started: updating 2016.04.24
    % inputs
        %
    % outputs
        %

    % changelog
        % 2016.xx - changed inputs to getOptions format
    % TODO
        %

    %========================
    options.maxDistanceForMatch = 4;

    options.cellDistances = [];

    options.exclusionDistanceReal = 1e2;

    options.exclusionDistanceOther = 1e4;

    options.d = [];
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    try
        % cellDistances = options.cellDistances;
        cellDistances = options.d;
        maxDistanceForMatch = options.maxDistanceForMatch;

        nCellsReal = size(realCellParams,1);
        nCellsEst = size(estCellParams,1);

        if isempty(cellDistances)
            cellDistances = squareform(pdist([realCellParams(:,1:2); estCellParams(:,1:2)]));
        end

        cellDistances(1:nCellsReal,1:nCellsReal) = options.exclusionDistanceReal;
        cellDistances(nCellsReal+(1:nCellsEst),nCellsReal+(1:nCellsEst)) = options.exclusionDistanceOther;
        distSize = size(cellDistances);

        matchInds = zeros(min(nCellsReal,nCellsEst),2);
        nCellsMatched = 0;
        [minDist,minInd]=min(cellDistances(:));
        while minDist<=maxDistanceForMatch

            [ind1, ind2]=ind2sub(distSize,minInd);
            cellDistances(ind1,:)=options.exclusionDistanceOther; %#ok<AGROW>
            cellDistances(:,ind2)=options.exclusionDistanceOther; %#ok<AGROW>
            cellDistances(ind2,:)=options.exclusionDistanceOther; %#ok<AGROW>
            cellDistances(:,ind1)=options.exclusionDistanceOther; %#ok<AGROW>

            nCellsMatched=nCellsMatched+1;

            if ind1<=nCellsReal
                matchInds(nCellsMatched,1)=ind1;
                if ind2>nCellsReal
                    matchInds(nCellsMatched,2)=ind2-nCellsReal;
                else
                    disp('Warning: cell matching not working properly');
                end
            elseif ind2<=nCellsReal
                matchInds(nCellsMatched,1)=ind2;
                if ind1>nCellsReal
                    matchInds(nCellsMatched,2)=ind1-nCellsReal;
                else
                    disp('Warning: cell matching not working properly');
                end
            else
                disp('Warning: cell matching not working properly');
            end

            [minDist,minInd]=min(cellDistances(:));
        end

        matchIndsReal=matchInds(1:nCellsMatched,1);
        matchIndsEst=matchInds(1:nCellsMatched,2);

        [matchIndsReal, inds]=sort(matchIndsReal,'ascend');
        matchIndsEst=matchIndsEst(inds);

        meanDist=sqrt(sum((realCellParams(matchIndsReal(matchIndsReal>0),1:2)-estCellParams(matchIndsEst(matchIndsReal>0),1:2)).^2,2));

        meanDist=mean(meanDist);

    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
    end
end