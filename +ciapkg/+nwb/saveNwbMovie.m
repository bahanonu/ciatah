function [output1,output2] = saveNwbMovie(inputData,fileSavePath,varargin)
	% Saves input matrix into NWB format
	% Biafra Ahanonu
	% started: 2020.05.28 [09:51:52]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		% Add structure that allows users to modify defaults for all the NWB settings

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% old way of saving, only temporary until full switch
	options.datasetname = '/1';
	% HDF5: 'append' (don't blank HDF5 file) or 'new' (blank HDF5 file)
	options.writeMode = 'new';
	% save only a portion of the dataset, useful for large datasets
	% 3D matrix, [0 0 0] start and [x y z] end.
	options.hdfStart = [];
	options.hdfCount = [];
	% Int: Defines gzip compression level (0-9). 0 = no compression, 9 = most compression.
	options.deflateLevel = 0;
	% Struct: structure of information to add. Will create a HDF5 file
	options.addInfo = [];
	% Str: e.g. '/movie/processingSettings'
	options.addInfoName = '';
	% Int: chunk size in [x y z] of the dataset, leave empty for auto chunking
	options.dataDimsChunkCopy = [];
	% Str: description of imaging plane
	options.descriptionImagingPlane = 'NA';
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
		if strcmp(options.writeMode,'new')
			if exist(fileSavePath,'file')==2
				fprintf('Deleting: %s.\n',fileSavePath)
				delete(fileSavePath)
			end
		end

		options.descriptionImagingPlane
		nwb = NwbFile( ...
			'session_description', options.descriptionImagingPlane,...
			'identifier', 'NA', ...
			'session_start_time', datetime(1776, 07, 04, 0, 0, 0,'Format',"yyyy-MM-dd'T'HH:mm:ss.SSSSSS",'TimeZone',"UTC"), ... % optional
			'general_experimenter', 'NA', ... % optional
			'general_session_id', 'NA', ... % optional
			'general_institution', 'NA', ... % optional
			'general_related_publications', 'NA');

		% disp(nwb)
		% pause

		subject = types.core.Subject( ...
		    'subject_id', 'NA', ...
		    'age', 'NA', ...
		    'description', 'NA', ...
		    'species', 'Mus musculus', ...
		    'sex', 'M');

		nwb.general_subject = subject;

		optical_channel = types.core.OpticalChannel( ...
		    'description', options.descriptionImagingPlane, ...
		    'emission_lambda', 520.);
		device_name = 'Device';
		nwb.general_devices.set(device_name, types.core.Device());
		imaging_plane_name = 'imaging_plane';
		imaging_plane = types.core.ImagingPlane( ...
		    'optical_channel', optical_channel, ...
		    'description', options.descriptionImagingPlane, ...
		    'device', types.untyped.SoftLink(['/general/devices/' device_name]), ...
		    'excitation_lambda', 480., ...
		    'imaging_rate', 20., ...
		    'indicator', 'GFP', ...
		    'location', 'NA');
		nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);
		% we are going to need this later
		imaging_plane_path = ['/general/optophysiology/' imaging_plane_name];

		if ~ischar(inputData)
			disp('Adding matrix to NWB')
			image_series = types.core.TwoPhotonSeries( ...
			    'imaging_plane', types.untyped.SoftLink(imaging_plane_path), ...
			    'starting_time', 0.0, ...
			    'starting_time_rate', 3.0, ...
			    'data', inputData, ...
			    'data_unit', 'lumens');
			nwb.acquisition.set('TwoPhotonSeries', image_series);
		elseif ischar(inputData)
			[movieType, supported] = ciapkg.io.getMovieFileType(inputData);

			image_series = types.core.TwoPhotonSeries( ...
			    'external_file', inputData, ...
			    'imaging_plane', types.untyped.SoftLink(imaging_plane_path), ...
			    'external_file_starting_frame', 0, ...
			    'format', movieType, ...
			    'starting_time_rate', 3.0, ...
			    'starting_time', 0.0, ...
			    'data', NaN(2, 2, 2), ...
			    'data_unit', 'lumens');

			nwb.acquisition.set('TwoPhotonSeries2', image_series);
		end

		nwbExport(nwb, fileSavePath);

		% % add information about data to HDF5 file
		% if strcmp(options.writeMode,'new')
		% 	if isempty(options.hdfStart)
		% 		dataDims = size(inputData);
		% 		% [dim1 dim2 dim3] = size(inputData);
		% 	else
		% 		dataDims = options.hdfCount - options.hdfStart;
		% 	end

		% 	disp('Blanking HDF5!')
		% 	hdf5write(fileSavePath,'/movie/info/dimensions',dataDims,'WriteMode','append');
		% 	currentDateTimeStr = datestr(now,'yyyymmdd_HHMM','local');
		% 	hdf5write(fileSavePath,'/movie/info/date',currentDateTimeStr,'WriteMode','append');
		% 	hdf5write(fileSavePath,'/movie/info/savePath',fileSavePath,'WriteMode','append');
		% 	hdf5write(fileSavePath,'/movie/info/Deflate',options.deflateLevel,'WriteMode','append');
		% end

		if ~isempty(options.addInfo)
			if ~iscell(options.addInfo)
				options.addInfo = {options.addInfo};
				options.addInfoName = {options.addInfoName};
			end
			addInfoLen = length(options.addInfo);
			for addInfoStructNo = 1:addInfoLen
				thisAddInfo = options.addInfo{addInfoStructNo};
				infoList = fieldnames(thisAddInfo);
				nInfo = length(infoList);
				for fieldNameNo = 1:nInfo
					thisField = infoList{fieldNameNo};
					hdf5write(fileSavePath,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
					% h5write(fileSavePath,[options.addInfoName{addInfoStructNo} '/' thisField],thisAddInfo.(thisField),'WriteMode','append');
				end
			end
		end

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end