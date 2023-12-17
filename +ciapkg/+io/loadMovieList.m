function [outputMovie, movieDims, nPixels, nFrames] = loadMovieList(movieList, varargin)
	% [outputMovie, movieDims, nPixels, nFrames] = loadMovieList(movieList, varargin)
	% 
	% Load movies, automatically detects type (avi, tif, or hdf5) and concatenates if multiple movies in a list.
	% 	NOTE:
	% 		The function assumes input is 2D time series movies with [x y frames] as dimensions
	% 		If movies are different sizes, use largest dimensions and align all movies to top-left corner.
	% 
	% Biafra Ahanonu
	% started: 2013.11.01
	% 
	% Inputs
	% 	movieList = either a char string containing a path name or a cell array containing char strings, e.g. 'pathToFile' or {'path1','path2'}
	% 
	% Outputs
	% 	outputMovie - [x y frame] matrix.
	% 	movieDims - structure containing x,y,z information for the movie.
	% 	nPixels - total number of pixels in the movie across all frames.
	% 	nFrames - total number of frames in the movie depending on user requests in option.frameList.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	%	% Int vector: list of specific frames to load.
	%	options.frameList = [];
	%	% Str: path to MAT-file to load movie into, e.g. when conducting processing on movies that are larger than RAM.
	%	options.matfile = '';
	%	% Str: Variable name for movie to store MAT-file in. DO NOT CHANGE for the moment.
	%	options.matfileVarname = 'outputMovie';
	%	% Cell array of str: list of supported file types, in general DO NOT change.
	%	options.supportedTypes = {'.h5','.hdf5','.tif','.tiff','.avi',...
	%		'.nwb',... % Neurodata Without Borders format
	%		'.isxd',... % Inscopix format
	%		'.oir',... % Olympus formats
	%		'.czi','.lsm'... % Zeiss formats
	%	};
	%	% Str: movie type.
	%	options.movieType = 'tiff';
	%	% Str: hierarchy name in HDF5 file where movie data is located.
	%	options.inputDatasetName = '/1';
	%	% Str: default NWB hierarchy names in HDF5 file where movie data is located, will look in the order indicates
	%	options.defaultNwbDatasetName = {'/acquisition/TwoPhotonSeries/data'};
	%	% Str: fallback hierarchy name, e.g. '/images'
	%	options.inputDatasetNameBackup = [];
	%	% Binary: 1 = convert file movie to double, 0 = keep original format.
	%	options.convertToDouble = 0;
	%	% Str: 'single','double'
	%	options.loadSpecificImgClass = [];
	%	% Binary: 1 = read frame by frame to save memory, 0 = read continuous chunk.
	%	options.forcePerFrameRead = 0;
	%	% Binary: 1 = waitbar/progress bar is shown, 0 = no progress shown.
	%	options.waitbarOn = 1;
	%	% Binary: 1 = just return the movie dimensions, do not load the movie.
	%	options.getMovieDims = 0;
	%	% Binary: 1 = treat movies in list as continuous with regards to frames to extract.
	%	options.treatMoviesAsContinuous = 0;
	%	% Binary: 1 = whether to display info on command line.
	%	options.displayInfo = 1;
	%	% Binary: Whether to display diagnostic information
	%	options.displayDiagnosticInfo = 0;
	%	% Binary: 1 = display diagnostic information, 0 = do not display diagnostic information.
	%	options.displayWarnings = 1;
	%	% Matrix: Pre-specify the size, if need to get around memory re-allocation issues
	%	options.presetMovieSize = [];
	%	% Binary: 1 = avoid pre-allocating if single large matrix, saves memory. 0 = pre-allocate matrix.
	%	options.largeMovieLoad = 0;
	%	% Int: [numParts framesPerPart] number of equal parts to load the movie in
	%	options.loadMovieInEqualParts = [];
	%	% Binary: 1 = only check information for 1st file then populate the rest with identical information, useful for folders with thousands of TIF or other images
	%	options.onlyCheckFirstFileInfo = 0;
	%	% Binary: 1 = h5info, 0 = hdf5info. DO NOT rely on this, will be deprecated/eliminated soon.
	%	options.useH5info = 1;
	%	% Int: [] = do nothing, 1-3 indicates R,G,B channels to take from multicolor RGB AVI
	%	options.rgbChannel = [];
	%	% Int: Bio-Formats series number to load.
	%	options.bfSeriesNo = 1;
	%	% Int: Bio-Formats channel number to load.
	%	options.bfChannelNo = 1;
	%	% Cell array: Store file information, e.g. make TIFF reading faster.
	%	options.fileInfo = {};

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
		% 2020.10.19 [12:11:14] - Improved comments and options descriptions.
		% 2021.02.15 [11:55:36] - Fixed loading HDF5 datasetname that has only a single frame, loadMovieList would ask for 3rd dimension information that did not exist.
		% 2021.06.21 [10:22:32] - Added support for Bio-Formats compatible files, specifically Olympus (OIR) and Zeiss (CZI, LSM).
		% 2021.06.28 [16:57:27] - Added check that deals with users requesting more frames than are in the movie in the case where "options.largeMovieLoad==1" and a matrix is pre-allocated.
		% 2021.06.30 [12:26:12] - Added additional checks for frameList to remove if negative or zero along with additional checks during movie loading to prevent loading frames outside movie extent.
		% 2021.07.03 [08:55:06] - dims.three fix for reading tifs, esp. ImageJ >4GB.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.08.13 [02:31:48] - Added HDF5 capitalized file extension.
        % 2021.08.26 [16:15:37] - Ensure that loadMovieList has all output arguments set no matter return conditions.
        % 2022.02.24 [10:24:28] - AVI now read(...,'native') is faster.
		% 2022.03.07 [15:56:58] - Speed improvements related to imfinfo calls.
		% 2022.03.13 [19:43:23] - Add option to load movie into a MAT-file.
		% 2022.03.23 [22:24:46] - Improve Bio-Formats support, including using bfGetPlane to partially load data along with adding ndpi support.
		% 2022.07.05 [21:21:35] - Add SlideBook Bio-Formats support. Remove local function getMovieFileType to force use of CIAtah getMovieFileType function. Updated getIndex call to avoid issues with certain Bio-Formats. Ensure getting correct Bio-Formats frames and loadMovieList output.
		% 2022.07.28 [18:44:47] - Hide TIF warnings.
		% 2022.10.24 [10:32:25] - Added mp4 support.
		% 2022.10.27 [18:33:58] - Update AVI support to do additional cdata checks.
		% 2022.12.02 [16:04:03] - To reduce automatic conversion to double when reading HDF5 with largeMovieLoad=1 and a specific set of frames, force outputMovie default value to be single. This is made consistent across all image types, checks if float or not then re-initializes default outputMovie.
        
	% TODO
		% OPEN
			% Bio-Formats
				% Allow outputting as a [x y c t] matrix to allow support for multiple color channels without needing to re-read file multiple times.
			% Determine file type by properties of file instead of extension (don't trust input...)
			% Remove all use of tmpMovie....
			% Add ability to degrade gracefully with HDF5 dataset names, so try several backup datasetnames if one doesn't work.
			% Allow fallbacks for HDF5 dataset name, e.g. if can't find /1, look for /images. Might never add this as it opens up dangers of loading the incorrect dataset if a user makes a mistake, better to give out a warning.
		% DONE
			% allow user to input frames that are global across several files, e.g. [1:500 1:200 1:300] are the lengths of each movie, so if input [650:670] in frameList, should grab 150:170 from movie 2 - DONE, see treatMoviesAsContinuous option.
			% verify movies are of supported load types, remove from list if not and alert user, should be an option (e.g. return instead) - DONE
			% MAKE tiff loading recognize frameList input. - DONE
			% Add preallocation by pre-reading each movie's dimensions - DONE

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% Str: path to MAT-file to load movie into, e.g. when conducting processing on movies that are larger than RAM.
	options.matfile = '';
	% Str: Variable name for movie to store MAT-file in. DO NOT CHANGE for the moment.
	options.matfileVarname = 'outputMovie';
	% Cell array of str: list of supported file types, in general DO NOT change.
	options.supportedTypes = {'.h5','.hdf5','.tif','.tiff','.avi',...
		'.nwb',... % Neurodata Without Borders format
		'.isxd',... % Inscopix format
		'.oir',... % Olympus formats
		'.czi','.lsm'... % Zeiss formats
	};
	% Str: movie type.
	options.movieType = 'tiff';
	% Str: hierarchy name in HDF5 file where movie data is located.
	options.inputDatasetName = '/1';
	% Str: default NWB hierarchy names in HDF5 file where movie data is located, will look in the order indicates
	options.defaultNwbDatasetName = {'/acquisition/TwoPhotonSeries/data'};
	% Str: fallback hierarchy name, e.g. '/images'
	options.inputDatasetNameBackup = [];
	% Binary: 1 = convert file movie to double, 0 = keep original format.
	options.convertToDouble = 0;
	% Str: 'single','double'
	options.loadSpecificImgClass = [];
	% Binary: 1 = read frame by frame to save memory, 0 = read continuous chunk.
	options.forcePerFrameRead = 0;
	% Binary: 1 = waitbar/progress bar is shown, 0 = no progress shown.
	options.waitbarOn = 1;
	% Binary: 1 = just return the movie dimensions, do not load the movie.
	options.getMovieDims = 0;
	% Binary: 1 = treat movies in list as continuous with regards to frames to extract.
	options.treatMoviesAsContinuous = 0;
	% Binary: 1 = whether to display info on command line.
	options.displayInfo = 1;
	% Binary: Whether to display diagnostic information
	options.displayDiagnosticInfo = 0;
	% Binary: 1 = display diagnostic information, 0 = do not display diagnostic information.
	options.displayWarnings = 1;
	% Matrix: Pre-specify the size, if need to get around memory re-allocation issues
	options.presetMovieSize = [];
	% Binary: 1 = avoid pre-allocating if single large matrix, saves memory. 0 = pre-allocate matrix.
	options.largeMovieLoad = 0;
	% Int: [numParts framesPerPart] number of equal parts to load the movie in
	options.loadMovieInEqualParts = [];
	% Binary: 1 = only check information for 1st file then populate the rest with identical information, useful for folders with thousands of TIF or other images
	options.onlyCheckFirstFileInfo = 0;
	% Binary: 1 = h5info, 0 = hdf5info. DO NOT rely on this, will be deprecated/eliminated soon.
	options.useH5info = 1;
	% Int: [] = do nothing, 1-3 indicates R,G,B channels to take from multicolor RGB AVI
	options.rgbChannel = [];
	% Int: Bio-Formats series number to load.
	options.bfSeriesNo = 0;
	% Int: Bio-Formats channel number to load.
	options.bfChannelNo = 1;
	% Int: Bio-Formats z dimension to load.
	options.bfZdimNo = 1;
	% Cell array: Store file information, e.g. make TIFF reading faster.
	options.fileInfo = {};
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end

	startTime = tic;
    
    % Ensure all output arguments set
    outputMovie = NaN('single');
    movieDims = NaN;
    nPixels = NaN;
    nFrames = NaN;
        
	if options.displayInfo==1
		display(repmat('#',1,3))
	end

	% ========================
	% Create MAT-file object and variable
	if ~isempty(options.matfile)
		save(options.matfile,'outputMovie','-v7.3');
		matObj = matfile(options.matfile,'Writable',true);

		% There is no need to pre-allocate the MAT-file, skip.
		options.largeMovieLoad = 1;
	end

	% ========================
	% Allow usr to input just a string if a single movie
	if ischar(movieList)
		movieList = {movieList};
    end
    % Setup file info.
    if isempty(options.fileInfo)
        options.fileInfo = cell([1 length(movieList)]);
    end

	% ========================
	% modify frameList if loading equal parts
	if ~isempty(options.loadMovieInEqualParts)
		fprintf('Loading %d equal parts of %d frames each\n',options.loadMovieInEqualParts(1),options.loadMovieInEqualParts(2))
		options.frameList = subfxnLoadEqualParts(movieList,options);
	end

	% Remove any frames that are zero or negative, not valid.
	if ~isempty(options.frameList)
        if any(options.frameList<1)
            subfxnDisplay(['Removing invalid frames from user input frame list (negative or zero).'],options);
            options.frameList(options.frameList<1) = [];
        end
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
				warning off
				tiffHandle = Tiff(thisMoviePath, 'r+');
				warning on
				tmpFrame = tiffHandle.read();
				xyDims = size(tmpFrame);
                options.fileInfo{iMovie} = imfinfo(thisMoviePath,'tif');
                % nTiles = numberOfTiles(tiffHandle);
                nTiles = size(options.fileInfo{iMovie},1);;
				if options.displayWarnings==0
					warning on
				end

				% dims.class{iMovie} = class(tmpFrame);
				dims.x(iMovie) = xyDims(1);
				dims.y(iMovie) = xyDims(2);
				% dims.z(iMovie) = size(imfinfo(thisMoviePath),1);
				dims.z(iMovie) = nTiles;
				dims.one(iMovie) = xyDims(1);
				dims.two(iMovie) = xyDims(2);
				% dims.three(iMovie) = size(imfinfo(thisMoviePath),1);
                dims.three(iMovie) = nTiles;

				if dims.z(iMovie)==1
					% fileInfo = imfinfo(thisMoviePath,'tif');
                    fileInfo = options.fileInfo{iMovie};
					try
						numFramesStr = regexp(fileInfo.ImageDescription, 'images=(\d*)', 'tokens');
						nFrames = str2double(numFramesStr{1}{1});
					catch
						% Try to grab using TIFF library
						try
							nFrames = tiffHandle.numberOfTiles;
						catch
							nFrames = 1;
						end
					end
					dims.z(iMovie) = nFrames;
					dims.three(iMovie) = nFrames;
				end
				tiffHandle.close(); clear tiffHandle
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
				dims.one(iMovie) = hReadInfo.Dims(1);
				dims.two(iMovie) = hReadInfo.Dims(2);
				% Check 3rd dimension exists
				if length(hReadInfo.Dims)>=3
					dims.z(iMovie) = hReadInfo.Dims(3);
					dims.three(iMovie) = hReadInfo.Dims(3);
				else
					dims.z(iMovie) = 0;
					dims.three(iMovie) = 0;
				end

				if dims.z(iMovie)
					offsetTmp = [0 0 1];
					blockTmp = [dims.x(iMovie) dims.y(iMovie) 1];
				else
					offsetTmp = [0 0];
					blockTmp = [dims.x(iMovie) dims.y(iMovie)];
				end
				if ischar(options.inputDatasetName)
					tmpDataset = options.inputDatasetName;
				else
					tmpDataset = thisDatasetName;
				end
				tmpFrame = readHDF5Subset(thisMoviePath,offsetTmp,blockTmp,'datasetName',tmpDataset,'displayInfo',options.displayInfo);
			case {'avi','mp4'}
				xyloObj = VideoReader(thisMoviePath);
				dims.x(iMovie) = xyloObj.Height;
				dims.y(iMovie) = xyloObj.Width;
				dims.z(iMovie) = xyloObj.NumberOfFrames;
				dims.one(iMovie) = xyloObj.Height;
				dims.two(iMovie) = xyloObj.Width;
				dims.three(iMovie) = xyloObj.NumberOfFrames;
				tmpFrame = read(xyloObj, 1, 'native');
				try
					if isstruct(tmpFrame)==1
						tmpFrame = tmpFrame.cdata;
					else
						% Do nothing
					end
				catch
				end
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
			case 'bioformats'
				bfreaderTmp = bfGetReader(thisMoviePath);
				bfreaderTmp.setSeries(options.bfSeriesNo);

				omeMeta = bfreaderTmp.getMetadataStore();
				stackSizeX = omeMeta.getPixelsSizeX(options.bfSeriesNo).getValue(); % image width, pixels
				stackSizeY = omeMeta.getPixelsSizeY(options.bfSeriesNo).getValue(); % image height, pixels
				stackSizeZ = omeMeta.getPixelsSizeZ(options.bfSeriesNo).getValue();
				% Get time points (frames) for this series
				nFrames = bfreaderTmp.getSizeT;

				xyDims = [stackSizeY stackSizeX];
				dims.x(iMovie) = xyDims(1);
				dims.y(iMovie) = xyDims(2);
				dims.z(iMovie) = nFrames;
				dims.one(iMovie) = xyDims(1);
				dims.two(iMovie) = xyDims(2);
				dims.three(iMovie) = nFrames;

				iPlane = bfreaderTmp.getIndex(0, options.bfChannelNo-1, 0)+1;
				tmpFrame = bfGetPlane(bfreaderTmp, iPlane);
				nChannels = omeMeta.getChannelCount(options.bfSeriesNo);
		end
		if isempty(options.loadSpecificImgClass)
			imgClass = class(tmpFrame);
		else
			imgClass = options.loadSpecificImgClass;
		end

		% Change the default outputMovie to be the right class depending on the input movie's class
		if any(strcmp(imgClass,{'single','double'}))
			outputMovie = NaN(imgClass);
		else
			outputMovie = zeros([1],imgClass);
		end

		% change dims.z if user specifies a list of frames
		if (~isempty(options.frameList)|options.frameList>dims.z(iMovie))&options.treatMoviesAsContinuous==0
			% Disallow frames that are longer than the length of the movie
			frameListTmp = options.frameList;
			if any(frameListTmp>dims.three(iMovie))
				rmIDx = frameListTmp>dims.three(iMovie);
				if options.displayInfo==1
					fprintf('Removing %d frames outside movie length.\n',sum(rmIDx));
				end
				frameListTmp(rmIDx) = [];
			else
			end
			dims.z(iMovie) = length(frameListTmp);
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
				frameListTmp = options.frameList;
				zDimLength = length(frameListTmp);
				if any(zDimLength>sum(dims.three))
					rmIDx = frameListTmp>sum(dims.three);
					if options.displayInfo==1
						fprintf('Removing %d frames outside movie length.\n',sum(rmIDx));
					end
					frameListTmp(rmIDx) = [];
					zDimLength = length(frameListTmp);
				end
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
		disp([cellfun(@max,globalFrame,'UniformOutput',false); cellfun(@min,globalFrame,'UniformOutput',false)])
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
				preallocSize = [xDimMax yDimMax zDimLength];
				subfxnDisplay(['pre-allocating ' imgClass ' NaN matrix: ' num2str(preallocSize)],options);
				outputMovie = NaN(preallocSize,imgClass);
			else
				preallocSize = [xDimMax yDimMax zDimLength];
				% subfxnDisplay('pre-allocating single ones matrix...',options);
				subfxnDisplay(['pre-allocating ' imgClass ' ones matrix: ' num2str(preallocSize)],options);
				outputMovie = ones(preallocSize,imgClass);
				% j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
				% return;
				outputMovie(:,:,:) = 0;
			end
		else
			preallocSize = [xDimMax yDimMax zDimLength];
			% subfxnDisplay('pre-allocating single zeros matrix...',options);
			subfxnDisplay(['pre-allocating ' imgClass ' zeros matrix: ' num2str(preallocSize)],options);
			outputMovie = zeros(preallocSize,imgClass);
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

		% Remove any frames that are outside the movie length.
		if any(thisFrameList>dims.three(iMovie))
			rmIDx2 = thisFrameList>dims.three(iMovie);
			if options.displayInfo==1
				fprintf('Removing %d frames outside movie length.\n',sum(rmIDx2));
			end
			thisFrameList(rmIDx2) = [];
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
					% fileInfoH = imfinfo(thisMoviePath,'tif');
                    fileInfoH = options.fileInfo{iMovie};
					displayInfoH = 1;
					NumberframeH = dims.z(iMovie);
				elseif options.onlyCheckFirstFileInfo==1&&iMovie>1
					displayInfoH = 0;
					NumberframeH = dims.z(iMovie);
                    fileInfoH = options.fileInfo{iMovie};
				else
					% For all other cases (e.g. TIF stacks) don't alter
					tmpFramePerma = [];
					displayInfoH = 1;
					Numberframe = [];
					NumberframeH = [];
					fileInfoH = options.fileInfo{iMovie};
				end

				if options.displayInfo==0
					displayInfoH = 0;
				end

				if numMovies==1
					if isempty(thisFrameList)
						outputMovie = load_tif_movie(thisMoviePath,1,'displayInfo',options.displayInfo,'fileInfo',fileInfoH);
						% outputMovie = outputMovie.Movie;
					else
						outputMovie = load_tif_movie(thisMoviePath,1,'frameList',thisFrameList,'displayInfo',options.displayInfo,'fileInfo',fileInfoH);
					end

					if isempty(options.matfile)
						outputMovie = outputMovie.Movie;
					else
						matObj.outputMovie = outputMovie.Movie;
					end
				else
					if isempty(thisFrameList)
						tmpMovie = load_tif_movie(thisMoviePath,1,'tmpImage',tmpFramePerma,'displayInfo',displayInfoH,'Numberframe',NumberframeH,'fileInfo',fileInfoH);
						% tmpMovie = tmpMovie.Movie;
					else
						tmpMovie = load_tif_movie(thisMoviePath,1,'frameList',thisFrameList,'tmpImage',tmpFramePerma,'displayInfo',displayInfoH,'Numberframe',NumberframeH,'fileInfo',fileInfoH);
					end

					if isempty(options.matfile)
						tmpMovie = tmpMovie.Movie;
					else
						if iMovie==1
							if dims.z(iMovie)==0
								matObj.outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1) = tmpMovie.Movie;
							else
								matObj.outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:dims.z(iMovie)) = tmpMovie.Movie;				
							end
						else
							% assume 3D movies with [x y frames] as dimensions
							zOffset = sum(dims.z(1:iMovie-1));
							matObj.outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+1):(zOffset+dims.z(iMovie))) = tmpMovie.Movie;
						end
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
					if options.largeMovieLoad==1&&numMovies==1
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
			case {'avi','mp4'}
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
					tmpAviFrame = read(xyloObj, readFrame,'native');
					% Check for data type
					try
						if isstruct(tmpAviFrame)
							tmpAviFrame = tmpAviFrame.cdata;
						else
							% Do nothing, frame is already a matrix
						end
					catch

					end
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
			case 'bioformats'
				% Setup movie class
				bfreaderTmp = bfGetReader(thisMoviePath);
				bfreaderTmp.setSeries(options.bfSeriesNo);

				omeMeta = bfreaderTmp.getMetadataStore();
				stackSizeX = omeMeta.getPixelsSizeX(options.bfSeriesNo).getValue(); % image width, pixels
				stackSizeY = omeMeta.getPixelsSizeY(options.bfSeriesNo).getValue(); % image height, pixels
				stackSizeZ = omeMeta.getPixelsSizeZ(options.bfSeriesNo).getValue();
				nChannels = omeMeta.getChannelCount(options.bfSeriesNo);

				% Get the number of time points (frames).
				nFramesHere = bfreaderTmp.getSizeT;

				xyDims = [stackSizeX stackSizeY];

				if isempty(thisFrameList)
					nFrames = nFramesHere;
					framesToGrab = 1:nFrames;
				else
					nFrames = length(thisFrameList);
					framesToGrab = thisFrameList;
				end
				vidHeight = xyDims(2);
				vidWidth = xyDims(1);

				% Preallocate movie structure.
				if numMovies==1
					outputMovie = zeros(vidHeight, vidWidth, nFrames, imgClass);
				else
					tmpMovie = zeros(vidHeight, vidWidth, nFrames, imgClass);
				end

				% Read one frame at a time.
				reverseStr = '';
				iframe = 1;
				nFrames = length(framesToGrab);


				zPlane = 0;
				iZ = 1;
				dispEvery = round(nFrames/20);
				% Adjust for zero-based indexing
				framesToGrab = framesToGrab-1;

				% figure;
				reverseStr = '';
				for t = framesToGrab
					iPlane = bfreaderTmp.getIndex(zPlane, options.bfChannelNo-1, t)+1;
					tmpFrame = bfGetPlane(bfreaderTmp, iPlane);
					% figure;
					% imagesc(tmpFrame);
					if numMovies==1
						outputMovie(:,:,iZ) = tmpFrame;
					else
						tmpMovie(:,:,iZ) = tmpFrame;
					end
					iZ = iZ+1;
					
					if options.displayInfo==1
						reverseStr = cmdWaitbar(iZ,nFrames,reverseStr,'inputStr','Loading bio-formats file: ','waitbarOn',options.waitbarOn,'displayEvery',dispEvery);
					end
					% pause(0.01)
				end
				if numMovies==1
					clear tmpMovie
				end
				% ciapkg.api.playMovie(tmpMovie);
				% size(tmpMovie)

				% continue;
				extraBioformatsFlag = 0;
				if extraBioformatsFlag==1
					% Read in movie data
					tmpMovie = bfopen(thisMoviePath);

					% bfopen returns an n-by-4 cell array, where n is the number of series in the dataset. If s is the series index between 1 and n:
					% The data{s, 1} element is an m-by-2 cell array, where m is the number of planes in the s-th series. If t is the plane index between 1 and m:
					% The data{s, 1}{t, 1} element contains the pixel data for the t-th plane in the s-th series.
					% The data{s, 1}{t, 2} element contains the label for the t-th plane in the s-th series.
					% The data{s, 2} element contains original metadata key/value pairs that apply to the s-th series.
					% The data{s, 3} element contains color lookup tables for each plane in the s-th series.
					% The data{s, 4} element contains a standardized OME metadata structure, which is the same regardless of the input file format, and contains common metadata values such as physical pixel sizes - see OME metadata below for examples.

					% Frame information
					frameInfo = tmpMovie{options.bfSeriesNo, 1}(:,2);

					% Grab just the movie frames and convert from cell to matrix.
					tmpMovie = tmpMovie{options.bfSeriesNo, 1}(:,1);
					tmpMovie = cat(3,tmpMovie{:});

					% Only keep single channel if more than 1 channel in an image.
					if nChannels>1
						try
							chanKeepIdx = cell2mat(cellfun(@(x) str2num(cell2mat(regexp(x,'(?<=C\?=|C=)\d+(?=/)','match'))),frameInfo,'UniformOutput',false));
							chanKeepIdx = chanKeepIdx==options.bfChannelNo;
							tmpMovie = tmpMovie(:,:,chanKeepIdx);
						catch err
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
					end
				end
			% ========================
			otherwise
				% let's just not deal with this for now
				return;
		end
		if exist('tmpMovie','var')
			if iMovie==1
				if dims.z(iMovie)==0
					outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1) = tmpMovie;
				else
					outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:dims.z(iMovie)) = tmpMovie;	
				end
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
		outputMovie = double(outputMovie);
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
% function [movieType, supported] = getMovieFileType(thisMoviePath)
% 	% determine how to load movie, don't assume every movie in list is of the same type
% 	supported = 1;
% 	try
% 		[pathstr,name,ext] = fileparts(thisMoviePath);
% 	catch
% 		movieType = '';
% 		supported = 0;
% 		return;
% 	end
% 	% files are assumed to be named correctly (lying does no one any good)
% 	if any(strcmp(ext,{'.h5','.hdf5','.HDF5'}))		
% 		movieType = 'hdf5';
% 	elseif strcmp(ext,'.nwb')
% 		movieType = 'hdf5';
% 	elseif any(strcmp(ext,{'.tif','.tiff'}))		
% 		movieType = 'tiff';
% 	elseif strcmp(ext,'.avi')
% 		movieType = 'avi';
% 	elseif strcmp(ext,'.isxd') % Inscopix file format
% 		movieType = 'isxd';
% 	elseif strcmp(ext,'.ndpi') % Hamamatsu file format
% 		movieType = 'bioformats';
% 	elseif strcmp(ext,'.oir') % Olympus file format
% 		movieType = 'bioformats';
% 	elseif any(strcmp(ext,{'.czi','.lsm'})) % Zeiss file format
% 		movieType = 'bioformats';
% 	elseif endsWith(ext,'.sld') % SlideBook file format
% 		movieType = 'bioformats';
% 	else
% 		movieType = '';
% 		supported = 0;
% 	end
% end
function subfxnDisplay(str,options)
	if options.displayInfo==1
		disp(str)
	end
end

function frameListTmp = subfxnLoadEqualParts(movieList,options)
    import ciapkg.api.* % import CIAtah functions in ciapkg package API.
    
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
