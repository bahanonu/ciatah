function viewHotKeyAcc(figNo)
	% Allows hotkeys to be added to the current figure for manipulation
	% Biafra Ahanonu
	% started: 2017.04.12
	% inputs
	    %
	% outputs
	    %
	% changelog
	    %
	% TODO
	    % add options for how much to offset

	% allows hotkeys to be added to the current figure for manipulation
	% A figure
	% fig = figure('menubar','none');
	fig = figure(figNo);
	% Add menus with Accelerators
	mymenu = uimenu('Parent',fig,'Label','Hot Keys');
	uimenu('Parent',mymenu,'Label','Data Cursor','Accelerator','d','Callback',@(src,evt)datacursormode(fig,'on'));
	uimenu('Parent',mymenu,'Label','Zoom','Accelerator','f','Callback',@(src,evt)zoom(fig,'on'));
	uimenu('Parent',mymenu,'Label','Pan','Accelerator','g','Callback',@(src,evt)pan(fig,'on'));
	% Some plot
	%plot(rand(1,50))
end