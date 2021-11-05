function [inputSignalShuffled] = shuffleMatrix(inputSignal,varargin)
	% Shuffles matrix in 1st dimension.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% thanks to Scott Teuscher for the super useful vectorized circshift (http://www.mathworks.com/matlabcentral/fileexchange/41051-vectorized-circshift)
	% inputs
		% inputSignal - input signal (or matrix)
	% outputs
		%


	[inputSignalShuffled] = ciapkg.signal_processing.shuffleMatrix(inputSignal,'passArgs', varargin);
end