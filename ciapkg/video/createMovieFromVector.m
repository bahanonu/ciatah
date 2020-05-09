function [vectorMovie] = createMovieFromVector(inputVector,movieDim,varargin)
	% Creates a movie with specific dimensions based on a vector; useful for natively synchronizing 1D signals with movies without having to hack plot commands.
	% Biafra Ahanonu
	% started: 2015.11.08
	% inputs
		% inputVector - 1D vector (any type, preferably single), e.g. [1 2 3 10 3 3 -1 20]
		% movieDim - 3 element 1D vector of matrix dimensions, e.g. [x y t] = [100 100 245]
	% outputs
		% vectorMovie - 3D movie ([x y t]) with dimensions of movieDim and class of inputVector

	% changelog
		%
	% TODO
		%

	%========================
	% Different normalization types'oneToNegativeOne' 'oneToOne' 'zeroToOne' 'zeroCentered' 'zeroCenteredCorrect' 'dfof'
	options.normalizeVector = 'zeroToOne';
	% amount before and after current frame to plot, e.g. [-30:30]
	options.windowSize = [-30:30];
	% movie height downsample size
	options.secondDimDownsample = 5;
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
		% get dims and create vector movie
		movieDimY = round(movieDim(1)/options.secondDimDownsample);
		vectorClass = class(inputVector);
		vectorMovie = zeros([movieDimY movieDim(2) movieDim(3)],vectorClass);
		nFrames = movieDim(3);

		windowSize = options.windowSize;
		nStims = length(windowSize);

		if ~isempty(options.normalizeVector)
			display('Normalizing vector...')
			inputVector = normalizeVector(inputVector,'normRange',options.normalizeVector);
		end

		reverseStr = '';
		% amount to downsample the second dimension
		movieDimY = round(movieDim(1)/options.secondDimDownsample);

		for frameNo = 1:nFrames
			frameVectorIdx = windowSize+frameNo;

			% remove out of bound indices
			frameVectorIdx(frameVectorIdx<=0) = 0;
			% frameVectorIdx(frameVectorIdx==0) = frameVectorIdx(find(frameVectorIdx,1,'first'));
			frameVectorIdx(frameVectorIdx>nFrames) = 0;
			% frameVectorIdx(frameVectorIdx==0) = frameVectorIdx(find(frameVectorIdx,1,'last'));

			% add each time point in vector to movie
			for thisFrameVectorNo = 1:length(frameVectorIdx)
				if frameVectorIdx(thisFrameVectorNo)==0
					relativeStimValue = 1;
				else
					relativeStimValue = round(inputVector(frameVectorIdx(thisFrameVectorNo))*movieDimY);
				end
				% add relative (to max) value of vector to movie
				vectorMovie(1:relativeStimValue,thisFrameVectorNo,frameNo) = 0.05;
			end

			% resize vector movie to match movie dimensions given
			vectorMovie(:,:,frameNo) = imresize(vectorMovie(:,1:length(frameVectorIdx),frameNo),[movieDimY movieDim(2)],'bilinear');
			vectorMovie(:,round(end/2),frameNo) = 1;

			reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','creating matrix: ','waitbarOn',1,'displayEvery',5);
		end

		vectorMovie = flipdim(vectorMovie,1);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end