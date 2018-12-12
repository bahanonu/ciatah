function [output] = viewLineFilledError(inputMean,inputStd,varargin)
	% Makes solid error bars around line.
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
	options.xValues = [];
	%
	% options.lineColor = repmat(0.85,[1 3]);
	options.lineColor = [0.5 0 0];
	options.errorColor = repmat(0.85,[1 3]);
	options.linewidth = 5;
	options.errorAlpha = 0.5;
	% number of std dev. to plot
	options.sigmaNum = 1.96;
	% std, sem
	options.errorType = 'std';

	options.ncount = [];
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
		if isempty(options.xValues)
			x = 1:length(inputMean);
		else
			x = options.xValues;
		end
    	y = inputMean;
    	dy = options.sigmaNum*inputStd;
    	if strcmp(options.errorType,'sem')&~isempty(options.ncount)
    		dy = dy/sqrt(options.ncount);
    	end
    	colorMatrix = hsv(10);
    	colorMatrix = repmat(options.lineColor,[2 1]);
    	colorMatrixError = repmat(options.errorColor,[2 1]);
    	randColor = randsample(10,1,false);
    	randColor = 1;
    	h = fill([x(:);flipud(x(:))],[y(:)-dy(:);flipud(y(:)+dy(:))],colorMatrixError(randColor,:),'linestyle','none');
    	% set(h,'facealpha',options.errorAlpha)
    	lh = line(x,y,'Color',colorMatrix(randColor,:)/1.5,'LineWidth',options.linewidth);
    	% lh.Color
    	output = 1;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end