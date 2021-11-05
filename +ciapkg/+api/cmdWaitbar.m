function [reverseStr] = cmdWaitbar(i,nItems,reverseStr,varargin)
	% Puts a txt waitbar into the cmd window, less intrusive than pop-up waitbar.
	% Biafra Ahanonu
	% started: 2014.01.14
	% thanks to:
		% http://www.mathworks.com/matlabcentral/newsreader/view_thread/32291
		% http://stackoverflow.com/questions/11050205/text-progress-bar-in-matlab
	% inputs
			%
	% outputs
			%

	% changelog
			% 2014.02.14 [16:35:55] now is mostly
	% TODO
			% Should reverseStr be made global so function is entirely self-contained? - NO, globals are evil.
			% change so waitbarOn = 0 can short circuit getOptions to save speed execution time
	% example
		% before loop = reverseStr
		% reverseStr = cmdWaitbar(i,nItems,reverseStr,'inputStr','loading hdf5','waitbarOn',options.waitbarOn,'displayEvery',50);

	[reverseStr] = ciapkg.view.cmdWaitbar(i,nItems,reverseStr,'passArgs', varargin);
end