%% Example 3:  Extract trial-averaged neural trajectories from PSTHs
%  Perform dimensionality reduction with DimReduce and automatically
%  visualize data in DataHigh.  The data has 56 trials for two reach
%  directions. Data is from (Yu et al., 2009).
%
%  Please see User Guide and online videos for detailed instructions.
%
%  Quick start:
%  1. 20ms bin width
%     1.0 spikes/s  threshold
%     (unchecked) trial-averaged neural trajs (PSTHs have already been
%     taken)
%  2. Method: PCA
%  3. Choose a smoothing kernel width of 25ms.
%  4. Select dimensionality of 61.  Click 'Perform dim reduction.'
%  5. When the PostDimReduce figure pops up, select a dimensionality 8.
%  6. Click 'Upload to DataHigh.'
%  7. See ex3_visualize.m to visualize trial-averaged
%     neural trajectories with DataHigh.
%


cd ..
load('./data/ex3_psths.mat');
% D(icond).data : (num_neurons x num_1ms_timepoints)
DataHigh(D, 'DimReduce');
cd ./examples