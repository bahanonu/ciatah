function [legendHandle] = groupColorLegend(typeArray,colorMatrix,varargin)
	% Correctly plots multi-colored legend entries.
	% Biafra Ahanonu
	% 2014.01.23 [10:41:07]
	% inputs
		%
	% outputs
		%

	[legendHandle] = ciapkg.view.groupColorLegend(typeArray,colorMatrix,'passArgs', varargin);
end