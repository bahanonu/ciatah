function [success] = convertInscopixIsxdToHdf5(inputFilePath,varargin)
	% Converts Inscopix proprietary ISXD to HDF5.
	% Biafra Ahanonu
	% started: 2019.01.15 [21:17:45]
	% inputs
		% inputMoviePath - char: path to ISXD file.
	% outputs
		%

	% changelog
		% 2019.07.11 [19:55:24] - Added support for JSON file information to metadata file.
	% TODO
		%

	%========================
	% Char: alternative file path
	options.altSavePath = '';
	% name of the input hierarchy in the HDF5 files
	options.inputDatasetName = '/1';
	% name of the output hierarchy in the HDF5 files
	options.outputDatasetName = '/1';
	options.frameList = 1;
	options.downsampleFactor = 4;
	% max size of a chunk in Mbytes
	options.maxChunkSize = 20000;
	options.bytesToMB = 1024^2;
	% interval over which to show waitbar
	options.waitbarInterval = 1000;
	% char: suffix to append for metadata filename
	options.metadataName = '_metadata';
	% get the new filename for the downsampled movie
	[pathstr,name,ext] = fileparts(inputFilePath);
	options.newFilename = [pathstr filesep 'concat_' name '.h5'];
	options.newFilenameInfoFile = [pathstr filesep name options.metadataName '.mat'];
	% downsample to different folder
	options.saveFolder = [];
	% second if want to do another downsample without loading another file
	options.saveFolderTwo = [];
	options.downsampleFactorTwo = 2;
	[pathstr,name,ext] = fileparts(inputFilePath);
	options.newFilenameTwo = [pathstr filesep 'concat_' name '.h5'];
	options.newFilenameInfoFileTwo = [pathstr filesep name options.metadataName '.mat'];
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;

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
		success = 0;
		% Test that Inscopix MATLAB API ISX package installed
		try
			inputMovieIsx = isx.Movie.read(inputFilePath);
		catch
			if ismac
				baseInscopixPath = './';
			elseif isunix
				baseInscopixPath = './';
			elseif ispc
				baseInscopixPath = 'C:\Program Files\Inscopix\Data Processing';
			else
				disp('Platform not supported')
			end

			if exist(baseInscopixPath,'dir')==7
			else
				baseInscopixPath = '.\';
			end
			pathToISX = uigetdir(baseInscopixPath,'Enter path to Inscopix Data Processing program installation folder (e.g. +isx should be in the directory)');
			addpath(pathToISX);
			help isx
		end


		inputMovieIsx = isx.Movie.read(inputFilePath);
		nFrames = inputMovieIsx.timing.num_samples;

		if ~isempty(options.saveFolder)
			[pathstr,name,ext] = fileparts(options.newFilename);
			options.newFilename = [options.saveFolder filesep name '.h5'];
			[pathstr,name,ext] = fileparts(inputFilePath);
			options.newFilenameInfoFile = [options.saveFolder filesep name options.metadataName '.mat'];
		end
		if ~isempty(options.saveFolderTwo)
			[pathstr,name,ext] = fileparts(options.newFilename);
			options.newFilenameTwo = [options.saveFolderTwo filesep name '.h5'];
			[pathstr,name,ext] = fileparts(inputFilePath);
			options.newFilenameInfoFileTwo = [options.saveFolderTwo filesep name options.metadataName '.mat'];
		end

		display(repmat('+',1,21))
		display(['saving to: ' options.newFilename])
		startTime = tic;
		% movie dimensions and subsets to analyze
		[subsets dataDim] = getSubsetOfDataToAnalyze(inputFilePath, options, varargin);
		subsetsDiff = diff(subsets);
		% to compensate for flooring of linspace
		subsetsDiff(end) = subsetsDiff(end)+1;
		display(['subsets: ' num2str(subsets)]);
		display(['subsets diffs: ' num2str(subsetsDiff)]);
		try
			nSubsets = (length(subsets)-1);

			% Setup movie class
			inputMovieIsx = isx.Movie.read(inputFilePath);
			iMIx = inputMovieIsx;

			% Save out movie information
			inputMovieIsxInfo.num_samples = iMIx.timing.num_samples;
			inputMovieIsxInfo.period = iMIx.timing.period;
			inputMovieIsxInfo.start = iMIx.timing.start;
			inputMovieIsxInfo.dropped = iMIx.timing.dropped;
			inputMovieIsxInfo.cropped = iMIx.timing.cropped;
			inputMovieIsxInfo.get_valid_samples = iMIx.timing.get_valid_samples();
			inputMovieIsxInfo.get_valid_samples_mask = iMIx.timing.get_valid_samples_mask();
			inputMovieIsxInfo.get_offsets_since_start = [iMIx.timing.get_offsets_since_start().secs_float];
			inputMovieIsxInfo.num_pixels = iMIx.spacing.num_pixels;
			inputMovieIsxInfo.data_type = iMIx.data_type;
			inputMovieIsxInfo.file_path = iMIx.file_path;

			[pathstr,name,ext] = fileparts(inputFilePath);
			jsonPaths = getFileList('pathstr','session.json')
			if isempty(jsonPaths)
			else
				sessionJsonValue = jsondecode(fileread(jsonPaths{1}));
				inputMovieIsxInfo.sessionInfo = sessionJsonValue;
			end

			fprintf('Saving log file: %s\n',options.newFilenameInfoFile);
			save(options.newFilenameInfoFile,'inputMovieIsxInfo','-v7.3')

			if ~isempty(options.saveFolderTwo)
				fprintf('Saving log file: %s\n',options.newFilenameInfoFileTwo);
				save(options.newFilenameInfoFileTwo,'inputMovieIsxInfo','-v7.3')
			end

			for currentSubset=1:nSubsets
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
				% fprintf('current location: %d | %d/%d\n',round(currentSubsetLocation/dataDim.z*100),currentSubsetLocation,dataDim.z);

				% Load subset of ISXD file into memory and cast to the correct class
				inputMovie = zeros([dataDim.x dataDim.y lengthSubset],class(inputMovieIsx.get_frame_data(0)));
				frameCount = 1;
				for frameNoHere = currentSubsetLocation:(currentSubsetLocation+lengthSubset-1)
					% [frameCount frameNoHere]
					inputMovie(:,:,frameCount) = inputMovieIsx.get_frame_data(frameNoHere-1);
					frameCount = frameCount+1;
				end
				% inputMovie = readHDF5Subset(inputFilePath,offset,block,'datasetName',options.inputDatasetName);

				% split into second movie if need be
				if ~isempty(options.saveFolderTwo)
					inputMovieTwo = inputMovie;
				end
				% downsample section of the movie, keep in memory
				downsampleMovieNested('downsampleDimension', 'space','downsampleFactor',options.downsampleFactor,'waitbarInterval',options.waitbarInterval);
				% thisMovie = uint16(thisMovie);
				display(['subset class: ' class(inputMovie)])

				% For snapshots with a single frame
				if size(inputMovie,3)==1
					inputMovie(:,:,2) = inputMovie;
				end

				% save the movie
				if currentSubset==1
					createHdf5File(options.newFilename, options.outputDatasetName, inputMovie,'deflateLevel',options.deflateLevel);
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
						createHdf5File(options.newFilenameTwo, options.outputDatasetName, inputMovie,'deflateLevel',options.deflateLevel);
					else
						appendDataToHdf5(options.newFilenameTwo, options.outputDatasetName, inputMovie);
					end
				end
				% clear inputMovie;
			end
			success = 1;
			options.inputDatasetName = options.outputDatasetName;
			[subsets dataDim] = getSubsetOfDataToAnalyzeHDF5(options.newFilename, options, varargin);
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
			% Code
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
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
							if mod(frame,nestedoptions.waitbarInterval)==0&nestedoptions.waitbarOn==1|frame==downY
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
							if mod(frame,nestedoptions.waitbarInterval)==0&nestedoptions.waitbarOn==1|frame==downZ
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

