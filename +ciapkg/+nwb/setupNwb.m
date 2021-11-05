function [success] = setupNwb(varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: INSERT_DATE
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.03.26 [06:27:48] - Fix for options.defaultObjDir leading to incorrect NWB folder and cores not being generated.
	% TODO
		%

	% ========================
	% Str: default path for CIAtah
	options.defaultObjDir = ciapkg.getDir;
	% Str: default root path where all external programs are stored
	options.externalProgramsDir = ciapkg.getDirExternalPrograms();
	% Str: default path for MatNWB Matlab code
	options.matnwbDir = 'matnwb';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		success = 0;
		% Load NWB Schema as needed
		if exist('types.core.Image')==0
			try
				disp('Generating matnwb types core files with "generateCore.m"')
				origPath = pwd;
				mat2nwbPath = [options.externalProgramsDir filesep options.matnwbDir];
				disp(['cd ' mat2nwbPath])
				cd(mat2nwbPath);
				generateCore;
				disp(['cd ' origPath])
				cd(origPath);
			catch
				cd(ciapkg.getDir);
			end
			ciapkg.loadDirs;
		else
			disp('NWB Schema types already loaded!')
		end
		success = 1;

	catch err
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
