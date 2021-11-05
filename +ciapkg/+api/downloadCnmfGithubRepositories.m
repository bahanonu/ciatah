function [success] = downloadCnmfGithubRepositories(varargin)
	% Biafra Ahanonu
	% Downloads CNMF and CNMF-E repositories.
	% started: 2019.01.14 [10:23:05]

	[success] = ciapkg.download.downloadCnmfGithubRepositories('passArgs', varargin);
end