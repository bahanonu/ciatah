function [outputMovie] = createSideBySide(primaryMovie,secondaryMovie,varargin)
	% Auto-create side-by-side, either save output as hdf5 or return a matrix
	% Biafra Ahanonu
	% started: 2014.01.04 (code taken from controllerAnalysis)
	% inputs
		% primaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
		% secondaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
	% outputs
		% outputMovie - horizontally concatenated movie


	[outputMovie] = ciapkg.video.createSideBySide(primaryMovie,secondaryMovie,'passArgs', varargin);
end