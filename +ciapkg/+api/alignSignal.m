function [alignedSignal] = alignSignal(responseSignal, alignmentSignal,timeSeq,varargin)
	% Aligns values in a response signal (can be multiple response signals) to binary points in an alignment signal (e.g. 1=align to this time-point, 0=don't align).
	% Biafra Ahanonu
	% started: 2013.11.13 [23:47:34]
	% inputs
		% responseSignal = MxN matrix of M signals over N points
		% alignmentSignal = a 1xN vector of 0s and 1s, where 1s will be alignment points
		% timeSeq = 1xN sequence giving time around alignments points to process, e.g. -2:2.
	% options
		% overallAlign = align all response signals to alignmentSignal pts
	% outputs
		% alignedSignal = a matrix of size 1xlength(timeSeq) if sum all signals or Mxlength(timeSeq) if keep the sums for each signal separate

	[alignedSignal] = ciapkg.signal_processing.alignSignal(responseSignal, alignmentSignal,timeSeq,'passArgs', varargin);
end