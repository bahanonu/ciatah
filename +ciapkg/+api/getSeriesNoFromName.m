function [bfSeriesNo] = getSeriesNoFromName(inputMoviePath,bfSeriesName,varargin)
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
		
	try
		bfSeriesNo = ciapkg.bf.getSeriesNoFromName(inputMoviePath,bfSeriesName,'passArgs',varargin);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end