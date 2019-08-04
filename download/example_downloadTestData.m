function [success] = example_downloadTestData(varargin)
	% Biafra Ahanonu
	% Downloads example test data from Stanford Box
	% Started September 2018

	%========================
	options.downloadPreprocessed = 0;
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
		rawSavePathDownload = ['data' filesep '2014_04_01_p203_m19_check01_raw'];
		if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end

		rawSavePathDownload = [rawSavePathDownload filesep 'concat_recording_20140401_180333.h5'];
		if exist(rawSavePathDownload,'file')~=2
			fprintf('Downloading file to %s\n',rawSavePathDownload)
			websave(rawSavePathDownload,'https://stanford.box.com/shared/static/jmld9o9s0oemvn6oionr3lf9lwobqk9l.h5');
		else
			fprintf('Already downloaded %s\n',rawSavePathDownload)
		end

		if options.downloadPreprocessed==1
			rawSavePathDownload = ['data' filesep '2014_04_01_p203_m19_check01']
			if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end

			rawSavePathDownload = [rawSavePathDownload filesep '2014_04_01_p203_m19_check01_turboreg_crop_dfof_downsampleTime_1.h5'];
			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading file to %s\n',rawSavePathDownload)
				websave(rawSavePathDownload,'https://stanford.box.com/shared/static/0zasceqd7b9ea6pa4rsgx1ag1mpjwmrf.h5');
			end

			rawSavePathDownload = ['data' filesep '2014_04_01_p203_m19_check01' filesep '2014_04_01_p203_m19_check01_turboreg_crop_dfof_1.h5'];
			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading file to %s\n',rawSavePathDownload)
				websave(rawSavePathDownload,'https://stanford.box.com/shared/static/azabf70oky7vriek48pb98jt2c5upj5i.h5');
			end
		end
		success = 1;
	catch err
		success = 0;
		disp('Check internet connection or download files manually, see *data* folder')
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end