function [subsets dataDim] = getSubsetOfDataToAnalyze(inputFilePath, options, varargin)
	% get HDF5 info
	% hinfo = hdf5info(inputFilePath);
	% hinfo.GroupHierarchy.Datasets;
	% find dataset name location
	% datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
	% thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
	% hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);


	inputMovieIsx = isx.Movie.read(inputFilePath);
	nFrames = inputMovieIsx.timing.num_samples;
	xyDims = inputMovieIsx.spacing.num_pixels;

	% hReadInfo = getHdf5Info(hinfo,options);
	dataDim.x = xyDims(1);
	dataDim.y = xyDims(2);
	dataDim.z = nFrames;
	% estimate size of movie in Mbytes
	testFrame = inputMovieIsx.get_frame_data(0);
	% testFrame = readHDF5Subset(inputFilePath,[0 0 0],[dataDim.x dataDim.y 1],'datasetName',options.inputDatasetName);
	testFrameInfo = whos('testFrame');
	estSizeMovie = (testFrameInfo.bytes/options.bytesToMB)*dataDim.z;
	numSubsets = ceil(estSizeMovie/options.maxChunkSize)+1;
	% get the subsets of the 3D matrix to analyze
	subsets = floor(linspace(1,dataDim.z,numSubsets));
end

function [subsets dataDim] = getSubsetOfDataToAnalyzeHDF5(inputFilePath, options, varargin)
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