function [options] = getOptions(options,inputArgs,varargin)
    % Gets default options for a function, replaces with inputArgs inputs if they are present.
    % Biafra Ahanonu
    % started: 2013.11.04
    %
    % inputs
    %   options - structure with options
    %   inputArgs - an even numbered cell array, with {'option','value'} as the ordering. Normally pass varargin.
    %
    % NOTE
    %   use the 'options' name-value pair to input an options structure that will overwrite default options in a function, example below.
    %   options.Stargazer = 1;
    %   options.SHH = 0;
    %   getMutations(mutationList,'options',options);
    %
    %   This is in contrast to using name-value pairs, both will produce the same result.
    %   getMutations(mutationList,'Stargazer',1,'SHH',0);
    %
    % USAGE
    %   %========================
    %   options.movieType = 'tiff';
    %   % get options
    %   options = getOptions(options,varargin);
    %   % unpack options into current workspace, comment out if want to just call options structure
    %   fn=fieldnames(options);
    %   for i=1:length(fn)
    %       eval([fn{i} '=options.' fn{i} ';']);
    %   end
    %   %========================

    % changelog
    % 2014.02.12 [11:56:00] - added feature to allow input of an options structure that contains the options instead of having to input multiple name-value pairs. - Biafra
    % 2014.07.10 [05:19:00] - added displayed warning if an option is input that was not present (this usually indicates typo) - Lacey (merged)
    % 2014.12.10 [19:32:54] - now gets calling function and uses that to get default options - Biafra
    % 2015.08.24 [23:31:36] - updated comments. - Biafra
    % 2015.12.03 [13:52:15] - Added recursive aspect to mirrorRightStruct and added support for handling struct name-value inputs. mirrorRightStruct checks that struct options input by the user are struct in the input options. - Biafra
    % 2016.xx.xx - warnings now show both calling function and it's parent function, improve debug for warnings. Slight refactoring of code to make easier to follow. - Biafra

    % TODO
    % allow input of an option structure - DONE!
    % call settings function to have defaults for all functions in a single place - DONE!
    % allow recursive overwriting of options structure - DONE!
    % Type checking of all field names input by the user?

    %========================
    % whether getOptions should use recursive structures
    goptions.recursiveStructs = 1;
    % whether to show warning if option input that is not in original structure
    goptions.showWarnings = 1;
    % number of parent stacks to show
    goptions.nParentStacks = 1;
    % Binary: 1 = get defaults for a function
    goptions.getFunctionDefaults = 0;
    % filter through options
    try
        for i = 1:2:length(varargin)
            inputField = varargin{i};
            if isfield(goptions, inputField)
                inputValue = varargin{i+1};
                goptions.(inputField) = inputValue;
            end
        end
    catch err
        localShowErrorReport(err);
        display(['Incorrect options given to <a href="matlab: opentoline(''getOptions.m'')">getOptions</a>"'])
    end
    % don't do this! recursion with no base case waiting to happen...
    % goptions = getOptions(goptions,varargin);
    %========================

    % Get default options for a function
    if goptions.getFunctionDefaults==1
        [ST,I] = dbstack;
        fieldnames(ST)
        parentFunctionName = {ST.name};
        parentFunctionName = parentFunctionName{2};
        [optionsTmp] = getSettings(parentFunctionName);
        if isempty(optionsTmp)
            % Do nothing, don't use defaults if not present
        else
            options = optionsTmp;
            % options = mirrorRightStruct(inputOptions,options,goptions,val);
        end
    end

    % Get list of available options
    validOptions = fieldnames(options);

    % Loop over all input arguments, overwrite default/input options
    for i = 1:2:length(inputArgs)
        % inputArgs = inputArgs{1};
        val = inputArgs{i};
        if ischar(val)
            %display([inputArgs{i} ': ' num2str(inputArgs{i+1})]);
            if strcmp('options',val)
                % Special options struct, only add field names defined by the user. Keep all original field names that are not input by the user.
                inputOptions = inputArgs{i+1};
                options = mirrorRightStruct(inputOptions,options,goptions,val);
            elseif sum(strcmp(val,validOptions))>0&isstruct(options.(val))&goptions.recursiveStructs==1
                % If struct name-value, add users field name changes only, keep all original field names in the struct intact, struct-recursion ON
                inputOptions = inputArgs{i+1};
                options.(val) = mirrorRightStruct(inputOptions,options.(val),goptions,val);
            elseif sum(strcmp(val,validOptions))>0
                % Non-options, non-struct value, struct-recursion OFF
                % elseif ~isempty(strcmp(val,validOptions))
                % Way more elegant, directly overwrite option
                options.(val) = inputArgs{i+1};
                % eval(['options.' val '=' num2str(inputArgs{i+1}) ';']);
            else
                if goptions.showWarnings==1
                    localShowWarnings(2,'name-value','','',val,goptions.nParentStacks);
                end
            end
        else
            if goptions.showWarnings==1
                localShowWarnings(2,'name-value incorrect','','',val,goptions.nParentStacks);
            end
            continue;
        end
    end
    %display(options);
