function [xPlot, yPlot] = getSubplotDimensions(nPlots,varargin)
	% Creates an optimal arrangement of subplots, always aiming to make a symmetrical grid.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% nPlots - integer, number of subplots that will be created
	% outputs
		%

	[xPlot, yPlot] = ciapkg.view.getSubplotDimensions(nPlots,'passArgs', varargin);
end