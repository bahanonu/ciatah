%% Example 1:  Extract Neural States from Raw Spike Trains using DimReduce
%  Perform dimensionality reduction with DimReduce and automatically
%  visualize data in DataHigh.  The data has raw spike trains from 61
%  neurons for 56 trials for seven reach directions. The bin size is 1ms,
%  and each trial is 400ms (taken in the delay period, 100ms after the
%  target onset).
%  Data is from (Yu et al., 2009), and corresponds to Example 1 in the
%  DataHigh JNE Paper.
%  Please see User Guide and online videos for detailed instructions.
%
%
%  Quick start:
%  1. 400ms bin width
%     1.0 spikes/s  threshold
%     (unchecked) trial-averaged neural trajs
%  2. Method: FA
%  3. Candidate dims: 1:20
%  4. Click the 'Perform cross-validation' button.
%  5. Look at metric plots from dimensionality reduction.
%  6. Select a dimensionality of 7.
%  7. Click 'Perform dim reduction.'  When the PostDimReduce 
%     figure pops up, click 'Upload to DataHigh'.
%  8. See ex1_visualize.m to visualize neural states with DataHigh.
%

cd ..
load('./data/ex1_spikecounts.mat');
% D(itrial).data : (num_neurons x 400ms)
% D(itrial).condition : 'reach1', 'reach2', ..., 'reach7'
DataHigh(D, 'DimReduce');
cd ./examples