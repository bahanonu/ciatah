function [pkgNameStr] = pkgName(varargin)
	% Get name for the package (CIAtah by default).
	% Biafra Ahanonu
	% started: updated: 2021.03.16 [‏‎14:39:41]
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
		pkgNameStr = 'CIAtah';
	catch err
		pkgNameStr = 'CIAtah';
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end