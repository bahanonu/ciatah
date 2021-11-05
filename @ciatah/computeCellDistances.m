function obj = computeCellDistances(obj)
	% Calculates within session cell-cell distances.
	% Biafra Ahanonu
	% started: 2014.07.31
		% 2021.07.23 [13:50:08] branched from CIAtah
		% branch from calciumImagingAnalysis 2020.05.07 [15:16:56]
	% inputs
		%
	% outputs
		%
		
	% changelog
		% 2021.07.23 [00:22:22] - Added plots that show the distribution of cell-cell distances.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
		
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
			% obj.modelVarsFromFilesCheck(thisFileNum);
			 obj.modelVarsFromFilesCheck(thisFileNum);
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
				[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid] = modelGetSignalsImages(obj,'returnType','raw');
				nIDs = length(obj.stimulusNameArray);
				nSignals = size(inputSignals,1);
				if isempty(inputImages);continue;end
				% [xCoords yCoords] = findCentroid(inputImages);
				[xCoords, yCoords] = findCentroid(inputImages,'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
				% continue;
			end
			distMatrix = squareform(pdist([xCoords(:)*obj.MICRON_PER_PIXEL yCoords(:)*obj.	MICRON_PER_PIXEL]));
			distMatrix(logical(eye(size(distMatrix)))) = NaN;
			% figure;imagesc(distMatrix==0);colorbar;

			distMatrixPairs = distMatrix(:);
			distMatrixPairs = distMatrixPairs(~isnan(distMatrixPairs));

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
	
	% plot outputs
	figure;
	clear g;
	maxVal = ceil(nanmax(obj.sumStats.cellDistances(:)));
	edgeVals = [-1:(maxVal+1)];
	g(1,1) = gramm('x',obj.sumStats.cellDistances,'color',obj.sumStats.sessionStr);
	g(1,2)=copy(g(1));
	g(2,1)=copy(g(1));
	g(2,2)=copy(g(1));
	g(3,1)=copy(g(1));
	g(3,2)=copy(g(1));
	% g.facet_grid(obj.sumStats.sessionStr,[]);
	% g.stat_density();	
	g(1,1).stat_bin('geom','line','edges',edgeVals); %Default binning (30 bins)
    g(1,1).set_title('Histogram raw counts','FontSize',10);

	g(2,1).stat_bin('normalization','probability','geom','line','edges',edgeVals); %Default binning (30 bins)
    g(2,1).set_title('Histogram counts (probability)','FontSize',10);
    
	%Normalization to 'probability'
	% g(2,1).stat_bin('normalization','probability','geom','overlaid_bar');
	% g(2,1).set_title('''normalization'',''probability''','FontSize',10);
	g(3,1).stat_bin('normalization','cumcount','geom','line','edges',edgeVals);
	g(3,1).set_title('Zoomed','FontSize',10);
	g(3,1).axe_property('XLim',[0 20],'YLim',[0 200]);
	% xlim([0 20]);ylim([0 200]);

	%Normalization to cumulative count
	g(1,2).stat_bin('normalization','cumcount','geom','line','edges',edgeVals);
	g(1,2).set_title('''normalization'',''cumcount''','FontSize',10);

	%Normalization to cumulative density
	g(2,2).stat_bin('normalization','cdf','geom','stairs','edges',edgeVals);
	g(2,2).set_title('''normalization'',''cdf''','FontSize',10);
    
    % Holder
    g(3,2).stat_bin('normalization','cumcount','geom','line','edges',edgeVals);
	g(3,2).set_title('Zoomed','FontSize',10);
	g(3,2).axe_property('XLim',[0 1],'YLim',[0 1]);
    g(3,2).set_title('Legend','FontSize',10);
    
    g(1,1).no_legend();
    g(1,2).no_legend();
    g(2,1).no_legend();
    g(2,2).no_legend();
    g(3,1).no_legend();
	
    g.set_names('color','Animal-session','x','Cell-cell distance (px)');
	g.set_title('Cell-cell distances within sessions');

	g.draw();
	
	% line([5 5],[0 200],'Color','k','LineStyle','--','Parent',g.facet_axes_handles(3));
		
	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellDistanceStats.csv'];
	disp(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter',',');
end