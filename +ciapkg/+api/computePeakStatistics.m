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

	[peakOutputStat] = ciapkg.signal_processing.computePeakStatistics(inputSignals,'passArgs', varargin);
end