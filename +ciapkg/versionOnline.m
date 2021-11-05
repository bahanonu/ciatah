function [onlineVersion, dateTimeStr] = versionOnline(varargin)
	% Obtains the online repository version.
	% Biafra Ahanonu
	% started: 2020.08.18 [‏‎11:16:56]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.02.02 [13:42:19] - Updated to handle new VERSION file that includes datestamp on 2nd line.
		% 2021.03.21 [17:41:54] - Update VERSION path.
		% 2021.03.25 [23:18:06] - Now checks multiple location of VERSION file to future proof in case it is moved.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Char: GitHub API URL to VERSION file on CIAPKG repository.
		% https://raw.githubusercontent.com/bahanonu/calciumImagingAnalysis/master
	options.versionURL = {'https://api.github.com/repos/bahanonu/calciumImagingAnalysis/contents/+ciapkg/VERSION','https://api.github.com/repos/bahanonu/calciumImagingAnalysis/contents/ciapkg/VERSION','https://api.github.com/repos/bahanonu/calciumImagingAnalysis/contents/VERSION'};
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
		onlineVersion = '';
		dateTimeStr = '';

		if iscell(options.versionURL)

		elseif ischar(options.versionURL)
			options.versionURL = {options.versionURL};
		else
			disp('Incorrect version URL')
			return;
		end

		nChecks = length(options.versionURL);

		for checkNo = 1:nChecks
			% Get version information online
			% Get information about specific version file online using GitHub API
			[versionInfo, status] = urlread(options.versionURL{checkNo},'Timeout',options.timeOutSec);
			% [versionInfo, status] = webread(options.versionURL,'Timeout',options.timeOutSec);
			if status==1
				versionInfo = jsondecode(versionInfo);
				[onlineVersion, status] = urlread(versionInfo.download_url,'Timeout',options.timeOutSec);
				% [onlineVersion, status] = webread(versionInfo.download_url,'Timeout',options.timeOutSec);
				if status==0
					disp('Could not dowload CIAPKG version information.')
					return;
				end
				if ~isempty(regexp(onlineVersion,'\n'))
					onlineVersionTmp = strsplit(onlineVersion,'\n');
					onlineVersion = onlineVersionTmp{1};
					dateTimeStr = onlineVersionTmp{2};
				end
				disp(['URL #' num2str(checkNo)])
				% Stop early
				break
			end
		end

		success = 1;
	catch err
		onlineVersion = '';
		dateTimeStr = '';
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end