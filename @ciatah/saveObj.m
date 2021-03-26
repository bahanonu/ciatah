function obj = saveObj(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	if isempty(obj.objSaveLocation)
		[filePath,folderPath,~] = uiputfile('*.*','select folder to save object mat file to','CIAtah_properties.mat');
		% exit if user picks nothing
		% if folderListInfo==0; return; end
		savePath = [folderPath filesep filePath];
		% tmpObj = obj;
		% obj = struct(obj);
		obj.objSaveLocation = savePath;
	else
		savePath = obj.objSaveLocation;
	end
	disp(['saving to: ' savePath])
	try
	  save(savePath,'obj','-v7.3');
	catch
	  disp('Problem saving, choose new location...')
	  obj.objSaveLocation = [];
	  obj.saveObj();
	end
	% obj = tmpObj;
end