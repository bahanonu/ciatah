function [success] = modelAddOutsideDependencies(dependencyName,varargin)
	% Used to request certain outside dependencies from users.
	% Biafra Ahanonu
	% started: 2017.11.16 [16:50:28]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.10.15 [12:29:30] - Added flag to prevent recursive loop between resetMiji and modelAddOutsideDependencies.
		% 2021.02.01 [??‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.06.20 [00:20:12] - Updated to add support for ImageJ call instead of Fiji.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.12.26 [‏‎09:10:55] - No longer use Fiji-based Miji.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.exampleOption = '';
	options.defaultExternalProgramDir = ciapkg.getDirExternalPrograms();
	options.recursionExit = 0;
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
				if exist('MIJ','class')==8
					disp('Miji loaded!')
					return;
				else
					manageMiji('startStop','setupImageJ');
					if exist('MIJ','class')==8
						disp('Miji loaded!')
						return;
					end
                end
                
                % No longer use Fiji-based Miji.
                return;

				if exist('Miji.m','file')==2
					display(['Miji located in: ' which('Miji.m')]);
					% Miji is loaded, continue
				elseif ~isempty(java.lang.System.getProperty('plugins.dir'))&options.recursionExit==0
					disp('Miji JAR files already loaded, skipping. If Miji issue, use "resetMiji".')
				else
					% pathToMiji = inputdlg('Enter path to Miji.m in Fiji (e.g. \Fiji.app\scripts):',...
					%              'Miji path', [1 100]);
					% pathToMiji = pathToMiji{1};
					% display('Dialog box: Enter path to Miji.m in Fiji (likely in "scripts" folder, e.g. \Fiji.app\scripts)')
					fijiList = getFileList(options.defaultExternalProgramDir,'(Fiji.app|fiji-.*-20151222(?!.zip|.dmg))');
					if ~isempty(fijiList)
						if ismac
							checkMijiPath = [fijiList{1} filesep 'scripts'];
						elseif isunix
							checkMijiPath = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
						elseif ispc
							checkMijiPath = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
						else
							checkMijiPath = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
						end
						% checkMijiPath = [options.defaultExternalProgramDir filesep 'Fiji.app' filesep 'scripts'];
						if exist(checkMijiPath,'dir')==7
							fprintf('AUTOMATICALLY adding Miji path: %s\n',checkMijiPath);
							pathToMiji = checkMijiPath;
						end
					end
					if exist('pathToMiji','var')==0
						if exist(options.defaultExternalProgramDir,'dir')==7
							loadPathHere = options.defaultExternalProgramDir;
							loadStr = ['Enter path to Miji.m in Fiji (likely in "scripts" folder, e.g. ' filesep ciapkg.pkgName options.defaultExternalProgramDir '\Fiji.app\scripts)'];
						else
							loadPathHere = '\.';
							loadStr = ['Enter path to Miji.m in Fiji (likely in "scripts" folder, e.g. \Fiji.app\scripts)'];
						end
						disp(['Dialog box: ' loadStr])
						pathToMiji = uigetdir(loadPathHere,loadStr);
					end
					if ischar(pathToMiji)
						privateLoadBatchFxnsPath = 'private\settings\privateLoadBatchFxns.m';
						if exist(privateLoadBatchFxnsPath,'file')~=0
							fid = fopen(privateLoadBatchFxnsPath,'at')
							fprintf(fid, '\npathtoMiji = ''%s'';\n', pathToMiji);
							fclose(fid);
						end
						addpath(pathToMiji);
					end

					if options.recursionExit==1
						return;
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