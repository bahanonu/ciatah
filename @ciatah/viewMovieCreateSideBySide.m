function obj = viewMovieCreateSideBySide(obj)
	% Align signal to a stimulus and display images.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	% =====================
	% fileFilterRegexp = obj.fileFilterRegexp;
	FRAMES_PER_SECOND = obj.FRAMES_PER_SECOND;
	% DOWNSAMPLE_FACTOR = obj.DOWNSAMPLE_FACTOR;
	% =====================
	% if strcmp(obj.analysisType,'group')
	% 	nFiles = length(obj.rawSignals);
	% else
	% 	nFiles = 1;
	% end
	% =====================
	movieSettings = inputdlg({...
		'start:end frames (leave blank for all)',...
		'behavior:movie sample rate (downsample factor): ',...
		'imaging movie regexp:',...
		'video folder(s), separate multiple folders by a comma:',...
		'side-by-side save folder:',...
		'rotate second movie?',...
		'save movie type (hdf5 or tiff)',...
		'division factor behavior movie',...
		'normalize before combining? 0=no, 1=yes'},...
		'downsample settings',1,{...
		'1:500',...
		num2str(obj.DOWNSAMPLE_FACTOR),...
		obj.fileFilterRegexp,...
		obj.videoDir{1},....
		obj.videoSaveDir,...
		'0',...
		'hdf5',...
		'10',...
		'0'});

	frameList = str2num(movieSettings{1});
	DOWNSAMPLE_FACTOR = str2num(movieSettings{2});
	obj.fileFilterRegexp = movieSettings{3}; fileFilterRegexp = obj.fileFilterRegexp;
	obj.videoDir = movieSettings{4}; videoDir = obj.videoDir;
	obj.videoSaveDir = movieSettings{5}; videoSaveDir = obj.videoSaveDir;
	rotateSecondMovie = str2num(movieSettings{6});
	saveMovieType = movieSettings{7};
	behaviorMovieDivisionFactor = str2num(movieSettings{8});
	normalizeMovies = str2num(movieSettings{9});
	% =====================
	videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','yymmdd_mNNN_assayNN','subject_assay'};
	scnsize = get(0,'ScreenSize');
	[videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
	% % =====================
	[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			% display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.fileIDNameArray{obj.fileNum}]);
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			% subject = obj.subjectNum{obj.fileNum};
			% assay = obj.assay{obj.fileNum};
			% =====================
			% frameList
			movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			[imagingMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',frameList(:));
			if ~isempty(videoDir)
				if isempty(frameList)
					frameListTmp = 1:size(imagingMovie,3);
					% frameListTmp = 1:min(cellfun(@(x) size(x,3), primaryMovie));
				else
					frameListTmp = frameList;
				end
				videoTrialRegExp = local_getVideoRegexp();
				% videoTrialRegExp
				vidList = getFileList(videoDir,videoTrialRegExp);
				if ~isempty(vidList)
					% get the movie
					% vidList
					behaviorMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListTmp(:)*DOWNSAMPLE_FACTOR,'treatMoviesAsContinuous',1);
					% behaviorMovie = createMovieMontage(behaviorMovie,nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,0);
					% [behaviorMovie] = createSideBySide(behaviorMovie,imagingMovie,'pxToCrop',[],'rotateSecondMovie',rotateSecondMovie);
					[behaviorMovie] = normalizeVector(single(behaviorMovie),'normRange','zeroToOne');
					[behaviorMovie] = normalizeMovie(behaviorMovie,'normalizationType','meanSubtraction');
					behaviorMovie = behaviorMovie/behaviorMovieDivisionFactor;

					[behaviorMovie] = createSideBySide(imagingMovie,behaviorMovie,'pxToCrop',[],'rotateSecondMovie',rotateSecondMovie,'normalizeMovies',normalizeMovies);
					switch saveMovieType
						case 'hdf5'
							savePathName = [videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_sideBySide.h5'];
							[output] = writeHDF5Data(behaviorMovie,savePathName);
						case 'tiff'
							savePathName = [videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_sideBySide.tif'];
							tiffOptions.comp = 'no';
							saveastiff(behaviorMovie, savePathName, tiffOptions);
						otherwise
							% body
					end
				end
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function videoTrialRegExp = local_getVideoRegexp()
		switch videoTrialRegExpIdx
			case 1
				videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			case 2
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
			case 3
				videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
			otherwise
				videoTrialRegExp = fileFilterRegexp
		end
	end
end