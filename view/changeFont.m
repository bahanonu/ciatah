function [success] = changeFont(varargin)
	% Changes the font of all values in a figure.
	% Biafra Ahanonu
	% started: 2019.05.05 [19:00:24]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		% Add support for changing other font aspects, e.g. figure Font family, command window font, etc.

	%========================
	% DESCRIPTION
	% Int: size of font to use
	options.FontSize = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		success = 0;
		if isempty(options.FontSize)
			userInput = inputdlg('New font');
			userInput = str2num(userInput{1});
		else
			userInput = options.FontSize;
		end
		set(findall(gcf,'-property','FontSize'),'FontSize',userInput);
		success = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end