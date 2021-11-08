function [success] = setupNwb(varargin)
	% Checks that NWB code is present and setup correctly.
	% Biafra Ahanonu
	% started: 2021.01.24 [14:31:24]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.03.26 [06:27:48] - Fix for options.defaultObjDir leading to incorrect NWB folder and cores not being generated.
	% TODO
		%

	[success] = ciapkg.nwb.setupNwb('passArgs', varargin);
end
