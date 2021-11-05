function viewVennDiagram(circleAreas,overlapAreas,totalArea,varargin)
	% Makes Venn diagram plot.
	% Biafra Ahanonu
	% originally started: 2017.03.08 [22:29:33]
		% branched 2018.04.28 [15:50:00], taken from older calciumImagingAnalysis method.
	% inputs
		% circleAreas
			% A [c1 c2 c3] integer or float vector containing the areas for each of the three circles, leave c3 blank if only two circles.
		% overlapAreas
			 % [i12 i13 i23 i123] integer or float containing intersect area of indicated circles, e.g. i12 is interspect of circles 1 and 2 or i123 is the insersect of circles 1, 2, and 3. Only input i12 if only two circles are used for circleAreas.
	% outputs
		% None, only plotting.

	ciapkg.view.viewVennDiagram(circleAreas,overlapAreas,totalArea,'passArgs', varargin);
end