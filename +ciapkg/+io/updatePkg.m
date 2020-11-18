function [success] = updatePkg(varargin)
	% Checks ciapkg version against GitHub repo and updates `ciapkg` and `+ciapkg` folders.
	% Biafra Ahanonu
	% started: 2020.08.18 [‏‎11:16:56]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% Char cell array: list of directories to remove then update, lead private, _external_programs, and data directories intact.
	options.removeDirs = {...
		'@calciumImagingAnalysis',...
		'+ciapkg',...
		'ciapkg',...
		'docs',...
		'file_exchange'};
	% Char: GitHub API URL to VERSION file on CIAPKG repository.
	options.versionURL = 'https://api.github.com/repos/bahanonu/calciumImagingAnalysis/contents/ciapkg/VERSION';
	% Binary: 1 = pop-up GUI enabled
	options.showGui = 1;
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

		% Get online CIAPKG version
		onlineVersion = ciapkg.versionOnline;
		% Get local CIAPKG version
		currentVersion = ciapkg.version;
		% currentVersion = 'v3.19.20201021135616'
		% currentVersion = 'v3.20.20201019131033';

		% Compare to see if running an old version.
		verCompare = subfxn_verCompare(currentVersion,onlineVersion);

		if verCompare==1
			verInfoStr = 'Running most up-to-date version!';
		elseif verCompare<1
			verInfoStr = 'Running behind! Initiating update.';
		elseif verCompare>1
			verInfoStr = 'I do not know how, but you are running ahead! [Dev build]';
		end

		disp(verInfoStr)
		if options.showGui==1
			uiwait(msgbox(verInfoStr));
		end

		% If the user is behind, ask if they want to update then initiate download and update from online repository
		if verCompare<1
			% Get a list of directories to remove, make sure


			% Confirm with the user

			% rmdir
			% nFolders = length(options.removeDirs);

			% for folderNo = 1:nFolders
			% end
		end
		success = 1;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	function [verCompare,compareVector] = subfxn_verCompare(verId1,verId2)
		fprintf('Comparing\nLocal:  %s.\nOnline: %s.\n',verId1,verId2);
		% Remove version tag
		verId1 = strrep(verId1,'v','');
		verId2 = strrep(verId2,'v','');

		% Compare two versions assuming major.minor.patch.build where in each the numbers always increment in a positive manner.
		verId1 = cellfun(@(x) str2num(x),strsplit(verId1,'.'));
		verId2 = cellfun(@(x) str2num(x),strsplit(verId2,'.'));
		compareVector = zeros([1 max(length(verId1),length(verId2))]);
		nLevels = length(compareVector)

		% Start at the highest level and only continue comparing while version 2 is greater than or equal to version 1.
		lockOut = 0; % 1 = higher level is an old version, so only calculate version difference
		for verLvl = 1:nLevels
			compareVector(verLvl) = verId1(verLvl) - verId2(verLvl);
			if compareVector(verLvl)<0 & lockOut==0 % This level indicates an old version
				verCompare = 0;
				lockOut = 1;
			end
		end

		% User is running the same exact version.
		if sum(compareVector)==0
			verCompare = 1;
		end

		% If user is running ahead, should only occur in development builds.
		if sum(compareVector)>0
			verCompare = 2;
		end
		disp(compareVector)
	end
end