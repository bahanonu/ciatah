function [signalMatrix, signalSpikes] = viewSpikeSummary(signalMatrix,signalSpikes,varargin)
	% gives several summary plots for a set of signals
	% biafra ahanonu
	% started: 2013.10.28
	% inputs
		% signalMatrix - 2D matrix of [signals frames] that contains the raw analog signal
		% signalSpikes - 2D matrix of [signals frames] that contains 0/1 indicating whether a peak occurred at that point
	% outputs
		% signalMatrix - 2D matrix of [signals frames] that contains the raw analog signal
		% signalSpikes - 2D matrix of [signals frames] that contains 0/1 indicating whether a peak occurred at that point

	[signalMatrix, signalSpikes] = ciapkg.view.viewSpikeSummary(signalMatrix,signalSpikes,'passArgs', varargin);
end