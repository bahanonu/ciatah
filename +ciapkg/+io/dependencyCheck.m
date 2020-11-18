function [outputTable] = dependencyCheck(varargin)
	% Check whether a MATLAB toolbox/feature has a license available and is installed.
	% Biafra Ahanonu
	% started: 2020.06.05 [11:23:53] - branch from initializeObj
	% inputs
		% Variable, see "options" structure below.
	% outputs
		% outputTable - table containing 5 variables: 'Toolbox','ToolboxName','License','Installed','Mismatch'. Mismatch indicates whether license and installed rows do not match.
	% Usage
		% [outputTable] = matlabToolboxCheck();

	% changelog
		% 2020.06.23 [15:46:04] - Updated for GitHub repository and added ability to check for all possible toolboxes.
	% TODO
		%

	try
		outputTable = ciapkg.io.matlabToolboxCheck('passArgs',varargin);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	% %========================
	% % Str: 'user' display only user toolboxes, 'all' display all toolboxes.
	% options.dispType = 'user';

	% % Binary: 1 = display output, 0 = do not display output
	% options.dispOutput = 1;

	% % Cell array of str: Essential toolboxes
	% options.toolboxList = {...
	% 	'distrib_computing_toolbox',...
	% 	'image_toolbox',...
	% 	'signal_toolbox',...
	% 	'statistics_toolbox',...
	% 	};

	% % Cell array of str: Not essential for core function, but nice to have
	% options.secondaryToolboxList = {...
	% 	'video_and_image_blockset',...
	% 	'bioinformatics_toolbox',...
	% 	'financial_toolbox',...
	% 	'neural_network_toolbox',...
	% };

	% % Name of your software package
	% options.softwarePackage = 'calciumImagingAnalysis';

	% % get options
	% options = getOptions(options,varargin);
	% % display(options)
	% % unpack options into current workspace
	% % fn=fieldnames(options);
	% % for i=1:length(fn)
	% % 	eval([fn{i} '=options.' fn{i} ';']);
	% % end
	% %========================

	% try
	% 	% Create output table
	% 	outputTable = table({''},{''},0,0,0,'VariableNames',{'Toolbox','ToolboxName','License','Installed','Mismatch'});

	% 	% Get list of toolboxes to check.
	% 	toolboxList = options.toolboxList;
	% 	secondaryToolboxList = options.secondaryToolboxList;
	% 	allTollboxList = {toolboxList,secondaryToolboxList};

	% 	% If user wants all features, given
	% 	if strcmp(options.dispType,'all')
	% 		allTollboxList = {com.mathworks.product.util.ProductIdentifier.values};
	% 		allToolboxSwitch = 1;
	% 	else
	% 		allToolboxSwitch = 0;
	% 	end

	% 	if ~isempty(options.softwarePackage)
	% 		options.softwarePackage = [' ' options.softwarePackage];
	% 	end

	% 	nLists = length(allTollboxList);
	% 	listInstalledToolboxes = ver;
	% 	warning('off','backtrace')
	% 	for listNo = 1:nLists
	% 		toolboxListHere = allTollboxList{listNo};
	% 		if isempty(toolboxListHere)
	% 			continue;
	% 		end

	% 		nToolboxes = length(toolboxListHere);

	% 		if allToolboxSwitch==0
	% 			if listNo==1
	% 				subfxnDisp('Required toolboxes (if warning appears, fix or install requested toolbox).');
	% 			else
	% 				subfxnDisp(' ');
	% 				subfxnDisp('2nd tier toolbox check (not required for main pre-processing pipeline).');
	% 			end
	% 		elseif allToolboxSwitch==1
	% 			subfxnDisp('Listing all toolboxes.')
	% 		end

	% 		for toolboxNo = 1:nToolboxes
	% 			if allToolboxSwitch==0
	% 				toolboxName = toolboxListHere{toolboxNo};

	% 				% Get product identifier if user inputs either name identifier
	% 				productidentifier = com.mathworks.product.util.ProductIdentifier.get(toolboxName);
	% 			elseif allToolboxSwitch==1
	% 				productidentifier = toolboxListHere(toolboxNo);
	% 			end

	% 			flexName = char(productidentifier.getFlexName);
	% 			humanName = char(productidentifier.getName);

	% 			% Check if toolbox license is available
	% 			licenseSwitch = license('test',flexName);

	% 			% Check which toolboxes are installed.
	% 			toolboxSwitch = any(strcmp({listInstalledToolboxes.Name}, humanName));

	% 			outputTable = [outputTable; {flexName,humanName,licenseSwitch,toolboxSwitch,licenseSwitch~=toolboxSwitch}];

	% 			if licenseSwitch==1&toolboxSwitch==1
	% 				if options.dispOutput==1
	% 					fprintf('Toolbox license available and toolbox is installed! %s (%s).\n',humanName,flexName)
	% 				end
	% 			elseif licenseSwitch==1&toolboxSwitch==0
	% 				if options.dispOutput==1
	% 					warning('Toolbox license available but toolbox is NOT installed. %s (%s).',humanName,flexName)
	% 				end
	% 			else
	% 				if listNo==1
	% 					if options.dispOutput==1
	% 						warning('Please obtain license and install %s (%s) toolbox before running%s. This toolbox is likely required.',humanName,flexName,options.softwarePackage);
	% 					end
	% 				else
	% 					if options.dispOutput==1
	% 						warning('Please obtain license and install %s (%s) toolbox before running%s. Some features may not work otherwise.',humanName,flexName,options.softwarePackage);
	% 					end
	% 				end
	% 			end
	% 		end
	% 	end
	% 	outputTable = outputTable(2:end,:);
	% 	warning('on','backtrace')
	% catch err
	% 	warning('on','backtrace')
	% 	disp(repmat('@',1,7))
	% 	disp(getReport(err,'extended','hyperlinks','on'));
	% 	disp(repmat('@',1,7))
	% end
	% function subfxnDisp(inputStr)
	% 	if options.dispOutput==1
	% 		disp(inputStr)
	% 	end
	% end
end