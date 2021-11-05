function [success] = convertRgbToGrayscale(inputListFile,varargin)
	% Converts rgb AVI file to grayscale, e.g. for ImageJ base tracking.
	% Biafra Ahanonu
	% started: 2017.03.23
	% inputs
		% inputListFile - A string pointing to a directory or a cell array of strings.
	% outputs
		%


	[success] = ciapkg.io.convertRgbToGrayscale(inputListFile,'passArgs', varargin);
end