function [inputMovies] = createMontageMovie(inputMovies,varargin)
	% Creates a movie montage from a cell array of movies
	% adapted from signalSorter and other subfunction.
	% Biafra Ahanonu
	% started: 2015.04.09
	% changelog
		% 2019.09.05 [16:42:29]
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Cell array of strings: each cell contains text to overlay on each movie.
	options.identifyingText = [];
	% font size for identifyingText
	options.fontSize = 15;
	% whether to normalize movies
	% options.normalizeMovies = ones([length(inputMovies) 1]);
	options.normalizeMovies = ones([length(inputMovies) 1]);
	% if want the montage to be in a row
	options.singleRowMontage = 0;
	% Int: specify the number of rows in the montage
	options.numRowMontage = [];
	% whether to downsample movies
	options.downsampleFactorSpace = 1;
	% whether to downsample movies
	options.downsampleFactorTime = 1;
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% whether to convert movie to double on load, not recommended
	options.convertToDouble = 0;
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% rotate xy dims of second movie
	options.rotateMovies = 0;
	% rotate xy dims of second movie
	options.rotateMoviesText = 0;
	% Int: which dimensions to flip
	options.flipdimsText = [];
	% Any value or NaN to pad array
	options.padArrayValue = [];
	% Int: [x y] pad array vector
	options.padSize = [3 3];
	% Binary: 1 = display info
	options.displayInfo = 1;
    % Binary: 1 = increase to largest movie instead of downsampling to the smallest movie.
	options.increaseToLargestMovie = 0;
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
		nMovies = length(inputMovies);

		% check to see if need to load movies
		for movieNo = 1:nMovies
            display(repmat('+',1,21))
            fprintf('%d/%d.\n',movieNo,nMovies)
			% get the movie
			if strcmp(class(inputMovies{movieNo}),'char')
				inputMovies{movieNo} = loadMovieList(inputMovies{movieNo},'convertToDouble',options.convertToDouble,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
			end
			if options.downsampleFactorSpace~=1
				inputMovies{movieNo} = downsampleMovie(inputMovies{movieNo},'downsampleDimension','space','downsampleFactor',options.downsampleFactorSpace);
			end
			if options.downsampleFactorTime~=1
				inputMovies{movieNo} = downsampleMovie(inputMovies{movieNo},'downsampleDimension','time','downsampleFactor',options.downsampleFactorTime);
			end
			if options.rotateMovies==1
				subfxnDisp('rotating...')
				subfxnDisp(['pre-rotation dims: ' num2str(size(inputMovies{movieNo}))])
				% inputMovies{movieNo} = permute(inputMovies{movieNo},[2 1 3]);
				inputMovies{movieNo} = rot90(inputMovies{movieNo});
				subfxnDisp(['post-rotation dims: ' num2str(size(inputMovies{movieNo}))])
			end
		end

		if sum(options.normalizeMovies)>0
			for movieNo = 1:nMovies
				% options.normalizeMovies(movieNo)==1
				[inputMovies{movieNo}] = normalizeVector(single(inputMovies{movieNo}),'normRange','zeroToOne');
			end
		end
		if ~isempty(options.identifyingText)
			for movieNo = 1:nMovies
				% options.identifyingText{movieNo}
				[inputMovies{movieNo}] = addText(inputMovies{movieNo},options.identifyingText{movieNo},options.fontSize);
				% imagesc(inputMovies{movieNo}(:,:,1));pause;
				if options.rotateMoviesText==1
					subfxnDisp('rotating...')
					subfxnDisp(['pre-rotation dims: ' num2str(size(inputMovies{movieNo}))])
					% inputMovies{movieNo} = permute(inputMovies{movieNo},[2 1 3]);
					inputMovies{movieNo} = rot90(inputMovies{movieNo});
					subfxnDisp(['post-rotation dims: ' num2str(size(inputMovies{movieNo}))])
				end
				if ~isempty(options.flipdimsText)
					inputMovies{movieNo} = flipdim(inputMovies{movieNo},options.flipdimsText);
				end
			end
		end
		if ~isempty(options.padSize)
			for movieNo = 1:nMovies
				if isempty(options.padArrayValue)
					padVal = nanmax(inputMovies{movieNo}(:));
				else
					padVal = options.padArrayValue;
				end
				inputMovies{movieNo} = padarray(inputMovies{movieNo},options.padSize,padVal,'both');
			end
		end

		if options.singleRowMontage==0
			[xPlot yPlot] = getSubplotDimensions(nMovies);
		else
			xPlot = 1;
			yPlot = nMovies;
		end
		if ~isempty(options.numRowMontage)
			xPlot = ceil(nMovies/options.numRowMontage);
			yPlot = options.numRowMontage;
		end
		% movieLengths = cellfun(@(x){size(x,3)},inputMovies);
		% maxMovieLength = max(movieLengths{:});
		inputMovieNo = 1;
		for xNo = 1:xPlot
			for yNo = 1:yPlot
				if inputMovieNo>length(inputMovies)
					[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},NaN(size(inputMovies{1})),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0,'displayInfo',options.displayInfo,'increaseToLargestMovie',options.increaseToLargestMovie);
				elseif yNo==1
					[behaviorMovie{xNo}] = inputMovies{inputMovieNo};
				else
					[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},inputMovies{inputMovieNo},'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0,'displayInfo',options.displayInfo,'increaseToLargestMovie',options.increaseToLargestMovie);
				end
				% size(behaviorMovie{xNo})
				inputMovieNo = inputMovieNo+1;
			end
		end
		subfxnDisp(['size behavior: ' num2str(size(behaviorMovie{1}))])
		behaviorMovie{1} = permute(behaviorMovie{1},[2 1 3]);
		subfxnDisp(['size behavior: ' num2str(size(behaviorMovie{1}))])
		subfxnDisp(repmat('-',1,7))
		for concatNo = 2:length(behaviorMovie)
			[behaviorMovie{1}] = createSideBySide(behaviorMovie{1},permute(behaviorMovie{concatNo},[2 1 3]),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0,'displayInfo',options.displayInfo,'increaseToLargestMovie',options.increaseToLargestMovie);
			behaviorMovie{concatNo} = {};
			size(behaviorMovie{1});
		end
		inputMovies = behaviorMovie{1};
		% behaviorMovie = cat(behaviorMovie{:},3)
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function subfxnDisp(txt)
		if options.displayInfo==1
			display(txt);
		end
	end
