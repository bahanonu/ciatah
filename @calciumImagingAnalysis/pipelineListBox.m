function [idNumIdxArray, ok] = pipelineListBox(obj,fxnsToRun,inputTxt,currentIdx)
	% Main GUI for calciumImagingAnalysis startup
	% Biafra Ahanonu
	% started: 2019.12.22 [09:01:38]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% Part of this function is based on http://undocumentedmatlab.com/articles/setting-listbox-mouse-actions/.

	try
		ok = 0;
		tooltipStruct = obj.tts;

		hFig = figure;
		uicontrol('Style','Text','String',[inputTxt 10 'Press ENTER to continue, ESC to exit.'],'Units','normalized','Position',[5 90 90 10]/100,'BackgroundColor','white','HorizontalAlignment','Left');

		% currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));

		hListbox = uicontrol(hFig, 'style','listbox','Units', 'normalized','position',[5,5,90,85]/100, 'string',fxnsToRun,'Value',currentIdx,'Tag','methodBox');

		set(hListbox,'Max',2,'Min',0);
		% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))
		set(hListbox,'KeyReleaseFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))

		% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(evnt,'press',hFig))
		% Get the listbox's underlying Java control
		jScrollPane = findjobj(hListbox);
		% We got the scrollpane container - get its actual contained listbox control
		jListbox = jScrollPane.getViewport.getComponent(0);
		% Convert to a callback-able reference handle
		jListbox = handle(jListbox, 'CallbackProperties');
		% set(hListbox, 'TooltipString','sss');
		% Set the mouse-movement event callback
		set(jListbox, 'MouseMovedCallback', {@mouseMovedCallback,hListbox,tooltipStruct});

		figure(hFig)
		uicontrol(hListbox)
		set(hFig, 'KeyPressFcn', @(source,eventdata) figure(hFig));
		hListboxStruct = [];
		uiwait(hFig)
		commandwindow
		% disp(hListboxStruct)
		% fxnsToRun{hListboxStruct.Value}
		if isempty(hListboxStruct)
			uiwait(msgbox('Please re-select a module then press enter. Do not close figure manually.'))
			idNumIdxArray = 1;
			ok = 0;
		else
			idNumIdxArray = hListboxStruct.Value;
			ok = 1;
		end
	catch err
		ok = 0;
		idNumIdxArray = 1;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	function onMousePress(evnt,pressRelease,hFig)
		%
	end
	function onKeyPressRelease(src, evnt, pressRelease,hFig)
		% disp(evnt)
		% disp(pressRelease)
		if strcmp(evnt.Key,'return')
			hListboxStruct.Value = hListbox.Value;
			% hListboxStruct = struct(hListbox);
			close(hFig)
		else
			% disp('Check')
		end
		% If escape, close.
		if strcmp(evnt.Key,'escape')
			hListboxStruct = [];
			close(hFig)
		end
	end
	function mouseMovedCallback(jListbox, jEventData, hListbox,tooltipStruct)
		% Get the currently-hovered list-item
		mousePos = java.awt.Point(jEventData.getX, jEventData.getY);
		hoverIndex = jListbox.locationToIndex(mousePos) + 1;
		listValues = get(hListbox,'string');
		hoverValue = listValues{hoverIndex};

		% Replace odd values for the section dividers.
		hoverValue = regexprep(hoverValue,'------- | -------','');
		hoverValue = regexprep(hoverValue,':|/| |','_');

		% Modify the tooltip based on the hovered item
		if any(strcmp(fieldnames(tooltipStruct),hoverValue))
			msgStr = sprintf('<html><b>%s</b>: <br>%s</html>', hoverValue, tooltipStruct.(hoverValue));
		else
			% msgStr = sprintf('<html><b>%s</b>: %s</html>', hoverValue, hoverValue);
			msgStr = sprintf('<html><b>No tooltip.</b></html>', hoverValue, hoverValue);
		end
		set(hListbox, 'TooltipString',msgStr);
	end
end