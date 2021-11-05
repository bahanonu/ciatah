function [success] = resetMiji(varargin)
	% This clears Miji from Java's dynamic path and then re-initializes. Use if Miji is not loading normally.
	% Biafra Ahanonu
	% started: 2019.01.28 [14:34:14]
	% inputs
		%
	% outputs
		%
	% usage
		% % Run the following commands one at a time in the command window.
		% resetMiji
		% % An instance of Miji should appear.
		% currP=pwd;Miji;cd(currP);
		% MIJ.exit

	% changelog
		% 2019.09.09 [18:04:10] - Updated to add fallback to modelAddOutsideDependencies to ask for path to Fiji/Miji in case it is not properly in the path or has been moved.
		% 2019.10.15 [12:29:30] - Added flag to prevent recursive loop between resetMiji and modelAddOutsideDependencies.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% DESCRIPTION
	options.nRounds = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% try
	success = 0;

	for i = 1:options.nRounds
		try
			clear MIJ miji Miji mij;
			javaDyna = javaclasspath('-dynamic');
			matchIdx = ~cellfun(@isempty,regexpi(javaDyna,'Fiji'));
			% cellfun(@(x) javarmpath(x),javaDyna(matchIdx));
			javaDynaPathStr = join(javaDyna(matchIdx),''',''');
			if ~isempty(javaDynaPathStr)
				eval(sprintf('javarmpath(''%s'');',javaDynaPathStr{1}))
			else
				disp('Empty Java dynamic path!')
			end
			clear MIJ miji Miji mij;
			% Load Miji so paths added to javaclasspath('-dynamic')
			currP=pwd;
			% Miji;
			Miji(false);
			cd(currP);
			MIJ.exit;
			% pause(1);
			% java.lang.Runtime.getRuntime().gc;
			% Miji;
			% MIJ.exit;
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))

			try
				modelAddOutsideDependencies('miji','recursionExit',1);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end

	success = 1;
	% catch err
	% 	success = 0;
	% 	display(repmat('@',1,7))
	% 	disp(getReport(err,'extended','hyperlinks','on'));
	% 	display(repmat('@',1,7))
	% end
end