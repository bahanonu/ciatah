function loadBatchFxns()
	% Loads the necessary directories to have the batch functions present.
	% Biafra Ahanonu
	% started: 2013.12.24 [08:46:11]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.07.25 [09:08:59] - Changed so that it adds folders to path from the directory where loadBatchFxns.m is located.
		% 2019.08.20 [09:18:01] - Improve speed by checking for folders already in MATLAB path.
		% 2019.08.25 [15:29:36] - Simplified Miji loading
	% TODO
		%

	% Disable the handle graphics warning "The DrawMode property will be removed in a future release. Use the SortMethod property instead." from being displayed. Comment out this line for debugging purposes as needed.
	warning('off','MATLAB:hg:WillBeRemovedReplaceWith')

	% add controller directory and subdirectories to path
	functionLocation = dbstack('-completenames');
	functionLocation = functionLocation(1).file;
	[functionDir,~,~] = fileparts(functionLocation);
	pathList = genpath(functionDir);
	% pathList = genpath(pwd);
	pathListArray = strsplit(pathList,pathsep);
	pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep '.git']));
	% pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep 'docs']));
	pathListArray = pathListArray(pathFilter);

	if verLessThan('matlab','9.0')
		pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep 'cnmfe']));
		pathFilter1 = cellfun(@isempty,regexpi(pathListArray,[filesep 'cnmf_original']));
		pathFilter2 = cellfun(@isempty,regexpi(pathListArray,[filesep 'cnmf_current']));
		pathFilter3 = cellfun(@isempty,regexpi(pathListArray,[filesep 'cvx_rd']));
		pathListArray = pathListArray(pathFilter&pathFilter1&pathFilter2&pathFilter3);
	else
		matchIdx = contains(pathListArray,{[filesep 'cnmfe'],[filesep 'cnmf_original'],[filesep 'cnmf_current'],[filesep 'cvx_rd']});
		pathListArray = pathListArray(~matchIdx);
	end

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

	% Automatically add Inscopix
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

	% add path for Miji, change as needed
	loadLocalFunctions = ['private' filesep 'settings' filesep 'privateLoadBatchFxns.m'];
	if exist(loadLocalFunctions,'file')~=0
		run(loadLocalFunctions);
	else
		pathtoMiji = ['_external_programs' filesep 'fiji-win64-20151222' filesep 'Fiji.app' filesep 'scripts\'];
		% create privateLoadBatchFxns.m
	end
	onPath = subfxnCheckPath(pathtoMiji);
	if exist(pathtoMiji,'dir')==7&&onPath==0
		if onPath==1
			fprintf('Miji already in PATH: %s.\n',pathtoMiji)
		else
			addpath(pathtoMiji);
			fprintf('Added private Miji to path: %s.\n',pathtoMiji)
		end
		openMijiCheck();
		% % Get Miji properly loaded in the path
		% if exist('Miji.m')==2&&exist('MIJ','class')==0
		% 	resetMiji;
		% else
		% end
	elseif onPath==1
		fprintf('Miji already in MATLAB path: %s\n',pathtoMiji);
		openMijiCheck()
	else
		fprintf('No folder at specified path, retry! %s.\n',pathtoMiji)
	end
	% cnmfVersionDirLoad('none');
end
function openMijiCheck()
	try
		currP=pwd;
		Miji;
		% MIJ.start;
		cd(currP);
		MIJ.exit;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
		manageMiji('startStop','start');
		manageMiji('startStop','exit');
	end
end
function onPath = subfxnCheckPath(thisRootPath)
	pathCell = regexp(path, pathsep, 'split');
	if verLessThan('matlab','9.0')
		matchIdx = ~cellfun(@isempty,regexpi(pathCell,thisRootPath));
		% pathListArray = pathListArray(pathFilter&pathFilter1&pathFilter2);
	else
		matchIdx = contains(pathCell,thisRootPath);
	end
	onPath = any(matchIdx);
end