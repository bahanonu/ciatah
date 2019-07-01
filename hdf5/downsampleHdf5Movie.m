function [success] = downsampleHdf5Movie(inputFilePath, varargin)
	% Downsamples the Hdf5 movie in inputFilePath piece by piece and appends it to already created hdf5 file.
	% Biafra Ahanonu
	% started: 2013.12.19
	% base append code based on work by Dinesh Iyer (http://www.mathworks.com/matlabcentral/newsreader/author/130530)
	% note: checked between this implementation and imageJ's scale, they are nearly identical (subtracted histogram mean is 1 vs each image mean of ~1860, so assuming precision error).
	% inputs
		% inputFilePath
	% options
		% datasetName = hierarchy where data is stored in HDF5 file

	% changelog
		% 2014.01.18 - improved method of obtaining the newFilename
		% 2014.06.16 - updated output notifications to user
	% TODO
		% Use handles to reduce memory load when doing computations.

	%========================
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
	% get the new filename for the downsampled movie
	[pathstr,name,ext] = fileparts(inputFilePath);
	options.newFilename = [pathstr filesep 'concat_' name '.h5'];
	% downsample to different folder
	options.saveFolder = [];
	% second if want to do another downsample without loading another file
	options.saveFolderTwo = [];
	options.downsampleFactorTwo = 2;
	[pathstr,name,ext] = fileparts(inputFilePath);
	options.newFilenameTwo = [pathstr filesep 'concat_' name '.h5'];
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [128 128 1];
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if ~isempty(options.saveFolder)
		[pathstr,name,ext] = fileparts(options.newFilename);
		options.newFilename = [options.saveFolder filesep name '.h5'];
	end
	if ~isempty(options.saveFolderTwo)
		[pathstr,name,ext] = fileparts(options.newFilename);
		options.newFilenameTwo = [options.saveFolderTwo filesep name '.h5'];
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
			% load subset of HDF5 file into memory
			inputMovie = readHDF5Subset(inputFilePath,offset,block,'datasetName',options.inputDatasetName);
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

function [subsets dataDim] = getSubsetOfDataToAnalyze(inputFilePath, options, varargin)
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
% function createHdf5File(filename, datasetName, inputData, varargin)
% 	% Create the HDF5 file
% 	fcpl_id = H5P.create('H5P_FILE_CREATE');
% 	fapl_id = H5P.create('H5P_FILE_ACCESS');

% 	fid = H5F.create(filename, 'H5F_ACC_TRUNC', fcpl_id, fapl_id);

% 	% Create the Space for the Dataset
% 	initDims = size(inputData);
% 	h5_initDims = fliplr(initDims);
% 	maxDims = [initDims(1) initDims(2) -1];
% 	h5_maxDims = fliplr(maxDims);
% 	space_id = H5S.create_simple(3, h5_initDims, h5_maxDims);

% 	% Create the Dataset
% 	% datasetName = '1';
% 	dcpl_id = H5P.create('H5P_DATASET_CREATE');
% 	chunkSize = [initDims(1) initDims(2) 1];
% 	h5_chunkSize = fliplr(chunkSize);
% 	H5P.set_chunk(dcpl_id, h5_chunkSize);

% 	% dsetType_id = H5T.copy('H5T_NATIVE_DOUBLE');
% 	dsetType_id = H5T.copy('H5T_NATIVE_UINT16');

% 	dset_id = H5D.create(fid, datasetName, dsetType_id, space_id, dcpl_id);

% 	% Initial Data to Write
% 	% rowDim = initDims(1); colDim = initDims(2);
% 	initDataToWrite = rand(initDims);

% 	% Write the initial data
% 	H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', inputData);

% 	% Close the open Identifiers
% 	H5S.close(space_id);
% 	H5D.close(dset_id);
% 	H5F.close(fid);


% function appendDataToHdf5(filename, datasetName, inputData, varargin)
% 	% appends 3D data to existing dataset in hdf5 file, assumes x,y are the same, only appending z.

% 	% open the dataset and append data to the unlimited dimension which in this case is the second dimension as seen from matlab.
% 	fid = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
% 	dset_id = H5D.open(fid, datasetName);

% 	% create the data to be appended
% 	% dimsOfData = [7 7 42];
% 	dimsOfData = size(inputData);
% 	h5_dimsOfData = fliplr(dimsOfData);

% 	% get the dataspace of the dataset to be appended
% 	space_id = H5D.get_space(dset_id);

% 	[~, h5_currDims] = H5S.get_simple_extent_dims(space_id);
% 	currDims = fliplr(h5_currDims);

% 	% update the extend of the dataspace to match the data to be appended
% 	newDims = currDims;
% 	newDims(3) = currDims(3) + dimsOfData(3);
% 	h5_newDims = fliplr(newDims);

% 	H5D.set_extent(dset_id, h5_newDims);

% 	% Data to append
% 	% rowDim = dimsOfData(1); colDim = dimsOfData(2);
% 	% dataToWrite = rand(dimsOfData);

% 	% Update the File Space ID such that only the appended data is written.
% 	H5S.close(space_id);
% 	space_id = H5D.get_space(dset_id);

% 	% Define the hyperslab selection
% 	start = [0 0 currDims(3)]; h5_start = fliplr(start);
% 	stride = [1 1 1]; h5_stride = fliplr(stride);
% 	count = [1 1 1]; h5_count = fliplr(count);
% 	block = dimsOfData; h5_block = fliplr(block);

% 	H5S.select_hyperslab(space_id, 'H5S_SELECT_SET', h5_start, h5_stride, h5_count, h5_block);

% 	% Write the Data
% 	memSpace_id = H5S.create_simple(3, h5_dimsOfData, []);
% 	H5D.write(dset_id, 'H5ML_DEFAULT', memSpace_id, space_id, 'H5P_DEFAULT', inputData);

% 	% Close the open identifiers
% 	H5S.close(memSpace_id);
% 	H5S.close(space_id);
% 	H5D.close(dset_id);
% 	H5F.close(fid);