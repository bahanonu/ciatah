function [options] = getOptions(options,inputArgs,varargin)
	% Gets default options for a function and replaces them with inputArgs inputs if they are present in Name-Value pair input (e.g. varargin).
	% Biafra Ahanonu
	% Started: 2013.11.04.
	%
	% inputs
		% options - structure passed by parent function with each fieldname containing an option to be used by the parent function.
		% inputArgs - an even numbered cell array, with {'option','value'} as the ordering. Normally pass varargin.
	% Outputs
		% options - options structure passed back to parent function with modified Name-Value inputs to function added.
	% NOTE
		% Use the 'options' name-value pair to input an options structure that will overwrite default options in a function, example below.
		% options.Stargazer = 1;
		% options.SHH = 0;
		% getMutations(mutationList,'options',options);
		%
		% This is in contrast to using name-value pairs, both will produce the same result.
		% getMutations(mutationList,'Stargazer',1,'SHH',0);
		%
		% The 'passArgs' name-value pair will pass through the parent functions varargin to child functions.
	% USAGE
		% function [input1,input2] = exampleFxn(input1,input2,varargin)
		% 	%========================
		% 	% DESCRIPTION
		% 	options.Stargazer = '';
		% 	% DESCRIPTION
		% 	options.SHH = '';
		% 	% DESCRIPTION
		% 	options.Option3 = '';
		% 	% get options
		% 	options = getOptions(options,varargin); % ***HERE IS WHERE getOptions IS USED***
		% 	% display(options)
		% 	% unpack options into current workspace
		% 	% fn=fieldnames(options);
		% 	% for i=1:length(fn)
		% 	% 	eval([fn{i} '=options.' fn{i} ';']);
		% 	% end
		% 	%========================
		% 	try
		% 		% Do something.
		% 		% How to use the passArgs feature.
		% 		childFunction(arg1,arg2,'passArgs',varargin);
		% 	catch err
		% 		disp(repmat('@',1,7))
		% 		disp(getReport(err,'extended','hyperlinks','on'));
		% 		disp(repmat('@',1,7))
		% 	end
		% end

	[options] = ciapkg.io.getOptions(options,inputArgs,'passArgs', varargin);
end