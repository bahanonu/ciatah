function [success] = example_downloadTestData(varargin)
	% Downloads example test data from Stanford Box
	% Biafra Ahanonu
	% started: September 2018
	% inputs
		%
	% outputs
		%

	% changelog
		% 2019.09.16 [13:03:33] - Added three new imaging sessions to use for cross-day alignment and made downloading more generalized.
	% TODO
		%

	%========================
	options.downloadPreprocessed = 0;
	% Download extra files
	options.downloadExtraFiles = 1;
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
		downloadList = {};
		% downloadList{end+1}.folderName
		% downloadList{end}.fileName
		% downloadList{end}.fileUrl
		% downloadList{end}.metaFile

		downloadList{end+1}.folderName = '2014_04_01_p203_m19_check01_raw';
		downloadList{end}.fileName = 'concat_recording_20140401_180333.h5';
		downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/jmld9o9s0oemvn6oionr3lf9lwobqk9l.h5';
		% downloadList{end}.metaFile = '';

		if options.downloadExtraFiles==1
			% downloadList{end+1}.folderName = ['batch' filesep '2014_07_31_p104_m80_PAV03'];
			% downloadList{end}.fileName = 'concat_recording_20140731_105559.h5';
			% downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/ddgy2zq3as9l3paifd1hltpojk93x9oa.h5';
			% % downloadList{end}.metaFile = 'https://stanford.box.com/shared/static/6qs3dt593uud314ins8qnxrnuj9sdm87.txt';

			% downloadList{end+1}.folderName = ['batch' filesep '2014_08_05_p104_m80_PAV04'];
			% downloadList{end}.fileName = 'concat_recording_20140805_180816.h5';
			% downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/psm56avve4gt3tquc88r7fri2xda9woe.h5';
			% % downloadList{end}.metaFile = 'https://stanford.box.com/shared/static/gf7agxqvp3ks0mr0ovy54t067agdp4tf.txt';

			% downloadList{end+1}.folderName = ['batch' filesep '2014_08_06_p104_m80_PAV05'];
			% downloadList{end}.fileName = 'concat_recording_20140806_104210.h5';
			% downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/ae8qcmkxcv8ax7g1yfs9qjp010gqyip3.h5';
			% % downloadList{end}.metaFile = 'https://stanford.box.com/shared/static/ja18hyade4jmh6czw0vxpxosiu3i9j9e.txt';

			downloadList{end+1}.folderName = ['batch' filesep '2014_08_05_p104_m19_PAV08'];
			downloadList{end}.fileName = 'concat_recording_20140805_162046.h5';
			downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/iv3v3iqmji7fd5lvdcere8q6tlb008vb.h5';

			downloadList{end+1}.folderName = ['batch' filesep '2014_08_06_p104_m19_PAV09'];
			downloadList{end}.fileName = 'concat_recording_20140806_103546.h5';
			downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/vyj69a7u2ay9uva9fbsyp34d8kvcvclw.h5';

			downloadList{end+1}.folderName = ['batch' filesep '2014_08_07_p104_m19_PAV10'];
			downloadList{end}.fileName = 'concat_recording_20140807_102507.h5';
			downloadList{end}.fileUrl = 'https://stanford.box.com/shared/static/xmhgqx3atceq8f0zwqdctegiqo2d71su.h5';
		end
		nFiles = length(downloadList);

		for fileNo = 1:nFiles
			fileInfo = downloadList{fileNo};
			rawSavePathDownload = ['data' filesep fileInfo.folderName];
			if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s\n',rawSavePathDownload);end

			rawSavePathDownload = [rawSavePathDownload filesep fileInfo.fileName];
			if exist(rawSavePathDownload,'file')~=2
				fprintf('Downloading file to %s\n',rawSavePathDownload)
				websave(rawSavePathDownload,fileInfo.fileUrl);
			else
				fprintf('Already downloaded %s\n',rawSavePathDownload)
			end

			% rawSavePathDownload = [rawSavePathDownload filesep fileInfo.metaFile];
			% if exist(rawSavePathDownload,'file')~=2
			% 	fprintf('Downloading file to %s\n',rawSavePathDownload)
			% 	websave(rawSavePathDownload,fileInfo.metaFile);
			% else
			% 	fprintf('Already downloaded %s\n',rawSavePathDownload)
			% end
		end

		% rawSavePathDownload = ['data' filesep '2014_04_01_p203_m19_check01_raw'];
		% if ~exist(rawSavePathDownload,'dir');mkdir(rawSavePathDownload);fprintf('Made folder: %s',rawSavePathDownload);end

		% rawSavePathDownload = [rawSavePathDownload filesep 'concat_recording_20140401_180333.h5'];
		% if exist(rawSavePathDownload,'file')~=2
		% 	fprintf('Downloading file to %s\n',rawSavePathDownload)
		% 	websave(rawSavePathDownload,'https://stanford.box.com/shared/static/jmld9o9s0oemvn6oionr3lf9lwobqk9l.h5');
		% else
		% 	fprintf('Already downloaded %s\n',rawSavePathDownload)
		% end

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

		% disp('Copy and paste the below folder')

		success = 1;
	catch err
		success = 0;
		disp('Check internet connection or download files manually, see *data* folder')
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end