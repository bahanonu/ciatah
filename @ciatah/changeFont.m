function obj = changeFont(obj,varargin)
	% Change figure font size
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% DESCRIPTION
	options.fontSize = [];
	% get options
	options = getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(options.fontSize)
		userInput = inputdlg('New font');
		userInput = str2num(userInput{1});
		set(findall(gcf,'-property','FontSize'),'FontSize',userInput);
	else
		set(findall(gcf,'-property','FontSize'),'FontSize',options.fontSize);
	end
end