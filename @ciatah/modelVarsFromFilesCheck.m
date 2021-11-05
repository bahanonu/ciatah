function obj = modelVarsFromFilesCheck(obj,folderNo,varargin)
	% Checks whether a specific folder has variables loaded, if not loads them.
	% Biafra Ahanonu
	% started: 2021.06.18 [20:25:49]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.06.21 [21:03:42] - Add check for objLocations
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% ========================
	% DESCRIPTION
	options.baseOption = '';
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
		try
			max(1,round(obj.objLocations{folderNo}.(obj.signalExtractionMethod)(:,1)));
			[rawSignals rawImages signalPeaks signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
			% obj.nSignals{fileNum}
			skipReload = 1;
		catch
			obj.guiEnabled = 0;
			% originalFileNum = 
            oldTmp = obj.foldersToAnalyze;
            obj.foldersToAnalyze = folderNo;
			obj.modelVarsFromFiles();
            obj.foldersToAnalyze = oldTmp;
			obj.fileNum = folderNo;
			obj.guiEnabled = 1;
			skipReload = 0;
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end