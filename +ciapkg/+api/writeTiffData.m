function [output] = writeTiffData(imgdata,FileSaving,varargin)
	% Writes out TIF data.
	% Created by Jerome Lecoq in 2012
	% Separate function by Biafra Ahanonu
	% 2015.07.06 [19:29:37]
	% inputs
		%
	% outputs
		%

	[output] = ciapkg.io.writeTiffData(imgdata,FileSaving,'passArgs', varargin);
end