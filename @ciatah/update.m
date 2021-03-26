function obj = update(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	% Notify user if they are behind version-wise.
	ciapkg.io.updatePkg;
	uiwait(msgbox('The CIAtah GitHub website will open. Click "Clone or download" button to download most recent version of CIAtah.'))
	web(obj.githubUrl);
end