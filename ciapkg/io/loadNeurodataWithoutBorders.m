function [inputImages,inputTraces,infoStruct, algorithmStr] = loadNeurodataWithoutBorders(inputFilePath,varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: 2020.04.04 [15:02:22]
	% inputs
		% inputFilePath - Str: path to NWB file. If a cell, will only load the first string.
	% outputs
		%

	% changelog
		% 2021.02.05 [19:02:44] - Parse the algorithm associated with the NWB signal extraction data.
	% TODO
		%

	%========================
	% DESCRIPTION
	% cellmax, pcaica, cnmf, cnmfe, extract, roi
	options.algorithm = '';
	% String: main name for image mask group
	options.groupImages = '/processing/ophys/ImageSegmentation/PlaneSegmentation';
	options.planeNo = 1;
	% Dataset name for image masks
	options.imagesName = 'image_mask';
	% String: main name for fluorescence series
	options.groupSignalSeries = '/processing/ophys/Fluorescence/RoiResponseSeries';
	% Cell array of strings: alternative names for fluorescence series
	options.groupSignalSeriesAlt = {'/processing/ophys/Fluorescence/Series','/processing/ophys/Fluorescence/RoiResponseSeries'};
	options.signalsName = 'data';
	% Int: user specified series number if needed
	options.signalSeriesNo = [];
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
		algorithmStr = '';

		if iscell(inputFilePath)
			inputFilePath = inputFilePath{1};
		end
		% Return if not a string, return as not appropriate input
		if ~ischar(inputFilePath)
			return;
		end
		try
			imagesGroupName = [options.groupImages num2str(options.planeNo) '/' options.imagesName];
			imagesGroupNameAttr = [options.groupImages num2str(options.planeNo)];
			% Check exist else use different default
			h5info(inputFilePath,imagesGroupName);
		catch
			imagesGroupName = [options.groupImages '/' options.imagesName];
			imagesGroupNameAttr = [options.groupImages];
		end

		if options.loadImages==1
			fprintf('Loading: %s file -> %s.\n',inputFilePath,imagesGroupName);
			inputImages = h5read(inputFilePath,imagesGroupName);
		else
			inputImages = [];
		end

		roitestNames = {options.groupSignalSeries,options.groupSignalSeriesAlt{:}};
		tracesGroupNameFinal = '';
		nNums = 2;
		numList = [1:nNums NaN];
		if ~isempty(options.signalSeriesNo)
			numList = [options.signalSeriesNo numList];
		end
		% Iterate until find the correct name for activity series
		for nameNo = 1:length(roitestNames)
			for seriesNo = numList
				try
					if isnan(seriesNo)==1
						tracesGroupName = [roitestNames{nameNo} '/' options.signalsName];
					else
						tracesGroupName = [roitestNames{nameNo} num2str(seriesNo) '/' options.signalsName];
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

		% Get description if later need cell-extraction information
		tmp = h5readatt(inputFilePath,imagesGroupNameAttr,'description');
		infoStruct.description = tmp;

		% Check if extraction method in infoStruct then add
		try
			if isfield(infoStruct,'description')
				tmpStr = regexp(infoStruct.description,'Extraction method: \w+','match');
				tmpStr = strsplit(tmpStr{1}{1},': ');
				algorithmStr = tmpStr{2};
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end