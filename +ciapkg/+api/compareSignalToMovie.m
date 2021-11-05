function [croppedPeakImages] = compareSignalToMovie(inputMovie, inputImages, inputSignal, varargin)
	% Shows a cropped version of inputMovie for each inputImages and aligns it to inputSignal peaks to make sure detection is working.
	% Biafra Ahanonu
	% started: 2013.11.04 [18:40:45]
	% inputs
		% inputMovie - matrix dims are [X Y t] - where t = number of time points
		% inputImages - matrix dims are [X Y n] - where n = number of filters, NOTE THE DIFFERENCE
		% inputSignal - matrix dims are [n t] - where n = number of signals, t = number of time points
	% outputs
		% none, this is a display function


	[croppedPeakImages] = ciapkg.view.compareSignalToMovie(inputMovie, inputImages, inputSignal,'passArgs', varargin);
end