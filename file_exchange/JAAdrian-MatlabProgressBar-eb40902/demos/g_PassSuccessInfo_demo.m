% Demo of the success bool of the update() method. This can be used to
% print failure messages during the loop.
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  21-Jun-2016 17:48:54
%


addpath('..');

numIterations = 1e2;


%% Pass success information of the current iteration

obj = ProgressBar(numIterations, ...
    'Title', 'Test Success' ...
    );

% throw the dice to generate some booleans. This parameters produce a
% success rate of 95%
wasSuccessful = logical(binornd(1, 0.95, numIterations, 1));
for iIteration = 1:numIterations,
    pause(0.1);
    
    obj.update([], wasSuccessful(iIteration));
end
obj.close();






% End of file: g_PassSuccessInfo_demo.m
