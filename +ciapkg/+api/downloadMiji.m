function [success] = downloadMiji(varargin)
	% Biafra Ahanonu
	% Downloads the correct Miji version for each OS.
	% started: 2019.07.30 [09:58:04]
	% inputs
		%
	% outputs
		%

	[success] = ciapkg.download.downloadMiji('passArgs', varargin);
end