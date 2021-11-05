function obj = modelBatchCopyFiles(obj)
	% Copies files from folders to a specific other folder.
	% Biafra Ahanonu
	% 2015.09.01 [21:36:38]
	%
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	% get user input
	movieSettings = inputdlg({...
			'start:end frames (leave blank for all)',...
			'file regexp:',...
			'copy to specific folder (leave blank to copy to same folder)',...
			'input HDF5 dataset name',...
			'output HDF5 dataset name',...
			'analyzing movie files (1 = yes, 0 = no):',...
			'back-up directory name (if copying into same folder)',...
			'name of new extension for movie (include leading dot, leave blank if keep the same)',...
			'append folder base string (blank if no)'...
		},...
		'copy files to /archive/ folder',1,...
		{...
			'1:4000',...
			obj.fileFilterRegexp,...
			'',...
			obj.inputDatasetName,...
			obj.inputDatasetName,...
			'1',...
			'archive',...
			'',...
			''...
		}...
	);
	setNo = 1;
	frameList = str2num(movieSettings{setNo});setNo = setNo+1;
	fileFilterRegexp = movieSettings{setNo};setNo = setNo+1;
	saveSpecificFolder = movieSettings{setNo};setNo = setNo+1;
	inputDatasetName =  movieSettings{setNo};setNo = setNo+1;
	outputDatasetName =  movieSettings{setNo};setNo = setNo+1;
	analyzeMovieFiles =  str2num(movieSettings{setNo});setNo = setNo+1;
	backupDirName =  movieSettings{setNo};setNo = setNo+1;
	newExtensionName =  movieSettings{setNo};setNo = setNo+1;
	useBaseFolderName =  movieSettings{setNo};setNo = setNo+1;

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	% loop over all directories and copy over a specified chunk of the movie file
	for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			switch analyzeMovieFiles
				case 1
					% load the movie
					movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
					% movieList = movieList{1};
					nMovies = length(movieList);
					for movieNo = 1:nMovies
						moviePath = movieList{movieNo};
						if isempty(frameList)
							frameListTmp = frameList;
						else
							movieDims = loadMovieList(moviePath,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single','getMovieDims',1);
							frameListTmp = frameList;
							% remove frames that are too large
							frameListTmp(frameListTmp>=movieDims.z) = [];
						end

						% create directory in other root
						if isempty(saveSpecificFolder)
							% move movie to archive folder if copying to the same folder then move file
							archivePath = [obj.inputFolders{obj.fileNum} filesep backupDirName];
							mkdir(archivePath);
							[PATHSTR,NAME,EXT] = fileparts(moviePath);
							archivePathFile = [archivePath filesep NAME EXT];
							display(['moving' num2str(movieNo) '/' num2str(nMovies) ': ' moviePath ' TO ' archivePathFile]);
							% movefile(moviePath,archivePathFile);
							if ispc
								dos(['move ' moviePath ' ' archivePathFile]);
							elseif isunix
								unix(['mv ' moviePath ' ' archivePathFile]);
							end
							newPathFile = moviePath;
							moviePath = archivePathFile;
						else
							[PATHSTR,NAME,EXT] = fileparts(obj.inputFolders{obj.fileNum});
							newPath = [saveSpecificFolder filesep NAME];
							mkdir(newPath)
							[PATHSTR,NAME,EXT] = fileparts(moviePath);
							newPathFile = [newPath filesep NAME EXT];
						end

						[primaryMovie] = loadMovieList(moviePath,'convertToDouble',0,'frameList',frameListTmp(:),'inputDatasetName',inputDatasetName);

						if ~isempty(newExtensionName)
							[PATHSTR,NAME,EXT] = fileparts(newPathFile);
							newPathFile = [PATHSTR filesep NAME newExtensionName];
						end

						if ~isempty(useBaseFolderName)
							[PATHSTR,NAME,EXT] = fileparts(newPathFile);
							newPathFile = [PATHSTR filesep obj.folderBaseSaveStr{obj.fileNum} '_' NAME EXT];
						end

						% save the file in the new location
						[output] = writeHDF5Data(primaryMovie,newPathFile,'datasetname',outputDatasetName);
					end
					% body
				case 0
					% load the movie
					fileList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
					nFiles = length(fileList);
					for fileNo = 1:nFiles
						filePath = fileList{fileNo};
						% create directory in other root
						if isempty(saveSpecificFolder)
							% move files to folder in current directory
							archivePath = [obj.inputFolders{obj.fileNum} filesep backupDirName];
							mkdir(archivePath);
							[PATHSTR,NAME,EXT] = fileparts(filePath);
							archivePathFile = [archivePath filesep NAME EXT];
							display(['moving' num2str(fileNo) '/' num2str(nFiles) ': ' filePath ' TO ' archivePathFile]);
							% movefile(filePath,archivePathFile);
							if ispc
								dos(['move ' filePath ' ' archivePathFile]);
							elseif isunix
								unix(['mv ' filePath ' ' archivePathFile]);
							end
							newPathFile = filePath;
							filePath = archivePathFile;
						else
							[PATHSTR,NAME,EXT] = fileparts(obj.inputFolders{obj.fileNum});
							newPath = [saveSpecificFolder filesep NAME];
							mkdir(newPath)
							[PATHSTR,NAME,EXT] = fileparts(filePath);
							newPathFile = [newPath filesep NAME EXT];
							display(['copying' num2str(fileNo) '/' num2str(nFiles) ': ' filePath ' TO ' newPathFile]);
							if ispc
								dos(['copy ' filePath ' ' newPathFile]);
							elseif isunix
								unix(['cp ' filePath ' ' newPathFile]);
							end
						end
					end
				otherwise
					% body
			end
	end

end