function [inputMovie, ResultsOutOriginal] = turboregMovie(inputMovie, varargin)
	% [inputMovie, ResultsOutOriginal] = turboregMovie(inputMovie, varargin)
	%
	% Motion corrects (using turboreg, NoRMCorre, displacement fields, etc.) a movie.
	% 	- Both turboreg (to get 2D translation coordinates) and registering images (transfturboreg, imwarp, imtransform) have been parallelized.
	% 	- Can also turboreg to one set of images and apply the registration to another set (e.g. for cross-day alignment).
	% 	- Spatial filtering is applied after obtaining registration coordinates but before transformation, this reduced chance that 0s or NaNs at edge after transformation mess with proper spatial filtering.
	%
	% Biafra Ahanonu
	% started 2013.11.09 [11:04:18]
	%
	% Parts of code based on that from Jerome Lecoq (2011) and parallel code update by Biafra Ahanonu (2013).
	%
	% Input
	% 	inputMovie - 3D matrix: [x y frames] matrix containing data to be motion corrected across frames.
	%
	% Output
	% 	inputMovie - 3D matrix: [x y frames] matrix containing data after motion correction across frames.
	% 	ResultsOutOriginal
	% 		TurboReg - Cell array {1 frames}: contains the motion correction data for each frame for later use.
	% 		NoRMCorre - Structure: contains the motion correction data for each frame for later use.

	% changelog
		% 2013.03.29 - parallelizing turboreg v1
		% 2013.11.09 - completed implementation, appears to work for basic case of a normal MxNxP movie. Need to test on full movie that has a lot of movement to verify and check that it is similar to imageJ. Fixed various naming issues and parfor can now show the percentage
		% 2013.11.10 - refactored so that it can now more elegantly handle larger movies during parallelization by chunking
		% 2013.11.30 - late update, but had also changed actual turbo-reg calling to be chunked
		% 2014.01.07 [01:29:02] - now modify 'local' matlabpool config to suit correct number of cores
		% 2014.01.18 [22:36:54] - now (correctly) surrounds the edges with black pixels to avoid screen flickering. NEEDS TO BE IMPROVED.
		% 2014.01.19 [15:50:23] - slight refactoring to improve memory usage.
		% 2014.01.20 [13:19:13] - added mean subtraction and imcomplement to allow for better turboreg
		% 2014.01.28 [17:36:42] - added feature to register a different movie than was turboreged, mainly used for obj aligning after registering global maps.
		% 2014.08.28 [15:01:04] - nested functions for turboreg and register
		% 2016.01.16 [19:38:08] - Added additional normalization options
		% 2016.09.xx - parallel switch now forces parfor to not open up a parallel pool of workers if switch = 0
		% 2019.01.15 [15:59:21] - Remove NaNs from inputMovie when using precomputedRegistrationCooords.
		% 2020.04.18 [19:04:13] - Update creation of xform to by default include rotation along with translation and skew.
		% 2020.08.18 [12:56:10] - Remove references to parfor_progress.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.09.11 [10:40:05] - Additional matlab disk normalizeType options.
		% 2021.11.01 [12:15:10] - Additional display of information.
		% 2021.11.16 [11:58:14] - Added verification that turboreg MEX function is in the path.
		% 2022.01.22 [20:46:51] - Refactor code to remove need to transform movie into cell array, performance and memory improvements.
		% 2022.03.08 [12:23:53] - Added NoRMCorre support, function will eventually be merged with "registerMovie" or renamed to indicate support for multiple algorithms. Reason to integrate NoRMCorre into this function is takes advantage of existing pre-processing pipeline and integration with other algorithms (e.g. cross-session).
		% 2022.03.09 [16:34:47] - Check if inputs are sparse, convert to single.
		% 2022.03.09 [17:32:42] - Use custom bahanonu NoRMCorre that is within a package and update to use reference picture instead of template.
		% 2022.04.23 [18:40:22] - Updated to which('normcorre.normcorre') from which('normcorre') since normcorre now inside a package.
		% 2022.09.12 [20:46:04] - Additional NoRMCorre support and getNoRMCorreParams checking before running NoRMCorre.
		% 2022.09.24 [18:32:04] - Changes to GUI display.
		% 2022.10.03 [18:20:34] - Correct user options input to normcorre.apply_shifts.
		% 2022.11.15 [14:16:40] - Add displacement field-based motion correction.
		% 2022.11.22 [15:34:27] - Add back in ability to remove NaNs from each frame before calculating shifts or displacements.
		% 2022.12.05 [18:35:05] - Add support for gradient-based filtering for motion correction input.
		% 2023.08.04 [07:34:45] - Support loading of prior coordinates from MAT-file in standard of modelPreprocessMovieFunction.
		% 2024.02.18 [18:46:34] - Added additional options for displacement field-based motion correction.
		% 2024.03.11 [20:53:19] - Update to row assignment for removeInputMovieEdges.
	% TO-DO
		% Add support for "imregtform" based registration.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% Using a compiled version of the ANSI C code developed by Philippe Thevenaz.
	%
	% It uses a MEX file as a gateway between the C code and MATLAB code. All C codes files are available in subfolder 'C'. The interface file is 'turboreg.c'. The main file from Turboreg is 'regFlt3d.c'. Original code has been modified to move new image calculation from C to Matlab to provide additional flexibility.
	% ========================
	% NOTES
		% If you get error on the availability of turboreg, please consider creating the mex file for your system using the following command in the C folder : mex turboreg.c regFlt3d.c svdcmp.c reg3.c reg2.c reg1.c reg0.c quant.c pyrGetSz.c pyrFilt.c getPut.c convolve.c BsplnWgt.c BsplnTrf.c phil.c
		% If getting blank frames with transfturboreg, install Visual C++ Redistributable Packages for Visual Studio 2013 (http://www.microsoft.com/en-us/download/details.aspx?id=40784)
		% See https://github.com/bahanonu/calciumImagingAnalysis/wiki/Preprocessing:-Motion-Correction#compiling-turboreg-and-transfturboreg-mex-file.
	% ========================

	% Check that input is not empty
	if isempty(inputMovie)
		disp('Empty movie matrix, exiting motion correction...')
		return;
	end

	% ========================
	% get options
	% =======IMPORTANT OPTIONS=====
	% Str: motion correction algorithm.
		% 'turboreg' - TurboReg as developed by Philippe Thevenaz.
		% 'normcorre' - NoRMCorre as developed by several authors at Flatiron Institute.
		% 'imregdemons' - Displacement field alignment based on imregdemons.
	options.mcMethod = 'turboreg';
	% options.mcMethod = 'normcorre';
	% Str: dataset name in HDF5 file where data is stored, if inputMovie is a path to a movie.
	options.inputDatasetName = '/1';
	% Int vector: if loading movie inside function, provide frameList to load specific frames
	options.frameList = [];
	% Int: which frame in the inputMovie to use as a reference to register all other frames to.
	options.refFrame = 1;
	% Matrix: same type as the inputMovie, this will be appended to the end of the movie and used as the reference frame. This is for cases in which the reference frame is not contained in the movie.
	options.refFrameMatrix = [];
	% Str: Register images using 'imtransform' or 'imwarp' (Matlab) or 'transfturboreg' (C)
	options.registrationFxn = 'transfturboreg';
	% Binary: 1 = remove NaNs before computing transform/displacement matrix, 0 = do not alter NaN state.
	options.removeNan = 0;
	% Float: any numeric value to replace NaNs with if options.removeNan==1.
	options.nanReplaceVal = 0;
	% display options for verification of input
	options.displayOptions = 0;
	% character string, path to save turboreg coordinates
	options.saveTurboregCoords = [];
	% already have registration coordinates
	options.precomputedRegistrationCooords = [];
	% already have registration coordinates
	options.precomputedRegistrationCooordsFullMovie = [];
	% =======TURBOREG OPTIONS=======
		% =======
		% SETTINGS
		% zapMean - If 'zapMean' is set to 'FALSE', the input data is left untouched. If zapMean is set to 'TRUE', the test data is modified by removing its average value, and the reference data is also modified by removing its average value prior to optimization.
		% minGain - An iterative algorithm needs a convergence criterion. If 'minGain' is set to '0.0', new tries will be performed as long as numerical accuracy permits. If 'minGain' is set between '0.0' and '1.0', the computations will stop earlier, possibly to the price of some loss of accuracy. If 'minGain' is set to '1.0', the algorithm pretends to have reached convergence as early as just after the very first successful attempt.
		% epsilon - The specification of machine-accuracy is normally machine-dependent. The proposed value has shown good results on a variety of systems; it is the C-constant FLT_EPSILON.
		% levels - This variable specifies how deep the multi-resolution pyramid is. By convention, the finest level is numbered '1', which means that a pyramid of depth '1' is strictly equivalent to no pyramid at all. For best registration results, the rule of thumb is to select a number of levels such that the coarsest representation of the data is a cube between 30 and 60 pixels on each side. Default value ensure that values
		% lastLevel - It is possible to short-cut the optimization before reaching the finest stages, which are the most time-consuming. The variable 'lastLevel' specifies which is the finest level on which optimization is to be performed. If 'lastLevel' is set to the same value as 'levels', the registration will take place on the coarsest stage only. If 'lastLevel' is set to '1', the optimization will take advantage of the whole multi-resolution pyramid.
		% =======
		% Int: Registration type.
			% affine (parallelism maintained)
			% projective (parallelism not guaranteed)
			% See https://www.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html.
			% Int values and meaning
			% 1 - affine,     no rotation, no skew
			% 2 - affine,     rotation,    no skew
			% 3 - projective, rotation,    no skew
			% 4 - affine,     no rotation, skew
			% 5 - projective, rotation,    no skew
		options.RegisType = 3;
		% Int: amount of smoothing along the x and y respectively. They give the half-width of a recursive Gaussian smoothing window.
		options.SmoothX = 80;%10
		options.SmoothY = 80;%10
		% Float: Between 0 and 1.
		options.minGain = 0.0; %0.4;
		% Int
		options.Levels = nestFxnCalculatePyramidDepth(min(size(inputMovie,1),size(inputMovie,2)));
		% Int
		options.Lastlevels = 1;
		% Float
		options.Epsilon = 1.192092896E-07;
		% Binary
		options.zapMean = 0;
		% Str: type of interpolation to use.
		options.Interp = 'bilinear'; %'bicubic'
	% =======NORMAL OPTIONS=======
	% DEPRECATED, see options.RegisType. 1 = take turboreg rotation, 0 = no rotation
	options.turboregRotation = 1;
	% max number of frames in the input matrix
	options.maxFrame = [];
	% number of frames to subset when registering
	options.subsetSizeFrames = 2000;
	% use parallel registration (using matlab pool)
	options.parallel = 1;
	% close the matlab pool after running?
	options.closeMatlabPool = 0;
	% add a black edge around movie
	options.blackEdge = 0;
	% Int vector: coordinates to crop, [] = entire FOV, 'manual' = usr input, [top-left-row top-left-col bottom-right-row bottom-right-col]
	options.cropCoords = [];
	% Binary: 1 = remove the edges of the movie
	options.removeEdges = 0;
	% Int: amount of pixels around the border to crop in primary movie (inputMovie)
	options.pxToCrop = 4;
	% alternative movie to register
	options.altMovieRegister = [];
	% which coordinates to register alternative movie to, number 2 since normally first cell is the reference turboreg coordinates
	options.altMovieRegisterNum = 2;
	% should a complement (inversion) of each frame be made?
	options.complementMatrix = 1;
	% Binary: 1 = run normalize movie methods
	options.meanSubtract = 0;
	% Binary: 1 = subtract the mean from each frame.
	options.meanSubtractNormalize = 0;
	% String: imagejFFT,matlabDisk,divideByLowpass,highpass,bandpass
	options.normalizeType = 'divideByLowpass';
	% Int: normalizeType=matlabDisk, size of disk to substract from frame (min dimension size/this parameter) so smaller = larger spatial filter.
	options.matlabdiskR1 = 10;
	% Int: normalizeType=matlabDisk, size of disk to blur frame.
	options.matlabdiskR2 = 3;
	% =======
	% Binary: 1 = bandpass after turboreg but before registering
	options.bandpassBeforeRegister = 0;
	% String: imagejFFT, divideByLowpass, bandpass. Normalize movie (highpass, etc.) before registering
	options.normalizeBeforeRegister = [];
	% imageJ normalization options
	options.imagejFFTLarge = 10000;
	options.imagejFFTSmall = 80;
	% for preprocessing matlab filtering
	options.normalizeFreqLow = 40;
	options.normalizeFreqHigh = 100;
	% highpass, lowpass, bandpass
	options.normalizeBandpassType = 'bandpass';
	% binary or gaussian
	options.normalizeBandpassMask = 'gaussian';
	% whether to save the lowpass version before registering, empty if no, string with file path if yes
	options.saveNormalizeBeforeRegister = [];
	% for options.bandpassBeforeRegister
	options.freqLow = 1;
	options.freqHigh = 4;
	% =======
	% 1 = show figures during processing
	options.showFigs = 1;
	% Binary: 1 = cmd line waitbar on. 0 = waitbar off.
	options.waitbarOn = 1;
	% =======
	% Binary: 1 = return the movie after normalizing, mean subtract, etc.
	options.returnNormalizedMovie = 0;
	% Binary: 1 = run correlation before spatial filtering, 0 = do not run correlation.
	options.computeCorr = 0;
	% =======
	% NoRMCorre
	% Struct: NoRMCorre settings
	options.optsNoRMCorre = ciapkg.motion_correction.getNoRMCorreParams([1 1 1],'guiDisplay',0);
	% =======
	% Displacement fields options (imregdemons)
	% Int: Indicate which displacement fields to remove.
		% [] = include all displacement fields
		% 1 = exclude Y displacement fields
		% 2 = exclude X displacement fields
	options.dfExclude = [];
	% Options for displacement fields
	options.df_AccumulatedFieldSmoothing = 0.54;
	options.df_Niter = [500 400 200];
	options.df_PyramidLevels = 3;
	options.df_DisplayWaitbar = false;
	% =======
	% 
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	if options.displayOptions==1
		fn_structdisp(options)
	end
	% ========================

	fprintf('Starting motion correction (%s)...\n',options.mcMethod);

	% ========================
	% Verify that turboreg MEX function is in the path.
	if isempty(which('turboreg'))==1||isempty(which('normcorre.normcorre'))==1
		% ciapkg.loadBatchFxns();
		ciapkg.loadBatchFxns('removeDirFxnToFindExclude','normcorre.m');
	end

	% ========================
	% Algorithm specific options
	switch options.mcMethod
		case 'turboreg'

		case 'normcorre'
			% NoRMCorre is to be run on the entire input matrix.
			options.cropCoords = [];
		case 'imregdemons'
			% NoRMCorre is to be run on the entire input matrix.
			options.cropCoords = [];
		otherwise

	end

	% ========================
	% check that Miji is present
	if strcmp(options.normalizeType,'imagejFFT')||strcmp(options.normalizeBeforeRegister,'imagejFFT')
		% if exist('Miji.m','file')==2
		% 	disp(['Miji located in: ' which('Miji.m')]);
		% 	% Miji is loaded, continue
		% else
		% 	pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
		% 				 'Miji path', [1 100]);
		% 	if ~isempty(pathToMiji)
		% 		pathToMiji = pathToMiji{1};
		% 		privateLoadBatchFxnsPath = 'private\privateLoadBatchFxns.m';
		% 		fid = fopen(privateLoadBatchFxnsPath,'at')
		% 		fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
		% 		fclose(fid);
		% 	end
		% end
		modelAddOutsideDependencies('miji');
	end
	% ========================
	% Check for sparse inputs
	if issparse(inputMovie)
		disp('Converting from sparse to single.')
		inputMovie = single(full(inputMovie));
	end
	% ========================
	inputMovieClass = class(inputMovie);
	if ischar(inputMovie)
		inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'frameList',options.frameList);
		% [pathstr,name,ext] = fileparts(inputFilePath);
		% options.newFilename = [pathstr '\concat_' name '.h5'];
	end
	options.maxFrame = size(inputMovie,3);
	movieDim = size(inputMovie);
	options.Levels=nestFxnCalculatePyramidDepth(min(movieDim(1),movieDim(2)));

	% inputMovie(isnan(inputMovie)) = 0;
	% ========================
	% add turboreg options to turboRegOptions structure
	turboRegOptions.RegisType = options.RegisType;
	turboRegOptions.SmoothX = options.SmoothX;
	turboRegOptions.SmoothY = options.SmoothY;
	turboRegOptions.minGain = options.minGain;
	turboRegOptions.Levels = options.Levels;
	turboRegOptions.Lastlevels = options.Lastlevels;
	turboRegOptions.Epsilon = options.Epsilon;
	turboRegOptions.zapMean = options.zapMean;
	turboRegOptions.Interp = options.Interp;
	if any(turboRegOptions.RegisType==[1 2 4])
		TransformationType = 'affine';
	else
		% RegisType = [3 5]
		TransformationType = 'projective';
	end
	% ========================
	% Register movie and return without using the rest of the function
	if ~isempty(options.precomputedRegistrationCooords)
		disp('Input pre-computed registration coordinates...')
		ResultsOut = options.precomputedRegistrationCooords;
		ResultsOutOriginal = ResultsOut;
		for resultNo = 1:size(inputMovie,3)
			ResultsOutTemp{resultNo} = ResultsOut{options.altMovieRegisterNum};
		end
		ResultsOut = ResultsOutTemp;
		% Remove NaNs from inputMovie so transfturboreg doesn't run into issue.
		inputMovie(isnan(inputMovie)) = 0;
		% convertInputMovieToCell();
		% size(inputMovie)
		% class(inputMovie)
		% size(inputMovie{1})
		% class(inputMovie{1})
		InterpListSelection = turboRegOptions.Interp;
		registerMovie();

		% Convert back into matrix.
		% inputMovie = cat(3,inputMovie{:});

		ResultsOutOriginal = ResultsOut;
		return;
	end

	% ========================
	% Register movie and return without using the rest of the function
	if ~isempty(options.precomputedRegistrationCooordsFullMovie)
		disp('Input pre-computed registration coordinates for full movie...')

		% Check if MAT-file is input, load into memory
		if ischar(options.precomputedRegistrationCooordsFullMovie)
			disp(['Loading: ' options.precomputedRegistrationCooordsFullMovie])
			loadTmp = load(options.precomputedRegistrationCooordsFullMovie);
			options.precomputedRegistrationCooordsFullMovie = loadTmp.ResultsOutOriginal{1}{1};
		end

		ResultsOut = options.precomputedRegistrationCooordsFullMovie;
		% ResultsOutOriginal = ResultsOut;
		% for resultNo=1:size(inputMovie,3)
		% 	ResultsOutTemp{resultNo} = ResultsOut{options.altMovieRegisterNum};
		% end
		% ResultsOut = ResultsOutTemp;
		% Remove NaNs from inputMovie so transfturboreg doesn't run into issue.
		inputMovie(isnan(inputMovie)) = 0;
		% convertInputMovieToCell();
		% size(inputMovie)
		% class(inputMovie)
		% size(inputMovie{1})
		% class(inputMovie{1})
		InterpListSelection = turboRegOptions.Interp;
		registerMovie();

		% Convert back into matrix.
		% inputMovie = cat(3,inputMovie{:});

		ResultsOutOriginal = ResultsOut;
		return;
	end
	% ========================
	if ~isempty(options.refFrameMatrix)
		inputMovie(:,:,end+1) = options.refFrameMatrix;
		options.refFrame = size(inputMovie,3);
		options.maxFrame = size(inputMovie,3);
		% refPic = single(squeeze(inputMovie(:,:,options.refFrame)));
	else
	end
	% ========================
	% if input crop coordinates are given, save a copy of the uncropped movie and crop the current movie
	inputMovieCropped = [];
	cropAndNormalizeInputMovie();

	if options.returnNormalizedMovie==1
		inputMovie = inputMovieCropped;
		return;
	end
	% ========================
	manageParallelWorkers('parallel',options.parallel);
	%========================
	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D = parallel.pool.DataQueue;
		afterEach(D, @nUpdateParforProgress);
		p = 0;
		nInterval = round(options.maxFrame/30);
		options_waitbarOn = options.waitbarOn;
		nFrames = size(inputMovieCropped,3);
		if nFrames<=(nInterval*2)
			nInterval = 100;
		end
	end
	% ========================
	startTime = tic;
	ResultsOut = {};
	ResultsOutOriginal = {};
	averagePictureEdge = [];
	% [ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovieCropped,turboRegOptions,options);
	turboregMovieParallel();

	if options.computeCorr==1

	end

	if ~isempty(options.saveTurboregCoords)
		disp(options.saveTurboregCoords)
		disp(ResultsOut)
	end
	ResultsOutOriginal = ResultsOut;

	clear inputMovieCropped;
	% ========================
	if ~isempty(options.normalizeBeforeRegister)
		switch options.normalizeBeforeRegister
			case 'imagejFFT'
				imagefFftOnInputMovie('inputMovie');
			case 'divideByLowpass'
				disp('dividing movie by lowpass...')
				% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
				inputMovie = normalizeMovie(single(inputMovie),'normalizationType','lowpassFFTDivisive','freqLow',options.freqLow,'freqHigh',options.freqHigh,'waitbarOn',1,'bandpassMask','gaussian');
				% [inputMovie] = normalizeMovie(single(inputMovie),...
					% 'normalizationType','lowpassFFTDivisive',...
					% 'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
					% 'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
			case 'bandpass'
				disp('bandpass filtering...')
				inputMovie = single(inputMovie);
				[inputMovie] = normalizeMovie(single(inputMovie),'normalizationType','fft','freqLow',options.freqLow,'freqHigh',options.freqHigh,'bandpassType','bandpass','showImages',0,'bandpassMask','gaussian');
			otherwise
				% do nothing
		end
	end
	% ========================
	% if cropped movie for turboreg, restore the old input movie for registration
	if ~isempty(options.altMovieRegister)
		disp(['preparing to register input #' options.altMovieRegisterNum ', converting secondary input movie...'])
		% ===
		% if we are using the turboreg coordinates for frame #options.altMovieRegisterNum to register all frames from options.altMovieRegister, want to give registerMovie an identical sized array to altMovieRegister like it normally expects
		% this was made for having refCellmap and testCellmap, aligning the testCellmap to the refCellmap then registering all the cell images for testCellmap to refCellmap
		ResultsOutTemp = cell([1 size(options.altMovieRegister,3)]);
		for resultNo=1:size(options.altMovieRegister,3)
			ResultsOutTemp{resultNo} = ResultsOut{options.altMovieRegisterNum};
		end
		ResultsOut = ResultsOutTemp;
		% ===
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% add input movie to
		inputMovie = options.altMovieRegister;
		% convertInputMovieToCell();
	elseif ~isempty(options.cropCoords)
		disp('restoring uncropped movie and converting to cell...');
		clear registeredMovie;
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% convertInputMovieToCell();
		% ===
	else
		% disp('converting movie to cell...');
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% convertInputMovieToCell();
		% ===
	end
	% ========================
	% these don't change (???) so pre-define before loop to reduce overhead and make parfor happy
	InterpListSelection = turboRegOptions.Interp;
	toc(startTime)
	% register movie
	% [inputMovie] = registerMovie(inputMovie,ResultsOut,InterpListSelection,TransformationType,options);
	registerMovie();
	% clear movieData;

	% ========================
	%Close the workers
	if options.closeMatlabPool
		manageParallelWorkers('parallel',options.parallel,'openCloseParallelPool','close');
	end
	toc(startTime)

	% ========================
	% disp('converting cell array back to matrix')
	%Convert cell array back to 3D matrix
	% inputMovie = cat(3,inputMovie{:});

	inputMovie = single(inputMovie);
	if options.showFigs==1
		subfxn_dispMovieFrames(inputMovie,'Registration==1',2);
	end
	% ========================
	if options.removeEdges==1
		removeInputMovieEdges();
	end

	toc(startTime)
	if options.blackEdge==1
		addBlackEdgeToMovie();
	end

	if ~isempty(options.refFrameMatrix)
		disp('removing ref picture');
		% inputMovie = inputMovie(:,:,1:end-1);
		inputMovie(:,:,end) = [];
		% refPic = single(squeeze(inputMovie(:,:,options.refFrame)));
	else
		%
	end

	% function subfxnComputeMovieCorr()
	% 	corrMetric
	% 	corrMetric2
	% 	for i =1:size(inputMovie,3);
	% 		thisFrame_cc = inputMovie(cc(2):cc(4),cc(1):cc(3),i);
	% 		corrMetric(i) = corr2(meanG_cc,thisFrame_cc);
	% 		corrMetric2(i) = corr(meanG_cc(:),thisFrame_cc(:),'Type','Spearman');
	% 	end
	% end

	function convertInputMovieToCell()
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);
		% reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end

	function convertinputMovieCroppedToCell()
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovieCropped);
		% reshapeValue = size(inputMovieCropped);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovieCropped = squeeze(mat2cell(inputMovieCropped,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end

	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (mod(p,nInterval)==0||p==1||p==nFrames)&&options_waitbarOn==1
				if p==nFrames
					fprintf('%d%%\n',round(p/nFrames*100))
				else
					fprintf('%d%% | ',round(p/nFrames*100))
				end
				% cmdWaitbar(p,nSignals,'','inputStr','','waitbarOn',1);
			end
			% [p mod(p,nInterval)==0 (mod(p,nInterval)==0||p==nSignals)&&options_waitbarOn==1]
		end
	end

	% function [ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovie,turboRegOptions,options)
	function turboregMovieParallel()
		switch options.mcMethod
			case 'turboreg'
				% get reference picture and other pre-allocation
				postProcessPic = single(squeeze(inputMovieCropped(:,:,options.refFrame)));
				mask = single(ones(size(postProcessPic)));
				imgRegMask = single(double(mask));
				% we add an offset to be able to give NaN to black borders
				averagePictureEdge = zeros(size(imgRegMask));
				refPic = single(squeeze(inputMovieCropped(:,:,options.refFrame)));
				% refPic = squeeze(inputMovieCropped(:,:,options.refFrame));

				MatrixMotCorrDispl = zeros(3,options.maxFrame);

				% ===
				%Convert array to cell array, allows slicing (not contiguous memory block)
				% convertinputMovieCroppedToCell();
				% ===

				% Get data class, can be removed...
				movieClass = class(inputMovieCropped);
				% you need this FileExchange function for progress in a parfor loop
				disp('turboreg-ing...');
				disp('');
				% parallel for loop, since each turboreg operation is independent, can send each frame to separate workspaces
				startTurboRegTime = tic;
				%
				nFramesToTurboreg = options.maxFrame;
				options_removeNan = options.removeNan;
				options_nanReplaceVal = options.nanReplaceVal;
				if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end
				parfor (frameNo=1:nFramesToTurboreg,nWorkers)
					% get current frames
					% thisFrame = inputMovieCropped{frameNo};

					thisFrame = inputMovieCropped(:,:,frameNo);

					thisFrameToAlign=single(thisFrame);
					% thisFrameToAlign=thisFrame;

					if options_removeNan==1
						thisFrame(isnan(thisFrame)) = options_nanReplaceVal;
						thisFrameToAlign(isnan(thisFrameToAlign)) = options_nanReplaceVal;
					end

					if ismac
						% Code to run on Mac platform
						[ImageOut,ResultsOut{frameNo}] = turboreg(refPic,thisFrameToAlign,mask,imgRegMask,turboRegOptions);
						% create a mask
						averagePictureEdge = averagePictureEdge | ImageOut==0;
					elseif isunix
						% Code to run on Linux platform
						[ResultsOut{frameNo}] = turboreg(refPic,thisFrameToAlign,mask,imgRegMask,turboRegOptions);
						% create a mask
						% averagePictureEdge = averagePictureEdge | ImageOut==0;
					elseif ispc
						% Code to run on Windows platform
						[ImageOut,ResultsOut{frameNo}] = turboreg(refPic,thisFrameToAlign,mask,imgRegMask,turboRegOptions);
						% create a mask
						averagePictureEdge = averagePictureEdge | ImageOut==0;
					else
						% return;
						disp('Platform not supported')
					end

					if ~verLessThan('matlab', '9.2')
						send(D, frameNo); % Update
					end
				end
				% dispstat('Finished.','keepprev');
				toc(startTurboRegTime);
				drawnow;
				% save('ResultsOutFile','ResultsOut');
			case 'normcorre'
				startTurboRegTime = tic;
				
				bound = 0;
				refPic = single(squeeze(inputMovieCropped(:,:,options.refFrame)));
				% refPic = refPic(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:);
				inputMovieCroppedTmp = inputMovieCropped(bound/2+1:end-bound/2,bound/2+1:end-bound/2,:);

				optsNoRMCorre = options.optsNoRMCorre;
				if isempty(fieldnames(optsNoRMCorre))
					disp('Getting NoRMCorre params...')
					optsNoRMCorre = ciapkg.motion_correction.getNoRMCorreParams(size(inputMovieCropped),'guiDisplay',0);
				end

				% Ensure NoRMCorre gets the correct inputs
				optsNoRMCorre.d1 = size(inputMovieCropped,1);
				optsNoRMCorre.d2 = size(inputMovieCropped,2);
				disp('===')
				fn_structdisp(optsNoRMCorre)
				optsNoRMCorre.method
				% fn_structdisp(optsNoRMCorre)
				% [optsNoRMCorre2] = subfxn_getNoRMCorreParams(inputMovieCropped);
				% disp('===')
				% fn_structdisp(optsNoRMCorre2)
				% optsNoRMCorre2.method
				disp('===')
				[~,ResultsOut,template2] = normcorre.normcorre_batch(...
					inputMovieCroppedTmp,...
					optsNoRMCorre,...
					refPic);
				clear inputMovieCroppedTmp
				toc(startTurboRegTime);	
			case 'imregdemons'
				disp('Demon-based displacement field registration...')
				nFramesToTurboreg = options.maxFrame;

				fixed = single(squeeze(inputMovieCropped(:,:,options.refFrame)));
				if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end

				df_AccumulatedFieldSmoothing = options.df_AccumulatedFieldSmoothing;
				df_Niter = options.df_Niter;
				df_PyramidLevels = options.df_PyramidLevels;
				df_DisplayWaitbar = options.df_DisplayWaitbar;

				parfor (frameNo=1:nFramesToTurboreg,nWorkers)
					thisFrame = inputMovieCropped(:,:,frameNo);
					moving = single(thisFrame);
					% Niter = df_Niter;
					% AccumulatedFieldSmoothing = df_AccumulatedFieldSmoothing;

					[ResultsOut{frameNo},movingReg] = imregdemons(moving,fixed,...
						df_Niter,...
						'PyramidLevels',df_PyramidLevels,...
						'DisplayWaitbar',df_DisplayWaitbar,...
						'AccumulatedFieldSmoothing',df_AccumulatedFieldSmoothing);

				    if ~verLessThan('matlab', '9.2')
				    	send(D, frameNo); % Update
				    end
				end
				% [Dxy,movingReg] = imregdemons(moving,fixed,Niter,...
				% 'AccumulatedFieldSmoothing',1.3,'DisplayWaitbar',false);
			otherwise
		end
			
	end

	function [optsNC] = subfxn_getNoRMCorreParams(inputMovieHere)
		[d1,d2,T] = size(inputMovieHere);
		bound = 0;
		sizeCorFactor = 1;
		% sizeCorFactor = 1;
		optsNC = normcorre.NoRMCorreSetParms(...
			'd1', d1-bound,...
			'd2', d2-bound,...
			'init_batch',  10,...
			'bin_width',  50,...
			'grid_size', [128,128]/sizeCorFactor,... % [128,128]/2 [64,64]
			'mot_uf', 4,...
			'correct_bidir', false,...
			'overlap_pre', 32,...
			'overlap_post', 32,...
			'max_dev', 50,...
			'use_parallel', true,...
			'print_msg', true,...
			'us_fac', 4,...
			'max_shift', 100,...
			'boundary', 'NaN');
			% 'init_batch_interval',options.refFrame,...
	end

	
	% function registerMovie(movieData,ResultsOut,InterpListSelection,TransformationType,options)
	function registerMovie()
		disp('registering frames...');
		disp('');

		switch options.mcMethod
			case 'imregdemons'
				subsetSize = options.subsetSizeFrames;
				nFramesHere = size(inputMovie,3);
				% numSubsets = ceil(length(inputMovie)/subsetSize)+1;
				numSubsets = ceil(nFramesHere/subsetSize)+1;
				% subsetList = round(linspace(1,length(inputMovie),numSubsets));
				subsetList = round(linspace(1,nFramesHere,numSubsets));
				display(['registering sublists: ' num2str(subsetList)]);
				if options.turboregRotation==1
					disp('Using rotation in registration')
				end
				fprintf('Performing %s registration and %s transformation.\n',options.registrationFxn,TransformationType);
				% ResultsOut{1}.Rotation
				nSubsets = (length(subsetList)-1);
				for thisSet=1:nSubsets
					subsetStartIdx = subsetList(thisSet);
					subsetEndIdx = subsetList(thisSet+1);
					if thisSet==nSubsets
						movieSubset = subsetStartIdx:subsetEndIdx;
						display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
					else
						movieSubset = subsetStartIdx:(subsetEndIdx-1);
						display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
					end

					% Get a slice of the data.
					% movieDataTemp(movieSubset) = inputMovie(movieSubset);
					
					% movieDataTemp = inputMovie(:,:,movieSubset);

					% loop over and register each frame
					if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end

					nMovieSubsets = length(movieSubset);				

					parfor (i = movieSubset,nWorkers)
						rOutTmp = ResultsOut{i};

						thisFrameT = inputMovie(:,:,i);

						D_restrict = rOutTmp;
						if ~isempty(options.dfExclude)
							D_restrict(:,:,options.dfExclude) = 0;
						end

						% Warp frame based on estimated displacement field
						thisFrameT = imwarp(thisFrameT,D_restrict,'linear','FillValues',NaN);

						inputMovie(:,:,i) = thisFrameT;
					end
					dispstat('Finished.','keepprev');
				end

			case 'normcorre'
				startTurboRegTime = tic;
				% [optsNC] = subfxn_getNoRMCorreParams(inputMovie);
				bound = 0;

				optsNoRMCorre = options.optsNoRMCorre;
				if isempty(fieldnames(optsNoRMCorre))
					disp('Getting NoRMCorre params...')
					optsNoRMCorre = ciapkg.motion_correction.getNoRMCorreParams(size(inputMovie),'guiDisplay',0);
				end

				% Ensure NoRMCorre gets the correct inputs
				optsNoRMCorre.d1 = size(inputMovie,1);
				optsNoRMCorre.d2 = size(inputMovie,2);
				disp('===')
				fn_structdisp(optsNoRMCorre)
				optsNoRMCorre.method
				% fn_structdisp(optsNoRMCorre)
				% [optsNoRMCorre2] = subfxn_getNoRMCorreParams(inputMovieCropped);
				% disp('===')
				% fn_structdisp(optsNoRMCorre2)
				% optsNoRMCorre2.method
				disp('===')

				% apply the shifts to the removed percentile
				inputMovie = normcorre.apply_shifts(...
					inputMovie,...
					ResultsOut,...
					optsNoRMCorre,bound/2,bound/2); 
				toc(startTurboRegTime);
				
			case 'turboreg'
				% Need to register subsets of the movie so parfor won't crash due to serialization errors.
				% TODO: make this subset based on the size of the movie, e.g. only send 1GB chunks to workers.
				subsetSize = options.subsetSizeFrames;
				nFramesHere = size(inputMovie,3);
				% numSubsets = ceil(length(inputMovie)/subsetSize)+1;
				numSubsets = ceil(nFramesHere/subsetSize)+1;
				% subsetList = round(linspace(1,length(inputMovie),numSubsets));
				subsetList = round(linspace(1,nFramesHere,numSubsets));
				display(['registering sublists: ' num2str(subsetList)]);
				if options.turboregRotation==1
					disp('Using rotation in registration')
				end
				fprintf('Performing %s registration and %s transformation.\n',options.registrationFxn,TransformationType);
				% ResultsOut{1}.Rotation
				nSubsets = (length(subsetList)-1);
				for thisSet=1:nSubsets
					subsetStartIdx = subsetList(thisSet);
					subsetEndIdx = subsetList(thisSet+1);
					if thisSet==nSubsets
						movieSubset = subsetStartIdx:subsetEndIdx;
						display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
					else
						movieSubset = subsetStartIdx:(subsetEndIdx-1);
						display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
					end

					% Get a slice of the data.
					% movieDataTemp(movieSubset) = inputMovie(movieSubset);
					
					% movieDataTemp = inputMovie(:,:,movieSubset);

					% loop over and register each frame
					if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end

					turboregRotationOption = options.turboregRotation;
					registrationFxnOption = options.registrationFxn;
					nMovieSubsets = length(movieSubset);
					
					% [transformFxn] = subfxn_transformFxn(TransformationType);

					parfor (i = movieSubset,nWorkers)
						rOutTmp = ResultsOut{i};

						% thisFrameT = movieDataTemp{i};
						thisFrameT = inputMovie(:,:,i);

						% get rotation and translation profile for image
						% if turboregRotationOption==1
						% 	MatrixMotCorrDispl(:,i)=[rOutTmp.Translation(1) rOutTmp.Translation(2) rOutTmp.Rotation];
						% else
						% 	MatrixMotCorrDispl(:,i)=[rOutTmp.Translation(1) rOutTmp.Translation(2) 0];
						% end

						% Transform movie given results of turboreg

						switch registrationFxnOption
							case {'imtransform','imwarp'}
								% if turboregRotationOption==1
								% 	rotMat = [...
								% 			cos(rOutTmp.Rotation) sin(rOutTmp.Rotation) 0;...
								% 			-sin(rOutTmp.Rotation) cos(rOutTmp.Rotation) 0;...
								% 			0 0 0];
								% else
								% 	rotMat = [0 0 0;0 0 0;0 0 0];
								% end

								% translateMat =...
								% 	[0 0 0;...
								% 	0 0 0;...
								% 	rOutTmp.Translation(2) rOutTmp.Translation(1) 0];
								% xform = translateMat + SkewingMat;

								% Get the skew/translation/rotation matrix from turboreg
								SkewingMat = rOutTmp.Skew;

								rotMat = [...
									cos(rOutTmp.Rotation) sin(rOutTmp.Rotation) 0;...
									-sin(rOutTmp.Rotation) cos(rOutTmp.Rotation) 0;...
									0 0 1];

								translateMat =...
									[1 0 0;...
									0 1 0;...
									rOutTmp.Translation(2) rOutTmp.Translation(1) 1];

								xform = translateMat*SkewingMat*rotMat;

								if strcmp(registrationFxnOption,'imtransform')==1
									% Perform the transformation
									tform = maketform(TransformationType,double(xform));
									% InterpListSelection = 'nearest';
									thisFrameT = single(imtransform(thisFrameT,tform,char(InterpListSelection),...
										'UData',[1 size(thisFrameT,2)]-rOutTmp.Origin(2)-1,...
										'VData',[1 size(thisFrameT,1)]-rOutTmp.Origin(1)-1,...
										'XData',[1 size(thisFrameT,2)]-rOutTmp.Origin(2)-1,...
										'YData',[1 size(thisFrameT,1)]-rOutTmp.Origin(1)-1,...
										'fill',NaN));
								elseif strcmp(registrationFxnOption,'imwarp')==1
									tform = subfxn_transformFxn(TransformationType,xform);
									% Define input spatial referencing.
									RI = imref2d(size(thisFrameT),[[1 size(thisFrameT,2)]-rOutTmp.Origin(2)-1],[[1 size(thisFrameT,1)]-rOutTmp.Origin(1)-1]);

									% Define output spatial referencing.
									Rout = imref2d(size(thisFrameT),[[1 size(thisFrameT,2)]-rOutTmp.Origin(2)-1],[[1 size(thisFrameT,1)]-rOutTmp.Origin(1)-1]);

									thisFrameT = single(imwarp(thisFrameT,RI,tform,char(InterpListSelection),...
										'OutputView',Rout,...
										'FillValues',NaN));
								end
							case 'transfturboreg'
								frameClass = class(thisFrameT);
								thisFrameT = ...
								cast(...
									transfturboreg(...
										single(thisFrameT),...
										ones(size(thisFrameT),'single'),...
										rOutTmp),...
									frameClass);
							otherwise
								% do nothing
						end

						inputMovie(:,:,i) = thisFrameT;
					end
					dispstat('Finished.','keepprev');

					% inputMovie(movieSubset)=movieDataTemp(movieSubset);
					% clear movieDataTemp;
				end
			otherwise
				% Do nothing
			end
	end
	function removeInputMovieEdges()
		% turboreg outputs 0s where movement goes off the screen
		thisMovieMinMask = zeros([size(inputMovie,1) size(inputMovie,2)]);
		% options.turboreg.registrationFxn
		switch options.registrationFxn
			case 'imtransform'
				reverseStr = '';
				for row=1:size(inputMovie,1)
					% thisMovieMinMask(row,:) = logical(max(isnan(squeeze(inputMovie(3,:,:))),[],2,'omitnan'));
					thisMovieMinMask(row,:) = logical(max(isnan(squeeze(inputMovie(row,:,:))),[],2,'omitnan'));
					reverseStr = cmdWaitbar(row,size(inputMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			case 'transfturboreg'
				reverseStr = '';
				for row=1:size(inputMovie,1)
					thisMovieMinMask(row,:) = logical(min(squeeze(inputMovie(row,:,:))~=0,[],2,'omitnan')==0);
					reverseStr = cmdWaitbar(row,size(inputMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			otherwise
				% do nothing
		end
		topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
		bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
		leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
		rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
		tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
		display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])
		if tmpPxToCrop~=0
			if tmpPxToCrop<options.pxToCrop
				% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
				cropMatrixPreProcess(tmpPxToCrop);
			else
				% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
				cropMatrixPreProcess(options.pxToCrop);
			end
		end

		% if size(inputMovie,2)>=size(inputMovie,1)
		% 	coords(1) = options.pxToCrop; %xmin
		% 	coords(2) = options.pxToCrop; %ymin
		% 	coords(3) = size(inputMovie,1)-options.pxToCrop;   %xmax
		% 	coords(4) = size(inputMovie,2)-options.pxToCrop;   %ymax
		% else
		% 	coords(1) = options.pxToCrop; %xmin
		% 	coords(2) = options.pxToCrop; %ymin
		% 	coords(4) = size(inputMovie,1)-options.pxToCrop;   %xmax
		% 	coords(3) = size(inputMovie,2)-options.pxToCrop;   %ymax
		% end

		% rowLen = size(inputMovie,1);
		% colLen = size(inputMovie,2);
		% % options.pxToCrop
		% % a,b are left/right column values
		% a = coords(1);
		% b = coords(3);
		% % c,d are top/bottom row values
		% c = coords(2);
		% d = coords(4);
		% % set those parts of the movie to NaNs
		% inputMovie(1:rowLen,1:a,:) = NaN;
		% inputMovie(1:rowLen,b:colLen,:) = NaN;
		% inputMovie(1:c,1:colLen,:) = NaN;
		% inputMovie(d:rowLen,1:colLen,:) = NaN;

		% % put black around the edges
		% dimsT = size(inputMovie);
		% minMovie=min(inputMovie,[],3);
		% % 	maxMovie=max(inputMovie,[],3);
		% % 	varMovie=var(inputMovie,[],3);
		% meanM = mean(minMovie(:));
		% stdM = std(minMovie(:));
		% minFrame = minMovie<(meanM-2.5*stdM);
		% removeFrameIdx = find(minFrame);
		% % 	maxFrameIdx = find(maxMovie>2);
		% % croppedtMovie = zeros(dimsT);
		% for i=1:dimsT(3)
		%     thisFrame = inputMovie(:,:,i);
		%     thisFrame(removeFrameIdx) = 0;
		%     inputMovie(:,:,i) = thisFrame;
		% end
	end
	function cropMatrixPreProcess(pxToCropPreprocess)
		% if size(thisMovie,2)>=size(thisMovie,1)
		% 	coords(1) = pxToCropPreprocess; %xmin
		% 	coords(2) = pxToCropPreprocess; %ymin
		% 	coords(3) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
		% 	coords(4) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		% else
		% 	coords(1) = pxToCropPreprocess; %xmin
		% 	coords(2) = pxToCropPreprocess; %ymin
		% 	coords(4) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
		% 	coords(3) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		% end
		% % a,b are left/right column values
		% a = coords(1);
		% b = coords(3);
		% % c,d are top/bottom row values
		% c = coords(2);
		% d = coords(4);

		topRowCrop = pxToCropPreprocess; % top row
		leftColCrop = pxToCropPreprocess; % left column
		bottomRowCrop = size(inputMovie,1)-pxToCropPreprocess; % bottom row
		rightColCrop = size(inputMovie,2)-pxToCropPreprocess; % right column

		% rowLen = size(inputMovie,1);
		% colLen = size(inputMovie,2);
		% set leftmost columns to NaN
		inputMovie(1:end,1:leftColCrop,:) = NaN;
		% set rightmost columns to NaN
		inputMovie(1:end,rightColCrop:end,:) = NaN;
		% set top rows to NaN
		inputMovie(1:topRowCrop,1:end,:) = NaN;
		% set bottom rows to NaN
		inputMovie(bottomRowCrop:end,1:end,:) = NaN;
	end
	function addBlackEdgeToMovie()
		% We project along z and make a nice binary image with 0 on the sides
		averagePictureEdge=~averagePictureEdge;

		StatsRegion = regionprops(averagePictureEdge,'Extrema');
		% [x y]
		% [top-left
		% top-right
		% right-top
		% right-bottom
		% bottom-right
		% bottom-left
		% left-bottom
		% left-top]
		TopIndice=[1 2 3 8];
		LeftIndice=[1 6 7 8];
		RightIndice=[2 3 4 5];
		BottomIndice=[4 5 6 7];

		extremaMatrix = StatsRegion.Extrema;
		xmin=ceil(max(extremaMatrix(LeftIndice,1)));
		ymin=ceil(max(extremaMatrix(TopIndice,2)));
		xmax=floor(min(extremaMatrix(RightIndice,1)));
		ymax=floor(min(extremaMatrix(BottomIndice,2)));

		rectCrop=[xmin ymin xmax-xmin ymax-ymin];

		if options.showFigs==1
			[~, ~] = openFigure(100, '');
			imagesc(imcrop(inputMovie(:,:,1),rectCrop));
		end
		% To get the final size, we just apply on the first figure
		% for i=1:dimsT(3)
		% 	thisFrame = inputMovie(:,:,i);
		% 	inputMovie(:,:,i)=imcrop(thisFrame,rectCrop);
		% end
	end
	function imagefFftOnInputMovie(inputMovieName)
		disp('dividing movie by lowpass via imageJ...')
		% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','imagejFFT','waitbarOn',1);
		% opens imagej
		% MUST ADD \Fiji.app\scripts
		% open imagej instance
		% Miji(false);
		startTime = tic;
		% pass matrix to imagej
		mijiAlreadyOpen = 0;
		try
			switch inputMovieName
				case 'inputMovie'
					MIJ.createImage('result', inputMovie, true);
				case 'inputMovieCropped'
					MIJ.createImage('result', inputMovieCropped, true);
				otherwise
					% body
			end
			mijiAlreadyOpen = 1;
		catch
			% Miji;
			% MIJ.start;
			manageMiji('startStop','start');

			switch inputMovieName
				case 'inputMovie'
					MIJ.createImage('result', inputMovie, true);
				case 'inputMovieCropped'
					MIJ.createImage('result', inputMovieCropped, true);
				otherwise
					% body
			end
		end
		commandwindow
		% settings taken from original imagej implementation
		bpstr= [' filter_large=' num2str(options.imagejFFTLarge) ' filter_small=' num2str(options.imagejFFTSmall) ' suppress=None tolerance=5 process'];
		MIJ.run('Bandpass Filter...',bpstr);
		% grab the image from imagej
		inputMovieFFT = MIJ.getCurrentImage;
		% mijiAlreadyOpen
		MIJ.run('Close');
		% close imagej instance
		if mijiAlreadyOpen==0
			% MIJ.exit;
			manageMiji('startStop','exit');
		end
		toc(startTime);
		% divide lowpass from image

		switch inputMovieName
			case 'inputMovie'
				inputMovie = bsxfun(@rdivide,single(inputMovie),single(inputMovieFFT));
			case 'inputMovieCropped'
				inputMovieCropped = bsxfun(@rdivide,single(inputMovieCropped),single(inputMovieFFT));
			otherwise
				% body
		end
		% choose whether to save a copy of the lowpass fft
		% expand this to include the raw turboreg
		if ~isempty(options.saveNormalizeBeforeRegister)
			disp('saving lowpass...')
			if ~isempty(options.refFrameMatrix)
				inputMovieFFT = inputMovieFFT(:,:,1:end-1);
			end
			if exist(options.saveNormalizeBeforeRegister,'file')
				appendDataToHdf5(options.saveNormalizeBeforeRegister, options.inputDatasetName, inputMovieFFT);
			else
				createHdf5File(options.saveNormalizeBeforeRegister, options.inputDatasetName, inputMovieFFT);
			end
		end
		clear inputMovieFFT;
	end
	function cropAndNormalizeInputMovie()
		if strcmp(options.cropCoords,'manual')
			cc = getCropSelection(inputMovie(:,:,1));
			inputMovieCropped = inputMovie(cc(2):cc(4), cc(1):cc(3), :);
			display(['cropped dims: ' num2str(size(inputMovieCropped))])
		elseif ~isempty(options.cropCoords)
			disp('cropping stack...');
			cc = options.cropCoords;
			inputMovieCropped = inputMovie(cc(2):cc(4), cc(1):cc(3), :);
			if options.showFigs==1
				% Display the subsetted image with appropriate axis ratio
				[~,~] = openFigure(456, '');
				% subplot(1,2,1);
				imagesc(inputMovie(:,:,1));title('original');
				axis image; colormap gray; drawnow;hold on
				[~,~] = openFigure(457, '');
				% subplot(1,2,2);
				imagesc(inputMovieCropped(:,:,1));title('cropped region');
				axis image; colormap gray; drawnow;hold off;
			end
			display(['cropped dims: ' num2str(size(inputMovie))])
			display(['cropped dims: ' num2str(size(inputMovieCropped))])
		else
			inputMovieCropped = inputMovie;
		end
		% do mean subtraction and matrix inversion to improve turboreg
		Ntime = size(inputMovieCropped,3);
		if options.meanSubtract==1
			switch options.normalizeType
				case 'imagejFFT'
					imagefFftOnInputMovie('inputMovieCropped');
				case 'gradient'
					disp('Creating gradient image')
					nImages = size(inputMovieCropped,3);
					if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end
					parfor (imageNo = 1:nImages,nWorkers)
						% imageNow = squeeze(inputMovieCropped{imageNo});
						% inputMovieCropped{imageNo} = transform(imageNow);

						imageNow = squeeze(inputMovieCropped(:,:,imageNo));
						inputMovieCropped(:,:,imageNo) = gradient(imageNow);

						% if (mod(imageNo,20)==0|imageNo==nImages)
						%     reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','fspecial normalizing');
						% end
					end
				case 'matlabDisk'
					% single(inputMovieCropped)
					disp('Matlab fspecial disk background removal')

					%Get dimension information about 3D movie matrix
					[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovieCropped);
					% reshapeValue = size(inputMovieCropped);

					%Convert array to cell array, allows slicing (not contiguous memory block)
					% inputMovieCropped = squeeze(mat2cell(inputMovieCropped,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

					% imageNow = squeeze(inputMovieCropped{1});
					imageNow = squeeze(inputMovieCropped(:,:,1));
					[rows,cols] = size(imageNow);
					r1 = min(rows,cols)/options.matlabdiskR1;
					r2 = options.matlabdiskR2;
					hDisk  = fspecial('disk', r1);
					hDisk2 = fspecial('disk', r2);
					transform = @(A) transform_2(A,hDisk,hDisk2);
					reverseStr = '';
					nImages = size(inputMovieCropped,3);
					% nImages = length(inputMovieCropped);

					if options.parallel==1; nWorkers=Inf;else;nWorkers=0;end
					parfor (imageNo = 1:nImages,nWorkers)
						% imageNow = squeeze(inputMovieCropped{imageNo});
						% inputMovieCropped{imageNo} = transform(imageNow);

						imageNow = squeeze(inputMovieCropped(:,:,imageNo));
						inputMovieCropped(:,:,imageNo) = transform(imageNow);

						% if (mod(imageNo,20)==0|imageNo==nImages)
						%     reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','fspecial normalizing');
						% end
					end
					dispstat('Finished.','keepprev');

					% inputMovieCropped = cat(3,inputMovieCropped{:});
				case 'divideByLowpass'
					disp('dividing movie by lowpass...')
					inputMovieCropped = normalizeMovie(single(inputMovieCropped),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
					% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','lowpassFFTDivisive','freqLow',options.freqLow,'freqHigh',options.freqHigh,'waitbarOn',1,'bandpassMask','gaussian');
					% inputMovieCropped = normalizeMovie(single(inputMovieCropped),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
					% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','lowpassFFTDivisive','freqLow',options.freqLow,'freqHigh',options.freqHigh,'waitbarOn',1);
					% playMovie(inputMovieCropped);
				case 'highpass'
					disp('high-pass filtering...')
					[inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',7,'freqHigh',500,'bandpassType','highpass','showImages',0,'bandpassMask','gaussian');
					% [inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',1,'freqHigh',7,'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
				case 'bandpass'
					disp('bandpass...')
					[inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',options.normalizeFreqLow,'freqHigh',options.normalizeFreqHigh,'bandpassType',options.normalizeBandpassType,'showImages',0,'bandpassMask',options.normalizeBandpassMask);
					% [inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',1,'freqHigh',7,'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
				otherwise
					% do nothing
			end

			if options.complementMatrix==1
				disp('mean subtracting and complementing matrix...');
			else
				disp('mean subtracting...');
			end
			reverseStr = '';
			for frameInd=1:Ntime
				if options.meanSubtractNormalize==1
					thisFrame=squeeze(inputMovieCropped(:,:,frameInd));
					meanThisFrame = mean(thisFrame(:));
					inputMovieCropped(:,:,frameInd) = inputMovieCropped(:,:,frameInd)-meanThisFrame;
					reverseStr = cmdWaitbar(frameInd,Ntime,reverseStr,'inputStr','subtracting mean','waitbarOn',1,'displayEvery',50);
				end
				if options.complementMatrix==1
					inputMovieCropped(:,:,frameInd) = imcomplement(inputMovieCropped(:,:,frameInd));
				end
			end
		end
		if options.showFigs==1
			subfxn_dispMovieFrames(inputMovieCropped,'Registration==0',1);
		end
		% title('normalized movie');
		% GammaValue = 2.95
		% GammaValue = 0.25
		% inputMovieCropped = 255 * (inputMovieCropped/255).^ GammaValue;
		% playMovie(inputMovieCropped);
	end
	disp('=======')
end
function subfxn_dispMovieFrames(inputMovieCropped,titleStr,inputMod)
	ciapkg.api.openFigure(9019, '');
	colormap gray;
	rowN = 2;
	colN = 3;
	spOffset = (inputMod-1)*colN;
	subplot(rowN,colN,1+spOffset)
		imagesc(squeeze(inputMovieCropped(:,:,1)));
		axis image; box off;
		title('Images to use to get registration coordinates');
		ylabel(titleStr)
	subplot(rowN,colN,2+spOffset)
		imagesc(squeeze(inputMovieCropped(:,:,end)));
		axis image; box off;
		title('Last frame in movie')
	subplot(rowN,colN,3+spOffset)
		imagesc(squeeze(inputMovieCropped(:,:,1))-squeeze(inputMovieCropped(:,:,end)));
		axis image; box off;
		title('Diff image #1 and #2')
	% ciapkg.overloaded.suptitle(titleStr)
	drawnow
end
function cropCoords = getCropSelection(thisFrame)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% get a crop of the input region
	[~,~] = openFigure(9, '');
	subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('select region')

	% Use ginput to select corner points of a rectangular
	% region by pointing and clicking the subject twice
	% p = ginput(2);

	h = imrect(gca);
	addNewPositionCallback(h,@(p) title(mat2str(p,3)));
	fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
	setPositionConstraintFcn(h,fcn);
	p = round(wait(h));

	% Get the x and y corner coordinates as integers
	% cropCoords(1) = min(floor(p(1)), floor(p(2))); %xmin
	% cropCoords(2) = min(floor(p(3)), floor(p(4))); %ymin
	% cropCoords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
	% cropCoords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

	cropCoords(1) = p(1); %xmin
	cropCoords(2) = p(2); %ymin
	cropCoords(3) = p(1)+p(3); %xmax
	cropCoords(4) = p(2)+p(4); %ymax

	% Index into the original image to create the new image
	thisFrameCropped = thisFrame(cropCoords(2):cropCoords(4), cropCoords(1): cropCoords(3));

	% Display the subsetted image with appropriate axis ratio
	[~, ~] = openFigure(9, '');
	subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
end
function depth = nestFxnCalculatePyramidDepth(len)
	% via Jessica Maxey
	min_size = 45;
	depth = 0;
	while (min_size <= len)
		len = len/2;
		depth = depth + 1;
	end
end
function A_tr = transform_2(A, ssm_filter, asm_filter)

	A_tr = A - imfilter(A, ssm_filter, 'replicate');

	A_tr = imfilter(A_tr, asm_filter);

end
function [tform] = subfxn_transformFxn(TransformationType,xform)
	% Create anonymous transform function to save CPU cycles in loop
	switch TransformationType
		case 'affine'
			% transformFxn = @(xform) affine2d(xform);
			tform = affine2d(double(xform));
			% tform = subfxn_transformFxn(TransformationType,double(xform));
		case 'projective'
			% transformFxn = @(xform) projective2d(xform);
			tform = projective2d(double(xform));
		otherwise
			% transformFxn = @(xform) affine2d(xform);
			tform = affine2d(double(xform));
	end
end