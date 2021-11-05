function [outputImages, outputMeanImageCorrs, outputMeanImageCorr2, outputMeanImageStruct] = createPeakTriggeredImages(inputMovie, inputImages, inputSignals, varargin)
	% Gets event triggered average image from an input movie based on cell images located in input image and trace matrix.
	% Biafra Ahanonu
	% started: 2015.09.28, abstracted from behaviorAnalysis
	% inputs
		% inputMovie - [x y frames]
		% inputImages - [x y nSignals]
		% inputSignals - [nSignals frames]
	% outputs
		%

	[outputImages, outputMeanImageCorrs, outputMeanImageCorr2, outputMeanImageStruct] = ciapkg.image.createPeakTriggeredImages(inputMovie, inputImages, inputSignals,'passArgs', varargin);
end