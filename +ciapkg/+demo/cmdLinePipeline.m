% Running calciumImagingAnalysis (CIAPKG) imaging analysis via the command line
% Biafra Ahanonu
% Below is an example `cacliumImagingAnalysis` pipeline using the command line for users that do not want to use the calciumImagingAnalysis class or want to create their own custom batch analyses.
	% It assumes you have already run `example_downloadTestData` to download the example test data.
	% It will also run cross-day matching at the end.
	% All sections marked "USER INTERFACE" indicate that a GUI will appear to view processed movie, conduct cell sorting, or other interface.
% Changelog
	% 2020.09.15 [19:54:14] - Use ciapkg.getDir() to make sure demo always calls correct path regardless of where user is pointing. Also make playMovie calls have titles to make clearer to new users and allow a GUI-less option.
	% 2020.09.23 [08:35:58] - Updated to add support for cross-session analysis and use ciapkg.demo.runPreprocessing() to process the other imaging sessions.
	% 2020.10.17 [19:30:01] - Update to use ciapkg.signal_extraction.runPcaIca for PCA-ICA to make easier for users to run in the future.
	% 2021.01.17 [21:38:55] - Updated to show detrend example

%% Initialize
guiEnabled = 1;
saveAnalysis = 1;
inputDatasetName = '/1';
rawFileRegexp = 'concat';

%% Download test data, only a single session
example_downloadTestData('downloadExtraFiles',0);

%% Load movie to analyze
analysisFolderPath = [ciapkg.getDir() filesep 'data' filesep '2014_04_01_p203_m19_check01'];
inputMoviePath = getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
% inputMoviePath = [analysisFolderPath filesep 'concat_recording_20140401_180333.h5'];
inputMovie = loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName);

%% USER INTERFACE Visualize slice of the movie
if guiEnabled==1
	playMovie(inputMovie(:,:,1:500),'extraTitleText','Raw movie');
	% Alternatively, visualize by entering the file path
	playMovie(inputMoviePath,'extraTitleText','Raw movie directly from file');
end

%% USER INTERFACE Downsample input movie if need to
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

%% Detrend movie if needed (default linear trend), e.g. to compensate for bleaching
inputMovie = normalizeMovie(inputMovie,'normalizationType','detrend','detrendDegree',1);

%% USER INTERFACE Get coordinates to crop from the user separately
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

%% USER INTERFACE Final check of movie before cell extraction
if guiEnabled==1
	playMovie(inputMovie3,'extraTitleText','Processed movie for cell extraction');
end

%% Run PCA-ICA cell extraction
nPCs = 300;
nICs = 225;
pcaicaStruct = ciapkg.signal_extraction.runPcaIca(inputMovie3,nPCs,nICs,'version',2,'output_units','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);

%% Save outputs to NWB format
[~,folderName,~] = fileparts(analysisFolderPath);
% mkdir([analysisFolderPath filesep 'nwbFiles']);
nwbFilePath = [analysisFolderPath filesep 'nwbFiles' filesep folderName '_pcaicaAnalysis.nwb'];
if saveAnalysis==1
	saveNeurodataWithoutBorders(pcaicaStruct.IcaFilters,{pcaicaStruct.IcaTraces},'pcaica',nwbFilePath);
end

%% USER INTERFACE Run cell sorting using matrix outputs from cell extraction.
if guiEnabled==1
	[outImages, outSignals, choices] = signalSorter(pcaicaStruct.IcaFilters,pcaicaStruct.IcaTraces,'inputMovie',inputMovie3);
end

%% USER INTERFACE Run signal sorting using NWB files from cell extraction.
if saveAnalysis==1&guiEnabled==1
	disp(repmat('=',1,21));disp('Running signalSorter using NWB file input.')
	[outImages, outSignals, choices] = signalSorter(nwbFilePath,[],'inputMovie',inputMovie3);
end

%% Plot results of sorting
figure;
subplot(1,2,1);imagesc(max(IcaFilters,[],3));axis equal tight; title('Raw filters')
subplot(1,2,2);imagesc(max(outImages,[],3));axis equal tight; title('Sorted filters')

%% USER INTERFACE Create an overlay of extraction outputs on the movie and signal-based movie
[inputMovieO] = createImageOutlineOnMovie(inputMovie3,IcaFilters,'dilateOutlinesFactor',0);
if guiEnabled==1
	playMovie(inputMovieO,'extraMovie',inputMovie3,'extraTitleText','Overlay of cell outlines on processed movie');
end

[signalMovie] = createSignalBasedMovie(IcaTraces,IcaFilters,'signalType','peak');
if guiEnabled==1
	playMovie(signalMovie,'extraMovie',inputMovie3,'extraTitleText','Cell activity-based movie');
end

movieM = cellfun(@(x) normalizeVector(x,'normRange','zeroToOne'),{inputMovie3,inputMovieO,signalMovie},'UniformOutput',false);
playMovie(cat(2,movieM{:}));

%% Run pre-processing on 3 batch movies then do cross-session alignment
batchMovieList = {...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_05_p104_m19_PAV08'],...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_06_p104_m19_PAV09'],...
[ciapkg.getDir() filesep 'data' filesep 'batch' filesep '2014_08_07_p104_m19_PAV10']...
};

