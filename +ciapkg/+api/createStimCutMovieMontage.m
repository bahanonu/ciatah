function [k] = createStimCutMovieMontage(inputMovie,nAlignPts,timeVector,varargin)
	% Creates a montage movie aligned to specific timepoints.
	% Biafra Ahanonu
	% fxn started: 2014.08.13 - broke off from controllerAnalysis script from ~2014.03
	% inputs
		% inputMovie - path to movie file, in cell array, e.g. {'path.h5'}
		% inputAlignPts - vector containing the frames to align to
		% savePathName - path to save output movie, exclude the extension.
	% outputs
		% 2015.11.05

	[k] = ciapkg.video.createStimCutMovieMontage(inputMovie,nAlignPts,timeVector,'passArgs', varargin);
end