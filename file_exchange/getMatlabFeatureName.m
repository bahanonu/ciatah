function OUT = getMatlabFeatureName(fullname)
	% getFeatureName - translates a toolbox name from 'ver' into
	% a feature name and vice versa, also checks license availability
	%
	% Syntax:
	%   getFeatureName(fullname)
	%
	% Inputs:
	%   fullname:       character vector of toolbox name as listed in ver
	%                   output (optional, if none given all features are
	%                   listed)
	%
	% Outputs:
	%   translation:    cell array with clear name, feature name and license
	%                   availability
	%
	%-------------------------------------------------------------------------
	% https://www.mathworks.com/matlabcentral/answers/377731-how-do-features-from-license-correspond-to-names-from-ver
	% Version 1.1
	% 2018.09.04        Julian Hapke
	% 2020.05.05        checks all features known to current release
	% 2020.06.05		Biafra - added check that Toolbox is avaliable/installed.
	%-------------------------------------------------------------------------
	assert(nargin < 2, 'Too many input arguments')
	% defaults
	checkAll = true;
	installedOnly = false;
	if nargin
	  checkAll = false;
	  installedOnly = strcmp(fullname, '-installed');
	end
	listInstalledToolboxes = ver;
	if checkAll || installedOnly
		allToolboxes = com.mathworks.product.util.ProductIdentifier.values;
		nToolboxes = numel(allToolboxes);
		out = cell(nToolboxes, 3);
		for iToolbox = 1:nToolboxes
		  marketingName = char(allToolboxes(iToolbox).getName());
		  flexName = char(allToolboxes(iToolbox).getFlexName());
		  out{iToolbox, 1} = marketingName;
		  out{iToolbox, 2} = flexName;
		  out{iToolbox, 3} = license('test', flexName);
		  out{iToolbox, 4} = any(strcmp({listInstalledToolboxes.Name}, marketingName));
		end
		if installedOnly
		  installedToolboxes = ver;
		  installedToolboxes = {installedToolboxes.Name}';
		  out = out(ismember(out(:,1), installedToolboxes),:);
		end
		if nargout
			OUT = out;
		else
			out = [{'Name', 'FlexLM Name', 'License Available'}; out];
			disp(out)
		end
	else
		productidentifier = com.mathworks.product.util.ProductIdentifier.get(fullname);
		if (isempty(productidentifier))
			warning('"%s" not found.', fullname)
			OUT = cell(1,4);
			return
		end
		feature = char(productidentifier.getFlexName());
		marketingName = char(productidentifier.getName());
		OUT = [...
			{marketingName} ...
			{feature} ...
			{license('test', feature)} ...
			{any(strcmp({listInstalledToolboxes.Name}, marketingName))}];
	end
end