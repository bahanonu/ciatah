function [success] = saveNwbMovie(inputData,fileSavePath,varargin)
	% Saves input matrix into NWB format output file.
	% Biafra Ahanonu
	% started: 2020.05.28 [09:51:52]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		% Add structure that allows users to modify defaults for all the NWB settings

	[success] = ciapkg.nwb.saveNwbMovie(inputData,fileSavePath,'passArgs', varargin);
end