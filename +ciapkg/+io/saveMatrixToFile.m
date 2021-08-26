function [success] = saveMatrixToFile(inputMatrix,savePath,varargin)
	% Save 3D matrix to arbitrary file type (HDF5, TIF, AVI for now).
	% Biafra Ahanonu
	% started: 2016.01.12 [11:09:53]
	% inputs
		% inputMatrix - [x y frame] movie matrix
		% savePath - character string of path to file with extension included,
	% outputs
		%

	% changelog
		% 2021.04.24 [16:00:01] - updated TIFF saving to add support for export of multi-channel color timeseries TIFF stack if in format [x y C t] where x,y = width/height, C = RGB channels, t = frames
	% TODO
		% Add checking of data size so tiff can be automatically switched

	%========================
	% default or force a save type
	options.saveType = 'avi';
	% how to save AVI, e.g. 'Motion JPEG AVI', see https://www.mathworks.com/help/matlab/ref/videowriter.html#inputarg_profile
	options.aviSaveType = 'Grayscale AVI';
	% whether to have the waitbar enabled
	options.waitbarOn = 1;
	% hierarchy name in hdf5 where movie is
	options.inputDatasetName = '/1';
	% frame rate, e.g. for AVI
	options.saveFPS = 20;
	% HDF5: additional information to save inside the HDF5 file
	options.addInfo = [];
	% HDF5: dataset name for additional info, e.g. '/movie/processingSettings'
	options.addInfoName = [];
	% HDF5: append (don't blank HDF5 file) or new (blank HDF5 file)
	options.writeMode = 'new';
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 1;
	% Str: description of imaging plane
	options.descriptionImagingPlane = 'NA';
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
		[options.saveType supported] = getMovieFileType(savePath);
		if supported==0
			display('Unsupported save type, supported types are tif, tiff, h5, hdf5, and avi.')
			return;
		end
		display(['save matrix size: ' num2str(size(inputMatrix))])
		startTime = tic;
		movieClass = class(inputMatrix);
		switch options.saveType
			case 'avi'
				fprintf('Saving to: %s\n',savePath);
				%
				nFrames = size(inputMatrix,3);
				writerObj = VideoWriter(savePath,options.aviSaveType);
				writerObj.FrameRate = options.saveFPS;
				open(writerObj);
				switch movieClass
					case 'single'
						inputMatrix = normalizeVector(inputMatrix,'normRange','zeroToOne');
					case 'double'
						inputMatrix = normalizeVector(inputMatrix,'normRange','zeroToOne');
					otherwise
						% do nothing
				end

				% Same each frame to AVI file
				reverseStr = '';
				for frameNo = 1:nFrames
					thisFrame = inputMatrix(:,:,frameNo);
					writeVideo(writerObj,thisFrame);
					reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','saving avi','waitbarOn',options.waitbarOn,'displayEvery',50);
				end
				close(writerObj);
			case 'tiff'
				tiffOptions.comp = 'no';
				tiffOptions.overwrite = true;
                if length(size(inputMatrix))==4
                    tiffOptions.color = true;
                    disp('Saving TIFF as color timeseries stack.');
                end
				fprintf('Saving to: %s\n',savePath);
				saveastiff(inputMatrix, savePath, tiffOptions);
			case 'hdf5'
				fprintf('Saving to: %s\n',savePath);
				[output] = writeHDF5Data(inputMatrix,savePath,'datasetname',options.inputDatasetName,'addInfo',options.addInfo,'addInfoName',options.addInfoName,'writeMode',options.writeMode,'deflateLevel',options.deflateLevel);
			case 'nwb'
				fprintf('Saving to: %s\n',savePath);
				% options.writeMode = '';
				ciapkg.nwb.saveNwbMovie(inputMatrix,savePath,'datasetname',options.inputDatasetName,'addInfo',options.addInfo,'addInfoName',options.addInfoName,'deflateLevel',options.deflateLevel,'descriptionImagingPlane',options.descriptionImagingPlane,'writeMode',options.writeMode);
			otherwise
				%
		end
		endTime = toc(startTime);
		fprintf('Done! Time elapsed: %0.1f seconds | %0.3f minutes \n',endTime,endTime/60);
		success = 1;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
function [movieType supported] = getMovieFileType(thisMoviePath)
	% determine how to load movie, don't assume every movie in list is of the same type
	supported = 1;
	try
		[pathstr,name,ext] = fileparts(thisMoviePath);
	catch
		movieType = '';
		supported = 0;
		return;
	end
	% files are assumed to be named correctly (lying does no one any good)
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		movieType = 'hdf5';
	elseif strcmp(ext,'.nwb')
		movieType = 'nwb';
	elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
		movieType = 'tiff';
	elseif strcmp(ext,'.avi')
		movieType = 'avi';
	else
		movieType = '';
		supported = 0;
	end
end