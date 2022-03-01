function [figHandle, figAdd] = openFigure(figNo, figSize,varargin)
	% OPENFIGURE(figNo, figSize,varargin)
	% 
	% Opens a figure, if default not set to docked, opens figure on the left half of the screen. If figure is already created, focuses MATLAB on the figure without changing user focus (e.g. background plotting).
	% 
	% Biafra Ahanonu
	% started: 2013.10.29
	% 
	% inputs
	%   figNo - int: number of figure.
	%   figSize - int vector: size of figure.
	% 
	% outputs
	%	figHandle - handle to created figure.
	% 	figAdd - int: increment of current figure number for sequential plotting.

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.02.28 [10:55:20] - Option to add a title to the figure, e.g. "Figure 1" becomes "Fig. 1 - Lorem ipsum". Also make user accessible change figure background color.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Int: increment the figure number input by this amount for the output only.
	options.add = 1;
	% Str: title for figure, e.g. "Figure 1" becomes "Fig. 1 - Lorem ipsum". Leave empty to ignore.
	options.figTitle = '';
	% Str: separator to use for figure title.
	options.figTitleSep = '';
	% Str: default figure background color. Leave empty to ignore.
	options.defaultColor = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%   eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		figHandle = 1;
		figAdd = 1;

		if ishandle(figNo)
			set(0,'CurrentFigure',figNo)
			figHandle = figNo;
		else
			figHandle = figure(figNo);
		end

		% When making plots, have them be sequential
		figAdd = figNo+options.add;

		% Set the default color to white
		if ~isempty(options.defaultColor)
			set(gcf,'color',options.defaultColor);
		end

		if ~strcmp(get(0,'DefaultFigureWindowStyle'),'docked')
			scnsize = get(0,'ScreenSize');
			position = get(figHandle,'Position');
			outerpos = get(figHandle,'OuterPosition');
			borders = outerpos - position;
			edge = -borders(1)/2;
			if strcmp(figSize,'full')
				pos1 = [0, 0, scnsize(3), scnsize(4)];
			else
				pos1 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)];
			end
			set(figHandle,'OuterPosition',pos1);
		end

		if ~isempty(options.figTitle)
			set(figHandle,'Name',['Fig. ' num2str(figNo) ' | ' options.figTitle],'NumberTitle','off')
		end
	catch err
		figHandle = [];
		figAdd = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end