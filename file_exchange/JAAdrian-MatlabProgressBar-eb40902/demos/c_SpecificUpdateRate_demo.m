% Demo how to manipulate the update rate
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  21-Jun-2016 17:14:54
%


addpath('..');

numIterations = 1e6;


%% Desired update rate should be 5 Hz (the default is 10 Hz)

updateRateHz = 10;

% pass the number of iterations and the update cycle in Hz
obj = ProgressBar(numIterations, ...
    'UpdateRate', updateRateHz ...
    );

for iIteration = 1:numIterations,
    obj.update();
end
obj.close();




%% No desired update rate
% (incorporate a pause to prevent faster updates than MATLAB can print)

numIterations = 100;

updateRateHz = inf;

% pass the number of iterations and the update cycle in Hz
obj = ProgressBar(numIterations, ...
    'UpdateRate', updateRateHz ...
    );

for iIteration = 1:numIterations,
    obj.update();
    
    pause(0.1);
end
obj.close();








% End of file: c_SpecificUpdateRate_demo.m
