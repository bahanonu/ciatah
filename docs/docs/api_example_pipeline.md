# Example `{{ site.name }}` pipeline via the command line.

Below is an example `{{ site.name }}` pipeline using the command line for those that do not want to use the class or want to create their own custom batch analyses. It assumes you have already run `example_downloadTestData` to download the example test data and have MATLAB path set to the `{{ site.name }}` root directory.

Can also access the pipeline by typing `edit ciapkg.demo.cmdLinePipeline` into the MATLAB command window or run by typing in `ciapkg.demo.cmdLinePipeline;`.

```MATLAB
% Running {{ site.name }} from MATLAB command line/window

%% Load {{ site.name }} functions
loadBatchFxns();

%% Load movie to analyze
inputMovie = loadMovieList([ciapkg.getDir() filesep 'data' filesep '2014_04_01_p203_m19_check01' filesep 'concat_recording_20140401_180333.h5']);
```

```MATLAB
%% Visualize slice of the movie
playMovie(inputMovie(:,:,1:500));
% Alternatively, visualize by entering the file path
playMovie(inputMoviePath);
```

```MATLAB
%% Downsample input movie if need to
inputMovieD = downsampleMovie(inputMovie,'downsampleDimension','space','downsampleFactor',4);
playMovie(inputMovie,'extraMovie',inputMovieD);

% Alternatively, if you have Inscopix ISXD files, downsample by reading segments from disk using.
moviePath = 'PATH_TO_ISXD';
opts.maxChunkSize = 5000; % Max chunk size in Mb to load into RAM.
opts.downsampleFactor = 4; % How much to downsample original movie, set to 1 for no downsampling.
convertInscopixIsxdToHdf5(moviePath,'options',opts);
```

```MATLAB
%% Remove stripes from movie if needed
% Show full filter sequence for one frame
sopts.stripOrientation = 'both';
sopts.meanFilterSize = 1;
sopts.freqLowExclude = 10;
sopts.bandpassType = 'highpass';
removeStripsFromMovie(inputMovie(:,:,1),'options',sopts,'showImages',1);
% Run on the entire movie
removeStripsFromMovie(inputMovie,'options',sopts);
```

```MATLAB
%% Get coordinates to crop
[cropCoords] = getCropCoords(squeeze(inputMovie(:,:,1)));
toptions.cropCoords = cropCoords;
```

```MATLAB
%% Motion correction
% Or have turboreg run manual correction
toptions.cropCoords = 'manual';
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
```

```MATLAB
%% Compare raw and motion corrected movies
playMovie(inputMovie,'extraMovie',inputMovie2);
```

```MATLAB
%% Run dF/F
inputMovie3 = dfofMovie(single(inputMovie2),'dfofType','dfof');
```

```MATLAB
%% Run temporal downsampling
inputMovie3 = downsampleMovie(inputMovie3,'downsampleDimension','time','downsampleFactor',4);
```

```MATLAB
%% Final check of movie before cell extraction
playMovie(inputMovie3);
```

```MATLAB
%% Run PCA-ICA cell extraction. CNMF-e, CNMF, ROI, and other cell-extraction algorithms are also available.
nPCs = 300; nICs = 225;
[PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, PcaInfo] = run_pca(inputMovie3, nPCs, 'movie_dataset_name','/1');
[IcaFilters, IcaTraces, IcaInfo] = run_ica(PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues, size(inputMovie3,1), size(inputMovie3,2), nICs, 'output_units','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);
IcaTraces = permute(IcaTraces,[2 1]);
```

```MATLAB
%% Save outputs to NWB format
saveNeurodataWithoutBorders(IcaFilters,{IcaTraces},'pcaica','pcaica.nwb');
```

