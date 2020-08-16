function [jsonStr] = jsonWrite(inputVar,saveStr,varargin)
	% Writes an input variable out as a JSON string to a file or sends back to parent function.
	% Biafra Ahanonu
	% started: 2020.06.09 [12:19:01]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% DESCRIPTION
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		if nargin==1
			saveStr = '';
		end

		% Encode the input variable as a JSON string
		jsonStr = jsonencode(inputVar);

		if ~isempty(saveStr)
			fprintf('Saving to %s.\n',saveStr);
			fID = fopen(saveStr,'w');
			fprintf(fID,'%s',jsonStr);
			fclose(fID);
		end

		if nargout==0
			disp(subfxnHumanReadable(jsonStr));
		end

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end

function [jsonStr] = subfxnHumanReadable(jsonStr)
	% Make human readable
	jsonStr = strrep(jsonStr, ',', sprintf(',\r'));
	jsonStr = strrep(jsonStr, '[{', sprintf('[\r{\r'));
	jsonStr = strrep(jsonStr, '}]', sprintf('\r}\r]'));
end