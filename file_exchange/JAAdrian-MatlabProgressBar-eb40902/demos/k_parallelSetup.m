% Demo of the parallel functionality using a parfor loop. This script may
% throw errors if you don't own the Parallel Processing Toolbox.
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  27-Jun-2016 22:04:18
%


addpath('..');

numIterations = 500;

if isempty(gcp('nocreate')),
    parpool();
end



%% Without knowledge of total number of iterations

% Instantiate the object with the 'Parallel' switch set to true and save
% the aux. files in the pwd.
obj = ProgressBar([], ...
    'Parallel', true, ...
    'WorkerDirectory', pwd, ...
    'Title', 'Parallel 1' ...
    );


parfor iIteration = 1:numIterations,
    pause(0.1);
    
    % USE THIS FUNCTION AND NOT THE UPDATE() METHOD OF THE OBJECT!!!
    updateParallel([], pwd);
end
obj.close();




%% With knowledge of total number of iterations

% Instantiate the object with the 'Parallel' switch set to true and save
% the aux. files in the default directory (tempdir)
obj = ProgressBar(numIterations, ...
    'Parallel', true, ...
    'Title', 'Parallel 2' ...
    );


parfor iIteration = 1:numIterations,
    pause(0.1);
    
    % USE THIS FUNCTION AND NOT THE UPDATE() METHOD OF THE OBJECT!!!
    updateParallel();
end
obj.close();


% End of file: k_parallelSetup.m
