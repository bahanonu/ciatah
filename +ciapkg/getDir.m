function [ciapkgDir] = getDir(varargin)
	% Returns the root ciapkg directory, e.g. the folder containing the +ciapkg package folder.
	% Biafra Ahanonu
	% started: 2020.08.31 [12:46:57]
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
		functionLocation = dbstack('-completenames');
		functionLocation = functionLocation(1).file;
		[functionDir,~,~] = fileparts(functionLocation);
		% [functionDir,~,~] = fileparts(functionDir);
		[ciapkgDir,~,~] = fileparts(functionDir);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end