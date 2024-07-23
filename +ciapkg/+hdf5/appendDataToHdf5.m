function appendDataToHdf5(filename, datasetName, inputData, varargin)
	% appendDataToHdf5(filename, datasetName, inputData, varargin)
	% 
	% Appends 3D data to existing dataset in hdf5 file, assumes x,y are the same, only appending z.
	% 
	% Biafra Ahanonu
	% started: 2014.01.07
	% 
	% inputs
	%	filename - Str: path to existing HDF5 file.
	% 	datasetName - Str: name for the existing dataset to append to.
	% 	inputData - 3D matrix: input data to append to the end of the existing HDF5 dataset.
	% outputs
		%

	% changelog
		% 2014.07.22
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.03.13 [23:49:04] - Update comments.
		% 2023.09.24 [19:29:43] - Flag to silence command line output.
	% TODO
		%

	% ========================
	% Binary: 1 = whether to display info on command line. 2 = short output.
	options.displayInfo = 1;
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	if options.displayInfo==1
		display(['appending data to: ' filename])
	elseif options.displayInfo==2
		fprintf('+');
	end
	% open the dataset and append data to the unlimited dimension which in this case is the second dimension as seen from matlab.
	fid = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
	dset_id = H5D.open(fid, datasetName);

	% create the data to be appended
	% dimsOfData = [7 7 42];
	dimsOfData = size(inputData);
	h5_dimsOfData = fliplr(dimsOfData);

	% get the dataspace of the dataset to be appended
	space_id = H5D.get_space(dset_id);

	[~, h5_currDims] = H5S.get_simple_extent_dims(space_id);
	currDims = fliplr(h5_currDims);

	% update the extend of the dataspace to match the data to be appended
	newDims = currDims;
	newDims(3) = currDims(3) + dimsOfData(3);
	h5_newDims = fliplr(newDims);

	H5D.set_extent(dset_id, h5_newDims);

	% Data to append
	% rowDim = dimsOfData(1); colDim = dimsOfData(2);
	% dataToWrite = rand(dimsOfData);

	% Update the File Space ID such that only the appended data is written.
	H5S.close(space_id);
	space_id = H5D.get_space(dset_id);

	% Define the hyperslab selection
	start = [0 0 currDims(3)]; h5_start = fliplr(start);
	stride = [1 1 1]; h5_stride = fliplr(stride);
	count = [1 1 1]; h5_count = fliplr(count);
	block = dimsOfData; h5_block = fliplr(block);

	H5S.select_hyperslab(space_id, 'H5S_SELECT_SET', h5_start, h5_stride, h5_count, h5_block);

	% Write the Data
	memSpace_id = H5S.create_simple(3, h5_dimsOfData, []);
	H5D.write(dset_id, 'H5ML_DEFAULT', memSpace_id, space_id, 'H5P_DEFAULT', inputData);

	% Close the open identifiers
	H5S.close(memSpace_id);
	H5S.close(space_id);
	H5D.close(dset_id);
	H5F.close(fid);
	if options.displayInfo==1
		display('done appending.')
	elseif options.displayInfo==2
		fprintf('1|');
	end
end