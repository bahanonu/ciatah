function [acceleration, outputStruct] = computeAccelerometerOutput(x,y,z,varargin)
	% Takes xyz accelerometer input and process total acceleration.
	% Biafra Ahanonu
	% started: 2018.04.17 [16:26:03]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	[acceleration, outputStruct] = ciapkg.behavior.computeAccelerometerOutput(x,y,z,'passArgs', varargin);
end