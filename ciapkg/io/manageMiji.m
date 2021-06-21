function manageMiji(varargin)
	% Controls starting and stopping of Miji in a way to reduce issues
	% Biafra Ahanonu
	% started: 2019.04.08
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.06.20 [00:20:38] - Add support for setting up ImageJ along with closing all windows to future proof any changes to those calls.
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
				try
					% If MIJ class not loaded, load Miji.m.
					if exist('MIJ','class')~=8
						% Load Miji so paths added to javaclasspath('-dynamic')
						currP = pwd;
						% Miji;
						Miji(false);
						cd(currP);
						MIJ.exit;
					end
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
						return;
					end
				end

				% If Miji.m not in path, ask user
				if exist('MIJ','class')~=8
				else
					if exist('Miji.m','file')~=2
						modelAddOutsideDependencies('miji');
					end
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
			case 'setupImageJ'
				% Sets up ImageJ by pointing Java path to the jar files.

				imagejPath = [ciapkg.getDirExternalPrograms filesep 'imagej'];
				pathsToAdd = {[imagejPath filesep 'mij.jar'],[imagejPath filesep 'ij.jar']};
				nPaths = length(pathsToAdd);
				for i = 1:nPaths
					thisPath = pathsToAdd{i};
					disp('Loading MIJI + ImageJ.')
					fprintf('Adding to Java path: %s\n',thisPath);
					javaaddpath(thisPath);
				end
			case 'closeAllWindows'
				% Closes all open windows but leaves ImageJ running.

				% MIJ.run('Close All Without Saving');
				% MIJ.closeAllWindows;
				allClosedFlag = 0
				nImagesToBreak = 20;
				imageNo = 1
				while allClosedFlag==0
					try
						MIJ.getListImages
						MIJ.run('Close')
					catch
						allClosedFlag = 1;
					end
					imageNo = imageNo + 1;
				end
				MIJ.closeAllWindows;
				% MIJ.exit;
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