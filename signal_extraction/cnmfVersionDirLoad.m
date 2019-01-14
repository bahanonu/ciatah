function [success] = cnmfVersionDirLoad(cnmfVersion,varargin)
	% Allow switching between CNMF versions by loading the correct repository directory.
	% Biafra Ahanonu
	% started: 2018.10.20
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% Relative path assumed for batch_processing package
	options.signalExtractionRootPath = 'signal_extraction';
	% Binary: 1 = display paths to be added or removed
	options.displayOutput = 1;
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

		originalPath = [options.signalExtractionRootPath filesep 'cnmf_original'];
		currentPath = [options.signalExtractionRootPath filesep 'cnmf_current'];
		cnmfePath = [options.signalExtractionRootPath filesep 'cnmfe'];

		switch cnmfVersion
			case 'original'
				% Add and remove necessary CNMF directories from path
				subfxnRemovePathHere({currentPath,cnmfePath},options);

				fprintf('Add %s\n',originalPath);
				addpath(genpath(originalPath));
			case 'current'
				% Add and remove necessary CNMF directories from path
				subfxnRemovePathHere({originalPath,cnmfePath},options);

				fprintf('Add %s\n',currentPath);
				addpath(genpath(currentPath));
			case 'cnmfe'
				% Add and remove necessary CNMF directories from path
				subfxnRemovePathHere({currentPath,originalPath},options);

				fprintf('Add %s\n',cnmfePath);
				addpath(genpath(cnmfePath));
			case 'none'
				disp('Removing all CNMF dir from path')
				% Add and remove necessary CNMF directories from path
				subfxnRemovePathHere({currentPath,originalPath,cnmfePath},options);
			otherwise
				% do nothing
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
function subfxnRemovePathHere(listOfRootPaths,options)
	for pathNo = 1:length(listOfRootPaths)
		thisRootPath = listOfRootPaths{pathNo};
		pathCell = regexp(path, pathsep, 'split');
		matchIdx = contains(pathCell,thisRootPath);
	  	onPath = any(matchIdx);
		% if ispc  % Windows is not case-sensitive
		%   onPath = any(contains(pathCell,thisRootPath));
		% else
		%   onPath = any(contains(pathCell,thisRootPath));
		% end
		% onPath
		if onPath==1
			rmPaths = join(pathCell(matchIdx),pathsep);
			if options.displayOutput==1
				disp(rmPaths);
			end
			fprintf('Found in path, removing %s\n',thisRootPath);
			% genpath(thisRootPath)
			rmpath(rmPaths{1});
		end
	end
end