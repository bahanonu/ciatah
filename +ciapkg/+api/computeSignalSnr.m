function [inputSnr, inputMse, inputSnrSignal, inputSnrNoise, outputSignal, outputNoise] = computeSignalSnr(inputSignals,varargin)
	% Obtains an approximate SNR for an input signal
	% Biafra Ahanonu
	% started: 2013.11.04 [11:54:09]
	% inputs
		% inputSignals: [nSignals frame] matrix
	% outputs
		% inputSnr: [1 nSignals] vector of calculated SNR. NaN used where SNR is not calculated.
		% inputMse: [1 nSignals] vector of MSE. NaN used where MSE is not calculated.
	% options
		% % type of SNR to calculate
		% options.SNRtype = 'mean(signal)/std(noise)';
		% % frames around which to remove the signal for noise estimation
		% options.timeSeq = [-10:10];
		% % show the waitbar
		% options.waitbarOn = 1;
		% % save time if already computed peaks
		% options.testpeaks = [];
		% options.testpeaksArray = [];

	[inputSnr, inputMse, inputSnrSignal, inputSnrNoise, outputSignal, outputNoise] = ciapkg.signal_processing.computeSignalSnr(inputSignals,'passArgs', varargin);
end