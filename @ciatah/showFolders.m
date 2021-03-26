function obj = showFolders(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	for i = 1:length(obj.inputFolders)
		disp([num2str(i) ' | ' obj.inputFolders{i}])
	end
end