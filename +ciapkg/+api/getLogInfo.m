function [logStruct] = getLogInfo(logFilePath,varargin)
	% Opens a log file (e.g. Inscopix recording file) and outputs a structure containing the field information for the structure.
	% Biafra Ahanonu
	% started: 2014.01.30
	% based on R code by Biafra Ahanonu started: 2013.09.18
	% inputs
		%
	% outputs
		%

	[logStruct] = ciapkg.io.getLogInfo(logFilePath,'passArgs', varargin);
end