# Example `{{ site.name }}` pipeline via the command line.

Below is an example `{{ site.name }}` pipeline using the command line for those that do not want to use the class or want to create their own custom batch analyses. It assumes you have already run `example_downloadTestData` to download the example test data and have MATLAB path set to the `{{ site.name }}` root directory.

Can also access the pipeline by typing `edit ciapkg.demo.cmdLinePipeline` into the MATLAB command window or run by typing in `ciapkg.demo.cmdLinePipeline;`.

## Setup
```MATLAB
% Running {{ site.name }} from MATLAB command line/window

guiEnabled = 1;
saveAnalysis = 1;
inputDatasetName = '/1';
rawFileRegexp = 'concat';

% Setup folder paths
analysisFolderPath = [ciapkg.getDir() filesep 'data' filesep '2014_04_01_p203_m19_check01'];
[~,folderName,~] = fileparts(analysisFolderPath);
% Setup NWB folder paths
nwbFilePath = [analysisFolderPath filesep 'nwbFiles' filesep folderName];
nwbFileFolderPath = [analysisFolderPath filesep 'nwbFiles'];

% Load {{ site.name }} functions
loadBatchFxns();
```

```MATLAB
%% Download test data, only a single session
ciapkg.api.example_downloadTestData('downloadExtraFiles',0);
```

```MATLAB
%% Load movie to analyze
inputMoviePath = ciapkg.api.getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
% inputMoviePath = [analysisFolderPath filesep 'concat_recording_20140401_180333.h5'];
inputMovie = ciapkg.api.loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName);
```

## Visualize movie
```MATLAB
%% Visualize slice of the movie
ciapkg.api.playMovie(inputMovie(:,:,1:500),'extraTitleText','Raw movie');
% Alternatively, visualize by entering the file path
ciapkg.api.playMovie(inputMoviePath,'extraTitleText','Raw movie directly from file');
```

## Downsample movie
```MATLAB
%% Downsample input movie if need to
inputMovieD = ciapkg.api.downsampleMovie(inputMovie,'downsampleDimension','space','downsampleFactor',4);
ciapkg.api.playMovie(inputMovie,'extraMovie',inputMovieD,'extraTitleText','Raw movie vs. down-sampled movie');

% Alternatively, if you have Inscopix ISXD files, downsample by reading segments from disk using.
moviePath = 'PATH_TO_ISXD';
opts.maxChunkSize = 5000; % Max chunk size in Mb to load into RAM.
opts.downsampleFactor = 4; % How much to downsample original movie, set to 1 for no downsampling.
ciapkg.api.convertInscopixIsxdToHdf5(moviePath,'options',opts);
```

## Remove stripe artifacts (e.g. from camera) from movie
```MATLAB
%% Remove stripes from movie if needed
% Show full filter sequence for one frame
sopts.stripOrientation = 'both';
sopts.meanFilterSize = 1;
sopts.freqLowExclude = 10;
sopts.bandpassType = 'highpass';
ciapkg.api.removeStripsFromMovie(inputMovie(:,:,1),'options',sopts,'showImages',1);
% Run on the entire movie
ciapkg.api.removeStripsFromMovie(inputMovie,'options',sopts);
```

## Detrend movie if needed (default linear trend), e.g. to compensate for bleaching over time.
```MATLAB
%% Detrend movie
inputMovie = ciapkg.api.normalizeMovie(inputMovie,'normalizationType','detrend','detrendDegree',1);
```

## Run motion correction
```MATLAB
%% Get coordinates to crop from the user separately or set automatically
if guiEnabled==1
	[cropCoords] = ciapkg.api.getCropCoords(squeeze(inputMovie(:,:,1)));
	toptions.cropCoords = cropCoords;
	% Or have turboreg function itself directly ask the user for manual area from which to obtain correction coordinates
	% toptions.cropCoords = 'manual';
else
	toptions.cropCoords = [26 34 212 188];
end
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
[inputMovie2, ~] = ciapkg.api.turboregMovie(inputMovie,'options',toptions);
```

```MATLAB
%% Compare raw and motion corrected movies
ciapkg.api.playMovie(inputMovie,'extraMovie',inputMovie2);
```

## Convert movie to units of relative fluorescence
```MATLAB
%% Run dF/F
inputMovie3 = ciapkg.api.dfofMovie(single(inputMovie2),'dfofType','dfof');
```

## Downsample movie
```MATLAB
%% Run temporal downsampling
inputMovie3 = ciapkg.api.downsampleMovie(inputMovie3,'downsampleDimension','time','downsampleFactor',4);
```

```MATLAB
%% Final check of movie before cell extraction
ciapkg.api.playMovie(inputMovie3);
```

## Run PCA-ICA
```MATLAB
%% Run PCA-ICA cell extraction. CNMF-e, CNMF, ROI, and other cell-extraction algorithms are also available.
nPCs = 300;
nICs = 225;
pcaicaStruct = ciapkg.signal_extraction.runPcaIca(inputMovie3,nPCs,nICs,'version',2,'output_units','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);
```

