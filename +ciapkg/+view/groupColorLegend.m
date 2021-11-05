function [legendHandle] = groupColorLegend(typeArray,colorMatrix,varargin)
	% Correctly plots multi-colored legend entries.
	% Biafra Ahanonu
	% 2014.01.23 [10:41:07]
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
	options.exampleOption = 'doSomething';
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
    	warning off
		for i=1:length(typeArray)
		    plot(0,0,'Color',colorMatrix(i,:),'Marker','.','LineStyle','none');
		    hold on
		end
    	warning on
		legendHandle = legend(typeArray);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end