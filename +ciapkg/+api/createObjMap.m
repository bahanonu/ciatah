function [cellmap] = createObjMap(inputImages,varargin)
	% Creates a cellmap from a ZxXxY input matrix of input images.
	% Biafra Ahanonu
	% started: 2013.10.12
	% inputs
		%
	% outputs
		%

	[cellmap] = ciapkg.image.createObjMap(inputImages,'passArgs', varargin);
end