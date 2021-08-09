% Demo of using ASCII hashes instead of the fancy Unicode blocks.
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  25-Jun-2016 14:26:43
%


addpath('..');

numIterations = 100;


%% Don't use unicode characters

obj = ProgressBar(numIterations, ...
    'Unicode', false, ...
    'Title', 'ASCII' ...
    );

for iIteration = 1:numIterations,
    pause(0.1);
    
    obj.update();
end
obj.close();






% End of file: j_NonUnicodeProgressBar.m
