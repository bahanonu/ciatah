function s = readStruct(file)
% READSTRUCT(FILE) Reads structure from text file, FILE.
% The last entry in each row is the value. The previous
% entries are field (and subfield) names.

% Open the specified file.
fid = fopen(file);

% Read in the first line and set the line number.
line = fgetl(fid);

% The function, fgetl, returns a -1 when an end-of-file is encountered.
while ~isequal(line, -1);

    % Initially, no items from this line
    items = {};

    % Number of items extracted from this line.
    numberOfItems = 0;

    % While there is still some path left, keep parsing nodes into a cell array.
    while line
        numberOfItems = numberOfItems + 1;
        [items{numberOfItems}, line] = strtok(line);
    end

    % Only process non-empty lines.
    if numberOfItems > 1

        % Last item on line is value of field. If first element of last item is a letter,
        % then assume that last item is a char array. Otherwise, assume it is a number.
        if isletter(items{end}(1))
            value = ['''', items{end}, '''']; % Wrap quotes around string.
        else
            value = items{end};
        end

        % remove value from list of items (leaving only field names).
        items = items(1:length(items)-1);

        fieldname = 's'; % Initialize construction of field name.
        for item = items
            fieldname = [fieldname, '.', item{:}]; % Append subfield names to field name.
        end

        % Construct command to assign value to field name.
        command = [fieldname, ' = ', value, ';']

        eval(command);

    elseif numberOfItems == 1;

        error ('Every non-empty line must contain must contain at least one field name and one value.')

    end

    line = fgetl(fid);

end

fclose(fid);