%% Example 1: Visualize neural states with DataHigh
%  The dataset corresponds to Section 3.1 in the DataHigh JNE paper. 
%  Each datapoint represents a trial.  Trials are separated into seven 
%  different reach directions (colors).  The space was reduced 
%  from 61 neurons to 7 latent dimensions with factor analysis (see 
%  ex1_dimreduce.m).  
%  More information about the data can be found in (Yu et al., 2009).
%
%  Detailed instructions can be found in the User Guide and the website.

cd ..
load('./data/ex1_neuralstates.mat');
%  D(itrial).data (num_latents x num_trials_in_cond)
DataHigh(D);
cd ./examples