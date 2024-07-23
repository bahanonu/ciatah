function [inputMovie] = normalizeMovie(inputMovie, varargin)
	% Takes an input movie and applies a particular spatial or temporal normalization (e.g. lowpass divisive).
	% Biafra Ahanonu
	% started: 2013.11.09 [09:25:48]
	% inputs
		% inputMovie = [x y frames] 3D matrix
	% outputs
		% inputMovie = [x y frames] 3D matrix normalized

	% changelog
		% 2014.02.17 added in mean subtraction/division to function
		% 2017.08.18 [09:02:42] changed medfilt2 to have symmetric padding from default zero padding.
		% 2019.10.08 [09:14:33] - Add option for user to input crop coordinates in case they have a NaN or other border from motion correction, so that does not affect spatial filtering. User can also now input a char for inputMovie and have it load within the function to help reduce memory overhead
		% 2019.10.29 [13:51:04] - Added support for parallel.pool.Constant when PCT auto-start parallel pool disabled.
		% 2021.01.15 [21:09:55] - Moved detrend support into normalizeMovie.
		% 2021.06.02 [20:04:49] - Detrend movie now uses nanmean to get around issues in motion corrected videos.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.05.16 [16:39:45] - Switch away from using nanmean to mean('omitnan'). Detrend flight code refactor.
		% 2022.11.15 [15:14:14] - matlabdisk no longer converts to cell array, bad memory usage. Improve other memory usage in function.
		% 2022.12.05 [14:15:48] - Change how NaN check before filtering is run. Remove on a per-frame basis so that the NaNs can be added back in at the correct pixel locations.
		% 2022.12.05 [14:22:03] - Further eliminate nanmean/nanmin/nanmax usage, use dims instead of (:) [waste memory], and general refactoring.
		% 2022.12.06 [17:19:16] - Added movie subset support to reduce memory usage with parfor.
		% 2023.04.04 [19:36:21] - Fix detrendDegree passing.
		% 2023.06.08 [09:17:06] - Added subfxnFft movie subset support to reduce memory usage with parfor.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Str: Use one of the below inputs depending on the normalization or filtering required.
		% fft - Fast Fourier Transform on each frame, either high-, low-, or band-pass. See below options.
		% bandpassDivisive - Divide each frame by a bandpass version of the movie.
		% lowpassFFTDivisive - Divide each frame by a lowpass version of the movie.
		% imfilterSmooth - Spatially smooth each frame using imfilter.
		% imfilter - Divide each frame by a imfilter smoothed version.
		% meanSubtraction - Subtract each frame by its own mean, e.g. detrend on a per frame basis.
		% meanDivision - Divide each frame by its own mean.
		% negativeRemoval - Flip all negative values to positive, e.g. abs() entire movie.
		% detrend - Detrend the entire movie
	options.normalizationType = 'meanDivision';
	% Str: for fft.
	options.secondaryNormalizationType = [];
	% Int: maximum frame to normalize.
	options.maxFrame = size(inputMovie,3);
	% Binary: 1 = use parallel registration (using matlab pool).
	options.parallel = 1;
	% Int: number of frames to use for subsetting when using parfor, to reduce memory usage.
	options.subsetSize = 300;
	% ===
	% options for fft
	% Int: for bandpass, low freq to pass
	options.freqLow = 10;
	% Int: for bandpass, high freq to pass
	options.freqHigh = 50;
	% Int: imageJ normalization options
	options.imagejFFTLarge = 10000;
	options.imagejFFTSmall = 80;
	% Str: highpass, lowpass, bandpass
	options.bandpassType = 'highpass';
	% Str: binary or gaussian
	options.bandpassMask = 'gaussian';
	% Binary: show the frequency spectrum and images? 0 = no, 1 = yes
	options.showImages = 0;
	% ===
	% IMFILTER options
	% Str: fspecial, 'disk' or 'gaussian' option
	option.imfilterType = 'disk';
	% Str: how to deal with boundaries, see http://www.mathworks.com/help/images/ref/imfilter.html
	options.boundaryType = 'circular';
	% Int: 'disk' option: pixel radius to blur
	options.blurRadius = 35;
	% Int: 'gaussian' option
	options.sizeBlur = 80;
	options.sigmaBlur = 3;
	% ===
	% Binary: 1 = whether to show the divided and dfof in Matlab FFT testing
	options.testDuplicateDfof = 1;
	% size of neighborhood to use for median filter
	options.medianFilterNeighborhoodSize = 6;
	% type of padding, zeros/symmetric/indexed
	options.medianFilterPadding = 'symmetric';
	% Version of pad image to use for FFT, 1 = original, 2 = make image dimensions power of 2 (speeds up computation in many cases).
	options.padImageVersion = 2;
	% Int vector: empty = do not crop else pixel coordinates of a square to crop following convention [left-column top-row right-column bottom-row]
	options.cropCoords = [];
	% Binary: 1 = removes NaN from the movie since they will cause problems for most filtering functions. 0 = do not remove NaNs (ONLY use if movie has none or using options.cropCoords)
	options.runNanCheck = 1;
	% cmd line waitbar on?
	options.waitbarOn = 1;
	% Binary: 1 = yes, normalize Matlab FFT test movies
	options.normalizeMatlabFftTestMovies = 0;
	% Int: 1 = linear detrend, >1 = nth-degree polynomial detrend
	options.detrendDegree = 1;
	% ===
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% list of specific frames to load
	options.frameList = [];
	% ===
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	% fprintf('***\nRunning normalization: %s\n',options.normalizationType);
	fprintf('***Running normalization: %s\n',options.normalizationType);
	if strcmp(options.normalizationType,'bandpassDivisive')
		options.normalizationType = 'fft';
	end
	if strcmp(options.normalizationType,'lowpassFFTDivisive')
		options.normalizationType = 'fft';
		options.secondaryNormalizationType = 'lowpassFFTDivisive';
		options.bandpassType = 'lowpass';
	end
	%========================

	% Load movie directly in function if path, to save memory in some cases.
	if ischar(inputMovie)==1
		% ischar(inputMovie)
		inputMovie = loadMovieList(inputMovie,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName,'getMovieDims',0,'displayInfo',1,'largeMovieLoad',1);
		% size(inputMovie)
		options.maxFrame = size(inputMovie,3);
	end

	%========================
	% input is an image, convert to movie
	if length(size(inputMovie))==2
		inputMovieDims = 2;
		inputMovieTmp(:,:,1) = inputMovie;
		inputMovie = inputMovieTmp;
	else
		inputMovieDims = 3;
	end
	%========================
	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D = parallel.pool.DataQueue;
		afterEach(D, @nUpdateParforProgress);
		p = 0;
		N = size(inputMovie,3);
		nInterval = round(N/20);%100
		options_waitbarOn = options.waitbarOn;
	end
	%========================
	switch options.normalizationType
		case 'medianFilter'
			subfxnMedianFilter();
		case 'imagejFFT'
			subfxnImagejFFT();
		case 'imagejFFT_test'
			subfxnImagejFFT_test();
		case 'fft'
			subfxnFft();
		case 'matlabFFT_test'
			subfxnMatlabFFT_test();
		case 'matlabDisk'
			subfxnMatlabDisk();
		case 'matlabFFTTemporal'
			subfxnMatlabFFTTemporal();
		case 'matlabFFTTemporal_test'
			disp('Not implemented here.')
			% Nothing here yet
		case 'imfilterSmooth'
			subfxnImfilterSmooth();
		case 'imfilter'
			subfxnImfilter();
		case 'detrend'
			subfxnDetrend();
		case 'meanSubtraction'
			disp('mean subtracting movie');
			inputMean = mean(inputMovie,[1 2],'omitnan');
			inputMean = cast(inputMean,class(inputMovie));
			inputMovie = bsxfun(@minus,inputMovie,inputMean);
		case 'meanDivision'
			disp('mean dividing movie');
			inputMean = mean(inputMovie,[1 2],'omitnan');
			inputMean = cast(inputMean,class(inputMovie));
			inputMovie = bsxfun(@rdivide,inputMovie,inputMean);
			% inputMean = nansum(nansum(inputMovie,1),2);
			% inputMean = cast(inputMean,class(inputMovie))
		case 'negativeRemoval'
			disp('Switching movie negative values to positive (abs)');
			inputMin = abs(min(inputMovie,[],[1 2 3],'omitnan'));
			inputMin = cast(inputMin,class(inputMovie));
			inputMovie = bsxfun(@plus,inputMovie,inputMin);
		case 'zeroToOne'
			disp('normalizing movie between 0 and 1');
			nFrames = size(inputMovie,3);
			% reverseStr = '';
			for frameNo2 = 1:nFrames
				thisFrame = squeeze(inputMovie(:,:,frameNo2));
				maxVec = max(thisFrame,[],[1 2],'omitnan');
				minVec = min(thisFrame,[],[1 2],'omitnan');
				inputMovie(:,:,frameNo2) = (thisFrame-minVec)./(maxVec-minVec);
				if ~verLessThan('matlab', '9.2')
					send(D, frameNo2); % Update
				end
				% reverseStr = cmdWaitbar(frameNo2,nFrames,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			end
		otherwise
			disp('Input correct option, returning movie...')
			% inputMovie = NaN;
			return;
	end

	if inputMovieDims==2
		inputMovie = squeeze(inputMovie(:,:,1));
	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			if (mod(p,nInterval)==0||p==1||p==nFrames)&&options_waitbarOn==1
				if p==nFrames
					fprintf('%d\n',round(p/nFrames*100))
				else
					fprintf('%d|',round(p/nFrames*100))
				end
				% cmdWaitbar(p,nSignals,'','inputStr','','waitbarOn',1);
			end
			% [p mod(p,nInterval)==0 (mod(p,nInterval)==0||p==nSignals)&&options_waitbarOn==1]
		end
	end
	function mijiCheck()
		% if exist('Miji.m','file')==2
		% 	disp(['Miji located in: ' which('Miji.m')]);
		% 	% Miji is loaded, continue
		% else
		% 	pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
		% 				 'Miji path', [1 100]);
		% 	pathToMiji = pathToMiji{1};
		% 	privateLoadBatchFxnsPath = 'private\privateLoadBatchFxns.m';
		% 	fid = fopen(privateLoadBatchFxnsPath,'at');
		% 	fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
		% 	fclose(fid);
		% end
		modelAddOutsideDependencies('miji');
	end
	function [movieTmp] = addText(movieTmp,inputText,fontSize)
		nFrames = size(movieTmp,3);
		maxVal = max(movieTmp,[],[1 2 3],'omitnan');
		minVal = min(movieTmp,[],[1 2 3],'omitnan');
		reverseStr = '';
		for frameNo = 1:nFrames
			tmpFrame = insertText(movieTmp(:,:,frameNo),[0 0],num2str(inputText(frameNo)),...
				'BoxColor',[maxVal maxVal maxVal],...
				'TextColor',[minVal minVal minVal],...
				'AnchorPoint','LeftTop',...
				'FontSize',fontSize,...
				'BoxOpacity',1);
			movieTmp(:,:,frameNo) = squeeze(mean(tmpFrame,3,'omitnan'));
			reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','adding text to movie','waitbarOn',1,'displayEvery',10);
		end
		% maxVal = max(movieTmp,[],[1 2 3],'omitnan')
		% movieTmp(movieTmp==maxVal) = 1;
		% 'BoxColor','white'
	end
	function [cutoffFilter] = createCutoffFilter(testImage,bandpassMask,lowFreq,highFreq,bandpassType,padImage)
		cutoffFilter = [];
		if padImage==1
			if options.padImageVersion==2
				[imX, imY] = size(testImage);
				optDim = @(x) 2^ceil(log(x)/log(2));
				optPadSize = max([optDim(imX) optDim(imY)]);
				options.padSize = [ceil((optPadSize-imX)/2) ceil((optPadSize-imY)/2)];
				testImage = padarray(testImage,[options.padSize(1) options.padSize(2)],'symmetric');
				testImage = testImage(1:optPadSize,1:optPadSize);
			else
				padSize = round(1.0*mean(size(testImage)));
				testImage = padarray(testImage,[padSize padSize],'symmetric');
			end
		end
		testImageFFT = fft2(testImage);
		testImageFFT = fftshift(testImageFFT);
		[imFFTX, imFFTY] = size(testImageFFT);

		switch bandpassMask
			case 'gaussian'
				% implemented using fspecial
				if lowFreq==0
					highpassFilter = ones([imFFTX imFFTY],class(testImage));
				else
					highpassFilter = 1-normalizeVector(fspecial('gaussian', [imFFTX imFFTY],lowFreq),'normRange','zeroToOne');
				end
				lowpassFilter = normalizeVector(fspecial('gaussian', [imFFTX imFFTY],highFreq),'normRange','zeroToOne');
				switch bandpassType
					case 'highpass'
						cutoffFilter = highpassFilter;
					case 'lowpass'
						cutoffFilter = lowpassFilter;
					case 'bandpass'
						cutoffFilter = highpassFilter.*lowpassFilter;
					case 'inverseBandpass'
						cutoffFilter = 1-highpassFilter.*lowpassFilter;
					otherwise
						% do nothing
				end
			case 'binary'
				% create binary mask, tried with fspecial but this is easier
				[ffty, fftx] = size(testImageFFT);
				cx = round(fftx/2);
				cy = round(ffty/2);
				[x,y] = meshgrid(-(cx-1):(fftx-cx),-(cy-1):(ffty-cy));
				highpassFilter = ((x.^2+y.^2)>lowFreq^2);
				lowpassFilter = ((x.^2+y.^2)<highFreq^2);
				switch bandpassType
					case 'highpass'
						cutoffFilter = highpassFilter;
					case 'lowpass'
						cutoffFilter = lowpassFilter;
					case 'bandpass'
						cutoffFilter = highpassFilter.*lowpassFilter;
					case 'inverseBandpass'
						cutoffFilter = 1-highpassFilter.*lowpassFilter;
					otherwise
						% do nothing
				end
			otherwise
				disp('invalid option given')
				cutoffFilter = inputImage;
				return
		end
	end
	function subfxnMedianFilter()
		disp('Running Matlab median filter')
		% convert movie to correct class output by fft
		% outputClass = class(fftImage(squeeze(inputMovie(:,:,1)),'options',ioptions));
		% inputMovie = cast(inputMovie,outputClass);
		% openFigure(9012, '');imagesc(cutoffFilter);colormap gray;title([num2str(ioptions.lowFreq) ' | ' num2str(ioptions.highFreq)])
		% ========================
		manageParallelWorkers('parallel',options.parallel);
		% ========================
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);
		% reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

		reverseStr = '';
		nFramesToNormalize = options.maxFrame;
		% try [percent, progress] = parfor_progress(nFramesToNormalize);catch;end; dispStepSize = round(nFramesToNormalize/20); dispstat('','init');
		medianFilterNeighborhoodSize = options.medianFilterNeighborhoodSize;
		medianFilterPadding = options.medianFilterPadding;
		maxFrame = options.maxFrame;
		nFrames = nFramesToNormalize;
		parfor frame=1:nFramesToNormalize
			% [percent progress] = parfor_progress;if mod(progress,dispStepSize) == 0;dispstat(sprintf('progress %0.1f %',percent));else;end
			thisFrame = squeeze(inputMovie{frame});
			% thisFrame = imnoise(thisFrame,'salt & pepper',0.02);
			% xx = 6;
			% inputMovie{frame} = medfilt2(thisFrame,[xx xx],'zeros'); - ORIGINAL
			inputMovie{frame} = medfilt2(thisFrame,[medianFilterNeighborhoodSize medianFilterNeighborhoodSize],medianFilterPadding);
			% inputMovie{frame} = ordfilt2(thisFrame,1,ones(xx,xx));
			% inputMovie{frame} = wiener2(thisFrame,[5 5]);
			% xx = 4;
			% inputMovie{frame} = conv2(double(thisFrame), ones(xx)/xx^2, 'same');
			if ~verLessThan('matlab', '9.2')
				send(D, frame); % Update
			end
			% if mod(frame,round(maxFrame/10))==0
				% fprintf ('%2.0f-',frame/options.maxFrame*100);drawnow
				% fprintf(1,'\b%d',i);
				% fprintf(1,'=');drawnow
			% end
		end
		dispstat('Finished.','keepprev');
		inputMovie = cat(3,inputMovie{:});
	end
	function subfxnImagejFFT()
		% opens imagej
		mijiCheck()
		% MUST ADD \Fiji.app\scripts
		% open imagej instance
		% Miji(false);
		% Miji;
		% MIJ.start;
		manageMiji('startStop','start');
		startTime = tic;
		% pass matrix to imagej
		MIJ.createImage('result', inputMovie, true);
		% settings taken from original imagej implementation
		% bpstr= ' filter_large=10000 filter_small=80 suppress=None tolerance=5 process';
		bpstr= [' filter_large=' num2str(options.imagejFFTLarge) ' filter_small=' num2str(options.imagejFFTSmall) ' suppress=None tolerance=5 process'];
		MIJ.run('Bandpass Filter...',bpstr);
		% grab the image from imagej
		inputMovieFFT = MIJ.getCurrentImage;
		% close imagej instance
		MIJ.run('Close');
		% MIJ.exit;
		manageMiji('startStop','exit');
		toc(startTime);
		% divide lowpass from image
		inputMovie = bsxfun(@rdivide,single(inputMovie),single(inputMovieFFT));
	end
	function subfxnImagejFFT_test()
		mijiCheck()
		reverseStr = '';
		% inputImage = squeeze(inputMovie(:,:,1));
		options.runfftTest=0;
		lowFreqList = [10 50 80];
		highFreqList = [10000 5000 120];
		fontSize = 30;
		userFreqList = inputdlg({'filter_small','filter_large','font size (pt)'},'bandpass parameters',[1 100],{num2str(lowFreqList),num2str(highFreqList),num2str(fontSize)});
		lowFreqList = str2num(userFreqList{1});
		highFreqList = str2num(userFreqList{2});
		fontSize = str2num(userFreqList{3});

		[lowFreqList,highFreqList] = meshgrid(lowFreqList, highFreqList);
		lowFreqList = lowFreqList(:);
		highFreqList = highFreqList(:);
		nFreqs = length(lowFreqList);
		% pairs = [p(:) q(:)];

		% inputImageTest = zeros([size(inputImage,1) size(inputImage,2) nFreqs]);
		inputImageTest = cell([nFreqs 1]);
		inputMovieDuplicate = cell([nFreqs 1]);
		inputMovieDivide = cell([nFreqs 1]);
		% size(inputImageTest)
		% Miji(false);
		% Miji;
		MIJ.start;
		startTime = tic;
		for freqNo = 1:nFreqs
			lowFreq = lowFreqList(freqNo);
			highFreq = highFreqList(freqNo);
			% pass matrix to imagej
			MIJ.createImage('result', inputMovie, true);
			% settings taken from original imagej implementation
			bpstr= [' filter_large=' num2str(highFreq) ' filter_small=' num2str(lowFreq) ' suppress=None tolerance=5 process'];
			MIJ.run('Bandpass Filter...',bpstr);
			% grab the image from imagej
			inputMovieFFT = MIJ.getCurrentImage;
			% inputImageTest(:,:,freqNo) = inputMovieFFT;
			inputImageTest{freqNo} = inputMovieFFT;
			inputMovieDuplicate{freqNo} = inputMovie;
			% divide lowpass from image
			inputMovieDivide{freqNo} = bsxfun(@rdivide,single(inputMovie),single(inputMovieFFT));

			moptions.identifyingText{freqNo} = [num2str(lowFreq) ' | ' num2str(highFreq)];
			reverseStr = cmdWaitbar(freqNo,nFreqs,reverseStr,'inputStr','normalizing movie','displayEvery',5);
			MIJ.run('Close');
		end
		% MIJ.exit;
		manageMiji('startStop','exit');
		% moptions.identifyingText = strsplit(num2str(freqList),' ');
		moptions.singleRowMontage = 1;
		moptions.fontSize = fontSize;
		[inputMovieDuplicate] = createMontageMovie(inputMovieDuplicate,'options',moptions);
		moptions.identifyingText = [];
		[inputImageTest] = createMontageMovie(inputImageTest,'options',moptions);
		[inputMovieDivide] = createMontageMovie(inputMovieDivide,'options',moptions);
		inputMovie = permute(cat(2,inputMovieDuplicate,inputImageTest,inputMovieDivide),[2 1 3]);
		% close imagej instance
		% [inputImageTest] = addText(inputImageTest,freqList,42);
		% inputImageTestArray(:,:,:,1) = inputImageTest;
		% figure(10)
		% montage(permute(inputImageTestArray(:,:,:,1),[1 2 4 3]))
		% inputMovie = inputImageTestArray;
	end
	function subfxnFft()
		disp('Running Matlab FFT')
		% bandpassMatrix = zeros(size(inputMovie));
		% get options
		ioptions.showImages = options.showImages;
		ioptions.lowFreq = options.freqLow;
		ioptions.highFreq = options.freqHigh;
		ioptions.bandpassType = options.bandpassType;
		ioptions.bandpassMask = options.bandpassMask;
		ioptions.padImage = 1;
		ioptions.padImageVersion = options.padImageVersion;
		% convert movie to correct class output by fft
		outputClass = class(fftImage(squeeze(inputMovie(:,:,1)),'options',ioptions));
		inputMovie = cast(inputMovie,outputClass);
		% pre-calculate filter to save time
		testImage = squeeze(inputMovie(:,:,1));
		[cutoffFilter] = createCutoffFilter(testImage,ioptions.bandpassMask,ioptions.lowFreq,ioptions.highFreq,ioptions.bandpassType,ioptions.padImage);
		ioptions.cutoffFilter = cutoffFilter;
		% openFigure(9012, '');imagesc(cutoffFilter);colormap gray;title([num2str(ioptions.lowFreq) ' | ' num2str(ioptions.highFreq)])
		% ========================
		manageParallelWorkers('parallel',options.parallel);
		% ========================
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);
		% reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

		reverseStr = '';
		% parfor_progress(options.maxFrame);
		% dispstat('','init');
		% fprintf(1,'FFT movie:  ');
		nFramesToNormalize = options.maxFrame;
		nFrames = nFramesToNormalize;
		% try;[percent progress] = parfor_progress(nFramesToNormalize);catch;end; dispStepSize = round(nFramesToNormalize/20); dispstat('','init');
		secondaryNormalizationType = options.secondaryNormalizationType;
		maxFrame = options.maxFrame;
		coords = options.cropCoords;

		if ~isempty(options.cropCoords)
			thisFrame1 = squeeze(inputMovie(coords(2):coords(4), coords(1):coords(3),1));
			thisFrame2 = squeeze(inputMovie(:,:,1));
			disp(['Cropping movie just for FFT (' num2str(size(thisFrame1)) '), original movie size remains the same (' num2str(size(thisFrame2)) ').'])
			% a,b are left/right column values
			a = coords(1);
			b = coords(3);
			% c,d are top/bottom row values
			c = coords(2);
			d = coords(4);
		else
			a = [];
			b = [];
			c = [];
			d = [];
		end

		%if isempty(gcp)
		%	opts2.Value = ioptions;
		%else
		%	opts2 = parallel.pool.Constant(ioptions);
        %end
        opts2 = parallel.pool.Constant(ioptions);
		% startState = ticBytes(gcp);
		options_runNanCheck = options.runNanCheck;

		parfor frame = 1:nFramesToNormalize
			% [percent progress] = parfor_progress;if mod(progress,dispStepSize) == 0;dispstat(sprintf('progress %0.1f %',percent));else;end
			% thisFrame = squeeze(inputMovie(:,:,frame));
			% if isempty(options.secondaryNormalizationType)
			% 	inputMovie(:,:,frame) = fftImage(thisFrame,'options',ioptions);
			% else
			% 	tmpFrame = fftImage(thisFrame,'options',ioptions);
			% 	inputMovie(:,:,frame) = thisFrame./tmpFrame;
			% end
			% reverseStr = cmdWaitbar(frame,options.maxFrame,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			% thisFrame = squeeze(inputMovie{frame});
			thisFrame = inputMovie(:,:,frame);
			thisFrame = squeeze(thisFrame);

			if options_runNanCheck==1
				nanMask = isnan(thisFrame);
				thisFrame(nanMask) = mean(thisFrame,[1 2 3],'omitnan');
			end

			if isempty(secondaryNormalizationType)
				if isempty(coords)
					thisFrame = fftImage(thisFrame,'options',opts2.Value);
				else
					thisFrame(c:d, a:b) = fftImage(thisFrame(c:d, a:b),'options',opts2.Value);
				end
			else
				if isempty(coords)
					tmpFrame = fftImage(thisFrame,'options',opts2.Value);
				else
					tmpFrame = thisFrame;
					tmpFrame(c:d, a:b) = fftImage(thisFrame(c:d, a:b),'options',opts2.Value);
				end
				tmpFrameMin = min(tmpFrame,[],[1 2],'omitnan');
				if tmpFrameMin<0
					tmpFrame = tmpFrame + abs(tmpFrameMin);
				end
				thisFrame = thisFrame./tmpFrame;
			end

			if options_runNanCheck==1
				thisFrame(nanMask) = NaN;
			end

			inputMovie(:,:,frame) = thisFrame;

			if ~verLessThan('matlab', '9.2')
				send(D, frame); % Update
			end

			% if mod(frame,round(maxFrame/10))==0
				% fprintf ('%2.0f-',frame/options.maxFrame*100);drawnow
				% fprintf(1,'\b%d',i);
				% fprintf(1,'=');drawnow
			% end
			% percent = parfor_progress;
			% dispstat(num2str(percent),'keepthis');
			% parfor_progress
			% drawnow
			% bandpassMatrix(:,:,frame) = fftImage(thisFrame,'options',ioptions);
			% bandpassMatrix(:,:,frame) = imcomplement(bandpassMatrix(:,:,frame));
			% = bsxfun(@ldivide,squeeze(movie20hz(:,:,1)),filteredFrame
		end
		% tocBytes(gcp,startState)
		dispstat('Finished.','keepprev');
		% fprintf(1,'\n');
		% parfor_progress(0);
		% inputMovie = cat(3,inputMovie{:});

		% options.secondaryNormalizationType
		% if isempty(options.secondaryNormalizationType)
		% 	inputMovie = bsxfun(@ldivide,inputMovie,inputMovieTmp);
		% end
		% inputMovie = bandpassMatrix;
	end
	function subfxnMatlabFFT_test()
		reverseStr = '';
		% inputImage = squeeze(inputMovie(:,:,1));
		% options.runfftTest=0;
		% lowFreqList = [10 50 80];
		% highFreqList = [50 100 500];
		lowFreqList = [1 3];
		highFreqList = [7 14];
		fontSize = 30;
		userFreqList = inputdlg({'lowFreq','highFreq','font size (pt)'},'bandpass parameters',[1 100],{num2str(lowFreqList),num2str(highFreqList),num2str(fontSize)});
		lowFreqList = str2num(userFreqList{1});
		highFreqList = str2num(userFreqList{2});
		fontSize = str2num(userFreqList{3});

		[lowFreqList,highFreqList] = meshgrid(lowFreqList, highFreqList);
		lowFreqList = lowFreqList(:);
		highFreqList = highFreqList(:);
		nFreqs = length(lowFreqList);
		% pairs = [p(:) q(:)];

		% inputImageTest = zeros([size(inputImage,1) size(inputImage,2) nFreqs]);
		inputImageTest = cell([nFreqs 1]);
		inputMovieDuplicate = cell([nFreqs 1]);
		inputMovieDivide = cell([nFreqs 1]);
		inputMovieDfof = cell([nFreqs 1]);
		% size(inputImageTest)


		startTime = tic;
		for freqNo = 1:nFreqs
			disp([num2str(freqNo) '/' num2str(nFreqs)])
			lowFreq = lowFreqList(freqNo);
			highFreq = highFreqList(freqNo);
			inputMovieFFT = inputMovie;
			% set FFT options
			ioptions.showImages = options.showImages;
			ioptions.lowFreq = lowFreq;
			ioptions.highFreq = highFreq;
			ioptions.bandpassType = options.bandpassType;
			ioptions.bandpassMask = options.bandpassMask;
			ioptions.padImage=1;
			% covert to correct output class
			outputClass = class(fftImage(squeeze(inputMovie(:,:,1)),'options',ioptions));
			inputMovieFFT = cast(inputMovieFFT,outputClass);
			% ============
			% % pre-calculate filter to save time
			testImage = squeeze(inputMovieFFT(:,:,1));
			[cutoffFilter] = createCutoffFilter(testImage,ioptions.bandpassMask,ioptions.lowFreq,ioptions.highFreq,ioptions.bandpassType,ioptions.padImage);
			ioptions.cutoffFilter = cutoffFilter;
			% openFigure(9012, '');imagesc(cutoffFilter);colormap gray;title([num2str(lowFreq) ' | ' num2str(highFreq)])
			% FFT each image
			reverseStr = '';
			% options.secondaryNormalizationType
			% mean(inputMovieFFT,[1 2 3],'omitnan')
			if options.runNanCheck==1
				inputMovieFFT(isnan(inputMovieFFT)) = 0;
			end

			% inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
			% parfor frame=1:options.maxFrame
			% thisFrame = squeeze(inputMovie{frame});
			% if isempty(options.secondaryNormalizationType)
			% 	inputMovie{frame} = fftImage(thisFrame,'options',ioptions);
			% else
			% 	tmpFrame = fftImage(thisFrame,'options',ioptions);
			% 	inputMovie{frame} = thisFrame./tmpFrame;
			% end
			% if mod(frame,round(options.maxFrame/10))==0
			% 	% fprintf ('%2.0f-',frame/options.maxFrame*100);drawnow
			% 	% fprintf(1,'\b%d',i);
			% 	% fprintf(1,'=');drawnow
			% end
			% inputMovie = cat(3,inputMovie{:});

			options_runNanCheck = options.runNanCheck;

			for frame=1:options.maxFrame
				thisFrame = squeeze(inputMovieFFT(:,:,frame));

				if options_runNanCheck==1
					nanMask = isnan(thisFrame);
					thisFrame(nanMask) = mean(thisFrame,[1 2 3],'omitnan');
				end

				thisFrame = fftImage(thisFrame,'options',ioptions);
				% if isempty(options.secondaryNormalizationType)
				% else
				% 	% tmpFrame = fftImage(thisFrame,'options',ioptions);
				% 	% inputMovieFFT(:,:,frame) = thisFrame./tmpFrame;
				% 	thisFrame = fftImage(thisFrame,'options',ioptions);
				% end

				if options_runNanCheck==1
					thisFrame(nanMask) = NaN;
				end

				inputMovieFFT(:,:,frame) = thisFrame;
				% bandpassMatrix(:,:,frame) = fftImage(thisFrame,'options',ioptions);
				% bandpassMatrix(:,:,frame) = imcomplement(bandpassMatrix(:,:,frame));
				reverseStr = cmdWaitbar(frame,options.maxFrame,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
				% = bsxfun(@ldivide,squeeze(movie20hz(:,:,1)),filteredFrame
			end
			% inputImageTest(:,:,freqNo) = inputMovieFFT;
			inputMovieFFTMin = min(inputMovieFFT,[],[1 2 3],'omitnan');
			inputImageTest{freqNo} = inputMovieFFT - inputMovieFFTMin+1;
			inputMovieDuplicate{freqNo} = cast(inputMovie,outputClass);
			% divide lowpass from image
			if options.testDuplicateDfof == 1
				minMovie = min(inputMovieDuplicate{freqNo},[],[1 2 3],'omitnan');
				if minMovie<0
					inputMovieDuplicate{freqNo} = inputMovieDuplicate{freqNo} + 1.1*abs(minMovie);
				end

				% inputMovieDivide{freqNo} = bsxfun(@rdivide,inputMovieDuplicate{freqNo},inputImageTest{freqNo});
				inputMovieDivide{freqNo} = bsxfun(@rdivide,inputMovieDuplicate{freqNo},inputMovieFFT);
				% if isempty(options.secondaryNormalizationType)
				% else
				% 	inputMovieDivide{freqNo} = inputImageTest{freqNo};
				% end
				% mean(inputMovieDuplicate{freqNo}(:),[],'omitnan')
				% mean(inputImageTest{freqNo}(:),[],'omitnan')
				% inputMovieDivide{freqNo} = bsxfun(@minus,inputMovieDuplicate{freqNo},inputImageTest{freqNo});
				inputMovieDfof{freqNo} = dfofMovie(inputMovieDivide{freqNo});
			else
				inputMovieDivide{freqNo} = [];
				inputMovieDfof{freqNo} = [];
			end

			moptions.identifyingText{freqNo} = [num2str(lowFreq) ' | ' num2str(highFreq)];
			% reverseStr = cmdWaitbar(freqNo,nFreqs,reverseStr,'inputStr','normalizing movie','displayEvery',5);
		end
		% moptions.identifyingText = strsplit(num2str(freqList),' ');
		% moptions.normalizeMovies = options.normalizeMatlabFftTestMovies;
		moptions.singleRowMontage = 1;
		moptions.fontSize = fontSize;
		[inputMovieDuplicate] = createMontageMovie(inputMovieDuplicate,'options',moptions);
		moptions.identifyingText = [];
		[inputImageTest] = createMontageMovie(inputImageTest,'options',moptions);
		if options.testDuplicateDfof == 1
			[inputMovieDivide] = createMontageMovie(inputMovieDivide,'options',moptions);
			[inputMovieDfof] = createMontageMovie(inputMovieDfof,'options',moptions);
			inputMovie = permute(cat(2,inputMovieDuplicate,inputImageTest,inputMovieDivide,inputMovieDfof),[2 1 3]);
		else
			inputMovie = permute(cat(2,inputMovieDuplicate,inputImageTest),[2 1 3]);
		end
	end
	function subfxnDetrend()
		% This will detrend (linear, polynomial, exponential decay, etc.) an input movie based on user input
		manageParallelWorkers('parallel',options.parallel);
		% ========================
		%Get dimension information about 3D movie matrix
		[inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);

		frameMeanInputMovie = squeeze(mean(inputMovie,[1 2],'omitnan'));

		trendVals = frameMeanInputMovie - detrend(frameMeanInputMovie,options.detrendDegree);

		% meanInputMovie = detrend(frameMeanInputMovie,0);
		meanInputMovie = squeeze(mean(frameMeanInputMovie,[1 2 3],'omitnan'));

		nFramesToNormalize = options.maxFrame;
		nFrames = nFramesToNormalize;

		% trendVals = [];

		% if isempty(gcp)
		% 	opts2.Value = ioptions;
		% else
		% 	opts2 = parallel.pool.Constant(ioptions);
		% end

		% parfor frame = 1:nFramesToNormalize
		% 	inputMovie(:,:,frame) = inputMovie(:,:,frame) - trendVals(frame) + meanInputMovie;

		% 	% thisFrame = inputMovie(:,:,frame);
		% 	% thisFrame = squeeze(thisFrame);
		% 	% thisFrame = thisFrame - trendVals(frame);
		% 	% thisFrame = thisFrame + meanInputMovie;

		% 	% inputMovie(:,:,frame) = thisFrame;

		% 	if ~verLessThan('matlab', '9.2')
		% 		send(D, frame); % Update
		% 	end
		% end

		% Detrend each frame only using subset to reduce memory usage
		subsetSize = options.subsetSize;
		movieLength = size(inputMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		disp(['Detrending sublists: ' num2str(subsetList)]);
		nSubsets = (length(subsetList)-1);

		for thisSet = 1:nSubsets
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
		    end
		    disp([num2str(movieSubset(1)) '-' num2str(movieSubset(end)) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			disp(repmat('$',1,7))

			inputMovieTmp = inputMovie(:,:,movieSubset);
			trendValsTmp = trendVals(movieSubset);
			nFramesTmp = size(inputMovieTmp,3);
			% movieSubset2 = 1:nFramesTmp;

			parfor frameNo = 1:nFramesTmp
			    % if frameNo==startFrame||mod(frameNo,50)==0
				%     fprintf('%d | ',frameNo);
				% end
				inputMovieTmp(:,:,frameNo) = inputMovieTmp(:,:,frameNo) - trendValsTmp(frameNo) + meanInputMovie;
			end
		    disp('===');
			inputMovie(:,:,movieSubset) = inputMovieTmp;
		    fprintf('\n');
		end
	end
	function subfxnMatlabDisk()
		disp('Matlab fspecial disk background removal')

		%Get dimension information about 3D movie matrix
		% [inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);
		% reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		%inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

		%imageNow = squeeze(inputMovie{1});
		imageNow = squeeze(inputMovie(:,:,1));
		[rows,cols] = size(imageNow);
		r1 = min(rows,cols)/10;
		r2 = 3;
		hDisk  = fspecial('disk', r1);
		hDisk2 = fspecial('disk', r2);

        C_hDisk = parallel.pool.Constant(hDisk);
        C_hDisk2 = parallel.pool.Constant(hDisk2);

		transform = @(A) transform_2(A,hDisk,hDisk2);
		%reverseStr = '';
		% nImages = size(inputMovieCropped,3);
		nImages = size(inputMovie,3);
        nFrames = nImages;

		% [percent progress] = parfor_progress(nImages); dispStepSize = round(nImages/20); dispstat('','init');
		parfor frame = 1:nImages
			% [percent progress] = parfor_progress;if mod(progress,dispStepSize) == 0;dispstat(sprintf('progress %0.1f %',percent));else;end
			% imageNow = squeeze(inputMovie{imageNo});
		    thisFrame = inputMovie(:,:,frame);
			thisFrame = squeeze(thisFrame);
            thisFrame = transform_2(thisFrame,C_hDisk.Value,C_hDisk2.Value);
            % imageNow = transform(imageNow);
			% inputMovie{imageNo} = transform(imageNow);
			inputMovie(:,:,frame) = thisFrame;
			% if (mod(imageNo,20)==0|imageNo==nImages)
			%     reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','fspecial normalizing');
			% end

            if ~verLessThan('matlab', '9.2')
				send(D, frame); % Update
			end
		end
		%parfor_progress(0);
        %dispstat('Finished.','keepprev');

		% inputMovie = cat(3,inputMovie{:});
    end
	function subfxnMatlabFFTTemporal()
		sigma = 1.5;
		fsize = 10;
		x = linspace(-fsize / 2, fsize / 2, fsize);
		% gauss = exp(-x .^ 2 / (2 * sigma ^ 2));
		% gauss = gaussFilter / sum (gauss);
		gaussFilter = normpdf(x,0,sigma);
		inputMovieDims = size(inputMovie);

		d1 = designfilt('lowpassiir','FilterOrder',12, ...
			'HalfPowerFrequency',0.10,'DesignMethod','butter');
		% tt = filtfilt(d1,double(squeeze(g(72,60,:))));

		width = inputMovieDims(1);
		height = inputMovieDims(2);
		[p,q] = meshgrid(1:width, 1:height);
		idPairs = [p(:) q(:)];
		% idPairs = unique(sort(idPairs,2),'rows');
		% idPairs((idPairs(:,1)==idPairs(:,2)),:) = [];
		nPairs = size(idPairs,1);
		reverseStr = '';
		inputMovie = single(inputMovie);
		for idPairNum = 1:nPairs
			widthNo = idPairs(idPairNum,1);
			heightNo = idPairs(idPairNum,2);
			% inputMovie(widthNo,heightNo,:) = conv(squeeze(inputMovie(widthNo,heightNo,:)), gaussFilter, 'same');
			tmpLine = filtfilt(d1,double(squeeze(inputMovie(widthNo,heightNo,:))));
			inputMovie(widthNo,heightNo,:) = tmpLine;
			reverseStr = cmdWaitbar(idPairNum,nPairs,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
		end
	end
	function subfxnImfilterSmooth()
		% create filter
		switch option.imfilterType
			case 'disk'
				movieFilter = fspecial('disk', options.blurRadius);
			case 'gaussian'
				movieFilter = fspecial('gaussian', [options.sizeBlur options.sizeBlur], options.sigmaBlur);
			otherwise
				return
		end
		nFrames = size(inputMovie,3);
		% inputMovieFiltered = zeros(size(inputMovie),class(inputMovie));
		reverseStr = '';
		options_boundaryType = options.boundaryType;

		%Get dimension information about 3D movie matrix
		% [inputMovieX, inputMovieY, inputMovieZ] = size(inputMovie);
		% reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
		options_runNanCheck = options.runNanCheck;
		parfor frame=1:nFrames
			thisFrame = squeeze(inputMovie(:,:,frame));
			% thisFrame = inputMovie{frame};

			if options_runNanCheck==1
				nanMask = isnan(thisFrame);
				thisFrame(nanMask) = mean(thisFrame,[1 2 3],'omitnan');
			end

			thisFrame = imfilter(thisFrame, movieFilter,options_boundaryType);

			if options_runNanCheck==1
				thisFrame(nanMask) = NaN;
			end

			inputMovie(:,:,frame) = thisFrame
			% inputMovie{frame} = imfilter(thisFrame, movieFilter,options_boundaryType);
			% reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','imfilter normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			if ~verLessThan('matlab', '9.2')
				send(D, frame); % Update
			end
		end
		% inputMovie = cat(3,inputMovie{:});
		% divide each frame by the filtered movie to remove 'background'
		% inputMovie = inputMovieFiltered;
	end
	function subfxnImfilter()
		% create filter
		switch option.imfilterType
			case 'disk'
				movieFilter = fspecial('disk', options.blurRadius);
			case 'gaussian'
				movieFilter = fspecial('gaussian', [options.sizeBlur options.sizeBlur], options.sigmaBlur);
			otherwise
				return
		end
		nFrames = size(inputMovie,3);
		inputMovieFiltered = zeros(size(inputMovie),class(inputMovie));
		reverseStr = '';
		options_runNanCheck = options.runNanCheck;
		for frame=1:nFrames
			thisFrame = squeeze(inputMovie(:,:,frame));

			if options_runNanCheck==1
				nanMask = isnan(thisFrame);
				thisFrame(nanMask) = mean(thisFrame,[1 2 3],'omitnan');
			end

		 	thisFrame = imfilter(thisFrame, movieFilter,options.boundaryType);

			if options_runNanCheck==1
				thisFrame(nanMask) = NaN;
			end

		 	inputMovieFiltered(:,:,frame) = thisFrame;

			reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
		end
		% divide each frame by the filtered movie to remove 'background'
		inputMovie = bsxfun(@ldivide,inputMovieFiltered,inputMovie);
	end
	% function [D p N nInterval] = subfxnSetupParforProgress(~)
	% 	% Only implement in Matlab 2017a and above
	% 	if ~verLessThan('matlab', '9.2')
	% 	    D = parallel.pool.DataQueue;
	% 	    afterEach(D, @nUpdateParforProgress);
	% 	    p = 1;
	% 	    N = nImages;
	% 	    nInterval = 20;
	% 	end
	% end

	% function nUpdateParforProgress(~)
	%     if ~verLessThan('matlab', '9.2')
	%         p = p + 1;
	%         if (mod(p,nInterval)==0||p==nImages)&&options_waitbarOn==1
	%             cmdWaitbar(p,nImages,'','inputStr','','waitbarOn',1);
	%         end
	%     end
	% end
end
function A_tr = transform_2(A, ssm_filter, asm_filter)

	A_tr = A - imfilter(A, ssm_filter, 'replicate');

	A_tr = imfilter(A_tr, asm_filter);

end