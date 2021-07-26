function obj = setup(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	uiwait(ciapkg.overloaded.msgbox(['CIAtah setup will:' 10 '1 - check and download dependencies as needed,' 10 '2 - then ask for a list of folders to include for analysis,' 10 '3 - and finally name for movie files to look for.' 10 10 'Press OK to continue.'],'Note to user','modal'));

	% Download and load dependent software packages into "_external_programs" folder.
	% Also download test data into "data" folder.
	obj.loadDependencies;
	disp('Finished loading dependencies, now choose folders to add...');

	% Add folders containing imaging data.
	obj.modelAddNewFolders;

	% [optional] Set the names calciumImagingAnalysis will look for in each folder
	obj.setMovieInfo;
end