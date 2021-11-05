function obj = removeConcurrentAnalysisFiles(obj)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	obj.foldersToAnalyze
	if obj.guiEnabled==1
		if isempty(obj.foldersToAnalyze)
			scnsize = get(0,'ScreenSize');
			[fileIdxArray, ~] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
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

	% Find all concurrent analysis files and delete them
	nFolders = length(fileIdxArray);
	nFoldersTotal = length(obj.inputFolders);
	for folderNo = 1:nFolders
		i = fileIdxArray(folderNo);
		try
			% disp([num2str(i) ' | ' obj.inputFolders{i}])
			fileList = getFileList(obj.inputFolders{i},obj.concurrentAnalysisFilename);
			if ~isempty(fileList)
				fprintf('%d/%d (%d/%d) will delete analysis file: %s\n',i,nFoldersTotal,folderNo,nFolders,fileList{1})
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
	userInput = input('Continue (1 = yes, 0 = no)? ');
	if userInput==1
		for folderNo = 1:nFolders
			i = fileIdxArray(folderNo);
			try
				% disp([num2str(i) ' | ' obj.inputFolders{i}])
				fprintf('%d/%d (%d/%d): %s\n',i,nFoldersTotal,folderNo,nFolders,obj.inputFolders{i})
				fileList = getFileList(obj.inputFolders{i},obj.concurrentAnalysisFilename);
				if ~isempty(fileList)
					fprintf('Deleting analysis file: %s\n',fileList{1})
					delete(fileList{1});
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end
end