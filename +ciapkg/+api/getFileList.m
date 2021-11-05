function [fileList] = getFileList(inputDir, filterExp,varargin)
	% Gathers a list of files based on an input regular expression.
	% Biafra Ahanonu
	% started: 2013.10.08 [11:02:31]
	% inputs
		% inputDir - directory to gather files from and regexp filter for files
		% filterExp - regexp used to find files
	% outputs
		% file list, full path

	[fileList] = ciapkg.io.getFileList(inputDir, filterExp,'passArgs', varargin);
end