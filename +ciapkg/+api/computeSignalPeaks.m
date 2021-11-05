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

	[signalPeaks, signalPeaksArray, signalSigmas] = ciapkg.signal_processing.computeSignalPeaks(signalMatrix,'passArgs', varargin);
end