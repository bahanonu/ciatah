function viewNeighborsAuto(inputImages, inputSignals, neighborsCell, varargin)
	% View the neighboring cells, their traces and trace correlations.
	% Biafra Ahanonu
	% started 2013.11.01
	% inputs
		% inputImages - [x y nCells] matrices containing each set of filters
		% inputSignals - [nFilters frames] matrices containing each set of filter traces
		% neighborsCell - {nCells 1} cell array of [nNeighborId 1] vectors of neighbor IDs for each cell matching indices in inputImages
	% outputs
		%

	ciapkg.neighbor.viewNeighborsAuto(inputImages, inputSignals, neighborsCell,'passArgs', varargin);
end