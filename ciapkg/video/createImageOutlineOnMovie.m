function [inputMovie] = createImageOutlineOnMovie(inputMovie,inputImages,varargin)
	% Gets outlines of cell extraction source outputs and overlays them onto a movie.
	% Biafra Ahanonu
	% started: 2018.02.15 [10:00:12]
	% inputs
		% inputMovie - [X Y Z] matrix of X,Y height/width and Z frames
		% inputImages - [x y nFilters] matrix
	% outputs
		% inputMovie - input movie with cell outline added

	% changelog
		%
	% TODO
		%

	%========================
	% Int: list of frames to load if loading movie inside function.
	options.frameList = [];
	% String: hierarchy name in hdf5 where movie data is located.
	options.inputDatasetName = '/1';
	% Float: [0,1] value to threshold of max
	options.thresholdOutline = 0.3;
	% Binary: 1 = use waitbar to indicate progress, 0 = don't use waitbar.
	options.waitbarOn = 1;
	% Float: Any value to use for the outlines, e.g. 1 or NaN. NaN recommended, if lease empty, uses maximum movie value.
	options.movieVal = [];
	%
	options.dilateOutlinesFactor = 1;
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
		inputMovieClass = class(inputMovie);
		if strcmp(inputMovieClass,'char')
			inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName,'frameList',options.frameList);
			% [pathstr,name,ext] = fileparts(inputFilePath);
			% options.newFilename = [pathstr '\concat_' name '.h5'];
		end

		% Get the outlines from the thresholded images.
		[thresholdedImages boundaryIndices] = thresholdImages(inputImages,'binary',1,'getBoundaryIndex',1,'threshold',options.thresholdOutline,'imageFilter','median','imageFilterBinary','median','medianFilterNeighborhoodSize',3);

		if options.dilateOutlinesFactor==1
			nullImage = zeros([size(inputImages(:,:,1))]);
			nullImage([boundaryIndices{:}]) = 1;
			nullImage = imdilate(nullImage,strel('disk',options.dilateOutlinesFactor));
			boundaryIndices = {find(nullImage)};
		end

		% Go through each frame and substitute values at the outline indices.
		nFrames = size(inputMovie,3);
		if isempty(options.movieVal)
			replaceMovieVal = nanmax(inputMovie(:));
		else
			replaceMovieVal = options.movieVal;
		end
		reverseStr = '';
		for frameNo = 1:nFrames
			tmpImg = inputMovie(:,:,frameNo);
			tmpImg([boundaryIndices{:}]) = tmpImg([boundaryIndices{:}])+replaceMovieVal;
			inputMovie(:,:,frameNo) = tmpImg;
			reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','Adding outlines to cells','waitbarOn',options.waitbarOn,'displayEvery',50);
		end

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end