Run CNMF or CNMF-e cell extraction.
```MATLAB
%% Run CNMF or CNMF-e cell extraction. Check each function with "edit" for options.
numExpectedComponents = 225;
cellWidth = 10;
cnmfOptions.otherCNMF.tau = cellWidth/2; % expected width of cells

% Run CNMF
[cnmfAnalysisOutput] = computeCnmfSignalExtractionClass(movieList,numExpectedComponents,'options',cnmfOptions);

% Run CNMF-e
[cnmfeAnalysisOutput] = computeCnmfeSignalExtraction_batch(movieList{1},'options',cnmfeOptions);

%% Save outputs to NWB format
saveNeurodataWithoutBorders(cnmfAnalysisOutput.extractedImages,{cnmfAnalysisOutput.extractedSignals,cnmfAnalysisOutput.extractedSignalsEst},'cnmf','cnmf.nwb');
saveNeurodataWithoutBorders(cnmfeAnalysisOutput.extractedImages,{cnmfeAnalysisOutput.extractedSignals,cnmfeAnalysisOutput.extractedSignalsEst},'cnmfe','cnmfe.nwb');
```

Run EXTRACT cell extraction.
```MATLAB
%% Run EXTRACT cell extraction. Check each function with "edit" for options.
% Load default configuration
extractConfig = get_defaults([]);

outStruct = extractor(inputMovie,extractConfig);
extractAnalysisOutput.filters = outStruct.spatial_weights;
% permute so it is [nCells frames]
extractAnalysisOutput.traces = permute(outStruct.temporal_weights, [2 1]);

% Other run information if saving as a MAT-file.
extractAnalysisOutput.info = outStruct.info;
extractAnalysisOutput.config = outStruct.config;
extractAnalysisOutput.info = outStruct.info;
extractAnalysisOutput.userInputConfig = extractConfig;
extractAnalysisOutput.opts = outStruct.config;

%% Save outputs to NWB format
saveNeurodataWithoutBorders(extractAnalysisOutput.filters,{extractAnalysisOutput.traces},'cnmf','cnmf.nwb');
```

```MATLAB
%% Run signal sorting using matrix inputs
[outImages, outSignals, choices] = signalSorter(IcaFilters,IcaTraces,'inputMovie',inputMovie3);
```

```MATLAB
%% Run signal sorting using NWB
[outImages, outSignals, choices] = signalSorter('pcaica.nwb',[],'inputMovie',inputMovie3);
```

```MATLAB
%% Plot results of sorting
figure;
subplot(1,2,1);imagesc(max(IcaFilters,[],3));axis equal tight; title('Raw filters')
subplot(1,2,2);imagesc(max(outImages,[],3));axis equal tight; title('Sorted filters')
```

```MATLAB
%% Create an overlay of extraction outputs on the movie and signal-based movie
[inputMovieO] = createImageOutlineOnMovie(inputMovie3,IcaFilters,'dilateOutlinesFactor',0);
[signalMovie] = createSignalBasedMovie(IcaTraces,IcaFilters,'signalType','peak');
```

```MATLAB
%% Play all three movies
% Normalize all the movies
movieM = cellfun(@(x) normalizeVector(x,'normRange','zeroToOne'),{inputMovie3,inputMovieO,signalMovie},'UniformOutput',false);
playMovie(cat(2,movieM{:}));
```

```MATLAB
%% Run cross-session alignment of cells
% Create input images, cell array of [x y nCells] matrices
inputImages = {day1Images,day2Images,day3Images};

% options to change
opts.maxDistance = 5; % distance in pixels between centroids for them to be grouped
opts.trialToAlign = 1; % which session to start alignment on
opts.nCorrections = 1; %number of rounds to register session cell maps.
opts.RegisTypeFinal = 2 % 3 = rotation/translation and iso scaling; 2 = rotation/translation, no iso scaling

% Run alignment code
[alignmentStruct] = matchObjBtwnTrials(inputImages,'options',opts);

% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

% View the cross-session matched cells, saved to `private\_tmpFiles` sub-folder.
[success] = createMatchObjBtwnTrialsMaps(inputImages,alignmentStruct);
```