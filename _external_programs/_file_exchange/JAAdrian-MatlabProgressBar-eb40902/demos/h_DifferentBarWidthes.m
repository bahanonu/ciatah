% Demo of a desired bar width
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  24-Jun-2016 15:43:41
%


addpath('..');

numIterations = 50;

%% Define larger bar width

barWidth = 100;

obj = ProgressBar(numIterations, ...
    'Width', barWidth, ...
    'Title', 'Larger Width' ...
    );

for iIteration = 1:2:numIterations,
    pause(0.1);
    
    obj.update(2);
end
obj.close();

%% Define smaller bar width

barWidth = 72;

obj = ProgressBar(numIterations, ...
    'Width', barWidth, ...
    'Title', 'Smaller Width' ...
    );

for iIteration = 1:2:numIterations,
    pause(0.1);
    
    obj.update(2);
end
obj.close();




% End of file: h_DifferentBarWidthes.m
