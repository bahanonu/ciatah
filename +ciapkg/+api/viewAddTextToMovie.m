function [movieTmp] = viewAddTextToMovie(movieTmp,inputText,fontSize,varargin)
	% Adds text to movie matrix.
	% Biafra Ahanonu
	% inputs
		% inputSignal - input signal (or matrix)
	% outputs
		%

	[movieTmp] = ciapkg.video.viewAddTextToMovie(movieTmp,inputText,fontSize,'passArgs', varargin);
end