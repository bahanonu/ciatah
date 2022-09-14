function [bfSeriesNo] = getSeriesNoFromName(inputFilePath,bfSeriesName,varargin)
	% [bfSeriesNo] = getSeriesNoFromName(inputFilePath,bfSeriesName,varargin)
	% 
	% Returns series number for Bio-Formats series with name given by user.
	% 
	% Biafra Ahanonu
	% started: 2022.07.15 [08:10:16]
	% 
	% Inputs
	% 	inputFilePath - Str: path to Bio-Formats compatible file.
	% 	bfSeriesName - Str: name of series within the file. Can be a regular expression.
	% 
	% Outputs
	% 	bfSeriesNo - Int: series number (1-based indexing) matching the input series name. NaN is output if no series is found.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% File ID connection from calling bfGetReader(inputFilePath), this is to save time on larger files by avoiding opening the connection again.
	% 	options.fileIdOpen = '';

	% Changelog
		%
	% TODO
		%

	% ========================
	% File ID connection from calling bfGetReader(inputFilePath), this is to save time on larger files by avoiding opening the connection again.
	options.fileIdOpen = [];
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
		% By default output NaN if no series found.
		bfSeriesNo = NaN;

		if isempty(options.fileIdOpen)
			disp(['Opening connection to Bio-Formats file:' inputFilePath])
			startReadTime = tic;
			fileIdOpen = bfGetReader(inputFilePath);
			toc(startReadTime)
		else
			fileIdOpen = options.fileIdOpen;
		end
		omeMeta = fileIdOpen.getMetadataStore();

		if isempty(bfSeriesName)
			disp('Please provide a series name for Bio-Formats')
		else
			disp(['Searching for series: "' bfSeriesName '"'])
			nSeries = fileIdOpen.getSeriesCount();
			seriesNameArray = cell([1 nSeries]);
			disp('===')
			disp(['Series in file: ' inputFilePath])
			for seriesNo = 1:nSeries
				% Convert 1-based to 0-based indexing.
				thisStr = char(omeMeta.getImageName(seriesNo-1));
				seriesNameArray{seriesNo} = thisStr;
				disp([num2str(seriesNo) ': "' thisStr '"'])
			end
			disp('===')
			matchIdx = ~cellfun(@isempty,regexp(seriesNameArray,bfSeriesName));
			if any(matchIdx)
				bfSeriesNo = find(matchIdx);
				bfSeriesNo = bfSeriesNo(1);
				disp(['Series found: ' num2str(bfSeriesNo) ' - "' seriesNameArray{bfSeriesNo} '"'])
			end
		end
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
function [outputs] = localfxn_exampleFxn(arg)
	% Always start local functions with "localfxn_" prefix.
	% outputs = ;
end	