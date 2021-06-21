function obj = modelVarsFromFilesCheck(obj,folderNo,varargin)
	% Checks whether a specific folder has variables loaded, if not loads them.
	% Biafra Ahanonu
	% started: 2021.06.18 [20:25:49]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%


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
			[rawSignals rawImages signalPeaks signalPeaksArray, ~, ~, rawSignals2] = modelGetSignalsImages(obj,'returnType','raw');
			% obj.nSignals{fileNum}
			skipReload = 1;
		catch
			obj.guiEnabled = 0;
			% originalFileNum = 
			obj.modelVarsFromFiles();
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