function obj = modelAddNewFolders(obj,varargin)
	% Add folders to the class.
	% Biafra Ahanonu
	% started: 2014.12.22 (probably before)
	%========================
	% Cell array of folders to add, particularly for GUI-less operations
	options.folderCellArray = {};
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	try
		nExistingFolders = length(obj.inputFolders);
		if isempty(options.folderCellArray)
			newFolderList = inputdlg('One new line per folder path. Enter folder path WITHOUT any single/double quotation marks around the path.','Adding folders to calciumImagingAnalysis object.',[21 150]);
            if isempty(newFolderList)
                warning('No folders given. Please re-run modelAddNewFolders.')
                return
            end
			newFolderList = newFolderList{1,1};
			% size(newFolderList)
			% class(newFolderList)

			% if obj.guiEnabled==1
			% 	scnsize = get(0,'ScreenSize');
			% 	[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
			% else
			% 	fileIdxArray = 1:length(obj.fileIDNameArray);
			% end
			nNewFolders = size(newFolderList,1);
			fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
			nFolders = length(fileIdxArray);
			newFolderListCell = {};
			for thisFileNumIdx = 1:nFolders
				% strtrim(newFolderList(thisFileNumIdx,:))
				% class(strtrim(newFolderList(thisFileNumIdx,:)))
				newFolderListCell{thisFileNumIdx} = strtrim(newFolderList(thisFileNumIdx,:));
			end
		else
			newFolderListCell = options.folderCellArray;
			nNewFolders = length(newFolderListCell);
		end

		fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
		% obj.foldersToAnalyze = fileIdxArray;
		nFolders = length(fileIdxArray);
		display(repmat('-',1,7))
		display('Existing folders:')
		cellfun(@display,obj.inputFolders)
		display(repmat('-',1,7))
		display(['Number new folders:' num2str(nFolders) ' | New folder indices: ' num2str(fileIdxArray)]);
		for thisFileNumIdx = 1:nFolders
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			obj.inputFolders{obj.fileNum,1} = newFolderListCell{thisFileNumIdx};
			obj.dataPath{obj.fileNum,1} = newFolderListCell{thisFileNumIdx};
			% display(repmat('=',1,21))
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
		end
		display('Folders added:')
		cellfun(@display,obj.inputFolders((end-nFolders+1):end));
		display('Adding file info to class...')
		obj.modelGetFileInfo();
		% display('Getting model variables...')
		% obj.modelVarsFromFiles();
		% display('Running pipeline...')
		% obj.runPipeline();

		% Reset folders to analyze
		obj.foldersToAnalyze = [];
	catch err
		obj.foldersToAnalyze = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end