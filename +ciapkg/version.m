function [versionStr, dateTimeStr] = version(varargin)
	% Get version for CIAtah.
	% Biafra Ahanonu
	% started: 2020.06.06 [23:36:36]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.01.18 [13:23:24] - Updated so reads CIAtah version directly from VERSION file instead of having the version information in two places (which increases probability of mismatch).
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
		verPath = [ciapkg.getDir filesep 'ciapkg' filesep 'VERSION'];
		verStr = readcell(verPath,'FileType','text');
		versionStr = verStr{1};
		dateTimeStr = num2str(verStr{2});
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end