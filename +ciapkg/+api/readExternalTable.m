function [outputTable] = readExternalTable(inputTableFilename,varargin)
	% Read in table, decides whether to do a single or multiple tables, if multiple tables, should have the same column names.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		% inputTableFilename - string pointing toward file
	% outputs
		%

	[outputTable] = ciapkg.io.readExternalTable(inputTableFilename,'passArgs', varargin);
end