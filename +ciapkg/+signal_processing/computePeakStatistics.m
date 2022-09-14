function [peakOutputStat] = computePeakStatistics(inputSignals,varargin)
	% [peakOutputStat] = computePeakStatistics(inputSignals,varargin)
	% 
	% Get slope ratio, the average trace from detected peaks, and other peak-related statistics.
	% 
	% Biafra Ahanonu
	% started: 2013.12.09
	% 
	% Inputs
	% 	inputSignals = [n m] matrix where n = {1....N} and m = frames.
	% 
	% Outputs
	% 	peakOutputStat - structure containing the following fields, where N = number of signals, P = # of peaks, W = peak window (frames):
	% 		fwhmSignal - Cell array {1 N} of [1 P] vectors: Full width at half maximum for each peak.
	% 		slopeRatio - Vector [1 N]: slope ratio (e.g. area of rise vs. decay) of peaks for each signal.
	% 		avgSpikeTrace - Vector [N W]: average peak for each signal.
	% 		avgSpikeVar - Vector [1 N]: average variance of the signal after the peak across all peaks.
	% 		avgSpikeCorr - Vector [1 N]: average correlation of all post-peak signals.
	% 		traceErr - Vector [1 N]: deviation in the error across all peaks within W window.
	% 		avgFwhm - Vector [1 N]: mean Full width at half maximum across all peaks for each signal.
	% 		fwhmSignalSignals - Cell array {1 N} of [1 P] vectors: Full width at half maximum for each peak.
	% 		avgPeakAmplitude - Vector [1 N]: mean peak amplitude across all peaks for each signal.
	% 		traceSkewness - Vector [1 N]: the skewness of each signal.
	% 		traceKurtosis - Vector [1 N]: the kurtosis of each signal.
	% 		traceFanoFactor - Vector [1 N]: the fano factor of each signal.
	% 		traceAutoCorr - Vector [1 N]: the auto-correlation of each signal defined at set frame shift (see options.frameShiftAmt).
	% 		spikeCenterTrace - Cell array {1 N} of [P W] vectors: matrix containing signal sliced around all peaks.
	% 		pwelchPxx - Cell array {1 N}: PSDs for each signal.
	% 		pwelchf - Cell array {1 N}: frequency corresponding to the output PSDs for each signal.

	% TODO
		% - Use the SNR signal calculated to determine when to end the S ratio calculation
	% changelog
		% 2013.12.24 - changed output so that it is a structure, allows more flexibility when adding new statistics.
		% 2019.09.10 [11:30:07] - Added fano factor, trace frame lagged auto-correlation, parallelization, and misc improvements.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.03.14 [01:31:51] - Update comments along with code standard improvements.
		% 2022.04.26 [00:12:03] - options.testpeaksArray can be used regardless of vector (with peak frames) orientation.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Char cell array: cell array of strings for different features to include in the output.
	options.featureList = {'avgSpikeTrace','spikeCenterTrace','avgSpikeVar','avgSpikeCorr','avgPeakAmplitude','slopeRatio','fwhmTrace'};
	% Binary: 1 = only detect and output the slope ratio. 0 = perform full analysis/output.
	options.onlySlopeRatio = 0;
	% Int vector: window (in frames) around each peak to perform the various peak statistics analyses.
	options.spikeROI = -40:40;
	% Int: number of frames before and after peak to use for certain statistics, e.g. slopeRatio.
	options.slopeFrameWindow = 10;
	% Binary: 1 = show the wait bar. 0 = do not show wait bar.
	options.waitbarOn = 1;
	% Binary: 1 = calculate power-spectral density.
	options.psd = 0;
	% Binary: 1 = plot fwhm analysis. 0 = do not plot analysis.
	options.fwhmPlot = 0;
	% Matrix: save time if already computed peaks. [nSignals frame] matrix. Binary matrix with 1 = peaks, 0 = non-peaks.
	options.testpeaks = [];
	% Cell array: save time if already computed peaks. {1 nSignals} cell array. Each cell contains [1 nPeaks] vector that stores the frame locations of each peak.
	options.testpeaksArray = [];
	% Binary: 1 = median filter the data.
	options.medianFilter = 1;
	% Int: number of frames to calculate rolling median filter.
	options.medianFilterLength = 200;
	% Int: the size of the moving average to use on the input signals, to smooth out noise.
	options.movAvgFiltSize = [];
	% Int: number of frames to shift when calculating auto-correlation.
	options.frameShiftAmt = 2;
	% get options
	options = getOptions(options,varargin);
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	disp('Median filtering before peak statistics')
	for signalNoNow = 1:size(inputSignals,1)
		inputSignal = inputSignals(signalNoNow,:);
		inputSignalMedian = medfilt1(inputSignal,options.medianFilterLength);
		inputSignal = inputSignal - inputSignalMedian;
		inputSignals(signalNoNow,:) = inputSignal;
		if ~isempty(options.movAvgFiltSize)
			inputSignals(signalNoNow,:) = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal);
		end
	end

	% get a list of all indices to pull out
	nSignals = size(inputSignals,1);
	% reverseStr = '';
	if isempty(options.testpeaks)
		[testpeaks, testpeaksArray] = computeSignalPeaks(inputSignals,'waitbarOn',options.waitbarOn,'makeSummaryPlots',0);
	else
		testpeaks = options.testpeaks;
		testpeaksArray = options.testpeaksArray;
	end

	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D = parallel.pool.DataQueue;
		afterEach(D, @nUpdateParforProgress);
		p = 0;
		N = nSignals;
		nInterval = round(N/30);%25
		options_waitbarOn = options.waitbarOn;
	end

	disp('Getting peak statistics: ')

	% optsConstant = parallel.pool.Constant(options);
	options_onlySlopeRatio = options.onlySlopeRatio;
	options_psd = options.psd;
	options_spikeROI = options.spikeROI;
	options_slopeFrameWindow = options.slopeFrameWindow;
	options_frameShiftAmt = options.frameShiftAmt;

	parfor i = 1:nSignals
		% optionsOutCopy = optsConstant.Value;
		thisSignal = inputSignals(i,:);
		[peakStat] = peakStats(testpeaksArray{i},thisSignal,options_spikeROI,options_slopeFrameWindow,options_onlySlopeRatio,options_psd);

		% peakStat
		if options_onlySlopeRatio==1
			slopeRatio(i) = peakStat.slopeRatio;
			continue;
		end

		slopeRatio(i) = peakStat.slopeRatio;
		avgSpikeTrace(i,:) = peakStat.avgSpikeTrace;
		avgSpikeVar(i) = peakStat.avgSpikeVar;
		avgSpikeCorr(i) = peakStat.avgSpikeCorr;
		traceErr(i) = peakStat.traceErr;
		fwhmSignal{i} = peakStat.fwhmTrace(:);
		avgFwhm(i) = mean(peakStat.fwhmTrace(:),'omitnan');
		fwhmSignalSignals{i} = peakStat.fwhmTrace(:);
		avgPeakAmplitude(i) = peakStat.avgPeakAmplitude;
		traceSkewness(i) = skewness(thisSignal(:));
		traceKurtosis(i) = kurtosis(thisSignal(:));
		traceFanoFactor(i) = (std(thisSignal(:),'omitnan')^2)/mean(thisSignal(:),'omitnan');
		traceAutoCorr(i) = corr(thisSignal(:),circshift(thisSignal(:),options_frameShiftAmt));
		spikeCenterTrace{i} = peakStat.spikeCenterTrace;
		if options_psd==1
			pwelchPxx{i} = peakStat.pwelchPxx;
			pwelchf{i} = peakStat.pwelchf;
		end

		if ~verLessThan('matlab', '9.2')
			send(D, i); % Update
		end

		% reduce waitbar access
		% reverseStr = cmdWaitbar(i,nSignals,reverseStr,'inputStr','getting statistics','waitbarOn',options.waitbarOn,'displayEvery',50);
	end

	if options.onlySlopeRatio==1
		peakOutputStat.slopeRatio = slopeRatio;
	else
		peakOutputStat.slopeRatio = single(slopeRatio);
		peakOutputStat.avgSpikeTrace = single(avgSpikeTrace);
		peakOutputStat.avgSpikeVar = single(avgSpikeVar);
		peakOutputStat.avgSpikeCorr = single(avgSpikeCorr);
		peakOutputStat.traceErr = single(traceErr);
		peakOutputStat.fwhmSignal = cat(1,fwhmSignal{:});
		peakOutputStat.avgFwhm = single(avgFwhm);
		peakOutputStat.fwhmSignalSignals = fwhmSignalSignals;
		peakOutputStat.avgPeakAmplitude = single(avgPeakAmplitude);
		peakOutputStat.traceSkewness = single(traceSkewness);
		peakOutputStat.traceKurtosis = single(traceKurtosis);
		peakOutputStat.traceFanoFactor = single(traceFanoFactor);
		peakOutputStat.traceAutoCorr = single(traceAutoCorr);
		peakOutputStat.spikeCenterTrace = spikeCenterTrace;
		if options.psd==1
			peakOutputStat.pwelchPxx = pwelchPxx;
			peakOutputStat.pwelchf = pwelchf;
		end
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
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (mod(p,nInterval)==0||p==1||p==nSignals)&&options_waitbarOn==1
				if p==nSignals
					fprintf('%d\n',round(p/nSignals*100))
				else
					fprintf('%d|',round(p/nSignals*100))
				end
				% cmdWaitbar(p,nSignals,'','inputStr','','waitbarOn',1);
			end
			% [p mod(p,nInterval)==0 (mod(p,nInterval)==0||p==nSignals)&&options_waitbarOn==1]
		end
	end
