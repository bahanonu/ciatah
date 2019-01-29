function [outputMovie] = createSideBySide(primaryMovie,secondaryMovie,varargin)
	% Auto-create side-by-side, either save output as hdf5 or return a matrix
	% Biafra Ahanonu
	% started: 2014.01.04 (code taken from controllerAnalysis)
	% inputs
		% primaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
		% secondaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
	% outputs
		% outputMovie - horizontally concatenated movie
	% changelog
		% 2014.01.27 [22:57:19] - changed to allow input of either a path or a matrix, more generalized
	% TODO
		% allow option for vertical concat?
		% spatio-temporal should be one abstracted for-loop, no? - DONE 2014.01.27 [21:52:37]

	% ========================
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% if want a different set of frames loaded for the second movie
	options.frameListSecondary = [];
	% whether to convert movie to double on load, not recommended
	options.convertToDouble = 0;
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% string to a movie, preferably AVI
	options.recordMovie = 0;
	% amount of pixels around the border to crop in primary movie
	options.pxToCrop = [];
	% downsample combined movie
	options.downsampleFactorFinal = 1;
	% make movies equal by using NaN instead of temporal downsampling.
	options.makeTimeEqualUsingNans = 0;
	% 1 = yes, 0 = no. whether to normalize each movies pixel distribution between [0 1]
	options.normalizeMovies = 1;
	% rotate xy dims of second movie
	options.rotateSecondMovie = 0;
	% rotate xy dims of primary movie
	options.rotatePrimaryMovie = 0;
	%
	options.increaseToLargestMovie = 0;
	% Binary: 1 = display info
	options.displayInfo = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	try
		% ========================
		% get the movie
		if strcmp(class(primaryMovie),'char')|strcmp(class(primaryMovie),'cell')
			primaryMovie = loadMovieList(primaryMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
		end

		% load secondary movie
		if isempty(options.frameListSecondary)
			if strcmp(class(secondaryMovie),'char')|strcmp(class(secondaryMovie),'cell')
				secondaryMovie = loadMovieList(secondaryMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameList);
			end
		else
			if strcmp(class(secondaryMovie),'char')|strcmp(class(secondaryMovie),'cell')
				secondaryMovie = loadMovieList(secondaryMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameListSecondary);
			end
		end
		% ========================
		% If movies are 4D rgb ([x y t c] where c = 3 for RGB colors) then call function again again for each dimension then concat the resulting individual RGB movies into a single output movie
		primaryDimNum = length(size(primaryMovie));
		secondaryDimNum = length(size(secondaryMovie));
		if primaryDimNum==4|secondaryDimNum==4
			subfxnDisp('4D movie detected...')

			% get size of 4th dim depending on which input is 4D
			if secondaryDimNum==4&primaryDimNum~=4
				nColorDims = size(secondaryMovie,4);
			else
				nColorDims = size(primaryMovie,4);
			end
			sideBySideMatrix = {};
			for colorNo = 1:nColorDims
				subfxnDisp(repmat('=',1,21))
				subfxnDisp(['color: ' num2str(colorNo) '/' num2str(nColorDims)])
				if secondaryDimNum==4
					if primaryDimNum==4
						sideBySideMatrix{colorNo} = createSideBySide(squeeze(primaryMovie(:,:,:,colorNo)),squeeze(secondaryMovie(:,:,:,colorNo)),'options',options);
					else
						sideBySideMatrix{colorNo} = createSideBySide(primaryMovie,squeeze(secondaryMovie(:,:,:,colorNo)),'options',options);
					end
				else
					sideBySideMatrix{colorNo} = createSideBySide(squeeze(primaryMovie(:,:,:,colorNo)),secondaryMovie,'options',options);
				end
			end
			outputMovie = cat(4,sideBySideMatrix{:});
			return;
		end

		if options.rotatePrimaryMovie==1
			subfxnDisp('rotating...')
			subfxnDisp(['pre-rotation dims: ' num2str(size(primaryMovie))])
			primaryMovie = permute(primaryMovie,[2 1 3]);
			subfxnDisp(['post-rotation dims: ' num2str(size(primaryMovie))])
		end
		if options.rotateSecondMovie==1
			subfxnDisp('rotating...')
			subfxnDisp(['pre-rotation dims: ' num2str(size(secondaryMovie))])
			secondaryMovie = permute(secondaryMovie,[2 1 3]);
			subfxnDisp(['post-rotation dims: ' num2str(size(secondaryMovie))])
		end

		% ========================
		% make movies single for calculations sake
		% primaryMovie = single(primaryMovie);
		% secondaryMovie = single(secondaryMovie);

		% ========================
		subfxnDisp('cropping primary movie...')
		% Get the x and y corner coordinates as integers
		if ~isempty(options.pxToCrop)
			if size(primaryMovie,2)>=size(primaryMovie,1)
				coords(1) = options.pxToCrop; %xmin
				coords(2) = options.pxToCrop; %ymin
				coords(3) = size(primaryMovie,1)-options.pxToCrop;   %xmax
				coords(4) = size(primaryMovie,2)-options.pxToCrop;   %ymax
			else
				coords(1) = options.pxToCrop; %xmin
				coords(2) = options.pxToCrop; %ymin
				coords(4) = size(primaryMovie,1)-options.pxToCrop;   %xmax
				coords(3) = size(primaryMovie,2)-options.pxToCrop;   %ymax
			end
			rowLen = size(primaryMovie,1);
			colLen = size(primaryMovie,2);
			% a,b are left/right column values
			a = coords(1);
			b = coords(3);
			% c,d are top/bottom row values
			c = coords(2);
			d = coords(4);
			cropChoice = 2;
			switch cropChoice
				case 1
					primaryMovie(1:rowLen,1:a,:) = NaN;
					primaryMovie(1:rowLen,b:colLen,:) = NaN;
					primaryMovie(1:c,1:colLen,:) = NaN;
					primaryMovie(d:rowLen,1:colLen,:) = NaN;
				case 2
					primaryMovie = primaryMovie(coords(2):coords(4), coords(1): coords(3),:);
				otherwise

			end
		end
		% ========================
		subfxnDisp('making movies spatially and temporally identical...')
		% to generalize out downsampling, create cell arrays to call that contain the dimension information
		dimensionList = {3, 2, 1};
		dimensionNameList = {'time','space','space'};
		% loop over each of the dimensions to resize to
		loopList = [1 3]; %1:length(dimensionList)
		for i=loopList
			thisDim = dimensionList{i};
			thisDimName = dimensionNameList{i};
			lengthPrimary = size(primaryMovie,thisDim);
			lengthSecond = size(secondaryMovie,thisDim);
			subfxnDisp(['length primary: ' num2str(lengthPrimary)])
			subfxnDisp(['length secondary: ' num2str(lengthSecond)])
			if options.makeTimeEqualUsingNans==1&strcmp(thisDimName,'time')
				if lengthPrimary>lengthSecond
					subfxnDisp('adding NaNs to end of second movie...')
					movieDiff = lengthPrimary-lengthSecond;
					secondaryMovie(:,:,end+movieDiff) = NaN;
				elseif lengthSecond>lengthPrimary
					subfxnDisp('adding NaNs to end of first movie...')
					movieDiff = lengthSecond-lengthPrimary;
					primaryMovie(:,:,end+movieDiff) = NaN;
				end
				continue
			end
			if lengthPrimary>lengthSecond
				% display(['downsampling: ' movieList{1}]);
				if options.increaseToLargestMovie==1
					downsampleFactor = lengthSecond/lengthPrimary;
					secondaryMovie = downsampleMovie(secondaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthPrimary,'downsampleX',lengthPrimary);
				else
					downsampleFactor = lengthPrimary/lengthSecond;
					primaryMovie = downsampleMovie(primaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthSecond,'downsampleX',lengthSecond);
				end
			elseif lengthSecond>lengthPrimary
				% display(['downsampling: ' vidList{1}]);
				if options.increaseToLargestMovie==1
					downsampleFactor = lengthPrimary/lengthSecond;
					primaryMovie = downsampleMovie(primaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthSecond,'downsampleX',lengthSecond);
				else
					downsampleFactor = lengthSecond/lengthPrimary;
					secondaryMovie = downsampleMovie(secondaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthPrimary,'downsampleX',lengthPrimary);
				end
			end
		end
		%========================
		% normalize movies between 0 and 1 so they display correctly together, better if their distributions are the same
		if options.normalizeMovies==1
			subfxnDisp('normalizing movies...')
			[primaryMovie] = normalizeVector(single(primaryMovie),'normRange','zeroToOne');
			[primaryMovie] = normalizeMovie(primaryMovie,'normalizationType','meanSubtraction');
			[secondaryMovie] = normalizeVector(single(secondaryMovie),'normRange','zeroToOne');
			[secondaryMovie] = normalizeMovie(secondaryMovie,'normalizationType','meanSubtraction');
		end
		% ========================
		% horizontally concat the movies
		subfxnDisp('concatenating movies...')
		subfxnDisp(['size primary: ' num2str(size(primaryMovie))])
		subfxnDisp(['size secondary: ' num2str(size(secondaryMovie))])
		outputMovie = horzcat(primaryMovie,secondaryMovie);
		clear primaryMovie secondaryMovie
		if options.downsampleFactorFinal>1
			subfxnDisp('downsampling final movie...')
			outputMovie = downsampleMovie(outputMovie,'downsampleDimension','space','downsampleFactor',options.downsampleFactorFinal);
		end

		% if user ask to save movie, do so.
		if options.recordMovie~=0
			writerObj = VideoWriter(options.recordMovie);
			open(writerObj);
			nFrames = size(outputMovie,3);
			reverseStr = '';
			for frame=1:nFrames
				writeVideo(writerObj,squeeze(outputMovie(:,:,frame)));
				if mod(frame,5)==0|frame==nFrames
				    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','writing movie');drawnow;
				end
			end
			close(writerObj);
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	%% subfxnDisp: function description
	function subfxnDisp(txt)
		if options.displayInfo==1
			display(txt)
		end
	end
end
