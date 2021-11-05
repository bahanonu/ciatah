function [cnmfAnalysisOutput] = computeCnmfSignalExtractionOriginal(inputMovie,numExpectedComponents,varargin)
	% Wrapper for CNMF, for use with https://github.com/epnev/ca_source_extraction/commit/8799b13df2b09f30e27fc852e4f5f39ae6f44405
	% Building off of demo_script.m in CNMF github repo
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

	[cnmfAnalysisOutput] = ciapkg.signal_extraction.computeCnmfSignalExtractionOriginal(inputMovie,numExpectedComponents,'passArgs', varargin);
end