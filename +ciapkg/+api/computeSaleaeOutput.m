function [outputData] = computeSaleaeOutput(matfile,varargin)
	% Processes Saleae output files. This is for data collected with Saleae Logic 1.x software, NOT 2.x.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% matfile - Str: path to Mat-file with Salaea outputs
	% outputs
		% outputData - table consisting of session times, frame clock (digital channel 0), and events in each channel or analog values in that frame.

	[outputData] = ciapkg.behavior.computeSaleaeOutput(matfile,'passArgs', varargin);
end