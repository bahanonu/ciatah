function [inputImages, inputSignals, choices] = signalSorter(inputImages,inputSignals,varargin)
	% Displays a GUI for sorting images (e.g. cells) and their associated signals (e.g. fluorescence activity traces). Also does preliminary sorting based on image/signal properties if requested by user.
	% See following URL for details of GUI and tips on manual sorting: https://github.com/bahanonu/calciumImagingAnalysis/wiki/Manual-cell-sorting-of-cell-extraction-outputs.
	% Biafra Ahanonu
	% started: 2013.10.08
	% Dependent code
		% getOptions.m, createObjMap.m, removeSmallICs.m, identifySpikes.m, etc., see repository
	% inputs
		% inputImages - [x y N] matrix where N = number of images, x/y are dimensions. Use permute(inputImages,[2 3 1]) if you use [N x y] for matrix indexing.
			% Alternatively, make inputImages = give path to NWB file and inputSignals = [] for signalSorter to automatically load NWB files.
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames.
		% inputID - obsolete, kept for compatibility, just input empty []
		% nSignals - obsolete, kept for compatibility
	% outputs
		% inputImages - [N x y] matrix where N = number of images, x/y are dimensions with only manual choices kept.
		% inputSignals
		% choices

	[inputImages, inputSignals, choices] = ciapkg.classification.signalSorter(inputImages,inputSignals,'passArgs', varargin);
end