function [versionStr, dateTimeStr] = version(varargin)
	% Get version for CIAtah.
	% Biafra Ahanonu
	% started: 2020.06.06 [23:36:36]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.01.18 [13:23:24] - Updated so reads CIAtah version directly from VERSION file instead of having the version information in two places (which increases probability of mismatch).
		% 2021.01.21 [10:36:30] - Changed to use readtable instead of readcell to increase compatability across MATLAB versions.
		% 2021.01.21 [17:03:54] - Added fscanf backup to readtable in case of Matlab compatibility issues, also specified more readtable defaults to avoid errors (Matlab 202a+ changed default behavior). Added last step backup of zero version.
		% 2021.03.21 [17:41:54] - Update VERSION path.
	% TODO
		%

	%========================
	% DESCRIPTION
	% options.exampleOption = '';
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		verPath = [ciapkg.getDir filesep '+ciapkg' filesep 'VERSION'];

		% verStr = readcell(verPath,'FileType','text');
		% versionStr = verStr{1};
		% dateTimeStr = num2str(verStr{2});

		verStr = readtable(verPath,'ReadVariableNames',0,'FileType','text','Format','auto','TextType','string');
		versionStr = verStr{1,1}{1};
		dateTimeStr = num2str(verStr{2,1}{1});
	catch
		try
			% disp('readtable issues, trying backup')
			fileID = fopen(verPath,'r');
			verStr = fscanf(fileID,'%c')
			fclose(fileID);
			verStr = strsplit(verStr,'\n');
			versionStr = strrep(verStr{1},'\n','');
			dateTimeStr = verStr{2};
		catch err
			versionStr = 'v0.00.0'
			dateTimeStr = '00000000000000';
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
end