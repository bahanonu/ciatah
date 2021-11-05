function [inputSignalspread] = spreadSignal(inputSignal,varargin)
	% Spreads a signal out over several points in a vector, akin to smoothing except signal is kept absolute, e.g. [0 0 1 0 0] to [0 1 1 1 0].
	% Biafra Ahanonu
	% started: 2014.01.26 [15:48:34]
	% inputs
		% inputSignal
	% outputs
		% inputSignalspread


	[inputSignalspread] = ciapkg.signal_processing.spreadSignal(inputSignal,'passArgs', varargin);
end