function [inputImageFiltered, additionalOutput] = fftImage(inputImage,varargin)
	% Computes FFT on input image.
	% Biafra Ahanonu
	% started: 2013.11.09
	% inputs
		% inputImage - [x y] matrix
	% outputs
		% inputImageFiltered - [x y] matrix
	% example
		% test the lowpass and highpass on an image with a range of options
		% f = fftImage(frame,'runfftTest',1,'bandpassType','lowpass');
		% f = fftImage(frame,'runfftTest',1,'bandpassType','highpass');

	% below information was helpful in devising the function
		% http://www.mathworks.com/help/matlab/ref/fft2.html
		% https://www.cs.auckland.ac.nz/courses/compsci773s1c/lectures/ImageProcessing-html/topic1.htm
		% http://math-reference.com/s_fourier.html
		% http://wayback.archive.org/web/20130513181427/http://sharp.bu.edu/~slehar/fourier/fourier.html#filtering
		% http://www.dspguide.com/ch24/5.htm
		% http://astro.berkeley.edu/~jrg/ngst/fft/fourier.html
		% http://matlabgeeks.com/tips-tutorials/how-to-do-a-2-d-fourier-transform-in-matlab/
		% http://www.mathworks.com/matlabcentral/fileexchange/30947-gaussian-bandpass-filter-for-image-processing/content/gaussianbpf.m
		% http://qsimaging.com/ccd_noise_interpret_ffts.html

	% changelog
		% 2013.11.09 [13:21:06] updated function so it no longer converts to uint8 as this causes problems. Also, changed inputImageFiltered = inputImageFFT + filter3.*inputImageFFT; to inputImageFiltered = filter3.*inputImageFFT;
		% 2014.06.03 - updated to do binary fft
		% 2014.06.04 - added padding to reduce edge effects on the image
		% 2014.06.26 - update gaussian filter, using fspecial now and removed fft2 padding from original function
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2018.09.04 [17:31:47] - option to have padding optimized for power of 2, increasing fft speed by about 4.5x.
	% TODO
		% something...

	%========================
	% binary or gaussian
	options.bandpassMask = 'gaussian';
	% run a test over a range of frequencies
	% 0 = no, 1 = yes
	options.runfftTest = 0;
	% low frequency to have as cutoff
	options.lowFreq = 7;
	% high frequency to have as cutoff
	options.highFreq = 300;
	% take actual filters as inputs
	options.highpassFilter = [];
	options.lowpassFilter = [];
	options.cutoffFilter = [];
	% 1 = yes, 0 = no, pad image (e.g. remove halo around the edge)
	options.padImage = 1;
	%
	options.padImageVersion = 2;
	% add padding to the image
	options.padSize = round(1.0*mean(size(inputImage)));
	% highpass, lowpass, bandpass
	options.bandpassType = 'highpass';
	% show the frequency spectrum and images, for analysis purposes
	% 0 = no, 1 = yes
	options.showImages = 0;
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
		additionalOutput.blank = '';
		if options.runfftTest==0
			% pad the array to remove edge effects
			[imX imY] = size(inputImage);
			[imXOriginal imYOriginal] = size(inputImage);
			if options.padImage==1
				if options.padImageVersion==2
					optDim = @(x) 2^ceil(log(x)/log(2));
					optPadSize = max([optDim(imX) optDim(imY)]);
					options.padSize = [ceil((optPadSize-imX)/2) ceil((optPadSize-imY)/2)];
					inputImage = padarray(inputImage,[options.padSize(1) options.padSize(2)],'symmetric');
					inputImage = inputImage(1:optPadSize,1:optPadSize);
				else
					inputImage = padarray(inputImage,[options.padSize options.padSize],'symmetric');
				end
			else

			end
			% conversion fun
			% mean(inputImage(:))
			% inputImage = single(mat2gray(inputImage));
			% mean(inputImage(:))
			[imX imY] = size(inputImage);
			% convert to frequency spectrum
			% tic
			inputImageFFT = fft2(inputImage);
			% toc
			inputImageFFT = fftshift(inputImageFFT);
			[imFFTX imFFTY] = size(inputImageFFT);

			% create mask
			% tic
			if isempty(options.cutoffFilter)
				switch options.bandpassMask
					case 'gaussian'
						% implemented using fspecial
						if isempty(options.highpassFilter)
							if options.lowFreq==0
								highpassFilter = ones([imFFTX imFFTY]);
							else
								highpassFilter = 1-normalizeVector(fspecial('gaussian', [imFFTX imFFTY],options.lowFreq),'normRange','zeroToOne');
							end
						else
							highpassFilter = options.highpassFilter;
						end
						if isempty(options.lowpassFilter)
							lowpassFilter = normalizeVector(fspecial('gaussian', [imFFTX imFFTY],options.highFreq),'normRange','zeroToOne');
						else
							lowpassFilter = options.lowpassFilter;
						end
						switch options.bandpassType
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
						[ffty fftx] = size(inputImageFFT);
						cx = round(fftx/2);
						cy = round(ffty/2);
						[x,y] = meshgrid(-(cx-1):(fftx-cx),-(cy-1):(ffty-cy));
						highpassFilter = ((x.^2+y.^2)>options.lowFreq^2);
						lowpassFilter = ((x.^2+y.^2)<options.highFreq^2);
						switch options.bandpassType
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
			else
				cutoffFilter = options.cutoffFilter;
			end
			% toc

			% alter freq domain based on filter
			% size(cutoffFilter)
			% size(inputImageFFT)
			inputImageFFTFiltered = cutoffFilter.*inputImageFFT;

			% transform freq domain back to spatial
			% tic
			inputImageFiltered = ifftshift(inputImageFFTFiltered);
			inputImageFiltered = ifft2(inputImageFiltered);
			% toc
			% display('===========')
			% inputImageFiltered = real(inputImageFiltered(1:imX,1:imY));
			% inputImageFiltered = single(inputImageFiltered);

			% crop images back to original dimensions
			if options.padImage==1
				% imXOriginal
				 % imYOriginal
			 	if options.padImageVersion==2
					xIdx = (options.padSize(1)+1):(options.padSize(1)+imXOriginal);
					yIdx = (options.padSize(2)+1):(options.padSize(2)+imYOriginal);
					inputImageFiltered = inputImageFiltered(xIdx,yIdx);
					inputImageFiltered = single(real(inputImageFiltered));
				else
					inputImageFiltered = inputImageFiltered(options.padSize+1:end-options.padSize,options.padSize+1:end-options.padSize);
				end

				% size(inputImageFiltered)
				% size(inputImage)
			end

			% display images
			% options.showImages
			if options.showImages==1
				if options.padImage==1
					% imXOriginal
					 % imYOriginal
				 	if options.padImageVersion==2
						inputImage = inputImage(xIdx,yIdx);
				 	else
						inputImage = inputImage(options.padSize+1:end-options.padSize,options.padSize+1:end-options.padSize);
				 	end
				 end
				inputImageNorm = normalizeVector(inputImage,'normRange','zeroToOne');
				inputImageFilteredNorm = normalizeVector(inputImageFiltered,'normRange','zeroToOne');
				openFigure(90, '');
				colormap(customColormap([]));
				% colormap gray;
				subplot(2,3,1)
					fftshow2(inputImageFFT,'log')
					title('frequency spectrum of image')
				subplot(2,3,2)
					imagesc(cutoffFilter)
					title('filter')
				subplot(2,3,3)
					inputImageFFTFiltered(1,1) = max(inputImageFFT(:));
					inputImageFFTFiltered(1,2) = min(inputImageFFT(:));
					fftshow2(inputImageFFTFiltered,'log')
					title('frequency spectrum of cutoff')
				subplot(2,3,4)
					imagesc(inputImage)
					title(['input image, mean= ' num2str(nanmean(inputImage(:)))])
				subplot(2,3,5)
					imagesc(inputImageFilteredNorm)
					title(['fft image, mean=' num2str(nanmean(inputImageFiltered(:)))])
				subplot(2,3,6)
					% imagesc(horzcat(inputImageNorm,inputImageFilteredNorm))
					% title('combined images')
					imageDiff = inputImage-inputImageFiltered;
					imagesc(imageDiff);
					title(['difference, mean=' num2str(nanmean(imageDiff(:)))])
				drawnow
			end
			additionalOutput.inputImageFFT = inputImageFFT;
			additionalOutput.cutoffFilter = cutoffFilter;
			additionalOutput.inputImageFFTFiltered = inputImageFFTFiltered;
		else
			reverseStr = '';
			options.runfftTest=0;
			freqList = 1:30;
			nFreqs = length(freqList);
			inputImageTest = zeros([size(inputImage,1) size(inputImage,2) nFreqs]);
			for freq = freqList
				freqDiff = options.highFreq - options.lowFreq;
				switch options.bandpassType
					case 'highpass'
						options.lowFreq = freq;
					case 'lowpass'
						options.highFreq = freq;
				end
				inputImageTest(:,:,freq) = fftImage(inputImage,'options',options);
				reverseStr = cmdWaitbar(freq,nFreqs,reverseStr,'inputStr','normalizing movie','displayEvery',5);
			end
			inputImageTestArray(:,:,:,1) = inputImageTest;
			figure(10)
			montage(permute(inputImageTestArray(:,:,:,1),[1 2 4 3]))
			inputImageFiltered = inputImageTestArray;
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
function fftshow2(f,type)
	% Usage: FFTSHOW(F,TYPE)
	%
	% Displays the fft matrix F using imshow, where TYPE must be one of
	% 'abs' or 'log'. If TYPE='abs', then then abs(f) is displayed; if
	% TYPE='log' then log(1+abs(f)) is displayed. If TYPE is omitted, then
	% 'log' is chosen as a default.
	%
	% changelog
		% 2014.06.04 - change imshow to imagesc to speed up display of images.
	%
	% Example:
	% c=imread('cameraman.tif');
	% cf=fftshift(fft2(c));
	% fftshow(cf,'abs')
	%
	if nargin<2,
		type='log';
	end
	if (type=='log')
		fl = log(1+abs(f));
		fm = max(fl(:));
		imagesc(im2uint8(fl/fm))
	elseif (type=='abs')
		fa=abs(f);
		fm=max(fa(:));
		imagesc(fa/fm)
	else
		error('TYPE must be abs or log.');
	end;
end