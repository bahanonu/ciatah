function [success] = setupNwb(varargin)
	% Checks that NWB code is present and setup correctly.
	% Biafra Ahanonu
	% started: 2021.01.24 [14:31:24]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.02.01 [‏‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.03.26 [06:27:48] - Fix for options.defaultObjDir leading to incorrect NWB folder and cores not being generated.
		% 2021.11.07 [16:13:44] - Update to include check for each of the NWB dependencies taken from saveNeurodataWithoutBorders.
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
	options = ciapkg.api.getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		success = 0;
		try
			% Check that all necessary files are loaded
			loadDependenciesFlag = 0;
			if length(which('yaml.ReadYaml'))==0
				disp('yaml not loaded, loading now...')
				loadDependenciesFlag = 1;
			end
			if length(which('get_input_args'))==0
				disp('matnwb not loaded, loading now...')
				loadDependenciesFlag = 1;
			end
			if length(which('add_processed_ophys'))==0
				disp('nwb_schnitzer_lab not loaded, loading now...')
				loadDependenciesFlag = 1;
			end
			if loadDependenciesFlag==1
				ciapkg.io.loadDependencies(...
					'guiEnabled',0,...
					'depIdxArray',5,...
					'forceUpdate',0);
					% 'dependencyStr','downloadNeuroDataWithoutBorders',...
					% 'dispStr','Download NWB (NeuroDataWithoutBorders)',...
				ciapkg.loadDirs;
			else
				disp('NWB dependencies loaded.')
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end

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
