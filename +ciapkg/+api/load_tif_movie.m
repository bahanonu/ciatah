function [out] = load_tif_movie(filename,downsample_xy,varargin)
	% Loads filename movie, downsamples in space by factor downsample_xy.
	% Biafra Ahanonu
	% parts adapted from
		% Jerome Lecoq for SpikeE
		% http://www.mathworks.com/matlabcentral/answers/108021-matlab-only-opens-first-frame-of-multi-page-tiff-stack
	% updating: 2013.10.22
	% inputs
		%
	% outputs
		%

	[out] = ciapkg.io.load_tif_movie(filename,downsample_xy,'passArgs', varargin);
end