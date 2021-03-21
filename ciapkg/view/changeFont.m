function [success] = changeFont(FontSize,varargin)
	% Changes the font of all values in a figure.
	% Biafra Ahanonu
	% started: 2019.05.05 [19:00:24]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.04.28 [19:17:49] - Added ability to change all the font colors at the same time, useful for making presentations on non-white backgrounds.
		% 2020.10.01 [09:39:33] - Added support for changing font type.
        % 2021.03.07 [16:35:55] - Add font name support.
	% TODO
		% Add support for changing other font aspects, e.g. figure Font family, command window font, etc.

	%========================
	% DESCRIPTION
	% Int: size of font to use
	options.FontSize = [];
	% Float: [r g b] vector between 0 to 1.
	options.fontColor = [];
	% Str: Name of font family, e.g. Consolas.
	options.fontName = [];
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
		if ischar(FontSize)
			set(findall(gcf,'-property','FontName'),'FontName',FontSize);
		else
			options.FontSize = FontSize;
			if isempty(options.FontSize)
				userInput = inputdlg('New font');
				userInput = str2num(userInput{1});
			else
				userInput = options.FontSize;
			end
			set(findall(gcf,'-property','FontSize'),'FontSize',userInput);
			if ~isempty(options.fontColor)
				try
					set(findall(gcf,'-property','FontSize'),'Color',options.fontColor);
					set(findall(gcf,'-property','YColor'),'YColor',options.fontColor);
					set(findall(gcf,'-property','XColor'),'XColor',options.fontColor);
				catch

				end
            end
            if ~isempty(options.fontName)
                set(findall(gcf,'-property','FontName'),'FontName',options.fontName);
            end
            
		end
		success = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end