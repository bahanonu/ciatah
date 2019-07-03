function plotSignalsGraph(IcaTraces,varargin)
	% Plots signals, offsetting by a fixed amount.
	% Biafra Ahanonu
	% started: 2013.11.02
	% inputs
		%
	% outputs
		%
	% changelog
		% 2019.04.22 [19:14:47] - changed from plot to line so when exporting to illustrator don't need to merge lines
	% TODO
		% add options for how much to offset

	%========================
	% options.minAdd = 0.05;
	options.minAdd = 0;
	options.maxAdd = 1.1;
	options.inputXAxis = [];
	options.LineWidth = 1;
	options.smoothTrace = 0;
	options.incrementAmount = [];
	options.maxIncrementPercent = 0.5;
	options.newAxisColorOrder = 'gray';
	% list of traces to plot
	options.plotList = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	nSignals = size(IcaTraces,1);
	originalAxisColorOrder = get(groot,'defaultAxesColorOrder');
	switch options.newAxisColorOrder
		case 'gray'
			c1 = gray(nSignals*2);
			c1=c1(1:round(end/2),:);
		case 'red'
			c1 = customColormap({[1 0.5 0.5],[1 0 0]},'nPoints',nSignals*2);
			c1=c1(round(linspace(1,nSignals*2,nSignals)),:);
			% c1 = c1(randperm(size(c1,1)),:);
		case 'green'
			c1 = customColormap({[0.5 1 0.5]/1.5,[0 1 0]/2},'nPoints',nSignals*2);
			c1=c1(round(linspace(1,nSignals*2,nSignals)),:);
			% c1 = c1(randperm(size(c1,1)),:);
		case 'blue'
			c1 = customColormap({[0.5 0.5 1],[0 0 1]},'nPoints',nSignals*2);
			c1=c1(round(linspace(1,nSignals*2,nSignals)),:);
			% c1 = c1(randperm(size(c1,1)),:);
		otherwise
			c1 = [];
	end
	if ~isempty(c1)
		set(groot,'defaultAxesColorOrder',c1);
	end

	if isempty(options.plotList)
		tmpTrace = IcaTraces;
	else
		tmpTrace = IcaTraces(plotList,:);
	end

	rmList = sum(~isnan(tmpTrace),2)~=0;
	tmpTrace = tmpTrace(rmList,:);
	rmList = sum(tmpTrace,2)~=0;
	tmpTrace = tmpTrace(rmList,:);

	% for i=1:size(tmpTrace,1)
	%     tmpTrace(i,:)=normalizeVector(tmpTrace(i,:),);
	% end
	% tmpTrace2 = tmpTrace;
	incrementAmount = 0;
	incrementAmountAll = mean(nanmax(tmpTrace,[],2)*options.maxIncrementPercent);
	for i=2:size(tmpTrace,1)
		if isempty(options.incrementAmount)
			incrementAmount = nanmean(tmpTrace(i-1,:));
			if incrementAmount<options.minAdd
				incrementAmount = options.minAdd;
			end
		else
			incrementAmount = incrementAmount+options.incrementAmount;
		end
		tmpTrace(i,:)=tmpTrace(i,:)+incrementAmount+incrementAmountAll;
		if options.smoothTrace==1
			movAvgFiltSize = 3;
			tmpTrace(i,:) = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,tmpTrace(i,:));
		end
	end

	nXaxisPoints = size(tmpTrace,2);
	tmpTrace = flipdim(tmpTrace,1);
	% options.inputXAxis
	if isempty(options.inputXAxis)
		% plot(tmpTrace','LineWidth',options.LineWidth);
		plotXaxis = 1:nXaxisPoints;
	else
		display('================')
		display('custom x-axis')
		% plot(options.inputXAxis,tmpTrace','LineWidth',options.LineWidth);
		% line(options.inputXAxis,tmpTrace','LineWidth',options.LineWidth);
		plotXaxis = options.inputXAxis;
	end

	if isempty(c1)
		line(plotXaxis,tmpTrace','LineWidth',options.LineWidth);
	else
		for ii = 1:size(tmpTrace,1)
			line(plotXaxis,tmpTrace(ii,:),'LineWidth',options.LineWidth,'Color',c1(ii,:));
		end
	end

	axis([0 size(tmpTrace,2) min(tmpTrace(:))-options.minAdd options.maxAdd*max(tmpTrace(:))]);
	box off;

	set(groot,'defaultAxesColorOrder',originalAxisColorOrder);

	% for i=1:size(normalTrace,1)
	%     figure(42)
	%     subplot(2,1,1)
	%     plot(IcaTraces(i,:));
	%     subplot(2,1,2)
	%     plot(normalTrace(i,:));
	%     [x,y,reply]=ginput(1);
	% end

	% figure(6)
	% tmpTrace = normalTrace;
	% for i=2:size(tmpTrace,1)
	%     tmpTrace(i,:)=tmpTrace(i,:)+max(tmpTrace(i-1,:))+.1;
	% end
	% plot(tmpTrace([1:20],:)');

	% axis([0 nFrames -0.5 max(tmpTrace([1:20]))+1]);

	% setFigureDefaults();

	% check if two IC traces have correlation
	% l=corrcoef([bandpass' normal']);
	% l(l<0.8)=0;
	% imagesc(l(1:600,600:1400));
	% xlabel('pure DFOF cells');
	% ylabel('bandpass cells');
	% title('bandpass vs normal');

	% figure(42)
	% subplot(3,1,1)
	% plot(IcaTraces(ICtoCheck,:));
	% subplot(3,1,2)
	% plot(normalTrace);
	% subplot(3,1,3)
	% plot(thresholdedTrace);
end