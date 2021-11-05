function [exitSignal, ostruct] = playMovie(inputMovie, varargin)
	[exitSignal, ostruct] = ciapkg.view.playMovie(inputMovie,'passArgs', varargin);
end