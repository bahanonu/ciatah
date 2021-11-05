function [inputImages,inputTraces,infoStruct, algorithmStr] = loadNeurodataWithoutBorders(inputFilePath,varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: 2020.04.04 [15:02:22]
	% inputs
		% inputFilePath - Str: path to NWB file. If a cell, will only load the first string.
	% outputs
		% inputImages - 3D or 4D matrix containing cells and their spatial information, format: [x y nCells].
		% inputSignals - 2D matrix containing activity traces in [nCells nFrames] format.
		% infoStruct - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
		% algorithmStr - String of the algorithm name.

	[inputImages,inputTraces,infoStruct, algorithmStr] = ciapkg.io.loadNeurodataWithoutBorders(inputFilePath,'passArgs', varargin);
end