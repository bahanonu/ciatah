function [success, destFolders] = moveFilesToFolders(pathToSrc,pathToDest,varargin)
    % copies folder structure (i.e. only folders, not files) from src to dest then searches for files in dest that are in src subfolders and moves them to their corresponding subfolders in dest. this is NOT recursive.
    % biafra ahanonu
    % started: 2014.01.03 [19:13:01]
    % inputs
        % pathToSrc
        % pathToDest
    % outputs
        %

    [success, destFolders] = ciapkg.io.moveFilesToFolders(pathToSrc,pathToDest,'passArgs', varargin);
end