function obj = showProtocolSubjectsSessions(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	protocolList = unique(obj.protocol);
	for i = 1:length(protocolList)
		protocolStr = protocolList{i};
		subjectList = obj.subjectStr(strcmp(protocolStr,obj.protocol));
		fprintf('Protocol %s | %d subjects | %d sessions\n',protocolStr,length(unique(subjectList)),length(subjectList))
		% disp([num2str(i) ' | ' obj.inputFolders{i}])
	end
end