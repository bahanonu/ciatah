function [percent progressLength] = parfor_progress(N)
%PARFOR_PROGRESS Progress monitor (progress bar) that works with parfor.
%   PARFOR_PROGRESS works by creating a file called parfor_progress.txt in
%   your working directory, and then keeping track of the parfor loop's
%   progress within that file. This workaround is necessary because parfor
%   workers cannot communicate with one another so there is no simple way
%   to know which iterations have finished and which haven't.
%
%   PARFOR_PROGRESS(N) initializes the progress monitor for a set of N
%   upcoming calculations.
%
%   PARFOR_PROGRESS updates the progress inside your parfor loop and
%   displays an updated progress bar.
%
%   PARFOR_PROGRESS(0) deletes parfor_progress.txt and finalizes progress
%   bar.
%
%   To suppress output from any of these functions, just ask for a return
%   variable from the function calls, like PERCENT = PARFOR_PROGRESS which
%   returns the percentage of completion.
%
%   Example:
%
%      N = 100;
%      parfor_progress(N);
%      parfor i=1:N
%         pause(rand); % Replace with real code
%         parfor_progress;
%      end
%      parfor_progress(0);
%
%   See also PARFOR.

% By Jeremy Scheff - jdscheff@gmail.com - http://www.jeremyscheff.com/

error(nargchk(0, 1, nargin, 'struct'));

if nargin < 1
    N = -1;
end

percent = 0;
progressLength = 0;
return;
w = 50; % Width of progress bar
saveDir = 'private';
filePath = [saveDir filesep 'parfor_progress.txt'];
if ~exist(saveDir,'dir');mkdir(saveDir);end

if N > 0
    f = fopen(filePath, 'w');
    if f<0
        error('Do you have write permissions for %s?', pwd);
    end
    fprintf(f, '%d\n', N); % Save N at the top of progress.txt
    fclose(f);

    if nargout == 0
        % disp(['  0%[>', repmat(' ', 1, w), ']']);
        dispstat(['  0%[>', repmat(' ', 1, w), ']']);
    end
elseif N == 0
    delete(filePath);
    percent = 100;

    if nargout == 0
        % disp([repmat(char(8), 1, (w+9)), char(10), '100%[', repmat('=', 1, w+1), ']']);
        dispstat([repmat(char(8), 1, (w+9)), char(10), '100%[', repmat('=', 1, w+1), ']']);
    end
else
    % if ~exist(filePath, 'file')
    %     error([filePath ' not found. Run PARFOR_PROGRESS(N) before PARFOR_PROGRESS to initialize ' filePath '.']);
    % end
    return;
    try
        f = fopen(filePath, 'A');
    catch
        error([filePath ' not found. Run PARFOR_PROGRESS(N) before PARFOR_PROGRESS to initialize ' filePath '.']);
    end
    fprintf(f, '1\n');
    fclose(f);

    f = fopen(filePath, 'r');
    progress = fscanf(f, '%d');
    progressLength = length(progress(2:end));
    fclose(f);
    try
        percent = (length(progress)-1)/progress(1)*100;
    catch
    end

    if nargout == 0
        perc = sprintf('%3.0f%%', percent); % 4 characters wide, percentage
        % reverseStr = repmat(sprintf('\b'), 1, length(perc)-1);
        % fprintf([reverseStr, perc]);drawnow;
        outputStr = [repmat(char(8), 1, (w+9)), char(10), perc, '[', repmat('=', 1, round(percent*w/100)), '>', repmat(' ', 1, w - round(percent*w/100)), ']'];
        % disp(outputStr);
        dispstat(outputStr);
        % fprintf([repmat('\b', 1, (w+9)), '\n', perc, '[', repmat('=', 1, round(percent*w/100)), '>', repmat(' ', 1, w - round(percent*w/100)), ']']);
    end
end
