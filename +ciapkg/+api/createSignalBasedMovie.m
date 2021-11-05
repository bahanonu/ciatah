function [signalMovie] = createSignalBasedMovie(inputSignals,inputImages,varargin)
	% uses images and signals for sources from an original movie to create a cleaner, more binary movie
	% biafra ahanonu
	% started: 2014.07.20 [14:09:34]
	% inputs
		% inputSignals - [n t], n = number of signals, t = time
		% inputImages - [n x y], n = number of images, x/y are the dimensions of the images, use permute(inputImages,[3 1 2]) if you store z dimension last
	% outputs
		% signalMovie - [x y t] movie, reconstructed from cell traces
	% options
		% filterInputs: should the input images be automatically filtered to remove large or low SNR signals? 0 = no, 1 = yes
		% signalType 'raw' or 'peak', peaks uses a smoothed version of the detected peaks
		% inputPeaks : [n t] matrix (n = number of signals, t = time) of pre-computed peaks, should contain 1 = peak, 0 = no peak

	[signalMovie] = ciapkg.video.createSignalBasedMovie(inputSignals,inputImages,'passArgs', varargin);
end