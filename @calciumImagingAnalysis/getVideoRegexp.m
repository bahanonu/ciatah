function obj = getVideoRegexp(obj)
	% Internal function to get user imaging preprocessing settings
	% Biafra Ahanonu
	% started: 2017.04.17 [15:08:00]
	% inputs
	    %
	% outputs
	    %

	% changelog
	    %
	% TODO
	    %

	switch videoTrialRegExpIdx
		case 1
			videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum} '.*' videoCameraId];
		case 2
			% videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			dateTmp = strsplit(obj.date{obj.fileNum},'_');
			videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
		case 3
			videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
		otherwise
			videoTrialRegExp = fileFilterRegexp
	end
end