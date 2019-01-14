function [obj] = modelReadTable(obj,varargin)
	% Read in table, decides whether to do a single or multiple tables. If multiple tables, should have the same column names.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% which table to read in
	options.table = 'discreteStimulusTable';
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

	if isempty(obj.delimiter)
		delimiter = 'tab';
	end
	pathClass = class(obj.(options.table));
	% pathClass
	switch pathClass
		case 'char'
			display(['loading: ' obj.(options.table)])
			outputTable = readtable(obj.(options.table),'Delimiter',obj.delimiter,'FileType','text');
		case 'cell'
			nPaths = length(obj.(options.table));
			for i=1:nPaths
				thisTablePath = obj.(options.table){i};
				if(exist(thisTablePath, 'file'))
					display(['loading: ' thisTablePath])
					if ~exist('outputTable')
						outputTable = readtable(char(obj.(options.table)(i)),'Delimiter',obj.delimiter,'FileType','text','TreatAsEmpty',{'NA','N/A'});
						if options.addFileInfoToTable==1
							[outputTable] = addFileInfoToTable(outputTable,thisTablePath);
						end
					else
						tmpTable = readtable(char(obj.(options.table)(i)),'Delimiter',obj.delimiter,'FileType','text','TreatAsEmpty',{'NA','N/A'});
						if options.addFileInfoToTable==1
							[tmpTable] = addFileInfoToTable(tmpTable,thisTablePath);
						end
						outputTable = [outputTable;tmpTable];
					end
				end
			end
		otherwise
	end

	obj.(options.table) = outputTable;

	function [inputTable] = addFileInfoToTable(inputTable,inputFileName)
		fileInfo = getFileInfo(inputFileName);
		repeatSize = [size(inputTable,1) 1];
		inputTable.subject = repmat(fileInfo.subjectNum,repeatSize);
	    % inputTable.assay = repmat({fileInfo.assay},repeatSize);
	    inputTable.trial = repmat({fileInfo.assay},repeatSize);
	    inputTable.date = repmat({fileInfo.date},repeatSize);
	end
end