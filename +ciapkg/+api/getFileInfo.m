function [fileInfo] = getFileInfo(fileStr, varargin)
	% Gets file information for subject based on the file path, returns a structure with various information.
	% Biafra Ahanonu
	% started: 2013.11.04 [12:38:42]
	% inputs
		% fileStr - character string
	% options
		% assayList
	% outputs
		%

	[fileInfo] = ciapkg.io.getFileInfo(fileStr,'passArgs', varargin);
end