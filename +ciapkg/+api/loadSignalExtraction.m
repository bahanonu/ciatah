function [inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = loadSignalExtraction(inputFilePath,varargin)
	% Loads CIAtah-style MAT or NWB files containing signal extraction results.
	% Biafra Ahanonu
	% started: 2021.02.03 [10:53:11]
	% inputs
		% inputFilePath - path to signal extraction output
	% outputs
		% inputImages - 3D or 4D matrix containing cells and their spatial information, format: [x y nCells].
		% inputSignals - 2D matrix containing activity traces in [nCells nFrames] format.
		% infoStruct - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
		% algorithmStr - String of the algorithm name.
		% inputSignals2 - same as inputSignals but for secondary traces an algorithm outputs.

	% changelog
		% 2021.03.10 [18:50:48] - Updated to add support for initial set of cell-extraction algorithms.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	
	[inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = ciapkg.io.loadSignalExtraction(inputFilePath,'passArgs', varargin);
end