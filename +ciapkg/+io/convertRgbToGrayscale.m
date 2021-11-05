function [success] = convertRgbToGrayscale(inputListFile,varargin)
	% Converts rgb AVI file to grayscale, e.g. for ImageJ base tracking.
	% Biafra Ahanonu
	% started: 2017.03.23
	% inputs
		% inputListFile - A string pointing to a directory or a cell array of strings.
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% blank = all frames, else vector with [1:framesDesired]
	options.frameList = [];
	% string for the modifier to put on new movies
	options.movieModifier = '_uncompressedGrayscale';
	% 'mean' = take mean of RGB channels, 'single' = take R channel only
	options.rgbConversionType = 'single';
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
		% user input a file linking to directories
		if ischar(inputListFile)
			fid = fopen(inputListFile, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			fileList = tmpData{1,1};
			fclose(fid);
		elseif iscell(inputListFile)
			fileList = inputListFile;
		else
			display('Incorrect input, try again.')
			return;
		end
		nFiles = length(fileList);

		% loop over all files and convert to 8bit grayscale AVI.
		for fileNo = 1:nFiles
			thisMoviePath = fileList{fileNo};

			fprintf('Reading from: %s\n',thisMoviePath);
			xyloObj = VideoReader(thisMoviePath);

			% get new naming scheme for saved file
			[oldPath,oldName,oldExt] = fileparts(thisMoviePath);
			newFilePath = [oldPath filesep oldName options.movieModifier oldExt];
			fprintf('Writing to : %s\n',newFilePath);

			% open the video writer object
			writerObj = VideoWriter(newFilePath,'Grayscale AVI');
			open(writerObj);

			% determine which frames to use
			if isempty(options.frameList)
				nFrames = xyloObj.NumberOfFrames;
				framesToGrab = 1:nFrames;
			else
				nFrames = length(options.frameList);
				framesToGrab = options.frameList;
			end

			% Preallocate movie structure.
			vidHeight = xyloObj.Height;
			vidWidth = xyloObj.Width;
			tmpMovie = zeros(vidHeight, vidWidth, nFrames, 'uint8');

			% Read one frame at a time, convert, and save.
			nFrames = length(framesToGrab);
			for frameNo = 1:nFrames
				readFrame = framesToGrab(frameNo);
				tmpAviFrame = read(xyloObj, readFrame);
				frameClass = class(tmpAviFrame);
				% check if frame is RGB or grayscale, if RGB only take one channel (since they will be identical for RGB grayscale)
				if size(tmpAviFrame,3)==3
					switch options.rgbConversionType
						case 'single'
							tmpAviFrame = squeeze(tmpAviFrame(:,:,1));
						case 'mean'
							tmpAviFrame = squeeze(mean(tmpAviFrame,3));
						otherwise
							tmpAviFrame = squeeze(tmpAviFrame(:,:,1));
					end
				end
				tmpAviFrame = cast(tmpAviFrame,frameClass);
			    % tmpMovie(:,:,frameNo) = tmpAviFrame;

			    writeVideo(writerObj,tmpAviFrame);

		        % display progress
		        if mod(frameNo,5)==0
		        	fprintf('progress %d/%d\n',frameNo,nFrames);
		        end
			end
			close(writerObj);
		end
		success = 1;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end