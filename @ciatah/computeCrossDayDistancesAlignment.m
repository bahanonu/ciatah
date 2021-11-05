function obj = computeCrossDayDistancesAlignment(obj)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	obj.sumStats = [];
	obj.sumStats.distances.cellDistances = [];
	obj.sumStats.distances.cellPairs = [];
	obj.sumStats.distances.sessionStr = {};

	obj.sumStats.centroids.sessionStr = {};
	obj.sumStats.centroids.cellNo = [];
	obj.sumStats.centroids.x = [];
	obj.sumStats.centroids.y = [];

	obj.sumStats.globalIDs.sessionStr = {};
	obj.sumStats.globalIDs.cellNo = [];
	obj.sumStats.globalIDs.numGlobalIDs = [];

	% Get all the cell distances
	theseFieldnames = fieldnames(obj.globalIDs.distances);
	allDistances = [];
	for subjNo = 1:length(theseFieldnames)
		fprintf('%s\n',theseFieldnames{subjNo})
		% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
		% allDistances = [allDistances(:); obj.globalIDs.distances.(theseFieldnames{subjNo}(:))];
		allDistances = obj.globalIDs.distances.(theseFieldnames{subjNo})(:);
		nPtsAdd = length(allDistances);
		obj.sumStats.distances.cellDistances(end+1:end+nPtsAdd,1) = allDistances;
		obj.sumStats.distances.cellPairs(end+1:end+nPtsAdd,1) = 1:length(allDistances);
		obj.sumStats.distances.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
	end
	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellDistanceStatsAligned.tab'];
	disp(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats.distances),savePath,'FileType','text','Delimiter','\t');

	% return;
	disp('===')
	% Get all the cell centroids
	theseFieldnames = fieldnames(obj.globalIDs.matchCoords);
	for subjNo = 1:length(theseFieldnames)
		fprintf('%s\n',theseFieldnames{subjNo})
	% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
		if strcmp(theseFieldnames{subjNo},'null')==1
			continue;
		end
		allCentroids = obj.globalIDs.matchCoords.(theseFieldnames{subjNo});
		nPtsAdd = size(allCentroids,1);
		obj.sumStats.centroids.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
		obj.sumStats.centroids.cellNo(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
		obj.sumStats.centroids.x(end+1:end+nPtsAdd,1) = allCentroids(:,2);
		obj.sumStats.centroids.y(end+1:end+nPtsAdd,1) = allCentroids(:,1);
	end

	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellCentroidsAligned.tab'];
	disp(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats.centroids),savePath,'FileType','text','Delimiter','\t');


	theseFieldnames = fieldnames(obj.globalIDs);
	for subjNo = 1:length(theseFieldnames)
		fprintf('%s\n',theseFieldnames{subjNo})
	% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
		if sum(strcmp(theseFieldnames{subjNo},{'null','matchCoords','distances'}))==1
			continue;
		end

		globalIDsD = obj.globalIDs.(theseFieldnames{subjNo});
		globalIDsIdx = logical(sum(globalIDsD~=0,2)>1);
		% globalIDs = globalIDs(globalIDsIdx,:);
		globalIDsIdx = sum(globalIDsIdx);

		nPtsAdd = size(globalIDsIdx,1);
		obj.sumStats.globalIDs.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
		obj.sumStats.globalIDs.cellNo(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
		obj.sumStats.globalIDs.numGlobalIDs(end+1:end+nPtsAdd,1) = globalIDsIdx(:);
		% obj.sumStats.globalIDs.y(end+1:end+nPtsAdd,1) = allCentroids(:,1);

		% clear cumProb nAlignSum;
		% nGlobalSessions = size(globalIDs,2);
		% nGIds = size(globalIDs,1);
		% for gID = 1:nGlobalSessions
	 %		  cumProb(gID) = sum(sum(~(globalIDs==0),2)==gID)/nGIds;
	 %		  nAlignSum(gID) = sum(sum(~(globalIDs==0),2)==gID);
	 %	 end
	end

	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_globalIDNums.tab'];
	disp(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats.globalIDs),savePath,'FileType','text','Delimiter','\t');

end