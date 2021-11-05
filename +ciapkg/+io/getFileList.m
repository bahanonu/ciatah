function [fileList] = getFileList(inputDir, filterExp,varargin)
	% Gathers a list of files based on an input regular expression.
	% Biafra Ahanonu
	% started: 2013.10.08 [11:02:31]
	% inputs
		% inputDir - directory to gather files from and regexp filter for files
		% filterExp - regexp used to find files
	% outputs
		% file list, full path

	% changelog
		% 2014.03.21 - added feature to input cell array of filters
		% 2016.03.20 - added exclusion filter to function
		% 2019.03.08 [13:12:59] - added support for natural sorting of files
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.09.10 [03:17:56] - Added support to exclude adding the input directory to each file path.
	% TODO
		% Fix recusive to recursive in a backwards compatible way

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Binary: 1 = recursively find files in all sub-directories. 0 = only find files in inputDir directory.
	options.recursive = '';
	% Append 
	options.regexpWithFolder = 0;
	% String: filter to exclude.
	options.excludeFilter = '';
	% Binary: 1 = add inputDir to file paths, 0 = do not add input directory.
	options.addInputDirToPath = 1;
	% Char: lexicographic (e.g. 1 10 11 2 21 22 unless have 01 02 10 11 21 22) or numeric (e.g. 1 2 10 11 21 22) or natural (e.g. 1 2 10 11 21 22)
	% options.sortMethod = 'lexicographic';
	options.sortMethod = 'natural';
	% DEPRECIATED 1 = recursively find files in all sub-directories. 0 = only find files in inputDir directory.
	options.recusive = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	if ~isempty(options.recursive)
		options.recusive = options.recursive;
	end
	% options.recursive = options.recusive;

	if ~iscell(filterExp)
		filterExp = {filterExp};
	end
	if ischar(inputDir)
		inputDir = {inputDir};
	end

	fileList = {};
	for thisDir = inputDir
		thisDirHere = thisDir{1};
		if options.recusive==0
			files = dir(thisDirHere);
		else
			files = dirrec(thisDirHere)';
		end
		for file=1:length(files)
			if options.recusive==0
				filename = files(file,1).name;
				if options.regexpWithFolder==1
					filename = [options.regexpWithFolder filesep filename];
				end

				if(~isempty(cell2mat(regexpi(filename, filterExp))))
					if options.addInputDirToPath==1
						fileList{end+1} = [thisDirHere filesep filename];
					else
						[~,filename,filenameExt] = fileparts(filename);
						filename = [filename filenameExt];
						fileList{end+1} = [filename];
					end
				end
			else
				filename = files(file,:);
				filename = filename{1};
				if(~isempty(cell2mat(regexpi(filename, filterExp))))
					if options.addInputDirToPath==1
						fileList{end+1} = [filename];
					else
						[~,filename,filenameExt] = fileparts(filename);
						filename = [filename filenameExt];
						fileList{end+1} = [filename];
					end
				end
			end
		end
	end
	if ~isempty(options.excludeFilter)
		% excludeIdx = find(~cellfun(@isempty,(regexp(fileList,options.excludeFilter))));
		excludeIdx = ~cellfun(@isempty,(regexp(fileList,options.excludeFilter)));
		fileList(excludeIdx) = [];
		% includeIdx = setdiff(1:length(fileList),excludeIdx)
	end
	if ~isempty(fileList)&&(strcmp(options.sortMethod,'natural')|strcmp(options.sortMethod,'numeric'))
		fileList = natsortfiles(fileList);
	end
end