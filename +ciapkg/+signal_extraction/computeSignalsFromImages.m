function [outputSignal, inputImages] = computeSignalsFromImages(inputImages,inputMovie, varargin)
	% CIAtah package wrapper for applyImagesToMovie. 
	% Applies images to a 3D movie matrix in order to get a signal based on a thresholded version of the image.
	% Biafra Ahanonu
	% started: 2013.10.11 [2020.10.27 [12:56:27] for wrapper]
	% inputs
		% inputImages - [x y signalNo] of images, signals will be calculated for each image from the movie.
		% inputMovie - [x y frame] or char string path to the movie.
	% outputs
		% outputSignal - [signalNo frame] matrix of each signal's activity trace extracted directly from the movie.
		% inputImages - [x y signalNo], same as input.

	% changelog
		%
	% TODO
		%

	% ========================
	% DESCRIPTION
	% OPTIONS ARE THE SAME AS loadMovieList.
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		[outputSignal, inputImages] = applyImagesToMovie(inputImages,inputMovie, 'passArgs',varargin);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end