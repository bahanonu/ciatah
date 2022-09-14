function [output1,output2] = exampleFxn(input1,input2,varargin)
	% [output1,output2] = EXAMPLEFXN(input1,input2,varargin)
	% 
	% DESCRIPTION.
	% 
	% Biafra Ahanonu
	% started: INSERT_DATE
	% 
	% Inputs
	% 	input1
	% 	input2
	% 
	% Outputs
	% 	output1
	% 	output2
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2022.03.14 [01:47:04] - Added nested and local functions to the example function.
	% TODO
		%

	% ========================
	% DESCRIPTION
	options.exampleOption = '';
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		% Code
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [outputs] = nestedfxn_exampleFxn(arg)
		% Always start nested functions with "nestedfxn_" prefix.
		% outputs = ;
	end	
end
function [outputs] = localfxn_exampleFxn(arg)
	% Always start local functions with "localfxn_" prefix.
	% outputs = ;
end	

% CIAtah method
function obj = functionName(obj,varargin)
	% EXAMPLEFXN(input1,input2,varargin)
	% 
	% DESCRIPTION.
	% 
	% Biafra Ahanonu
	% started: INSERT_DATE
	% 
	% inputs
	% 	input1
	% 	input2
	% outputs
	% 	output1
	% 	output2

	% changelog
		%
	% TODO
		%


	% ========================
	% DESCRIPTION
	options.baseOption = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		% Code
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end

% started: 2014.01.03 [19:13:01]
obj.addprop('discreteStimuliToAnalyze')