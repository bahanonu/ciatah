function obj = loadBatchFunctionFolders(obj)
	% Loads the necessary directories to have the batch functions present.
	% Biafra Ahanonu
	% started: 2013.12.24 [08:46:11]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	loadRepoMethod = 1;
	if loadRepoMethod==1
		loadBatchFxns();
	else
		subfxnLoadFxns();
	end

	function subfxnLoadFxns()
		% Disable the handle graphics warning "The DrawMode property will be removed in a future release. Use the SortMethod property instead." from being displayed. Comment out this line for debugging purposes as needed.
		warning('off','MATLAB:hg:WillBeRemovedReplaceWith')

		% add controller directory and subdirectories to path
		functionLocation = dbstack('-completenames');
		functionLocation = functionLocation(1).file;
		[functionDir,~,~] = fileparts(functionLocation);
		[functionDir,~,~] = fileparts(functionDir);
		pathList = genpath(functionDir);
		pathListArray = strsplit(pathList,pathsep);
		pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep '.git']));
		% pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep 'docs']));
		pathListArray = pathListArray(pathFilter);

		% =================================================
		% Remove directories that should not be loaded by default
		% matchIdx = contains(pathListArray,{[filesep 'cnmfe'],[filesep 'cnmf_original'],[filesep 'cnmf_current'],[filesep 'cvx_rd'],[filesep 'Fiji.app'],[filesep 'fiji-.*-20151222']});
		% pathListArray = pathListArray(~matchIdx);
		if ismac
			sepChar = filesep;
		elseif isunix
			sepChar = filesep;
		elseif ispc
			sepChar = '\\';
		else
			sepChar = filesep;
		end
		matchIdx = cellfun(@isempty,regexp(pathListArray,[sepChar '(cnmfe|cnmf_original|cnmf_current|cvx_rd|Fiji\.app|fiji-.*-20151222)']));
		pathListArray = pathListArray(matchIdx);

		% =================================================
		% Remove paths that are already in MATLAB path to save time
		pathFilter = cellfun(@isempty,pathListArray);
		pathListArray = pathListArray(~pathFilter);
		pathFilter = ismember(pathListArray,strsplit(path,pathsep));
		pathListArray = pathListArray(~pathFilter);

		if isempty(pathListArray)
			fprintf('MATALB path already has all needed non-private folders under: %s\n',functionDir);
		else
			fprintf('Adding all non-private folders under: %s\n',functionDir);
			pathList = strjoin(pathListArray,pathsep);
			addpath(pathList);
		end

		% =================================================
		% Automatically add Inscopix Data Processing Software
		if ismac
			baseInscopixPath = '';
		elseif isunix
			baseInscopixPath = '';
		elseif ispc
			baseInscopixPath = 'C:\Program Files\Inscopix\Data Processing';
		else
			disp('Platform not supported')
		end
		pathFilter = ismember(baseInscopixPath,strsplit(path,pathsep));
		if pathFilter==0
			if ~isempty(baseInscopixPath)&&exist(baseInscopixPath,'dir')==7
				addpath(baseInscopixPath);

				if exist('isx.Movie','class')==8
					fprintf('Inscopix Data Processing software added: %s\n',baseInscopixPath)
				else
					disp('Check Inscopix Data Processing software install!')
				end
			else
			end
		else
			fprintf('Inscopix Data Processing software already in path: %s\n',baseInscopixPath)
		end
	end
end