function obj = resetMijiClass(obj)
	% This clears Miji from Java's dynamic path and then re-initializes. Use if Miji is not loading normally.
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	resetMiji
	% success = 0;

	% for i = 1:2
	% 	try
	% 		% clear MIJ miji Miji mij;
	% 		javaDyna = javaclasspath('-dynamic');
	% 		matchIdx = ~cellfun(@isempty,regexpi(javaDyna,'Fiji'));
	% 		% cellfun(@(x) javarmpath(x),javaDyna(matchIdx));
	% 		javaDynaPathStr = join(javaDyna(matchIdx),''',''');
	% 		if ~isempty(javaDynaPathStr)
	% 			eval(sprintf('javarmpath(''%s'');',javaDynaPathStr{1}))
	% 		end
	% 		clear MIJ miji Miji mij;
	% 		% pause(1);
	% 		% java.lang.Runtime.getRuntime().gc;
	% 		% Miji;
	% 		% MIJ.exit;
	% 	catch err
	% 		disp(repmat('@',1,7))
	% 		disp(getReport(err,'extended','hyperlinks','on'));
	% 		disp(repmat('@',1,7))
	% 	end
	% end

	% success = 1;
end