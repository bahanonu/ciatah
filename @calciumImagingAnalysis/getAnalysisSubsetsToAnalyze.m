function [fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = getAnalysisSubsetsToAnalyze(obj)
    % Internal function to get folders and stimuli to analyze
    % Biafra Ahanonu
    % started: 2015.09.14 [14:54:00]
    % inputs
        %
    % outputs
        %

    % changelog
        %
    % TODO
        %

    % if strcmp(obj.analysisType,'group')
    %     nFiles = length(obj.rawSignals);
    % else
    %     nFiles = 1;
    % end

    scnsize = get(0,'ScreenSize');
    guiEnabled = obj.guiEnabled;
    guiEnabled = 0;

    if guiEnabled==1
        [fileIdxArray, ok] = listdlg('ListString',obj.folderBaseSaveStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');

        if isempty(obj.stimulusNameArray)
            idNumIdxArray = [];
        else
            [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','stimuli to analyze?');
        end
    else
        if isempty(obj.foldersToAnalyze)
            fileIdxArray = 1:length(obj.folderBaseSaveStr);
        else
            fileIdxArray = obj.foldersToAnalyze;
        end
        if isempty(obj.discreteStimuliToAnalyze)&~isempty(obj.stimulusNameArray)
            idNumIdxArray = 1:length(obj.stimulusNameArray);
        else
            idNumIdxArray = obj.discreteStimuliToAnalyze;
        end
    end
    nFilesToAnalyze = length(fileIdxArray);
    % nFiles = length(obj.rawSignals);
    nFiles = length(obj.inputFolders);
end