% USER INTERFACE Get the motion correction crop coordinates
cropCoordsCell = {};
nFolders = length(batchMovieList);
for folderNo = 1:nFolders
	analysisFolderPath = batchMovieList{folderNo};
	inputMoviePath = getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	% inputMoviePath = [analysisFolderPath filesep 'concat_recording_20140401_180333.h5'];
	inputMovie = loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName,'frameList',1:2);

	[cropCoords] = getCropCoords(squeeze(inputMovie(:,:,1)));
	% toptions.cropCoords = cropCoords;
	cropCoordsCell{folderNo} = cropCoords;
end

%% Run pre-processing on each of the movies.
procMovieCell = cell([1 nFolders]);
for folderNo = 1:nFolders
	inputMoviePath = getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	inputMovie = loadMovieList(inputMoviePath,'inputDatasetName',inputDatasetName,'frameList',[]);
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

%% Run cell-extraction on the movies
pcaicaStructCell = cell([1 nFolders]);
nPCs = 300;
nICs = 225;
for folderNo = 1:nFolders
	inputMoviePath = getFileList(analysisFolderPath,rawFileRegexp,'sortMethod','natural');
	pcaicaStruct{folderNo} = ciapkg.signal_extraction.runPcaIca(procMovieCell{folderNo},nPCs,nICs,'version',2,'outputUnits','fl','mu',0.1,'term_tol',5e-6,'max_iter',1e3);
end
disp('Done with PCA-ICA analysis pre-processing!')

%% Run cross-session alignment of cells
% Create input images, cell array of [x y nCells] matrices
inputImages = cellfun(@(x) x.IcaFilters,pcaicaStruct,'UniformOutput',false);

% options to change
opts.maxDistance = 5; % distance in pixels between centroids for them to be grouped
opts.trialToAlign = 1; % which session to start alignment on
opts.nCorrections = 1; %number of rounds to register session cell maps.
opts.RegisTypeFinal = 2; % 3 = rotation/translation and iso scaling; 2 = rotation/translation, no iso scaling

% Run alignment code
[alignmentStruct] = matchObjBtwnTrials(inputImages,'options',opts);

% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

% View the cross-session matched cells, saved to `private\_tmpFiles` sub-folder.
[success] = createMatchObjBtwnTrialsMaps(inputImages,alignmentStruct);

% Display cross-session matching movies
disp('Playing movie frames')
crossSessionMovie1 = 'private\_tmpFiles\matchObjColorMap50percentMatchedSession_matchedCells.avi';
crossSessionMovie2 = 'private\_tmpFiles\matchObjColorMapAllMatchedSession_matchedCells.avi';
playMovie(crossSessionMovie1,'extraMovie',crossSessionMovie2,'rgbDisplay',1);