function [success] = createMatchObjBtwnTrialsMaps(inputImages,matchStruct,varargin)
	% Creates obj maps that are color coded by the objects global ID across imaging sessions to check quality of cross-session alignment.
	% Biafra Ahanonu
	% started: 2020.04.08 [11:36:38]
	% inputs
		% inputImages - cell array of [x y nFilters] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}, that should ALREADY be properly translated.
		% matchStruct - output structure from matchObjBtwnTrials.
	% outputs
		%

	[success] = ciapkg.classification.createMatchObjBtwnTrialsMaps(inputImages,matchStruct,'passArgs', varargin);
end