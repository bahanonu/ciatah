% Demo of nested bars. At this point only one nested bar is supported
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  21-Jun-2016 17:14:36
%


addpath('..');

numOuterIterations = 3;
numInnerIterations = 20;



%% Nested Bars without inner update rate

% be sure to set the update rate to inf to disable a timed printing of the
% bar!
obj1 = ProgressBar(numOuterIterations, ...
    'UpdateRate', inf, ...
    'Title', 'Loop 1' ...
    );

% helper method to print a first progress bar before the inner loop starts.
% This prevents a blank line until the first obj1.update() is called.
obj1.start();
for iOuterIteration = 1:numOuterIterations,
    obj2 = ProgressBar(numInnerIterations, ...
        'UpdateRate', inf, ...
        'Title', 'Loop 2' ...
        );
    
    for jInnerIteration = 1:numInnerIterations,
        obj2.update();
        
        pause(0.1);
    end
    obj2.close();
    
    obj1.update();
end
obj1.close();




%% Nested Bars WITH inner update rate

numInnerIterations = 50e3;

% be sure to set the update rate to inf to disable a timed printing of the
% bar!
obj1 = ProgressBar(numOuterIterations, ...
    'UpdateRate', inf, ...
    'Title', 'Loop 1' ...
    );

obj1.start();
for iOuterIteration = 1:numOuterIterations,
    % this progress can have an update rate!
    obj2 = ProgressBar(numInnerIterations, ...
        'UpdateRate', 5, ...
        'Title', 'Loop 2' ...
        );
    
    for jInnerIteration = 1:numInnerIterations,        
        obj2.update();
    end
    obj2.close();
    
    obj1.update();
end
obj1.close();





% End of file: d_NestedProgressBars_demo.m
