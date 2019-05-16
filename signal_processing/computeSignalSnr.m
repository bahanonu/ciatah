function [inputSnr, inputMse, inputSnrSignal, inputSnrNoise, outputSignal, outputNoise] = computeSignalSnr(inputSignals,varargin)
	% Obtains an approximate SNR for an input signal
	% Biafra Ahanonu
	% started: 2013.11.04 [11:54:09]
	% inputs
		% inputSignals: [nSignals frame] matrix
	% outputs
		% inputSnr: [1 nSignals] vector of calculated SNR. NaN used where SNR is not calculated.
		% inputMse: [1 nSignals] vector of MSE. NaN used where MSE is not calculated.
	% options
		% % type of SNR to calculate
		% options.SNRtype = 'mean(signal)/std(noise)';
		% % frames around which to remove the signal for noise estimation
		% options.timeSeq = [-10:10];
		% % show the waitbar
		% options.waitbarOn = 1;
		% % save time if already computed peaks
		% options.testpeaks = [];
		% options.testpeaksArray = [];
	% changelog
		% 2013.12.08 now uses RMS to calculate the SNR after removing the signal to get an estimated noise trace.
		% 2018.03.25 - Added iterative method to determine when signal ends. also added mean centering of trace to correct for offset traces causing problems.


	%========================
	% type of SNR to calculate
	options.SNRtype = 'mean(signal)/std(noise)';
	% frames around which to remove the signal for noise estimation
	options.timeSeq = (-10:10);
	% Str: iterativeRemove = find peaks and remove only once signal below options.noiseSigmaThreshold.
	options.signalCalcType = 'iterativeRemoveSignal';
	% Int: number of iterations for signalCalcType = 'iterativeRemoveSignal'
	options.signalCalcIters = 1;
	% show the waitbar
	options.waitbarOn = 1;
	% whether to display output information
	options.displayOutput = 1;
	% save time if already computed peaks
	options.testpeaks = [];
	options.testpeaksArray = [];
	% alternative if want to use non-shared peaks
	options.testpeaksArrayAlt = [];
	% return all signal SNR
	options.returnEachPeakSNR = 0;
	% Binary: 1 = only use peaks, 0 = use rise/fall around peaks for SNR signal calculation
	options.useOnlyPeaksSignal = 0;
	% number of standard deviations above the threshold to count as spike
	% options.numStdsForThresh = 1.0;
	options.numStdsForThresh = 2;
	% detect on differential ('diff') or raw ('raw') trace
	options.detectMethod = 'diff';
	% Float: number of std above noise to use for signal estimation cutoff.
	options.noiseSigmaThreshold = 1;

	% Median filter the data
	options.medianFilter = 1;
	options.subtractMean = 1;
	% number of frames to calculate median filter
	options.medianFilterLength = 200;
	% the size of the moving average
	options.movAvgFiltSize = [];
	% Binary: 1 = convert input inputSignals matrix to cell array
	options.convertSignalsToCell = 1;
	% get options
	options = getOptions(options,varargin);
	%========================
	try
		if options.medianFilter==1
			if options.displayOutput==1
				disp('Median filtering before peak statistics')
			end
			for signalNoNow = 1:size(inputSignals,1)
				inputSignal = inputSignals(signalNoNow,:);
				inputSignalMedian = medfilt1(inputSignal,options.medianFilterLength);
				inputSignal = inputSignal - inputSignalMedian;
				inputSignals(signalNoNow,:) = inputSignal;
				if ~isempty(options.movAvgFiltSize)
					inputSignals(signalNoNow,:) = filtfilt(ones(1,options.movAvgFiltSize)/options.movAvgFiltSize,1,inputSignal);
				end
			end
		end

		if options.displayOutput==1
			disp(['SNR type: ' options.SNRtype])
		end
		% to later calculate the signal idx
		% outerFun = @(x,y) x+y;
		nSignals = size(inputSignals,1);
		% reverseStr = '';
		% calculate peak locations
		if isempty(options.testpeaksArray)
			[~, testpeaksArray] = computeSignalPeaks(inputSignals,'makeSummaryPlots',0,'waitbarOn',options.waitbarOn,'outputInfo',options.displayOutput,'numStdsForThresh',options.numStdsForThresh,'detectMethod',options.detectMethod);
		else
			% testpeaks = options.testpeaks;
			testpeaksArray = options.testpeaksArray;
			options.testpeaksArray = [];
		end
		if isempty(options.testpeaksArrayAlt)
			testpeaksArrayAlt = [];
		else
			testpeaksArrayAlt = options.testpeaksArrayAlt;
			options.testpeaksArrayAlt
		end
		if options.returnEachPeakSNR==1
			inputSnr = cell(nSignals,1);
			inputSnrSignal = cell(nSignals,1);
			inputSnrNoise = cell(nSignals,1);
			inputMse = NaN([1 nSignals]);
		else
			inputSnr = NaN([1 nSignals]);
			inputSnrSignal = NaN([1 nSignals]);
			inputSnrNoise = NaN([1 nSignals]);
			inputMse = NaN([1 nSignals]);
		end
		outputSignal = cell([1 nSignals]);
		outputNoise = cell([1 nSignals]);
		% size(testpeaksArray)
		% nSignals
		% MAKE PARFOR
		% try [~, ~] = parfor_progress(nSignals);catch;end; dispStepSize = round(nSignals/20); dispstat('','init');

		optionsOriginal = options;

		% Convert to cell array to reduce memory transfer during parallelization
		if options.convertSignalsToCell==1
			inputSignals = squeeze(mat2cell(inputSignals,ones(1,size(inputSignals,1)),size(inputSignals,2)));
		end

		% Only implement in Matlab 2017a and above
		if ~verLessThan('matlab', '9.2')
			D = parallel.pool.DataQueue;
			afterEach(D, @nUpdateParforProgress);
			p = 1;
			% N = nSignals;
			nInterval = 25;
			options_waitbarOn = options.waitbarOn;
		end

		parfor signalNo=1:nSignals
			options = optionsOriginal;
			% loopSignal = inputSignals(signalNo,:);
			loopSignal = inputSignals{signalNo};
			if options.subtractMean==1
				loopSignal = loopSignal - nanmean(loopSignal(:));
			end
			loopSignalConstant = loopSignal;
			testpeaks = testpeaksArray{signalNo};
			switch options.SNRtype
				case 'mean(signal)/std(noise)'
					% Xapp=zeros(1,length(X));
					if ~isempty(testpeaks)
						% peakIdx = bsxfun(outerFun,options.timeSeq',testpeaks);
						if isempty(testpeaksArrayAlt)
							peakIdx = bsxfun(@plus,options.timeSeq',testpeaks);
							tmpTestPeak = testpeaks;
						else
							tmpTestPeak = testpeaksArrayAlt{signalNo};
							peakIdx = bsxfun(@plus,options.timeSeq',tmpTestPeak(:)');
						end

						peakIdx = unique(peakIdx(:));
						if ~isempty(peakIdx)
							% remove peaks outside range of signal
							peakIdx(peakIdx>length(loopSignal))=[];
							peakIdx(peakIdx<=0)=[];

							% remove signal then add back in noise based on signal statistics
							noiseSignal = loopSignal;
							noiseSignal(peakIdx) = NaN;
							% noiseSignal(peakIdx) = [];
							% noiseSignal(peakIdx) = normrnd(nanmean(noiseSignal),nanstd(noiseSignal),[1 length(peakIdx)]);

							if strcmp(options.signalCalcType,'iterativeRemoveSignal')
								for iterNo = 1:options.signalCalcIters
									[peakIdx] = subfxnCalcSignalNew(options,noiseSignal,loopSignal,tmpTestPeak);

									% remove peaks outside range of signal
									peakIdx(peakIdx>length(loopSignal))=[];
									peakIdx(peakIdx<=0)=[];

									% remove signal then add back in noise based on signal statistics
									noiseSignal = loopSignal;
									noiseSignal(peakIdx) = NaN;
								end
							end

							% remove noise from signal vector
							xtmp = zeros([1 length(loopSignal)]);
							xtmp(peakIdx) = 1;
							loopSignal(~logical(xtmp)) = NaN;

							% compute SNR
							% x_snr = (rootMeanSquare(loopSignal)/rootMeanSquare(noiseSignal))^2;
							% nanstd(noiseSignal)
							% loopSignal
							outputSignal{signalNo} = loopSignal;
							outputNoise{signalNo} = noiseSignal;

							% pltSignal = loopSignalConstant;
							% figure;plot(pltSignal,'k');hold on;plot(outputSignal{signalNo}+max(pltSignal),'r');hold on;plot(outputNoise{signalNo}+max(pltSignal),'b');legend('original','signal','noise');box off; xlabel('frames');ylabel('Signal intensity change');drawnow

							if options.returnEachPeakSNR==1
								tmpSignal = loopSignalConstant;
								x_snr = tmpSignal(testpeaks)/nanstd(noiseSignal);
								x_signal = tmpSignal(testpeaks);
								x_noise = nanstd(noiseSignal);
							else
								tmpSignal = loopSignalConstant;
								if options.useOnlyPeaksSignal==1
									% x_snr = nanmean(tmpSignal(testpeaks)/nanstd(noiseSignal));
									x_signal = nanmean(tmpSignal(testpeaks));
									x_noise = nanstd(noiseSignal);
								else
									% x_snr = nanmean(loopSignal)/nanstd(noiseSignal);
									x_signal = nanmean(loopSignal);
									x_noise = nanstd(noiseSignal);
								end
								x_snr = x_signal/x_noise;
								% x_snr = nanmean(tmpSignal(testpeaks))/nanstd(tmpSignal);
								% x_snr = rootMeanSquare(tmpSignal(testpeaks))/rootMeanSquare(noiseSignal);
							end
							xRms = rootMeanSquare(loopSignal);
						else
							x_snr = NaN;
							xRms = NaN;
							x_signal = NaN;
							x_noise = NaN;
							outputSignal{signalNo} = loopSignal;
							outputNoise{signalNo} = loopSignal;
						end
					else
						x_snr = NaN;
						xRms = NaN;
						x_signal = NaN;
						x_noise = NaN;
						outputSignal{signalNo} = loopSignal;
						outputNoise{signalNo} = loopSignal;
					end
					if options.returnEachPeakSNR==1
						inputSnr{signalNo}=x_snr;
						inputSnrSignal{signalNo}=x_signal;
						inputSnrNoise{signalNo}=x_noise;
						inputMse(signalNo)=xRms;
					else
						inputSnr(signalNo)=x_snr;
						inputSnrSignal(signalNo)=x_signal;
						inputSnrNoise(signalNo)=x_noise;
						inputMse(signalNo)=xRms;
					end
					% Xapp(testpeaks)=X(testpeaks);
					% [psnr,mse,maxerr,L2rat] = measerr(X,Xapp);
					% IcaSnr(signalNo)=psnr;
					% IcaMse(signalNo)=mse;
				otherwise
					disp('incorrect SNR type')
			end

			% print progress
			if ~verLessThan('matlab', '9.2')
				% Update
				send(D, signalNo);
			end
			if options.waitbarOn==1&&options.displayOutput==1
				% [percent, progress] = parfor_progress;if mod(progress,dispStepSize) == 0;dispstat(sprintf('progress %0.1f %',percent));end
				% reverseStr = cmdWaitbar(signalNo,nSignals,reverseStr,'inputStr','obtaining SNR','waitbarOn',options.waitbarOn,'displayEvery',50);
			end
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
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
%% functionname: function description
function [peakIdx] = subfxnCalcSignalNew(options,noiseSignal,loopSignal,tmpTestPeak)
	noiseStd = nanstd(noiseSignal(:));
	% noiseStd
	nPeaks = length(tmpTestPeak);
	peakIdxTmp1 = cell([1 nPeaks]);
	peakIdxTmp2 = cell([1 nPeaks]);
	noiseSigmaThreshold = options.noiseSigmaThreshold;
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
			% 	aboveNoise = loopSignal(currFrame)>options.noiseSigmaThreshold*noiseStd;
			% 	currFrame = currFrame - 1;
			% 	if currFrame<1
			% 		break
			% 	end
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
			% 	aboveNoise = loopSignal(currFrame)>options.noiseSigmaThreshold*noiseStd;
			% 	currFrame = currFrame + 1;
			% 	if currFrame>length(loopSignal)
			% 		break
			% 	end
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
function [RMS] = rootMeanSquare(x)
	RMS = sqrt(nanmean(x.^2));
end