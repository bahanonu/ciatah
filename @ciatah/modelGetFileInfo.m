function obj = modelGetFileInfo(obj)
	% Get information for each folder
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	obj.inputFolders = obj.dataPath;
	for i=1:length(obj.dataPath)
		fileInfo = getFileInfo(obj.dataPath{i},'subjectRegexp',obj.subjectRegexp);
		% fileInfo
		obj.subjectStr{i} = fileInfo.subject;
		obj.subjectNum{i} = fileInfo.subjectNum;
		obj.subjectProtocolStr{i} = [fileInfo.protocol '_' fileInfo.subject];
		obj.assay{i} = fileInfo.assay;
		obj.protocol{i} = fileInfo.protocol;
		obj.assayType{i} = fileInfo.assayType;
		obj.assayNum{i} = fileInfo.assayNum;
		obj.imagingPlane{i} = fileInfo.imagingPlane;
		obj.imagingPlaneNum{i} = fileInfo.imagingPlaneNum;
		obj.date{i} = fileInfo.date;
		obj.fileIDArray{i} = strcat(obj.subjectStr{i},'_',obj.assay{i});
		obj.fileIDNameArray{i} = char([obj.subjectStr{i},' ',obj.assay{i}]);
		obj.folderBaseSaveStr{i} = strcat(fileInfo.date,'_',fileInfo.protocol,'_',fileInfo.subject,'_',fileInfo.assay);
		obj.folderBasePlaneSaveStr{i} = strcat(fileInfo.date,'_',fileInfo.protocol,'_',fileInfo.subject,'_',fileInfo.assay,'_',fileInfo.imagingPlane);
		obj.folderBaseDisplayStr{i} = strrep(obj.folderBaseSaveStr{i},'_',' ');

		obj.folderBaseSaveStrUnique{i} = strcat(fileInfo.date,'_',fileInfo.protocol,'_',fileInfo.subject,'_',fileInfo.assay,'_',datestr(now,'yyyymmdd_HHMMSSFFF','local'));
		pause(0.001)
	end
end