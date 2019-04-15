function manageMiji(varargin)
	% Controls starting and stopping of Miji in a way to reduce issues
	% Biafra Ahanonu
	% started: 2019.04.08
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% DESCRIPTION
	options.startStop = 'start';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		startStop = options.startStop;
		switch startStop
			case 'start'
				% If MIJ class not loaded, load Miji.m.
				if exist('MIJ')~=8
					% Load Miji so paths added to javaclasspath('-dynamic')
					currP=pwd;Miji;cd(currP);
					MIJ.exit;
				end

				% If Miji.m not in path, ask user
				if exist('Miji.m')~=2
					modelAddOutsideDependencies('miji');
				end

				% First attempt to open Miji
				try
					MIJ.start;
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))

					disp('Reset Java class path and Miji then try again');
					resetMiji

					% Try again after resetting Miji.
					try
						MIJ.start;
					catch err
						disp(repmat('@',1,7))
						disp('Apparently Miji hates your computer, sorry!')
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
					end
				end
			case 'exit'
				try
					MIJ.exit;
				catch err
					disp(repmat('@',1,7))
					disp('Miji likely already closed, throwing Java error.')
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			otherwise
				% Body
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end