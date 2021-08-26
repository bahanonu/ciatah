% Demo of some standard applications with known total number of iterations
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  21-Jun-2016 17:12:41
%


addpath('..');

numIterations = 50;


%% Simple setup WITH known number of iterations

obj = ProgressBar(numIterations);

for iIteration = 1:numIterations,
    pause(0.1);
    
    obj.update();
end
obj.close();




%% Simple setup WITH known number of iterations and title

obj = ProgressBar(numIterations, ...
    'Title', 'Progress' ...
    );

for iIteration = 1:numIterations,
    pause(0.1);
    
    obj.update();
end
obj.close();




%% Now with a different step size

obj = ProgressBar(numIterations, ...
    'Title', 'Step Size 2' ...
    );

stepSize = 2;

for iIteration = 1:stepSize:numIterations,
    pause(0.1);
    
    obj.update(stepSize);
end
obj.close();




%% Simulate an iteration which takes longer so the timed printing stops

pauses = [0.1*ones(numIterations/2-1,1); 2; 0.1*ones(numIterations/2,1)];

obj = ProgressBar(numIterations, ...
    'Title', 'Waiting' ...
    );

for iIteration = 1:numIterations,
    pause(pauses(iIteration));
    
    obj.update();
end
obj.close();

%% Simulate a progress with it/sec < 1

numIterations = 10;
obj = ProgressBar(numIterations, ...
    'Title', 'Slow Progress' ...
    );

for iIteration = 1:numIterations,
    pause(1.5);
    
    obj.update();
end
obj.close();





% End of file: b_simpleProgressBar_demo.m
