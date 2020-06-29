function [signalPeaks, signalPeaksArray, signalSigmas] = computeSignalPeaks(signalMatrix, varargin)
	% Binarize [0,1] input analog signals based on peaks in the signal.
	% Biafra Ahanonu
	% started: 2013.10.28
	% inputs
	  % signalMatrix: [nSignals frame] matrix
	% outputs
		% signalPeaks: [nSignals frame] matrix. Binary matrix with 1 = peaks.
		% signalPeaksArray: {1 nSignals} cell array. Each cell contains [1 nPeaks] vector that stores the frame locations of each peak.
	% options
		% See below.
		% % make a plot?
		% options.makePlots = 0;
		% % show waitbar?
		% options.waitbarOn = 1;
		% % make summary plots of spike information
		% options.makeSummaryPlots = 0;
		% % number of standard deviations above the threshold to count as spike
		% options.numStdsForThresh = 3;
		% % minimum number of time units between events
		% options.minTimeBtEvents = 8;
		% % shift peak detection
		% options.nFramesShift = 0;
		% % should diff and fast oopsi be done?
		% options.addedAnalysis = 0;
		% % use simulated oopsi data
		% options.oopsiSimulated = 0;
	% changelog
		% 2015.10.06 [00:14:09] Changed computePeakForSignal to shift the signal to the actual nearby peak since findpeak is sometimes off by a frame or two, should also improve the S-ratio.
		% 2016.07.05 [14:52:43] Made changes to computePeakForSignal to improve diff based peak detection.
	% TODO:
		% allow input of options file (e.g. for different GCaMP variants, brain regions, etc.)
		% integrate nearest neighbor into analysis if there is a lot of cross-talk
		% possibly integrate into identifySpikes?
		% TODO: convert main loop to parfor, convert signalMatrix to cell array to allow this. Normally fast enough that this won't provide a speed-up.

	% add controller directory and subdirectories to path
	% addpath(genpath(pwd));
	%========================
	% Binary: 1 = show plots with found events and other information for each signal. 0 = do not show signal plot GUI.
	options.makePlots = 0;
	% show waitbar?
	options.waitbarOn = 1;
	% make summary plots of spike information
	options.makeSummaryPlots = 0;
	% ===
	% number of standard deviations above the threshold to count as spike
	% options.numStdsForThresh = 3;
	% options.numStdsForThresh = 0.5;
	options.numStdsForThresh = 3;
	% alternative for display purposes
	options.numStdsForThreshTwo = 2;
	% minimum number of time units between events
	options.minTimeBtEvents = 8;
	% detect on differential ('diff') or raw ('raw') trace
	% options.detectMethod = 'raw';
	options.detectMethod = 'diff';
	% the size of the moving average
	options.movAvgReqSize = 2;
	options.movAvgFiltSize = 3;
	% decide whether to have a moving average
	options.doMovAvg = 1;
	% subtract median calculated over a filter of some range.
	options.doMedianFilter = 1;
	% number of frames to calculate median filter
	options.medianFilterLength = 201;
	% report the midpoint of the rise
	options.reportMidpoint=0;
	% shift peak detection
	options.nFramesShift = 0;
	% region around each peak to look for a maximum to adjust the test peak by
	options.peakMaxLook = -6:6;
	% ===
	% should diff and fast oopsi be done?
	options.addedAnalysis = 0;
	% use simulated oopsi data
	options.oopsiSimulated = 0;
	% decide whether to have a moving average
	% options.doMovAvg = 0;
	% 1 = open workers, 0 = do not open workers
	options.parallel = 1;
	% display output
	options.outputInfo = 1;
	% Binary: 1 = convert input inputSignals matrix to cell array
	options.convertSignalsToCell = 1;
	% get user inputs
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	try
		% make sure matrix is double
		% if ~strcmp(class(signalMatrix),'double')
		if ~isa(signalMatrix,'double')
			if options.outputInfo==1
				disp('converting signalMatrix to double');
			end
			signalMatrix = double(signalMatrix);
		end
		if options.outputInfo==1
			disp('calculating signal peaks...')
		end
		nSignals = size(signalMatrix,1);
		nFrames = size(signalMatrix,2);

		% Remove any NaN signals, set to the mean
		if sum(isnan(signalMatrix(:)))>0
			if options.outputInfo==1
				disp('Removing NaNs from matrix');
			end
			for signalNo = 1:nSignals
				repIdx = isnan(signalMatrix(signalNo,:));
				signalMatrix(signalNo,repIdx) = nanmean(signalMatrix(signalNo,:));
			end
		end

		% this matrix will contain binarized version of signalMatrix
		signalPeaks = zeros(size(signalMatrix));
		% contains a list for each signal of locations of peaks
		signalPeaksArray = cell([1 nSignals]);
		% open waitbar
		% if options.waitbarOn==1 waitbarHandle = waitbar(0, 'detecting traces...'); end
		% loop over all signals.
		% reverseStr = '';
		manageParallelWorkers('parallel',options.parallel);
		signalPeaksArrayTmp = cell([1 nSignals]);
		signalSigmas = repmat([],[1 nSignals]);
		% try;[percent progress] = parfor_progress(nSignals);catch;end; dispStepSize = round(nSignals/20); dispstat('','init');

		% Convert to cell array to reduce memory transfer during parallelization
		if options.convertSignalsToCell==1
			% signalMatrix = squeeze(mat2cell(signalMatrix,ones(1,size(signalMatrix,1)),size(signalMatrix,2)));
		end

		[optionsOut] = computePeakForSignalOptions('options', options);

		% Only implement in Matlab 2017a and above
		if ~verLessThan('matlab', '9.2')
			D = parallel.pool.DataQueue;
			afterEach(D, @nUpdateParforProgress);
			p = 1;
			N = nSignals;
			nInterval = round(nSignals/30);%25
			options_waitbarOn = options.waitbarOn;
		end

		% signalIdxAll = {};
		% if options.convertSignalsToCell==1
		%     parfor signalNum3 = 1:nSignals
		%         signalIdxAll{signalNum3} = signalNum3;
		%     end
		% else
		%     parfor signalNum3 = 1:nSignals
		%         signalIdxAll{signalNum3} = sub2ind(size(signalMatrix), repmat(signalNum3,[nFrames 1]), [1:nFrames]');
		%     end
		% end

		% startState = ticBytes(gcp);
		if isempty(gcp)
			optsConstant.Value = optionsOut;
		else
			optsConstant = parallel.pool.Constant(optionsOut);
		end
		optionsCopy_addedAnalysis = options.addedAnalysis;
		optionsCopy_convertSignalsToCell = options.convertSignalsToCell;
		parfor signalNum = 1:nSignals
			optionsOutCopy = optsConstant.Value;
			% [percent progress] = parfor_progress;if mod(progress,dispStepSize) == 0;dispstat(sprintf('progress %0.1f %',percent));else;end
			% get the current signal and find its peaks
			% if options.convertSignalsToCell==1
			%     thisSignal = signalMatrix{signalNum2};
			%     signalNum = signalNum2;
			%     signalNum3 = signalNum2;
			%     signalSigmas(signalNum2) = std(thisSignal);
			%     signalPeaksArray{signalNum2} = computePeakForSignal(thisSignal,optionsOutCopy);
			% else
			%     signalNum = find(cellfun(@(x) sum(signalNum2==x),signalIdxAll));
			%     % signalIdx = sub2ind(size(signalMatrix), repmat(signalNum,[nFrames 1]), [1:nFrames]');
			%     % signalIdx = signalIdxAll{signalNum};
			%     thisSignal = signalMatrix(signalNum2);
			%     signalSigmas(signalNum) = std(thisSignal);
			%     signalPeaksArray{signalNum} = computePeakForSignal(thisSignal,optionsOutCopy);
			% end

			thisSignal = signalMatrix(signalNum,:);

			% if iscell(signalMatrix)==1
			%     thisSignal = signalMatrix{signalNum};
			% else
			%     thisSignal = signalMatrix(signalNum,:);
			%     % signalSigmas(signalNum) = std(thisSignal);
			%     % signalPeaksArray{signalNum} = computePeakForSignal(thisSignal,optionsOutCopy);
			% end

			%
			signalSigmas(signalNum) = std(thisSignal);
			signalPeaksArray{signalNum} = computePeakForSignal(thisSignal,optionsOutCopy);

			% [~] = viewComputePeaksPlot(thisSignal,signalPeaksArray{signalNum},[0 0 0],options.makePlots,50,2,'on')
			% ===
			if optionsCopy_addedAnalysis==1
				% using diff
				detectOld = optionsOutCopy.detectMethod;
				optionsOutCopy.detectMethod = 'diff';
				optionsOutCopy.detectMethod = detectOld;

				signalPeaksArrayTmp{signalNum} = computePeakForSignal(thisSignal,optionsOutCopy);
				% plot the resulting peaks overlayed
				[~] = viewComputePeaksPlot(thisSignal,signalPeaksArrayTmp{signalNum},[0 0 1],options.makePlots,20,0.1,'off',options)
				legend('signal','raw','signal','diff')
				title(['raw: ' num2str(length(signalPeaksArray{signalNum})) ' | diff: ' num2str(length(signalPeaksArrayTmp{signalNum}))]);
				[~,~,~]=ginput(1);
				% fast oopsi
				[Nhat] = computePeakForSignalOopsi(thisSignal,signalPeaksArray{signalNum},options);
				[~,~,~]=ginput(1);
				% if options.convertSignalsToCell==1
				% else
				% end
				% ===
			end
			% create matrix of peaks
			% signalPeaks(signalNum,signalPeaksArray{signalNum})=1;

			% waitbar access
			% reverseStr = cmdWaitbar(signalNum,nSignals,reverseStr,'inputStr','detecting peaks','waitbarOn',options.waitbarOn,'displayEvery',50);

			if ~verLessThan('matlab', '9.2')
				% Update
				send(D, signalNum);
			end
		end
		% tocBytes(gcp,startState)
		if options.makePlots==1
			for signalNum=1:nSignals
				if options.convertSignalsToCell==1
					% thisSignal = signalMatrix{signalNum};
					thisSignal = signalMatrix(signalNum,:);
				else
					thisSignal = signalMatrix(signalNum,:);
				end
					[~] = viewComputePeaksPlot(thisSignal,signalPeaksArray{signalNum},[0 0 0],options.makePlots,50,2,'on',options,signalNum,nSignals,options.numStdsForThresh);
					pause
					keyIn = get(gcf,'CurrentCharacter');
					if strcmp(keyIn,'e')
						return
					end
				% pause
				% clf
			end
		end
		for signalNum=1:nSignals
			% create matrix of peaks
			signalPeaks(signalNum,signalPeaksArray{signalNum})=1;
		end
	catch err
		signalPeaks = [];
		signalPeaksArray = {};
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	% summary of general statistics for this set of IC data
	try
		if options.makeSummaryPlots==1
			viewSpikeSummary(signalMatrix,signalPeaks);
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (mod(p,nInterval)==0||p==2||p==nSignals)&&options_waitbarOn==1
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
function [inputSignal] = viewComputePeaksPlot(inputSignal,testpeaks,dotColor,makePlots,markersize,linewidth,holdVal,options,signalNum,nSignals,numStdsForThresh)
	% decide whether to plot the peaks with points indicating location of
	% chosen peaks
	if makePlots==1
		% setFigureDefaults()
		fig1 = figure(422); clf;
		subplot(4,3,1)
			% hist(inputSignal(testpeaks),20);
			hist((inputSignal(testpeaks) - nanmean(inputSignal(:)))/nanstd(inputSignal(:)),20);
			hold(holdVal);
			title(num2str(nanstd(inputSignal(:))))
			xlabel('Peak amplitude (Z-score)');ylabel('Peak count')
			set(gca,'XMinorTick','on','TickDir','out');box off;
			% plot(histBins,histCounts);
			% set(gca,'yscale','log');

		subplot(4,3,2)
			peakROI = [-20:20];
			extractMatrix = bsxfun(@plus,testpeaks',peakROI);
			extractMatrix(extractMatrix<=0)=1;
			extractMatrix(extractMatrix>=size(inputSignal,2))=size(inputSignal,2);
			spikeCenterTrace = reshape(inputSignal(extractMatrix),size(extractMatrix));
			plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
			set(gca,'TickDir','out');box off;
			xlabel('Time (frames)');ylabel('Signal amplitude')
			title('All peaks')

		subplot(4,3,3)
			peakSignalAmplitude = inputSignal(testpeaks(:));
			[peakSignalAmplitude, peakIdx] = sort(spikeCenterTrace(:,round(end/2)+1),'descend');
			spikeCenterTrace = spikeCenterTrace(peakIdx,:);
			if size(spikeCenterTrace,1)>20
				spikeCenterTrace = spikeCenterTrace(1:20,:);
			end
			% xlabel('Time (frames)')
			plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
			xlabel('Time (frames)');ylabel('Signal amplitude')
			title('Top 20 peaks')
			set(gca,'TickDir','out');box off;

		subplot(4,3,[4:12])
			set(gcf,'color','w');
			% scnsize = get(0,'ScreenSize');
			% position = get(fig1,'Position');
			% outerpos = get(fig1,'OuterPosition');
			% borders = outerpos - position;
			% edge = -borders(1)/2;
			% %pos1 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)];
			% pos1 = [0, 0, scnsize(3), scnsize(4)];
			% set(fig1,'OuterPosition',pos1);

			plot(inputSignal, 'r');

			inputSignalMedian=medfilt1(inputSignal,options.medianFilterLength,'omitnan','truncate');
			inputSignal = inputSignal - inputSignalMedian;
			inputSignal = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal);
			hold on;
			plot(inputSignal, 'b');

			set(gca,'Color','none'); box off;
			set(gca,'TickDir','out');box off;
			hold on;
			% axis([0 length(inputSignal) -0.1 0.5]);
			scatter(testpeaks, inputSignal(testpeaks),markersize, 'LineWidth',linewidth,'MarkerFaceColor',dotColor, 'MarkerEdgeColor',dotColor)
			legend({'Raw signal','Raw signal minus rolling median filter'},'Location','northoutside')
			axis tight;
			xlabel('Time (frames)');ylabel('Signal amplitude')
			% options.numStdsForThresh = options.numStdsForThreshTwo;
			% signalPeaksArray{signalNum} = computePeakForSignal(thisSignal, 'options', options);

			% [x,y,reply]=ginput(1);
			% close(fig1);
			hold(holdVal);
			title(sprintf('%d peaks | Zoom is enabled for closer look at peaks',length(testpeaks)))
		zoom on
		suptitle(sprintf('Right arrow key to move to next signal | press ''e'' to exit | threshold = %0.2f | signal %d/%d',numStdsForThresh,signalNum,nSignals))
	end
