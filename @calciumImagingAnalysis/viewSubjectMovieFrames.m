function obj = viewSubjectMovieFrames(obj)
	% Creates frame snippets from movies of a subject, used to get a sense of how well cross-session alignment should work.
	% Biafra Ahanonu
	% branched from controllerAnalysis
	% started: 2014.08.01 [16:09:16] (2015.09.14 14:40)
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% fileFilterRegexp = 'concat';
	display(repmat('#',1,21))
	display('computing signal peaks...')
	nFiles = length(obj.rawSignals);

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	subjectList = unique(obj.subjectStr(fileIdxArray));

	movieSettings = inputdlg({...
			'regexp for movies',...
			'group by (1) subject, (2) folder, (3) all montage, or (4) cell extraction max proj',...
			'video save directory',...
			'normalize movie',...
			'start:end frames (do not leave blank)'...
		},...
		'movie frames settings',1,...
		{...
			'concat',...
			'1',...
			obj.videoSaveDir,...
			'0',...
			'100:101'...
		}...
	);
	setNo = 1;
	fileFilterRegexp = movieSettings{setNo};setNo = setNo+1;
	usrIdxChoiceType = str2num(movieSettings{setNo});setNo = setNo+1;
	obj.videoSaveDir = movieSettings{setNo};setNo = setNo+1;
	normalizeMovieSwitch = str2num(movieSettings{setNo});setNo = setNo+1;
	frameList = str2num(movieSettings{setNo});setNo = setNo+1;

	% Miji;
	MIJ.start;

	switch usrIdxChoiceType
		case 1
			for thisSubjectStr=subjectList
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				% validManualIdx = find(arrayfun(@(x) isempty(x{1}),obj.validManual));
				% classifyFoldersIdx = intersect(validFoldersIdx,validManualIdx);
				movieList = getFileList({obj.inputFolders{validFoldersIdx}}, fileFilterRegexp);
				movieList
				subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',frameList);
				% movieFrame = squeeze(movieFrame(:,:,1));
				subjectMovieFrames = subjectMovieFrames(:,:,1:2:end);
				if normalizeMovieSwitch==1
					[subjectMovieFrames] = normalizeVector(single(subjectMovieFrames),'normRange','zeroToOne');
					[subjectMovieFrames] = normalizeMovie(subjectMovieFrames,'normalizationType','meanSubtraction');
				end

				if ~isempty(obj.videoSaveDir)
					movieSavePathBase = strcat(obj.videoSaveDir,filesep,'subjectMovieFrames');
					if (~exist(movieSavePathBase,'dir')) mkdir(movieSavePathBase); end;
					movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.h5');
					[output] = writeHDF5Data(subjectMovieFrames,movieSavePath);
					movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.tiff');
					options.comp = 'no';
                    options.overwrite = true;
					movieSavePath
					saveastiff(subjectMovieFrames, movieSavePath, options);
				end

				MIJ.createImage(thisSubjectStr{1}, subjectMovieFrames, true);
				% pause
			end
			uiwait(msgbox('press OK to finish','Success','modal'));
			MIJ.run('Close All Without Saving');
		case 2
			[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
			for thisFileNumIdx = 1:nFilesToAnalyze
				try
					thisFileNum = fileIdxArray(thisFileNumIdx);
					obj.fileNum = thisFileNum;
					display(repmat('=',1,21))
					% display([num2str(thisFileNum) '/' num2str(length(fileIdxArray)) ': ' obj.fileIDNameArray{obj.fileNum}]);
					dispStr = [num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.folderBaseSaveStr{obj.fileNum}];
					display(dispStr);
					% validManualIdx = find(arrayfun(@(x) isempty(x{1}),obj.validManual));
					% classifyFoldersIdx = intersect(validFoldersIdx,validManualIdx);
					movieList = getFileList({obj.inputFolders{obj.fileNum}}, fileFilterRegexp);
					cellfun(@display,movieList);
					subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',frameList);
					% movieFrame = squeeze(movieFrame(:,:,1));
					subjectMovieFrames = subjectMovieFrames(:,:,1:2:end);

					if normalizeMovieSwitch==1
						[subjectMovieFrames] = normalizeVector(single(subjectMovieFrames),'normRange','zeroToOne');
						[subjectMovieFrames] = normalizeMovie(subjectMovieFrames,'normalizationType','meanSubtraction');
					end

					if ~isempty(obj.videoSaveDir)
						movieSavePathBase = strcat(obj.videoSaveDir,filesep,'subjectMovieFrames');
						if (~exist(movieSavePathBase,'dir')) mkdir(movieSavePathBase); end;
						movieSavePath = strcat(movieSavePathBase,filesep,obj.folderBaseSaveStr{obj.fileNum},'.h5');
						[output] = writeHDF5Data(subjectMovieFrames,movieSavePath);
						movieSavePath = strcat(movieSavePathBase,filesep,obj.folderBaseSaveStr{obj.fileNum},'.tiff');
						options.comp = 'no';
						display(['saving: ' movieSavePath])
						saveastiff(subjectMovieFrames, movieSavePath, options);
					end
					dispStr = [' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.folderBaseSaveStr{obj.fileNum}];
					MIJ.createImage(dispStr, subjectMovieFrames, true);
					for foobar=1:3; MIJ.run('In [+]'); end
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
				% pause
			end
			uiwait(msgbox('press OK to finish','Success','modal'));
			MIJ.run('Close All Without Saving');

		case 3
			[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
			movieListAll = {};
			primaryMovie = {};
			for thisFileNumIdx = 1:nFilesToAnalyze
				thisFileNum = fileIdxArray(thisFileNumIdx);
				obj.fileNum = thisFileNum;
				display(repmat('=',1,21))
				identifyingText{thisFileNumIdx} = obj.subjectStr{obj.fileNum};
				movieList = getFileList({obj.inputFolders{obj.fileNum}}, fileFilterRegexp);
				primaryMovie{thisFileNumIdx} = single(loadMovieList(movieList,'convertToDouble',0,'frameList',frameList));

				% movieListAll = {movieListAll{:} movieList{:}};
			end
			% subjectMovieFrames
			[primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',identifyingText,'normalizeMovies', zeros([length(primaryMovie) 1]),'singleRowMontage',0);
			if ~isempty(obj.videoSaveDir)
				movieSavePathBase = strcat(obj.videoSaveDir,filesep,'subjectMovieFrames');
				if (~exist(movieSavePathBase,'dir')) mkdir(movieSavePathBase); end;
				movieSavePath = strcat(movieSavePathBase,filesep,obj.folderBaseSaveStr{obj.fileNum},'.h5');
				[output] = writeHDF5Data(primaryMovie,movieSavePath);
				movieSavePath = strcat(movieSavePathBase,filesep,obj.folderBaseSaveStr{obj.fileNum},'.tiff');
				options.comp = 'no';
				display(['saving: ' movieSavePath])
				saveastiff(primaryMovie, movieSavePath, options);
            end
            disp(identifyingText)
            MIJ.createImage('Montage', primaryMovie, true);
            % for foobar=1:3; MIJ.run('In [+]'); end
            uiwait(msgbox('press OK to finish','Success','modal'));
			MIJ.run('Close All Without Saving');
		case 4
			[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
			for thisSubjectStr = subjectList
				try
					display(repmat('=',1,7))
					fprintf('Subject %s', thisSubjectStr{1});
					validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
					validFoldersIdx = intersect(fileIdxArray,validFoldersIdx);
					if isempty(validFoldersIdx)
						display('Skipping...')
						continue;
					end
					subjectMovieFrames = [];
					for folderNo = 1:length(validFoldersIdx)
						display('===')
						thisFileNum = validFoldersIdx(folderNo);
						obj.fileNum = thisFileNum;
						[inputSignals inputImages signalPeaks signalPeakIdx valid] = modelGetSignalsImages(obj,'returnType','raw');
						if isempty(inputSignals);display('no input signals');continue;end

						inputImages = thresholdImages(inputImages,'binary',0,'getBoundaryIndex',0,'threshold',0.4,'imageFilter','none');

						goodImages = inputImages(:,:,logical(valid));
						goodImages = nanmax(goodImages,[],3);

						badImages = inputImages(:,:,~logical(valid));
						badImages = nanmax(badImages,[],3);
						[sum(valid) size(goodImages) NaN size(inputImages)]
						goodImages = goodImages + 0.5*badImages;

						% [goodImages] = viewAddTextToMovie(goodImages,obj.assay{obj.fileNum},12);
						try
							size(subjectMovieFrames)
							size(goodImages)
							subjectMovieFrames(:,:,folderNo) = goodImages;
						catch err
							subjectMovieFrames(:,:,folderNo) = NaN;
							display(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							display(repmat('@',1,7))
						end

						try
							[subjectMovieFrames(:,:,folderNo)] = viewAddTextToMovie(subjectMovieFrames(:,:,folderNo),obj.assay{obj.fileNum},12);
						catch err
							display(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							display(repmat('@',1,7))
						end
					end

					% subjectMovieFrames

					% validManualIdx = find(arrayfun(@(x) isempty(x{1}),obj.validManual));
					% classifyFoldersIdx = intersect(validFoldersIdx,validManualIdx);
					% movieList = getFileList({obj.inputFolders{validFoldersIdx}}, fileFilterRegexp);
					% movieList
					% subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',frameList);
					% movieFrame = squeeze(movieFrame(:,:,1));
					% subjectMovieFrames = subjectMovieFrames(:,:,1:2:end);
					% if normalizeMovieSwitch==1
					% 	[subjectMovieFrames] = normalizeVector(single(subjectMovieFrames),'normRange','zeroToOne');
					% 	[subjectMovieFrames] = normalizeMovie(subjectMovieFrames,'normalizationType','meanSubtraction');
					% end

					if ~isempty(obj.videoSaveDir)
						movieSavePathBase = strcat(obj.videoSaveDir,filesep,'subjectMovieFrames');
						if (~exist(movieSavePathBase,'dir')) mkdir(movieSavePathBase); end;

						movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.h5');
						[success] = saveMatrixToFile(subjectMovieFrames,movieSavePath);

						movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.tiff');
						[success] = saveMatrixToFile(subjectMovieFrames,movieSavePath);
					end

					MIJ.createImage(thisSubjectStr{1}, subjectMovieFrames, true);
					% pause
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
			uiwait(msgbox('press OK to finish','Success','modal'));
			MIJ.run('Close All Without Saving');
		otherwise
			% body
	end
	MIJ.exit;
end