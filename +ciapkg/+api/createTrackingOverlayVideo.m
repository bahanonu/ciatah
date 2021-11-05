function [inputTrackingVideo] = createTrackingOverlayVideo(inputTrackingVideo,inputX,inputY,varargin)
	% Takes tracking data and makes an overlay on a behavioral movie.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputTrackingVideo - [x y frames] movie or path to AVI file
		% inputX - [1 frames] vector or path to csv table
		% inputY - [1 frames] vector or blank of inputX is a path
	% outputs
		%


	[inputTrackingVideo] = ciapkg.tracking.createTrackingOverlayVideo(inputTrackingVideo,inputX,inputY,'passArgs', varargin);
end