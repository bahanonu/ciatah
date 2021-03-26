% function obj = delete(obj)
	% Warn the user before deleting class
	% % Overload delete method to verify with user.
	% scnsize = get(0,'ScreenSize');
	% dependencyStr = {'downloadCnmfGithubRepositories','loadMiji','example_downloadTestData'};
	% [fileIdxArray, ok] = listdlg('ListString',dependencyStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Which dependency to load?');
	% obj.runPipeline;
	% % disp('hello');
% end