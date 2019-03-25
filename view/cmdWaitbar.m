function [reverseStr] = cmdWaitbar(i,nItems,reverseStr,varargin)
	% Puts a txt waitbar into the cmd window, less intrusive than pop-up waitbar.
	% Biafra Ahanonu
	% started: 2014.01.14
	% thanks to:
		% http://www.mathworks.com/matlabcentral/newsreader/view_thread/32291
		% http://stackoverflow.com/questions/11050205/text-progress-bar-in-matlab
	% inputs
			%
	% outputs
			%

	% changelog
			% 2014.02.14 [16:35:55] now is mostly
	% TODO
			% Should reverseStr be made global so function is entirely self-contained? - NO, globals are evil.
			% change so waitbarOn = 0 can short circuit getOptions to save speed execution time
	% example
		% before loop = reverseStr
		% reverseStr = cmdWaitbar(i,nItems,reverseStr,'inputStr','loading hdf5','waitbarOn',options.waitbarOn,'displayEvery',50);

	%========================
	options.inputStr = 'progress';
	options.waitbarOn = 1;
	options.displayEvery = 20;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 		eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if options.waitbarOn==0
		return;
	elseif i==1||mod(i,options.displayEvery)==0||i==nItems
		if i==1
			reverseStr = '\b';
		else
			% diary OFF
		end
		progN = round(i/nItems*100);
	    reverseStr = '';
		if usejava('desktop')==0
		    % return;
		    % reverseStr = '';
		    % options.inputStr = '';
			% txt=sprintf(': %1.2f | ',i/nItems*100);
			txt=sprintf('%d|',progN);
		end
		if i==1
			txt=sprintf(': %d|',progN);
		elseif i==nItems
			% reverseStr = '';
		    options.inputStr = '';
			txt=sprintf('%d\n',progN);
		elseif i~=1
			% reverseStr = '';
		    options.inputStr = '';
			txt=sprintf('%d|',progN);
		else
			txt=sprintf(': %d',progN);
		end
		% txt=strcat('\n',options.inputStr,txt,'%%');
		% txt=strcat('',options.inputStr,txt,'%%');
		txt=strcat('',options.inputStr,txt);
		fprintf([reverseStr, txt]);
		% drawnow;
	   	reverseStr = repmat(sprintf('\b'), 1, length(txt)-1);
	   	if usejava('desktop')==0
		    reverseStr = '';
	   	end
	end
	if i==nItems
		fprintf('\n');
		% drawnow;
	end
	% diary ON

	% create some text
	% note
	% 	tlen accumulates the total amount of text + 1<CR/LF>
	% 	for each line that you want to erase + 1 for itself
	% disp(sprintf('\n\n\ndemo: loop-indicator\n\n\n'));
	% z=char(8);
	% tlen = 0;
	% for i=1:options.nItems
		% if mod(i,10)==0
			% txt=sprintf('looping %5d %s',i,repmat('.',1,i));
			% txt = 'looping...';
			% tlen=length(txt)+1;
			% disp(txt);
			% do <something>
			% txt=sprintf('progress: %5d %g',i,i/nItems);
			% tlen=length(txt)+1;
			% disp(txt);
			% pause(.05)
			% clean
			% disp(repmat(z,1,tlen+1));
		% end
	% end
	% disp('done');
end