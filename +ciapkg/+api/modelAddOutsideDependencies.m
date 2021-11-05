function [success] = modelAddOutsideDependencies(dependencyName,varargin)
	% Used to request certain outside dependencies from users.
	% Biafra Ahanonu
	% started: 2017.11.16 [16:50:28]
	% inputs
		%
	% outputs
		%

	[success] = ciapkg.io.modelAddOutsideDependencies(dependencyName,'passArgs', varargin);
end