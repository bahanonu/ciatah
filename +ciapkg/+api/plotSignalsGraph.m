function [tmpTrace] = plotSignalsGraph(IcaTraces,varargin)
	% Plots signals, offsetting by a fixed amount.
	% Biafra Ahanonu
	% started: 2013.11.02
	% inputs
		%
	% outputs
		%

	[tmpTrace] = ciapkg.view.plotSignalsGraph(IcaTraces,'passArgs', varargin);
end