function [dataSubset] = readHDF5Subset(inputFilePath, offset, block, varargin)
	% Gets a subset of data from an HDF5 file.
	% Biafra Ahanonu
	% started: 2013.11.10
	% based on code from MathWorks; for details, see http://www.mathworks.com/help/matlab/ref/h5d.read.html
	% inputs
		%
		% offset = cell array of [xOffset yOffset frameOffset]
		% block = cell array of [xDim yDim frames], xDim and yDim should be the same size across all cell arrays, note, the "frames" dimension SHOULD NOT have overlapping frames across cell arrays
	% options
		% datasetName = hierarchy where data is stored in HDF5 file
	% changelog
		% 2013.11.30 [17:59:14]
		% 2014.01.15 [09:59:53] cleaned up code, removed unnecessary options
		% 2017.01.18 [15:01:15] added option to deal with 3D data in 4D format with singleton 4th dimension
		% 2018.09.28 - changed so can read from multiple non-contiguous	slabs of data at the same time

	%========================
	% old way of saving, only temporary until full switch
	options.datasetName = '/1';
	options.displayInfo = 1;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	% get file info
	% hinfo = hdf5info(inputFilePath);
	% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
	% xDim = hReadInfo.Dims(1);
	% yDim = hReadInfo.Dims(2);
    offsetRaw = offset;
    blockRaw = block;
    if iscell(offset)~=1
       offsetTmp = {};
       offsetTmp{1} = offset;
       offset = offsetTmp;
    end
    if iscell(block)~=1
       blockTmp = {};
       blockTmp{1} = block;
       block = blockTmp;
    end

    nSlabs = length(offset);

    % display file information for reference
	if options.displayInfo==1
        for sNo = 1:nSlabs
            display(['loading chunk | offset: ' num2str(offset{sNo}) ' | block: ' num2str(block{sNo}) 10]);
        end
	end

	% open fid to hdf5 dataset
	plist = 'H5P_DEFAULT';
	fid = H5F.open(inputFilePath);
	dset_id = H5D.open(fid,options.datasetName);
	dims = fliplr(block{1});%[xDim yDim 1]
    tmpVar = sum(cat(1,block{:}),1);
    dims(1) = tmpVar(3);
	mem_space_id = H5S.create_simple(length(dims),dims,dims);
	file_space_id = H5D.get_space(dset_id);

	try
        for sNo = 1:nSlabs
            % offset and size of the block to get, flip dimensions so in format that H5S wants
            offsetFlip = fliplr(offset{sNo});
            blockFlip = fliplr(block{sNo});

            % select the hyperslab
            % H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offsetFlip,[],[],blockFlip);

            % select the hyperslab
            if sNo==1
                H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offsetFlip,[],[],blockFlip);
            else
                H5S.select_hyperslab(file_space_id,'H5S_SELECT_OR',offsetFlip,[],[],blockFlip);
            end
            %output = H5S.select_valid(file_space_id)
            %[start,finish] = H5S.get_select_bounds(file_space_id)
            % select the data subset
        end
		dataSubset = H5D.read(dset_id,'H5ML_DEFAULT',mem_space_id,file_space_id,plist);
	catch err
        cat(1,offset{:})
        cat(1,block{:})
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))

        try
            if options.displayInfo==1
                display('Block contains extra dimension');
            end
            % offset and size of the block to get, flip dimensions so in format that H5S wants
            offsetTmp = offset; offsetTmp(4) = 0;
            blockTmp = block; blockTmp(4) = 1;
            offsetFlip = fliplr(offsetTmp);
            blockFlip = fliplr(blockTmp);

            % select the hyperslab
            H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offsetFlip,[],[],blockFlip);
            % select the data subset
            dataSubset = H5D.read(dset_id,'H5ML_DEFAULT',mem_space_id,file_space_id,plist);
        catch err
            display(repmat('@',1,7))
            disp(getReport(err,'extended','hyperlinks','on'));
            display(repmat('@',1,7))
        end
	end

	% close IDs
	H5S.close(file_space_id);
	H5D.close(dset_id);
	H5F.close(fid);

	% output file size
	j = whos('dataSubset');j.bytes=j.bytes*9.53674e-7;
	if options.displayInfo==1
		disp(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class])
	end
end