end
function [toStruct] = mirrorRightStruct(fromStruct,toStruct,goptions,toStructName)
    % Overwrites fields in toStruct with those in fromStruct, other toStruct fields remain intact.
    % More generally, copies fields in fromStruct into toStruct, if there is an overlap in field names, fromStruct overwrites.
    % Fields present in toStruct but not fromStruct are kept in toStruct output.
    fromNames = fieldnames(fromStruct);
    for name = 1:length(fromNames)
        fromField = fromNames{name};
        % if a field name is a struct, recursively grab user options from it
        if isfield(toStruct, fromField)|isprop(toStruct, fromField)
            if isstruct(fromStruct.(fromField))&goptions.recursiveStructs==1
                % safety check: field exist in toStruct and is also a structure
                if isstruct(toStruct.(fromField))
                    toStruct.(fromField) = mirrorRightStruct(fromStruct.(fromField),toStruct.(fromField),goptions,[toStructName '.' fromField]);
                else
                    localShowWarnings(3,'notstruct',toStructName,fromField,'',goptions.nParentStacks);
                end
            else
                toStruct.(fromField) = fromStruct.(fromField);
            end
        else
            if goptions.showWarnings==1
                localShowWarnings(3,'struct',toStructName,fromField,'',goptions.nParentStacks);
            end
        end
    end
end
function localShowErrorReport(err)
    % Displays an error report.
    display(repmat('@',1,7))
    disp(getReport(err,'extended','hyperlinks','on'));
    display(repmat('@',1,7))
end
function localShowWarnings(stackLevel,displayType,toStructName,fromField,val,nParentStacks)
    % Sub-function to centralize displaying of warnings within the function
    try
        % Calling localShowWarnings adds to the stack, adjust accordingly.
        stackLevel = stackLevel+1;

        % Get the entire function-call stack.
        [ST,~] = dbstack;
        callingFxn = ST(stackLevel).name;
        callingFxnPath=which(ST(stackLevel).file);
        callingFxnLine = num2str(ST(stackLevel).line);

        % Add info about parent function of function that called getOptions.
        callingFxnParentStr = '';
        % nParentStacks = 2;
        stackLevelTwo = stackLevel+1;
        for stackNo = 1:nParentStacks
            if length(ST)>=(stackLevelTwo)
                callingFxnParent = ST(stackLevelTwo).name;
                callingFxnParentPath = which(ST(stackLevelTwo).file);
                callingFxnParentLine = num2str(ST(stackLevelTwo).line);
                callingFxnParentStr = [callingFxnParentStr ' | <a href="matlab: opentoline(''' callingFxnParentPath ''',' callingFxnParentLine ')">' callingFxnParent '</a> line ' callingFxnParentLine];
            else
                callingFxnParentStr = '';
            end
            stackLevelTwo = stackLevelTwo+1;
        end

        % Display different information based on what type of warning occurred.
        switch displayType
            case 'struct'
                disp(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not a valid option for <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
            case 'notstruct'
                disp(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not originally a STRUCT, ignoring. <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
            case 'name-value incorrect'
                disp(['<strong>WARNING</strong>: enter the parameter name before its associated value in <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
            case 'name-value'
                disp(['<strong>WARNING</strong>: <a href="">' val '</a> is not a valid option for <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
            otherwise
                % do nothing
        end
    catch err
        localShowErrorReport(err);
        callingFxn = 'UNKNOWN FUNCTION';
        % Display different information based on what type of warning occurred.
        switch displayType
            case 'struct'
                disp(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not a valid option for "' callingFxn '"'])
            case 'notstruct'
                display('Unknown error.')
            case 'name-value incorrect'
                disp(['<strong>WARNING</strong>: enter the parameter name before its associated value in "' callingFxn '"'])
            case 'name-value'
                disp(['<strong>WARNING</strong>: <a href="">' val '</a> is not a valid option for "' callingFxn '"'])
            otherwise
                % do nothing
        end
    end
end