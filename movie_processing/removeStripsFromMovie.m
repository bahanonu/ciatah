function [inputMovie] = removeStripsFromMovie(inputMovie,varargin)
	% Removes vertical or horizontal stripes from movies.
	% Biafra Ahanonu
	% started: 2019.01.26 [14:17:16]
	% inputs
		% inputMovie = [x y frames] 3D matrix movie.
	% outputs
		% inputMovie = [x y frames] 3D matrix movie with stripes removed.

	% changelog
		%
	% TODO
		%

	%========================
	% Str: vertical or horizontal lines removal
	options.stripOrientation = 'vertical';
	% Int: Number of pixels to use for mean filter for filter mask
	options.meanFilterSize = 7;
	% Int: Higest frequency to exclude from strip filter.
	options.freqLowExclude = 10;
	% IGNORE Int: Higest frequency to exclude from strip filter.
	options.freqHighExclude = 50;


	% ===
	% options for fft, do not alter
	options.secondaryNormalizationType = [];
	% maximum frame to normalize
	options.maxFrame = size(inputMovie,3);
	% use parallel registration (using matlab pool)
	options.parallel = 1;
	% for bandpass, low freq to pass
	options.freqLow = 10;
	% for bandpass, high freq to pass
	options.freqHigh = 50;
	% highpass, lowpass, bandpass
	options.bandpassType = 'highpass';
	% binary or gaussian
	options.bandpassMask = 'gaussian';
	% show the frequency spectrum and images
	% 0 = no, 1 = yes
	options.showImages = 0;
	% Version of pad image to use for FFT, 1 = original, 2 = make image dimensions power of 2.
	options.padImageVersion = 2;
	% cmd line waitbar on?
	options.waitbarOn = 1;

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
		% ========================
		% Pad image to power of 2 size to improve image processing speed
	    stripCutoffFilter = ones([size(inputMovie,1) size(inputMovie,2)]);
		padImage = 1;
		if padImage==1
			if options.padImageVersion==2
				[imX imY] = size(stripCutoffFilter);
				optDim = @(x) 2^ceil(log(x)/log(2));
				optPadSize = max([optDim(imX) optDim(imY)]);
				options.padSize = [ceil((optPadSize-imX)/2) ceil((optPadSize-imY)/2)];
				stripCutoffFilter = padarray(stripCutoffFilter,[options.padSize(1) options.padSize(2)],'symmetric');
				stripCutoffFilter = stripCutoffFilter(1:optPadSize,1:optPadSize);
				% size(stripCutoffFilter)
			else
				padSize = round(1.0*mean(size(stripCutoffFilter)));
				stripCutoffFilter = padarray(stripCutoffFilter,[padSize padSize],'symmetric');
			end
		end

		% Create mean filter
		meanFilt = 1/options.meanFilterSize*ones(options.meanFilterSize,1);
	    meanFilt = meanFilt*meanFilt';
		% Create vertical or horizontal mask
		xN = size(stripCutoffFilter,1);
		yN = size(stripCutoffFilter,2);
		meanN = options.meanFilterSize;
		stripCutoffFilter = padarray(stripCutoffFilter,[meanN meanN],'symmetric');
		switch options.stripOrientation
			case 'horizontal'
				idxMid = round(size(stripCutoffFilter,2)/2);
				stripCutoffFilter(:,idxMid-1:idxMid+1) = 0;
			case 'vertical'
				idxMid = round(size(stripCutoffFilter,1)/2);
				stripCutoffFilter(idxMid-1:idxMid+1,:) = 0;
				% stripCutoffFilter(stripCutoffFilter==1) = NaN;
				% stripCutoffFilter = filter2(meanFilt,stripCutoffFilter,'full');
			case 'both'
				idxMid = round(size(stripCutoffFilter,2)/2);
				stripCutoffFilter(:,idxMid-1:idxMid+1) = 0;
				idxMid = round(size(stripCutoffFilter,1)/2);
				stripCutoffFilter(idxMid-1:idxMid+1,:) = 0;
			otherwise
				display('Please enter valid filter orientation.')
				return;
		end
		stripCutoffFilter = filter2(meanFilt,stripCutoffFilter,'same');
		stripCutoffFilter = stripCutoffFilter(meanN+1:(end-meanN),meanN+1:(end-meanN));
		% Add NaN's to allow later remove of low frequency from filter
		stripCutoffFilter(stripCutoffFilter>0.99999999) = NaN;

		% ========================
		display('Running Matlab FFT')
		inputMovie(isnan(inputMovie)) = 0;
		bandpassMatrix = zeros(size(inputMovie));
		% get options
		% ioptions.freqHighExclude = options.freqHighExclude;
		% ioptions.freqLowExclude = options.freqLowExclude;
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

		% ========================
		% Create final strip filter
		[cutoffFilter] = createCutoffFilter(testImage,ioptions.bandpassMask,options.freqLowExclude,options.freqHighExclude,ioptions.bandpassType,ioptions.padImage);
		% figure;imagesc(stripCutoffFilter);axis equal tight;colormap gray
		stripCutoffFilter = (1-stripCutoffFilter).*(cutoffFilter);
		stripCutoffFilter = 1-stripCutoffFilter;
		stripCutoffFilter = normalizeVector(stripCutoffFilter,'normRange','zeroToOne');
		stripCutoffFilter(isnan(stripCutoffFilter)) = 1;
		% figure;imagesc(stripCutoffFilter);axis equal tight;colormap gray
		% figure;imagesc(cutoffFilter);axis equal tight;colormap gray

		% ========================
		manageParallelWorkers('parallel',options.parallel);
		% ========================
		%Get dimension information about 3D movie matrix
		[inputMovieX inputMovieY inputMovieZ] = size(inputMovie);
		reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

		reverseStr = '';
		% parfor_progress(options.maxFrame);
		% dispstat('','init');
		% fprintf(1,'FFT movie:  ');
		nFramesToNormalize = options.maxFrame;
		try;[percent progress] = parfor_progress(nFramesToNormalize);catch;end; dispStepSize = round(nFramesToNormalize/20); dispstat('','init');
        secondaryNormalizationType = options.secondaryNormalizationType;
        maxFrame = options.maxFrame;

		ioptions.showImages = options.showImages;
        ioptions.cutoffFilter = stripCutoffFilter;

		for frame=1:nFramesToNormalize
			thisFrame = squeeze(inputMovie{frame});
			if isempty(secondaryNormalizationType)
				inputMovie{frame} = fftImage(thisFrame,'options',ioptions);
			else
				tmpFrame = fftImage(thisFrame,'options',ioptions);
				tmpFrameMin = nanmin(tmpFrame(:));
				if tmpFrameMin<0
					tmpFrame = tmpFrame + abs(tmpFrameMin);
				end
				inputMovie{frame} = thisFrame./tmpFrame;
			end
			if mod(frame,round(maxFrame/10))==0
				% fprintf ('%2.0f-',frame/options.maxFrame*100);drawnow
				% fprintf(1,'\b%d',i);
				% fprintf(1,'=');drawnow
			end
		end
		inputMovie = cat(3,inputMovie{:});
	catch err
		if iscell(inputMovie)
			inputMovie = cat(3,inputMovie{:});
		end
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function [cutoffFilter] = createCutoffFilter(testImage,bandpassMask,lowFreq,highFreq,bandpassType,padImage)
		cutoffFilter = [];
		if padImage==1
			if options.padImageVersion==2
				[imX imY] = size(testImage);
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
		[imFFTX imFFTY] = size(testImageFFT);

		switch bandpassMask
			case 'gaussian'
				% implemented using fspecial
				if lowFreq==0
					highpassFilter = ones([imFFTX imFFTY]);
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
				[ffty fftx] = size(testImageFFT);
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
				display('invalid option given')
				filtered_image = inputImage;
				return
		end
	end
end
