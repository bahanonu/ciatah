function loadBatchFxns(varargin)
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
		% 2019.11.13 [18:06:02] - Updated to make contains not include less than 9.1.
		% 2020.05.09 [16:40:13] - Updates to remove additional specific repositories that should not be loaded by default. Add support for overriding this feature.
		% 2020.06.05 [23:35:43] - If user doesn't have Parallel Toolbox, still works
		% 2020.07.21 [14:11:42] - Fix to make sure all sub-folders (not just the root) are also removed in the case of certain external_programs.
		% 2021.02.01 [??‎15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.06.20 [00:22:38] - Added manageMiji('startStop','closeAllWindows'); support.
		% 2021.07.16 [13:38:55] - Remove redundant loading and unloading of external programs via additional checks.
		% 2021.07.22 [19:51:50] - Moved loadBatchFxns into ciapkg package. Use ciapkg.getDir to get directory as standard IO.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.08.09 [12:06:32] - Do not add docs and data folders or sub-folders to the path.
		% 2021.08.24 [13:46:13] - Update to fullfile call using filesep to make platform neutral.
		% 2021.11.09 [19:14:49] - Improved handling of external programs both in adding and removing from path. Additional support for removing specific packages that are not always needed.
	% TODO
		%
	
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% Disable the handle graphics warning "The DrawMode property will be removed in a future release. Use the SortMethod property instead." from being displayed. Comment out this line for debugging purposes as needed.
	warning('off','MATLAB:hg:WillBeRemovedReplaceWith')

	% Get location of external program directory
	externalProgramsDir = ciapkg.getDirExternalPrograms();

	% List of M-files where if found, that programs directory should by default be removed from the path.
	removeDirFxnToFind = {'runCELLMax.m','extractor.m','normcorre.m','tenrandblk.m'};
	% 'cellmax.runCELLMax', 'CELLMax_Wrapper.m'

	% Add calciumImagingAnalysis directory and subdirectories to path, use dbstack to ensure only add in the root directory regardless of where user has current MATLAB folder.
	% functionLocation = dbstack('-completenames');
	% functionLocation = functionLocation(1).file;
	% [functionDir,~,~] = fileparts(functionLocation);
	functionDir = ciapkg.getDir;
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

	% pathListArray = subfxnRemoveDirs(0,pathListArray);
	pathListArrayOriginal = pathListArray;

	% =================================================
	% Remove paths that are already in MATLAB path to save time
	pathFilter = cellfun(@isempty,pathListArray);
	pathListArray = pathListArray(~pathFilter);
	pathFilter = ismember(pathListArray,strsplit(path,pathsep));
	pathListArray = pathListArray(~pathFilter);

	% Remove 'docs' and 'data', don't need to be in the path.
	matchIdxD = contains(pathListArray,[functionDir filesep 'docs']);
	pathListArray = pathListArray(~matchIdxD);

	matchIdxD = contains(pathListArray,[functionDir filesep 'data']);
	pathListArray = pathListArray(~matchIdxD);

	matchIdxD = contains(pathListArray,[externalProgramsDir filesep '_downloads']);
	pathListArray = pathListArray(~matchIdxD);	

	% If going to remove directories in removeDirFxnToFind then do so now to prevent redundant calls to addpath, etc.
	findListFlag = [];
	if isempty(varargin)
		[pathListArray,findListFlag] = subfxnRemoveDirs(0,pathListArray);
	end

	if strcmp(varargin,'excludeExternalPrograms')
		disp(['Excluding ' externalProgramsDir ' from PATH adding.'])
		matchIdx2 = contains(pathListArray,externalProgramsDir);
		pathListArray = pathListArray(~matchIdx2);
	end

	% =================================================
	% Add paths as needed and remove any paths that should not be present.

	skipRemovePath = 0;
	if isempty(pathListArray)&isempty(varargin)
		disp('Folders still need to be removed.')
		if any(findListFlag)
			skipRemovePath = 0;
		end
	elseif isempty(pathListArray)
		fprintf('MATALB path already has all needed non-private folders under: %s\n',functionDir);
		skipRemovePath = 1;
	else
		fprintf('Adding all non-private folders under: %s\n',functionDir);
		pathList = strjoin(pathListArray,pathsep);
		addpath(pathList);
	end

	loadMijiCheck = 1;
	if strcmp(varargin,'loadEverything')

	elseif strcmp(varargin,'skipLoadMiji')
		loadMijiCheck = 0;
	else
		if skipRemovePath==0
			pathListArray = subfxnRemoveDirs(1,pathListArrayOriginal);
		end
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
		disp('Platform not supported for Inscopix Data Processing Software.')
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
	try
		workerCheck = ~isempty(getCurrentTask());
	catch err
		workerCheck = 0;
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

	if workerCheck==1
	else
		if loadMijiCheck==0
			disp('Skipping loading of Miji.')
		else
			manageMiji('startStop','setupImageJ');
		end
	end
	loadMijiCheck = 0;

	if loadMijiCheck==0
		disp('Skipping loading of Miji.')
	elseif workerCheck==1
		disp('Inside MATLAB worker, do not load Miji.')
	elseif ~isempty(java.lang.System.getProperty('plugins.dir'))
		disp('Miji JAR files already loaded, skipping. If Miji issue, use "resetMiji".')
	else
		% add path for Miji, change as needed
		loadLocalFunctions = ['private' filesep 'settings' filesep 'privateLoadBatchFxns.m'];
		% First check for Fiji in _external_programs dir with path for this specific computer, since privateLoadBatchFxns might not generalize.
		fijiList = getFileList(externalProgramsDir,'(Fiji.app|fiji-.*-20151222(?!.zip|.dmg))');
		if ~isempty(fijiList)
			if ismac
				pathtoMiji = [fijiList{1} filesep 'scripts'];
			elseif isunix
				pathtoMiji = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
			elseif ispc
				pathtoMiji = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
			else
				pathtoMiji = [fijiList{1} filesep 'Fiji.app' filesep 'scripts'];
			end
			% pathtoMiji = [ciapkg.getDirExternalPrograms() filesep 'fiji-win64-20151222' filesep 'Fiji.app' filesep 'scripts'];

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

	function [pathListArray, findListFlag] = subfxnRemoveDirs(rmPathFlag,pathListArray)

		% Alternative to only keep certain external program directories
		% extDirKeep = {'matnwb','nwb_schnitzer_lab','yamlmatlab'};
		% externalProgramsDir
		% =================================================
		% List of functions in root of external program directories that should not be included by default.
		try
			fxnRootFolder = removeDirFxnToFind;
			pathToRmCell = {};
			findListFlag = [];
			matchIdxAll = [];
			for iNo = 1:length(fxnRootFolder)
				thisFxn = fxnRootFolder{iNo};

				fileLoc = which(thisFxn);
				if isempty(fileLoc)
					findListFlag(iNo) = 0;
				else
					findListFlag(iNo) = 1;
				end
				if rmPathFlag==1
					[pathToRm,~,~] = fileparts(fileLoc);
				else
					% extDir = dir([functionDir filesep externalProgramsDir]);
					extDir = dir([externalProgramsDir]);
					extDir = extDir([extDir.isdir]);
					if length(extDir)<3
						disp('No external programs!')
						return;
					end
					extDir = extDir(3:end);
					foundFiles = dir(fullfile([externalProgramsDir], ['**' filesep thisFxn '']));
					if isempty(foundFiles)
						pathToRm = [];
					else
						pathToRm = foundFiles.folder;
					end
				end

				if ~isempty(pathToRm)
					% extractor now in sub-directory
					if strcmp(thisFxn,'extractor.m')
						[pathToRm,~,~] = fileparts(pathToRm);
					end

					if strcmp(thisFxn,'CELLMax_Wrapper.m')|strcmp(thisFxn,'cellmax.runCELLMax')
						thisFxnStr = thisFxn;
						% pathToRm = [pathToRm filesep 'calciumImagingAnalysis'];
						% thisFxnStr  = [thisFxn ' | ' 'calciumImagingAnalysis'];
					else
						thisFxnStr = thisFxn;
					end
					matchIdx = contains(pathListArray,pathToRm);
					if rmPathFlag==1&any(matchIdx)==1
					% if rmPathFlag==1
						fprintf('Removing unneeded directory from path: %s.\n',thisFxnStr);
						% pathToRmCell{end+1} = pathToRm;
						pathToRmCell = [pathToRmCell{:} pathListArray(matchIdx)];
						% rmpath(pathToRm);
					elseif rmPathFlag==0
						fprintf('Removing unneeded directory from "to add" path list: %s.\n',thisFxnStr);
						% pathListArray = pathListArray(~matchIdx);
						if iNo==1
							matchIdxAll = ~matchIdx;
						else
							matchIdxAll = matchIdxAll|~matchIdx;
						end
					end
					% pathToRm
					% fprintf('Removing unneeded directory: %s.\n',pathListArray{matchIdx});
					% matchIdx
					% Remove from array so that it is not added to path later.
				end
			end

			if rmPathFlag==1
				% Only remove path if user requests
				rmpath(strjoin(pathToRmCell,pathsep));
			elseif rmPathFlag==0&~isempty(matchIdxAll)
				% Remove from list of folders to add to path
				pathListArray = pathListArray(~matchIdxAll);
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
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
	if verLessThan('matlab','9.1')
		matchIdx = ~cellfun(@isempty,regexpi(pathCell,thisRootPath));
		% pathListArray = pathListArray(pathFilter&pathFilter1&pathFilter2);
	else
		matchIdx = contains(pathCell,thisRootPath);
	end
	onPath = any(matchIdx);
end