function [inputMovie] = createImageOutlineOnMovie(inputMovie,inputImages,varargin)
	% Gets outlines of cell extraction source outputs and overlays them onto a movie.
	% Biafra Ahanonu
	% started: 2018.02.15 [10:00:12]
	% inputs
		% inputMovie - [X Y Z] matrix of X,Y height/width and Z frames
		% inputImages - [x y nFilters] matrix
	% outputs
		% inputMovie - input movie with cell outline added

	[inputMovie] = ciapkg.video.createImageOutlineOnMovie(inputMovie,inputImages,'passArgs', varargin);
end