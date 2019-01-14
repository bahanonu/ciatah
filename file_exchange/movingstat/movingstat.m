%% movingstat - will summarize up a vector based on N values specified
%  Well....talk about reinventing the wheel, only slower...turns out there
%  was a function in matlab to do most of what I was attempting. Using the
%  median as a summary statistic seems to be the only function not doable
%  using conv or filter.
% 
%  This fucntion calculates a moving sum, mean, etc, by aggregating 
%     forward N values using no loops if computer memory allows.  If no 
%     summary statistic is given, it will default to sum.  If computer
%     memroy is short, the function will default back to using loops.
%
%  This function should be extremely fast, there are no loops!  However,
%  because of this, memory could be a limitation with large sets of data,
%  and depending on the number of N-values to summarize for.  There is a
%  memory error trap if data are too large. 
%
%  If there is insufficient memory, the routine will switch to running in a
%  loop which is significantly slower, but at least it's still operational.
%
%  Output is length of input data minus N plus one (i.e. L-N+1)
%  
%  Data are expected to be in a single column.
%
%  UPDATES:
%    10/14/2010 - dramatically streamlined function.  Uses less memory now.
%    10/14/2010 - changed memory test to be exact using an error trap
%    10/18/2010 - comments from Cris Luengo noted that MATLAB has a
%    function that performs a lot of these types of operations except for
%    median. Updated to use the faster function except for median.  Which
%    reverts back to my original function.
%
%  Written by:
%     Jeff Burkey
%     King County, Department of Natural Resources and Parks
%     email: jeff.burkey@kingcounty.gov
%     October 13, 2010
%  
%  Example syntax:
%    dout = movingstat(data,20,@sum);
% or
%    dout = movingstat(data,7,@mean);
function dout = movingstat(din,N,fn)

    memsummary = memory;
    z = memsummary.MaxPossibleArrayBytes;

    if exist('fn','var') == 0
        % user didn't provide assume function to sum
        fn = @sum;
    end

    if nargin<2, error('Not enough input arguments!'), end
    
    [rows,cols] = size(din);
    if cols~=1, error('Data must be a vector!'), end
    if rows < cols, error('Data must be in a single column'), end
    if length(N)~=1, error('N must be a scalar!'), end
    if length(din) < N, error('Length of data cannot be less than N'), end
    
    L = rows;
    
    if L*8*2 > z
        str = 'Too much data, even for looping.\n';
        str = [str 'You will need to parse the data to process.\n'];
        error(str);
    end
    
    dout = fast;
    
    if isnan(dout)
        button = questdlg(...
            'Too much data. Do you want to continue with loops?', ...
            'movingstat: Large Dataset' ...
            );
        if strcmp(button,'Yes')
            dout = slow;
        else
            dout = nan;
        end
    end
    
    function dout = fast
        % This aggregation scheme is extremely efficient, but because it
        % can use a large amount of memory, a memory catch is applied.  If
        % the memory is exceeded, then the program will default to using 
        % loops.
        try
            switch func2str(fn)
                % Curteousy of Cris Luengo
                %  conv(data,ones(N,1),'valid');
                case 'mean'
                    dout = conv(din,ones(N,1)/N,'valid');
                case 'sum'
                    dout = conv(din,ones(N,1),'valid');
                otherwise
                    dout = fn(din(repmat(0:N-1,L-N+1,1)+cumsum(ones(L-N+1,N))),2);
            end
        catch me
            if strcmp(me.identifier,'MATLAB:nomem')
                dout = nan;
            end
        end
    end
    
    function dout = slow
        fprintf('Sorry. Too much data. Using loops.\nTime to get a cup of coffee.\n');
        try
            dout = zeros(L-N+1,1);
            h = waitbar(0,'Summarizing data. Please wait...');
            for irows = 1:L-N+1
                dout(irows) = fn(din(irows:irows+N-1));
                waitbar(irows/(L-N+1))
            end
        catch err
            close(h)
            fprintf('%s\n',err.message);
            dout = nan;
        end
        close(h)
    end
end