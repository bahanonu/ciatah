function [optsNC] = getNoRMCorreParams(movieDims,varargin)
	% [optsNC] = getNoRMCorreParams(varargin)
	% 
	% Automatically returns default NoRMCorre parameters or ask user to input parameters.
	% 
	% Biafra Ahanonu
	% started: 2022.07.18 [10:30:01]
	% 
	% Inputs
	% 	No inputs by default, all Name-Value pairs.
	% 
	% Outputs
	% 	optsNC - structure consisting of NormCorre options.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		%
	% TODO
		%

	% ========================
	% Binary: 1 = use GUI display for user to customize parameters.
	options.guiDisplay = 0;
	% Struct: Options from prior run of getNoRMCorreParams().
	options.priorOpts = struct;
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	optsNC = struct;

	try
		% [d1,d2,T] = size(inputMovieHere);
		d1 = movieDims(1);
		d2 = movieDims(2);
		T = movieDims(3);
		bound = 0;

		% Update to CIAtah default settings
		if isempty(fieldnames(options.priorOpts))
			optsNC2.d1 =  d1-bound;
			optsNC2.d2 =  d2-bound;
			optsNC2.init_batch =   10;
			optsNC2.bin_width =   50;
			optsNC2.grid_size =  [128,128];
			optsNC2.mot_uf =  4;
			optsNC2.correct_bidir =  false;
			optsNC2.overlap_pre =  32;
			optsNC2.overlap_post =  32;
			optsNC2.max_dev =  50;
			optsNC2.use_parallel =  true;
			optsNC2.print_msg =  true;
			optsNC2.us_fac =  4;
			optsNC2.max_shift =  100;
			optsNC2.boundary =  'NaN';
		else
			optsNC2 = options.priorOpts;
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	try
		optsNC = normcorre.NoRMCorreSetParms(...
			'd1', d1-bound,...
			'd2', d2-bound,...
			'init_batch', optsNC2.init_batch,...
			'bin_width', optsNC2.bin_width,...
			'grid_size', optsNC2.grid_size,...
			'mot_uf', optsNC2.mot_uf,...
			'correct_bidir', optsNC2.correct_bidir,...
			'overlap_pre', optsNC2.overlap_pre,...
			'overlap_post', optsNC2.overlap_post,...
			'max_dev', optsNC2.max_dev,...
			'use_parallel', optsNC2.use_parallel,...
			'print_msg', optsNC2.print_msg,...
			'us_fac', optsNC2.us_fac,...
			'max_shift', optsNC2.max_shift,...
			'boundary', optsNC2.boundary...
			);
			% 'init_batch_interval',options.refFrame,...

		% [optsNC] = ciapkg.io.mergeStructs(optsNC,optsNC2);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
	if options.guiDisplay==0
		return;
	end

	try
		% optsNC = normcorre.NoRMCorreSetParms(...
		% 	'd1', d1-bound,...
		% 	'd2', d2-bound,...
		% 	'd3', 1,...
		% 	'init_batch', optsNC2.init_batch,...
		% 	'bin_width', optsNC2.bin_width,...
		% 	'grid_size', optsNC2.grid_size,...
		% 	'mot_uf', optsNC2.mot_uf,...
		% 	'correct_bidir', optsNC2.correct_bidir,...
		% 	'overlap_pre', optsNC2.overlap_pre,...
		% 	'overlap_post', optsNC2.overlap_post,...
		% 	'max_dev', optsNC2.max_dev,...
		% 	'use_parallel', optsNC2.use_parallel,...
		% 	'print_msg', optsNC2.print_msg,...
		% 	'us_fac', optsNC2.us_fac,...
		% 	'max_shift', optsNC2.max_shift,...
		% 	'boundary', optsNC2.boundary...
		% 	);
		
		modFn = fieldnames(optsNC2);

		% [optsNC] = ciapkg.io.mergeStructs(optsNC,optsNC2);

		optsFn = {
		% dataset info
		{'d1', "number of rows"};
		{'d2', "number of cols"};
		% {'d3', "number of planes (for 3d imaging, default: 1)"};
		% patches
		{'grid_size', "size of non-overlapping regions (default: [d1,d2,d3])"};
		{'overlap_pre', "size of overlapping region (default: [32,32,16])"};
		{'min_patch_size', "minimum size of patch (default: [32,32,16])    "};
		{'min_diff', "minimum difference between patches (default: [16,16,5])"};
		{'us_fac', "upsampling factor for subpixel registration (default: 20)"};
		{'mot_uf', "degree of patches upsampling (default: [4,4,1])"};
		{'max_dev', "maximum deviation of patch shift from rigid shift (default: [3,3,1])"};
		{'overlap_post', "size of overlapping region after upsampling (default: [32,32,16])"};
		{'max_shift', "maximum rigid shift in each direction (default: [15,15,5])"};
		{'phase_flag', "flag for using phase correlation (default: false)"};
		{'shifts_method', "method to apply shifts ('FFT','cubic','linear')"};

		% template updating
		{'upd_template', "flag for online template updating (default: true)"};
		{'init_batch', "length of initial batch (default: 100)"};
		{'bin_width', "width of each bin (default: 200)"};
		{'buffer_width', "number of local means to keep in memory (default: 50)"};
		{'method', "method for averaging the template (default: {'median';'mean})"};
		{'iter', "number of data passes (default: 1)"};
		{'boundary', "method of boundary treatment 'NaN','copy','zero','template' (default:} 'copy')"};

		% misc
		{'add_value', "add dc value to data (default: 0)"};
		{'use_parallel', "for each frame, update patches in parallel (default: false)"};
		{'memmap', "flag for saving memory mapped motion corrected file (default: false)"};
		{'mem_filename', "name for memory mapped file (default: 'motion_corrected.mat')"};
		{'mem_batch_size', "batch size during memory mapping for speed (default: 5000)"};
		{'print_msg', "flag for printing progress to command line (default: true)"};

		% plotting
		{'plot_flag', "flag for plotting results in real time (default: false)"};
		{'make_avi', "flag for making movie (default: false)"};
		{'name', "name for movie (default: 'motion_corrected.avi')"};
		{'fr', "frame rate for movie (default: 30)"};

		% output type
		{'output_type', "'mat' (load in memory), 'memmap', 'tiff', 'hdf5', 'bin' (default:mat)"};
		{'h5_groupname', "name for hdf5 dataset (default: 'mov')"};
		{'h5_filename', "name for hdf5 saved file (default: 'motion_corrected.h5')"};
		{'tiff_filename', "name for saved tiff stack (default: 'motion_corrected.tif')"};
		{'output_filename', "name for saved file will be used if `h5_,tiff_filename` are not} specified"};

		% use windowing
		{'use_windowing', "flag for windowing data before fft (default: false)"};
		{'window_length', "length of window on each side of the signal as a fraction of signal length. Total length = length(signal)(1 + 2*window_length). (default: 0.5)"};
		{'bitsize', "bitsize for reading .raw files (default: 2 (uint16). other choices 1 (uint8), 4 (single), 8 (double))"};

		% offset from bidirectional sampling
		{'correct_bidir', "check for offset due to bidirectional scanning (default: true)"};
		{'nFrames', "number of frames to average (default: 50)"};
		{'bidir_us', "upsampling factor for bidirectional sampling (default: 10)"};
		{'col_shift', "known bi-directional offset provided by the user (default: [])"};
		};

		for iz = 1:length(optsFn)
			optsFn{iz}{2} = char(optsFn{iz}{2});
		end

		optsDefault = optsFn;

		movieSettingsStrs = {};
		defaultVals = {};
		for iz = 1:length(optsFn)
			movieSettingsStrs{end+1} = optsFn{iz}{2};
		end

		% optsTmp = cellfun(@num2str,struct2cell(optsDefault),'UniformOutput',false);
		for iz = 1:length(movieSettingsStrs)
			valStr = optsFn{iz}{1};
			dVal = optsNC.(valStr);
			if isnumeric(dVal)|islogical(dVal)
				dVal = num2str(dVal);
			elseif iscell(dVal)
				dVal = cell2str(dVal);
			else
				
			end
			defaultVals{end+1} = dVal;
			movieSettingsStrs{iz} = strrep([valStr ' | ' movieSettingsStrs{iz} ' | default: ' dVal],'_','\_');
			if any(strcmp(modFn,valStr))==1
				movieSettingsStrs{iz} = ['\bf\color{red}' movieSettingsStrs{iz}];
			end
		end
		% defaultVals
		% cellfun(@class,defaultVals,'UniformOutput',false)

		dlgStr = 'NoRMCorre (red options are those to focus on';
		AddOpts.Resize='on';
		AddOpts.WindowStyle='normal';
		% AddOpts.WindowStyle='non-modal';
		AddOpts.Interpreter='tex';
		AddOpts.DlgSize = [1200 100];
		mSet = inputdlgcol(movieSettingsStrs,...
			dlgStr,1,...
				defaultVals,...
			AddOpts,3);

		sNo = 1;

		for iz = 1:length(movieSettingsStrs)
			valStr = optsFn{iz}{1};
			dVal = optsNC.(valStr);
			if isnumeric(dVal)|islogical(dVal)
				optsNC.(valStr) = str2num(mSet{iz});
			elseif iscell(dVal)
				optsNC.(valStr) = eval(mSet{iz});
			else
				optsNC.(valStr) = mSet{iz};
			end
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [outputs] = nestedfxn_exampleFxn(arg)
		% Always start nested functions with "nestedfxn_" prefix.
		% outputs = ;
	end	
end

