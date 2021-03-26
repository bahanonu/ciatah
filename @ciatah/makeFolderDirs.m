function obj = makeFolderDirs(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	% ensure private folders are set
	if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);end
	if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);end
	if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);end
	% save the current object instance
end