function loadBatchFxns()
	% loads the necessary directories to have the batch functions present
	% Biafra Ahanonu
	% started: 2013.12.24 [08:46:11]

	% add controller directory and subdirectories to path
	pathList = genpath(pwd);
	pathListArray = strsplit(pathList,pathsep);
	pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep '.git']));
	pathListArray = pathListArray(pathFilter);

	pathList = strjoin(pathListArray,pathsep);
	addpath(pathList);

	% add path for Miji, change as needed
	% http://bigwww.epfl.ch/sage/soft/mij/
	% modelAddOutsideDependencies('miji');
	pathtoMiji = '\Fiji.app\scripts\';
	if exist(pathtoMiji,'dir')~=0
		addpath(pathtoMiji);
	else
		clear pathtoMiji;
	end
end