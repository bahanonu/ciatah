function caxisChange(inputLimits,varargin)
	% caxis wrapper to also change colorbar range to be correct automatically.
	% Biafra Ahanonu
	% started: 2019.10.08 [19:15:59]
	% inputs
		% inputLimits - [lowerLimit upperLimit] vector
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% DESCRIPTION
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		caxis(inputLimits);
		ax = gca;
		ax.Colorbar.Ticks = inputLimits;
		ax.Colorbar.TickLabels = cellfun(@num2str,num2cell(inputLimits),'UniformOutput',false);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end