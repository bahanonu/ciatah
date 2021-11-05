function [inputImageFiltered, additionalOutput] = fftImage(inputImage,varargin)
	% Computes FFT on input image.
	% Biafra Ahanonu
	% started: 2013.11.09
	% inputs
		% inputImage - [x y] matrix
	% outputs
		% inputImageFiltered - [x y] matrix
	% example
		% test the lowpass and highpass on an image with a range of options
		% f = fftImage(frame,'runfftTest',1,'bandpassType','lowpass');
		% f = fftImage(frame,'runfftTest',1,'bandpassType','highpass');


	[inputImageFiltered, additionalOutput] = ciapkg.image.fftImage(inputImage,'passArgs', varargin);
end