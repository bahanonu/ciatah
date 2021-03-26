function obj = modelPreprocessMovie(obj)
	% Controller for pre-processing movies, mainly aimed at calcium imaging data. Wrapper for modelPreprocessMovieFunction.
	% Biafra Ahanonu
	% started 2013.11.09 [10:46:23]

	% verify that there are folders present
	if isempty(obj.inputFolders)
		uiwait(msgbox('Please run modelAddNewFolders to add folders to the object','Success','modal'));
		return
	end
	% check that Miji exists, if not, have user enter information
	% try
	% 	Miji
	% 	MIJ.exit
	% catch
	modelAddOutsideDependencies('miji');
	if obj.guiEnabled==1
		if isempty(obj.foldersToAnalyze)
			scnsize = get(0,'ScreenSize');
			[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
		else
			fileIdxArray = obj.foldersToAnalyze;
		end
	else
		if isempty(obj.foldersToAnalyze)
			fileIdxArray = 1:length(obj.fileIDNameArray);
		else
			fileIdxArray = obj.foldersToAnalyze;
		end
	end

	options.fileFilterRegexp = 'concat_.*.h5';
	folderListInfo = {obj.inputFolders{fileIdxArray}};
	options.datasetName = obj.inputDatasetName;

	% controllerPreprocessMovie2('folderListPath',folderListInfo,'fileFilterRegexp',options.fileFilterRegexp,'datasetName',options.datasetName,'frameList',[]);
	obj.modelPreprocessMovieFunction('folderListPath',folderListInfo,'fileFilterRegexp',options.fileFilterRegexp,'datasetName',options.datasetName,'frameList',[]);
end