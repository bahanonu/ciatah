function [success] = writeDataToMatfile(inputDataPath,varName,outputMatfilePath,varargin)
	% [success] = writeDataToMatfile(inputDataPath,varName,outputMatfilePath,varargin)
	% 
	% Converts 3D movie matrix stored in a file (HDF5, TIF, AVI, NWB) into a MAT-file for use with larger-than-memory processing.
	% 
	% Biafra Ahanonu
	% started: 2022.03.14 [00:44:08]
	% 
	% inputs
	% 	inputMatfilePath - Str: path to matfile object containing data.
	% 	varName - Str: name of variable in MAT-file to save. Should be matrix of [x y frames].
	% 	inputFilename - Str: path where HDF5 file should be saved.
	% 
	% outputs
	% 	success - Binary: 1 = data saved correctly, 0 = data not saved correctly.
	% 

	% changelog
		%
	% TODO
		%

	% ========================
	% Str: name of HDF5 dataset to save data into.
	options.inputDatasetname = '/1';
	% Int: Number of frames to use for chunking the data to save in parts.
	options.chunkSize = 200;
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 9;
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [];
	% Str: class to force data to be, e.g. 'single', 'double', 'uint16', etc.
	options.saveSpecificImgClass = '';
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		success = 0;

		% Get size of the input data, call this way instead of size(inputObj.varName) to avoid loading entire dataset into memory.
		% dataDim = size(inputObj,varName);
		dataDimStruct = ciapkg.io.getMovieInfo(inputDataPath);
		dataDim = [dataDimStruct.one dataDimStruct.two dataDimStruct.three];

		if length(dataDim)~=3
			disp('Data is not a 3D matrix of size [:, :, >1], returning...')
			return;
		end

		% Use saving of individual fields of a structure to dynamically store user variable name.
		saveStruct = struct;
		% Save a temporary empty vector variable to MAT-file. Use -v7.3 to allow partial loading, saves memory.
		if isempty(options.saveSpecificImgClass)
			saveStruct.(varName) = zeros([dataDim(1) dataDim(2) 2],'single');
		else
			saveStruct.(varName) = zeros([dataDim(1) dataDim(2) 2],options.saveSpecificImgClass);
		end
		disp(['Creating MAT-file: ' outputMatfilePath])
		save(outputMatfilePath,'-struct','saveStruct','-v7.3');
		disp('Done creating MAT-file')

		% Create matfile object to saved MAT-file.
		disp('Creating matfile object.')
		inputObj = matfile(outputMatfilePath,'Writable',true);
		
		% Get coordinates to use.
		nFrames = dataDim(3);		
		subsetSize = options.chunkSize;
		movieLength = nFrames;
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		nSubsets = (length(subsetList)-1);

		disp('Writing file data to matfile in chunks:')
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

			% Get slice of the data
			inputDataSlice = ciapkg.io.loadMovieList(inputDataPath,'frameList',movieSubset,'inputDatasetName',options.inputDatasetname,'largeMovieLoad',1);

			if ~isempty(options.saveSpecificImgClass)
				inputDataSlice = cast(inputDataSlice,options.saveSpecificImgClass);
			end

			% Slice into the desired variable using dynamic field references to avoid loading entire dataset into memory.
			inputObj.(varName)(:,:,movieSubset) = inputDataSlice;

			% toc(subsetStartTime)
		end

		success = 1;

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [outputs] = nestedfxn_exampleFxn(arg)
		% Always start nested functions with "nestedfxn_" prefix.
		% outputs = ;
	end	
end