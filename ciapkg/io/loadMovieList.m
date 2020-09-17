function [outputMovie, movieDims, nPixels, nFrames] = loadMovieList(movieList, varargin)
	% Load movies, automatically detects type (avi, tif, or hdf5) and concatenates if multiple movies in a list.
	% Biafra Ahanonu
	% started: 2013.11.01
	% inputs
	% 	movieList = either a char string containing a path name or a cell array containing char strings, e.g. 'pathToFile' or {'path1','path2'}
	% outputs
	% 	outputMovie
	% 	movieDims
	% 	nPixels
	% 	nFrames
	% options
	% options.supportedTypes = {'.h5','.nwb','.hdf5','.tif','.tiff','.avi'};
	% % movie type
	% options.movieType = 'tiff';
	% % hierarchy name in hdf5 where movie is
	% options.inputDatasetName = '/1';
	% % convert file movie to double?
	% options.convertToDouble = 0;
	% % 'single','double'
	% options.loadSpecificImgClass = [];
	% % list of specific frames to load
	% options.frameList = [];
	% % should the waitbar be shown?
	% options.waitbarOn=1;
	% % just return the movie dimensions
	% options.getMovieDims = 0;
	% % treat movies in list as continuous with regards to frame
	% options.treatMoviesAsContinuous = 0;
	% NOTE: assume 3D movies with [x y frames] as dimensions, if movies are different sizes, use largest dimensions and align all movies to top-left corner

	% changelog
		% 2014.02.14 [14:14:39] now can load non-monotonic lists for avi and hdf5 files.
		% 2014.03.27 - several updates to speed up function, fixed several assumption issues (all movies same file type, etc.) and brought name scheme in line with other fxns
		% 2015.02.25 [15:32:10] fixed bug pertaining to treatMoviesAsContinuous not working properly if frameList was blank and only a single movie was input.
		% 2015.05.28 [02:39:51] bug fix with treatMoviesAsContinuous, the global frames weren't quite correct
		% 2016.02.23 [19:40:31] added in proper-ish ability to read in RGB grayscale AVI files
		% 2017.07.06 [20:13:53] improved getHdf5Info() subfxn to handle Jessica's HDF5 format in a more automatic fashion, e.g. if there is behavior or other group level data in the HDF5 file
		% 2018.02.16 [14:48:24] Fixed frame-by-frame HDF5 load being inefficient by using tmpMovie instead of loading directly into said movie
		% 2018.09.28 [16:49:29] HDF5 non-contiguous frame reading is faster, no looping since select multiple hyperslabs at once, see readHDF5Subset for more
		% 2019.01.16 [07:51:01] Added ISXD support (Inscopix format for v3+).
		% 2019.03.10 [19:28:47] Improve support for loading 1000s of TIF files by adding some performance improvements, ASSUMES that all tifs being loaded are from the same movie and have similar properties and dimensions. See options.onlyCheckFirstFileInfo.
		% 2019.06.06 [19:39:17] - Misc code fixes
		% 2019.10.07 [10:21:09] - Added h5info support and support for 16-bit float types.
		% 2019.10.09 [17:14:24] - Change dataset reading to handle HDF5 where main dataset is not a top-level directory OR it is a sub-directory that is not the only dataset in the HDF5.
		% 2020.04.05 [16:27:11] - Added check to support reading NWB as HDF5 file.
		% 2020.08.30 [10:16:08] - Change warning message output for HDF5 file of certain type.
		% 2020.08.31 [15:47:49] - Add option to suppress warnings.
	% TODO
		% OPEN
			% MAKE tiff loading recognize frameList input
			% verify movies are of supported load types, remove from list if not and alert user, should be an option (e.g. return instead) - DONE
			% allow user to input frames that are global across several files, e.g. [1:500 1:200 1:300] are the lengths of each movie, so if input [650:670] in frameList, should grab 150:170 from movie 2 - DONE, see treatMoviesAsContinuous option
		% DONE
			% Allow fallbacks for HDF5 dataset name, e.g. if can't find /1, look for /images
			% add preallocation by pre-reading each movie's dimensions - DONE
			% determine file type by properties of file instead of extension (don't trust input...)
			% remove need to use tmpMovie....
			% add ability to degrade gracefully with HDF5 dataset names, so try several backup datasetnames if one doesn't work

	% ========================
	options.supportedTypes = {'.h5','.hdf5','.nwb','.tif','.tiff','.avi','.isxd'};
	% movie type
	options.movieType = 'tiff';
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% Str: default NWB hierarchy names in HDF5 file where movie data is located, will look in the order indicates
	options.defaultNwbDatasetName = {'/acquisition/TwoPhotonSeries/data'};
	% fallback hierarchy name, e.g. '/images'
	options.inputDatasetNameBackup = [];
	% convert file movie to double?
	options.convertToDouble = 0;
	% 'single','double'
	options.loadSpecificImgClass = [];
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% Binary: 1 = read frame by frame to save memory, 0 = read continuous chunk.
	options.forcePerFrameRead = 0;
	% should the waitbar be shown?
	options.waitbarOn = 1;
	% just return the movie dimensions
	options.getMovieDims = 0;
	% treat movies in list as continuous with regards to frame
	options.treatMoviesAsContinuous = 0;
	% whether to display info
	options.displayInfo = 1;
	% whether to display diagnostic information
	options.displayDiagnosticInfo = 0;
	% whether to display diagnostic information
	options.displayWarnings = 1;
	% pre-specify the size, if need to get around memory re-allocation issues
	options.presetMovieSize = [];
	% Binary: 1 = avoid pre-allocating if single large matrix, saves memory
	options.largeMovieLoad = 0;
	% Int: [numParts framesPerPart] number of equal parts to load the movie in
	options.loadMovieInEqualParts = [];
	% Binary: 1 = only check information for 1st file then populate the rest with identical information, useful for folders with thousands of TIF or other images
	options.onlyCheckFirstFileInfo = 0;
	% Binary: 1 = h5info, 0 = hdf5info. DO NOT rely on this, will be deprecated/eliminated soon.
	options.useH5info = 1;
	% Int: [] = do nothing, 1-3 indicates R,G,B channels to take from multicolor RGB AVI
	options.rgbChannel = [];
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end

	startTime = tic;
	if options.displayInfo==1
		display(repmat('#',1,3))
	end
	% ========================
	% allow usr to input just a string if a single movie
	if ischar(movieList)
		movieList = {movieList};
	end

	% ========================
	% modify frameList if loading equal parts
	if ~isempty(options.loadMovieInEqualParts)
		fprintf('Loading %d equal parts of %d frames each\n',options.loadMovieInEqualParts(1),options.loadMovieInEqualParts(2))
		options.frameList = subfxnLoadEqualParts(movieList,options);
	end

	% ========================
	% remove unsupported files
	movieNo = 1;
	movieTypeList = cell([1 length(movieList)]);
	for iMovie = 1:length(movieList)
		thisMoviePath = movieList{iMovie};
		[options.movieType, supported] = getMovieFileType(thisMoviePath);
		movieTypeList{iMovie} = options.movieType;
		if supported==0
			subfxnDisplay(['removing unsupported file from list: ' thisMoviePath],options);
		else
			tmpMovieList{movieNo} = movieList{iMovie};
			movieNo = movieNo + 1;
		end
	end
	% if tmp doesn't exist, means no input files are valid, return
	if exist('tmpMovieList','var')
		movieList = tmpMovieList;
	else
		outputMovie = NaN;
		movieDims = NaN;
		nPixels = NaN;
		nFrames = NaN;
		if options.displayInfo==1
			toc(startTime);
			display(repmat('#',1,3))
		end
		return;
	end
	numMovies = length(movieList);

	% Test that Inscopix MATLAB API ISX package installed
	if any(strcmp(movieTypeList,'isxd'))==1
		inputFilePathCheck = movieList{find(strcmp(movieTypeList,'isxd'),1,'first')};
		try
			inputMovieIsx = isx.Movie.read(inputFilePathCheck);
		catch
			ciapkg.inscopix.loadIDPS();
		end
	end

	% ========================
	% pre-read each file to allow pre-allocation of output file
	reverseStr = '';
	for iMovie=1:numMovies
		thisMoviePath = movieList{iMovie};
		if options.onlyCheckFirstFileInfo==1&&iMovie>1
			fprintf('Adding movie #1 info to movie info for %d\\%d: %s\n',iMovie,numMovies,thisMoviePath);
			dims.x(iMovie) = dims.x(1);
			dims.y(iMovie) = dims.y(1);
			dims.z(iMovie) = dims.z(1);
			dims.one(iMovie) = dims.one(1);
			dims.two(iMovie) = dims.two(1);
			dims.three(iMovie) = dims.three(1);
			continue
		end
		if options.displayInfo==1
			fprintf('Getting movie info for %d\\%d: %s\n',iMovie,numMovies,thisMoviePath);
		end
		[options.movieType, supported] = getMovieFileType(thisMoviePath);
		if supported==0

		end
		switch options.movieType
			case 'tiff'
				if options.displayWarnings==0
					warning off
				end
				tiffHandle = Tiff(thisMoviePath, 'r');
				tmpFrame = tiffHandle.read();
				tiffHandle.close(); clear tiffHandle
				xyDims = size(tmpFrame);
				if options.displayWarnings==0
					warning on
				end

				dims.x(iMovie) = xyDims(1);
				dims.y(iMovie) = xyDims(2);
				dims.z(iMovie) = size(imfinfo(thisMoviePath),1);
				dims.one(iMovie) = xyDims(1);
				dims.two(iMovie) = xyDims(2);
				dims.three(iMovie) = size(imfinfo(thisMoviePath),1);

				if dims.z(iMovie)==1
					fileInfo = imfinfo(thisMoviePath);
					try
						numFramesStr = regexp(fileInfo.ImageDescription, 'images=(\d*)', 'tokens');
						nFrames = str2double(numFramesStr{1}{1});
					catch
						nFrames = 1;
					end
					dims.z(iMovie) = nFrames;
				end
			case 'hdf5'

				% Check if NWB file and alter input dataset name to default NWB if inputDatasetName does not point to a valid NWB dataset.
				[~,~,extTmp] = fileparts(thisMoviePath);
				if strcmp(extTmp,'.nwb')
					try
						h5info(thisMoviePath,options.inputDatasetName);
					catch
						for zCheck = 1:length(options.defaultNwbDatasetName)
							try
								options.inputDatasetName = options.defaultNwbDatasetName{zCheck};
								h5info(thisMoviePath,options.inputDatasetName);
							catch
								fprintf('Incorrect NWB dataset name: %s\n',options.inputDatasetName)
							end
						end
					end
				end
				clear extTmp zCheck;

				if options.useH5info==1
					hinfo = h5info(thisMoviePath);
				else
					hinfo = hdf5info(thisMoviePath);
				end
				[hReadInfo, thisDatasetName, datasetDims] = getHdf5Info();
				if options.displayDiagnosticInfo==1
					display(hReadInfo)
					hReadInfo.Name
				end
				hReadInfo.Dims = datasetDims;
				dims.x(iMovie) = hReadInfo.Dims(1);
				dims.y(iMovie) = hReadInfo.Dims(2);
				dims.z(iMovie) = hReadInfo.Dims(3);
				dims.one(iMovie) = hReadInfo.Dims(1);
				dims.two(iMovie) = hReadInfo.Dims(2);
				dims.three(iMovie) = hReadInfo.Dims(3);

				if ischar(options.inputDatasetName)
					tmpFrame = readHDF5Subset(thisMoviePath,[0 0 1],[dims.x(iMovie) dims.y(iMovie) 1],'datasetName',options.inputDatasetName,'displayInfo',options.displayInfo);
				else
					tmpFrame = readHDF5Subset(thisMoviePath,[0 0 1],[dims.x(iMovie) dims.y(iMovie) 1],'datasetName',thisDatasetName,'displayInfo',options.displayInfo);
				end
			case 'avi'
				xyloObj = VideoReader(thisMoviePath);
				dims.x(iMovie) = xyloObj.Height;
				dims.y(iMovie) = xyloObj.Width;
				dims.z(iMovie) = xyloObj.NumberOfFrames;
				dims.one(iMovie) = xyloObj.Height;
				dims.two(iMovie) = xyloObj.Width;
				dims.three(iMovie) = xyloObj.NumberOfFrames;
				tmpFrame = read(xyloObj, 1);
				% tmpFrame = readFrame(xyloObj);
			case 'isxd'
				inputMovieIsx = isx.Movie.read(thisMoviePath);
				nFrames = inputMovieIsx.timing.num_samples;
				xyDims = inputMovieIsx.spacing.num_pixels;
				dims.x(iMovie) = xyDims(1);
				dims.y(iMovie) = xyDims(2);
				dims.z(iMovie) = nFrames;
				dims.one(iMovie) = xyDims(1);
				dims.two(iMovie) = xyDims(2);
				dims.three(iMovie) = nFrames;
				tmpFrame = inputMovieIsx.get_frame_data(0);
		end
		if isempty(options.loadSpecificImgClass)
			imgClass = class(tmpFrame);
		else
			imgClass = options.loadSpecificImgClass;
		end
		% change dims.z if user specifies a list of frames
		if (~isempty(options.frameList)|options.frameList>dims.z(iMovie))&options.treatMoviesAsContinuous==0
			dims.z(iMovie) = length(options.frameList);
		end
		if options.displayInfo==1
			reverseStr = cmdWaitbar(iMovie,numMovies,reverseStr,'inputStr','checking movies','waitbarOn',options.waitbarOn,'displayEvery',10);
		end
	end
	if options.getMovieDims==1
		outputMovie = dims;
		if options.displayInfo==1
			toc(startTime);
			display(repmat('#',1,3))
		end
		return;
	end
	% dims
	xDimMax = max(dims.x);
	yDimMax = max(dims.y);
	switch options.treatMoviesAsContinuous
		case 0
			zDimLength = sum(dims.z);
		case 1
			if isempty(options.frameList)
				zDimLength = sum(dims.z);
			else
				zDimLength = length(options.frameList);
			end
		otherwise
			% body
	end
	% pre-allocated output structure, convert to input movie datatype
	% if strcmp(imgClass,'single')|strcmp(imgClass,'double')
	% 	if isempty(options.loadSpecificImgClass)
	% 		outputMovie = nan([xDimMax yDimMax zDimLength],imgClass);
	% 	else
	% 		display('pre-allocating single matrix...')
	% 		outputMovie = ones([xDimMax yDimMax zDimLength],imgClass);
	% 		% j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
	% 		% return;
	% 		outputMovie(:,:,:) = 0;
	% 	end
	% else
	% 	outputMovie = zeros([xDimMax yDimMax zDimLength],imgClass);
	% end

	% size(outputMovie)

	if options.treatMoviesAsContinuous==1&&~isempty(options.frameList)
		% totalZ = sum(dims.z);
		zdims = dims.z;
		frameList = options.frameList;
		zdimsCumsum = cumsum([0 zdims]);
		zdims = [1 zdims];
		for i=1:(length(zdims)-1)
			g{i} = frameList>zdimsCumsum(i)&frameList<=zdimsCumsum(i+1);
			globalFrame{i} = frameList(g{i}) - zdimsCumsum(i);
			dims.z(i) = length(globalFrame{i});
		end
		cellfun(@max,globalFrame,'UniformOutput',false)
		cellfun(@min,globalFrame,'UniformOutput',false)
		% pause
	else
		globalFrame = [];
	end

	% reshape movie if not including larger movies
	removeIdx = [];
	numList = 1:numMovies;
	for iMovie=numList
		if isempty(globalFrame)
			thisFrameList = options.frameList;
		else
			thisFrameList = globalFrame{iMovie};
			if isempty(thisFrameList)
				subfxnDisplay(['no global frames:' num2str(iMovie) '/' num2str(numMovies) ': ' thisMoviePath],options);
				removeIdx(end+1) = iMovie;
			end
		end
	end

	subfxnDisplay('-------',options);
	keepIdx = setdiff(numList,removeIdx);
	xDimMax = nanmax(dims.x(keepIdx));
	yDimMax = nanmax(dims.y(keepIdx));

	% pre-allocated output structure, convert to input movie datatype
	if options.largeMovieLoad==1
	else
		if strcmp(imgClass,'single')||strcmp(imgClass,'double')
			if isempty(options.loadSpecificImgClass)
				subfxnDisplay(['pre-allocating ' imgClass ' NaN matrix...'],options);
				outputMovie = NaN([xDimMax yDimMax zDimLength],imgClass);
			else
				subfxnDisplay('pre-allocating single ones matrix...',options);
				outputMovie = ones([xDimMax yDimMax zDimLength],imgClass);
				% j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
				% return;
				outputMovie(:,:,:) = 0;
			end
		else
			outputMovie = zeros([xDimMax yDimMax zDimLength],imgClass);
		end
	end
	subfxnDisplay('-------',options);
	% ========================
	for iMovie=1:numMovies
		thisMoviePath = movieList{iMovie};

		[options.movieType] = getMovieFileType(thisMoviePath);

		if isempty(globalFrame)
			thisFrameList = options.frameList;
		else
			thisFrameList = globalFrame{iMovie};
			if isempty(thisFrameList)
				subfxnDisplay(['no global frames:' num2str(iMovie) '/' num2str(numMovies) ': ' thisMoviePath],options);
				continue
			end
		end

		if options.displayInfo==1
			subfxnDisplay(['loading ' num2str(iMovie) '/' num2str(numMovies) ': ' thisMoviePath],options);
		end
		% depending on movie type, load differently
		switch options.movieType
			case 'tiff'
				% Pre-load the temporary image to reduce overhead and boost performance when loading many individual TIF images
				if iMovie==1&&options.onlyCheckFirstFileInfo==1
					thisMoviePath = movieList{iMovie};
					tiffHandle = Tiff(thisMoviePath, 'r');
					tmpFramePerma = tiffHandle.read();
					fileInfoH = imfinfo(thisMoviePath);
					displayInfoH = 1;
					NumberframeH = dims.z(iMovie);
				elseif options.onlyCheckFirstFileInfo==1&&iMovie>1
					displayInfoH = 0;
					NumberframeH = dims.z(iMovie);
				else
					% For all other cases (e.g. TIF stacks) don't alter
					tmpFramePerma = [];
					displayInfoH = 1;
					Numberframe = [];
					NumberframeH = [];
					fileInfoH = [];
				end

				if options.displayInfo==0
					displayInfoH = 0;
				end

				if numMovies==1
					if isempty(thisFrameList)
						outputMovie = load_tif_movie(thisMoviePath,1,'displayInfo',options.displayInfo);
						outputMovie = outputMovie.Movie;
					else
						outputMovie = load_tif_movie(thisMoviePath,1,'frameList',thisFrameList,'displayInfo',options.displayInfo);
						outputMovie = outputMovie.Movie;
					end
				else
					if isempty(thisFrameList)
						tmpMovie = load_tif_movie(thisMoviePath,1,'tmpImage',tmpFramePerma,'displayInfo',displayInfoH,'Numberframe',NumberframeH,'fileInfo',fileInfoH);
						tmpMovie = tmpMovie.Movie;
					else
						tmpMovie = load_tif_movie(thisMoviePath,1,'frameList',thisFrameList,'tmpImage',tmpFramePerma,'displayInfo',displayInfoH,'Numberframe',NumberframeH,'fileInfo',fileInfoH);
						tmpMovie = tmpMovie.Movie;
					end
				end
			% ========================
			case 'hdf5'
				if isempty(thisFrameList)&&options.forcePerFrameRead==0
					if options.useH5info==1
						hinfo = h5info(thisMoviePath);
					else
						hinfo = hdf5info(thisMoviePath);
					end
					% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
					% datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
					% thisDatasetName = strmatch(inputDatasetName,datasetNames);
					% hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
					hReadInfo = getHdf5Info();
					% read in the file
					% hReadInfo.Attributes
					if options.largeMovieLoad==1
						if options.useH5info==1
							outputMovie = h5read(thisMoviePath,options.inputDatasetName);
						else
							outputMovie = hdf5read(hReadInfo);
						end
					else
						if options.useH5info==1
							tmpMovie = h5read(thisMoviePath,options.inputDatasetName);
						else
							tmpMovie = hdf5read(hReadInfo);
						end
						if isempty(options.loadSpecificImgClass)
						else
							tmpMovie = cast(tmpMovie,imgClass);
						end
					end
				else
					% xxxx = 1;
					if sum(nanmin(diff(thisFrameList)==1))==1&&options.forcePerFrameRead==0
						% if contiguous segment of HDF5 file, read that in as one block to save time if user specifies as such
						inputFilePath = thisMoviePath;
						framesToGrab = thisFrameList;
						if options.useH5info==1
							hinfo = h5info(inputFilePath);
						else
							hinfo = hdf5info(inputFilePath);
						end
						% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
						[hReadInfo, thisDatasetName, datasetDims] = getHdf5Info();
						hReadInfo.Dims = datasetDims;
						xDim = hReadInfo.Dims(1);
						yDim = hReadInfo.Dims(2);

						subfxnDisplay(['loading movie as contiguous chunk: ' num2str([0 0 framesToGrab(1)-1]) ' | ' num2str([xDim yDim length(framesToGrab)])],options);
						% tmpMovie = readHDF5Subset(inputFilePath,[0 0 framesToGrab(1)-1],[xDim yDim length(framesToGrab)],'datasetName',options.inputDatasetName);
						% size(tmpMovie)
						% size(outputMovie)
						if ischar(options.inputDatasetName)
							tmpMovie = readHDF5Subset(inputFilePath,[0 0 framesToGrab(1)-1],[xDim yDim length(framesToGrab)],'datasetName',options.inputDatasetName,'displayInfo',options.displayInfo);
						else
							tmpMovie = readHDF5Subset(inputFilePath,[0 0 framesToGrab(1)-1],[xDim yDim length(framesToGrab)],'datasetName',thisDatasetName,'displayInfo',options.displayInfo);
						end
					else
						subfxnDisplay('Read frame-by-frame',options)
						% read frame-by-frame to save space
						inputFilePath = thisMoviePath;
						if options.useH5info==1
							hinfo = h5info(inputFilePath);
						else
							hinfo = hdf5info(inputFilePath);
						end
						% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
						[hReadInfo, thisDatasetName, datasetDims] = getHdf5Info();
						hReadInfo.Dims = datasetDims;
						xDim = hReadInfo.Dims(1);
						yDim = hReadInfo.Dims(2);
						% tmpMovie = readHDF5Subset(inputFilePath,[0 0 thisFrameList(1)],[xDim yDim length(thisFrameList)],'datasetName',options.inputDatasetName);
						framesToGrab = thisFrameList;
						if isempty(thisFrameList)&&options.forcePerFrameRead==1
							framesToGrab = 1:dims.z(iMovie);
						end
						nFrames = length(framesToGrab);
						% reverseStr = '';

						for iframe = 1:nFrames
							readFrame = framesToGrab(iframe);
							offsetT{iframe} = [0 0 readFrame-1];
							blockT{iframe} = [xDim yDim 1];
						end
						if ischar(options.inputDatasetName)
							thisFrame = readHDF5Subset(inputFilePath,offsetT,blockT,'datasetName',options.inputDatasetName,'displayInfo',0);
						else
							thisFrame = readHDF5Subset(inputFilePath,offsetT,blockT,'datasetName',thisDatasetName,'displayInfo',0);
						end
						if isempty(options.loadSpecificImgClass)
							% tmpMovie(:,:,iframe) = thisFrame;
							outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:nFrames) = thisFrame;
						else
							% assume 3D movies with [x y frames] as dimensions
							if(iMovie==1)
								outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:nFrames) = cast(thisFrame,imgClass);
							else
								zOffset = sum(dims.z(1:iMovie-1));
								outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+1:nFrames)) = cast(thisFrame,imgClass);
							end
						end
						% if options.displayInfo==1
						% 	reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading hdf5','waitbarOn',options.waitbarOn,'displayEvery',50);
						% end

						% for iframe = 1:nFrames
						% 	readFrame = framesToGrab(iframe);
						% 	if ischar(options.inputDatasetName)
						% 		thisFrame = readHDF5Subset(inputFilePath,[0 0 readFrame-1],[xDim yDim 1],'datasetName',options.inputDatasetName,'displayInfo',0);
						% 	else
						% 		thisFrame = readHDF5Subset(inputFilePath,[0 0 readFrame-1],[xDim yDim 1],'datasetName',thisDatasetName,'displayInfo',0);
						% 	end
						% 	if isempty(options.loadSpecificImgClass)
						% 		% tmpMovie(:,:,iframe) = thisFrame;
						% 		outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),iframe) = thisFrame;
						% 	else
						%     	% assume 3D movies with [x y frames] as dimensions
						% 	    if(iMovie==1)
						% 			outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),iframe) = cast(thisFrame,imgClass);
						% 	    else
						% 	    	zOffset = sum(dims.z(1:iMovie-1));
						% 	    	outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+iframe)) = cast(thisFrame,imgClass);
						% 	    end
						% 	end
						% 	if options.displayInfo==1
						% 		reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading hdf5','waitbarOn',options.waitbarOn,'displayEvery',50);
						% 	end
						% end
					end
				end
			% ========================
			case 'avi'
				xyloObj = VideoReader(thisMoviePath);

				if isempty(thisFrameList)
					nFrames = xyloObj.NumberOfFrames;
					framesToGrab = 1:nFrames;
				else
					nFrames = length(thisFrameList);
					framesToGrab = thisFrameList;
				end
				vidHeight = xyloObj.Height;
				vidWidth = xyloObj.Width;

				% Preallocate movie structure.
				tmpMovie = zeros(vidHeight, vidWidth, nFrames, 'uint8');

				% Read one frame at a time.
				reverseStr = '';
				iframe = 1;
				nFrames = length(framesToGrab);
				for iframe = 1:nFrames
					readFrame = framesToGrab(iframe);
					tmpAviFrame = read(xyloObj, readFrame);
					% check if frame is RGB or grayscale, if RGB only take one channel (since they will be identical for RGB grayscale)
					if size(tmpAviFrame,3)==3&isempty(options.rgbChannel)
						tmpAviFrame = squeeze(tmpAviFrame(:,:,1));
					elseif ~isempty(options.rgbChannel)
						tmpAviFrame = squeeze(tmpAviFrame(:,:,options.rgbChannel));
					end
					tmpMovie(:,:,iframe) = tmpAviFrame;
					% reduce waitbar access
					if options.displayInfo==1
						reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading avi','waitbarOn',options.waitbarOn,'displayEvery',50);
					end
					iframe = iframe + 1;
				end
			% ========================
			case 'isxd'
				% Setup movie class
				inputMovieIsx = isx.Movie.read(thisMoviePath);
				nFramesHere = inputMovieIsx.timing.num_samples;
				xyDims = inputMovieIsx.spacing.num_pixels;

				if isempty(thisFrameList)
					nFrames = nFramesHere;
					framesToGrab = 1:nFrames;
				else
					nFrames = length(thisFrameList);
					framesToGrab = thisFrameList;
				end
				vidHeight = xyDims(1);
				vidWidth = xyDims(2);

				% Preallocate movie structure.
				tmpMovie = zeros(vidHeight, vidWidth, nFrames, imgClass);

				% Read one frame at a time.
				reverseStr = '';
				iframe = 1;
				nFrames = length(framesToGrab);
				for iframe = 1:nFrames
					readFrame = framesToGrab(iframe);
					tmpAviFrame = inputMovieIsx.get_frame_data(readFrame-1);
					% tmpAviFrame = read(xyloObj, readFrame);
					% check if frame is RGB or grayscale, if RGB only take one channel (since they will be identical for RGB grayscale)
					% if size(tmpAviFrame,3)==3
					% 	tmpAviFrame = squeeze(tmpAviFrame(:,:,1));
					% end
					tmpMovie(:,:,iframe) = tmpAviFrame;
					% reduce waitbar access
					if options.displayInfo==1
						reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading ISXD','waitbarOn',options.waitbarOn,'displayEvery',50);
					end
					iframe = iframe + 1;
				end
			% ========================
			otherwise
				% let's just not deal with this for now
				return;
		end
		if exist('tmpMovie','var')
			if iMovie==1
				outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:dims.z(iMovie)) = tmpMovie;
				% outputMovie(:,:,:) = tmpMovie;
			else
				% assume 3D movies with [x y frames] as dimensions
				zOffset = sum(dims.z(1:iMovie-1));
				outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+1):(zOffset+dims.z(iMovie))) = tmpMovie;
				% outputMovie(:,:,end+1:end+size(tmpMovie,3)) = tmpMovie;
			end
			clear tmpMovie;
		else

		end
	end

	% hinfo = hdf5info('A:\shared\concatenated_2013_07_05_p62_m728_MAG1.h5');
	% DFOF = hdf5read(hinfo.GroupHierarchy.Datasets(1));
	% get size of movie
	% DFOFsize = size(DFOF.Movie);
	movieDims = size(outputMovie);
	nPixels = movieDims(1)*movieDims(2);
	if length(movieDims)==2
		nFrames = 1;
	else
		nFrames = movieDims(3);
	end
	if options.waitbarOn==1
		subfxnDisplay(['movie class: ' class(outputMovie)],options);
		subfxnDisplay(['movie size: ' num2str(size(outputMovie))],options);
		subfxnDisplay(['x-dims: ' num2str(dims.x)],options);
		subfxnDisplay(['y-dims: ' num2str(dims.y)],options);
		subfxnDisplay(['z-dims: ' num2str(dims.z)],options);
	end
	j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;
	subfxnDisplay(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class],options);
	% display(dims);
	% Convert the movie to single
	% DFOF=single(DFOF);
	if options.convertToDouble==1
		subfxnDisplay('converting to double...',options);
		outputMovie=double(outputMovie);
	end

	if options.displayInfo==1
		toc(startTime);
		display(repmat('#',1,3))
	end

	function [hReadInfo, thisDatasetName, datasetDims] = getHdf5Info()
		if ischar(options.inputDatasetName)
			try
				if options.useH5info==1
					datasetNames = {hinfo.Datasets.Name};
					% Strip leading forward slash for h5info compatability
					thisDatasetName = strcmp(options.inputDatasetName(2:end),datasetNames);
					hReadInfo = hinfo.Datasets(thisDatasetName);
					if isempty(hReadInfo)
						hReadInfo = h5info(thisMoviePath,options.inputDatasetName);
						thisDatasetName = options.inputDatasetName;
					end
					datasetDims = hReadInfo.Dataspace.Size;
				else
					datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
					thisDatasetName = strcmp(options.inputDatasetName,datasetNames);
					hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
					if isempty(hReadInfo)
						hReadInfo = h5info(thisMoviePath,options.inputDatasetName);
						datasetDims = hReadInfo.Dataspace.Size;
						thisDatasetName = options.inputDatasetName;
					else
						datasetDims = hReadInfo.Dims;
					end
				end
			catch err
				try
					if options.displayDiagnosticInfo==1
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
						h5disp(thisMoviePath)
					elseif options.displayWarnings==1
						warning('HDF5 dataset name not found in hinfo.Datasets.Name. Trying another method to load HDF5 dataset.')
					end
				catch
				end
				try
					hReadInfo = h5info(thisMoviePath,options.inputDatasetName);
					datasetDims = hReadInfo.Dataspace.Size;
					thisDatasetName = options.inputDatasetName;
				catch err
					try
						if options.displayDiagnosticInfo==1
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						elseif options.displayWarnings==1
							warning('Could not find %s in %s.',options.inputDatasetName,thisMoviePath)
						end
					catch
					end
					try
						datasetNames = {hinfo.GroupHierarchy.Groups.Datasets.Name};
						thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
						hReadInfo = hinfo.GroupHierarchy.Groups.Datasets(thisDatasetName);
					catch err
						try
							if options.displayDiagnosticInfo==1
								disp(repmat('@',1,7))
								disp(getReport(err,'extended','hyperlinks','on'));
								disp(repmat('@',1,7))
							elseif options.displayWarnings==1
								warning('HDF5 hinfo.GroupHierarchy.Groups.Datasets contains no dataset %s.',thisDatasetName)
							end
						catch
						end
						nGroups = length(hinfo.GroupHierarchy.Groups);
						datasetNames = {};
						for groupNo = 1:nGroups
							datasetNames{groupNo} = hinfo.GroupHierarchy.Groups(groupNo).Datasets.Name;
						end
						thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
						thisGroupNo = strmatch(options.inputDatasetName,datasetNames);
						% hReadInfo = hinfo.GroupHierarchy.Groups(thisDatasetName).Datasets;
						% hinfo.GroupHierarchy.Groups(thisGroupNo).Datasets.Name
						thisDatasetNo = strmatch(options.inputDatasetName,{hinfo.GroupHierarchy.Groups(thisGroupNo).Datasets.Name});
						hReadInfo = hinfo.GroupHierarchy.Groups(thisGroupNo).Datasets(thisDatasetNo);
					end
				end
			end
		else
			hReadInfo = hinfo.GroupHierarchy.Datasets(options.inputDatasetName);
			thisDatasetName = hinfo.GroupHierarchy.Datasets(options.inputDatasetName).Name;
		end
	end
