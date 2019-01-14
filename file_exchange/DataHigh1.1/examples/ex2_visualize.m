%% Example 3: Single-trial neural trajectories
% The dataset corresponds to Section 3.2 in the DataHigh JNE paper.  
% The data includes two conditions with 15 trials each.  The space 
% was reduced from 61 neurons to 15 latent dimensions with 
% Gaussian-process factor analysis (GPFA) (Yu et al., 2009).
%
%  Detailed instructions can be found in the User Guide and the website.

cd ..
load('./data/ex2_singletrialtrajs.mat');
DataHigh(D);
% D(itrial).data : (num_latents x num_20ms_timebins)
cd ./examples