```MATLAB
%% Save outputs to NWB format
if saveAnalysis==1
	ciapkg.api.saveNeurodataWithoutBorders(pcaicaStruct.IcaFilters,{pcaicaStruct.IcaTraces},'pcaica',[nwbFilePath '_pcaicaAnalysis.nwb']);
end
```

## Run CNMF or CNMF-e cell extraction.
```MATLAB
%% Run CNMF or CNMF-e cell extraction
numExpectedComponents = 225;
cellWidth = 10;
cnmfOptions.otherCNMF.tau = cellWidth/2; % expected width of cells

% Run CNMF
[success] = ciapkg.api.cnmfVersionDirLoad('current');
[cnmfAnalysisOutput] = ciapkg.api.computeCnmfSignalExtractionClass(inputMovie3,numExpectedComponents,'options',cnmfOptions);

% Run CNMF-e
[success] = ciapkg.api.cnmfVersionDirLoad('cnmfe');
cnmfeOptions.gSiz = cellWidth;
cnmfeOptions.gSig = ceil(cellWidth/4);
[cnmfeAnalysisOutput] = ciapkg.api.computeCnmfeSignalExtraction_batch(outputMoviePath,'options',cnmfeOptions);

% Save outputs to NWB format
if saveAnalysis==1
	% Save CNMF
	ciapkg.api.saveNeurodataWithoutBorders(cnmfAnalysisOutput.extractedImages,{cnmfAnalysisOutput.extractedSignals,cnmfAnalysisOutput.extractedSignalsEst},'cnmf',[nwbFilePath '_cnmf.nwb']);

	% Save CNMF-E
	ciapkg.api.saveNeurodataWithoutBorders(cnmfeAnalysisOutput.extractedImages,{cnmfeAnalysisOutput.extractedSignals,cnmfeAnalysisOutput.extractedSignalsEst},'cnmfe',[nwbFilePath '_cnmfe.nwb']);
end

[success] = ciapkg.api.cnmfVersionDirLoad('none');
```

## Run EXTRACT cell extraction.
```MATLAB
%% Run EXTRACT cell extraction. Check each function with "edit" for options.
% Load default configuration
ciapkg.loadBatchFxns('loadEverything');
extractConfig = get_defaults([]);

% See https://github.com/schnitzer-lab/EXTRACT-public#configurations.
cellWidth = 10;
extractConfig.avg_cell_radius = cellWidth;
extractConfig.num_partitions_x = 2;
extractConfig.num_partitions_y = 2;
extractConfig.use_sparse_arrays = 0;

outStruct = extractor(inputMovie3,extractConfig);

% Grab outputs and put into standard format
extractAnalysisOutput.filters = outStruct.spatial_weights;
% permute so it is [nCells frames]
extractAnalysisOutput.traces = permute(outStruct.temporal_weights, [2 1]);

% Other run information if saving as a MAT-file.
extractAnalysisOutput.info = outStruct.info;
extractAnalysisOutput.config = outStruct.config;
extractAnalysisOutput.info = outStruct.info;
extractAnalysisOutput.userInputConfig = extractConfig;
extractAnalysisOutput.opts = outStruct.config;

% Save outputs to NWB format
if saveAnalysis==1
	ciapkg.api.saveNeurodataWithoutBorders(extractAnalysisOutput.filters,{extractAnalysisOutput.traces},'extract',[nwbFilePath '_extract.nwb']);
end

% Remove EXTRACT from the path.
ciapkg.loadBatchFxns();
```

## Manual sort output cells
```MATLAB
%% Run signal sorting using matrix inputs
[outImages, outSignals, choices] = ciapkg.api.signalSorter(IcaFilters,IcaTraces,'inputMovie',inputMovie3);
```

### Run signal sorting using NWB
```MATLAB
%% Run signal sorting using NWB
[outImages, outSignals, choices] = ciapkg.api.signalSorter([nwbFilePath '_pcaicaAnalysis.nwb'],[],'inputMovie',inputMovie3);
```

```MATLAB
%% Plot results of sorting
figure;
subplot(1,2,1);imagesc(max(IcaFilters,[],3));axis equal tight; title('Raw filters')
subplot(1,2,2);imagesc(max(outImages,[],3));axis equal tight; title('Sorted filters')
```

### Run signal sorting using multiple NWB files from cell extraction.
```MATLAB
% Run signal sorting using NWB files from cell extraction.
if saveAnalysis==1&guiEnabled==1
	disp(repmat('=',1,21));disp('Running signalSorter using NWB file input.')
	nwbFileList = ciapkg.api.getFileList(nwbFileFolderPath,'.nwb');
	if ~isempty(nwbFileList)
		nFiles = length(nwbFileList);
		outImages = {};
		outSignals = {};
		choices = {};
		for fileNo = 1:nFiles
			[outImages{fileNo}, outSignals{fileNo}, choices{fileNo}] = ciapkg.api.signalSorter(nwbFileList{fileNo},[],'inputMovie',inputMovie3);
		end

		% Plot results of sorting
		for fileNo = 1:nFiles
			try
				[inputImagesTmp,inputSignalsTmp,infoStructTmp,algorithmStrTmp,inputSignals2Tmp] = ciapkg.io.loadSignalExtraction(nwbFileList{fileNo});
				figure;
				subplot(1,2,1); 
					imagesc(max(inputImagesTmp,[],3));
					axis equal tight; 
					title([algorithmStrTmp ' | Raw filters'])
				subplot(1,2,2); 
					imagesc(max(outImages{fileNo},[],3));
					axis equal tight; 
					title('Sorted filters')
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
	end
end
```

