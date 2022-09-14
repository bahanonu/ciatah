function [valid, algorithmStr, infoStruct] = loadSignalExtractionSorting(inputFilePath,varargin)
	% [valid,algorithmStr,infoStruct] = loadSignalExtractionSorting(inputFilePath,varargin)
	% 
	% Loads manual or automated (e.g. CLEAN) sorting..
	% 
	% Biafra Ahanonu
	% started: 2022.05.31 [20:14:54] (branched from modelVarsFromFiles)
	% 
	% Inputs
	% 	inputFilePath - Str: path to signal extraction output.
	% 
	% Outputs
	% 	valid - logical vector: indicating which signals are valid and should be kept.
	% 	algorithmStr - Str: algorithm name.
	% 	infoStruct - Struct: contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		%
	% TODO
		%

	[valid, algorithmStr, infoStruct] = ciapkg.io.loadSignalExtractionSorting(inputFilePath,'passArgs', varargin);
end