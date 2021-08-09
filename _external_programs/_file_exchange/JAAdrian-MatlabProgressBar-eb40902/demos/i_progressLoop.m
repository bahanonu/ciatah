% Demo of the progress() wrapper object. This can be used in for loops to
% get rid of the update() method. All supported constructor options will
% internally be passed to the ProgressBar() constructor.
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  25-Jun-2016 11:25:15
%


addpath('..');

numIterations = 1e5;


%% No title and specialties

for iIteration = progress(1:numIterations),
    % do nothing and print only
end




%% title and specific update rate
for iIteration = progress(1:numIterations, ...
        'Title', 'Iterator', ...
        'UpdateRate', 5),
   
    % do nothing and print only
end






% End of file: i_progressLoop.m
