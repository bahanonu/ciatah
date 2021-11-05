function obj = modelSaveMatchObjBtwnTrials(obj,varargin)
	% Allow users to export output from computeMatchObjBtwnTrials.
	% Biafra Ahanonu
	% started: 2019.04.22 [‏‎08:41:24]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.06.29 [19:28:33] - Updated implementation.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
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
	%========================

	try
		disp('Method not implemented!')

		[filePath,folderPath,~] = uiputfile('*.*','select folder to save object mat file to','calciumImagingAnalysis_properties.mat');
		% exit if user picks nothing
		% if folderListInfo==0; return; end
		savePath = [folderPath filesep filePath];

		subjList = fieldnames(obj.globalIDStruct);
		for subjNo = 1:length(subjList)
			thisSubjectStr = subjList{subjNo};
			alignmentStruct = obj.globalIDStruct.(thisSubjectStr);

			structSavePath = [obj.dataSavePath filesep 'ciapkg_crossSessionAlignment_' thisSubjectStr '_' datestr(now,'yyyymmdd_HHMMSS','local') '.mat'];
			fprintf('Saving to: %s\n',structSavePath)
			save(structSavePath,'alignmentStruct','-v7.3');
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end