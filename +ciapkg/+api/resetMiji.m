function [success] = resetMiji(varargin)
	% This clears Miji from Java's dynamic path and then re-initializes. Use if Miji is not loading normally.
	% Biafra Ahanonu
	% started: 2019.01.28 [14:34:14]
	% inputs
		%
	% outputs
		%
	% usage
		% % Run the following commands one at a time in the command window.
		% resetMiji
		% % An instance of Miji should appear.
		% currP=pwd;Miji;cd(currP);
		% MIJ.exit

	[success] = ciapkg.io.resetMiji('passArgs', varargin);
end