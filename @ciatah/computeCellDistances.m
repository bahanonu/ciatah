function obj = computeCellDistances(obj)
	obj.sumStats = [];
	obj.sumStats.cellDistances = [];
	obj.sumStats.cellPairs = [];
	obj.sumStats.sessionStr = {};

	[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = obj.getAnalysisSubsetsToAnalyze();

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			% disp(repmat('=',1,21))
			fprintf('%s\n %d/%d (%d/%d): %s\n',repmat('=',1,21),thisFileNumIdx,nFilesToAnalyze,thisFileNum,nFiles,obj.fileIDNameArray{obj.fileNum})
			% disp([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);

			% try
			methodNum = 2;
			if methodNum==1
				disp('Using previously computed centroids...')
				[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid] = modelGetSignalsImages(obj,'returnOnlyValid',1);
				xCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(valid,1);
				yCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(valid,2);
				% npts = length(xCoords);
				% distanceMatrix = diag(zeros(1,npts))+squareform(distMatrix);
			else
			% catch
				[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid] = modelGetSignalsImages(obj);
				nIDs = length(obj.stimulusNameArray);
				nSignals = size(inputSignals,1);
				if isempty(inputImages);continue;end
				% [xCoords yCoords] = findCentroid(inputImages);
				[xCoords, yCoords] = findCentroid(inputImages,'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
				% continue;
			end
			distMatrix = pdist([xCoords(:)*obj.MICRON_PER_PIXEL yCoords(:)*obj.	MICRON_PER_PIXEL]);
			distMatrix(logical(eye(size(distMatrix)))) = NaN;

			distMatrixPairs = distMatrix(:);
			distMatrixPairs(~isnan(distMatrixPairs));

			nPtsAdd = length(distMatrixPairs);
			obj.sumStats.cellDistances(end+1:end+nPtsAdd,1) = distMatrixPairs;
			obj.sumStats.cellPairs(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
			obj.sumStats.sessionStr(end+1:end+nPtsAdd,1) = {obj.fileIDArray{obj.fileNum}};
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end

	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellDistanceStats.csv'];
	disp(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter',',');
end