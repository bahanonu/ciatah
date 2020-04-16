classdef calciumImagingAnalysis < dynamicprops
	% Performs analysis on calcium imaging data. Also performs analysis on behavior (response signals) compared to stimulus or other continuous signals during an imaging session.
	% Biafra Ahanonu
	% started: 2014.07.31
	% This is a re-write of my old code from controllerAnalysis. Encapsulating the functions and variables as methods and properties in a class should allow easier maintenance/flexibility.
	% inputs
		%
	% outputs
		%

	% changelog
		% updated: 2017.01.15 [01:31:54]
		% 2019.05.08 [10:59:59] - Added check for required toolboxes used in class.
		% 2019.07.25 [09:39:16] - Updated loading so that users only need to be in the root calciumImagingAnalysis path but required folders do not need to be loaded.
		% 2019.08.20 [09:33:32] - Improved loading of folders and Miji to save time.
		% 2019.08.30 [12:58:37] - Added Java heap space memory check on initialization.
		% 2019.09/10 - Added GUI font option and signalExtractionTraceOutputType.
		% 2019.10.15 [21:57:45] - Improved checking for directories that should not be loaded, remove need for verLessThan('matlab','9.0') check.
		% 2019.12.22 [09:01:38] - Re-vamped selection list dialog boxes for methods, cell-extraction, folders, etc. Now loads as a figure and for some (like methods list) has tooltips that describe each list item.
	% TODO
		%

	% dynamicprops is a subclass of handle, allowing addition of properties

	properties(GetAccess = 'public', SetAccess = 'public')
		% public read and write access.

		% FPS of movie(s) being analyzed
		FRAMES_PER_SECOND =  5;
		% Int: what factor temporally are analyzed movie from raw data
		DOWNSAMPLE_FACTOR =  4;
		% Float: estimated um per pixel
		MICRON_PER_PIXEL =  2.51; % 2.37;

		% Int: set the default UI font size
		fontSizeGui = 10;

		defaultObjDir = pwd;
		classVersion = 'v3.9.0-20200416';
		serverPath = '';
		privateSettingsPath = ['private' filesep 'settings' filesep 'privateLoadBatchFxns.m'];
		% place where functions can temporarily story user settings
		functionSettings = struct(...
			'null', NaN...
		);

		% user information
		userName = 'USA';

		% counters and stores
		% index of current folder
		fileNum = 1;
		% same as fileNum, will transfer to this since more clear
		folderNum = 1;
		% number to current stimulus index
		stimNum = 1;

		% Github repo path, for updating the repository code
		githubUrl = 'https://github.com/bahanonu/calciumImagingAnalysis';
		% Folder to put downloaded external programs
		externalProgramsDir = '_external_programs';

		% String: name of the analysis file to put in a folder to indicate to other computers the current computer is analyzing the folder and they should skip
		concurrentAnalysisFilename = '_currentlyAnalyzingFolderCheck.mat';

		% Cell array strings: List of methods to fast track folder to analyze dialog or skip altogether
		methodExcludeList = {'showVars','showFolders','setMainSettings','modelAddNewFolders','loadDependencies','saveObj','setStimulusSettings','modelDownsampleRawMovies','setMovieInfo','setup','update'};
		methodExcludeListVer2 = {'modelEditStimTable','behaviorProtocolLoad','modelPreprocessMovie','modelModifyMovies','removeConcurrentAnalysisFiles'};
		methodExcludeListStimuli = {'modelVarsFromFiles'};

		% 0 = load variables from disk, reduce RAM usage. 1 = load from disk to ram, faster for analysis.
		loadVarsToRam = 0;
		% show GUI for view functions?
		guiEnabled = 1;
		% indices for folders to analyze, [] = all
		foldersToAnalyze = [];
		% indices for stimuli to analyze, [] = all
		discreteStimuliToAnalyze = [];
		% io settings
		fileFilterRegexp = 'crop';
		% Regular expression for alternative file
		fileFilterRegexpAlt = 'crop';
		% Regular expression for alternative file during cell extraction
		fileFilterRegexpAltCellExtraction = '';
		% raw movie
		fileFilterRegexpRaw = 'concat';
		% behavior video regexp
		behaviorVideoRegexp = '';
		% loop over all files during analysis? 'individual' or 'group'
		analysisType  = 'group';
		% 1 = perform certain analysis on dF/F instead of peaks
		dfofAnalysis = 0;
		% 'filtered' returns auto/manually filtered signals/images, 'raw' returns raw
		modelGetSignalsImagesReturnType = 'filtered'
		% name of input dataset name for preprocessing
		inputDatasetName = '/1';
		% name of output dataset name for preprocessing
		outputDatasetName = '/1';
		%
		stimTriggerOnset = 0;
		% paths for specific types of files
		currentDateTimeSessionStr = datestr(now,'yyyymmdd_HHMMSS_FFF','local');
		currentDateTimeStr = datestr(now,'yyyymmdd','local');
		picsSavePath = ['private' filesep 'pics' filesep datestr(now,'yyyymmdd','local') filesep];
		dataSavePath = ['private' filesep 'data' filesep datestr(now,'yyyymmdd','local') filesep];
		dataSavePathFixed = ['private' filesep 'data' filesep];
		logSavePath = ['private' filesep 'logs' filesep datestr(now,'yyyymmdd','local') filesep];
		settingsSavePath = ['private' filesep 'settings'];
		%
		dataSaveFilenameModifier = '';
		% table save
		delimiter = ',';
		% name of i/o HDF5 dataset names
		hdf5Datasetname = '/1';
		% type of images to save analysis as '-dpng','-dmeta','-depsc2'
		imgSaveTypes = {'-dpng'};
		% Custom subject regexp find string to pass to getFileInfo
		subjectRegexp = '(m|M|f|F|Mouse|mouse|Mouse_|mouse_)\d+';
		% colormap to be used
		% colormap = customColormap([]);
		% colormap = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
		% colormap = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
		% colormapAlt = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
		% colormapAlt2 = diverging_map(linspace(0,1,100),[0 0 0.7],[0.7 0 0]);
		colormap = parula(100);
		colormapAlt = parula(100);
		colormapAlt2 = parula(100);
		% colormap = customColormap({[27 52 93]/256,[1 1 1],[106 41 50]/256},'nPoints',50);
		% use for stimulus related viewing functions
		% frames before/after stimulus to look
		timeSequence = [-25:25];
		postStimulusTimeSeq = [0:10];
		% bin analysis, integer only
		binDownsampleAmount = 1;
		% number of standard deviation for threshold crossing
		numStdsForThresh = 2.5;
		%
		stimulusTableValueName = 'frameSessionDownsampled';
		stimulusTableFrameName = 'frameSessionDownsampled';
		stimulusTableResponseName = 'response';
		stimulusTableTimeName = 'time';
		stimulusTableSessionName = 'trial';

		% methods
		currentMethod = 'modelAddNewFolders';

		% Region analysis
		regionModSaveStr = '_regionModSelectUser.mat'

		usrIdxChoiceStr = {'EM','PCAICA','EXTRACT','CNMF','CNMFE','ROI'};
		usrIdxChoiceDisplay = {'CELLMax (Kitch/Ahanonu)','PCAICA (Mukamel, 2009)','EXTRACT (Inan, 2017)','CNMF (Pnevmatikakis, 2016 or Giovannucci, 2019)','CNMF-E (Zhou, 2018)','ROI'};

		% PCAICA, EM, EXTRACT, CNMF, CNMFE
		signalExtractionMethod = 'PCAICA';
		% signalExtractionMethod = 'EM';
		% Int: indicates which trace output to use from 1 = primary trace, 2 = secondary trace, etc.
		signalExtractionTraceOutputType = 1;

		extractionMethodSaveStr = struct(...
			'PCAICA', '_pcaicaAnalysis',...
			'EM', '_emAnalysis',...
			'CELLMax','_cellmaxAnalysis',...
			'EXTRACT', '_extractAnalysis',...
			'CNMF', '_cnmfAnalysis',...
			'CNMFE', '_cnmfeAnalysis',...
			'ROI', '_roiAnalysis'...
		);
		extractionMethodStructSaveStr = struct(...
			'PCAICA', '_pcaicaAnalysis.mat',...
			'EM', '_emAnalysis.mat',...
			'EXTRACT', '_extractAnalysis.mat',...
			'CNMF', '_cnmfAnalysis.mat',...
			'CNMFE', '_cnmfeAnalysis.mat',...
			'ROI', '_roiAnalysis.mat'...
		);
		extractionMethodSortedSaveStr = struct(...
			'PCAICA', '_ICdecisions.mat',...
			'EM', '_emAnalysisSorted.mat',...
			'EXTRACT', '_extractAnalysisSorted.mat',...
			'CNMF', '_cnmfAnalysisSorted.mat',...
			'CNMFE', '_cnmfeAnalysisSorted.mat',...
			'ROI', '_roiAnalysisSorted.mat'...
		);
		extractionMethodClassifierSaveStr = struct(...
			'PCAICA', '_ICclassifierDecisions.mat',...
			'EM', '_emAnalysisClassifierDecisions.mat',...
			'EXTRACT', '_extractAnalysisClassifierDecisions.mat',...
			'CNMF', '_cnmfAnalysisClassifierDecisions.mat',...
			'CNMFE', '_cnmfeAnalysisClassifierDecisions.mat',...
			'ROI', '_roiAnalysisClassifierDecisions.mat'...
		);
		extractionMethodValidVarname = struct(...
			'PCAICA', 'valid',...
			'EM', 'validCellMax',...
			'EXTRACT', 'validEXTRACT',...
			'CNMF', 'validCNMF',...
			'CNMFE', 'validCNMFE',...
			'ROI', 'validROI'...
		);
		extractionMethodStructVarname = struct(...
			'PCAICA', 'pcaicaAnalysisOutput',...
			'EM', 'emAnalysisOutput',...
			'EXTRACT', 'extractAnalysisOutput',...
			'CNMF', 'cnmfAnalysisOutput',...
			'CNMFE', 'cnmfeAnalysisOutput',...
			'ROI', 'roiAnalysisOutput'...
		);

		% PCAICA names
		rawPCAICAStructSaveStr = '_pcaicaAnalysis.mat';
		rawICfiltersSaveStr = '_ICfilters.mat';
		rawICtracesSaveStr = '_ICtraces.mat';
		sortedICfiltersSaveStr = '_ICfilters_sorted.mat';
		sortedICtracesSaveStr = '_ICtraces_sorted.mat';
		sortedICdecisionsSaveStr = '_ICdecisions.mat';
		classifierICdecisionsSaveStr = '_ICclassifierDecisions.mat';
		structPCAICAVarname = 'pcaicaAnalysisOutput';
		validPCAICAStructVarname = 'valid';
		% ROI names
		rawROIStructSaveStr = '_roiAnalysis.mat';
		sortedRoiStructSaveStr = '_roiAnalysisSorted.mat';
		structROIVarname = 'roiAnalysisOutput';
		classifierRoiStructSaveStr = '_roiAnalysisClassifierDecisions.mat';
		rawROItracesSaveStr = '_ROItraces.mat';
		validRoiStructVarname = 'validROI';
		% EM names
		rawEMStructSaveStr = '_emAnalysis.mat';
		sortedEMStructSaveStr = '_emAnalysisSorted.mat';
		classifierEMStructSaveStr = '_emAnalysisClassifierDecisions.mat';
		structEMVarname = 'emAnalysisOutput';
		validEMStructVarname = 'validCellMax';
		% EXTRACT names
		rawEXTRACTStructSaveStr = '_extractAnalysis.mat';
		sortedEXTRACTStructSaveStr = '_extractAnalysisSorted.mat';
		classifierEXTRACTStructSaveStr = '_extractAnalysisClassifierDecisions.mat';
		validEXTRACTStructVarname = 'validEXTRACT';
		structEXTRACTVarname = 'extractAnalysisOutput';
		% CNMF names
		rawCNMFStructSaveStr = '_cnmfAnalysis.mat';
		sortedCNMFStructSaveStr = '_cnmfAnalysisSorted.mat';
		classifierCNMFStructSaveStr = '_cnmfAnalysisClassifierDecisions.mat';
		validCNMFStructVarname = 'validCNMF';
		structCNMRVarname = 'cnmfAnalysisOutput';

		% NWB-related properties
		% Whether to load NWB files, e.g. from modelExtractSignalsFromMovie
		nwbLoadFiles = 0;
		% Str: sub-folder where NWB files are stored. Leave blank to load from current folder.
		nwbFileFolder = 'nwbFiles';
		% Str: blank, use calciumImagingAnalysis regexp, else force use of this regexp for NWB files
		nwbFileRegexp = '';
		% Name of H5 group for images and signal series in NWB files
		nwbGroupImages = '/processing/ophys/ImageSegmentation/PlaneSegmentation1';
		nwbGroupSignalSeries = '/processing/ophys/fluorescence/Series';

		settingOptions = struct(...
			'analysisType',  {{'group','individual'}},...
			'loadVarsToRam', {{0,1}},...
			'guiEnabled', {{0,1}},...
			'dfofAnalysis', {{0,1}},...
			'picsSavePath', {{['private' filesep 'pics' filesep datestr(now,'yyyymmdd','local') filesep]}},...
			'delimiter', {{',','tab'}},...
			'imgSaveTypes', {{'-dpng','-dmeta','-depsc2'}}...
		);

		filterImageOptions = struct(...
			'minNumPixels', 10,...
			'maxNumPixels', 100,...
			'SNRthreshold', 1.45,...
			'minPerimeter', 5,...
			'maxPerimeter', 50,...
			'minSolidity', 0.8,...
			'minEquivDiameter', 3,...
			'maxEquivDiameter', 30,...
			'slopeRatioThreshold', 0.04...
		);

		downsampleRawOptions = struct(...
			'folderListInfo','USER_PATH',...
			'downsampleSaveFolder','USER_PATH',...
			'downsampleSrcFolder','USER_PATH',...
			'downsampleFactor','4',...
			'fileFilterRegexp','(recording.*.hdf5|recording.*.tif|.*.isxd)',...
			'datasetName','/images',...
			'maxChunkSize','25000',...
			'srcFolderFilterRegexp','201\d',...
			'srcSubfolderFileFilterRegexp','(recording.*.(txt|xml)|*.gpio)',...
			'srcSubfolderFileFilterRegexpExt','(.txt|.xml|.gpio)',...
			'downsampleSaveFolderTwo','',...
			'downsampleFactorTwo','2',...
			'outputDatasetName','/1'...
		);

		% Pre-processing options
		% Empty by default, if user opts to keep pre-process settings, this is saved as a struct.
		preprocessSettings = [];
		saveLoadPreprocessingSettings = 0;
		motionCorrectionRefFrame = 100;

		% io folders
		inputFolders = {};
		videoDir = '';
		videoSaveDir = '';
		trackingDir = '';
		stimulusDir = '';
		% if want to automatically save object to a specific location.
		objSaveLocation = [];

		% signal related
		% either the raw signals (traces) or
		rawSignals = {};
		% secondary either the raw signals (traces) or
		rawSignals2 = {};
		%
		rawImages = {};
		% computed signal peaks/locations, to reduce computation in functions
		signalPeaks = {};
		%
		signalPeaksArray = {};
		% computed centroid locations {[x y],...}
		objLocations = {};
		% mean correlation coefficient between image and movie
		imageMovieCorr = {};
		% cellmaps indicating which cells were filtered
		rawImagesFiltered = {};
		% structure of classifier structures, each field in the property should be named after the folder's subject, e.g. classifierStructs.m667 is the classification structure for subject m667
		classifierStructs = {};
		% structure of classifier structures for each folder, e.g. after running classification on each
		classifierFolderStructs = {};
		% cell array with {signalNo}.signalFeatures, {signalNo}.imageFeatures
		classifierFeatures = {};
		% cell array with {signalNo}.signalFeatures, {signalNo}.imageFeatures
		classifierImageFeaturesNames = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity'};
		% structure for all valid classifications to go
		valid = {};
		% Automated or manual classification
		validManual = {};
		% from automated classification
		validAuto = {};
		% valid cells based on a regional modification
		validRegionMod = {};
		% polygon vertices from previously selected regions
		validRegionModPoly = {};
		% whether or not rawSignals/rawImages have been replaced by only valid signals, hence, ignore validManual/validAuto
		validPurge = 0;
		% ROI to use for exclusion analysis
		analysisROIArray = {};
		% number of expected [PCs ICs] for PCA-ICA, alter for other procedures
		numExpectedSignals = {};

		% subject info
		% all are cell array of strings or numbers as specified in the name
		dataPath = {};
		subjectNum = {};
		subjectStr = {};
		subjectProtocolStr = {};
		assay = {};
		protocol = {};
		assayType = {};
		assayNum = {};
		imagingPlane = {};
		imagingPlaneNum = {};
		date = {};
		fileIDArray = {};
		fileIDNameArray = {};
		folderBaseSaveStr = {};
		folderBasePlaneSaveStr = {};
		folderBaseDisplayStr = {};
		folderBaseSaveStrUnique = {};

		% path to CSV/TAB file or matlab table containing trial information and frames when stimuli occur
		discreteStimulusTable = {};
		% cell array of strings
		stimulusNameArray = {};
		% cell array of strings, used for saving pictures/etc.
		stimulusSaveNameArray = {};
		% cell array of numbered values for stimulus, e.g. {65,10}
		stimulusIdArray = {};
		% [1 numTrialFrames] vectors with 1 for when stimulus occurs
		stimulusVectorArray = {};
		% vector sequence before/after to analyze stimulus
		stimulusTimeSeq = {};

		% path to a CSV/TAB file
		continuousStimulusTable = {};
		% cell array of strings
		continuousStimulusNameArray = {};
		% cell array of strings, used for saving pictures/etc.
		continuousStimulusSaveNameArray = {};
		% cell array of numbered values for stimulus, e.g. {65,10}
		continuousStimulusIdArray = {};
		% [1 numTrialFrames] vectors with 1 for when stimulus occurs
		continuousStimulusVectorArray = {};
		% vector sequence before/after to analyze stimulus
		continuousStimulusTimeSeq = {};

		% session trial names
		sessionTrialNames = '';

		% behavior metrics
		behaviorMetricTable = {};
		behaviorMetricNameArray = {};
		behaviorMetricIdArray = {};

		% List of available calciumImagingAnalysis methods
		methodsList = {...
		'------- SETUP -------',
		'modelAddNewFolders',
		'setup',
		'update',
		'loadDependencies',
		'setMovieInfo',
		'resetMijiClass',
		'',
		'------- CLASS/BEHAVIOR -------',
		'showVars',
		'showFolders',
		'saveObj',
		'initializeObj',
		'setMainSettings',
		'',
		'------- DATA CHECK/LOAD/EXPORT -------',
		'modelGetFileInfo',
		'modelVerifyDataIntegrity',
		'modelBatchCopyFiles',
		'modelLoadSaveData',
		'modelExportData',
		'',
		'------- PREPROCESS -------',
		'modelDownsampleRawMovies',
		'viewMovieFiltering',
		'viewMovieRegistrationTest',
		'',
		'viewMovie',
		'modelPreprocessMovie',
		'modelModifyMovies',
		'removeConcurrentAnalysisFiles',
		'',
		'------- CELL/SIGNAL EXTRACTION -------',
		'modelExtractSignalsFromMovie',
		'viewCellExtractionOnMovie',
		'removeConcurrentAnalysisFiles',
		'',
		'------- LOAD CELL-EXTRACTION/SIGNAL DATA -------',
		'modelVarsFromFiles',
		'',
		'------- SIGNAL SORTING -------',
		'computeManualSortSignals',
		'modelModifyRegionAnalysis',
		'',
		'------- PREPROCESS VERIFICATION -------',
		'viewMovie',
		'viewObjmaps',
		'viewCreateObjmaps',
		'viewSubjectMovieFrames'
		'viewMovieCreateSideBySide',
		'',
		'------- TRACKING -------',
		'modelTrackingData',
		'viewOverlayTrackingToVideo',
		'',
		'------- ACROSS SESSION ANALYSIS: COMPUTE/VIEW -------',
		'viewSubjectMovieFrames',
		'computeMatchObjBtwnTrials',
		'viewMatchObjBtwnSessions',
		'modelSaveMatchObjBtwnTrials',
		'computeCellDistances',
		'computeCrossDayDistancesAlignment'
		};

		% Tooltips for calciumImagingAnalysis methods
		tts = struct(...
			'SETUP', 'Methods for setting up the class.',...
			'modelAddNewFolders', 'Add new folders to calciumImagingAnalysis.',...
			'setup', 'Setup calciumImagingAnalysis if running for the 1st time or need to re-install dependencies (e.g. Fiji).',...
			'update', 'Update calciumImagingAnalysis, direct user toward relevant web address.',...
			'loadDependencies', 'Download and setup calciumImagingAnalysis dependencies.',...
			'setMovieInfo', 'Set information',...
			'resetMijiClass', 'Reset Fiji (e.g. Miji) if having problems loading.',...
			'CLASS_BEHAVIOR', 'Methods for modifying calciumImagingAnalysis behavior or saving.',...
			'showVars', 'Show all properties for this instance of calciumImagingAnalysis.',...
			'showFolders', 'Show all folders users have loaded into the class.',...
			'saveObj', 'Save this instance of the object for later loading.',...
			'initializeObj', 'IGNORE.',...
			'setMainSettings', 'IGNORE.',...
			'DATA_CHECK_LOAD_EXPORT', 'Methods for verify data and updating calciumImagingAnalysis meta-data.',...
			'modelGetFileInfo', 'Update information about each folder loaded into the class. Information derived from folder name.',...
			'modelVerifyDataIntegrity', 'Various sub-methods to verify data is valid and that certain files are present in each folder.',...
			'modelBatchCopyFiles', 'Batch copy files from one location to another or to move files to sub-folders within each folder (e.g. if users want to archive particular files).',...
			'modelLoadSaveData', 'IGNORE.',...
			'modelExportData', 'IGNORE.',...
			'PREPROCESS', 'Methods for pre-processing imaging movies.',...
			'modelDownsampleRawMovies', 'Spatially downsample large raw movies. Done in chunks so can process movies larger than available RAM.',...
			'viewMovieFiltering', 'IGNORE.',...
			'viewMovieRegistrationTest', 'Allows users to test several pre-processing setting to choose one that works best for their dataset.<br>Mainly focused on motion correction and spatial filtering.',...
			'viewMovie', 'Allows users to view their movie in several ways for each folder.',...
			'modelPreprocessMovie', 'Main pre-processing method to do motion correction, spatial filtering, calculate relative fluorescence, etc.',...
			'modelModifyMovies', 'Used to add user-defined borders to the movie.<br>e.g. if want to blank out areas outside GRIN lens so they do not interfere with cell extraction, etc.',...
			'removeConcurrentAnalysisFiles', 'Removes temporary files created when running analysis across multiple workstations in "modelPreprocessMovie" or "modelExtractSignalsFromMovie".',...
			'CELL_SIGNAL_EXTRACTION', 'Methods related to cell extraction.',...
			'modelExtractSignalsFromMovie', 'Main method to allow pre-processing',...
			'viewCellExtractionOnMovie', 'Overlays cell-extraction outputs on the imaging movie to allow users to verify cell shape, that cells were not missed, etc.',...
			'LOAD_CELL_EXTRACTION_SIGNAL_DATA', 'Methods relating to loading cell-extraction data into calciumImagingAnalysis.',...
			'modelVarsFromFiles', 'Load cell-extraction data into calciumImagingAnalysis.<br>RUN EACH TIME re-loading calciumImagingAnalysis and have already run cell extraction on the folders added to calciumImagingAnalysis.',...
			'SIGNAL_SORTING', 'Methods relating to sorting/classification of cell-extraction outputs.',...
			'computeManualSortSignals', 'A GUI that allows ',...
			'modelModifyRegionAnalysis', '',...
			'PREPROCESS_VERIFICATION', '',...
			'viewObjmaps', 'Creates several figures displaying cell-extraction outputs from each selected folder.',...
			'viewCreateObjmaps', 'Creates several figures displaying cell-extraction outputs from each selected folder.',...
			'viewSubjectMovieFrames', 'Takes frames or cell-extraction cell maps from each folder associated with an animal and displays them as a movie to help aid in visual inspection of cross-session alignment possibilities.',...
			'viewMovieCreateSideBySide', 'Combines synchronized imaging and behavior or other experimental videos to allow side-by-side comparisons.',...
			'TRACKING', 'Methods related to tracking animals.',...
			'modelTrackingData', 'After running ImageJ-based tracking, use this module to clean-up the data and overlay it on the behavior movie.',...
			'viewOverlayTrackingToVideo', 'Creates a video where the animal''s computed centroid and velocity is overlaid on the video.',...
			'ACROSS_SESSION_ANALYSIS__COMPUTE_VIEW', 'Methods related to aligning cells across imaging sessions.',...
			'computeMatchObjBtwnTrials', 'Main method to match cell-extraction outputs (e.g. cells) across imaging sessions.',...
			'viewMatchObjBtwnSessions', 'Allows users to visualize cross session matches and outputs videos to help with assessment as well.',...
			'modelSaveMatchObjBtwnTrials', 'IGNORE for now. Will allow users to save output of cross-session matching.',...
			'computeCellDistances', 'Computes the cell-cell distance for all cells in each imaging session and outputs as a CSV table.<br>Should be used to assess the largest distance to still count cells as matching during cross-session matching.',...
			'computeCrossDayDistancesAlignment', 'Computes the cell-cell distance of all cross-session matched cells.<br>e.g. ideally all will be below the cross-session cell distance cutoff.'...
		);
	end
	properties(GetAccess = 'public', SetAccess = 'private')
		% public read access, but private write access.

		% summary statistics data save stores
		sumStats = {};
		detailStats = {};
		tmpStats = {};
		saveDataType = {};

		% counters and stores
		figNames = {};
		figNo = {};
		figNoAll = 777;

		% signal related
		nSignals = {};
		nFrames = {};
		signalPeaksCopy = {};
		alignedSignalArray = {};
		alignedSignalShuffledMeanArray = {};
		alignedSignalShuffledStdArray = {};

		% stimulus
		% reorganize discreteStimulusTable into stimulus structures to reduce memory footprint
		discreteStimulusArray = {};
		discreteStimMetrics = {};

		% stimulus
		% reorganize discreteStimulusTable into stimulus structures to reduce memory footprint
		continuousStimulusArray = {};
		continuousStimMetrics = {};

		% behavior metric
		% reorganize behaviorMetricTable into stimulus structures to reduce memory footprint/provide common IO
		behaviorMetricArray = {};

		% for each folder have a structure containing different metrics.
		neuroBehaviorMetric = {};

		% distance metrics
		distanceMetric = {};
		distanceMetricShuffleMean = {};
		distanceMetricShuffleStd = {};

		% correlation metrics
		corrMatrix = {};

		% significant signals, different variables for controlling which signals are statistically significant, given some test
		currentSignificantArray = [];
		significantArray = {};
		significantStatsArray = {};
		sigModSignals = {};
		sigModSignalsAll = {};
		ttestSignSignals = {};

		% cross session alignment
		globalIDs = [];
		globalIDCoords = {};
		globalIDFolders = {};
		globalIDImages = {};
		globalRegistrationCoords = {};
		globalObjectMapTurboreg = [];
		globalStimMetric = [];
	end
	properties(GetAccess = 'private', SetAccess = 'private')
		% private read and write access
	end
	properties(Constant = true)
		% cannot be changed after object is created
		% MICRON_PER_PIXEL =  2.37;
	end

	methods
		% methods, including the constructor are defined in this block
		function obj = calciumImagingAnalysis(varargin)
			% CLASS CONSTRUCTOR
			warning on;
			clc
			% ' Calcium Imaging Analysis Class
			disp([...
			'calciumImagingAnalysis' 10 ...
			'A software package for analyzing one- and two-photon calcium imaging datasets.' 10 10 ...
			'Biafra Ahanonu <<a href="emailto:bahanonu@alum.mit.edu">bahanonu@alum.mit.edu</a>>' 10 ...
			'Version ' obj.classVersion 10 10 ...
			'Made in USA' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			'* * * * * * * * * * :::::::::::::::::::::::::' 10 ...
			'* * * * * * * * * * =========================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10 ...
			':::::::::::::::::::::::::::::::::::::::::::::' 10 ...
			'=============================================' 10])

			disp(repmat('*',1,42))
			disp('Constructing calciumImagingAnalysis imaging analysis object...')

			% Ensure that default directory is the calciumImagingAnalysis repository root
			functionLocation = dbstack('-completenames');
			functionLocation = functionLocation(1).file;
			[functionDir,~,~] = fileparts(functionLocation);
			[functionDir,~,~] = fileparts(functionDir);
			obj.defaultObjDir = functionDir;
			clear functionDir functionLocation;

			obj.loadBatchFunctionFolders();
			disp(repmat('*',1,42))

			% Because the obj
			%========================
			% obj.exampleOption = '';
			% get options
			obj = getOptions(obj,varargin);
			% disp(options)
			% unpack options into current workspace
			% fn=fieldnames(options);
			% for i=1:length(fn)
			%	 eval([fn{i} '=options.' fn{i} ';']);
			% end
			%========================

			obj = initializeObj(obj);

			disp(repmat('*',1,42))
			disp('Done initializing calciumImagingAnalysis!')
			disp(repmat('*',1,42))

			disp([...
			'Run processing pipeline by typing below (or clicking link) into command window (no semi-colon!):' 10 ...
			'<a href="matlab: obj">obj</a>'])

			% disp([...
			% 'Run processing pipeline by typing into command window:' 10 ...
			% '<a href="">obj.runPipelineProcessing</a>' 10 ...
			% 'or for advanced features: ' 10 ...
			% '<a href="">obj.runPipeline</a>' 10])
		end
		% getter and setter functions
		function dataPath = get.dataPath(obj)
			dataPath = obj.dataPath;
		end
	end
	methods(Static = true)
		% functions that are related but not dependent on instances of the class
		% function obj = loadObj(oldObj)
		%	  [filePath,folderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
		%	  % exit if user picks nothing
		%	  % if folderListInfo==0; return; end
		%	  load([folderPath filesep filePath]);
		%	  oldObj = obj;
		%	  obj = calciumImagingAnalysis;
		%	  obj = getOptions(obj,oldObj);
		% end
	end
	methods(Access = private)
		% methods only executed by other class methods

		% model methods, usually for input-output like saving information to files
		% for obtaining the current stim from tables
		[behaviorMetric] = modelGetBehaviorMetric(obj,inputID)
	end
	methods(Access = protected)
		% methods only executed by other class methods, also available to subclasses
	end
	methods(Access = public)
		% these are in separate M-files

		[output output2] = modelGetStim(obj,idNum,varargin)

		% view help about the object
		obj = help(obj)

		% specific experiments


		% compute methods, performs some computation and returns calculation to class property
		obj = computeMatchObjBtwnTrials(obj,varargin)
		obj = computeManualSortSignals(obj)
		obj = computeClassifyTrainSignals(obj)

		% just need stimulus files

		% view methods, for displaying charts
		% no prior computation
		obj = viewCreateObjmaps(obj,varargin)

		% pre-processing checking
		obj = viewMovie(obj)
		obj = viewMovieFiltering(obj)
		obj = viewMovieRegistrationTest(obj)
		obj = viewMovieCreateSideBySide(obj)
		obj = modelModifyMovies(obj)
		obj = viewCellExtractionOnMovie(obj,varargin)

		% require pre-computation, individual

		% require pre-computation, group, global alignment
		obj = viewMatchObjBtwnSessions(obj,varargin)
		% movies

		% require pre-computation and behavior metrics, individual

		% requires manual sorting

		% need tracking
		obj = viewOverlayTrackingToVideo(obj)

		% model methods, usually for input-output like saving information to files
		obj = modelAddNewFolders(obj,varargin)
		obj = modelExportData(obj,varargin)
		obj = modelReadTable(obj,varargin)
		obj = modelTableToStimArray(obj,varargin)
		obj = modelGetFileInfo(obj)
		obj = modelVerifyDataIntegrity(obj)
		obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID,varargin)
		obj = modelSaveSummaryStats(obj,varargin)
		obj = modelSaveDetailedStats(obj)
		obj = modelVarsFromFiles(obj)
		obj = modelModifyRegionAnalysis(obj,varargin)
		obj = modelExtractSignalsFromMovie(obj,varargin)
		obj = modelPreprocessMovie(obj)
		obj = modelDownsampleRawMovies(obj)
		obj = modelBatchCopyFiles(obj)
		obj = modelLoadSaveData(obj)
		obj = modelSaveMatchObjBtwnTrials(obj,varargin)

		% helps clean and load tracking data
		obj = modelTrackingData(obj)

		% helper
		[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid, validType, inputSignals2] = modelGetSignalsImages(obj,varargin)
		[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = getAnalysisSubsetsToAnalyze(obj)
		[preprocessSettingStruct, preprocessingSettingsAll] = getRegistrationSettings(obj,inputTitleStr,varargin)

		% set methods, for IO to specific variables in a controlled manner
		obj = setMainSettings(obj)

		function obj = initializeObj(obj)
			% load dependencies.
			loadBatchFxns();
			cnmfVersionDirLoad('none','displayOutput',0);
			% [success] = cnmfVersionDirLoad('cnmfe');

			% Load colormaps
			obj.colormap = customColormap({[0 0 1],[1 1 1],[0.5 0 0],[1 0 0]});
			obj.colormapAlt = customColormap({[0 0 0.7],[1 1 1],[0.7 0 0]});
			obj.colormapAlt2 = diverging_map(linspace(0,1,100),[0 0 0.7],[0.7 0 0]);

			% Check required toolboxes are available, warn if not
			disp(repmat('*',1,42))
			toolboxList = {...
			'distrib_computing_toolbox',...
			'image_toolbox',...
			'signal_toolbox',...
			'statistics_toolbox',...
			};
			secondaryToolboxList = {...
				'video_and_image_blockset',...
				'bioinformatics_toolbox',...
				'financial_toolbox',...
				'neural_network_toolbox',...
			};
			allTollboxList = {toolboxList,secondaryToolboxList};
			nLists = length(allTollboxList);
			for listNo = 1:nLists
				toolboxListHere = allTollboxList{listNo};
				nToolboxes = length(toolboxListHere);
				if listNo==1
				else
					disp('2nd tier toolbox check (not required for main pre-processing pipeline).')
				end
				for toolboxNo = 1:nToolboxes
					toolboxName = toolboxListHere{toolboxNo};
					if license('test',toolboxName)==1
						fprintf('Toolbox available! %s\n',toolboxName)
					else
						if listNo==1
							warning('Please install %s toolbox before running calciumImagingAnalysis. This toolbox is likely required.',toolboxName);
						else
							warning('Please install %s toolbox before running calciumImagingAnalysis. Some features (e.g. for cell extraction) may not work otherwise.',toolboxName);
						end
						% if ~verLessThan('matlab', '9.5')
						%	  warning('Please install Neural Network toolbox before running classifySignals');
						% else
						%	  warning('Please install Deep Learning Toolbox before running classifySignals');
						% end
						% return;
					end
				end
			end
			disp(repmat('*',1,42))

			% Ensure date paths are up to date
			obj.picsSavePath = ['private' filesep 'pics' filesep datestr(now,'yyyymmdd','local') filesep];
			obj.dataSavePath = ['private' filesep 'data' filesep datestr(now,'yyyymmdd','local') filesep];
			obj.logSavePath = ['private' filesep 'logs' filesep datestr(now,'yyyymmdd','local') filesep];
			obj.settingsSavePath = ['private' filesep 'settings'];
			obj.videoSaveDir = ['private' filesep 'vids' filesep datestr(now,'yyyymmdd','local') filesep];

			% ensure private folders are set
			if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);fprintf('Creating directory: %s\n',obj.picsSavePath);end
			if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);fprintf('Creating directory: %s\n',obj.dataSavePath);end
			if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);fprintf('Creating directory: %s\n',obj.logSavePath);end
			if ~exist(obj.settingsSavePath,'dir');mkdir(obj.settingsSavePath);fprintf('Creating directory: %s\n',obj.settingsSavePath);end
			if ~exist(obj.videoSaveDir,'dir');mkdir(obj.videoSaveDir);fprintf('Creating directory: %s\n',obj.videoSaveDir);end

			% load user specific settings
			loadUserSettings = ['private' filesep 'settings' filesep 'calciumImagingAnalysisInitialize.m'];
			if exist(loadUserSettings,'file')~=0
				run(loadUserSettings);
			else
				% create privateLoadBatchFxns.m
			end

			% if use puts in a single folder or a path to a txt file with folders
			if ~isempty(obj.rawSignals)&ischar(obj.rawSignals)
				if isempty(regexp(obj.rawSignals,'.txt'))&exist(obj.rawSignals,'dir')==7
					% user just inputs a single directory
					obj.rawSignals = {obj.rawSignals};
				else
					% user input a file linking to directories
					fid = fopen(obj.rawSignals, 'r');
					tmpData = textscan(fid,'%s','Delimiter','\n');
					obj.rawSignals = tmpData{1,1};
					fclose(fid);
				end
				obj.inputFolders = obj.rawSignals;
				obj.dataPath = obj.rawSignals;
			end
			% add subject information to object given datapath
			if ~isempty(obj.dataPath)
				obj.modelGetFileInfo();
			else
				disp('No folder paths input, run <a href="matlab: obj.currentMethod=''modelAddNewFolders'';obj">modelAddNewFolders</a> method to add new folders.');
				% warning('Input data paths for all files!!! option: dataPath')
			end
			if ~isempty(obj.discreteStimulusTable)&~strcmp(class(obj.discreteStimulusTable),'table')
				obj.modelReadTable('table','discreteStimulusTable');
				obj.modelTableToStimArray('table','discreteStimulusTable','tableArray','discreteStimulusArray','nameArray','stimulusNameArray','idArray','stimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName);
			end
			if ~isempty(obj.continuousStimulusTable)&~strcmp(class(obj.continuousStimulusTable),'table')
				obj.delimiter = ',';
				obj.modelReadTable('table','continuousStimulusTable','addFileInfoToTable',1);
				obj.delimiter = ',';
				obj.modelTableToStimArray('table','continuousStimulusTable','tableArray','continuousStimulusArray','nameArray','continuousStimulusNameArray','idArray','continuousStimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName,'grabStimulusColumnFromTable',1);
			end
			% load behavior tables
			if ~isempty(obj.behaviorMetricTable)&~strcmp(class(obj.behaviorMetricTable),'table')
				obj.modelReadTable('table','behaviorMetricTable');
				obj.modelTableToStimArray('table','behaviorMetricTable','tableArray','behaviorMetricArray','nameArray','behaviorMetricNameArray','idArray','behaviorMetricIdArray','valueName','value');
			end
			% modify stimulus naming scheme
			if ~isempty(obj.stimulusNameArray)
				obj.stimulusSaveNameArray = obj.stimulusNameArray;
				obj.stimulusNameArray = strrep(obj.stimulusNameArray,'_',' ');
			end
			% load all the data
			if ~isempty(obj.rawSignals)&ischar(obj.rawSignals{1})
				disp('paths input, going to load files')
				obj.guiEnabled = 0;
				obj = modelVarsFromFiles(obj);
				obj.guiEnabled = 1;
			end
			% check if signal peaks have already been calculated
			if isempty(obj.signalPeaks)&~isempty(obj.rawSignals)
				% obj.computeSignalPeaksFxn();
			else
				disp('No folder data specified, load data with <a href="matlab: obj.currentMethod=''modelVarsFromFiles'';obj">modelVarsFromFiles</a> method.');
				% warning('no signal data input!!!')
			end
			% load stimulus tables

			disp(repmat('*',1,42))
			% Check java heap size
			try
				javaHeapSpaceSizeGb = java.lang.Runtime.getRuntime.maxMemory*1e-9;
				if javaHeapSpaceSizeGb<6.7
					javaErrorStr = sprintf('Java max heap memory is %0.3f Gb, this is too small to run Miji.\n\nPlease put "java.opts" file in the MATLAB start-up path or change MATALB start-up folder to calciumImagingAnalysis root folder and restart MATLB before continuing.\n',javaHeapSpaceSizeGb);
					warning(javaErrorStr);
					msgbox(javaErrorStr,'Note to user','modal')
				else
					fprintf('Java max heap memory is %0.3f Gb, this should be sufficient to run Miji. Please change "java.opts" file to increase heap space if run into Miji memory errors.\n',javaHeapSpaceSizeGb);
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end

		function obj = setup(obj)
			uiwait(msgbox(['calciumImagingAnalysis setup will:' 10 '1 - check and download dependencies as needed,' 10 '2 - then ask for a list of folders to include for analysis,' 10 '3 - and finally name for movie files to look for.' 10 10 'Press OK to continue.'],'Note to user','modal'));

			% Download and load dependent software packages into "_external_programs" folder.
			% Also download test data into "data" folder.
			obj.loadDependencies;

			% Add folders containing imaging data.
			obj.modelAddNewFolders;

			% [optional] Set the names calciumImagingAnalysis will look for in each folder
			obj.setMovieInfo;
		end

		function obj = update(obj)
			uiwait(msgbox('The calciumImagingAnalysis GitHub website will open. Click "Clone or download" button to download most recent version of calciumImagingAnalysis.'))
			web(obj.githubUrl);
		end

		function obj = loadBatchFunctionFolders(obj)
			% Loads the necessary directories to have the batch functions present.
			% Biafra Ahanonu
			% started: 2013.12.24 [08:46:11]

			% Disable the handle graphics warning "The DrawMode property will be removed in a future release. Use the SortMethod property instead." from being displayed. Comment out this line for debugging purposes as needed.
			warning('off','MATLAB:hg:WillBeRemovedReplaceWith')

			% add controller directory and subdirectories to path
			functionLocation = dbstack('-completenames');
			functionLocation = functionLocation(1).file;
			[functionDir,~,~] = fileparts(functionLocation);
			[functionDir,~,~] = fileparts(functionDir);
			pathList = genpath(functionDir);
			pathListArray = strsplit(pathList,pathsep);
			pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep '.git']));
			% pathFilter = cellfun(@isempty,regexpi(pathListArray,[filesep 'docs']));
			pathListArray = pathListArray(pathFilter);

			% =================================================
			% Remove directories that should not be loaded by default
			% matchIdx = contains(pathListArray,{[filesep 'cnmfe'],[filesep 'cnmf_original'],[filesep 'cnmf_current'],[filesep 'cvx_rd'],[filesep 'Fiji.app'],[filesep 'fiji-.*-20151222']});
			% pathListArray = pathListArray(~matchIdx);
			if ismac
				sepChar = filesep;
			elseif isunix
				sepChar = filesep;
			elseif ispc
				sepChar = '\\';
			else
				sepChar = filesep;
			end
			matchIdx = cellfun(@isempty,regexp(pathListArray,[sepChar '(cnmfe|cnmf_original|cnmf_current|cvx_rd|Fiji\.app|fiji-.*-20151222)']));
			pathListArray = pathListArray(matchIdx);

			% =================================================
			% Remove paths that are already in MATLAB path to save time
			pathFilter = cellfun(@isempty,pathListArray);
			pathListArray = pathListArray(~pathFilter);
			pathFilter = ismember(pathListArray,strsplit(path,pathsep));
			pathListArray = pathListArray(~pathFilter);

			if isempty(pathListArray)
				fprintf('MATALB path already has all needed non-private folders under: %s\n',functionDir);
			else
				fprintf('Adding all non-private folders under: %s\n',functionDir);
				pathList = strjoin(pathListArray,pathsep);
				addpath(pathList);
			end

			% =================================================
			% Automatically add Inscopix Data Processing Software
			if ismac
				baseInscopixPath = '';
			elseif isunix
				baseInscopixPath = '';
			elseif ispc
				baseInscopixPath = 'C:\Program Files\Inscopix\Data Processing';
			else
				disp('Platform not supported')
			end
			pathFilter = ismember(baseInscopixPath,strsplit(path,pathsep));
			if pathFilter==0
				if ~isempty(baseInscopixPath)&&exist(baseInscopixPath,'dir')==7
					addpath(baseInscopixPath);

					if exist('isx.Movie','class')==8
						fprintf('Inscopix Data Processing software added: %s\n',baseInscopixPath)
					else
						disp('Check Inscopix Data Processing software install!')
					end
				else
				end
			else
				fprintf('Inscopix Data Processing software already in path: %s\n',baseInscopixPath)
			end
		end

		function obj = resetMijiClass(obj)
			% This clears Miji from Java's dynamic path and then re-initializes. Use if Miji is not loading normally.
			resetMiji
			% success = 0;

			% for i = 1:2
			% 	try
			% 		% clear MIJ miji Miji mij;
			% 		javaDyna = javaclasspath('-dynamic');
			% 		matchIdx = ~cellfun(@isempty,regexpi(javaDyna,'Fiji'));
			% 		% cellfun(@(x) javarmpath(x),javaDyna(matchIdx));
			% 		javaDynaPathStr = join(javaDyna(matchIdx),''',''');
			% 		if ~isempty(javaDynaPathStr)
			% 			eval(sprintf('javarmpath(''%s'');',javaDynaPathStr{1}))
			% 		end
			% 		clear MIJ miji Miji mij;
			% 		% pause(1);
			% 		% java.lang.Runtime.getRuntime().gc;
			% 		% Miji;
			% 		% MIJ.exit;
			% 	catch err
			% 		disp(repmat('@',1,7))
			% 		disp(getReport(err,'extended','hyperlinks','on'));
			% 		disp(repmat('@',1,7))
			% 	end
			% end

			% success = 1;
		end

		function obj = display(obj)
			% Overload display method so can run object by just typing 'obj' in command window.
			obj.runPipeline;
			% display('hello');
		end
		% function delete(obj)
			% Warn the user before deleting class
		% end

		% function obj = delete(obj)
		% 	% Overload delete method to verify with user.
		% 	scnsize = get(0,'ScreenSize');
		% 	dependencyStr = {'downloadCnmfGithubRepositories','loadMiji','example_downloadTestData'};
		% 	[fileIdxArray, ok] = listdlg('ListString',dependencyStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Which dependency to load?');
			% obj.runPipeline;
		% 	% disp('hello');
		% end

		function obj = showVars(obj)
			obj.disp;
		end

		function obj = loadDependencies(obj)
			scnsize = get(0,'ScreenSize');
			dependencyStr = {'downloadMiji','downloadCnmfGithubRepositories','example_downloadTestData','loadMiji','downloadNeuroDataWithoutBorders'};
			dispStr = {'Download Fiji (to run Miji)','Download CNMF, CNMF-E, and CVX code.','Download test one-photon data.','Load Fiji/Miji into MATLAB path.','Download NWB (NeuroDataWithoutBorders)'};
			[fileIdxArray, ~] = listdlg('ListString',dispStr,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','Which dependencies to load? (Can select multiple)','InitialValue',[1 2 3 5]);
			analysisTypeD = dependencyStr(fileIdxArray);
			dispStr = dispStr(fileIdxArray);
			for depNo = 1:length(fileIdxArray)
				disp([10 repmat('>',1,42)])
				disp(dispStr{depNo})
				switch analysisTypeD{depNo}
					case 'downloadCnmfGithubRepositories'
						[success] = downloadCnmfGithubRepositories();
					case 'downloadMiji'
						depStr = {'Save Fiji to default directory','Save Fiji to custom directory'};
						[fileIdxArray, ~] = listdlg('ListString',depStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','Where to save Fiji?');
						depStr = depStr{fileIdxArray};
						if fileIdxArray==1
							downloadMiji();
						else
							downloadMiji('defaultDir','');
						end
						% if exist('pathtoMiji','var')
						% end
					case 'loadMiji'
						modelAddOutsideDependencies('miji');
					case 'example_downloadTestData'
						example_downloadTestData();
					case 'downloadNeuroDataWithoutBorders'
						optionsH.signalExtractionDir = obj.externalProgramsDir;
						optionsH.gitNameDisp = {'nwb_schnitzer_lab','yamlmatlab','matnwb'};
						optionsH.gitRepos = {'https://github.com/schnitzer-lab/nwb_schnitzer_lab','https://github.com/ewiger/yamlmatlab','https://github.com/NeurodataWithoutBorders/matnwb'};
						optionsH.gitRepos = cellfun(@(x) [x '/archive/master.zip'],optionsH.gitRepos,'UniformOutput',false);
						optionsH.outputDir = optionsH.gitNameDisp;
						optionsH.gitName = cellfun(@(x) [x '-master'],optionsH.gitNameDisp,'UniformOutput',false);
						[success] = downloadGithubRepositories('options',optionsH);

						% Load NWB Schema as needed
						if exist('types.core.Image')==0
							try
								disp('Generating matnwb types core files with "generateCore.m"')
								origPath = pwd;
								mat2nwbPath = [obj.defaultObjDir filesep obj.externalProgramsDir filesep 'matnwb'];
								disp(['cd ' mat2nwbPath])
								cd(mat2nwbPath);
								generateCore;
								disp(['cd ' origPath])
								cd(origPath);
							catch
								cd(obj.defaultObjDir);
							end
						else
							disp('NWB Schema types already loaded!')
						end
					otherwise
						% nothing
				end
			end
		end

		function obj = downloadLatestGithubVersion(obj)
			% Blank function
		end

		function obj = setMovieInfo(obj)
			movieSettings = inputdlg({...
					'Regular expression for raw files (e.g. if raw files all have "concat" in the name, put "concat"): ',...
					'Regular expression for processed files, skip if no processed files (e.g. if processed files all have "dfof" in the name, put "dfof"): ',...
					'[optional, if using HDF5] Input HDF5 file dataset name (e.g. "/images" for raw Inscopix or "/1" for example data, sans quotes): '...
				},...
				'Movie information',[1 100],...
				{...
					obj.fileFilterRegexpRaw,...
					obj.fileFilterRegexp,...
					obj.inputDatasetName...
				}...
			);
			obj.fileFilterRegexpRaw = movieSettings{1};
			obj.fileFilterRegexp = movieSettings{2};
			obj.inputDatasetName = movieSettings{3};
		end

		function obj = showProtocolSubjectsSessions(obj)
			protocolList = unique(obj.protocol);
			for i = 1:length(protocolList)
				protocolStr = protocolList{i};
				subjectList = obj.subjectStr(strcmp(protocolStr,obj.protocol));
				fprintf('Protocol %s | %d subjects | %d sessions\n',protocolStr,length(unique(subjectList)),length(subjectList))
				% disp([num2str(i) ' | ' obj.inputFolders{i}])
			end
		end

		function obj = removeConcurrentAnalysisFiles(obj)
			obj.foldersToAnalyze
			if obj.guiEnabled==1
				if isempty(obj.foldersToAnalyze)
					scnsize = get(0,'ScreenSize');
					[fileIdxArray, ~] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
				else
					fileIdxArray = obj.foldersToAnalyze;
				end
			else
				if isempty(obj.foldersToAnalyze)
					fileIdxArray = 1:length(obj.fileIDNameArray);
				else
					fileIdxArray = obj.foldersToAnalyze;
				end
			end

			% Find all concurrent analysis files and delete them
			nFolders = length(fileIdxArray);
			nFoldersTotal = length(obj.inputFolders);
			for folderNo = 1:nFolders
				i = fileIdxArray(folderNo);
				try
					% disp([num2str(i) ' | ' obj.inputFolders{i}])
					fileList = getFileList(obj.inputFolders{i},obj.concurrentAnalysisFilename);
					if ~isempty(fileList)
						fprintf('%d/%d (%d/%d) will delete analysis file: %s\n',i,nFoldersTotal,folderNo,nFolders,fileList{1})
					end
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			end
			userInput = input('Continue (1 = yes, 0 = no)? ');
			if userInput==1
				for folderNo = 1:nFolders
					i = fileIdxArray(folderNo);
					try
						% disp([num2str(i) ' | ' obj.inputFolders{i}])
						fprintf('%d/%d (%d/%d): %s\n',i,nFoldersTotal,folderNo,nFolders,obj.inputFolders{i})
						fileList = getFileList(obj.inputFolders{i},obj.concurrentAnalysisFilename);
						if ~isempty(fileList)
							fprintf('Deleting analysis file: %s\n',fileList{1})
							delete(fileList{1});
						end
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))
					end
				end
			end
		end

		function obj = showFolders(obj)
			for i = 1:length(obj.inputFolders)
				disp([num2str(i) ' | ' obj.inputFolders{i}])
			end
		end

		function valid = getValid(obj,validType)
			try
				fprintf('Getting %s identifications...\n',validType)
				obj.valid{obj.fileNum}.(obj.signalExtractionMethod).(validType);
				valid = obj.valid{obj.fileNum}.(obj.signalExtractionMethod).(validType);
			catch
				valid=[];
			end
		end

		function obj = changeCaxis(obj)
			userInput = inputdlg('CAXIS min max');str2num(userInput{1});
			S = findobj(gcf,'Type','Axes');
			% C = cell2mat(get(S,'Clim'));
			C = str2num(userInput{1});
			% C = [-1 7];
			set(S,'CLim',C);
		end

		function obj = changeFont(obj,varargin)
			%========================
			% DESCRIPTION
			options.fontSize = [];
			% get options
			options = getOptions(options,varargin);
			% disp(options)
			% unpack options into current workspace
			% fn=fieldnames(options);
			% for i=1:length(fn)
			% 	eval([fn{i} '=options.' fn{i} ';']);
			% end
			%========================

			if isempty(options.fontSize)
				userInput = inputdlg('New font');
				userInput = str2num(userInput{1});
				set(findall(gcf,'-property','FontSize'),'FontSize',userInput);
			else
				set(findall(gcf,'-property','FontSize'),'FontSize',options.fontSize);
			end
		end

		function obj = checkToolboxes(obj)
			license('inuse')
		end

		function GetSize(obj)
			props = properties(obj);
			totSize = 0;
			for ii=1:length(props)
				currentProperty = getfield(obj, char(props(ii)));
				s = whos('currentProperty');
				totSize = totSize + s.bytes;
			end
			fprintf(1, '%d bytes\n', totSize);
		end

		function makeFolderDirs(obj)
			% ensure private folders are set
			if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);end
			if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);end
			if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);end
			% save the current object instance
		end

		function obj = saveObj(obj)

			if isempty(obj.objSaveLocation)
				[filePath,folderPath,~] = uiputfile('*.*','select folder to save object mat file to','calciumImagingAnalysis_properties.mat');
				% exit if user picks nothing
				% if folderListInfo==0; return; end
				savePath = [folderPath filesep filePath];
				% tmpObj = obj;
				% obj = struct(obj);
				obj.objSaveLocation = savePath;
			else
				savePath = obj.objSaveLocation;
			end
			disp(['saving to: ' savePath])
			try
			  save(savePath,'obj','-v7.3');
			catch
			  disp('Problem saving, choose new location...')
			  obj.objSaveLocation = [];
			  obj.saveObj();
			end
			% obj = tmpObj;
		end

		function obj = computeCrossDayDistancesAlignment(obj)
			obj.sumStats = [];
			obj.sumStats.distances.cellDistances = [];
			obj.sumStats.distances.cellPairs = [];
			obj.sumStats.distances.sessionStr = {};

			obj.sumStats.centroids.sessionStr = {};
			obj.sumStats.centroids.cellNo = [];
			obj.sumStats.centroids.x = [];
			obj.sumStats.centroids.y = [];

			obj.sumStats.globalIDs.sessionStr = {};
			obj.sumStats.globalIDs.cellNo = [];
			obj.sumStats.globalIDs.numGlobalIDs = [];

			% Get all the cell distances
			theseFieldnames = fieldnames(obj.globalIDs.distances);
			allDistances = [];
			for subjNo = 1:length(theseFieldnames)
				fprintf('%s\n',theseFieldnames{subjNo})
				% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
				% allDistances = [allDistances(:); obj.globalIDs.distances.(theseFieldnames{subjNo}(:))];
				allDistances = obj.globalIDs.distances.(theseFieldnames{subjNo})(:);
				nPtsAdd = length(allDistances);
				obj.sumStats.distances.cellDistances(end+1:end+nPtsAdd,1) = allDistances;
				obj.sumStats.distances.cellPairs(end+1:end+nPtsAdd,1) = 1:length(allDistances);
				obj.sumStats.distances.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
			end
			savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellDistanceStatsAligned.tab'];
			disp(['saving data to: ' savePath])
			writetable(struct2table(obj.sumStats.distances),savePath,'FileType','text','Delimiter','\t');

			% return;
			disp('===')
			% Get all the cell centroids
			theseFieldnames = fieldnames(obj.globalIDs.matchCoords);
			for subjNo = 1:length(theseFieldnames)
				fprintf('%s\n',theseFieldnames{subjNo})
			% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
				if strcmp(theseFieldnames{subjNo},'null')==1
					continue;
				end
				allCentroids = obj.globalIDs.matchCoords.(theseFieldnames{subjNo});
				nPtsAdd = size(allCentroids,1);
				obj.sumStats.centroids.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
				obj.sumStats.centroids.cellNo(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
				obj.sumStats.centroids.x(end+1:end+nPtsAdd,1) = allCentroids(:,2);
				obj.sumStats.centroids.y(end+1:end+nPtsAdd,1) = allCentroids(:,1);
			end

			savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellCentroidsAligned.tab'];
			disp(['saving data to: ' savePath])
			writetable(struct2table(obj.sumStats.centroids),savePath,'FileType','text','Delimiter','\t');


			theseFieldnames = fieldnames(obj.globalIDs);
			for subjNo = 1:length(theseFieldnames)
				fprintf('%s\n',theseFieldnames{subjNo})
			% hexscatter(allCentroids(:,1),allCentroids(:,2),'res',50);
				if sum(strcmp(theseFieldnames{subjNo},{'null','matchCoords','distances'}))==1
					continue;
				end

				globalIDsD = obj.globalIDs.(theseFieldnames{subjNo});
				globalIDsIdx = logical(sum(globalIDsD~=0,2)>1);
				% globalIDs = globalIDs(globalIDsIdx,:);
				globalIDsIdx = sum(globalIDsIdx);

				nPtsAdd = size(globalIDsIdx,1);
				obj.sumStats.globalIDs.sessionStr(end+1:end+nPtsAdd,1) = {theseFieldnames{subjNo}};
				obj.sumStats.globalIDs.cellNo(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
				obj.sumStats.globalIDs.numGlobalIDs(end+1:end+nPtsAdd,1) = globalIDsIdx(:);
				% obj.sumStats.globalIDs.y(end+1:end+nPtsAdd,1) = allCentroids(:,1);

				% clear cumProb nAlignSum;
				% nGlobalSessions = size(globalIDs,2);
				% nGIds = size(globalIDs,1);
				% for gID = 1:nGlobalSessions
			 %		  cumProb(gID) = sum(sum(~(globalIDs==0),2)==gID)/nGIds;
			 %		  nAlignSum(gID) = sum(sum(~(globalIDs==0),2)==gID);
			 %	 end
			end

			savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_globalIDNums.tab'];
			disp(['saving data to: ' savePath])
			writetable(struct2table(obj.sumStats.globalIDs),savePath,'FileType','text','Delimiter','\t');

		end

		function obj = computeCellDistances(obj)
			obj.sumStats = [];
			obj.sumStats.cellDistances = [];
			obj.sumStats.cellPairs = [];
			obj.sumStats.sessionStr = {};

			[fileIdxArray, idNumIdxArray, nFilesToAnalyze, nFiles] = obj.getAnalysisSubsetsToAnalyze();

			for thisFileNumIdx = 1:nFilesToAnalyze
				try
					thisFileNum = fileIdxArray(thisFileNumIdx);
					obj.fileNum = thisFileNum;
					% disp(repmat('=',1,21))
					fprintf('%s\n %d/%d (%d/%d): %s\n',repmat('=',1,21),thisFileNumIdx,nFilesToAnalyze,thisFileNum,nFiles,obj.fileIDNameArray{obj.fileNum})
					% disp([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);

					% try
					methodNum = 2;
					if methodNum==1
						disp('Using previously computed centroids...')
						[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid] = modelGetSignalsImages(obj,'returnOnlyValid',1);
						xCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(valid,1);
						yCoords = obj.objLocations{obj.fileNum}.(obj.signalExtractionMethod)(valid,2);
						% npts = length(xCoords);
						% distanceMatrix = diag(zeros(1,npts))+squareform(distMatrix);
					else
					% catch
						[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid] = modelGetSignalsImages(obj);
						nIDs = length(obj.stimulusNameArray);
						nSignals = size(inputSignals,1);
						if isempty(inputImages);continue;end
						% [xCoords yCoords] = findCentroid(inputImages);
						[xCoords, yCoords] = findCentroid(inputImages,'thresholdValue',0.4,'imageThreshold',0.4,'roundCentroidPosition',0);
						% continue;
					end
					distMatrix = pdist([xCoords(:)*obj.MICRON_PER_PIXEL yCoords(:)*obj.	MICRON_PER_PIXEL]);
					distMatrix(logical(eye(size(distMatrix)))) = NaN;

					distMatrixPairs = distMatrix(:);
					distMatrixPairs(~isnan(distMatrixPairs));

					nPtsAdd = length(distMatrixPairs);
					obj.sumStats.cellDistances(end+1:end+nPtsAdd,1) = distMatrixPairs;
					obj.sumStats.cellPairs(end+1:end+nPtsAdd,1) = 1:nPtsAdd;
					obj.sumStats.sessionStr(end+1:end+nPtsAdd,1) = {obj.fileIDArray{obj.fileNum}};
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
				end
			end

			savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_cellDistanceStats.csv'];
			disp(['saving data to: ' savePath])
			writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter',',');
		end
		function obj = runPipeline(obj,varargin)
			try
				setFigureDefaults();
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
				obj.loadBatchFunctionFolders();
			end
			try
				set(0, 'DefaultUICOntrolFontSize', obj.fontSizeGui)
			catch
				set(0, 'DefaultUICOntrolFontSize', 11)
			end
			close all;clc;

			fxnsToRun = obj.methodsList;
			%========================
			options.fxnsToRun = fxnsToRun;
			% get options
			options = getOptions(options,varargin);
			% disp(options)
			% unpack options into current workspace
			% fn=fieldnames(options);
			% for i=1:length(fn)
			%	eval([fn{i} '=options.' fn{i} ';']);
			% end
			%========================
			fxnsToRun = options.fxnsToRun;
			% initialDir = pwd;
			% set back to initial directory in case exited early
			% restoredefaultpath;
			% loadBatchFxns();
			if strcmp(obj.defaultObjDir,pwd)~=1
				cd(obj.defaultObjDir);
			end

			if ischar(obj.videoDir)
				obj.videoDir = {obj.videoDir};
			end

			% ensure private folders are set
			if ~exist(obj.picsSavePath,'dir');mkdir(obj.picsSavePath);end
			if ~exist(obj.dataSavePath,'dir');mkdir(obj.dataSavePath);end
			if ~exist(obj.logSavePath,'dir');mkdir(obj.logSavePath);end

			props = properties(obj);
			totSize = 0;
			% for ii=1:length(props)
			%	  currentProperty = getfield(obj, char(props(ii)));
			%	  s = whos('currentProperty');
			%	  totSize = totSize + s.bytes;
			% end
			% sprintf('%.f',totSize*1.0e-6)
			% fprintf(1, '%d bytes\n', totSize*1.0e-6);
			% runs all currently implemented view functions

			scnsize = get(0,'ScreenSize');
			dlgSize = [scnsize(3)*0.4 scnsize(4)*0.6];

			currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));
			% Only keep the 1st method if it is twice in the function list.
			[~,duplicateIdx] = unique(fxnsToRun,'stable');
			currentIdx = intersect(currentIdx,duplicateIdx);
			% [idNumIdxArray, ok] = listdlg('ListString',fxnsToRun,'InitialValue',currentIdx(1),'ListSize',dlgSize,'Name','Sir! I have a plan! Select a calcium imaging analysis method or procedure to run:');

			[idNumIdxArray, fileIdxArray, ok] = obj.calciumImagingAnalysisMainGui(fxnsToRun,['calciumImagingAnalysis: "Sir! I have a plan!" Hover over methods for tooltip descriptions.'],currentIdx);
			obj.foldersToAnalyze = fileIdxArray;
			bypassUI = 1;

			% [idNumIdxArray, ok] = obj.pipelineListBox(fxnsToRun,['"Sir! I have a plan!" Select a calciumImagingAnalysis method or procedure to run. Hover over items for tooltip descriptions.'],currentIdx);
			if ok==0; return; end

			% excludeList = {'showVars','showFolders','setMainSettings','modelAddNewFolders','loadDependencies','saveObj','setStimulusSettings','modelDownsampleRawMovies'};
			% excludeListVer2 = {'modelEditStimTable','behaviorProtocolLoad','modelPreprocessMovie','modelModifyMovies','removeConcurrentAnalysisFiles'};
			% excludeListStimuli = {'modelVarsFromFiles'};
			excludeList = obj.methodExcludeList;
			excludeListVer2 = obj.methodExcludeListVer2;
			excludeListStimuli = obj.methodExcludeListStimuli;

			if isempty(intersect(fxnsToRun,excludeList))&isempty(intersect(fxnsToRun,excludeListVer2))
				% [guiIdx, ok] = listdlg('ListString',{'Yes','No'},'InitialValue',1,'ListSize',dlgSize,'Name','GUI Enabled?');
				[guiIdx, ok] = obj.pipelineListBox({'Yes','No'},['GUI Enabled?'],1);
				if ok==0; return; end
				% idNumIdxArray
				% turn off gui elements, run in batch
				obj.guiEnabled = guiIdx==1;
			end

			fxnsToRun = {fxnsToRun{idNumIdxArray}};
			obj.currentMethod = fxnsToRun{1};

			if bypassUI==0&isempty(intersect(fxnsToRun,excludeList))
				scnsize = get(0,'ScreenSize');
				usrIdxChoiceStr = obj.usrIdxChoiceStr;
				usrIdxChoiceDisplay = obj.usrIdxChoiceDisplay;
				% use current string as default
				currentIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));
				% [sel, ok] = listdlg('ListString',usrIdxChoiceDisplay,'InitialValue',currentIdx,'ListSize',dlgSize,'Name','Get to the data! Cell extraction algorithm to use for analysis?');
				[sel, ok] = obj.pipelineListBox(usrIdxChoiceDisplay,['"Get to the data!" Cell extraction algorithm to use for analysis?'],currentIdx);

				if ok==0; return; end
				% (Americans love a winner)
				usrIdxChoiceList = {2,1};
				obj.signalExtractionMethod = usrIdxChoiceStr{sel};
			end
			if bypassUI==0&~isempty(obj.inputFolders)&isempty(intersect(fxnsToRun,excludeList))&isempty(intersect(fxnsToRun,excludeListVer2))
				if isempty(obj.protocol)
					obj.modelGetFileInfo();
				end
				folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
				selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
				% set(0, 'DefaultUICOntrolFontSize', 16)
				% select subjects to analyze
				subjectStrUnique = unique(obj.subjectStr);
				% [subjIdxArray, ok] = listdlg('ListString',subjectStrUnique,'ListSize',dlgSize,'Name','Which subjects to analyze?');
				[subjIdxArray, ok] = obj.pipelineListBox(subjectStrUnique,['Which subjects to analyze?'],1);
				if ok==0; return; end
				subjToAnalyze = subjectStrUnique(subjIdxArray);
				subjToAnalyze = find(ismember(obj.subjectStr,subjToAnalyze));
				% get assays to analyze
				assayStrUnique = unique(obj.assay(subjToAnalyze));
				% [assayIdxArray, ok] = listdlg('ListString',assayStrUnique,'ListSize',dlgSize,'Name','Which assays to analyze?');
				[assayIdxArray, ok] = obj.pipelineListBox(assayStrUnique,['Which assays to analyze?'],1);
				if ok==0; return; end
				assayToAnalyze = assayStrUnique(assayIdxArray);
				assayToAnalyze = find(ismember(obj.assay,assayToAnalyze));
				% filter for folders chosen by the user
				validFoldersIdx = intersect(subjToAnalyze,assayToAnalyze);
				% if isempty(validFoldersIdx)
				%	  continue;
				% end
				useAltValid = {'no additional filter','manual index entry','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file']};
				useAltValidStr = {'no additional filter','manual index entry','manually sorted folders','not manually sorted folders','manual classification already in obj',['has extracted cells'],'missing extracted cells','fileFilterRegexp','valid auto','movie file'};
				% [choiceIdx, ok] = listdlg('ListString',useAltValid,'ListSize',dlgSize,'Name','Choose additional folder sorting filters');
				[choiceIdx, ok] = obj.pipelineListBox(useAltValid,['Choose additional folder sorting filters'],1);
				if ok==0; return; end

				if ok==1
					useAltValid = useAltValidStr{choiceIdx};
				else
					useAltValid = 0;
				end
				% useAltValid = 0;
				[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx);

				% [fileIdxArray, ok] = listdlg('ListString',selectList,'ListSize',dlgSize,'Name','Which folders to analyze?','InitialValue',validFoldersIdx);
				[fileIdxArray, ok] = obj.pipelineListBox(selectList,['Which folders to analyze?'],validFoldersIdx);
				if ok==0; return; end

				obj.foldersToAnalyze = fileIdxArray;
				if isempty(obj.stimulusNameArray)|~isempty(intersect(fxnsToRun,excludeListVer2))|~isempty(intersect(fxnsToRun,excludeListStimuli))
					obj.discreteStimuliToAnalyze = [];
				else
					% [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',dlgSize,'Name','which stimuli to analyze?');
					[idNumIdxArray, ok] = obj.pipelineListBox(obj.stimulusNameArray,['Which stimuli to analyze?'],1);
					if ok==0; return; end

					obj.discreteStimuliToAnalyze = idNumIdxArray;
				end
			elseif bypassUI==0&~isempty(intersect(fxnsToRun,excludeListVer2))
				folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
				selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
				% [fileIdxArray, ok] = listdlg('ListString',selectList,'ListSize',dlgSize,'Name','Which folders to analyze?','InitialValue',1);
				[fileIdxArray, ok] = obj.pipelineListBox(selectList,['Which folders to analyze?'],1);
				if ok==0; return; end

				obj.foldersToAnalyze = fileIdxArray;
			else
				if isempty(obj.stimulusNameArray)|~isempty(intersect(fxnsToRun,excludeListVer2))|~isempty(intersect(fxnsToRun,excludeListStimuli))
					obj.discreteStimuliToAnalyze = [];
				else
					% [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',dlgSize,'Name','which stimuli to analyze?');
					[idNumIdxArray, ok] = obj.pipelineListBox(obj.stimulusNameArray,['Which stimuli to analyze?'],1);
					if ok==0; return; end

					obj.discreteStimuliToAnalyze = idNumIdxArray;
				end
			end

			for thisFxn = fxnsToRun
				try
					disp(repmat('!',1,21))
					if ismethod(obj,thisFxn)
						disp(['Running: obj.' thisFxn{1}]);
						obj.(thisFxn{1});
					else
						disp(['Method not supported, skipping: obj.' thisFxn{1}]);
					end
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
					if strcmp(obj.defaultObjDir,pwd)~=1
						restoredefaultpath;
						cd(obj.defaultObjDir);
						loadBatchFxns();
						% cnmfVersionDirLoad('current','displayOutput',0);
					end
				end
			end
			obj.guiEnabled = 1;
			obj.foldersToAnalyze = [];
			% set back to initial directory in case exited early
			% restoredefaultpath;
			% loadBatchFxns();
			if strcmp(obj.defaultObjDir,pwd)~=1
				cd(obj.defaultObjDir);
			end

			disp([10 10 ...
			'Run processing pipeline by typing below (or clicking link) into command window (no semi-colon!):' 10 ...
			'<a href="matlab: obj">obj</a>'])
		end

		function [validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx)
			switch useAltValid
				case 'manual index entry'
				theseSettings = inputdlg({...
						'list (separated by commas) of indexes'
						},...
							'Folders to process',1,...
						{...
							'1'
						}...
					);
				validFoldersIdx = str2num(theseSettings{1});
				case 'missing extracted cells'
					switch obj.signalExtractionMethod
						case 'PCAICA'
							missingRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
						case 'EM'
							missingRegexp = obj.rawEMStructSaveStr;
						case 'EXTRACT'
							missingRegexp = obj.rawEXTRACTStructSaveStr;
						case 'CNMF'
							missingRegexp = obj.rawCNMFStructSaveStr;
						case 'CNMFE'
							missingRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
						otherwise
							missingRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
					end
					missingRegexp = strrep(missingRegexp,'.mat','');
					validFoldersIdx2 = [];
					for folderNo = 1:length(obj.dataPath)
						filesToLoad = getFileList(obj.dataPath{folderNo},missingRegexp);
						if isempty(filesToLoad)
							disp(['no extracted signals: ' obj.dataPath{folderNo}])
							validFoldersIdx2(end+1) = folderNo;
						end
					end
					validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
				case 'has extracted cells'
					switch obj.signalExtractionMethod
						case 'PCAICA'
							cellRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
						case 'EM'
							cellRegexp = obj.rawEMStructSaveStr;
						case 'EXTRACT'
							cellRegexp = obj.rawEXTRACTStructSaveStr;
						case 'CNMF'
							cellRegexp = obj.rawCNMFStructSaveStr;
						case 'CNMFE'
							cellRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
						otherwise
							% cellRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
							cellRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
					end
					cellRegexp = strrep(cellRegexp,'.mat','');
					validFoldersIdx2 = [];
					for folderNo = 1:length(obj.dataPath)
						filesToLoad = getFileList(obj.dataPath{folderNo},cellRegexp);
						if ~isempty(filesToLoad)
							disp(['has extracted signals: ' obj.dataPath{folderNo}])
							validFoldersIdx2(end+1) = folderNo;
						end
					end
					validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
				case 'movie file'
					movieRegexp = obj.fileFilterRegexp;
					validFoldersIdx2 = [];
					for folderNo = 1:length(obj.dataPath)
						filesToLoad = getFileList(obj.dataPath{folderNo},movieRegexp);
						if ~isempty(filesToLoad)
							disp(['has movie file: ' obj.dataPath{folderNo}])
							validFoldersIdx2(end+1) = folderNo;
						end
					end
					validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
				case 'fileFilterRegexp'
					validFoldersIdx2 = [];
					for folderNo = 1:length(obj.dataPath)
						filesToLoad = getFileList(obj.dataPath{folderNo},obj.fileFilterRegexp);
						if isempty(filesToLoad)
							validFoldersIdx2(end+1) = folderNo;
							disp(['missing dfof: ' obj.dataPath{folderNo}])
						end
					end
					validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
				case 'valid auto'
					validFoldersIdx = find(cell2mat(cellfun(@isempty,obj.validAuto,'UniformOutput',0)));
				case 'not manually sorted folders'
					switch obj.signalExtractionMethod
						case 'PCAICA'
							missingRegexp = obj.sortedICdecisionsSaveStr;
						case 'EM'
							missingRegexp = obj.sortedEMStructSaveStr;
						case 'EXTRACT'
							missingRegexp = obj.sortedEXTRACTStructSaveStr;
						case 'CNMF'
							missingRegexp = obj.sortedCNMFStructSaveStr;
						otherwise
							missingRegexp = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
					end
					validFoldersIdx = [];
					missingRegexp = strrep(missingRegexp,'.mat','');
					disp(['missingRegexp: ' missingRegexp])
					for folderNo = 1:length(obj.inputFolders)
						filesToLoad = getFileList(obj.inputFolders{folderNo},missingRegexp);
						% filesToLoad
						%filesToLoad
						if isempty(filesToLoad)
							validFoldersIdx(end+1) = folderNo;
							disp(['not manually sorted: ' obj.dataPath{folderNo}])
						else
							disp(['manually sorted: ' obj.dataPath{folderNo}])
						end
					end
				case 'manually sorted folders'
					switch obj.signalExtractionMethod
						case 'PCAICA'
							missingRegexp = obj.sortedICdecisionsSaveStr;
						case 'EM'
							missingRegexp = obj.sortedEMStructSaveStr;
						case 'EXTRACT'
							missingRegexp = obj.sortedEXTRACTStructSaveStr;
						case 'CNMF'
							missingRegexp = obj.sortedCNMFStructSaveStr;
						otherwise
							missingRegexp = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
					end
					validFoldersIdx = [];
					missingRegexp = strrep(missingRegexp,'.mat','');
					disp(['missingRegexp: ' missingRegexp])
					for folderNo = 1:length(obj.inputFolders)
						filesToLoad = getFileList(obj.inputFolders{folderNo},missingRegexp);
						%filesToLoad
						if ~isempty(filesToLoad)
							validFoldersIdx(end+1) = folderNo;
							disp(['manually sorted: ' obj.dataPath{folderNo}])
						end
					end
				case 'manual classification already in obj'
					validFoldersIdx = find(arrayfun(@(x) ~isempty(x{1}),obj.validManual));
				otherwise
					% body
			end
		end
		function [idNumIdxArray, validFoldersIdx, ok] = calciumImagingAnalysisMainGui(obj,fxnsToRun,inputTxt,currentIdx)
			% Main GUI for calciumImagingAnalysis startup
			try
				ok = 0;
				tooltipStruct = obj.tts;

				excludeList = obj.methodExcludeList;
				excludeListVer2 = obj.methodExcludeListVer2;

				subjectStrUnique = unique(obj.subjectStr);
				assayStrUnique = unique(obj.assay);
				usrIdxChoiceStr = obj.usrIdxChoiceStr;
				usrIdxChoiceDisplay = obj.usrIdxChoiceDisplay;
				% use current string as default
				currentCellExtIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));
				folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
				selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));

				useAltValid = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file'],'manual index entry'};
				useAltValidStr = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has extracted cells'],'missing extracted cells','fileFilterRegexp','valid auto','movie file','manual index entry'};

				hFig = figure;
				hListboxS = struct;
				mt = -10;
				set(hFig,'Name','calciumImagingAnalysis: start-up GUI','NumberTitle','off')
				uicontrol('Style','text','String',[inputTxt 10 'Press TAB to select next section, ENTER to continue, and ESC to exit.'],'Units','normalized','Position',[1 95 90 5]/100,'BackgroundColor','white','HorizontalAlignment','Left');

				% set(hFig,'Color',[0,0,0]);
				% currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));

				% set(hListboxS.cellExtractFiletype,'Callback',@(src,evt){set(src,'background',[1 1 1]*0.9)});
				selBoxInfo.methods.Tag = 'methodBox';
				selBoxInfo.cellExtract.Tag = 'cellExtractionBox';
				selBoxInfo.cellExtractFiletype.Tag = 'cellExtractionBox';
				selBoxInfo.folderFilt.Tag = 'folderFilt';
				selBoxInfo.subject.Tag = 'subjectBox';
				selBoxInfo.assay.Tag = 'assayBox';
				selBoxInfo.folders.Tag = 'folders';
				selBoxInfo.guiEnabled.Tag = 'folders';

				selBoxInfo.methods.Value = currentIdx;
				selBoxInfo.cellExtract.Value = currentCellExtIdx;
				if obj.nwbLoadFiles==1;ggg=2;else;ggg=1;end;
				selBoxInfo.cellExtractFiletype.Value = ggg;
				selBoxInfo.folderFilt.Value = 1;
				selBoxInfo.subject.Value = 1:length(subjectStrUnique);
				selBoxInfo.assay.Value = 1:length(assayStrUnique);
				selBoxInfo.folders.Value = 1:length(selectList);
				if obj.guiEnabled==1;ggg=1;else;ggg=2;end;
				selBoxInfo.guiEnabled.Value = ggg;

				selBoxInfo.methods.string = fxnsToRun;
				selBoxInfo.cellExtract.string = usrIdxChoiceDisplay;
				selBoxInfo.cellExtractFiletype.string = {'calciumImagingAnalysis format','NeuroDataWithoutBorders (NWB) format'};
				selBoxInfo.folderFilt.string = useAltValid;
				selBoxInfo.subject.string = subjectStrUnique;
				selBoxInfo.assay.string = assayStrUnique;
				selBoxInfo.folders.string = selectList;
				selBoxInfo.guiEnabled.string = {'GUI in methods enabled','GUI in methods disabled'};

				selBoxInfo.methods.title = 'Select a calciumImagingAnalysis method:';
				selBoxInfo.cellExtract.title = 'Cell-extraction method:';
				selBoxInfo.cellExtractFiletype.title = 'Cell-extraction file format:';
				selBoxInfo.folderFilt.title = 'Folder select filters:';
				selBoxInfo.assay.title = 'Folder assay names:';
				selBoxInfo.subject.title = 'Animal IDs:';
				selBoxInfo.folders.title = 'Loaded folders:';
				selBoxInfo.guiEnabled.title = 'GUI (for methods that ask for options):';

				selBoxInfo.methods.loc = [0,8,38,85];
				selBoxInfo.cellExtract.loc = [50+mt,81,24-mt/2,12];
				selBoxInfo.cellExtractFiletype.loc = [50+mt,73,24-mt/2,5];
				selBoxInfo.folderFilt.loc = [75+mt-mt/2,73,25-mt/2,20];
				selBoxInfo.subject.loc = [50+mt,51,24-mt/2,18];
				selBoxInfo.assay.loc = [75+mt-mt/2,51,25-mt/2,18];
				selBoxInfo.folders.loc = [50+mt,0,50-mt,48];
				selBoxInfo.guiEnabled.loc = [0,0,38,5];

				tmpList2 = fieldnames(selBoxInfo);
				for ff = 1:length(tmpList2)
					try
						hListboxS.(tmpList2{ff}) = uicontrol(hFig, 'style','listbox','Units','normalized','position',selBoxInfo.(tmpList2{ff}).loc/100, 'string',selBoxInfo.(tmpList2{ff}).string,'Value',selBoxInfo.(tmpList2{ff}).Value,'Tag',selBoxInfo.(tmpList2{ff}).Tag);
						if strcmp('methods',tmpList2{ff})==1
							set(hListboxS.(tmpList2{ff}),'background',[0.8 0.9 0.8]);
						end

						selBoxInfo.(tmpList2{ff}).titleLoc = selBoxInfo.(tmpList2{ff}).loc;
						selBoxInfo.(tmpList2{ff}).titleLoc(2) = selBoxInfo.(tmpList2{ff}).loc(2)+selBoxInfo.(tmpList2{ff}).loc(4);
						selBoxInfo.(tmpList2{ff}).titleLoc(4) = 2;

						uicontrol('Style','Text','String',selBoxInfo.(tmpList2{ff}).title,'Units','normalized','Position',selBoxInfo.(tmpList2{ff}).titleLoc/100,'BackgroundColor','white','HorizontalAlignment','Left','FontWeight','Bold');
						set(hListboxS.(tmpList2{ff}),'Max',2,'Min',0);
					catch
					end
				end
				hListbox = hListboxS.methods;
				% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))

				% jTmp = findjobj(hListboxS.cellExtract);jTmp.setSelectionAppearanceReflectsFocus(0);

				fxnToAttach = {'KeyReleaseFcn','Callback'};%, 'ButtonDownFcn' KeyReleaseFcn
				for fxnNo = 1:length(fxnToAttach)
					set(hListbox,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.cellExtract,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.cellExtractFiletype,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.assay,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.subject,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.folderFilt,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
					set(hListboxS.folders,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
				end

				% Assign focus lost callbacks to each selection box
				tmpList1 = fieldnames(hListboxS);
				for ff = 1:length(tmpList1)
					jScrollPane = findjobj(hListboxS.(tmpList1{ff}));
					jListbox = jScrollPane.getViewport.getComponent(0);
					set(jListbox, 'FocusGainedCallback',{@onFocusGain});
					set(jListbox, 'FocusLostCallback',{@onFocusLost});
					% set(jListbox, 'PropertyChangeCallback',{@onPropertyChange});
					% jListbox
				end

				% set(gcf,'WindowKeyPressFcn',@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig));

				% See http://undocumentedmatlab.com/articles/setting-listbox-mouse-actions/.
				% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(evnt,'press',hFig))
				% Get the listbox's underlying Java control
				jScrollPane = findjobj(hListbox);
				% We got the scrollpane container - get its actual contained listbox control
				jListbox = jScrollPane.getViewport.getComponent(0);
				% Convert to a callback-able reference handle
				jListbox = handle(jListbox, 'CallbackProperties');
				% set(hListbox, 'TooltipString','sss');
				% Set the mouse-movement event callback
				set(jListbox, 'MouseMovedCallback', {@mouseMovedCallback,hListbox,tooltipStruct});

				% [guiIdx, ok] = obj.pipelineListBox({'Yes','No'},['GUI Enabled?'],1);
				% if ok==0; return; end
				% idNumIdxArray
				% turn off gui elements, run in batch


				figure(hFig)
				uicontrol(hListbox)
				% set(hFig, 'KeyPressFcn', @(src,event) onFigKeyPress(src,event,hListboxS));
				hListboxStruct = [];
				hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
				hListboxStruct.Value = hListbox.Value;
				hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
				hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
				if hListboxStruct.nwbLoadFiles==1;hListboxStruct.nwbLoadFiles=0;else;hListboxStruct.nwbLoadFiles=1;end
				% Make sure GUI is up-to-date on first display.
				onKeyPressRelease([],[],'press',hFig);

				uiwait(hFig)
				commandwindow
				% disp(hListboxStruct)
				% fxnsToRun{hListboxStruct.Value}
				if isempty(hListboxStruct)
					uiwait(msgbox('Please re-select a module then press enter. Do not close figure manually.'))
					idNumIdxArray = 1;
					ok = 0;
				else
					idNumIdxArray = hListboxStruct.Value;
					validFoldersIdx = hListboxStruct.ValueFolder;
					obj.guiEnabled = hListboxStruct.guiIdx==1;
					if hListboxStruct.nwbLoadFiles==1;hListboxStruct.nwbLoadFiles=0;else;hListboxStruct.nwbLoadFiles=1;end
					obj.nwbLoadFiles = hListboxStruct.nwbLoadFiles;
					ok = 1;
				end
				% idNumIdxArray = get(hListboxS.folders,'Value');
			catch err
				ok = 0;
				idNumIdxArray = 1;
				validFoldersIdx = 1;
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end

			function onPropertyChange(src,event)
				% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.8,0.8));
			end
			% function onFigKeyPress(source,eventdata,hListboxS)
			function onFocusGain(src,event)
				% disp('ddd')
				% figure(hFig)
				tmpList = fieldnames(hListboxS);
				for ff = 1:length(tmpList)
					% jScrollPane = findjobj(hListboxS.(tmpList1{ff}));
					% jListbox = jScrollPane.getViewport.getComponent(0);
					% set(src,'background',javax.swing.plaf.ColorUIResource(0.8,0.8,0.8));
					% set(jListbox, 'selectionForeground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
					% set(jListbox, 'selectionForeground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
					% set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
				end
				% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
				set(src,'background',javax.swing.plaf.ColorUIResource(0.8,0.9,0.8));
				% gco
				% set(gco,'background',[1 1 1]*0.9);
			end
			function onFocusLost(src,event)
				% disp('ddd')
				% figure(hFig)
				% tmpList = fieldnames(hListboxS);
				% for ff = 1:length(tmpList)
				% 	set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
				% end
				% set(src,'background',javax.swing.plaf.ColorUIResource(1,1,1));
				set(src,'background',javax.swing.plaf.ColorUIResource(0.2,0.2,0.2));
				% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
				% gco
				% set(gco,'background',[1 1 1]*0.9);
			end
			function onMousePress(evnt,pressRelease,hFig)
				%
			end
			function onKeyPressRelease(src, evnt, pressRelease,hFig)
				% disp(evnt)
				% disp(pressRelease)
				% disp('ddd')
				figure(hFig)
				tmpList = fieldnames(hListboxS);
				for ff = 1:length(tmpList)
					set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
				end
				% set(gco,'background',[1 1 1]*0.9);

				if isempty(intersect(fxnsToRun{get(hListbox,'Value')},excludeList))
					set(hListboxS.cellExtract,'Enable','on');
					set(hListboxS.assay,'Enable','on');
					set(hListboxS.subject,'Enable','on');
					set(hListboxS.folderFilt,'Enable','on');
					set(hListboxS.folders,'Enable','on');
				else
					set(hListboxS.cellExtract,'Enable','off');
					set(hListboxS.assay,'Enable','off');
					set(hListboxS.subject,'Enable','off');
					set(hListboxS.folderFilt,'Enable','off');
					set(hListboxS.folders,'Enable','off');
				end

				if isempty(intersect(fxnsToRun{get(hListbox,'Value')},excludeListVer2))

				else
					set(hListboxS.cellExtract,'Enable','off');
					% set(hListboxS.assay,'Enable','off');
					% set(hListboxS.subject,'Enable','off');
					% set(hListboxS.folderFilt,'Enable','off');
					% set(hListboxS.folders,'Enable','off');
				end

				% if any(strcmp('methodBox',get(src,'Tag')))

					obj.signalExtractionMethod = usrIdxChoiceStr{get(hListboxS.cellExtract,'Value')};
					% currentCellExtIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));

					% filter for folders chosen by the user
					subjToAnalyze = subjectStrUnique(get(hListboxS.subject,'Value'));
					subjToAnalyze = find(ismember(obj.subjectStr,subjToAnalyze));

					assayToAnalyze = assayStrUnique(get(hListboxS.assay,'Value'));
					assayToAnalyze = find(ismember(obj.assay,assayToAnalyze));

					validFoldersIdx = intersect(subjToAnalyze,assayToAnalyze);

					% if ok==1
						useAltValid = useAltValidStr{get(hListboxS.folderFilt,'Value')};
					% else
						% useAltValid = 0;
					% end

					[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx);

					if strcmp(get(src,'Tag'),'folders')~=1
						set(hListboxS.folders,'Value',validFoldersIdx);
					end
					% assayStrUnique = unique(obj.assay(subjToAnalyze));
					% set(hListboxS.assay,'string',assayStrUnique);
				% else

				% end
				try
					evnt.Key;
					keyCheck = 1;
				catch
					keyCheck = 0;
				end
				if keyCheck==1
					if strcmp(evnt.Key,'return')
						% hListboxStruct.Value = hListbox.Value;
						hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
						hListboxStruct.Value = hListbox.Value;
						hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
						hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
						% hListboxStruct = struct(hListbox);
						close(hFig)
					else
						% disp('Check')
					end
					% If escape, close.
					if strcmp(evnt.Key,'escape')
						hListboxStruct = [];
						close(hFig)
					end
				end
				% catch
				% end
			end
			function mouseMovedCallback(jListbox, jEventData, hListbox,tooltipStruct)
				% Get the currently-hovered list-item
				mousePos = java.awt.Point(jEventData.getX, jEventData.getY);
				hoverIndex = jListbox.locationToIndex(mousePos) + 1;
				listValues = get(hListbox,'string');
				hoverValue = listValues{hoverIndex};

				% Replace odd values for the section dividers.
				hoverValue = regexprep(hoverValue,'------- | -------','');
				hoverValue = regexprep(hoverValue,':|/| |','_');

				% Modify the tooltip based on the hovered item
				if any(strcmp(fieldnames(tooltipStruct),hoverValue))
					msgStr = sprintf('<html><b>%s</b>: <br>%s</html>', hoverValue, tooltipStruct.(hoverValue));
				else
					% msgStr = sprintf('<html><b>%s</b>: %s</html>', hoverValue, hoverValue);
					msgStr = sprintf('<html><b>No tooltip.</b></html>', hoverValue, hoverValue);
				end
				set(hListbox, 'TooltipString',msgStr);
			end
		end

		function [idNumIdxArray, ok] = pipelineListBox(obj,fxnsToRun,inputTxt,currentIdx)
			% Part of this function is based on http://undocumentedmatlab.com/articles/setting-listbox-mouse-actions/.

			try
				ok = 0;
				tooltipStruct = obj.tts;

				hFig = figure;
				uicontrol('Style','Text','String',[inputTxt 10 'Press ENTER to continue, ESC to exit.'],'Units','normalized','Position',[5 90 90 10]/100,'BackgroundColor','white','HorizontalAlignment','Left');

				% currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));

				hListbox = uicontrol(hFig, 'style','listbox','Units', 'normalized','position',[5,5,90,85]/100, 'string',fxnsToRun,'Value',currentIdx,'Tag','methodBox');

				set(hListbox,'Max',2,'Min',0);
				% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))
				set(hListbox,'KeyReleaseFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))

				% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(evnt,'press',hFig))
				% Get the listbox's underlying Java control
				jScrollPane = findjobj(hListbox);
				% We got the scrollpane container - get its actual contained listbox control
				jListbox = jScrollPane.getViewport.getComponent(0);
				% Convert to a callback-able reference handle
				jListbox = handle(jListbox, 'CallbackProperties');
				% set(hListbox, 'TooltipString','sss');
				% Set the mouse-movement event callback
				set(jListbox, 'MouseMovedCallback', {@mouseMovedCallback,hListbox,tooltipStruct});

				figure(hFig)
				uicontrol(hListbox)
				set(hFig, 'KeyPressFcn', @(source,eventdata) figure(hFig));
				hListboxStruct = [];
				uiwait(hFig)
				commandwindow
				% disp(hListboxStruct)
				% fxnsToRun{hListboxStruct.Value}
				if isempty(hListboxStruct)
					uiwait(msgbox('Please re-select a module then press enter. Do not close figure manually.'))
					idNumIdxArray = 1;
					ok = 0;
				else
					idNumIdxArray = hListboxStruct.Value;
					ok = 1;
				end
			catch err
				ok = 0;
				idNumIdxArray = 1;
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
			function onMousePress(evnt,pressRelease,hFig)
				%
			end
			function onKeyPressRelease(src, evnt, pressRelease,hFig)
				% disp(evnt)
				% disp(pressRelease)
				if strcmp(evnt.Key,'return')
					hListboxStruct.Value = hListbox.Value;
					% hListboxStruct = struct(hListbox);
					close(hFig)
				else
					% disp('Check')
				end
				% If escape, close.
				if strcmp(evnt.Key,'escape')
					hListboxStruct = [];
					close(hFig)
				end
			end
			function mouseMovedCallback(jListbox, jEventData, hListbox,tooltipStruct)
				% Get the currently-hovered list-item
				mousePos = java.awt.Point(jEventData.getX, jEventData.getY);
				hoverIndex = jListbox.locationToIndex(mousePos) + 1;
				listValues = get(hListbox,'string');
				hoverValue = listValues{hoverIndex};

				% Replace odd values for the section dividers.
				hoverValue = regexprep(hoverValue,'------- | -------','');
				hoverValue = regexprep(hoverValue,':|/| |','_');

				% Modify the tooltip based on the hovered item
				if any(strcmp(fieldnames(tooltipStruct),hoverValue))
					msgStr = sprintf('<html><b>%s</b>: <br>%s</html>', hoverValue, tooltipStruct.(hoverValue));
				else
					% msgStr = sprintf('<html><b>%s</b>: %s</html>', hoverValue, hoverValue);
					msgStr = sprintf('<html><b>No tooltip.</b></html>', hoverValue, hoverValue);
				end
				set(hListbox, 'TooltipString',msgStr);
			end
		end
	end
end