function [outputSignal, inputImages] = applyImagesToMovie(inputImages,inputMovie, varargin)
	% Applies images to a 3D movie matrix in order to get a signal based on a thresholded version of the image.
	% Biafra Ahanonu
	% started: 2013.10.11
	% inputs
		% inputImages - [x y signalNo] of images, signals will be calculated for each image from the movie.
		% inputMovie - [x y frame] or char string path to the movie.
	% outputs
		% outputSignal - [signalNo frame] matrix of each signal's activity trace extracted directly from the movie.
		% inputImages - [x y signalNo], same as input.

	[outputSignal, inputImages] = ciapkg.signal_processing.applyImagesToMovie(inputImages,inputMovie,'passArgs', varargin);
end