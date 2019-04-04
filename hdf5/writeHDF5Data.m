function [success] = writeHDF5Data(inputData,saveDir,varargin)
	% Saves input data to a HDF5 file, tries to preserve datatype.
	% Biafra Ahanonu
	% started: 2013.11.01
	%
	% inputs
		% movieList = full path names for movies to concatenate
	% outputs
		% success = 1 if successful save, 0 if error.
	% options
		% datasetname = HDF5 hierarchy where data should be stored

	% changelog
		% 2014.01.23 - updated so that it saves as the input data-type rather than defaulting to double
		% 2014.10.06 - added chunking to save, decrease compatibility problems.
		% 2015.06.19 - added automatic creation of file's directory if it doesn't already exist.
		% 2019.03.19 [17:37:38] User option to customize chunking instead of using whole x-y, useful for very large FOV movies
	% TODO
		% Add option to overwrite existing HDF5 file ()

	%========================
	% old way of saving, only temporary until full switch
	options.datasetname = '/1';
	% HDF5: append (don't blank HDF5 file) or new (blank HDF5 file)
	options.writeMode = 'new';
	% save only a portion of the dataset, useful for large datasets
	% 3D matrix, [0 0 0] start and [x y z] end.
	options.hdfStart = [];
	options.hdfCount = [];
	options.addInfo = [];
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
 	options.deflateLevel = 0;
	% e.g. '/movie/processingSettings'
	options.addInfoName = [];
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [];
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	try
		if strcmp(options.writeMode,'new')
			if exist(saveDir,'file')
				delete(saveDir)
			end
		end
		% ensure that the directory exists
		[pathstr,name,ext] = fileparts(saveDir);
		if (~exist(pathstr,'dir')) mkdir(pathstr); end;
		%get class name
		inputClass = class(inputData);
		display(['input class: ' inputClass])
		% create a h5 file
		display(['creating HDF5 file: ' saveDir])
		if isempty(options.hdfStart)
			dataDims = size(inputData);
			% [dim1 dim2 dim3] = size(inputData);
		else
			dataDims = options.hdfCount - options.hdfStart;
		end
		if isempty(options.dataDimsChunkCopy)
			% set the last dimension to 1 for chunking
			dataDimsChunkCopy = dataDims;
			dataDimsChunkCopy(end) = 1;
		else
			dataDimsChunkCopy = options.dataDimsChunkCopy;
		end
		if strcmp(options.writeMode,'new')
			% create HDF dataspace
			h5create(saveDir,options.datasetname,dataDims,'Datatype',inputClass,'ChunkSize',dataDimsChunkCopy,'Deflate',options.deflateLevel);
		else
			display(['New HDF5 not created, overwriting <' options.datasetname '> dataset'])
		end
		% write out the inputData
		display(['writing HDF5 file: ' saveDir])
		if isempty(options.hdfStart)
			h5write(saveDir,options.datasetname, inputData);
		else
			h5write(saveDir,options.datasetname, inputData, options.hdfStart, options.hdfCount);
		end

		% add information about data to HDF5 file
		if strcmp(options.writeMode,'new')
			hdf5write(saveDir,'/movie/info/dimensions',dataDims,'WriteMode','append');
			currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
			hdf5write(saveDir,'/movie/info/date',currentDateTimeStr,'WriteMode','append');
			hdf5write(saveDir,'/movie/info/savePath',saveDir,'WriteMode','append');
			hdf5write(saveDir,'/movie/info/Deflate',options.deflateLevel,'WriteMode','append');
		end
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
					hdf5write(saveDir,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
				end
			end
		end

		display('success!!!');
		success = 1;
	catch err
		success = 0;
		display('something went wrong 0_o');
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end