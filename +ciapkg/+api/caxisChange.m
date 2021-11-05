function caxisChange(inputLimits,varargin)
	% caxis wrapper to also change colorbar range to be correct automatically.
	% Biafra Ahanonu
	% started: 2019.10.08 [19:15:59]
	% inputs
		% inputLimits - [lowerLimit upperLimit] vector
	% outputs
		%

	ciapkg.view.caxisChange(inputLimits,'passArgs', varargin);
end