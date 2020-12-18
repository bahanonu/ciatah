function [outputSignal, inputImages] = applyImagesToMovie(inputImages,inputMovie, varargin)
	% Applies images to a 3D movie matrix in order to get a signal based on a thresholded version of the image.
	% Biafra Ahanonu
	% started: 2013.10.11
	% inputs
		% inputImages - [x y signalNo] of images, signals will be calculated for each image from the movie.
		% inputMovie - [x y frame] or char string path to the movie.
	% outputs
		% outputSignal - [signalNo frame] matrix of each signal's activity trace extracted directly from the movie.
		% inputImages - [x y signalNo], same as input.

	% changelog
		% 2014.02.17 [11:37:35] updated to have single inputs, bring notation in line with other programs
		% 2014.08.11 - obtain traces using linear indexing and reshaping, much faster than using bsxfun since don't have to make a large intermediate matrix.
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals].
		% 2020.04.28 [17:10:37] - Output modified inputImages.
		% 2020.10.19 [11:27:33] - Supports inputMovie as a character path to the movie.
		% 2020.10.26 [17:08:16] - Finished updating to allow read from disk and binning.
		% 2020.10.27 [12:57:53] - Added support for weighted computation of signals based on pixel values in each image.
		% 2020.12.02 [00:21:28] - Remove parallelization across inputImages to reduce memory overhead and serialization memory issues (e.g. transferring a duplicate of the movie to all workers).
	% TODO
		% DONE: Change so that it accepts a movie and images, current implementation is too specific.
		% DONE: Add ability to use the values of the filter (multiple by indices).

	%========================
	% Binary: 1 = input images already thresholded, 0 = not thresholded, applyImagesToMovie will threshold.
	options.alreadyThreshold = 0;
	% Binary: 1 = show the wait bar.
	options.waitbarOn = 1;
	% Float: value between 0 to 1, all values below this fraction of max value for each input image will be set to zero and not used for calculating output signal.
	options.threshold = 0.5;
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% Binary: 1 = read movie from HDD, 0 = load into RAM
	options.readMovieChunks = 0;
	% Int: Number of frames
	options.nFramesPerChunk = 5e3;
	% Binary: 1 = weight the output trace by the value of the individual pixels, 0 = all image pixels above threshold are weighted evenly when calculating activity trace.
	options.weightSignalByImage = 0;

	% OBSOLETE Binary: 1 = load the images/movies
	% inputDir, inputID, fileRegExp, PCAsuffix
	options.manualLoadSave = 0;

	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%   eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% Check maximum number of cores available
	% maxCores = feature('numCores');
	% Open works = max core #, probably should do maxCores-1 for
	%     stability...
	% matlabpool('open',maxCores);

	if ischar(inputMovie)==1
		% options.readMovieChunks = 1;
		inputMoviePath = inputMovie;
		[movieInfo] = ciapkg.io.getMovieInfo(inputMoviePath,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);

		if options.readMovieChunks==0
			inputMovie = loadMovieList(inputMovie,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
		end
		% if options.readMovieChunks==0
		% else

		% end
	else
		options.readMovieChunks = 0;
	end

	% get number of ICs and frames
	nImages = size(inputImages,3);
	nFrames = size(inputMovie,3);
	%
	nPts = nFrames;
	movieDims = size(inputMovie);

	% matrix multiple to get trace for each time-point
	reverseStr = '';
	if options.alreadyThreshold==0
		inputImages = thresholdImages(inputImages,'waitbarOn',1,'threshold',options.threshold);
	end
	disp(num2str([nanmin(inputMovie(:)) nanmax(inputMovie(:))]))

	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D_updateParforProgress = parallel.pool.DataQueue;
		afterEach(D_updateParforProgress, @nUpdateParforProgress);
		p_updateParforProgress = 1;
		N_updateParforProgress = nImages;
		nInterval_updateParforProgress = round(nImages/30); %25
		options_waitbarOn = options.waitbarOn;
	end

	if options.readMovieChunks==1
		frameBins = 1:options.nFramesPerChunk:movieInfo.three;
		frameBins(end+1) = movieInfo.three;
		nBins = (length(frameBins)-1);
		outputSignalCell = cell([nBins 1]);
		% Pre-threshold the PCA-ICA filters to save time.
		inputImagesThres = thresholdImages(inputImages,'waitbarOn',1,'threshold',options.threshold);
		tmpOpts = options;
		for binNo = 1:nBins
			disp('+++++++++++++++++++++++++++++++++++++++++++++++++++++')
			if binNo==nBins
				framesToProcess = frameBins(binNo):frameBins(binNo+1);
			else
				framesToProcess = frameBins(binNo):(frameBins(binNo+1)-1);
			end
			fprintf('ROI signal extract %d to %d frames.\n',framesToProcess(1),framesToProcess(end));
			tmpOpts.frameList = framesToProcess;
			tmpOpts.weightSignalByImage = options.weightSignalByImage;
			tmpOpts.alreadyThreshold = 1;
			tmpOpts.readMovieChunks = 0; % Prevent recusion loop.
			[outputSignalCell{binNo}, ~] = applyImagesToMovie(inputImagesThres,inputMoviePath,'options',tmpOpts);
		end

		% Combine all the frame chunks into a single [signalNo frames] size matrix
		outputSignal = cat(2,outputSignalCell{:});

	else
		outputSignal = subfxn_runSignalExtraction();
	end
	function outputSignal = subfxn_runSignalExtraction()
		% pre-allocate traces
		outputSignal = zeros(nImages,nFrames);
		opts_weightSignalByImage = options.weightSignalByImage;
		% parfor(imageNo = 1:nImages,2)
		for imageNo = 1:nImages
			iImage = squeeze(inputImages(:,:,imageNo));

			% =======
			% get the linear indices, much faster that way
			% tmpThres = squeeze(inputImagesThres(:,:,i));
			tmpThres = iImage;
			nPts = size(inputMovie,3);
			movieDims = size(inputMovie);
			[x, y] = find(tmpThres~=0);
			nValid = length(x);
			xrepmat = repmat(x,[1 nPts])';
			yrepmat = repmat(y,[1 nPts])';
			framerepmat = repmat(1:nPts,[1 length(x)]);
			linearInd = sub2ind(movieDims, xrepmat(:),yrepmat(:), framerepmat(:));
			if isempty(linearInd)
				disp('empty linearInd!!!')
			end
			tmpTrace = inputMovie(linearInd);
			% tmpTrace
			tmpTrace = reshape(tmpTrace,[nPts nValid]);
			if opts_weightSignalByImage==1
                    tmpWeights = tmpThres(tmpThres~=0);
                    tmpWeights = tmpWeights/nanmax(tmpWeights(:));
                    tmpTrace = tmpTrace.*tmpWeights(:)';
			end
			% imagesc(tmpTrace); colorbar;pause
			% size(tmpTrace)
			tmpTrace = squeeze(nanmean(tmpTrace,2));
			% size(tmpTrace)
			% display(num2str([nanmin(tmpTrace(:)) nanmax(tmpTrace(:))]))
			% =======
			% use bsxfun to matrix multiple 2D image to 3D movie
			% tmpTrace = nansum(nansum(bsxfun(@times,iImage,inputMovie),1),2);
			% normalize trace
			% tmpTrace = tmpTrace/mean(tmpTrace)-1;
			% =======
			outputSignal(imageNo,:) = tmpTrace(:);
			if ~verLessThan('matlab', '9.2'); send(D_updateParforProgress, imageNo); end % Update progress bar

			% reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','applying images to movie','displayEvery',5,'waitbarOn',options.waitbarOn);
		end
	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p_updateParforProgress = p_updateParforProgress + 1;
			pTmp = p_updateParforProgress;
			nTmp = N_updateParforProgress;
			if (mod(pTmp,nInterval_updateParforProgress)==0||pTmp==2||pTmp==nTmp)&&options_waitbarOn==1
				if pTmp==nTmp
					fprintf('%d\n',round(pTmp/nTmp*100))
				else
					fprintf('%d|',round(pTmp/nTmp*100))
				end
				% cmdWaitbar(p,nSignals,'','inputStr','','waitbarOn',1);
			end
			% [p mod(p,nInterval)==0 (mod(p,nInterval)==0||p==nSignals)&&options_waitbarOn==1]
		end
	end
end
	% normalize traces around zero
	% outputSignal = normalizeVector(outputSignal,'normRange','zeroCentered');

	% if options.manualLoadSave==1
	%     %For each day, load the downsampled DFOF movie
	%     files = getFileList(inputDir, fileRegExp);
	%     % load movies, automatically concatenate
	%     numMovies = length(files);
	%     for tifMovie=1:numMovies
	%         display(['loading ' num2str(tifMovie) '/' num2str(numMovies) ': ' files{tifMovie}])
	%         tmpDFOF = load_tif_movie(files{tifMovie},1);
	%         if(tifMovie==1)
	%             DFOF(:,:,:) = tmpDFOF.Movie;
	%         else
	%             DFOF(:,:,end+1:end+length(tmpDFOF.Movie)) = tmpDFOF.Movie;
	%         end
	%     end

	%     filesToLoad={};
	%     filesToLoad{1} = [inputDir filesep inputID '_ICfilters' PCAsuffix '.mat'];
	%     for i=1:length(filesToLoad)
	%         display(['loading: ' filesToLoad{i}]);
	%         load(filesToLoad{i})
	%     end
	% end

	% if options.manualLoadSave==1
	%     % save IC traces
	%     savestring = [inputDir filesep inputID '_ICtraces_applied' '.mat'];
	%     display(['saving: ' savestring])
	%     save(savestring,'IcaTraces');
	% end