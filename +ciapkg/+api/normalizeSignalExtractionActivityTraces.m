function inputSignals = normalizeSignalExtractionActivityTraces(inputSignals,inputImages, varargin)
	% [inputSignals] = ciapkg.signal_extraction.normalizeSignalExtractionActivityTraces(inputSignals,inputImages,'passArgs', varargin);
	% 
	% Normalizes cell activity traces by the max value in the associated image, normally to produce dF/F equivalent activity traces
	%
	% started: 2019.08.25 [18:19:34]
	% Biafra Ahanonu
	% Branched from normalizeCELLMaxTraces (Lacey Kitch and Biafra Ahanonu)
	% inputs
		% inputImages - [N x y] matrix where N = number of images, x/y are dimensions. Use permute(inputImages,[3 1 2]) if you use [x y N] for matrix indexing.
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames.
	% outputs
		% inputSignals - [N time] matrix where N = number of signals (traces) and time = frames. These are the modified signals

	[inputSignals] = ciapkg.signal_extraction.normalizeSignalExtractionActivityTraces(inputSignals,inputImages,'passArgs', varargin);
end