function [success] = runCvxSetup(varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: INSERT_DATE
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
	% TODO
		%

	[success] = ciapkg.signal_extraction.runCvxSetup('passArgs', varargin);
end