end
function [Nhat] = computePeakForSignalOopsi(inputSignal,testpeaks, options, varargin)
	% clear, clc,

	switch options.oopsiSimulated
		case 1
			% set simulation metadata
			T       = 1000; % # of time steps
			V.dt    = 1/8;  % time step size

			% initialize params
			P.a     = 1;    % observation scale
			P.b     = 0;    % observation bias
			tau     = 1.5;    % decay time constant
			P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
			P.lam   = 0.1;  % firing rate = lam*dt
			P.sig   = 0.1;  % standard deviation of observation noise

			% simulate data
			N = poissrnd(P.lam*V.dt*ones(T,1)); % simulate spike train
			N(100) = 10;
			P.sig   = std(N);  % standard deviation of observation noise
		case 0
			% our data
			% inputSignal = inputSignal(1:1000);
			% testpeaks = testpeaks(testpeaks<1000);
			T = length(inputSignal);
			V.dt    = 1/5;  % time step size
			P.k = 30;
			%
			P.a     = 1;    % observation scale
			P.b     = 0;    % observation bias
			tau     = 1.5;    % decay time constant
			P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
			P.lam   = 0.01;  % firing rate = lam*dt

			inputSignalMetric = nanmean(inputSignal(testpeaks));
			% inputSignalMetric = nanmax(inputSignal(testpeaks));
			N = inputSignal(:)/inputSignalMetric;
			% inputSignal = normalizeVector(inputSignal,'normRange','zeroToOne');
			% N = inputSignal(:);
			P.sig = std(inputSignal(:)); % standard deviation of observation noise
			P.sig
			F = N;
			% N = zeros([length(inputSignal) 1]);
			% N(testpeaks) = 1;
			% normalizeVector(inputSignal(:),'normRange','zero')

		otherwise
			% body
	end
	P.sig = 0.1; % standard deviation of observation noise
	C = filter(1,[1 -P.gam],N);         % calcium concentration
	F = P.a*C+P.b + P.sig*randn(T,1);   % observations
	% fast oopsi
	[Nhat Phat] = fast_oopsi(F,V,P);

	% smc-oopsi
	V.smc_iter_max = 1;
	% [M P V] = smc_oopsi(F,V,P);

	%% plot results
	figure(1), clf
	tvec=0:V.dt:(T-1)*V.dt;
	tvec = 1:T;
	h(1)=subplot(411); plot(tvec,F); axis('tight'), ylabel('F (au)')
	h(2)=subplot(412); plot(tvec,C); axis('tight'), ylabel('C (au)')
	switch options.oopsiSimulated
		case 1
			h(3)=subplot(4,1,[3 4]); stem(tvec,N,'.'); hold on, plot(tvec,Nhat,'r','linewidth',1), axis('tight'), ylabel('fast')
		case 0
			h(3)=subplot(4,1,3); stem(tvec,N,'.'); hold on, plot(tvec,Nhat,'r','linewidth',1), axis('tight'), ylabel('fast')
			h(4)=subplot(414);plot(tvec,inputSignal, 'r'); box off; hold on;
			scatter(testpeaks, inputSignal(testpeaks),50, 'LineWidth',2,'MarkerFaceColor',[0 0 1], 'MarkerEdgeColor',[0 0 1]); axis('tight')
		otherwise
	end
	% Nsmc = M.nbar/max(M.nbar);
	% Nsmc(Nsmc<0.1)=0;
	% h(4)=subplot(414); stem(tvec,N); hold on, plot(tvec,Nsmc,'k','linewidth',2); axis('tight'), ylabel('smc')
	% xlabel('time (sec)')
	linkaxes(h,'x')
