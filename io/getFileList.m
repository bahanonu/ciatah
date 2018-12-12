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
    % TODO
        % Fix recusive to recursive in a backwards compatible way

    %========================
    options.recusive = 0;
    %
    options.recursive = '';
    %
    options.regexpWithFolder = 0;
    %
    options.excludeFilter = '';
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
                    fileList{end+1} = [thisDirHere filesep filename];
                end
            else
                filename = files(file,:);
                filename = filename{1};
                if(~isempty(cell2mat(regexpi(filename, filterExp))))
                    fileList{end+1} = [filename];
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
end