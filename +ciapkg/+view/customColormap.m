function [outputColormap] = customColormap(colorList,varargin)
	% Creates a custom colormap.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.nPoints = 50;
	% whether to have discrete cutoffs
	options.discreteCutoff = 0;
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
		if nargin==0
			colorList = {[0 0 1], [1 1 1], [1 0 0]};
		end
		if (~iscell(colorList)&~isempty(colorList))
			colorList2 = {};
			for i = 1:size(colorList,1)
				colorList2{end+1} = colorList(i,:);
			end
			colorList = colorList2;
		end
		if isempty(colorList)
			% colorList = {[1 1 1], [0 0 1],[1 0 0]};
			colorList = {[0 0 1], [1 1 1], [1 0 0]};
			% [0 0 1],[1 1 1],[0.5 0 0],[1 0 0]
			% colorList = {[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]};
			% colorList = {[27 52 93]/256,[1 1 1],[106 41 50]/256};
			 % colorList = diverging_map(linspace(0,1,options.nPoints),[0 0 1],[1 0 0]);
			 % outputColormap = colorList;
             % return;
		end
		% else
		nColors = length(colorList);
		redMap = [];
		greenMap = [];
		blueMap = [];
		if options.discreteCutoff==0
			for i=1:(nColors-1)
				redMap = [redMap linspace(colorList{i}(1),colorList{i+1}(1),options.nPoints)];
				greenMap = [greenMap linspace(colorList{i}(2),colorList{i+1}(2),options.nPoints)];
				blueMap = [blueMap linspace(colorList{i}(3),colorList{i+1}(3),options.nPoints)];
			end
			outputColormap = [redMap', greenMap', blueMap'];
		else
			outputColormap = [];
			nColorPoints = diff(ceil(linspace(1,options.nPoints,nColors+1)));
			nColorPoints(end) = nColorPoints(end)+1;
			for i=1:nColors
				outputColormap = [outputColormap; repmat(colorList{i},[nColorPoints(i) 1])];
			end
		end
		% end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end