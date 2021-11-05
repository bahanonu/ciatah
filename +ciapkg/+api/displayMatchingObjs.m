function [matchedObjMaps, euclideanStruct] = displayMatchingObjs(inputImages,globalIDs,varargin)
    % Displays information on matching cells across sessions.
    % Biafra Ahanonu
    % started: 2014.01.03 [19:13:01]
    % inputs
        % inputImages - cell array {1, N} N = each trial of [x y nFilters] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}
        % globalIDs, [M N] matrix with M = number of global IDs and N = each trial. Each m,n pair specifies the index of that global obj m in the data of trial n. If .globalIDs(m,n)==0, means no match was found.
    % outputs
        %

    [matchedObjMaps, euclideanStruct] = ciapkg.view.displayMatchingObjs(inputImages,globalIDs,'passArgs', varargin);
end