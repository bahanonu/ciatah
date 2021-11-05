function [OutStruct] = matchObjBtwnTrials(inputImages,varargin)
	% Registers images to a set imaging session then matches objs between sessions to one another and outputs the alignment indicies for a single global cell across sessions. All images cropped to the minimum x,y dimension among all the input imaging session datasets.
	% Biafra Ahanonu
	% started: 2013.10.31
	% inputs
		% inputImages - cell array of [x y nFilters] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}
	% options
		% inputSignals - cell array of [nFilters frames] matrices containing each set of filter traces
	% outputs
		% OutStruct - structure containing
		% .globalIDs, [M N] matrix with M = number of global IDs and N = each session. Each m,n pair specifies the index of that global obj m in the data of session n. If .globalIDs(m,n)==0, means no match was found.
		% .trialIDs, a cell array that matches each column n in the matrix to a particular id, either automatic or input a cell array of strings specifying what each session is.
		% .coords, a [M C] matrix with M = number of global ID and C = 2 (1st column is x, 2nd column is y coordinates),

	[OutStruct] = ciapkg.classification.matchObjBtwnTrials(inputImages,'passArgs', varargin);
end