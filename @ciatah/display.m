function obj = display(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	% Overload display method so can run object by just typing 'obj' in command window.
	obj.runPipeline;
	% display('hello');
end