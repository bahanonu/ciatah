function [inputMovie] = addDroppedFramesToMovie(inputMovie,droppedFrames,varargin)
	% Fixes movie by adding dropped frames with the mean of the movie (to reduce impact on cell extraction algorithms).
	% Biafra Ahanonu
	% started: 2016.10.04 [20:31:15]
	% inputs
		% inputMovie - matrix dims are [X Y t] - where t = number of time points
		% path to inscopix file or list of dropped frames
	% outputs
		% inputMovie with dropped frames added back in.

	[inputMovie] = ciapkg.video.addDroppedFramesToMovie(inputMovie,droppedFrames,'passArgs', varargin);
end