## Overlay cells on movies as sanity check
```MATLAB
%% Create an overlay of extraction outputs on the movie and signal-based movie
[inputMovieO] = ciapkg.api.createImageOutlineOnMovie(inputMovie3,IcaFilters,'dilateOutlinesFactor',0);
[signalMovie] = ciapkg.api.createSignalBasedMovie(IcaTraces,IcaFilters,'signalType','peak');
```

```MATLAB
%% Play all three movies
% Normalize all the movies
movieM = cellfun(@(x) ciapkg.api.normalizeVector(x,'normRange','zeroToOne'),{inputMovie3,inputMovieO,signalMovie},'UniformOutput',false);
ciapkg.api.playMovie(cat(2,movieM{:}));
```

## Batch process example movies and perform cross-session cell alignment
```MATLAB
%% Run pre-processing on 3 batch movies then do cross-session alignment
batchMovieList = {...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_05_p104_m19_PAV08'],...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_06_p104_m19_PAV09'],...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_07_p104_m19_PAV10']...
};
```

```MATLAB
% USER INTERFACE Get the motion correction crop coordinates
cropCoordsCell = {};
nFolders = length(batchMovieList);
for folderNo = 1:nFolders
	analysisFolderPath = batchMovieList{folderNo};
	inputMoviePath = ciapkg.api.getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	% inputMoviePath = [analysisFolderPath filesep 'concat_recording_20140401_180333.h5'];
	inputMovie = ciapkg.api.loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName,'frameList',1:2);

	[cropCoords] = ciapkg.api.getCropCoords(squeeze(inputMovie(:,:,1)));
	% toptions.cropCoords = cropCoords;
	cropCoordsCell{folderNo} = cropCoords;
end
```

```MATLAB
%% Run pre-processing on each of the movies.
procMovieCell = cell([1 nFolders]);
for folderNo = 1:nFolders
	inputMoviePath = ciapkg.api.getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	inputMovie = ciapkg.api.loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName,'frameList',[]);
	procOpts.motionCorrectionCropCoords = cropCoordsCell{folderNo};
	procOpts.dfofMovie = 1;
	procOpts.motionCorrectionFlag = 1;
	procOpts.normalizeMovieFlag = 1;
	procOpts.normalizeType = 'divideByLowpass';
	procOpts.freqLow = 0;
	procOpts.freqHigh = 7;
	procOpts.downsampleTimeFactor = 4;
	procMovieCell{folderNo} = ciapkg.demo.runPreprocessing(inputMovie,'options',procOpts);
end
disp('Done with pre-processing!')
```

```MATLAB
%% Run cell-extraction on the movies
pcaicaStructCell = cell([1 nFolders]);
nPCs = 300;
nICs = 225;
for folderNo = 1:nFolders
	inputMoviePath = ciapkg.api.getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	pcaicaStruct{folderNo} = ciapkg.signal_extraction.runPcaIca(procMovieCell{folderNo},nPCs,nICs,'version',2,'outputUnits','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);
end
disp('Done with PCA-ICA analysis pre-processing!')
```

```MATLAB
%% Run cross-session alignment of cells
% Create input images, cell array of [x y nCells] matrices
inputImages = cellfun(@(x) x.IcaFilters,pcaicaStruct,'UniformOutput',false);

% options to change
opts.maxDistance = 5; % distance in pixels between centroids for them to be grouped
opts.trialToAlign = 1; % which session to start alignment on
opts.nCorrections = 1; %number of rounds to register session cell maps.
opts.RegisTypeFinal = 2; % 3 = rotation/translation and iso scaling; 2 = rotation/translation, no iso scaling

% Run alignment code
[alignmentStruct] = ciapkg.api.matchObjBtwnTrials(inputImages,'options',opts);

% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

% View the cross-session matched cells, saved to `private\_tmpFiles` sub-folder.
[success] = ciapkg.api.createMatchObjBtwnTrialsMaps(inputImages,alignmentStruct);
```

```MATLAB
%% Display cross-session matching movies
disp('Playing movie frames')
crossSessionMovie1 = [ciapkg.getDir filesep 'private' filesep '_tmpFiles' filesep 'matchObjColorMap50percentMatchedSession_matchedCells.avi'];
crossSessionMovie2 = [ciapkg.getDir filesep 'private' filesep '_tmpFiles' filesep 'matchObjColorMapAllMatchedSession_matchedCells.avi'];
ciapkg.api.playMovie(crossSessionMovie1,'extraMovie',crossSessionMovie2,'rgbDisplay',1);
```