function [logStruct] = getLogInfo(logFilePath,varargin)
	% Opens a log file (e.g. Inscopix recording file) and outputs a structure containing the field information for the structure.
	% Biafra Ahanonu
	% started: 2014.01.30
	% based on R code by Biafra Ahanonu started: 2013.09.18
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.delimiter = ':';
	options.logType = 'inscopix';
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
		% files are assumed to be named correctly (lying does no one any good)
		switch options.logType
			case 'inscopix'
				[pathstr,name,ext] = fileparts(logFilePath);
				if strcmp(ext,'.xml')
					options.logType = 'inscopixXML';
				elseif strcmp(ext,'.mat')
					options.logType = 'inscopixMAT';
				else
					% do something
				end
			otherwise
				% body
		end

		% different parsers depending on type of log
		switch options.logType
			case 'inscopix'
				% open the file, read in newline
				fid = fopen(logFilePath);
					logTxt = textscan(fid,'%s','delimiter','');
				fclose(fid);
				logTxt = logTxt{1};
				[logStruct] = parseInscopixLog(logTxt,options);
			case 'inscopixXML'
				[logStruct] = parseInscopixXMLLog(logFilePath,options);
			case 'inscopixMAT'
				[logStruct] = parseInscopixMATLog(logFilePath,options);
			otherwise
				logStruct.null = true;
				return
		end
		logStruct.filename = logFilePath;
		logStruct.fileType = options.logType;
	catch err
		display(repmat('@',1,7));
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7));
		logStruct.null = true;
		logType = NaN;
	end
end

function [logStruct] = parseInscopixMATLog(logTxt,options)
	load(logTxt);
	logStruct = inputMovieIsxInfo;
end

function [logStruct] = parseInscopixXMLLog(logTxt,options)
	rootName = 'recording';
	parentName = 'attrs';
	childName = 'attr';
	attributeName = 'name';
	logStruct = xml2struct(logTxt);
	logStruct = logStruct.(rootName).(parentName).(childName);
	nAttrs = length(logStruct);
	for attrNo = 1:nAttrs
		tmpLogStruct.(logStruct{attrNo}.Attributes.(attributeName)) = logStruct{attrNo}.Text;
	end
	logStruct = tmpLogStruct;
end

function [logStruct] = parseInscopixLog(logTxt,options)
	% remove files from structure for now
	filesLineIdx = strmatch('FILES',logTxt);
	if ~isempty(filesLineIdx)
		logTxtClean = {logTxt{1:(filesLineIdx-1)}}';
	end
	% convert time to seconds
	timeLineIdx = strmatch('TIME',logTxtClean);
	if ~isempty(timeLineIdx)
		timeArray = strsplit(logTxtClean{timeLineIdx},options.delimiter);
		timeSeconds = str2num(timeArray{2})*60 + str2num(timeArray{3});
		logTxtClean{timeLineIdx} = strcat(timeArray{1},options.delimiter,num2str(timeSeconds));
	end
	% convert version number to a integer
	versionLineIdx = strmatch('VERSION',logTxt);
	if ~isempty(versionLineIdx)
		logTxtClean{versionLineIdx} = strrep(logTxtClean{versionLineIdx},'.','');
	end

	% turn log txt array into cell array, extract names and values
	logCellArray = cellfun(@(x)(strsplit(x,options.delimiter)),logTxtClean,'UniformOutput',0);
	logNames = cellfun(@(x)(x{1}),logCellArray,'UniformOutput',0);
	logNames = strrep(logNames,' ','_');
	logValues = cellfun(@(x)(str2num(x{2})),logCellArray,'UniformOutput',0);

	% combine values and names into single array
	logStruct = cell2struct(logValues,logNames,1);
end