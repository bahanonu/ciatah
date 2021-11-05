function [success] = cnmfVersionDirLoad(cnmfVersion,varargin)
	% Allow switching between CNMF versions by loading the correct repository directory.
	% Biafra Ahanonu
	% started: 2018.10.20
	% inputs
		%
	% outputs
		%

	[success] = ciapkg.signal_extraction.cnmfVersionDirLoad(cnmfVersion,'passArgs', varargin);
end