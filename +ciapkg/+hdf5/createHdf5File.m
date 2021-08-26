function createHdf5File(filename, datasetName, inputData, varargin)
	% Creates an HDF5 file at filename under given datasetName hierarchy and saves inputData.
	% Biafra Ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.03.25 [17:17:49] - Add support for custom user HDF5 chunking as opposed to previous automatic chunking
		% 2019.08.20 [11:38:54] - Added additional support for more data types.
        % 2021.02.02 [13:15:11] - Close space_id, dset_id, and fid with low-level HDF5 functions before appending data with hdf5write to avoid read/write issues.
	% TODO
		%
	%========================
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [];
	options.addInfo = [];
	% Char array: cell array of strings matching addInfo, e.g. '/movie/processingSettings'
	options.addInfoName = [];
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	display(['creating: ' filename])
	% Create the HDF5 file
	fcpl_id = H5P.create('H5P_FILE_CREATE');
	fapl_id = H5P.create('H5P_FILE_ACCESS');

	fid = H5F.create(filename, 'H5F_ACC_TRUNC', fcpl_id, fapl_id);

	% Create the Space for the Dataset
	initDims = size(inputData);
	h5_initDims = fliplr(initDims);
	maxDims = [initDims(1) initDims(2) -1];
	h5_maxDims = fliplr(maxDims);
	space_id = H5S.create_simple(3, h5_initDims, h5_maxDims);

	% Create the Dataset
	% datasetName = '1';
	dcpl_id = H5P.create('H5P_DATASET_CREATE');

	if isempty(options.dataDimsChunkCopy)
		% set the last dimension to 1 for chunking
		chunkSize = [initDims(1) initDims(2) 1];
	else
		chunkSize = options.dataDimsChunkCopy;
	end
	h5_chunkSize = fliplr(chunkSize);

	H5P.set_chunk(dcpl_id, h5_chunkSize);
	fprintf('Set compression level to %d of 9\n',options.deflateLevel);
	H5P.set_deflate(dcpl_id,options.deflateLevel);

	inputClass = class(inputData);
	switch inputClass
		case 'single'
			dsetType_id = H5T.copy('H5T_IEEE_F32LE');
		case 'double'
			dsetType_id = H5T.copy('H5T_NATIVE_DOUBLE');
		case 'uint16'
			dsetType_id = H5T.copy('H5T_NATIVE_UINT16');
		case 'int16'
			dsetType_id = H5T.copy('H5T_NATIVE_INT16');
		case 'uint8'
			dsetType_id = H5T.copy('H5T_NATIVE_UINT8');
		case 'int8'
			dsetType_id = H5T.copy('H5T_NATIVE_INT8');
		otherwise
			disp(['Data type ' inputClass ' not supported.'])
			return;
			% body
	end

	dset_id = H5D.create(fid, datasetName, dsetType_id, space_id, dcpl_id);

	% Initial Data to Write
	% rowDim = initDims(1); colDim = initDims(2);
	% initDataToWrite = rand(initDims);

	% Write the initial data
	H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', inputData);
    
    % Close the opened identifiers
	H5S.close(space_id);
	H5D.close(dset_id);
	H5F.close(fid);

	% Append movie relevant information to HDF5 file
	% if strcmp(options.writeMode,'new')
		% hdf5write(filename,'/movie/info/dimensions',dataDims,'WriteMode','append');
		currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
		hdf5write(filename,'/movie/info/date',currentDateTimeStr,'WriteMode','append');
		hdf5write(filename,'/movie/info/savePath',filename,'WriteMode','append');
		hdf5write(filename,'/movie/info/Deflate',options.deflateLevel,'WriteMode','append');
	% end

	% add information about data to HDF5 file
	if ~isempty(options.addInfo)
		if ~iscell(options.addInfo)
			options.addInfo = {options.addInfo};
			options.addInfoName = {options.addInfoName};
		end
		addInfoLen = length(options.addInfo);
		for addInfoStructNo = 1:addInfoLen
			thisAddInfo = options.addInfo{addInfoStructNo};
			infoList = fieldnames(thisAddInfo);
			nInfo = length(infoList);
			for fieldNameNo = 1:nInfo
				thisField = infoList{fieldNameNo};
				hdf5write(filename,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
			end
		end
	end
end