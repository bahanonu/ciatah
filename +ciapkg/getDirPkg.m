function [ciapkgDir] = getDirPkg(dirType,varargin)
	% Standardized location to obtain relevant CIAtah directories, e.g. location of default data folder.
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
		switch dirType
			case 'data'
				ciapkgDir = [ciapkg.getDir() filesep 'data'];
			otherwise
				ciapkgDir = '';
				disp('Incorrect input, returning null.')
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end