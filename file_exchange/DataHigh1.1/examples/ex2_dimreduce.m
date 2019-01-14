%% Example 2:  Extract single-trial neural trajectories from Raw Spike Trains using DimReduce
%  Perform dimensionality reduction with DimReduce on raw spike trains 
%  and automatically visualize the extracted single-trial neural 
%  trajectories in DataHigh.  The data has 56 trials for two reach
%  directions. Data is from (Yu et al., 2009).
%  Please see User Guide and online videos for detailed instructions. 
%
%  Quick start (with GPFA trick):
%  1. 20ms bin width
%     1.0 spikes/s  threshold
%     (unchecked) trial-averaged neural trajs
%  2. Method: GPFA
%  3. Select a dimensionality of 40.
%  5. Click the 'Perform Dim Reduction' button (will take ~2min).
%  6. When the PostDimReduce figure pops up, select a dimensionality of 8.
%  7. Click 'Upload to DataHigh.'
%  8. See ex2_visualize.m to visualize the single-
%     trial neural trajectories with DataHigh.
%


cd ..
load('./data/ex2_rawspiketrains.mat');
% D(itrial).data : (num_neurons x num_1ms_bins)
DataHigh(D, 'DimReduce');
cd ./examples