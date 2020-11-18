function [onlineVersion] = versionOnline(varargin)
	% Obtains the online repository version.
	% Biafra Ahanonu
	% started: 2020.08.18 [‏‎11:16:56]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% Char: GitHub API URL to VERSION file on CIAPKG repository.
	options.versionURL = 'https://api.github.com/repos/bahanonu/calciumImagingAnalysis/contents/ciapkg/VERSION';
	% Int: time in second before urlread function errors due to timeout
	options.timeOutSec = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		success = 0;

		% Get version information online
		% Get information about specific version file online using GitHub API
		[versionInfo, status] = urlread(options.versionURL,'Timeout',options.timeOutSec);
		if status==1
			versionInfo = jsondecode(versionInfo);
			[onlineVersion, status] = urlread(versionInfo.download_url,'Timeout',options.timeOutSec);
			if status==0
				disp('Could not dowload CIAPKG version information.')
				return;
			end
		end
		
		success = 1;
	catch err
		onlineVersion = '';
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end