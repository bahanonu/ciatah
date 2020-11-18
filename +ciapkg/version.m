function [versionStr, dateTimeStr] = version(varargin)
	% Get version for calciumImagingAnalysis
	% Biafra Ahanonu
	% started: 2020.06.06 [23:36:36]
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
		versionStr = 'v3.21.2';
		dateTimeStr = '20201117211648';
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end