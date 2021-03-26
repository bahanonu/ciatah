function obj = GetSize(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	props = properties(obj);
	totSize = 0;
	for ii=1:length(props)
		currentProperty = getfield(obj, char(props(ii)));
		s = whos('currentProperty');
		totSize = totSize + s.bytes;
	end
	fprintf(1, '%d bytes\n', totSize);
end