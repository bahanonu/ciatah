function [inputMovie] = detrendMovie(inputMovie,varargin)
	% Detrend a movie to account for photobleaching, etc. Alias for call to normalizeMovie.
	% Biafra Ahanonu
	% started: 2021.09.16 [21:48:56]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% ========================
	% Int: 1 = linear detrend, >1 = nth-degree polynomial detrend
	option.detrendDegree = 1;
	% Int: maximum frame to normalize.
	options.maxFrame = size(inputMovie,3);
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		inputMovie = ciapkg.movie_processing.normalizeMovie(inputMovie,...
			'normalizationType','detrend',...
			'detrendDegree',option.detrendDegree,...
			'maxFrame',options.maxFrame);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end