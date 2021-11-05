function [coords] = getCropCoords(thisFrame,varargin)
	% GUI to allow users to select crop coordinates.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	[coords] = ciapkg.image.getCropCoords(thisFrame,'passArgs', varargin);
end