function [inputSignalShuffled] = shuffleMatrix(inputSignal,varargin)
	% Shuffles matrix in 1st dimension.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% thanks to Scott Teuscher for the super useful vectorized circshift (http://www.mathworks.com/matlabcentral/fileexchange/41051-vectorized-circshift)
	% inputs
		% inputSignal - input signal (or matrix)
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% number of resampling from shifted MI
	options.nSamples = 1;
	%
	options.waitbarOn = 1;

	%
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
		nPoints = size(inputSignal,2);
		nSignals = size(inputSignal,1);
		reverseStr = '';
		inputSignalShuffled = zeros(size(inputSignal));
		% nResponses = 10;
		nLoopSignalPts = size(inputSignal,2);
		for responseNo=1:nSignals
			% loopSignal = inputSignal(responseNo,:);
			% vectCircShift(loopSignal,randsample(length(nSignals),options.nSamples,true))
			% nLoopSignalPts = length(inputSignal(responseNo,:));
			shiftBy = randsample(nLoopSignalPts,options.nSamples,true);
			inputSignalShuffled(responseNo,:) = circshift(inputSignal(responseNo,:),shiftBy,2);
			% signalPtVector = 1:nLoopSignalPts;
			% signalPtVector = signalPtVector + shiftBy;
			% signalPtVector(signalPtVector>nLoopSignalPts) = 1:shiftBy;
			% inputSignalShuffled(responseNo,:) = inputSignal(responseNo,signalPtVector);
			% signalPtVector
			% inputSignalShuffled(responseNo,:) = vectCircShift(loopSignal,randsample(length(loopSignal),options.nSamples,true));

			% reverseStr = cmdWaitbar(responseNo,nSignals,reverseStr,'inputStr','shuffling matrix','waitbarOn',options.waitbarOn,'displayEvery',5);
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end