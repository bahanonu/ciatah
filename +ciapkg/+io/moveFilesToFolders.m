function [success destFolders] = moveFilesToFolders(pathToSrc,pathToDest,varargin)
    % copies folder structure (i.e. only folders, not files) from src to dest then searches for files in dest that are in src subfolders and moves them to their corresponding subfolders in dest. this is NOT recursive.
    % biafra ahanonu
    % started: 2014.01.03 [19:13:01]
    % inputs
        % pathToSrc
        % pathToDest
    % outputs
        %

    % changelog
        % 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
    % TODO
        %

    import ciapkg.api.* % import CIAtah functions in ciapkg package API.

    %========================
    % used to determine which folders to copy from src to dest
    options.srcFolderFilterRegexp = '201\d';
    % this regexp is used to search the destination directory
    options.srcSubfolderFileFilterRegexp = 'recording.*.(txt|xml)';%xml
    %
    options.srcSubfolderFileFilterRegexpExt = '(.txt|.xml)';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================
    success = 0;
    try
        % get a list of the folders to move and search for files
        listOfSrcFolders = getFileList(pathToSrc,options.srcFolderFilterRegexp);
        nFolders = length(listOfSrcFolders);
        %
        destFolders = {};

        % for each folder from the source directory, find all of the relevant
        % files and move them into appropriate sub-directories
        for i = 1:nFolders
            loopFolder = listOfSrcFolders{i};
            % get the base folder name, create a copy in destination directory
            [pathstr,destFolderName,ext] = fileparts(loopFolder);
            destFolderMovePath = [pathToDest '\' destFolderName];

            % for each folder, filter for specific file name scheme
            loopFolderFiles = getFileList(loopFolder,options.srcSubfolderFileFilterRegexp);
            loopFolderFiles = regexp(loopFolderFiles, options.srcSubfolderFileFilterRegexp,'match');
            if ~isempty(loopFolderFiles)
                % loop over each src subfolder file, use it as a regexp to find and move dest files
                for j = 1:length(loopFolderFiles)
                    display(repmat('_',1,7))
                    iFile = regexprep(loopFolderFiles{j},options.srcSubfolderFileFilterRegexpExt,'');
                    filesToMove = getFileList(pathToDest,iFile);
                    if ~isempty(filesToMove)
                        destFolders{end+1} = destFolderMovePath;
                        for k = 1:length(filesToMove)
                            thisFileToMoveSrc = filesToMove{k};
                            [pathstr,fileToMove,ext] = fileparts(thisFileToMoveSrc);
                            thisFileToMoveSrc
                            thisFileToMoveDest = [destFolderMovePath '\' fileToMove ext]
                            if ~exist(destFolderMovePath,'file')
                                mkdir(pathToDest,destFolderName);
                            end
                            % use system calls to move files, appears to be fastest method
                            if ispc
                                dos(['move ' thisFileToMoveSrc ' ' thisFileToMoveDest]);
                            elseif isunix
                                unix(['mv ' thisFileToMoveSrc ' ' thisFileToMoveDest]);
                            end
                            % java.io.File(thisFileToMoveSrc).renameTo(java.io.File(thisFileToMoveDest));
                            % movefile(thisFileToMoveSrc,thisFileToMoveDest)
                        end
                    else
                        display(char(strcat('no matching files: ',loopFolder,loopFolderFiles{j})));
                    end
                end
            end
        end
        success = 1;
    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
        success = 0;
    end
end