% Demo of another counting unit. At this point, only 'Bytes' is supported
% as alternative.
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  22-Jun-2016 12:32:50
%


addpath('..');

% set up some dummy file sizes and 'processing times' for each file
dummyFile = {rand(1e3, 1), rand(5e2, 1), rand(1e5, 1), rand(1e5, 1)};
filePause = [1, 0.5, 3, 3];

numTotalBytes = sum(cellfun(@(x) size(x, 1), dummyFile));


%% Work with size of processed bytes WITHOUT knowledge of total bytes

obj = ProgressBar([], ...
    'Unit', 'Bytes', ...
    'Title', 'Test Bytes 1' ...
    );

for iFile = 1:length(dummyFile),
    buffer = dummyFile{iFile};
    
    pause(filePause(iFile));
    obj.update(length(buffer));
end
obj.close();




%% Work with size of processed bytes WITH knowledge of total bytes

obj = ProgressBar(numTotalBytes, ...
    'Unit', 'Bytes', ...
    'Title', 'Test Bytes 2' ...
    );

for iFile = 1:length(dummyFile),
    buffer = dummyFile{iFile};
    
        
    pause(filePause(iFile));
    obj.update(length(buffer));
end
obj.close();







% End of file: e_CountProcessedBytes.m