end

function [peakStat] = peakStats(testpeaks,inputSignal,spikeROI,slopeFrameWindow,onlySlopeRatio,options_psd)
	% finds peaks in the data then extracts information from them
	% [testpeaks dummyVar] = computeSignalPeaks(inputSignal);
	% if peaks exists, do statistics else return NaNs
	if ~isempty(testpeaks)
		% Force peaks to be correct dimensions.
		testpeaks = testpeaks(:);
		% get a list of indices around which to extract spike signals
		extractMatrix = bsxfun(@plus,testpeaks,spikeROI);
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
		if onlySlopeRatio==1
			return;
		end

		% size(spikeCenterTrace)
		% get the average trace around a peak
		if size(spikeCenterTrace,1)==1
			peakStat.avgSpikeTrace = spikeCenterTrace;
		else
			peakStat.avgSpikeTrace = mean(spikeCenterTrace,'omitnan');
		end

		% or get correlation
		% corrHere = corr(spikeCenterTrace',spikeCenterTrace','type','Pearson');
		% corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)','type','Pearson');

		% corrHere = corr(spikeCenterTrace',spikeCenterTrace','type','Spearman');
		corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)','type','Spearman');

		corrHere(logical(eye(size(corrHere)))) = NaN;
		peakStat.avgSpikeCorr = mean(corrHere(:),'omitnan');

		if 0
			% size(spikeCenterTrace)
			figure(4433)
			subplot(1,2,1)
				corrHere = corr(spikeCenterTrace',spikeCenterTrace');
				imagesc(corrHere)
				corrHere(logical(eye(size(corrHere)))) = NaN;
				title(num2str(mean(corrHere(:),'omitnan')))
			subplot(1,2,2)
				corrHere = corr(spikeCenterTrace(:,round(end/2):end)',spikeCenterTrace(:,round(end/2):end)');
				imagesc(corrHere)
				corrHere(logical(eye(size(corrHere)))) = NaN;
				title(num2str(mean(corrHere(:),'omitnan')))
				pause(0.01);
			% size(corr(spikeCenterTrace',spikeCenterTrace'))
		end

		% peakStat.avgSpikeVar = nanmean(squeeze(nanvar(spikeCenterTrace(:,round(end/2):end),[],1)));
		% Change to index of dispersion
		varH = var(spikeCenterTrace(:,round(end/2):end),[],1,'omitnan');
		meanH = mean(spikeCenterTrace(:,round(end/2):end),1,'omitnan');
		peakStat.avgSpikeVar = mean(squeeze(varH),'omitnan');
		peakStat.avgSpikeVMR = mean(squeeze(varH./meanH),'omitnan');

		% get the peak amplitude
		peakStat.avgPeakAmplitude = peakStat.avgSpikeTrace(find(spikeROI==0));
		% slopeRatio = (peakDfof-avgSpikeTrace(find(spikeROI==-slopeFrameWindow)))/(peakDfof-avgSpikeTrace(find(spikeROI==slopeFrameWindow)));

		% get the deviation in the error
		peakStat.traceErr = sum(std(spikeCenterTrace,'omitnan'))/sqrt(size(spikeCenterTrace,1));

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

		if options_psd==1
			% get the power-spectrum
			[peakStat.pwelchPxx, peakStat.pwelchf] = pwelch(inputSignal,100,25,512,5);
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
		if options_psd==1
			peakStat.pwelchPxx = NaN;
			peakStat.pwelchf = NaN;
		end
	end
end
% function plotStatistics()
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
% end
% function localfxn_createOutput()

	% peakOutputStat.fwhmSignal = [];
	% peakOutputStat.slopeRatio = [];
	% peakOutputStat.avgSpikeTrace = [];
	% peakOutputStat.avgSpikeVar = [];
	% peakOutputStat.avgSpikeCorr = [];
	% peakOutputStat.traceErr = [];
	% peakOutputStat.fwhmSignal = [];
	% peakOutputStat.avgFwhm = [];
	% peakOutputStat.fwhmSignalSignals = [];
	% peakOutputStat.avgPeakAmplitude = [];
	% peakOutputStat.traceSkewness = [];
	% peakOutputStat.traceKurtosis = [];
	% peakOutputStat.traceFanoFactor = [];
	% peakOutputStat.traceAutoCorr = [];
	% peakOutputStat.spikeCenterTrace = [];
	% peakOutputStat.pwelchPxx = [];
	% peakOutputStat.pwelchf = [];
% end