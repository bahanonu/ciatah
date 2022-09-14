function [pullStruct] = mergeStructs(toStruct,fromStruct,varargin)
    % [toStruct] = mergeStructs(fromStruct,toStruct,overwritePullFields)
    %
    % Copies fields in fromStruct into toStruct, if there is an overlap in field names, fromStruct overwrites toStruct unless specified otherwise.
    %
    % Biafra Ahanonu
    % started: 2014.02.12
    %
    % inputs
    %   toStruct - Structure that is to be updated with values from fromStruct.
    %   fromStruct - structure to use to overwrite toStruct.
    %   overwritePullFields - 1 = overwrite toStruct fields with fromStruct, 0 = don't overwrite.
    % outputs
    %   toStruct - structure with fromStructs values added.

    [pullStruct] = ciapkg.io.mergeStructs(toStruct,fromStruct,'passArgs', varargin);
end