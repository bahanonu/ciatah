function viewColorLinePlot(v1,v2,varargin)
	% Creates a line plot that changes color over the range of the line, e.g. for open-field tracking visualization.
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
	options.colors = [];
	options.v3 = [];
	options.colorbar = 0;
	options.lineWidth = 0.5;
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
		v3 = options.v3;
		% colors=hot(60);
		if isempty(options.colors)
			colors = customColormap({[0 0 1],[1 1 1],[1 0 0]},'nPoints',options.nPoints);
		else
			colors = options.colors;
		end
		colour_sections=size(colors,1);
		bin_size=length(v1)/colour_sections; %Determines the step size for each colour
		bin_size
		if isempty(v3)==1
		    for i=1:colour_sections
		    	% x = v1(1:ceil(bin_size*i));
		    	% y = v2(1:ceil(bin_size*i));
	            % xflip = [x(1 : end - 1) fliplr(x)];
	            % yflip = [y(1 : end - 1) fliplr(y)];
		        if i==1
		            xx=plot(v1(1:ceil(bin_size*i)),v2(1:ceil(bin_size*i)));
		            % patch(xflip, yflip, colors(i,:), 'EdgeAlpha', 0.9, 'FaceColor', 'none');
		        else
		            xx=plot(v1(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v2(ceil(bin_size*i-bin_size):ceil(bin_size*i)));
		            % patch(xflip, yflip, colors(i,:), 'EdgeAlpha', 0.9, 'FaceColor', 'none');
		        end
		        set(xx,'Color',colors(i,:),'LineWidth',options.lineWidth);
		        if i==1
		            hold on
		        end
		    end
		end
		if isempty(v3)==0
		    for i=1:colour_sections
		    if i==1
		        xx=plot3(v1(1:ceil(bin_size*i)),v2(1:ceil(bin_size*i)),v1(1:ceil(bin_size*i)));
		    else
		        xx=plot3(v1(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v2(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v3(ceil(bin_size*i-bin_size):ceil(bin_size*i)));
		    end
		    set(xx,'Color',colors(i,:),'LineWidth',options.lineWidth);
		    if i==1
		        hold on
		    end
		    end
		end
		if options.colorbar==1
		    % set colormap to use for colorbar
		    colormap(colors);
		    colorbar;
		else

		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end