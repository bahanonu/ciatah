function [pcaicaAnalysisOutput] = runPcaIca(inputMovie,nPCs,nICs,varargin)
	% Wrapper to run PCA-ICA (Mukamel, 2009) cell extraction using two existing versions on CIAPKG.
	% Biafra Ahanonu
	% started: 2019.10.31 [10:01:18]
	% inputs
		% inputMovie - Matrix ([x y frames]) or char string pointing to movie path.
		% nPCs - Int: number of principal components to request from PCA.
		% nICs - Int: number of independent components to request from ICA. Should be less than nPCs.
	% outputs
		% pcaicaAnalysisOutput - structure containing output filters and traces for the requested number of nICs.
		% pcaicaAnalysisOutput.IcaFilters - Matrix with dimensions [x y nICs].
		% pcaicaAnalysisOutput.IcaTraces - Matrix with dimensions [nICs frames].

	% changelog
		% 2020.10.14 [13:52:47] - Updated to complete conversion from class to independent function.
		% 2020.10.17 [19:05:12] - Additional updates to deal with matrix inputs and give additional information for each PCA-ICA version output.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % Import CIAtah package API

	%========================
	% Int:
		% 2 = Hakan/Tony version. (Preferred)
		% 1 = SpikeE version (Maggie Carr, Eran Mukamel, Jerome Lecoq, and Lacey Kitch, Biafra Ahanonu)
	options.version = 2;
	% Termination tolerance, e.g. 1e-5.
	options.TermTolICs = 10^(-5);
	% Str: hierarchy name in hdf5 where movie data is located
	options.inputDatasetName = '/1';
	% Float: parameter (between 0 and 1) specifying weight of temporal information in spatio-temporal ICA
	options.mu = 0.1;
	% Float: termination tolerance, e.g. 1e-5.
	options.term_tol = 5e-6;
	% Int: max iterations of FastICA, e.g. 750.
	options.max_iter = 1e3;
	% Str: output units, options: string of fluorescence ('fl'), standard deviation ('std'), '2norm', or variance ('var').
	options.outputUnits = 'fl';
	% Str: character string with regular expression if inputMovie is a folder path. In general ignore and give direct path to movie.
	options.fileFilterRegexp = 'concat';
	% Int vector: list of specific frames to load.
	options.frameList = [];
	% DEPRECIATED
		options.selectPCs = 0;
		options.selectICs = 0;
		options.displayIcImgs = 0;
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
		if options.version==1
			disp('running PCA-ICA, old version...')
			startTime = tic;
			[PcaFilters, PcaTraces] = ciapkg.signal_extraction.pca_ica.runPCA(inputMovie, '', nPCs, options.fileFilterRegexp,'inputDatasetName',options.inputDatasetName,'frameList',options.frameList);
			if isempty(PcaFilters)
				disp('PCs are empty, skipping...')
				return;
			end
			[IcaFilters, IcaTraces, IcaInfo] = ciapkg.signal_extraction.pca_ica.runICA(PcaFilters, PcaTraces, '', nICs, '');
			pcaicaAnalysisOutput.IcaInfo = IcaInfo;
			traceSaveDimOrder = '[nComponents frames]';
			% reorder if needed
			options.IcaSaveDimOrder = 'xyz';
			if strcmp(options.IcaSaveDimOrder,'xyz')
				IcaFilters = permute(IcaFilters,[2 3 1]);
				imageSaveDimOrder = 'xyz';
			else
				imageSaveDimOrder = 'zxy';
			end
		elseif options.version==2
			disp('running PCA-ICA, new version...')
			startTime = tic;
			[PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, PcaInfo] = ciapkg.signal_extraction.pca_ica_2.run_pca(inputMovie, nPCs, 'movie_dataset_name',options.inputDatasetName,'frameList',options.frameList);

			if isempty(PcaOutputTemporal)
				disp('PCs are empty, skipping...')
				return;
			end

			disp('+++')
			if ischar(inputMovie)==1
				movieDims = loadMovieList(inputMovie,'convertToDouble',0,'frameList',[],'inputDatasetName',options.inputDatasetName,'treatMoviesAsContinuous',1,'getMovieDims',1,'frameList',options.frameList);
			else
				movieDimsTmp = size(inputMovie);
				movieDims.x = movieDimsTmp(1);
				movieDims.y = movieDimsTmp(2);
				movieDims.z = movieDimsTmp(3);
			end

			% output_units = 'fl';
			% output_units = 'std';
			% options.PCAICA.term_tol = 5e-6;
			% options.PCAICA.max_iter = 1e3;
			[IcaFilters, IcaTraces, IcaInfo] = ciapkg.signal_extraction.pca_ica_2.run_ica(...
				PcaOutputSpatial,...
				PcaOutputTemporal,...
				PcaOutputSingularValues,...
				movieDims.x, movieDims.y,...
				nICs,...
				'output_units',options.outputUnits,...
				'mu',options.mu,...
				'term_tol',options.term_tol,...
				'max_iter',options.max_iter);
			IcaTraces = permute(IcaTraces,[2 1]);
			traceSaveDimOrder = '[nComponents frames]';
			% reorder if needed
			options.IcaSaveDimOrder = 'xyz';
			if strcmp(options.IcaSaveDimOrder,'xyz')
				imageSaveDimOrder = 'xyz';
			else
				IcaFilters = permute(IcaFilters,[3 1 2]);
				imageSaveDimOrder = 'zxy';
			end
			pcaicaAnalysisOutput.IcaInfo = IcaInfo;
			pcaicaAnalysisOutput.PcaInfo = PcaInfo;
		else
			disp('Incorrect version requested.')
			pcaicaAnalysisOutput.status = 0;
			return;
		end

		pcaicaAnalysisOutput.PcaIcaVersion = options.version;
		pcaicaAnalysisOutput.IcaFilters = IcaFilters;
		pcaicaAnalysisOutput.IcaTraces = IcaTraces;
		pcaicaAnalysisOutput.imageSaveDimOrder = imageSaveDimOrder;
		pcaicaAnalysisOutput.traceSaveDimOrder = traceSaveDimOrder;
		pcaicaAnalysisOutput.nPCs = nPCs;
		pcaicaAnalysisOutput.nICs = nICs;
		pcaicaAnalysisOutput.time.startTime = startTime;
		pcaicaAnalysisOutput.time.endTime = toc(startTime);
		pcaicaAnalysisOutput.time.dateTime = datestr(now,'yyyymmdd_HHMM','local');
		if ischar(inputMovie)
			pcaicaAnalysisOutput.movieList = inputMovie;
		else
			pcaicaAnalysisOutput.movieList = 'matrixInput';
		end
		pcaicaAnalysisOutput.status = 1;

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end