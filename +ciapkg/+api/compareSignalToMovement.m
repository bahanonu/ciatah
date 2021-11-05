function [outputData] = compareSignalToMovement(inputSignals,inputMovement,varargin)
	% Compares a set of input signals to a movement vector.
	% Biafra Ahanonu
	% started: 2013.10.30 [12:45:53]
	% inputs
		% inputSignals
		% inputMovement - a table containing XM, YM, Angle, Slice, and velocity.
	% outputs
		% outputData

	[outputData] = ciapkg.tracking.compareSignalToMovement(inputSignals,inputMovement,'passArgs', varargin);
end