end
function [movieTmp] = addText(movieTmp,inputText,fontSize)
	% 2016.07.01 [15:05:03] - improved
	nFrames = size(movieTmp,3);
	maxVal = nanmax(movieTmp(:))*0.9;
	minVal = nanmin(movieTmp(:));
	% minVal = NaN;
	reverseStr = '';
	% create a frame, put text on it, and then directly replace all sections of the movie with that text
	movieTmpTwo = minVal*ones([size(movieTmp,1) size(movieTmp,2)]);
	movieTmpTwo = squeeze(nanmean(...
		insertText(movieTmpTwo,[0 0],inputText,...
		'BoxColor',[maxVal maxVal maxVal],...
		'TextColor',[minVal minVal minVal],...
		'AnchorPoint','LeftTop',...
		'FontSize',fontSize,...
		'BoxOpacity',1)...
	,3));
	% imagesc(movieTmpTwo);pause
	% [i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo==maxVal));
	% [i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo==maxVal));
	midVal = (minVal+maxVal)/2;
	[i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo>midVal));
	movieTmpTwo = repmat(movieTmpTwo,[1 1 size(movieTmp,3)]);
	% movieTmpTwo(movieTmpTwo<maxVal*0.6) = NaN;
	% movieTmpTwo(movieTmpTwo>=maxVal*0.6) = maxVal;
	movieTmp(min(i):max(i),min(j):max(j),:) = movieTmpTwo(min(i):max(i),min(j):max(j),:);

	% for frameNo = 1:nFrames
	% 	movieTmp(:,:,frameNo) = squeeze(nanmean(...
	% 		insertText(movieTmp(:,:,frameNo),[0 0],inputText,...
	% 		'BoxColor',[maxVal maxVal maxVal],...
	% 		'TextColor',[minVal minVal minVal],...
	% 		'AnchorPoint','LeftTop',...
	% 		'FontSize',fontSize,...
	% 		'BoxOpacity',1)...
	% 	,3));
	% 	reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','adding text to movie','waitbarOn',1,'displayEvery',10);
	% end
	% maxVal = nanmax(movieTmp(:))
	% movieTmp(movieTmp==maxVal) = 1;
	% 'BoxColor','white'

end