function [success] = writeMatfileToHDF5(inputMatfilePath,varName,outputFilename,varargin)
	% [success] = writeMatfileToHDF5(inputMatfilePath,varName,outputFilename,varargin)
	% 
	% Writes a MAT-file dataset to HDF5 by reading the matrix in parts to avoid large overhead.
	% 
	% Biafra Ahanonu
	% started: 2022.03.13 [23:49:18]
	% 
	% inputs
	% 	inputMatfilePath - path to matfile object containing data.
	% 	varName - Str: name of variable in MAT-file to save. Should be matrix of [x y frames].
	% 	inputFilename - Str: path where HDF5 file should be saved.
	% 
	% outputs
	% 	success - Binary: 1 = data saved correctly, 0 = data not saved correctly.

	% changelog
		%
	% TODO
		%

	% ========================
	% Str: name of HDF5 dataset to save data into.
	options.datasetname = '/1';
	% HDF5: append (don't blank HDF5 file) or new (blank HDF5 file)
	options.writeMode = 'new';
	% Int: Number of frames to use for chunking the data to save in parts.
	options.chunkSize = 200;
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 9;
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [];
	% Struct: structure of information to add. Will create a HDF5 file
	options.addInfo = [];
	% Str: e.g. '/movie/processingSettings'
	options.addInfoName = '';
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		success = 0;

		% Create matfile object.
		inputObj = matfile(inputMatfilePath);

		% Get size of the input data, call this way instead of size(inputObj.varName) to avoid loading entire dataset into memory.
		dataDims = size(inputObj,varName);

		if length(dataDims)~=3
			disp('Data is not a 3D matrix of size [:, :, >1], returning...')
			return;
		end
		
		% Get coordinates to use.
		nFrames = dataDims(3);		
		subsetSize = options.chunkSize;
		movieLength = nFrames;
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		nSubsets = (length(subsetList)-1);

		% Write data out in chunks.
		for thisSet = 1:nSubsets
			% subsetStartTime = tic;

			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			disp(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
			end
			disp([num2str(movieSubset(1)) '-' num2str(movieSubset(end)) ' ' num2str(thisSet) '/' num2str(nSubsets)])

			% Slice into the desired variable using dynamic field references to avoid loading entire dataset into memory.
			inputDataSlice = inputObj.(varName)(:,:,movieSubset);

			if thisSet==1
				ciapkg.hdf5.createHdf5File(outputFilename, options.datasetname, inputDataSlice,'deflateLevel',options.deflateLevel,'dataDimsChunkCopy',options.dataDimsChunkCopy);
			else
				ciapkg.hdf5.appendDataToHdf5(outputFilename, options.datasetname, inputDataSlice);
			end

			% toc(subsetStartTime)
		end

		% add information about data to HDF5 file
		if strcmp(options.writeMode,'new')
			hdf5write(outputFilename,'/movie/info/dimensions',dataDims,'WriteMode','append');
			currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
			hdf5write(outputFilename,'/movie/info/date',currentDateTimeStr,'WriteMode','append');
			hdf5write(outputFilename,'/movie/info/savePath',outputFilename,'WriteMode','append');
			hdf5write(outputFilename,'/movie/info/Deflate',options.deflateLevel,'WriteMode','append');
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
					hdf5write(outputFilename,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
					% h5write(fileSavePath,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
				end
			end
		end

		success = 1;
	catch err
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	% function [outputs] = nestedfxn_exampleFxn(arg)
	% 	% Always start nested functions with "nestedfxn_" prefix.
	% 	% outputs = ;
	% end	
end