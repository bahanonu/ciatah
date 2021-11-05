function [inputMoviePathProcessed,inputMoviePathProcessedDownsample] = runPreprocessing(inputMovie,varargin)
	% Biafra Ahanonu
	% Runs pre-processing on a raw imaging movie
	% Started September 2018
	% inputs
		% inputMovie - char str, path to folder containing file to process
	% outputs
		%

	% changelog
		% 2020.05.13 [08:03:08] - Change normalization frequency.
		% 2020.10.14 [13:30:04] - Additional updates to deal with various user inputs.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% Str: regular expression indicating file to use
	options.rawFileRegexp = 'concat';
	% 1 = only get movie paths and don't process
	options.getMoviePathsOnly = 0;
	% dfof or dfstd
	options.dfofType = 'dfof';
	% Binary: 1 = dF/F the inputMovie
	options.dfofMovie = 1;
	% Int: amount to downsample movie in space
	options.downsampleSpaceFactor = 1;
	% Int: amount to downsample the movie in time
	options.downsampleTimeFactor = 4;
	% Binary: 1 - Run motion correction on the movie
	options.motionCorrectionFlag = 1;
	% Binary: 1 - Use the motion correction GUI
	options.motionCorrectionGUI = 1;
	% Vector: input motion correction coordinates, [xTopLeft yTopLeft xBottomRight yBottomRight]
	options.motionCorrectionCropCoords = [];
	% Normalization OPTS
		% Binary: 1 - remove background fluctuations in the movie
		options.normalizeMovieFlag = 1;
		% Str: fft,bandpassDivisive,lowpassFFTDivisive,imfilterSmooth,imfilter,meanSubtraction,meanDivision,negativeRemoval
		options.normalizeType = 'divideByLowpass';
		% Int: Low frequencies for normalization
		options.freqLow = 0;
		% Int: High frequencies for normalization
		options.freqHigh = 7;
	% Char:
		% lexicographic (e.g. 1 10 11 2 21 22 unless have 01 02 10 11 21 22)
		% numeric (e.g. 1 2 10 11 21 22)
		% natural (e.g. 1 2 10 11 21 22)
	options.listSortMethod = 'natural';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	startTime = tic;

	if ~isempty(options.motionCorrectionCropCoords)
		options.motionCorrectionGUI = 0;
	end

	if ischar(inputMovie)||iscell(inputMovie)
		inputIsStr = 1;
		% Get list of files, sort in natural order (e.g. 1, 2, 10 vs. 1, 10, 2)
		listOfFiles = getFileList(inputMovie,options.rawFileRegexp,'sortMethod',options.listSortMethod);
		% Get folder information
		[PATHSTR,NAME,EXT] = fileparts(listOfFiles{1});
		[~,folderName,~] = fileparts(PATHSTR);

		% Get filename flags for processing
		processStr = ['_' options.dfofType];
		if options.normalizeMovieFlag==1
			processStr = ['_normalized' processStr];
		end
		if options.motionCorrectionFlag==1
			processStr = ['_turboreg' processStr];
		end
		if options.downsampleSpaceFactor>1
			processStr = ['_downsampleSpace' processStr];
		end
		inputMoviePathProcessed = [PATHSTR filesep folderName processStr '.h5'];
	else
		inputIsStr = 0;
	end

	% Run first type of pre-processing
	if inputIsStr==0||(exist(inputMoviePathProcessed,'file')~=2&&options.getMoviePathsOnly==0)
		% Crop the FOV for motion correction to save time and avoid edge effects
		cropCoords = subfxnMotionCorrectionCrop();

		if inputIsStr==1
			% Load all files and concatenate into one large file
			inputMovie = loadMovieList(listOfFiles,'inputDatasetName',options.inputDatasetName);
		else
			% inputMovie = inputMovie;
		end

		% Downsample in space
		if options.downsampleSpaceFactor>1
			subfxnDownsampleSpace();
		end

		% motion correct then normalize else just normalize
		if options.motionCorrectionFlag==1
			subfxnMotionCorrection();
		elseif options.normalizeMovieFlag==1
			subfxnNormalizeMovie();
		end

		% dfof
		if options.dfofMovie==1
			subfxnDfofMovie();
		else
			disp(['Skip ' options.dfofType]);
		end

		% save processed movie
		if inputIsStr==1
			saveMatrixToFile(inputMovie,inputMoviePathProcessed,'inputDatasetName',options.inputDatasetName,'deflateLevel',1);
		else
			inputMoviePathProcessed = inputMovie;
		end
	else
		fprintf('Already processed %s\n',inputMoviePathProcessed)
	end

	% Downsample in time, dfof, save
	if inputIsStr==1
		if options.downsampleTimeFactor==1
			disp('No downsample in time')
			processStr = [processStr '_downsampleTime'];
			inputMoviePathProcessedDownsample = [PATHSTR filesep folderName processStr '.h5'];
		else
			processStr = [processStr '_downsampleTime'];
			inputMoviePathProcessedDownsample = [PATHSTR filesep folderName processStr '.h5'];
			if exist(inputMoviePathProcessedDownsample,'file')~=2&&options.getMoviePathsOnly==0
				subfxnDownsampleTime();
				saveMatrixToFile(inputMovie,inputMoviePathProcessedDownsample,'inputDatasetName',options.inputDatasetName,'deflateLevel',1);
			else
				fprintf('Already processed %s\n',inputMoviePathProcessedDownsample)
			end
		end
	else
		if options.downsampleTimeFactor==1
			inputMoviePathProcessedDownsample = [];
		else
			subfxnDownsampleTime();
			inputMoviePathProcessedDownsample = inputMovie;
		end
	end

	endTime = toc(startTime);
	fprintf('Pre-processing took %.1f minutes\n\n',endTime/60)

	function subfxnDownsampleTime()
		inputMovie = downsampleMovie(inputMovie,'downsampleDimension','time','downsampleFactor',options.downsampleTimeFactor);
	end

	function subfxnDfofMovie()
		inputMovie = dfofMovie(single(inputMovie),'dfofType',options.dfofType);
	end
	function cropCoords = subfxnMotionCorrectionCrop()
		if options.downsampleSpaceFactor>1&options.motionCorrectionFlag==1&options.motionCorrectionGUI==1
			inputMovieT = loadMovieList(listOfFiles,'inputDatasetName',options.inputDatasetName,'frameList',1:2);
			% Downsample in space
			inputMovieT = downsampleMovie(inputMovieT,'downsampleDimension','space','downsampleFactor',options.downsampleSpaceFactor);
			[cropCoords] = getCropCoords(squeeze(inputMovieT(:,:,1)));
		elseif options.motionCorrectionGUI==1&options.motionCorrectionFlag==1
			if inputIsStr==0
				[cropCoords] = getCropCoords(inputMovie(:,:,1));
			else
				[cropCoords] = getCropCoords(listOfFiles);
			end
		else
			cropCoords = options.motionCorrectionCropCoords;
			if options.downsampleSpaceFactor>1
				cropCoords = round(cropCoords/options.downsampleSpaceFactor);
			end
		end
		% Make sure coordinates don't fall outside movie
		cropCoords = max(cropCoords,1);
	end
	function subfxnDownsampleSpace()
		inputMovie = downsampleMovie(inputMovie,'downsampleDimension','space','downsampleFactor',options.downsampleSpaceFactor);
	end
	function subfxnMotionCorrection()
		if ismac
		    % Code to run on Mac platform
		    toptions.registrationFxn = 'imtransform';
		elseif isunix
		    % Code to run on Linux platform
		    toptions.registrationFxn = 'imtransform';
		elseif ispc
		    % Code to run on Windows platform
		    toptions.registrationFxn = 'transfturboreg';
		else
			return;
		    disp('Platform not supported')
		end
		toptions.cropCoords = cropCoords;
		toptions.turboregRotation = 0;
		toptions.removeEdges = 1;
		toptions.pxToCrop = 10;
		toptions.complementMatrix = 1;
		toptions.meanSubtract = 1;
		toptions.meanSubtractNormalize = 1;
		toptions.normalizeType = 'matlabDisk';
		toptions.normalizeBeforeRegister = options.normalizeType;
		toptions.freqLow = options.freqLow;
		toptions.freqHigh = options.freqHigh;
		[inputMovie, ~] = turboregMovie(inputMovie,'options',toptions);
	end
	function subfxnNormalizeMovie()
		if ~isempty(options.normalizeType)
			switch options.normalizeType
				case 'imagejFFT'
					imagefFftOnInputMovie('inputMovie');
				case 'divideByLowpass'
					display('dividing movie by lowpass...')
					% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
					inputMovie = normalizeMovie(single(inputMovie),'normalizationType','lowpassFFTDivisive','freqLow',options.freqLow,'freqHigh',options.freqHigh,'waitbarOn',1,'bandpassMask','gaussian');
					% [inputMovie] = normalizeMovie(single(inputMovie),...
						% 'normalizationType','lowpassFFTDivisive',...
						% 'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
						% 'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
				case 'bandpass'
					display('bandpass filtering...')
					inputMovie = single(inputMovie);
					[inputMovie] = normalizeMovie(single(inputMovie),'normalizationType','fft','freqLow',options.freqLow,'freqHigh',options.freqHigh,'bandpassType','bandpass','showImages',0,'bandpassMask','gaussian');
				otherwise
					% do nothing
			end
		end
	end

end