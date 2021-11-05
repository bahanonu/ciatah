function [outputColormap] = customColormap(colorList,varargin)
	% Creates a custom colormap.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	
	if nargin==0
	    [outputColormap] = ciapkg.view.customColormap();
	elseif nargin==1
		[outputColormap] = ciapkg.view.customColormap(colorList,'passArgs', varargin);
	else
	    [outputColormap] = ciapkg.view.customColormap(colorList,'passArgs', varargin);
	end
end