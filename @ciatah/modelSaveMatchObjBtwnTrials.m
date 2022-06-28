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
		% 2022.06.27 [19:25:42] - Remove user selecting folder to save structure to and add additional instructions.
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
		% disp('Method not implemented!')

		% [filePath,folderPath,~] = uiputfile('*.*','select folder to save object mat file to','calciumImagingAnalysis_properties.mat');
		% exit if user picks nothing
		% if folderListInfo==0; return; end
		% savePath = [folderPath filesep filePath];

		disp('Saving MAT-file for each subject (animal) containing structure. Global ID matrix [globalID sessionID] is found in <strong>alignmentStruct</strong> variable and fieldname <strong>alignmentStruct.globalIDs</strong>.')
		disp('See additional details at <a href="https://bahanonu.github.io/ciatah/pipeline_detailed_cross_session/#output-of-computematchobjbtwntrials">https://bahanonu.github.io/ciatah/pipeline_detailed_cross_session/#output-of-computematchobjbtwntrials</a>.')
		subjList = fieldnames(obj.globalIDStruct);
		for subjNo = 1:length(subjList)
			display(repmat('=',1,7))
			thisSubjectStr = subjList{subjNo};
			alignmentStruct = obj.globalIDStruct.(thisSubjectStr);

			fprintf('Saving cross-session alignment for subject/animal: <strong>%s</strong>.\n',thisSubjectStr);
			saveFileName = ['ciapkg_crossSessionAlignment_' thisSubjectStr '_' datestr(now,'yyyymmdd_HHMMSS','local') '.mat'];
			structSavePath = fullfile(obj.dataSavePath,saveFileName);
			fprintf('Saving to: %s\n',structSavePath)
			save(structSavePath,'alignmentStruct','-v7.3');
		end

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end