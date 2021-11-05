function [inputMovie, ResultsOutOriginal] = turboregMovie(inputMovie, varargin)
	% Motion corrects (using turboreg) a movie. 
		% - Both turboreg (to get 2D translation coordinates) and registering images (transfturboreg, imwarp, imtransform) have been parallelized. 
		% - Can also turboreg to one set of images and apply the registration to another set (e.g. for cross-day alignment). 
		% - Spatial filtering is applied after obtaining registration coordinates but before transformation, this reduced chance that 0s or NaNs at edge after transformation mess with proper spatial filtering.
	% Biafra Ahanonu
	% started 2013.11.09 [11:04:18]
	% modified from code created by Jerome Lecoq in 2011 and parallel code update by biafra ahanonu

	[inputMovie, ResultsOutOriginal] = ciapkg.motion_correction.turboregMovie(inputMovie,'passArgs', varargin);
end