end
function [optionsOut] = computePeakForSignalOptions(varargin)
	%========================
	% number of standard deviations above the threshold to count as spike
	options.numStdsForThresh = 3;
	% minimum number of time units between events
	options.minTimeBtEvents = 10;
	% make a plot?
	options.makePlots = 0;
	% the size of the moving average
	options.movAvgReqSize = 2;
	options.movAvgFiltSize = 3;
	% subtract median calculated over a filter of some range.
	options.doMedianFilter = 1;
	% number of frames to calculate median filter
	options.medianFilterLength = 201;
	% decide whether to have a moving average
	options.doMovAvg = 1;
	% report the midpoint of the rise
	options.reportMidpoint=0;
	% shift peak detection
	options.nFramesShift = 0;
	% detect on differential ('diff') or raw ('raw') trace
	options.detectMethod = 'raw';
	% region around each peak to look for a maximum to adjust the test peak by
	options.peakMaxLook = [-6:6];
	% get options
	optionsOut = getOptions(options,varargin,'showWarnings',0);
end
function [testpeaks] = computePeakForSignal(inputSignal, options)
	% identifies peaks in an input signal given a particular threshold and other parameters.
	% biafra ahanonu
	% started: 2013.10.28
	% adapted from Lacey Kitch's and Laurie Burns' code
	% inputs
		%
	% outputs
		%
	% changelog
		% 2013.11.18 [20:06:00]
	% TODO
		%

	%========================
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end;
	%========================

	% histBins = logspace(1,max(inputSignal));
	% [histCounts histBins] = hist(inputSignal(:),100);
	% plot(histBins,histCounts);
	% set(gca,'yscale','log');

	% median filter subtract
	if doMedianFilter==1
		inputSignalMedian=medfilt1(inputSignal,options.medianFilterLength,'omitnan','truncate');
		inputSignal = inputSignal - inputSignalMedian;
	end
	% moving average of input signal
	if doMovAvg==1
		% class(movAvgFiltSize)
		% movAvgFiltSize
		% class(inputSignal)
		% inputSignal(1:10)
		inputSignal = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,inputSignal);
	end

	switch options.detectMethod
		case 'diff'
			rawInputSignalStd = std(inputSignal(:));
			rawInputSignal = inputSignal;
			% get the differential
			inputSignal = [0 diff(inputSignal)];
			inputSignal(inputSignal<0) = 0;
			% options.nFramesShift = 0;
		case 'raw'
			%
		otherwise
			% body
	end

	% get standard deviation of current signal
	% inputSignalStd = std(inputSignal(:));
	inputSignalStd = nanstd(inputSignal(:));
	thisStdThreshold = inputSignalStd*numStdsForThresh;

	% =======
	% peakIdx = bsxfun(@plus,options.timeSeq',testpeaks);
	% tmpTestPeak = testpeaks;
	% % remove peaks outside range of signal
	% peakIdx(peakIdx>length(loopSignal))=[];
	% peakIdx(peakIdx<=0)=[];

	% % remove signal then add back in noise based on signal statistics
	% noiseSignal = loopSignal;
	% noiseSignal(peakIdx) = NaN;
	% =======

	% run findpeaks (part of signal), returns maxima above thisStdThreshold
	% and ignores smaller peaks around larger maxima within minTimeBtEvents
	warning off
	[~,testpeaks] = findpeaks(inputSignal,'minpeakheight',thisStdThreshold,'minpeakdistance',minTimeBtEvents);
	warning on

	% ignores smaller peaks around larger maxima within minTimeBtEvents
	%[~,testpeaks2] = findpeaks(inputSignal,'minpeakdistance',minTimeBtEvents);
	%testpeaks = intersect(testpeaks,testpeaks2);
	% extra check
	testpeaks = intersect(testpeaks,...
		find(filtfilt(ones(1,movAvgReqSize)/movAvgReqSize,1,inputSignal)>thisStdThreshold)...
		);

	% remove non-peaks within some set criteria
	switch options.detectMethod
		case 'diff'
			% get the differential
			testpeaks = testpeaks(rawInputSignal(testpeaks)>(numStdsForThresh*rawInputSignalStd));
			% options.nFramesShift = 0;

			% switch back for later analysis
			inputSignal = rawInputSignal;
		case 'raw'
			%
		otherwise
			% body
	end

	% check that maximum is at peak, else shift it
	if ~isempty(testpeaks)&options.reportMidpoint==0
		peakMaxLook = options.peakMaxLook;
		for peakNo = 1:length(testpeaks)
				testNewPeakIdx = testpeaks(peakNo)+peakMaxLook;
				if min(testNewPeakIdx)<=0|max(testNewPeakIdx)>length(inputSignal)
					continue;
				end
				testSignal = inputSignal(testNewPeakIdx);
				[~,maxSignal] = max(testSignal);
				% [maxSignal testpeaks(peakNo) testpeaks(peakNo)+(maxSignal-round(length(testNewPeakIdx)/2))]
				testpeaks(peakNo) = testpeaks(peakNo)+(maxSignal(1)-round(length(testNewPeakIdx)/2));
		end
	elseif options.reportMidpoint==1
		% peakMaxLook = options.peakMaxLook;
		% for peakNo = 1:length(testpeaks)
		%         testNewPeakIdx = testpeaks(peakNo)+peakMaxLook;
		%         if min(testNewPeakIdx)<=0|max(testNewPeakIdx)>length(inputSignal)
		%             continue;
		%         end
		%         testSignal = inputSignal(testNewPeakIdx);
		%         [~,maxSignal] = max(testSignal);
		%         % [maxSignal testpeaks(peakNo) testpeaks(peakNo)+(maxSignal-round(length(testNewPeakIdx)/2))]
		%         testpeaks(peakNo) = testpeaks(peakNo)+(maxSignal(1)-round(length(testNewPeakIdx)/2));
		% end
	end

	% shift peaks
	testpeaks = testpeaks + options.nFramesShift;

end

function [peakIdx] = subfxnCalcSignalNew(noiseSigmaThreshold,noiseSignal,loopSignal,tmpTestPeak)
	noiseStd = nanstd(noiseSignal(:));
	% noiseStd
	nPeaks = length(tmpTestPeak);
	peakIdxTmp1 = cell([1 nPeaks]);
	peakIdxTmp2 = cell([1 nPeaks]);
	% noiseSigmaThreshold = options.noiseSigmaThreshold;
	loopSignalThresholded = loopSignal>noiseSigmaThreshold*noiseStd;
	loopSignalThresholdedDiff = [0 diff(loopSignalThresholded)];
	for peakNo = 1:nPeaks
		try
			peakFrame = tmpTestPeak(peakNo);

			% currFrame = peakFrame;
			signalCriteria = loopSignalThresholdedDiff(1:peakFrame);
			currFrame = find(signalCriteria,1,'last');
			if isempty(currFrame)
				if sum(loopSignalThresholded(1:peakFrame))==length(loopSignalThresholded(1:peakFrame))
					currFrame = 1;
				end
			end
			% currFrame
			% aboveNoise = 1;
			% while aboveNoise==1
			%   aboveNoise = loopSignal(currFrame)>options.noiseSigmaThreshold*noiseStd;
			%   currFrame = currFrame - 1;
			%   if currFrame<1
			%       break
			%   end
			% end
			peakIdxTmp1{peakNo} = currFrame:peakFrame;

			% currFrame = peakFrame;
			% loopSignalThresholded = loopSignal>noiseSigmaThreshold*noiseStd;
			signalCriteria = abs(loopSignalThresholdedDiff(peakFrame:end));
			currFrame = find(signalCriteria,1,'first')+peakFrame;
			if isempty(currFrame)
				if sum(loopSignalThresholded(peakFrame:end))==length(loopSignalThresholded(peakFrame:end))
					currFrame = length(loopSignal);
				end
			end
			% currFrame
			% aboveNoise = 1;
			% currFrame = peakFrame;
			% while aboveNoise==1
			%   aboveNoise = loopSignal(currFrame)>options.noiseSigmaThreshold*noiseStd;
			%   currFrame = currFrame + 1;
			%   if currFrame>length(loopSignal)
			%       break
			%   end
			% end
			peakIdxTmp2{peakNo} = peakFrame:currFrame;
		catch err
			fprintf('peakFrame = %d\n',peakFrame);
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	peakIdx = [peakIdxTmp1{:} peakIdxTmp2{:}];
	peakIdx = unique(peakIdx(:));
end