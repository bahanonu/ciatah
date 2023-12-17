function [thisFrame,movieFileID,inputMovieDims] = readFrame(inputMoviePath,frameNo,varargin)
	% Fast reading of frame from files on disk. This is an alternative to loadMovieList that is much faster when only a single frame needs to be read.
	% Biafra Ahanonu
	% started: 2020.10.19 [11:45:24]
	% inputs
		% inputMoviePath | Str: path to a movie. Supports TIFF, AVI, HDF5, NWB, or Inscopix ISXD.
		% frameNo | Int: frame number.
	% outputs
		%
	% Usage
		% For non-HDF5 file types, need to open a link to the file then can pass the handle for faster subsequent reading.
			% [thisFrame,movieFileID,inputMovieDims] = ciapkg.io.readFrame(inputMoviePath,frameNo);
			% Then for the second call, feed in movieFileID and inputMovieDims to improve read speed.
			% [thisFrame] = ciapkg.io.readFrame(inputMoviePath,frameNo,'movieFileID',movieFileID,'inputMovieDims',inputMovieDims);

	% changelog
		% 2021.06.30 [01:26:29] - Updated handling of no file path character input.
		% 2021.07.03 [09:02:14] - Updated to have backup read method for different tiff styles.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.02.24 [10:24:28] - AVI now read(...,'native') is faster.
		% 2022.07.27 [13:48:43] - Ensure subfxn_loadFrame nested function outputs frame data (even if file does not contain the requested frame, e.g. empty matrix).
		% 2022.10.27 [18:33:58] - Update AVI support to do additional cdata checks.
		% 2023.06.07 [11:44:55] - Add support for reading multiple files if a character cell array of char vectors is given.
		% 2023.08.19 [14:45:49] - Add bioformats passing arguments for loadMovieList as options.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% Pointer created by Tiff (tif), VideoReader (avi), or isx.Movie.read (Inscopix ISXD files).
	options.movieFileID = [];
	% Vector: [1st 2nd 3rd] dimension of movie.
	options.inputMovieDims = [];
	% Str: default NWB hierarchy names in HDF5 file where movie data is located, will look in the order indicates
	options.defaultNwbDatasetName = {'/acquisition/TwoPhotonSeries/data'};
	% Binary: 1 = whether to display info on command line.
	options.displayInfo = 1;
	% Binary: Whether to display diagnostic information
	options.displayDiagnosticInfo = 0;
	% Binary: allow RGB display, e.g. for AVI
	options.rgbDisplay = 0;
	% Int: [] = do nothing, 1-3 indicates R,G,B channels to take from multicolor RGB AVI
	options.rgbChannel = [];
	% Int: Bio-Formats series number to load.
	options.bfSeriesNo = 0;
	% Int: Bio-Formats channel number to load.
	options.bfChannelNo = 1;
	% Int: Bio-Formats z dimension to load.
	options.bfZdimNo = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		movieFileID = [];
		thisFrame = [];
		inputMovieDims = [];

		if ~isempty(options.frameList)
			frameNo = options.frameList(frameNo);
        end
        
        if iscell(inputMoviePath)==1&&length(inputMoviePath)==1
            inputMoviePath = inputMoviePath{1};
            [thisFrame] = subfxn_loadFrameWrapper(inputMoviePath,options);
        elseif iscell(inputMoviePath)==1&&length(inputMoviePath)>1
        	disp(['Loading frame ' num2str(frameNo) ' from ' num2str(length(inputMoviePath)) ' movies.'])
        	thisFrameTmp = {};
        	nFrames = length(inputMoviePath);
        	for i = 1:nFrames
        		thisFrameTmp{i} = subfxn_loadFrameWrapper(inputMoviePath{i},options);
        	end
        	thisFrame = cat(3,thisFrameTmp{:});
        elseif ischar(inputMoviePath)==1
            [thisFrame] = subfxn_loadFrameWrapper(inputMoviePath,options);
        end		
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	function [thisFrame] = subfxn_loadFrameWrapper(inputMoviePath,options)
		% Check if path to valid movie file type
		if ischar(inputMoviePath)
			[movieType, supported, movieTypeSpecific] = ciapkg.io.getMovieFileType(inputMoviePath);
			options.movieType = movieType;
			options.movieTypeSpecific = movieTypeSpecific;
		else
			disp('Please input a file path.');
			return;
		end

		% Get the movie file identifier to faster access/reading during future calls.
		if isempty(options.movieFileID)
			options.movieFileID = subfxn_getMovieObj(inputMoviePath,options);
			movieFileID = options.movieFileID;
		end

		[thisFrame, inputMovieDims] = subfxn_loadFrame(inputMoviePath,options);
	end
	function [thisFrame, inputMovieDims] = subfxn_loadFrame(inputMoviePathHere,options)
		inputMovieDims = options.inputMovieDims;
		thisFrame = [];
		movieType = options.movieType;
		movieTypeSpecific = options.movieTypeSpecific;
		switch movieType
			case 'hdf5'
				% Much faster to input the existing movie dimensions.
				if isempty(options.inputMovieDims)
					[inputMovieDims] = ciapkg.io.getMovieInfo(inputMoviePathHere,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName,'displayInfo',0,'displayDiagnosticInfo',0);
					inputMovieDims = [inputMovieDims.one inputMovieDims.two inputMovieDims.three];
				else
					inputMovieDims = options.inputMovieDims;	
				end
				% inputMovieDims
				% inputMoviePathHere
				% options.inputDatasetName
				% [1 1 frameNo]
				% [inputMovieDims(1) inputMovieDims(2) 1]
				thisFrame = h5read(inputMoviePathHere,options.inputDatasetName,[1 1 frameNo],[inputMovieDims(1) inputMovieDims(2) 1]);
			case 'tiff'
				warning off;
				try
					if isempty(options.movieFileID)
						% Much slower, avoid.
						tiffID = subfxn_getMovieObj(inputMoviePathHere,options)
					else
						tiffID = options.movieFileID;
					end
					tiffID.setDirectory(frameNo);
					thisFrame = read(tiffID);
				catch
					try
						% thisFrame = imread(inputMoviePathHere, 'tif', 'Index', frameNo, 'Info', imgInfo);
						thisFrame = imread(inputMoviePathHere, 'tif', 'Index', frameNo);
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
						% fileInfo = imfinfo(filename);
					end
					% err
					% display(repmat('@',1,7))
					% disp(getReport(err,'extended','hyperlinks','on'));
					% display(repmat('@',1,7))
				end
				warning on;
			case 'avi'
				if isempty(options.movieFileID)
					% Much slower, avoid.
					xyloObj = subfxn_getMovieObj(inputMoviePathHere,options);
				else
					xyloObj = options.movieFileID;
				end
				thisFrame = read(xyloObj, frameNo,'native');
				if isstruct(thisFrame)
					thisFrame = thisFrame.cdata;
				else
					% Do nothing, frame is already a matrix
				end
				if options.rgbDisplay==0
					if size(thisFrame,3)==3 & isempty(options.rgbChannel)
						thisFrame = squeeze(thisFrame(:,:,1));
					elseif ~isempty(options.rgbChannel)
						thisFrame = squeeze(thisFrame(:,:,options.rgbChannel));
					end
				end
			case 'isxd'
				if isempty(options.movieFileID)
					% Much slower, avoid.
					inputMovieIsx = subfxn_getMovieObj(inputMoviePathHere,options)
				else
					inputMovieIsx = options.movieFileID;
				end
				thisFrame = inputMovieIsx.get_frame_data(frameNo-1);
			otherwise
				thisFrame = loadMovieList(inputMoviePathHere,...
					'inputDatasetName',options.inputDatasetName,...
					'displayInfo',0,'displayDiagnosticInfo',0,...
					'displayWarnings',0,'frameList',frameNo,...
					'bfSeriesNo',options.bfSeriesNo,...
					'bfChannelNo',options.bfChannelNo,...
					'bfZdimNo',options.bfZdimNo);
				
		end
	end
	function movieFileID = subfxn_getMovieObj(inputMoviePathHere,options)
		% Setup connection to file to reduce I/O for file types that need it.
		movieFileID = [];
		movieType = options.movieType;
		movieTypeSpecific = options.movieTypeSpecific;
		switch movieTypeSpecific
			case 'hdf5'
				%
			case 'nwb'
				try
					h5info(inputMoviePathHere,options.inputDatasetName);
				catch
					for zCheck = 1:length(options.defaultNwbDatasetName)
						try
							options.inputDatasetName = options.defaultNwbDatasetName{zCheck};
							h5info(inputMoviePathHere,options.inputDatasetName);
							fprintf('Correct NWB dataset name: %s\n',options.inputDatasetName)
						catch
							fprintf('Incorrect NWB dataset name: %s\n',options.inputDatasetName)
						end
					end
				end
			case 'tiff'
				warning off;
				try
					tiffID = Tiff(inputMoviePathHere,'r');
					movieFileID = tiffID;
				catch
				end
				warning on;
			case 'avi'
				xyloObj = VideoReader(inputMoviePathHere);
				movieFileID = xyloObj;
			case 'isxd'
				try
					inputMovieIsx = isx.Movie.read(inputMoviePathHere);
				catch
					ciapkg.inscopix.loadIDPS();
					inputMovieIsx = isx.Movie.read(inputMoviePathHere);
				end
				movieFileID = inputMovieIsx;
			otherwise
				%
		end
	end
end