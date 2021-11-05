function [output] = viewTableOnFigure(inputTable,varargin)
	% Adds a table to a figure.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.newFig = 1;
	% handle to previous table
	options.tableHandle = [];
	% row, column, value
	options.updateTable = {};
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
		output = 1;
		if ~isempty(options.tableHandle)
			% set(t,'Data',data);
			t = options.tableHandle;

			% t.Data{[options.updateTable{1}],[options.updateTable{2}]} = {options.updateTable{3}};
			t.Data([options.updateTable{1}],[options.updateTable{2}]) = options.updateTable{3};

			% jscroll = findjobj(t);
			% jtable = jscroll.getViewport.getComponent(0);
			% jtable.setValueAt(java.lang.String(options.updateTable{3}),options.updateTable{1},options.updateTable{2}); % to insert this value in cell (1,1)

			output = t;
		else
			% uitable('Data',T{:,:},'ColumnName',T.Properties.VariableNames,...
			    % 'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1]);

			if options.newFig==1
		    	f = figure;
		    	% pause(0.05)
		    	pause(2)
		    else
		    	clf
		    	f = gcf;
		    end
	        fp = get(f, 'Position');
		    t = uitable(f);
		    output = t;
		    % for i = 1:size(T,1)
		    % 	for j = 1:size(T,2)
		    % 			T(i,j) = {num2str(T{i,j})};
		    % 		try
			   %  	catch
			   %  	end
		    % 	end
		    % end
		    % class(T{1,1})
		    T2 = table2cell(inputTable);
		    t.Data = T2;
		    t.RowName = inputTable.Properties.RowNames;
		    t.ColumnName = inputTable.Properties.VariableNames;
		    % Figure-Size
		    t.Position = [0 0 fp(3:4)];
		    % t.Data = char(T{:,:});
		    % set(f, 'ResizeFcn', {@resizeCallback, gcf, t, T2});


			% % Get the table in string form.
			% TString = evalc('disp(T)');
			% % Use TeX Markup for bold formatting and underscores.
			% TString = strrep(TString,'<strong>','\bf');
			% TString = strrep(TString,'</strong>','\rm');
			% TString = strrep(TString,'_','\_');
			% % Get a fixed-width font.
			% FixedWidth = get(0,'FixedWidthFontName');
			% % Output the table using the annotation command.
			% annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
			%     'FontName',FixedWidth,'FontSize',7,'Units','Normalized','Position',[0 0 1 1]);
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
% function resizeCallback(hFig, ~, hAx, t, T2)
% 	pause(0.05)
%     fp = get(hFig, 'Position');
%     t.Position = [0 0 fp(3:4)];
% 	    t.Data = T2;
% end