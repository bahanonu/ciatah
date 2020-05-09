function [outputSignal, inputImages] = applyImagesToMovie(inputImages,inputMovie, varargin)
	% Applies images to a 3D movie matrix in order to get a signal based on a thresholded version of the image.
	% Biafra Ahanonu
	% started: 2013.10.11
	% inputs
		% inputImages - [x y signalNo]
		% inputMovie - [x y frame]
	% outputs
		%

	% changelog
		% 2014.02.17 [11:37:35] updated to have single inputs, bring notation in line with other programs
		% 2014.08.11 - obtain traces using linear indexing and reshaping, much faster than using bsxfun since don't have to make a large intermediate matrix.
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals].
		% 2020.04.28 [17:10:37] - Output modified inputImages.
	% TODO
		% change so that it accepts a movie and images, current implementation is too specific
		% add ability to use the values of the filter (multiple by indices)

	%========================
	% inputDir, inputID, fileRegExp, PCAsuffix
	% load the images/movies
	options.manualLoadSave = 0;
	options.alreadyThreshold = 0;
	options.waitbarOn = 1;
	options.threshold = 0.5;
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

	% get number of ICs and frames
	nImages = size(inputImages,3);
	nFrames = size(inputMovie,3);
	% pre-allocate traces
	outputSignal = zeros(nImages,nFrames);
	%
	nPts = nFrames;
	movieDims = size(inputMovie);

	% matrix multiple to get trace for each time-point
	reverseStr = '';
	if options.alreadyThreshold==0
		inputImages = thresholdImages(inputImages,'waitbarOn',1,'threshold',options.threshold);
	end
	display(num2str([nanmin(inputMovie(:)) nanmax(inputMovie(:))]))
	for imageNo = 1:nImages
		iImage = squeeze(inputImages(:,:,imageNo));
		% =======
		% get the linear indices, much faster that way
		% tmpThres = squeeze(inputImagesThres(:,:,i));
		tmpThres = iImage;
		nPts = size(inputMovie,3);
		movieDims = size(inputMovie);
		[x y] = find(tmpThres~=0);
		nValid = length(x);
		xrepmat = repmat(x,[1 nPts])';
		yrepmat = repmat(y,[1 nPts])';
		framerepmat = repmat(1:nPts,[1 length(x)]);
		linearInd = sub2ind(movieDims, xrepmat(:),yrepmat(:), framerepmat(:));
		if isempty(linearInd)
			display('empty linearInd!!!')
		end
		tmpTrace = inputMovie(linearInd);
		% tmpTrace
		tmpTrace = reshape(tmpTrace,[nPts nValid]);
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
		reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','applying images to movie','displayEvery',5,'waitbarOn',options.waitbarOn);
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