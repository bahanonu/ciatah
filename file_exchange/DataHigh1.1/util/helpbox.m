function helpbox(message)
% helpbox(message)
%
% This function overrides Matlab's helpdlg box, since it is quite awful.
% This function ensures font will be displayed big enough for both
% windows and mac computers.
% It also allows one to include new lines '\n'.
%  Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013

% ---GNU General Public License Copyright---
% This file is part of DataHigh.
% 
% DataHigh is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, version 2.
% 
% DataHigh is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details in COPYING.txt found
% in the main DataHigh directory.
% 
% You should have received a copy of the GNU General Public License
% along with DataHigh.  If not, see <http://www.gnu.org/licenses/>.
%
% If planning to re-distribute, do not delete original code 
% (but original code can be commented out).  Make changes clear, 
% obvious, and well-documented.  All changes must be explicitly 
% listed in an added section at the top of the changed file, 
% the main DataHigh.m file, and in a readme_CHANGES.txt file 
% in the main DataHigh directory. Explicitly list the authors
% who made the changes, and that the original authors do not
% endorse any changes.  If changes are useful, consider 
% contacting the authors to incorporate into the next DataHigh 
% code release.
%
% Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013

    if (strcmp(message(end-1:end), '\n') ~= 1) %append a new line if one is not at the end
        message = [message '\n'];
    end
    
    h = helpdlg(sprintf(message));

    num_newlines = 0;
    for ichar = 1:length(message)
        if (strcmp(message(ichar), '\'))
            num_newlines = num_newlines + 1;
        end
    end


    set(h, 'Units', 'normalized');
    pos = get(h, 'Position');

    
    % dig through h's children to find the text, change its fontsize
    
    children = get(h, 'Children');  % has three children, the second one is the axes


    
    % find text handle and change font size
    text_handle = get(children(2), 'Children');  % boom! we have the text handle
    


    
    if (ismac)
        set(h, 'Position', [0.3 0.3 0.4 .0225*num_newlines+.075]);
        set(text_handle, 'FontSize', 16);
        set(text_handle, 'FontName', 'Arial');
    else
        set(h, 'Position', [0.3 0.3 0.4 .0235*num_newlines+.085]);
        set(text_handle, 'FontSize', 14);
        set(text_handle, 'FontName', 'Helvetica');
    end

    





end