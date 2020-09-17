function out = load_tif_movie(filename,downsample_xy,varargin)
	% Loads filename movie, downsamples in space by factor downsample_xy.
	% Biafra Ahanonu
	% parts adapted from
		% Kerome Lecoq for spikee
		% http://www.mathworks.com/matlabcentral/answers/108021-matlab-only-opens-first-frame-of-multi-page-tiff-stack
	% updating: 2013.10.22
	% inputs
		%
	% outputs
		%
	% changelog
		% 2014.01.07 [10:14:49] - removed low-level reading, seems to have problems with some versions of tifflib, will fix later.
		% 2015.11.12 Added reading of TIFFs from ImageJ bigger than 4GB.
		% 2019.03.10 [20:17:09] Allow user to pre-input TIF temporary file to speed-up load times, esp. with individual files, see options.tmpImage and options.fileInfo
		% 2020.09.01 [14:27:12] - Suppress warning at user request and remove unecessary file handle call.
	% TODO
		%

	%========================
	options.exampleOption = 'doSomething';
	options.Numberframe = [];
	options.frameList = [];
	options.tmpImage = [];
	% Binary: 1 = display outputs in command window
	options.displayInfo = 1;
	% Pre-input imfinfo information here.
	options.fileInfo = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(options.tmpImage)
		%First load a single frame of the movie to get generic information
        if options.displayInfo==0
            warning off
        end
		TifLink = Tiff(filename, 'r'); % Create the Tiff object
		warning off
		TmpImage = TifLink.read();%Read in one picture to get the image size and data type
		warning on
		TifLink.close(); clear TifLink
	else
		TmpImage = options.tmpImage;
	end

	LocalImage = imresize(TmpImage, 1/downsample_xy); clear TmpImage; %Resize
	SizeImage=size(LocalImage);%xy dimensions
	ClassImage= class(LocalImage); clear LocalImage; %Get the class of the movie

	% Pre-allocate the movie
	if isempty(options.Numberframe)
		out.Numberframe=size(imfinfo(filename),1);% Number of frames
		framesToGrab = 1:out.Numberframe;
	else
		out.Numberframe = options.Numberframe;
		framesToGrab = out.Numberframe;
	end
	% out.Movie =zeros(SizeImage(1),SizeImage(2),out.Numberframe,ClassImage);

	% determine whether standard or non-standard TIFF
	display(repmat('=',1,3))
	if numel(framesToGrab)>1
		if options.displayInfo==1
			display('Running standard TIFF')
		end
		% standardTIFF();
		% standardTIFF2();
		standardTIFF_new();
	else
		if options.displayInfo==1
			display('Running non-standard TIFF')
		end
		nonstandardTIFF();
	end

	function standardTIFF()
		imgInfo = imfinfo(filename);
		num_images = numel(imgInfo);

		reverseStr = '';
		for frame = framesToGrab
			out.Movie(:,:,frame) = imread(filename, 'tif', 'Index', frame, 'Info', imgInfo);
			% out.Movie(:,:,frame) = imread(filename, frame);
			% out.Movie(:,:,frame) = imreadCustom(filename, 'tif', 'Index', frame, 'Info', imgInfo);
			reverseStr = cmdWaitbar(frame,numel(framesToGrab),reverseStr,'inputStr','Loading non-ImageJ tif','waitbarOn',1,'displayEvery',50);
		end
	end
	function standardTIFF_new()
		% fileInfo = imfinfo(filename);
		if isempty(options.fileInfo)
			fileInfo = imfinfo(filename);
		else
			fileInfo = options.fileInfo;
		end

		try
			if isfield(fileInfo,'ImageDescription')==1
				numFramesStr = regexp(fileInfo.ImageDescription, 'images=(\d*)', 'tokens');
				nFrames = str2double(numFramesStr{1}{1});
			else
				nFrames = size(fileInfo,1);
				fileInfo = fileInfo(1);
			end
		catch
			try
				if isfield(fileInfo,'StripOffsets')==1
					nFrames = length([fileInfo.StripOffsets]);
				end
			catch
				display('assuming single frame');
				nFrames = 1;
			end
		end
		if isempty(options.frameList)|nFrames==1
			framesToGrab2 = 1:nFrames;
		else
			framesToGrab2 = options.frameList;
		end
		nFramesDim = length(framesToGrab2);
		% open file handle, read file using low level I/O functions
		% fileID = fopen(filename , 'rb');
		% The StripOffsets field provides the offset to the first strip. Based on
		% the INFO for this file, each image assumed to consist of 1 strip.
		StripOffsets = [fileInfo.StripOffsets];
		% fileInfo.StripOffsets(1)
		% fseek(fileID, StripOffsets(1), 'bof');
		% It is assumed that the images are stored one after the other.
		frameNo = nFrames;
		imgHeight = [fileInfo.Height];
		imgWidth = [fileInfo.Width];
		out.Movie = zeros(imgHeight(1),imgWidth(1),nFramesDim,ClassImage);

		imgByteOrder = {fileInfo.ByteOrder};
		switch imgByteOrder{1}
			case 'little-endian'
				byteorder = 'ieee-le';
			case 'big-endian'
				byteorder = 'ieee-be';
			otherwise
				% body
		end

		fileType = ClassImage;

		reverseStr = '';

		warning off
		
		tiffID = Tiff(filename,'r');

		% tiffID.setDirectory(1);
		% rgbTiff = size(read(tiffID),3);
		for frameNo = 1:nFramesDim
			% out.Movie(:,:,frameNo) = fread(fileID, [fileInfo.Width fileInfo.Height], fileType, 0, byteorder)';
			% out.Movie(:,:,frameNo) = fread(fileID, [imgWidth(1) imgHeight(1)], fileType, 0, byteorder)';
			% fseek(fileID, StripOffsets(frameNo), 'bof');
			
			tiffID.setDirectory(framesToGrab2(frameNo));
			% rgbTiff = size(read(tiffID),3);
			%if rgbTiff==1
			try
				out.Movie(:,:,frameNo) = read(tiffID);
			catch
				tmpFrame = read(tiffID);
				out.Movie(:,:,frameNo) = tmpFrame(:,:,1);
			end
			%elseif rgbTiff==3
			%	tmpFrame = read(tiffID);
			%	out.Movie(:,:,frameNo) = tmpFrame(:,:,1);
			%end
			reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','loading ImageJ tif','waitbarOn',1,'displayEvery',50);
		end
		warning on
		% playMovie(out.Movie)

		% close handle to file
		% fclose(fileID);
	end
	function nonstandardTIFF()
		% imfinfo(filename)
		if isempty(options.fileInfo)
			fileInfo = imfinfo(filename);
		else
			fileInfo = options.fileInfo;
		end

		if isempty(options.Numberframe)
			try
				if isfield(fileInfo,'ImageDescription')==1
					numFramesStr = regexp(fileInfo.ImageDescription, 'images=(\d*)', 'tokens');
					nFrames = str2double(numFramesStr{1}{1});
				else
					nFrames = size(fileInfo,1);
					fileInfo = fileInfo(1);
				end
			catch
				display('assuming single frame');
				nFrames = 1;
			end
		else
			nFrames = options.Numberframe;
		end
		if isempty(options.frameList)|nFrames==1
			framesToGrab2 = 1:nFrames;
		else
			framesToGrab2 = options.frameList;
		end
		nFramesDim = length(framesToGrab2);
		% open file handle, read file using low level I/O functions
		fileID = fopen(filename , 'rb');
		% The StripOffsets field provides the offset to the first strip. Based on
		% the INFO for this file, each image assumed to consist of 1 strip.
		fseek(fileID, fileInfo.StripOffsets, 'bof');
		% It is assumed that the images are stored one after the other.
		frameNo = nFrames;
		out.Movie =zeros(fileInfo.Height,fileInfo.Width,nFramesDim,ClassImage);

		switch fileInfo.ByteOrder
			case 'little-endian'
				byteorder = 'ieee-le';
			case 'big-endian'
				byteorder = 'ieee-be';
			otherwise
				% body
		end

		fileType = ClassImage;

		reverseStr = '';
		frameNo2 = 1;
		for frameNo = 1:nFrames
			if frameNo==framesToGrab2(frameNo2)
				out.Movie(:,:,frameNo2) = fread(fileID, [fileInfo.Width fileInfo.Height], fileType, 0, byteorder)';
				if frameNo2~=length(framesToGrab2)
					frameNo2 = frameNo2 + 1;
				end
			end
			if frameNo>nanmax(framesToGrab2)
				break
			end
			% reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','loading ImageJ tif','waitbarOn',1,'displayEvery',50);
			if options.displayInfo==1
				reverseStr = cmdWaitbar(frameNo2,nFramesDim,reverseStr,'inputStr','loading ImageJ tif','waitbarOn',1,'displayEvery',50);
			end
		end

		% close handle to file
		fclose(fileID);
	end
	function standardTIFF2()
		imgInfo = imfinfo(filename);
		% % We use low-level access to the tifflib library file to avoid duplicating
		% % Access to the Tif properties while reading long list of directories in Tiffs
		FileID = tifflib('open',filename,'r');
		rps = tifflib('getField',FileID,Tiff.TiagID.RowsPerStrip);
		hImage = tifflib('getField',FileID,Tiff.TagID.ImageLength);
		% rps = min(rps,hImage);
		mImage=imgInfo(1).Width;
		nImage=imgInfo(1).Height;
		NumberImages=length(imgInfo);
		out.Movie=zeros(nImage,mImage,NumberImages,ClassImage);
		size(out.Movie)

		nrows = 0;
		reverseStr = '';
		for frameNo=1:framesToGrab
		   tifflib('setDirectory',FileID,frameNo);
		   % Go through each strip of data.
		   rps = min(rps,nImage);
		   for r = 1:rps:nImage
			  row_inds = r:min(nImage,r+rps-1);
			  stripNum = tifflib('computeStrip',FileID,r);
			  stripNum
			  % size(tifflib('readEncodedStrip',FileID,stripNum))
			  % size(row_inds)
			  % row_inds
			  out.Movie(row_inds,:,frameNo) = tifflib('readEncodedStrip',FileID,stripNum);
		   end
		   reverseStr = cmdWaitbar(frameNo,numel(framesToGrab),reverseStr,'inputStr','loading non-ImageJ tif','waitbarOn',1,'displayEvery',50);
		end
		tifflib('close',FileID);

		% for frameNo=framesToGrab
		%     tifflib('setDirectory',FileID,1+frameNo-1);
		%     % Go through each strip of data.
		%     for r = 1:rps:hImage
		%         row_inds = r:min(hImage,r+rps-1);
		%         stripNum = tifflib('computeStrip',FileID,r);
		%         display([num2str(r) ' | ' num2str(row_inds) ' | ' num2str(stripNum)])
		%         if downsample_xy~=1
		%             TmpImage(row_inds,:) = tifflib('readEncodedStrip',FileID,stripNum);
		%         else
		%             nrows = nrows + size(tifflib('readEncodedStrip',FileID,stripNum),1)
		%             out.Movie(row_inds,:,frameNo)= tifflib('readEncodedStrip',FileID,stripNum);
		%         end
		%     end
		%     if downsample_xy~=1
		%         out.Movie(:,:,frameNo)=imresize(TmpImage,1/downsample_xy);
		%     end
		%     reverseStr = cmdWaitbar(frame,numel(framesToGrab),reverseStr,'inputStr','loading non-ImageJ tif','waitbarOn',1,'displayEvery',50);
		% end
		% tifflib('close',FileID);
	end
end