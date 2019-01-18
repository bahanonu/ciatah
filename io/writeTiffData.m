function [output] = writeTiffData(imgdata,FileSaving,varargin)
	% Writes out TIF data.
	% Created by Jerome Lecoq in 2012
	% Separate function by Biafra Ahanonu
	% 2015.07.06 [19:29:37]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try

		% FileSaving=fullfile(handles.Path,handles.File);
		% FromFrame=str2num(get(handles.FromFrame,'String'));
		% ToFrame=str2num(get(handles.ToFrame,'String'));
		NumberFrame=size(imgdata,3);
		TifFile = Tiff(FileSaving,'w');
		% We populate the tag on pixel format depending on the current data
		% type
		switch class(imgdata)
		    case 'logical'
		        tagstruct.SampleFormat=1;
		        tagstruct.BitsPerSample=1;
		    case 'uint16'
		        tagstruct.SampleFormat=1;
		        tagstruct.BitsPerSample=16;
		    case 'int16'
		        tagstruct.SampleFormat=2;
		        tagstruct.BitsPerSample=16;
		    case 'single'
		        tagstruct.SampleFormat=3;
		        tagstruct.BitsPerSample=32;
		    case 'double'
		        tagstruct.SampleFormat=3;
		        tagstruct.BitsPerSample=64;
		    case 'uint8'
		        tagstruct.SampleFormat=1;
		        tagstruct.BitsPerSample=8;
		    case 'int8'
		        tagstruct.SampleFormat=2;
		        tagstruct.BitsPerSample=8;
		    case 'uint32'
		        tagstruct.SampleFormat=1;
		        tagstruct.BitsPerSample=32;
		    case 'int32'
		        tagstruct.SampleFormat=2;
		        tagstruct.BitsPerSample=32;
		end

		CompressionScheme = 1;
		% We populate compression scheme
		switch CompressionScheme
		    case 1
		        % No compression
		        tagstruct.Compression=1;
		    case 2
		        % LZW lossless
		        tagstruct.Compression=5;
		    case 3
		        % Packbits lossless
		        tagstruct.Compression=32773;
		    case 4
		        % Deflate lossless
		        tagstruct.Compression=32946;
		end

		tagstruct.ImageLength = size(imgdata,1);
		tagstruct.ImageWidth = size(imgdata,2);
		tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
		tagstruct.SamplesPerPixel = 1;
		tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
		tagstruct.Software = 'MATLAB';

		for i=1:NumberFrame
		    TifFile.setTag(tagstruct);
		    TifFile.write(imgdata(:,:,i));
		    TifFile.writeDirectory();
		end
		TifFile.close();

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
