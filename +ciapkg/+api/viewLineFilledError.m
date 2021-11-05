function [success] = viewLineFilledError(inputMean,inputStd,varargin)
	% Makes solid error bars around line.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputMean - Vector [1 timePoints] of y mean for each value of
		% inputStd - Vector [1 timePoints] indicating the std or SEM at each time point in inputMean
	% outputs
		% success - Binary 1 = ran without errors, 0 = encountered errors

	[success] = ciapkg.view.viewLineFilledError(inputMean,inputStd,'passArgs', varargin);
end