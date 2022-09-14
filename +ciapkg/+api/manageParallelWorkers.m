function [success] = manageParallelWorkers(varargin)
	% Manages loading and stopping parallel processing workers.
	% Biafra Ahanonu
	% started: 2015.12.01
	
	% changelog
		% 2022.02.28 [18:36:15] - Added ability to input just the number of workers to open as 1st single input argument that aliases for the "setNumCores" Name-Value input, still support other input arguments as well.
		
	if length(varargin)==1
		[success] = ciapkg.io.manageParallelWorkers(varargin{1});
	else
		[success] = ciapkg.io.manageParallelWorkers('passArgs', varargin);
	end
end