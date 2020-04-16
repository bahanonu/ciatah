function [inputImages,inputTraces,infoStruct] = loadNeurodataWithoutBorders(inputFilePath,varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: 2020.04.04 [15:02:22]
	% inputs
		% inputFilePath - Str: path to NWB file. If a cell, will only load the first string.
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% DESCRIPTION
	% cellmax, pcaica, cnmf, cnmfe, extract, roi
	options.algorithm = '';
	options.groupImages = '/processing/ophys/ImageSegmentation/PlaneSegmentation';
	options.planeNo = 1;
	options.imagesName = 'image_mask';
	options.groupSignalSeries = '/processing/ophys/Fluorescence/RoiResponseSeries';
	options.groupSignalSeriesAlt = '/processing/ophys/Fluorescence/Series';
	options.signalsName = 'data';
	options.signalSeriesNo = 1;
	% 1 = load images, 0 = do not load images (e.g. when user only wants the traces)
	options.loadImages = 1;
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
		inputImages = [];
		inputTraces = [];
		infoStruct = struct;

		if iscell(inputFilePath)
			inputFilePath = inputFilePath{1};
		end
		% Return if not a string, return as not appropriate input
		if ~ischar(inputFilePath)
			return;
		end
		if options.loadImages==1
			try
				imagesGroupName = [options.groupImages num2str(options.planeNo) '/' options.imagesName];
				% Check exist else use different default
				h5info(inputFilePath,imagesGroupName);
			catch
				imagesGroupName = [options.groupImages '/' options.imagesName];
			end
			fprintf('Loading: %s file -> %s.\n',inputFilePath,imagesGroupName);
			inputImages = h5read(inputFilePath,imagesGroupName);
		else
			inputImages = [];
		end

		roitestNames = {options.groupSignalSeries,options.groupSignalSeriesAlt};
		tracesGroupNameFinal = '';
		for ggg = 1:length(roitestNames)
			for fff = 1:2
				try
					% tracesGroupName = [options.groupSignalSeries num2str(options.signalSeriesNo) '/' options.signalsName];
					if fff==1
						tracesGroupName = [roitestNames{ggg} num2str(fff) '/' options.signalsName];
					else
						tracesGroupName = [roitestNames{ggg} '/' options.signalsName];
					end
					% Check exist else use different default
					h5info(inputFilePath,tracesGroupName);
					tracesGroupNameFinal = tracesGroupName;
				catch
				end
			end
		end
		fprintf('Loading: %s file -> %s.\n',inputFilePath,tracesGroupNameFinal);
		inputTraces = h5read(inputFilePath,tracesGroupNameFinal);

		disp(['inputImages: ' num2str(size(inputImages))]);
		disp(['inputTraces: ' num2str(size(inputTraces))]);
		tmp = h5readatt(inputFilePath,options.groupImages,'description');
		infoStruct.description = tmp;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end