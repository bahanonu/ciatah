function obj = viewMovieFiltering(obj)
	% Allows testing of spatial filtering.
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

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	movieSettings = inputdlg({...
			'start:end frames (leave blank for all)',...
			'FFT filter type (bandpass, lowpass, highpass)',...
			'FFT filter mask type (gaussian or binary)',...
			'movie regular expression',...
			'HDF5 dataset name',...
			'Show division and dfof of movie'...
		},...
		'Settings for movie spatial filtering check',[1 100],...
		{...
			'1:25',...
			'bandpass',...
			'gaussian',...
			'concat',...
			'/1',...
			'1'...
		}...
	);
	frameList = str2num(movieSettings{1});
	% options.normalizeFreqLow = str2num(movieSettings{1});
	% options.normalizeFreqHigh = str2num(movieSettings{1});
	options.normalizeBandpassType = movieSettings{2};
	options.normalizeBandpassMask = movieSettings{3};
	fileFilterRegexp = movieSettings{4};
	inputDatasetName = movieSettings{5};
	testDuplicateDfof = str2num(movieSettings{6});

	% loop over all directories and copy over a specified chunk of the movie file
	for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum} 10 obj.inputFolders{obj.fileNum}]);
			movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			movieList = movieList{1};

			% get list of frames and correct for user input
			if isempty(frameList)
				frameListTmp = frameList;
			else
				movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName,'getMovieDims',1);
				nMovieFrames = sum(movieDims.z);
				display(['movie frames: ' num2str(nMovieFrames)]);
				if nMovieFrames<nanmax(frameList)
					frameListTmp = frameList;
					frameListTmp(frameListTmp>nMovieFrames) = [];
				else
					frameListTmp = frameList;
				end
			end

			% get movie, normalize, and display
			[primaryMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',frameListTmp(:),'inputDatasetName',inputDatasetName);
			primaryMovie = single(primaryMovie);

			stopTesting = 1;
			while ~isempty(stopTesting)
				[inputMovieNormalized] = normalizeMovie(primaryMovie,'normalizationType','matlabFFT_test','bandpassType',options.normalizeBandpassType,'bandpassMask',options.normalizeBandpassMask,'testDuplicateDfof',testDuplicateDfof);

				playMovie(inputMovieNormalized,'colormapColor','gray');

				stopTesting = strmatch(questdlg('Repeat?', ...
					'Run filtering for this movie again?', ...
					'yes','no','yes'),'yes');
			end
	end

end