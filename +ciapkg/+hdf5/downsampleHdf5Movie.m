function [success] = downsampleHdf5Movie(inputFilePath, varargin)
	% [success] = downsampleHdf5Movie(inputFilePath, varargin)
	% 
	% Downsamples a movie (HDF5, SLD, etc.) in inputFilePath piece by piece and appends it to already created hdf5 file. Useful for large files that otherwise would not fit into RAM.
	% 
	% Biafra Ahanonu
	% started: 2013.12.19
	% 
	% Part of append code based on work by Dinesh Iyer (http://www.mathworks.com/matlabcentral/newsreader/author/130530)
	% note: checked between this implementation and imageJ's scale, they are nearly identical (subtracted histogram mean is 1 vs each image mean of ~1860, so assuming precision error).
	% 
	% inputs
	%	inputFilePath - Str: path to movie to downsample into HDF5.
	% outputs
	% 	success - Binary: 1 = completed successfully, 0 = did not complete successfully.
	% options
	%	inputDatasetName = hierarchy where data is stored in HDF5 file

	% changelog
		% 2014.01.18 - improved method of obtaining the newFilename
		% 2014.06.16 - updated output notifications to user
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.07.10 [19:24:29] - Added Bio-Formats support.
		% 2022.07.15 [13:34:28] - Switch chunking to automatic by default, generally improved reading from data later than small chunks.
	% TODO
		% Use handles to reduce memory load when doing computations.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Str: name of the input hierarchy in the HDF5 files
	options.inputDatasetName = '/1';
	% Str: name of the output hierarchy in the HDF5 files
	options.outputDatasetName = '/1';
	% Vector: frames to use.
	options.frameList = 1;
	% Int: amount to downsample movie. Value of 1 = no downsample (e.g. just file conversion).
	options.downsampleFactor = 4;
	% Int: max size of a chunk in Mbytes. For HDF5 files.
	options.maxChunkSize = 20000;
	% Int: bytes to MB conversion. DO NOT CHANGE.
	options.bytesToMB = 1024^2;
	% Int: number of frames to use when loading file in chunks. For Bio-Formats files!
	options.numFramesSubset = 1000;
	% interval over which to show waitbar
	options.waitbarInterval = 1000;
	% Str: new filename to save to for the downsampled movie.
	options.newFilename = '';
	% Str: downsample to different folder. Leave blank to use same folder as input file.
	options.saveFolder = [];
	% second if want to do another downsample without loading another file
	options.saveFolderTwo = [];
	% Int: amount to downsample movie to 2nd folder. Value of 1 = no downsample (e.g. just file conversion).
	options.downsampleFactorTwo = 2;
	% Str: new filename to save to for the downsampled movie in 2nd folder.
	options.newFilenameTwo = '';
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = []; % [128 128 1]
	% Str: movie type: hdf5, bioformats. Leave blank for automatic determination.
	options.movieType = '';
	% Int: Bio-Formats series number to load.
	options.bfSeriesNo = 1;
	% Int: Bio-Formats channel number to load.
	options.bfChannelNo = 1;
	% Int: Bio-Formats z dimension to load.
	options.bfZdimNo = 1;
	% Str: Bio-Formats series name. Function will search via regexp for this series within a Bio-Formats file.
	options.bfSeriesName = '';
	% Binary: 1 = whether to display info on command line.
	options.displayInfo = 1;
	% Binary: 1 = waitbar/progress bar is shown, 0 = no progress shown.
	options.waitbarOn = 1;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	[pathstr,name,ext] = fileparts(inputFilePath);
	inputFileEmpty = 0;
	if isempty(options.newFilename)
		inputFileEmpty = 1;
		options.newFilename = [pathstr filesep 'concat_' name '.h5'];
	end
	if isempty(options.newFilenameTwo)
		options.newFilenameTwo = [pathstr filesep 'concat_' name '.h5'];
	end

	% Check that options.dataDimsChunkCopy


	% Check type of movie being read in.
	if isempty(options.movieType)
		[options.movieType] = ciapkg.io.getMovieFileType(inputFilePath);
	end

	startTime = tic;

	fileIdOpen = [];

	switch options.movieType
		case 'hdf5'
			% movie dimensions and subsets to analyze
			[subsets, dataDim] = getSubsetOfDataToAnalyze(inputFilePath, options, varargin);
		case 'bioformats'
			disp(['Opening connection to Bio-Formats file:' inputFilePath])
			startReadTime = tic;
			fileIdOpen = bfGetReader(inputFilePath);
			toc(startReadTime)

			% If user inputs a series name, find within the file and overwrite default series name.
			if ~isempty(options.bfSeriesName)
				[bfSeriesNo] = ciapkg.bf.getSeriesNoFromName(inputFilePath,options.bfSeriesName,'fileIdOpen',fileIdOpen);
				if isnan(bfSeriesNo)
					disp(['Series "' options.bfSeriesName '" not found in ' inputFilePath])
					disp('Returning...')
					return;
				else
					options.bfSeriesNo = bfSeriesNo;
				end
			end

			% Convert for 0-base indexing.
			bfSeriesNoTrue = options.bfSeriesNo-1;

			fileIdOpen.setSeries(bfSeriesNoTrue);
			omeMeta = fileIdOpen.getMetadataStore();

			dim = struct;
			dataDim.x = omeMeta.getPixelsSizeX(bfSeriesNoTrue).getValue(); % image width, pixels
			dataDim.y = omeMeta.getPixelsSizeY(bfSeriesNoTrue).getValue(); % image height, pixels
			dataDim.z = fileIdOpen.getSizeT;

			thisStr = char(omeMeta.getImageName(bfSeriesNoTrue));

			disp(['Loading series: ' thisStr])
			display(dataDim)

			% If filename is empty
			if inputFileEmpty==1
				options.newFilename = [pathstr filesep 'concat_' thisStr '.h5'];
			end

			disp('===')
			disp(['Series in file: ' inputFilePath])
			nSeries = fileIdOpen.getSeriesCount();
			for seriesNo = 1:nSeries
				thisStr = char(omeMeta.getImageName(seriesNo-1));
				disp([num2str(seriesNo) ': "' thisStr '"'])
			end
			disp('===')

			% Get the subsets of the movie to analyze
			subsetSize = options.numFramesSubset;
			movieLength = dataDim.z;
			numSubsets = ceil(movieLength/subsetSize)+1;
			subsets = round(linspace(1,movieLength,numSubsets));
		otherwise
	end

	subsetsDiff = diff(subsets);
	% to compensate for flooring of linspace
	subsetsDiff(end) = subsetsDiff(end)+1;
	display(['subsets: ' num2str(subsets)]);
	display(['subsets diffs: ' num2str(subsetsDiff)]);

	% Change output filename if user request a different folder than where original file is.
	if ~isempty(options.saveFolder)
		[pathstr,name,ext] = fileparts(options.newFilename);
		options.newFilename = [options.saveFolder filesep name '.h5'];
	end
	if ~isempty(options.saveFolderTwo)
		[pathstr,name,ext] = fileparts(options.newFilename);
		options.newFilenameTwo = [options.saveFolderTwo filesep name '.h5'];
	end

	% Pre-establish connection to file to save time.
	switch options.movieType
		case 'hdf5'
			% hdf5FileWorkerConstant.Value = H5F.open(inputMovie);
		case 'bioformats'
			if isempty(fileIdOpen)
				disp(['Opening connection to Bio-Formats file:' inputFilePath])
				startReadTime = tic;
				fileIdOpen = bfGetReader(inputFilePath);
				toc(startReadTime)
			end
		otherwise
	end
	display(repmat('+',1,21))
	disp(['Saving to: ' options.newFilename])
	% display(['saving to: ' options.newFilename])

	try
		nSubsets = (length(subsets)-1);
		for currentSubset = 1:nSubsets
			loopStartTime = tic;
			% get current subset location and size
			currentSubsetLocation = subsets(currentSubset);
			lengthSubset = subsetsDiff(currentSubset);
			% convert offset to C-style offset for low-level HDF5 functions
			offset = [0 0 currentSubsetLocation-1];
			block = [dataDim.x dataDim.y lengthSubset];
			display('---')
			% display(sprintf(['current location: ' num2str(round(currentSubsetLocation/dataDim.z*100)) '% | ' num2str(currentSubsetLocation) '/' num2str(dataDim.z) '\noffset: ' num2str(offset) '\nblock: ' num2str(block)]));
			fprintf('current location: %d%% | %d/%d \noffset: %s \nblock: %s\n',round(currentSubsetLocation/dataDim.z*100),currentSubsetLocation,dataDim.z,mat2str(offset),mat2str(block));

			switch options.movieType
				case 'hdf5'
					% load subset of HDF5 file into memory
					inputMovie = readHDF5Subset(inputFilePath,offset,block,'datasetName',options.inputDatasetName);
				case 'bioformats'
					thisFrameList = currentSubsetLocation:(currentSubsetLocation+lengthSubset-1);
					disp(['Frames ' num2str(thisFrameList(1)) ' to ' num2str(thisFrameList(end))])
					[inputMovie] = local_readBioformats(inputFilePath,thisFrameList,fileIdOpen,options);
				otherwise
			end


			% split into second movie if need be
			if ~isempty(options.saveFolderTwo)
				inputMovieTwo = inputMovie;
			end

			% Downsample section of the movie, keep in memory
			if options.downsampleFactor==1
			else
				downsampleMovieNested('downsampleDimension', 'space','downsampleFactor',options.downsampleFactor,'waitbarInterval',options.waitbarInterval);
			end
			% thisMovie = uint16(thisMovie);
			display(['subset class: ' class(inputMovie)])

			% For snapshots with a single frame
			if size(inputMovie,3)==1
				inputMovie(:,:,2) = inputMovie;
			end

			% save the movie
			if currentSubset==1
				createHdf5File(options.newFilename, options.outputDatasetName, inputMovie,'deflateLevel',options.deflateLevel,'dataDimsChunkCopy',options.dataDimsChunkCopy);
			else
				appendDataToHdf5(options.newFilename, options.outputDatasetName, inputMovie);
			end
			toc(loopStartTime);
			display(sprintf(['downsample dims: ' num2str(size(inputMovie)) '\n-------']));

			if ~isempty(options.saveFolderTwo)
				display('secondary downsample in progress...')
				inputMovie = inputMovieTwo;
				% downsample section of the movie, keep in memory
				downsampleMovieNested('downsampleDimension', 'space','downsampleFactor',options.downsampleFactorTwo,'waitbarInterval',options.waitbarInterval);
				% save the movie
				if currentSubset==1
					createHdf5File(options.newFilenameTwo, options.outputDatasetName, inputMovie,'deflateLevel',options.deflateLevel,'dataDimsChunkCopy',options.dataDimsChunkCopy);
				else
					appendDataToHdf5(options.newFilenameTwo, options.outputDatasetName, inputMovie);
				end
			end
			% clear inputMovie;
		end
		success = 1;
		options.inputDatasetName = options.outputDatasetName;
		[subsets dataDim] = getSubsetOfDataToAnalyze(options.newFilename, options, varargin);
		display(repmat('+',1,7))
		display(['final HDF5 dims: ' num2str(cell2mat(struct2cell(dataDim))')]);
		display(repmat('+',1,7))
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
		success = 0;
	end
	toc(startTime);

	function downsampleMovieNested(varargin)
		% downsamples a movie in either space or time, uses floor to calculate downsampled dimensions.
		% biafra ahanonu
		% started 2013.11.09 [09:31:32]
		%
		% inputs
			% inputMovie: a NxMxP matrix
		% options
			% downsampleType
			% downsampleFactor - amount to downsample in time
		% changelog
			% 2013.12.19 added the spatial downsampling to the function.
		% TODO

		%========================
		% default options
		nestedoptions.downsampleDimension = 'time';
		nestedoptions.downsampleType = 'bilinear';
		nestedoptions.downsampleFactor = 4;
		% exact dimensions to downsample in Z
		nestedoptions.downsampleZ = [];
		nestedoptions.waitbarOn = 1;
		% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
		nestedoptions.frameList = [];
		% whether to convert movie to double on load, not recommended
		nestedoptions.convertToDouble = 0;
		% name of HDF5 dataset name to load
		nestedoptions.inputDatasetName = '/1';
		% interval over which to show waitbar
		nestedoptions.waitbarInterval = 1000;
		% get user options, else keeps the defaults
		nestedoptions = getOptions(nestedoptions,varargin);
		% unpack options into current workspace
		% fn=fieldnames(options);
		% for i=1:length(fn)
		%     eval([fn{i} '=options.' fn{i} ';']);
		% end
		%========================
		% load the movie within downsample function
		if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
			inputMovie = loadMovieList(inputMovie,'convertToDouble',nestedoptions.convertToDouble,'frameList',nestedoptions.frameList,'inputDatasetName',nestedoptions.inputDatasetName);
		end

		switch nestedoptions.downsampleDimension
			case 'time'
				switch nestedoptions.downsampleType
					case 'bilinear'
						% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
						downX = size(inputMovie,1);
						downY = size(inputMovie,2);
						if isempty(nestedoptions.downsampleZ)
							downZ = floor(size(inputMovie,3)/nestedoptions.downsampleFactor);
						else
							downZ = nestedoptions.downsampleZ;
						end
						% pre-allocate movie
						% inputMovieDownsampled = zeros([downX downY downZ]);
						% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
						reverseStr = '';
						for frame=1:downY
						   downsampledFrame = imresize(squeeze(inputMovie(:,frame,:)),[downX downZ],'bilinear');
						   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
						   inputMovie(1:downX,frame,1:downZ) = downsampledFrame;
						   % inputMovie(:,frame,:) = downsampledFrame;
							if frame==1||mod(frame,nestedoptions.waitbarInterval)==0&nestedoptions.waitbarOn==1|frame==downY
								reverseStr = cmdWaitbar(frame,downY,reverseStr,'inputStr','temporally downsampling matrix');
							end
						end
						inputMovie = inputMovie(:,:,1:downZ);
						drawnow;
					otherwise
						return;
				end
			case 'space'
				switch nestedoptions.downsampleType
					case 'bilinear'
						% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
						downX = floor(size(inputMovie,1)/nestedoptions.downsampleFactor);
						downY = floor(size(inputMovie,2)/nestedoptions.downsampleFactor);
						downZ = size(inputMovie,3);
						% pre-allocate movie
						% inputMovieDownsampled = zeros([downX downY downZ]);
						% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
						reverseStr = '';
						for frame=1:downZ
						   downsampledFrame = imresize(squeeze(inputMovie(:,:,frame)),[downX downY],'bilinear');
						   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
						   inputMovie(1:downX,1:downY,frame) = downsampledFrame;
						   % inputMovieDownsampled(1:downX,1:downY,frame) = downsampledFrame;
							if frame==1||mod(frame,nestedoptions.waitbarInterval)==0&nestedoptions.waitbarOn==1|frame==downZ
								reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr','spatially downsampling matrix');
							end
						end
						inputMovie = inputMovie(1:downX,1:downY,:);
						drawnow;
					otherwise
						return;
				end
			otherwise
				display('incorrect dimension option, choose time or space');
		end
		% display(' ');
	end
end

function [outputMovie] = local_readBioformats(thisMoviePath,thisFrameList,bfreaderTmp,options)
	% Reads in Bio-Formats data in chunks, uses open ID to speed up read times.

	% Setup movie class
	numMovies = 1;

	% Account for 0-base indexing.
	bfSeriesNoTrue = options.bfSeriesNo-1;

	% bfreaderTmp = bfGetReader(thisMoviePath);
	bfreaderTmp.setSeries(bfSeriesNoTrue);

	omeMeta = bfreaderTmp.getMetadataStore();
	stackSizeX = omeMeta.getPixelsSizeX(bfSeriesNoTrue).getValue(); % image width, pixels
	stackSizeY = omeMeta.getPixelsSizeY(bfSeriesNoTrue).getValue(); % image height, pixels
	stackSizeZ = omeMeta.getPixelsSizeZ(bfSeriesNoTrue).getValue();
	nChannels = omeMeta.getChannelCount(bfSeriesNoTrue);

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

	iPlane = bfreaderTmp.getIndex(0, options.bfChannelNo-1, 0)+1;
	tmpFrame = bfGetPlane(bfreaderTmp, iPlane);
	imgClass = class(tmpFrame);

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


	zPlane = 1;
	iZ = 1;
	dispEvery = round(nFrames/20);
	% Adjust for zero-based indexing
	% framesToGrab = framesToGrab-1;

	% figure;
	reverseStr = '';
	for t = framesToGrab
		% Assume 1-based adjust to 0-based indexing
		iPlane = bfreaderTmp.getIndex(zPlane-1, options.bfChannelNo-1, t-1)+1;
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
			reverseStr = ciapkg.view.cmdWaitbar(iZ,nFrames,reverseStr,'inputStr','Loading bio-formats file: ','waitbarOn',options.waitbarOn,'displayEvery',dispEvery);
		end
		% pause(0.01)
	end
end

function [subsets dataDim] = getSubsetOfDataToAnalyze(inputFilePath, options, varargin)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% get HDF5 info
	hinfo = hdf5info(inputFilePath);
	hinfo.GroupHierarchy.Datasets;
	% find dataset name location
	% datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
	% thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
	% hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
	hReadInfo = getHdf5Info(hinfo,options);
	dataDim.x = hReadInfo.Dims(1);
	dataDim.y = hReadInfo.Dims(2);
	dataDim.z = hReadInfo.Dims(3);
	% estimate size of movie in Mbytes
	testFrame = readHDF5Subset(inputFilePath,[0 0 0],[dataDim.x dataDim.y 1],'datasetName',options.inputDatasetName);
	testFrameInfo = whos('testFrame');
	estSizeMovie = (testFrameInfo.bytes/options.bytesToMB)*dataDim.z;
	numSubsets = ceil(estSizeMovie/options.maxChunkSize)+1;
	% get the subsets of the 3D matrix to analyze
	subsets = floor(linspace(1,dataDim.z,numSubsets));
end
function hReadInfo = getHdf5Info(hinfo,options)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	try
		datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
		thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
		hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
	catch
		try
			datasetNames = {hinfo.GroupHierarchy.Groups.Datasets.Name};
			thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
			hReadInfo = hinfo.GroupHierarchy.Groups.Datasets(thisDatasetName);
		catch
			nGroups = length(hinfo.GroupHierarchy.Groups);
			datasetNames = {};
			for groupNo = 1:nGroups
				datasetNames{groupNo} = hinfo.GroupHierarchy.Groups(groupNo).Datasets.Name;
			end
			thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
			hReadInfo = hinfo.GroupHierarchy.Groups(thisDatasetName).Datasets;
		end
	end
end