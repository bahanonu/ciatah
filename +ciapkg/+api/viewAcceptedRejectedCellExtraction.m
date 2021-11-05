function [success] = viewAcceptedRejectedCellExtraction(inputImages,inputSignals,valid,inputMovie,varargin)
	% Plots cell image, peak transients, and image from activity in movie for accepted and rejected cells, useful for publications.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	[success] = ciapkg.view.viewAcceptedRejectedCellExtraction(inputImages,inputSignals,valid,inputMovie,'passArgs', varargin);
end