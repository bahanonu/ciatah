function inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages)
	% Normalizes cell activity traces by the max value in the associated image, normally to produce dF/F equivalent activity traces
	% started: 2019.08.25 [18:19:34]
	% Biafra Ahanonu
	% Branched from normalizeCELLMaxTraces (Lacey Kitch and Biafra Ahanonu)
	% inputs
		% inputImages - [N x y] matrix where N = number of images, x/y are dimensions. Use permute(inputImages,[3 1 2]) if you use [x y N] for matrix indexing.
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames.
	% outputs
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames. These are the modified signals

	% changelog
		%
	% TODO
		%

	%========================
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

	nCells = size(inputSignals,1);
	disp('Normalizing traces by cell image values.')
	for cellNo = 1:nCells
	    thisImage = inputImages(:,:,cellNo);
	    normFactor = max(thisImage(:));
	    inputSignals(cellNo,:) = inputSignals(cellNo,:)*normFactor;
	end
end