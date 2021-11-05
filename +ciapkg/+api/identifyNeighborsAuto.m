function neighborsCell = identifyNeighborsAuto(inputImages, inputSignals, varargin)
	% This code automatically sorts through to find all obj neighbors within a certain distance of the target (boundary to boundary). The output is a cell array with vectors of the neighbor indices to each obj.
	% Biafra Ahanonu
	% started: 2013.11.01
	% based on code by laurie burns, started: sept 2010.
	% inputs
		% inputImages - [x y nCells] matrices containing each set of filters
		% inputSignals - [nFilters frames] matrices containing each set of filter traces
	% options
		% _
	% outputs
		% _

	[neighborsCell] = ciapkg.neighbor.identifyNeighborsAuto(inputImages, inputSignals,'passArgs', varargin);
end