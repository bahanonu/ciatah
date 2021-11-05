function [cnmfAnalysisOutput] = computeCnmfSignalExtraction_v2(inputMovie,numExpectedComponents,varargin)
	% Brapper function for CNMF, update for most recent versions.
	% Building off of demo_script.m in CNMF github repo
	% Most recent commit tested on: https://github.com/epnev/ca_source_extraction/commit/187bbdbe66bca466b83b81861b5601891a95b8d1
	% https://github.com/epnev/ca_source_extraction/blob/master/demo_script_class.m
	% Biafra Ahanonu
	% started: 2016.01.20
	% inputs
		% inputMovie - a string or a cell array of strings pointing to the movies to be analyzed (recommended). Else, [x y t] matrix where t = frames.
		% numExpectedComponents - number of expected components
	% outputs
		% cnmfAnalysisOutput - structure containing extractedImages and extractedSignals along with input parameters to the algorithm
	% READ BEFORE RUNNING
		% Get CVX from http://cvxr.com/cvx/doc/install.html
		% Run the below commands in Matlab after unzipping
		% cvx_setup
		% cvx_save_prefs (permanently stores settings)

	[cnmfAnalysisOutput] = ciapkg.signal_extraction.computeCnmfSignalExtraction_v2(inputMovie,numExpectedComponents,'passArgs', varargin);
end