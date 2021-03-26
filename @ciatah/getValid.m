function valid = getValid(obj,validType)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	try
		fprintf('Getting %s identifications...\n',validType)
		obj.valid{obj.fileNum}.(obj.signalExtractionMethod).(validType);
		valid = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).(validType);
	catch
		valid=[];
	end
end