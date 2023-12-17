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
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
        % 2021.11.18 [09:00:28] - Updated so can update font size, name, color more independent of one another.
        % 2022.01.14 [05:53:37] - Updated so doesn't change Axes backgroundcolor when changing font color, only Axes text.
        % 2022.03.14 [04:06:10] - Also check for matlab.ui.control.UIControl when conducting font color changes and ignore to not cause errors.
		% 2022.12.03 [21:51:44] - Update to handle legend, since use TextColor property instead of Color for text. Users can also put in a blank fontSize to avoid changing that property, can skip UI that would normally appear.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% DESCRIPTION
	% Binary: 1 = display GUI if font size is blank. 0 = no GUI displayed, font size changing is skipped.
	options.fontSizeGui = 0;
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
            if strcmp(FontSize,'none')
                
            else
                set(findall(gcf,'-property','FontName'),'FontName',FontSize);
            end
		else
			options.FontSize = FontSize;
			if options.fontSizeGui==0&isempty(options.FontSize)
			else
				if isempty(options.FontSize)
					userInput = inputdlg('New font');
					userInput = str2num(userInput{1});
				else
					userInput = options.FontSize;
				end
				set(findall(gcf,'-property','FontSize'),'FontSize',userInput);
			end
        end
        if ~isempty(options.fontColor)
            try
                tmpList = findall(gcf,'-property','FontSize');
                rmIdx = zeros([1 length(tmpList)]);
				lgdIdx = zeros([1 length(tmpList)]);
                for i = 1:length(tmpList)
                    if any(strcmp(class(tmpList(i)),{'matlab.graphics.axis.Axes','matlab.ui.control.UIControl'}))
                        rmIdx(i) = 1;
					end
					if any(strcmp(class(tmpList(i)),{'matlab.graphics.illustration.Legend'}))
                        lgdIdx(i) = 1;
					end
				end
				% Change text colors
                tmpList2 = tmpList(~rmIdx);
                set(tmpList2,'Color',options.fontColor);

				% Change legend colors
                tmpListLgd = tmpList(logical(lgdIdx));
                set(tmpListLgd,'TextColor',options.fontColor);
                %set(tmpListLgd,'Box','off');

                %tmpList2 = tmpList(~rmIdx);
                %set(tmpList2,'TextColor',options.fontColor);
                % set(findall(gcf,'-property','FontSize'),'Color',options.fontColor);
                set(findall(gcf,'-property','YColor'),'YColor',options.fontColor);
                set(findall(gcf,'-property','XColor'),'XColor',options.fontColor);
            catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))

            end
        end
        if ~isempty(options.fontName)
            set(findall(gcf,'-property','FontName'),'FontName',options.fontName);
        end
		success = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end