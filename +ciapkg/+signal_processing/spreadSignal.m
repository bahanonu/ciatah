function [inputSignalspread] = spreadSignal(inputSignal,varargin)
	% Spreads a signal out over several points in a vector, akin to smoothing except signal is kept absolute, e.g. [0 0 1 0 0] to [0 1 1 1 0].
	% Biafra Ahanonu
	% started: 2014.01.26 [15:48:34]
	% inputs
		% inputSignal
	% outputs
		% inputSignalspread

	% changelog
		% 2014.05.09 - remove signals outside the matrix range, e.g. if you have a spike at the very end of the signal.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% # of frames forward/back to look at
	options.timeSeq = [-2:2];
	% value to look for in the input signal
	options.alignSignal = 1;
	% make a fresh copy to avoid problems with pre-stimulus
	options.cleanCopy = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	timeSeq = options.timeSeq;
	% we transpose the matrix to get the correct idx, since matlab does column indexing and we want row indexing
	% inputSignal = inputSignal(:);
	signalIdx = find(inputSignal'==options.alignSignal);
	signalIdxSpread = bsxfun(@plus,timeSeq',signalIdx');
	if options.cleanCopy==0
		inputSignalspread = inputSignal';
	elseif options.cleanCopy==1
		inputSignalspread = zeros([size(inputSignal')]);
	end

	% remove signals outside the matrix range
	% signalIdxSpread
	signalIdxSpread(signalIdxSpread<1) = [];
	nPts = size(inputSignalspread,2);
	nSignals = size(inputSignalspread,1);
	signalIdxSpread(signalIdxSpread>(nPts*nSignals)) = [];
	% signalIdxSpread

	inputSignalspread(signalIdxSpread)=options.alignSignal;
	inputSignalspread = inputSignalspread';
end