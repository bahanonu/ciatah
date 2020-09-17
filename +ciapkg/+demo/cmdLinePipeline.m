% Running calciumImagingAnalysis command line
% Below is an example `cacliumImagingAnalysis` pipeline using the command line for those that do not want to use the class or want to create their own custom batch analyses. It assumes you have already run `example_downloadTestData` to download the example test data.
% Changelog
	% 2020.09.15 [19:54:14] - Use ciapkg.getDir() to make sure demo always calls correct path regardless of where user is pointing. Also make playMovie calls have titles to make clearer to new users and allow a GUI-less option.

guiEnabled = 0;
saveAnalysis = 1;

%% Download test data, only a single session
example_downloadTestData('downloadExtraFiles',0);

%% Load movie to analyze
analysisFolderPath = [ciapkg.getDir() filesep 'data' filesep '2014_04_01_p203_m19_check01'];
inputMoviePath = [analysisFolderPath filesep 'concat_recording_20140401_180333.h5'];
inputMovie = loadMovieList(inputMoviePath);

%% Visualize slice of the movie
if guiEnabled==1
	playMovie(inputMovie(:,:,1:500),'extraTitleText','Raw movie');
	% Alternatively, visualize by entering the file path
	playMovie(inputMoviePath,'extraTitleText','Raw movie directly from file');
end

%% Downsample input movie if need to
if guiEnabled==1
	inputMovieD = downsampleMovie(inputMovie,'downsampleDimension','space','downsampleFactor',4);
	playMovie(inputMovie,'extraMovie',inputMovieD,'extraTitleText','Raw movie vs. down-sampled movie');
end

%% Remove stripes from movie if needed
if guiEnabled==1
	% Show full filter sequence for one frame
	sopts.stripOrientation = 'both';
	sopts.meanFilterSize = 1;
	sopts.freqLowExclude = 10;
	sopts.bandpassType = 'highpass';
	removeStripsFromMovie(inputMovie(:,:,1),'options',sopts,'showImages',1);
	drawnow
	% Run on the entire movie
	inputMovie = removeStripsFromMovie(inputMovie,'options',sopts);
end

%% Get coordinates to crop from the user separately
if guiEnabled==1
	[cropCoords] = getCropCoords(squeeze(inputMovie(:,:,1)));
	toptions.cropCoords = cropCoords;
	% Or have turboreg function itself directly ask the user for manual area from which to obtain correction coordinates
	% toptions.cropCoords = 'manual';
else
	toptions.cropCoords = [26    34   212   188];
end

%% Motion correction
toptions.turboregRotation = 0;
toptions.removeEdges = 1;
toptions.pxToCrop = 10;
% Pre-motion correction
	toptions.complementMatrix = 1;
	toptions.meanSubtract = 1;
	toptions.meanSubtractNormalize = 1;
	toptions.normalizeType = 'matlabDisk';
% Spatial filter
	toptions.normalizeBeforeRegister = 'divideByLowpass';
	toptions.freqLow = 0;
	toptions.freqHigh = 7;
[inputMovie2, ~] = turboregMovie(inputMovie,'options',toptions);

%% Compare raw and motion corrected movies
if guiEnabled==1
	playMovie(inputMovie,'extraMovie',inputMovie2,'extraTitleText','Raw movie vs. motion-corrected movie');
end

%% Run dF/F
inputMovie3 = dfofMovie(single(inputMovie2),'dfofType','dfof');

%% Run temporal downsampling
inputMovie3 = downsampleMovie(inputMovie3,'downsampleDimension','time','downsampleFactor',4);

%% Final check of movie before cell extraction
if guiEnabled==1
	playMovie(inputMovie3,'extraTitleText','Processed movie for cell extraction');
end

%% Run PCA-ICA cell extraction
nPCs = 300; nICs = 225;
[PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, PcaInfo] = run_pca(inputMovie3, nPCs, 'movie_dataset_name','/1');
[IcaFilters, IcaTraces, IcaInfo] = run_ica(PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, size(inputMovie3,1), size(inputMovie3,2), nICs, 'output_units','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);
IcaTraces = permute(IcaTraces,[2 1]);

%% Save outputs to NWB format
[~,folderName,~] = fileparts(analysisFolderPath);
% mkdir([analysisFolderPath filesep 'nwbFiles']);
nwbFilePath = [analysisFolderPath filesep 'nwbFiles' filesep folderName '_pcaicaAnalysis.nwb'];
if saveAnalysis==1
	saveNeurodataWithoutBorders(IcaFilters,{IcaTraces},'pcaica',nwbFilePath);
end

%% Run cell extraction using matrix
if guiEnabled==1
	[outImages, outSignals, choices] = signalSorter(IcaFilters,IcaTraces,'inputMovie',inputMovie3);
end

%% Run signal sorting using NWB
if saveAnalysis==1&guiEnabled==1
	disp(repmat('=',1,21));disp('Running signalSorter using NWB file input.')
	[outImages, outSignals, choices] = signalSorter(nwbFilePath,[],'inputMovie',inputMovie3);
end

%% Plot results of sorting
figure;
subplot(1,2,1);imagesc(max(IcaFilters,[],3));axis equal tight; title('Raw filters')
subplot(1,2,2);imagesc(max(outImages,[],3));axis equal tight; title('Sorted filters')

%% Create an overlay of extraction outputs on the movie and signal-based movie
[inputMovieO] = createImageOutlineOnMovie(inputMovie3,IcaFilters,'dilateOutlinesFactor',0);
if guiEnabled==1
	playMovie(inputMovieO,'extraMovie',inputMovie3,'extraTitleText','Overlay of cell outlines on processed movie');
end

[signalMovie] = createSignalBasedMovie(IcaTraces,IcaFilters,'signalType','peak');
if guiEnabled==1
	playMovie(signalMovie,'extraMovie',inputMovie3,'extraTitleText','Cell activity-based movie');
end