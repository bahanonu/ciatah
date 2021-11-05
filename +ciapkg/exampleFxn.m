function [output1,output2] = exampleFxn(input1,input2,varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: INSERT_DATE
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% ========================
	% DESCRIPTION
	options.exampleOption = '';
	% get options
	options = ciapkg.io.getOptions(options,varargin);
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
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end

% CIAtah method
function obj = functionName(obj,varargin)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: INSERT_DATE
	% inputs
		%
	% outputs
		%

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