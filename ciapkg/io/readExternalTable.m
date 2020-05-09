function [outputTable] = readExternalTable(inputTableFilename,varargin)
	% Read in table, decides whether to do a single or multiple tables, if multiple tables, should have the same column names.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		% inputTableFilename - string pointing toward file
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% which table to read in
	% options.table = 'discreteStimulusTable';
	% table delimiter, 'tab' or ','
	options.delimiter = 'tab';
	% whether to add file information to the table
	options.addFileInfoToTable = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	pathClass = class(inputTableFilename);
	% pathClass
	switch pathClass
		case 'char'
			display(['loading: ' inputTableFilename])
			outputTable = readtable(inputTableFilename,'Delimiter',options.delimiter,'FileType','text');
		case 'cell'
			nPaths = length(inputTableFilename);
			for i=1:nPaths
				thisTablePath = inputTableFilename{i};
				if(exist(thisTablePath, 'file'))
					display(['loading: ' thisTablePath])
					if ~exist('outputTable')
						outputTable = readtable(char(inputTableFilename(i)),'Delimiter',options.delimiter,'FileType','text','TreatAsEmpty',{'NA','N/A'});
						if options.addFileInfoToTable==1
							[outputTable] = addFileInfoToTable(outputTable,thisTablePath);
						end
					else
						tmpTable = readtable(char(inputTableFilename(i)),'Delimiter',options.delimiter,'FileType','text','TreatAsEmpty',{'NA','N/A'});
						if options.addFileInfoToTable==1
							[tmpTable] = addFileInfoToTable(tmpTable,thisTablePath);
						end
						outputTable = [outputTable;tmpTable];
					end
				end
			end
		otherwise
	end

	function [inputTable] = addFileInfoToTable(inputTable,inputFileName)
		fileInfo = getFileInfo(inputFileName);
		repeatSize = [size(inputTable,1) 1];
		inputTable.subject = repmat(fileInfo.subjectNum,repeatSize);
	    % inputTable.assay = repmat({fileInfo.assay},repeatSize);
	    inputTable.trial = repmat({fileInfo.assay},repeatSize);
	end
end