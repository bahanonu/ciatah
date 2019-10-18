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
		% 2019.08.25 [15:29:36] - Simplified Miji loading.
		% 2019.10.08 [11:18:53] - Checked whether on parallel worker, if so they do not load Miji.
		% 2019.10.08 [18:01:44] - Make sure default Fiji directories are not included and load Miji sans GUI to reduce issues with users pressing other buttons when Miji appears during initial loading.
		% 2019.10.11 [09:59:17] - Check that Miji plugins.dir has been added as a Java system property, if so then skip full loading of Miji each time to save time.
		% 2019.10.15 [12:30:53] - Fixed checking for Fiji path in Unix systems.
		% 2019.10.15 [21:57:45] - Improved checking for directories that should not be loaded, remove need for verLessThan('matlab','9.0') check.
	% TODO
		%

	% Disable the handle graphics warning "The DrawMode property will be removed in a future release. Use the SortMethod property instead." from being displayed. Comment out this line for debugging purposes as needed.
	warning('off','MATLAB:hg:WillBeRemovedReplaceWith')

	externalProgramsDir = '_external_programs';

	% Add calciumImagingAnalysis directory and subdirectories to path, use dbstack to ensure only add in the root directory regardless of where user has current MATLAB folder.
	functionLocation = dbstack('-completenames');
	functionLocation = functionLocation(1).file;
	[functionDir,~,~] = fileparts(functionLocation);
	pathList = genpath(functionDir);
	% pathList = genpath(pwd);
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

	% =================================================
	% Load Miji
	% Only call Miji functions if NOT on a parallel worker
	if ~isempty(getCurrentTask())
		disp('Inside MATLAB worker, do not load Miji.')
	elseif ~isempty(java.lang.System.getProperty('plugins.dir'))
		disp('Miji JAR files already loaded, skipping. If Miji issue, use "resetMiji".')
	else
		% add path for Miji, change as needed
		loadLocalFunctions = ['private' filesep 'settings' filesep 'privateLoadBatchFxns.m'];
		% First check for Fiji in _external_programs dir with path for this specific computer, since privateLoadBatchFxns might not generalize.
		fijiList = getFileList('_external_programs','fiji-.*-20151222(?!.zip|.dmg)');
		if ~isempty(fijiList)
			% pathtoMiji = ['_external_programs' filesep 'fiji-win64-20151222' filesep 'Fiji.app' filesep 'scripts'];
			pathtoMiji = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
			% else
			% end
			% create privateLoadBatchFxns.m
		elseif exist(loadLocalFunctions,'file')~=0
			run(loadLocalFunctions);
		else
			% Do nothing
		end
		% If no path to Miji, just skip and request user download Fiji/Miji.
		if exist('pathtoMiji','var')
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
				fprintf('No folder at specified path (%s), retry! or run below command on command line to set Miji directory:\n\n modelAddOutsideDependencies(''miji'');\n',pathtoMiji)
			end
		else
			disp('Please run "downloadMiji();" to download Fiji and load Miji into MATLAB.')
		end
	end
	% cnmfVersionDirLoad('none');
end
function openMijiCheck()
	try
		currP=pwd;
		% Miji;
		Miji(false);
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