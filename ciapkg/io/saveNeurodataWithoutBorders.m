function [success] = saveNeurodataWithoutBorders(image_masks,roi_response_data,algorithm,outputFilePath,varargin)
	% Takes cell extraction outputs and saves then in NWB format per format in https://github.com/schnitzer-lab/nwb_schnitzer_lab.
	% Biafra Ahanonu
	% started: 2020.04.03 [16:01:45]
	% Based on mat2nwb in https://github.com/schnitzer-lab/nwb_schnitzer_lab.
	% inputs
		% image_masks - [x y z] matrix
		% roi_response_data - {1 N} cell with N = number of different signal traces for that algorithm.
		% algorithm - Name of the algorithm.
		% outputFilePath - file path to save NWB file to.
	% outputs
		%

	% changelog
		% 2020.07.01 [09:40:20] - Convert roi_response_data to cell if user inputs only a matrix.
		% 2020.09.15 [20:30:32] - Automatically creates directory where file is to be stored if it is not present.
	% TODO
		%

	%========================
	% DESCRIPTION
	options.fpathYML = [ciapkg.getDir filesep '_external_programs' filesep 'nwb_schnitzer_lab' filesep 'ExampleMetadata.yml'];
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
		metadata = yaml.ReadYaml(options.fpathYML);
		data_path = outputFilePath;

		if ~ischar(data_path)
			disp('Save path given not a character string, try again!')
			return;
		end

		% Make sure folder exists, else create it.
		[folderName,~,~] = fileparts(data_path);
		ciapkg.io.mkdir(folderName);

		% Get datatype name
		if contains(data_path,'extract')
		    data_type='extract';
		elseif contains(data_path,'cnmf') && ~contains(data_path,'cnmfe')
		    data_type='cnmf';
		elseif contains(data_path,'cnmfe')
		    data_type='cnmfe';
	    elseif contains(data_path,'cellmax')
	        data_type='cellmax';
		elseif contains(data_path,'em')
		    data_type='em';
		elseif contains(data_path,'pcaica')
		    data_type='pcaica';
		elseif contains(data_path,'roi')
		    data_type='roi';
	    else
	    	data_type = algorithm;
		end

		% Automatically convert to cell if matrix
		if iscell(roi_response_data)==0 & ismatrix(roi_response_data)==1
			disp('Converting roi_response_data to cell from matrix');
			roi_response_data = {roi_response_data};
		end

		tmpData = roi_response_data;
		roi_response_data = struct;
		for i=1:length(tmpData)
		    roi_response_data.(['ROI_' num2str(i)]) = tmpData{i};
		end

		nwbfile_input_args = get_input_args(metadata, 'NWBFile');
		% Convert to ISO 8601 format
		nwbfile_input_args{4} = datestr(nwbfile_input_args{4}, 'yyyy-mm-dd HH:MM:SS');
		nwb = NwbFile(nwbfile_input_args{:});

		subject_input_args = get_input_args(metadata, 'Subject');
		nwb.general_subject = types.core.Subject(subject_input_args{:});

		nwb = add_processed_ophys(nwb, metadata, image_masks, roi_response_data,data_type);

		% Remove previous file if it already exists
		if exist(outputFilePath,'file')==2
			fprintf('Deleting %s.\n',outputFilePath)
			delete(outputFilePath);
		end

		fprintf('Saving to: %s.\n',outputFilePath)
		nwbExport(nwb, outputFilePath);
		disp('Done saving to NWB!');
		success = 1;
	catch err
		success = 0;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end