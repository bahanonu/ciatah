function appendDataToHdf5(filename, datasetName, inputData, varargin)
	% Appends 3D data to existing dataset in hdf5 file, assumes x,y are the same, only appending z.
	% Biafra Ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	% changelog
		% 2014.07.22
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	display(['appending data to: ' filename])
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
	display('done appending.')
end