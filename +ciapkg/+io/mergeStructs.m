function [toStruct] = mergeStructs(toStruct,fromStruct,varargin)
	% [toStruct] = mergeStructs(fromStruct,toStruct,overwritePullFields)
	%
	% Copies fields in fromStruct into toStruct, if there is an overlap in field names, fromStruct overwrites toStruct unless specified otherwise.
	%
	% Biafra Ahanonu
	% started: 2014.02.12
	%
	% inputs
	% 	toStruct - Structure that is to be updated with values from fromStruct.
	% 	fromStruct - structure to use to overwrite toStruct.
	% 	overwritePullFields - 1 = overwrite toStruct fields with fromStruct, 0 = don't overwrite.
	% outputs
	% 	toStruct - structure with fromStructs values added.

	% changelog
		% 2022.07.06 [11:13:02] - Make updates from getOptions to include recursive structures and other options. Remove overwritePullFields input argument, make Name-Value input instead. Change naming of fromStruct and toStruct to fromStruct and toStruct, easier for users.
	% TODO
		%

	%========================
	% Options for getOptions.
	% Avoid recursion here, hence don't use getOptions for getOptions's options.
	% Binary: 1 = whether getOptions should use recursive structures or crawl through a structure's field names or just replace the entire structure. For example, if "1" then options that themselves are a structure or contain sub-structures, the fields will be replaced rather than the entire strucutre.
	goptions.recursiveStructs = 1;
	% Binary: 1 = show warning if user inputs Name-Value pair option input that is not in original structure.
	goptions.showWarnings = 1;
	% Int: number of parent stacks to show during warning.
	goptions.nParentStacks = 1;
	% Binary: 1 = get defaults for a function from getSettings.
	goptions.getFunctionDefaults = 0;
	% Binary: 1 = show full stack trace on incorrect option.
	goptions.showStack = 1;
	% OBSOLETE | Binary: 1 = overwrite toStruct input fields.
	goptions.overwritePullFields = 1;
	% Update getOptions's options based on user input.

	% get user options, else keeps the defaults
	goptions = ciapkg.io.getOptions(goptions,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	pushNames = fieldnames(fromStruct);
	pullNames = fieldnames(toStruct);
	% loop over all fromStruct fields, add them to fromStruct
	% for name = 1:length(pushNames)
	% 	iPushName = pushNames{name};

	% 	% % don't overwrite
	% 	% if overwritePullFields==0&~isempty(strmatch(iPushName,pullNames))
	% 	% 	continue;
	% 	% end
	% 	% toStruct.(iPushName) = fromStruct.(iPushName);

	% end
	[toStruct] = mirrorRightStruct(fromStruct,toStruct,goptions,'options');
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
					if goptions.showWarnings==1
						localShowWarnings(3,'notstruct',toStructName,fromField,'',goptions.nParentStacks,goptions.showStack);
					end
				end
			else
				toStruct.(fromField) = fromStruct.(fromField);
			end
		else
			if goptions.showWarnings==1
				localShowWarnings(3,'struct',toStructName,fromField,'',goptions.nParentStacks,goptions.showStack);
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
function localShowWarnings(stackLevel,displayType,toStructName,fromField,val,nParentStacks,showStack)
	% Sub-function to centralize displaying of warnings within the function
	try
		% Calling localShowWarnings adds to the stack, adjust accordingly.
		stackLevel = stackLevel+1;

		% Get the entire function-call stack.
		[ST,~] = dbstack;
		if isempty(ST)|length(ST)<stackLevel
			subfxnShowWarningsError(stackLevel,displayType,toStructName,fromField,val,nParentStacks);
			return;
		end
		callingFxn = ST(stackLevel).name;
		callingFxnPath = which(ST(stackLevel).file);
		callingFxnLine = num2str(ST(stackLevel).line);

		% Add info about parent function of function that called getOptions.
		callingFxnParentStr = '';
		if showStack==1
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
		end

		% Display different information based on what type of warning occurred.
		switch displayType
			case 'struct'
				warning(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not a valid option for <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
			case 'notstruct'
				warning(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not originally a STRUCT, ignoring. <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
			case 'name-value incorrect'
				warning(['<strong>WARNING</strong>: enter the parameter name before its associated value in <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
			case 'name-value'
				warning(['<strong>WARNING</strong>: <a href="">' val '</a> is not a valid option for <a href="matlab: opentoline(''' callingFxnPath ''',' callingFxnLine ')">' callingFxn '</a> on line ' callingFxnLine callingFxnParentStr])
			otherwise
				% do nothing
		end
	catch err
		localShowErrorReport(err);
		subfxnShowWarningsError(stackLevel,displayType,toStructName,fromField,val,nParentStacks);
	end
end
function subfxnShowWarningsError(stackLevel,displayType,toStructName,fromField,val,nParentStacks)
	callingFxn = 'UNKNOWN FUNCTION';
	% Display different information based on what type of warning occurred.
	switch displayType
		case 'struct'
			warning(['<strong>WARNING</strong>: <a href="">' toStructName '.' fromField '</a> is not a valid option for "' callingFxn '"'])
		case 'notstruct'
			warning('Unknown error.')
		case 'name-value incorrect'
			warning(['<strong>WARNING</strong>: enter the parameter name before its associated value in "' callingFxn '"'])
		case 'name-value'
			warning(['<strong>WARNING</strong>: <a href="">' val '</a> is not a valid option for "' callingFxn '"'])
		otherwise
			% do nothing
	end
end