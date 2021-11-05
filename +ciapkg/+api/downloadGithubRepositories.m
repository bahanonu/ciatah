function [success] = downloadGithubRepositories(varargin)
	% Downloads Github repositories repositories.
	% Biafra Ahanonu
	% started: 2019.01.14 [10:23:05]

	[success] = ciapkg.download.downloadGithubRepositories('passArgs', varargin);
end