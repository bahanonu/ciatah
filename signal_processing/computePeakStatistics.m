function [peakOutputStat] = computePeakStatistics(inputSignals,varargin)
	% Get slope ratio, the average trace from detected peaks, and other peak-related statistics
	% Biafra Ahanonu
	% started: 2013.12.09
	% inputs
		% inputSignals = [n m] matrix where n={1....N}
	% outputs
		% slopeRatio
		% traceErr
		% fwhmSignal
		% avgPeakAmplitude
		% spikeCenterTrace
		% pwelchPxx
		% pwelchf
	% changelog
		% 2013.12.24 - changed output so that it is a structure, allows more flexibility when adding new statistics.

	%========================
	%
	options.featureList = {'avgSpikeTrace','spikeCenterTrace','avgSpikeVar','avgSpikeCorr','avgPeakAmplitude','slopeRatio','fwhmTrace'};
	options.onlySlopeRatio = 0;
	%
	options.spikeROI = [-40:40];
	%
	options.slopeFrameWindow = 10;
	%
	options.waitbarOn = 1;
	% determine whether power-spectral density should be calculated
	options.psd = 0;
	% should fwhm analysis be plotted?
	options.fwhmPlot = 0;
	% save time if already computed peaks
	options.testpeaks = [];
	options.testpeaksArray = [];
	% Median filter the data
	options.medianFilter = 1;
	% number of frames to calculate median filter
	options.medianFilterLength = 200;
	options.movAvgFiltSize = [];
	% get options
	options = getOptions(options,varargin);
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	display('Median filtering before peak statistics')
	for signalNoNow = 1:size(inputSignals,1)
	    inputSignal = inputSignals(signalNoNow,:);
	    inputSignalMedian = medfilt1(inputSignal,options.medianFilterLength);
	    inputSignal = inputSignal - inputSignalMedian;
	    inputSignals(signalNoNow,:) = inputSignal;
	    if ~isempty(options.movAvgFiltSize)
	        inputSignals(signalNoNow,:) = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal);
	    end
	end


	peakOutputStat.fwhmSignal = [];
	% get a list of all indices to pull out
	nSignals = size(inputSignals,1);
	reverseStr = '';
	if isempty(options.testpeaks)
		[testpeaks testpeaksArray] = computeSignalPeaks(inputSignals,'waitbarOn',options.waitbarOn,'makeSummaryPlots',0);
	else
		testpeaks = options.testpeaks;
		testpeaksArray = options.testpeaksArray;
	end
	for i=1:nSignals
		thisSignal = inputSignals(i,:);
		[peakStat] = peakStats(testpeaksArray{i},thisSignal,spikeROI,slopeFrameWindow,options);

		% peakStat
		peakOutputStat.slopeRatio(i) = peakStat.slopeRatio;
		if options.onlySlopeRatio==1
			continue;
		end
		peakOutputStat.avgSpikeTrace(i,:) = peakStat.avgSpikeTrace;
		peakOutputStat.avgSpikeVar(i) = peakStat.avgSpikeVar;
		peakOutputStat.avgSpikeCorr(i) = peakStat.avgSpikeCorr;
		peakOutputStat.traceErr(i) = peakStat.traceErr;
		peakOutputStat.fwhmSignal = [peakOutputStat.fwhmSignal; peakStat.fwhmTrace(:)];
		peakOutputStat.avgFwhm(i) = nanmean(peakStat.fwhmTrace(:));
        peakOutputStat.fwhmSignalSignals{i} = peakStat.fwhmTrace(:);
		peakOutputStat.avgPeakAmplitude(i) = peakStat.avgPeakAmplitude;
		peakOutputStat.traceSkewness(i) = skewness(thisSignal(:));
		peakOutputStat.traceKurtosis(i) = kurtosis(thisSignal(:));
		peakOutputStat.spikeCenterTrace{i} = peakStat.spikeCenterTrace;
		if options.psd==1
			peakOutputStat.pwelchPxx{i} = peakStat.pwelchPxx;
			peakOutputStat.pwelchf{i} = peakStat.pwelchf;
		end

		% reduce waitbar access
		reverseStr = cmdWaitbar(i,nSignals,reverseStr,'inputStr','getting statistics','waitbarOn',options.waitbarOn,'displayEvery',50);
    end

    if options.fwhmPlot~=0
	    fwhmMax = max(peakOutputStat.fwhmSignal);
	    figCount = 1;
	    plotCount = 1;
	    sheight = 10;
	    swidth = 10;
	    for i=1:nSignals
	        figure(143+figCount)
	        subplot(sheight,swidth,plotCount);
	            hist(peakOutputStat.fwhmSignalSignals{i},[0:fwhmMax]);
	                % box off;
	            h = findobj(gca,'Type','patch');
	            set(h,'FaceColor',[0 0 0],'EdgeColor',[0 0 0])
	            set(gca,'xlim',[0 fwhmMax],'ylim',[0 20]);
	            if plotCount~=1
	                set(gca,'XTickLabel','','YTickLabel','');
	            end
	        plotCount = plotCount+1;
	        if (mod(i,sheight*swidth)==0)
	           figCount = figCount+1;
	           plotCount = 1;
	        end
	    end
	end

