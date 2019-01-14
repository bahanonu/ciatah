% Demo of the printMessage() method. In 3 iterations an info message is
% printed
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  21-Jun-2016 17:48:22
%


addpath('..');

numIterations = 1e2;

%% Simple setup and print a message in desired iterations

obj = ProgressBar(numIterations, ...
    'Title', 'Progress' ...
    );

for iIteration = 1:numIterations,
    obj.update();
    
    if iIteration == 30 || iIteration == 50 || iIteration == 70,
        obj.printMessage(sprintf('Hello! @Iteration %i', iIteration));
    end
    
    pause(1e-1);
end
obj.close();



% End of file: f_PrintInfoDuringRun_demo.m
