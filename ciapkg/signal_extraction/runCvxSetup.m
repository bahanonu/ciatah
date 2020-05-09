function [success] = runCvxSetup(varargin)
	% DESCRIPTION.
	% Biafra Ahanonu
	% started: INSERT_DATE
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% Str: default location of external programs
	options.defaultExternalProgramDir = ['_external_programs'];
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
		cvxSetupFilePath = [options.defaultExternalProgramDir filesep 'cvx_rd' filesep 'cvx_setup.m'];
		if exist(cvxSetupFilePath)&isempty(which('cvx_begin'))
			disp(['Running default cvx_setup.m: ' cvxSetupFilePath])
			run(cvxSetupFilePath);
		end

		if isempty(which('cvx_begin'))
			display('Dialog box: select cvx_setup.m.')
			[filePath,folderPath,~] = uigetfile(['*.*'],'select cvx_setup.m');
			run([folderPath filesep filePath]);
		end

		success = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