end

function [movieType, supported] = getMovieFileType(thisMoviePath)
	% determine how to load movie, don't assume every movie in list is of the same type
	supported = 1;
	try
		[pathstr,name,ext] = fileparts(thisMoviePath);
	catch
		movieType = '';
		supported = 0;
		return;
	end
	% files are assumed to be named correctly (lying does no one any good)
	if strcmp(ext,'.h5')||strcmp(ext,'.hdf5')
		movieType = 'hdf5';
	elseif strcmp(ext,'.nwb')
		movieType = 'hdf5';
	elseif strcmp(ext,'.tif')||strcmp(ext,'.tiff')
		movieType = 'tiff';
	elseif strcmp(ext,'.avi')
		movieType = 'avi';
	elseif strcmp(ext,'.isxd')
		movieType = 'isxd';
	else
		movieType = '';
		supported = 0;
	end
end
function subfxnDisplay(str,options)
	if options.displayInfo==1
		disp(str)
	end
end

function frameListTmp = subfxnLoadEqualParts(movieList,options)
	movieDims = loadMovieList(movieList,'convertToDouble',options.convertToDouble,'frameList',[],'inputDatasetName',options.inputDatasetName,'treatMoviesAsContinuous',options.treatMoviesAsContinuous,'loadSpecificImgClass',options.loadSpecificImgClass,'getMovieDims',1);

	loadMovieInEqualParts = options.loadMovieInEqualParts(1);
	defaultNumFrames = options.loadMovieInEqualParts(2);
	tmpList = round(linspace(1,sum(movieDims.z)-defaultNumFrames,loadMovieInEqualParts));
	display(['tmpList' num2str(tmpList)])
	tmpList = bsxfun(@plus,tmpList,[1:defaultNumFrames]');

	frameListTmp = tmpList(:);
	frameListTmp(frameListTmp<1) = [];
	frameListTmp(frameListTmp>sum(movieDims.z)) = [];
	frameListTmp = unique(frameListTmp);

	% [primaryMovie] = loadMovieList(movieListTmp2,'convertToDouble',0,'frameList',frameListTmp(:),'treatMoviesAsContinuous',treatMoviesAsContinuous,'inputDatasetName',obj.inputDatasetName);
end