function [peakStat] = peakStats(testpeaks,inputSignal,spikeROI,slopeFrameWindow,options)
	% finds peaks in the data then extracts information from them
	% [testpeaks dummyVar] = computeSignalPeaks(inputSignal);
	% if peaks exists, do statistics else return NaNs
	if ~isempty(testpeaks)
		% get a list of indices around which to extract spike signals
		extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
		extractMatrix(extractMatrix<=0)=1;
		extractMatrix(extractMatrix>=size(inputSignal,2))=size(inputSignal,2);
		peakStat.spikeCenterTrace = reshape(inputSignal(extractMatrix),size(extractMatrix));
		spikeCenterTrace = peakStat.spikeCenterTrace;

		% get a ratio metric (normalized between 1 and -1) for the asymmetry in the peaks
		prePeakIdx = find(spikeROI==-(slopeFrameWindow)):find(spikeROI==-1);
		postPeaklIdx = find(spikeROI==1):find(spikeROI==slopeFrameWindow);
		areaPrePeak = abs(mean(mean(spikeCenterTrace(:,prePeakIdx),2)));
		areaPostPeak = abs(mean(mean(spikeCenterTrace(:,postPeaklIdx),2)));
		peakStat.slopeRatio = (areaPostPeak-areaPrePeak)/(areaPostPeak+areaPrePeak);
		if options.onlySlopeRatio==1
			return;
		end

		% size(spikeCenterTrace)
		% get the average trace around a peak
		if size(spikeCenterTrace,1)==1
			peakStat.avgSpikeTrace = spikeCenterTrace;
		else
			peakStat.avgSpikeTrace = nanmean(spikeCenterTrace);
		end

		% or get correlation
		% corrHere = corr(spikeCenterTrace',spikeCenterTrace','type','Pearson');
		% corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)','type','Pearson');

		% corrHere = corr(spikeCenterTrace',spikeCenterTrace','type','Spearman');
		corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)','type','Spearman');

		corrHere(logical(eye(size(corrHere)))) = NaN;
		peakStat.avgSpikeCorr = nanmean(corrHere(:));

		if 0
			% size(spikeCenterTrace)
			figure(4433)
			subplot(1,2,1)
				corrHere = corr(spikeCenterTrace',spikeCenterTrace');
				imagesc(corrHere)
				corrHere(logical(eye(size(corrHere)))) = NaN;
				title(num2str(nanmean(corrHere(:))))
			subplot(1,2,2)
				corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)');
				imagesc(corrHere)
				corrHere(logical(eye(size(corrHere)))) = NaN;
				title(num2str(nanmean(corrHere(:))))
				pause(0.01);
			% size(corr(spikeCenterTrace',spikeCenterTrace'))
		end


		peakStat.avgSpikeVar = nanmean(squeeze(nanvar(spikeCenterTrace(:,round(end/2):end),[],1)));

		% get the peak amplitude
		peakStat.avgPeakAmplitude = peakStat.avgSpikeTrace(find(spikeROI==0));
		% slopeRatio = (peakDfof-avgSpikeTrace(find(spikeROI==-slopeFrameWindow)))/(peakDfof-avgSpikeTrace(find(spikeROI==slopeFrameWindow)));

		% get the deviation in the error
		peakStat.traceErr = sum(nanstd(spikeCenterTrace))/sqrt(size(spikeCenterTrace,1));

		% % get a ratio metric (normalized between 1 and -1) for the asymmetry in the peaks
		% prePeakIdx = find(spikeROI==-(slopeFrameWindow)):find(spikeROI==-1);
		% postPeaklIdx = find(spikeROI==1):find(spikeROI==slopeFrameWindow);
		% areaPrePeak = abs(mean(peakStat.avgSpikeTrace(prePeakIdx)));
		% areaPostPeak = abs(mean(peakStat.avgSpikeTrace(postPeaklIdx)));
		% areaPrePeak = abs(mean(sum(spikeCenterTrace(:,prePeakIdx),2)));
		% areaPostPeak = abs(mean(sum(spikeCenterTrace(:,postPeaklIdx),2)));
		% if options.onlySlopeRatio==1
		% areaPrePeak = abs(mean(mean(spikeCenterTrace(:,prePeakIdx),2)));
		% areaPostPeak = abs(mean(mean(spikeCenterTrace(:,postPeaklIdx),2)));
		% peakStat.slopeRatio = (areaPostPeak-areaPrePeak)/(areaPostPeak+areaPrePeak);
		% peakStat.avgSpikeTrace
		% peakStat.avgSpikeTrace(find(spikeROI==-(slopeFrameWindow)):find(spikeROI==-1))
		% peakStat.avgSpikeTrace(find(spikeROI==0):find(spikeROI==slopeFrameWindow))

		% plot(spikeCenterTrace');hold on;plot(peakStat.avgSpikeTrace,'k','LineWidth',3);
		% title([num2str(peakStat.slopeRatio) ' ' num2str(areaPostPeak) ' ' num2str(areaPrePeak)])
		% pause;clf

		% for graphing purposes, remove super large asymmetries
		% peakStat.slopeRatio(find(peakStat.slopeRatio>5))=NaN;
		% avgSpikeTraceCut = avgSpikeTrace(find(spikeROI==-slopeFrameWindow):find(spikeROI==slopeFrameWindow));
		% slopeRatio = skewness(avgSpikeTraceCut./max(avgSpikeTraceCut));

		% get fwhm for all peaks
		for i=1:size(spikeCenterTrace,1)
			peakStat.fwhmTrace(i) = fwhm(spikeROI,spikeCenterTrace(i,:));
        end

		if options.psd==1
			% get the power-spectrum
			[peakStat.pwelchPxx peakStat.pwelchf] = pwelch(inputSignal,100,25,512,5);
		end
	else
		peakStat.avgSpikeTrace = nan(1,length(spikeROI));
		peakStat.spikeCenterTrace = nan(1,length(spikeROI));
		peakStat.avgSpikeVar = NaN;
		peakStat.avgSpikeCorr = NaN;
		peakStat.avgPeakAmplitude = NaN;
		peakStat.slopeRatio = NaN;
		peakStat.fwhmTrace = NaN;
		peakStat.traceErr = NaN;
		if options.psd==1
			peakStat.pwelchPxx = NaN;
			peakStat.pwelchf = NaN;
		end
	end

function plotStatistics()
	% figure(92929)
	% hist(fwhmSignal,[0:nanmax(fwhmSignal)]); box off;
	% xlabel('FWHM (frames)'); ylabel('count');
	% title('full-width half-maximum for detected spikes');
	% h = findobj(gca,'Type','patch');
	% set(h,'FaceColor',[0 0 0],'EdgeColor','w')

% OLD CODE! IGNORE!
	% spikeROI = [-40:40];
	% extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
	% extractMatrix(extractMatrix<=0)=1;
	% extractMatrix(extractMatrix>=size(IcaTraces,2))=size(IcaTraces,2);
	% % extractMatrix
	% spikeCenterTrace = reshape(IcaTraces(i,extractMatrix),size(extractMatrix));
	% avgSpikeTrace = nanmean(spikeCenterTrace);
	% traceErr = nanstd(spikeCenterTrace)/sqrt(size(spikeCenterTrace,1));
	%
	% errorbar(spikeROI, avgSpikeTrace, traceErr);
	% t=1:length(traceErr);
	% fill([spikeROI fliplr(spikeROI)],[avgSpikeTrace+traceErr fliplr(avgSpikeTrace-traceErr)],[4 4 4]/8, 'FaceAlpha', 0.4, 'EdgeColor','none')