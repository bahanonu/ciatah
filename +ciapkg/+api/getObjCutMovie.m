function [k] = getObjCutMovie(inputMovie,inputImages,varargin)
	% Creates a movie cell array cut to a region around input cell images.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputMovie - [x y frames]
		% inputImages - [x y nSignals] - NOTE the dimensions, permute(inputImages,[3 1 2]) if you use [x y nSignals] convention
	% outputs
		%

	[k] = ciapkg.video.getObjCutMovie(inputMovie,inputImages,'passArgs', varargin);
end