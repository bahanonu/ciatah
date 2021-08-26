%% Example 4: Visualize trial-averaged neural trajectories of maze data
% The dataset corresponds to Section 3.3 in the DataHigh JNE paper. It
% provides many conditions (27) than the center-to-out reach task.
% For the maze task, the monkey had to make arm movements 
% around barriers to obtain the target.  
% These neural trajectories represent trial-averaged, single-electrode 
% recordings, concatenated together to form a population.  More 
% information about the data can be found in (Churchland et al., 2012).
%
%  Detailed instructions can be found in the User Guide and the website.

cd ..
load('./data/ex3_trialavgtrajs.mat');
DataHigh(D);
% D(icond).data : (num_latents x num_timebins)
cd ./examples