function [success] = modelAddOutsideDependencies(dependencyName,varargin)
	% Used to request certain outside dependencies from users.
	% Biafra Ahanonu
	% started: 2017.11.16 [16:50:28]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.exampleOption = '';
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
		success = 0;
		switch dependencyName
			case 'miji'
				if exist('Miji.m','file')==2
					display(['Miji located in: ' which('Miji.m')]);
					% Miji is loaded, continue
				else
					% pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
					%              'Miji path', [1 100]);
					% pathToMiji = pathToMiji{1};
					display('Dialog box: Enter path to Miji.m in Fiji (likely in "scripts" folder, e.g. \Fiji.app\scripts)')
					pathToMiji = uigetdir('\.','Enter path to Miji.m in Fiji (likely in "scripts" folder, e.g. \Fiji.app\scripts)');
					if ischar(pathToMiji)
						privateLoadBatchFxnsPath = 'private\settings\privateLoadBatchFxns.m';
						if exist(privateLoadBatchFxnsPath,'file')~=0
							fid = fopen(privateLoadBatchFxnsPath,'at')
							fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
							fclose(fid);
						end
						addpath(pathToMiji);
					end

					% % If MIJ class not loaded, load Miji.m.
					% if exist('MIJ')~=8
					% 	% Load Miji so paths added to javaclasspath('-dynamic')
					% 	currP=pwd;Miji;cd(currP);
					% 	MIJ.exit;
					% end

					% % First attempt to open Miji
					% try
					% 	MIJ.start;
					% catch err
					% 	disp(repmat('@',1,7))
					% 	disp(getReport(err,'extended','hyperlinks','on'));
					% 	disp(repmat('@',1,7))

					% 	disp('Reset Java class path and Miji then try again');
					% 	resetMiji

					% 	% Try again after resetting Miji.
					% 	try
					% 		MIJ.start;
					% 	catch err
					% 		disp(repmat('@',1,7))
					% 		disp('Apparently Miji hates your computer, sorry!')
					% 		disp(getReport(err,'extended','hyperlinks','on'));
					% 		disp(repmat('@',1,7))
					% 	end
					% end

					% Get Miji properly loaded in the path
					resetMiji;

					% % Load Miji so paths added to javaclasspath('-dynamic')
					% currP=pwd;Miji;cd(currP);
					% MIJ.exit;

				end
			otherwise
				display('Incorrect option input.')
				% do nothing
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end