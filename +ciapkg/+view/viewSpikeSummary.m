function [signalMatrix signalSpikes] = viewSpikeSummary(signalMatrix,signalSpikes,varargin)
	% gives several summary plots for a set of signals
	% biafra ahanonu
	% started: 2013.10.28
	% inputs
		% signalMatrix - 2D matrix of [signals frames] that contains the raw analog signal
		% signalSpikes - 2D matrix of [signals frames] that contains 0/1 indicating whether a peak occurred at that point
	% outputs
		% signalMatrix - 2D matrix of [signals frames] that contains the raw analog signal
		% signalSpikes - 2D matrix of [signals frames] that contains 0/1 indicating whether a peak occurred at that point
	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.figStart = 100;
	% synchronous activity threshold, percent of total signals active
	options.syncThreshold = 0.013;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% make plots...
	figNo = options.figStart;
	% openFigure(figStart,'full');hold off;figStart=figStart+1;
	[figHandle figNo] = openFigure(figNo, '');
	% subplot(2,2,1)
	%     signalMatrix(signalMatrix<0)=0;
	%     imagesc(signalMatrix);
	%     title(['dfof for all signals over entire trial'])
	%     set(gca,'Color','none'); box off;
	%     colormap hot;
	%
	% DATA
	signalSpikesShuffle = shuffleMatrix(signalSpikes);
	signalSpikesCell = {signalSpikes,signalSpikesShuffle};

	%
	num = 1;
	for i=[0,2]
		subplot(4,1,1+i)
			imagesc(~signalSpikesCell{num});
			title(['spikes for all signals over entire trial'])
			set(gca,'Color','none'); box off;
			colormap gray;%        colormap hot
		%
		subplot(4,1,2+i)
			nSignals = size(signalSpikesCell{num},1);
			nFrames = size(signalSpikesCell{num},2);
			syncSpikes = sum(signalSpikesCell{num},1);
			syncSpikesPct = syncSpikes/nSignals;
			% find(syncSpikes==options.syncThreshold);
			% smoothhist2D([g2; sum(g)]',7,[100,100],0.05,'image');hold on;box off;
			plot(1:nFrames, syncSpikesPct,'r');box off;
			title(['all signals: frame v. firing rate']);
			% legend('distance traveled','Location','NorthWest')
			xlabel('frame'); ylabel('percent signals with peaks');

		num = num+1;
	end
	% %
	% subplot(2,2,4)
	%     topCells = sum(signalSpikes,2);
	%     topCellCutoff = quantile(topCells, [0.9]);
	%     topCellIdx = find(topCells>=topCellCutoff);
	%     g=signalSpikes(topCellIdx,:);
	%     g2=1:length(sum(g));
	%     % smoothhist2D([g2; sum(g)]',7,[100,100],0.05,'image');hold on;box off;
	%     plot(sum(g,1),'r');box off;
	%     title(['signals with top 10% peaks: frame v. firing rate']);
	%     % legend('distance traveled','Location','NorthWest')
	%     xlabel('frame'); ylabel('firing rate (spikes/frame)');

	% histogram of total spikes in trial across all cells
	% openFigure(figStart,'full');hold off;figStart=figStart+1;
	[figHandle figNo] = openFigure(figNo, '');
	subplot(2,2,1)
		signalStd = std(sum(signalSpikes,2));
		signalMean = mean(sum(signalSpikes,2));
		% tmpVals = signalMatrix(logical(signalSpikes));
		% hist(tmpVals(:),30);box off;
		hist(sum(signalSpikes,2),30);box off;
		title(['distribution total peaks, individual signals:',10,' std=' num2str(signalStd) ', mean=' num2str(signalMean)]);
		xlabel('total peaks');ylabel('count');
		h = findobj(gca,'Type','patch');
		set(h,'FaceColor',[0 0 0],'EdgeColor','none');

	plotAlpha = 0.3;

	subplot(2,2,2)
		ITIall = [];
		for i=1:size(signalSpikes,1)
			ITIest(i) = mean(diff(find(signalSpikes(i,:)==1)));
			ITIall = [ITIall diff(find(signalSpikes(i,:)==1))];
		end
		histBins = round(logspace(1,log10(max(ITIest))));
		histCounts = hist(ITIest,histBins);
		hist(ITIest,histBins);
		box off;
		title('distribution of ITIs, averaged across signals');
		xlabel('mean ITI (frames)');ylabel('count');
		set(gca,'xscale','log');
		h = findobj(gca,'Type','patch');
		set(h(1),'FaceColor','k','FaceAlpha',plotAlpha,'EdgeColor','none');

	subplot(2,2,3)
		binMax = max(sum(signalSpikes,1));
		histBins = 0:binMax;
		histCounts = hist(sum(signalSpikes,1),histBins);
		histCounts = histCounts/sum(histCounts);
		histCountsShuffle = hist(sum(signalSpikesShuffle,1),histBins);
		histCountsShuffle = histCountsShuffle/sum(histCountsShuffle);

		bar(histBins,[histCounts; histCountsShuffle]','BarWidth', 1);hold on;
		% hist(sum(signalSpikes,1),histBins);hold on;
		% hist(sum(signalSpikesShuffle,1),histBins);
		h = findobj(gca,'Type','patch');
		%set(h(1),'FaceColor','r','FaceAlpha',plotAlpha,'EdgeColor','none');
		%set(h(2),'FaceColor','b','FaceAlpha',plotAlpha,'EdgeColor','none');
		set(gca,'XLim',[-0.5 binMax])
		box off;
		title('distribution simultaneous firing events');
		xlabel('simultaneous spikes');
		set(gca,'xminortick','on')
		ylabel('density (%)');
		legend({'normal','shuffled'});legend boxoff;
		hold off;

	subplot(2,2,4)
		[histCounts histBins] = getSyncCounts(signalSpikes,options);
		[histCountsShuffle histBinsShuffle] = getSyncCounts(signalSpikesShuffle,options);
		bar(histBins,[histCounts; histCountsShuffle]','BarWidth', 1);
		h = findobj(gca,'Type','patch');
		set(h(1),'FaceColor','r','FaceAlpha',plotAlpha,'EdgeColor','none');
		set(h(2),'FaceColor','b','FaceAlpha',plotAlpha,'EdgeColor','none');
		box off;
		set(gca,'XLim',[-0.01 max(histBins)+0.05])
		legend({'normal','shuffled'});legend boxoff;
		set(gca,'xminortick','on')
		% set(gca,'YScale','log');
		% title('distribution simultaneous firing events');
		xlabel('participation in sync activity (%)');
		ylabel('density (%)');
		hold off;


		% h = findobj(gca,'Type','patch');
		% set(h,'FaceColor',[0 0 0],'EdgeColor','none');
	% subplot(2,2,4)
	%     hist(ITIall,round(logspace(0,log10(max(ITIall)))));box off;
	%     title('distribution of all ITIs in all signals');
	%     xlabel('ITI (frames)');ylabel('count');
	%     set(gca,'xscale','log');
	%     h = findobj(gca,'Type','patch');
	%     set(h,'FaceColor',[0 0 0],'EdgeColor','w');

		% openFigure(figStart,'half');hold off;figStart=figStart+1;

		% [x,y,reply]=ginput(1);

		% openFigure(figStart,'half');figStart=figStart+1;
		% g = sum(signalSpikes,1);
		% % g = filtfilt(ones(1,5)/5,1,g);
		% % wts = repmat(1/30,29,1);
		% % g = conv(g,wts,'valid');
		% g = interp1(1:length(g),g,linspace(1,length(g),length(g)/30));
		% g2=1:length(g);
		% plot(g2, g(g2), 'r');
		% set(gca,'Color','none'); box off;
end
function [histCounts histBins] = getSyncCounts(signalSpikes,options)
	nSignals = size(signalSpikes,1);
	nFrames = size(signalSpikes,2);
	syncSpikes = sum(signalSpikes,1);
	syncSpikesPct = syncSpikes/nSignals;
	% figure(2123);plot(syncSpikesPct); hold off;
	syncFrames = find(syncSpikesPct>=options.syncThreshold);
	numSyncSpikesPerSignal = signalSpikes(:,syncFrames);
	% sum(numSyncSpikesPerSignal,2)
	numSyncSpikesPerSignal = sum(numSyncSpikesPerSignal,2)/length(syncFrames);
	% binMax = max(numSyncSpikesPerSignal);
	binMax = 0.1;
	histBins = 0:0.01:binMax;
	% histBins = 30;
	[histCounts histBins] = hist(numSyncSpikesPerSignal,histBins);
	histCounts = histCounts/sum(histCounts);
	% histCounts
	% histCountsKeep = find(~histCounts==0);
	% histCounts = histCounts(histCountsKeep);
	% histBins = histBins(histCountsKeep);
end