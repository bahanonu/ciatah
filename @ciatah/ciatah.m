classdef ciatah < dynamicprops
	% Performs analysis on calcium imaging data. Also performs analysis on behavior (response signals) compared to stimulus or other continuous signals during an imaging session.
	% Biafra Ahanonu
	% started: 2014.07.31 (2020.10.25 [22:30:29])
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
		% 2020.03.23 [22:36:36] - Re-vamped selection dialog so everything is on a single panel and users can interactively alter how they filter folders.
		% 2020.05.07 [15:13:53] - Refactored a bit to remove methods that do not need to be in the main class definition to allow easier updating later.
		% 2021.03.25 [20:15:31] - Use ciapkg.getDir() to ensure using root directory consistently rather than ciapkgRoot.
		% 2021.03.25 [22:46:38] - Moved many smaller helper functions in ciatah.m to their own M-files to make maintenance easier.
		% 2021.06.18 [20:28:28] - Added modelVarsFromFilesCheck support.
		% 2021.06.30 [11:14:12] - Added FRAMES_PER_SECOND_PLAYBACK.
	% TODO
		%

	% dynamicprops is a subclass of handle, allowing addition of properties

	properties(GetAccess = 'public', SetAccess = 'public')
		% public read and write access.

		% FPS of movie(s) being analyzed
		FRAMES_PER_SECOND =  5;
		% FPS of movie playback
		FRAMES_PER_SECOND_PLAYBACK =  20;
		% Int: what factor temporally are analyzed movie from raw data
		DOWNSAMPLE_FACTOR =  4;
		% Float: estimated um per pixel
		MICRON_PER_PIXEL =  2.51; % 2.37;

		% Int: set the default UI font size
		fontSizeGui = 10;

		% Float: allows font size in GUI to be scaled
		fontSizeGuiScale = 1;

		defaultObjDir = pwd;
		classVersion = ciapkg.version();
		serverPath = '';
		privateSettingsPath = [ciapkg.getDir() filesep 'private' filesep 'settings' filesep 'privateLoadBatchFxns.m'];
		% place where functions can temporarily story user settings
		functionSettings = struct(...
			'null', NaN...
		);

		% user information
		userName = 'USA';
		% Taxonomic species name, defaults to mouse.
		species = 'mus musculus';

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
		externalProgramsDir = ciapkg.getDirExternalPrograms();

		% String: name of the analysis file to put in a folder to indicate to other computers the current computer is analyzing the folder and they should skip
		concurrentAnalysisFilename = '_currentlyAnalyzingFolderCheck.mat';

		% Cell array strings: List of methods to fast track folder to analyze dialog or skip altogether
		methodExcludeList = {'showVars','showFolders','setMainSettings','loadDependencies','saveObj','setStimulusSettings','modelDownsampleRawMovies','setMovieInfo','setup','update'};
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
		picsSavePath = [ciapkg.getDir() filesep 'private' filesep 'pics' filesep datestr(now,'yyyymmdd','local') filesep];
		dataSavePath = [ciapkg.getDir() filesep 'private' filesep 'data' filesep datestr(now,'yyyymmdd','local') filesep];
		dataSavePathFixed = [ciapkg.getDir() filesep 'private' filesep 'data' filesep];
		logSavePath = [ciapkg.getDir() filesep 'private' filesep 'logs' filesep datestr(now,'yyyymmdd','local') filesep];
		settingsSavePath = [ciapkg.getDir() filesep 'private' filesep 'settings'];
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

		usrIdxChoiceStr = {...
			'PCAICA',...
			'CNMF',...
			'CNMFE',...
			'ROI',...
			'CELLMax',...
			'EXTRACT',...
			'EM'};
		usrIdxChoiceDisplay = {...
			'PCAICA (Mukamel, 2009)',...
			'CNMF (Giovannucci, 2019)',...
			'CNMF-E (Zhou, 2018)',...
			'ROI',...
			'CELLMax (Kitch/Ahanonu)',...
			'EXTRACT (Inan, 2021)',...
			'CELLMax [EM] (Kitch/Ahanonu)'...
			};

		% PCAICA, EM, EXTRACT, CNMF, CNMFE
		signalExtractionMethod = 'PCAICA';
		% signalExtractionMethod = 'EM';
		% Int: indicates which trace output to use from 1 = primary trace, 2 = secondary trace, etc.
		signalExtractionTraceOutputType = 1;

		extractionMethodSaveStr = struct(...
			'PCAICA', '_pcaicaAnalysis',...
			'EM', '_emAnalysis',...
			'CELLMax', '_cellmaxAnalysis',...
			'EXTRACT', '_extractAnalysis',...
			'CNMF', '_cnmfAnalysis',...
			'CNMFE', '_cnmfeAnalysis',...
			'ROI', '_roiAnalysis'...
		);
		extractionMethodStructSaveStr = struct(...
			'PCAICA', '_pcaicaAnalysis.mat',...
			'EM', '_emAnalysis.mat',...
			'CELLMax', '_cellmaxAnalysis.mat',...
			'EXTRACT', '_extractAnalysis.mat',...
			'CNMF', '_cnmfAnalysis.mat',...
			'CNMFE', '_cnmfeAnalysis.mat',...
			'ROI', '_roiAnalysis.mat'...
		);
		extractionMethodSortedSaveStr = struct(...
			'PCAICA', '_ICdecisions.mat',...
			'EM', '_emAnalysisSorted.mat',...
			'CELLMax', '_cellmaxAnalysisSorted.mat',...
			'EXTRACT', '_extractAnalysisSorted.mat',...
			'CNMF', '_cnmfAnalysisSorted.mat',...
			'CNMFE', '_cnmfeAnalysisSorted.mat',...
			'ROI', '_roiAnalysisSorted.mat'...
		);
		extractionMethodClassifierSaveStr = struct(...
			'PCAICA', '_ICclassifierDecisions.mat',...
			'EM', '_emAnalysisClassifierDecisions.mat',...
			'CELLMax', '_cellmaxAnalysisClassifierDecisions.mat',...
			'EXTRACT', '_extractAnalysisClassifierDecisions.mat',...
			'CNMF', '_cnmfAnalysisClassifierDecisions.mat',...
			'CNMFE', '_cnmfeAnalysisClassifierDecisions.mat',...
			'ROI', '_roiAnalysisClassifierDecisions.mat'...
		);
		extractionMethodValidVarname = struct(...
			'PCAICA', 'valid',...
			'EM', 'validCellMax',...
			'CELLMax', 'validCellMax',...
			'EXTRACT', 'validEXTRACT',...
			'CNMF', 'validCNMF',...
			'CNMFE', 'validCNMFE',...
			'ROI', 'validROI'...
		);
		extractionMethodStructVarname = struct(...
			'PCAICA', 'pcaicaAnalysisOutput',...
			'EM', 'emAnalysisOutput',...
			'CELLMax', 'cellmaxAnalysisOutput',...
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
		% Whether to write or load NWB files, e.g. from modelExtractSignalsFromMovie
		nwbLoadFiles = 0;
		% Str: sub-folder where NWB files are stored. Leave blank to load from current folder.
		nwbFileFolder = 'nwbFiles';
		% Str: blank, use calciumImagingAnalysis regexp, else force use of this regexp for NWB files
		nwbFileRegexp = '';
		% Name of H5 group for movies, images, and signal series in NWB files
		nwbGroupImages = '/processing/ophys/ImageSegmentation/PlaneSegmentation';
		nwbGroupSignalSeries = '/processing/ophys/Fluorescence/RoiResponseSeries';
		nwbGroupMovie = '/acquisition/TwoPhotonSeries/data';

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
		saveLoadPreprocessingSettings = 1;
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
		'help',
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
		'------- VISUALIZATION/PREPROCESS CHECK -------',
		'viewMovieFiltering',
		'viewMovieRegistrationTest',
		'viewMovie',
		'',
		'------- PREPROCESS -------',
		'modelDownsampleRawMovies',
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
		'viewMovieCreateSideBySide',
		'',
		'------- ACROSS SESSION ANALYSIS: COMPUTE/VIEW -------',
		'viewSubjectMovieFrames',
		'computeMatchObjBtwnTrials',
		'',
		'viewMatchObjBtwnSessions',
		'modelSaveMatchObjBtwnTrials',
		'computeCellDistances',
		'computeCrossDayDistancesAlignment',
		'',
		'------- TRACKING -------',
		'modelTrackingData',
		'viewOverlayTrackingToVideo'
		};

		% Tooltips for calciumImagingAnalysis methods
		tts = struct(...
			'SETUP', 'Methods for setting up the class.',...
			'modelAddNewFolders', 'Add new folders to calciumImagingAnalysis.',...
			'help', 'Some tips if running into trouble using calciumImagingAnalysis.',...
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
			'modelSaveMatchObjBtwnTrials', 'Will allow users to save output of cross-session matching.',...
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
		globalIDStruct = {};
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
		function obj = ciatah(varargin)
			% CLASS CONSTRUCTOR
			warning on;
			clc
			% ' Calcium Imaging Analysis Class
			disp([...
			ciapkg.pkgName ' (calciumImagingAnalysis)' 10 ...
			'A software package for analyzing one- and two-photon calcium imaging datasets.' 10 10 ...
			'Biafra Ahanonu <<a href="emailto:bahanonu@alum.mit.edu">bahanonu@alum.mit.edu</a>>' 10 ...
			'Version ' obj.classVersion 10 10 ...
			'Made in USA']);

			obj.usaflag;

			disp(repmat('*',1,42))
			disp(['Constructing ' ciapkg.pkgName ' imaging analysis object...'])

			% Ensure that default directory is the CIAtah repository root
			functionLocation = dbstack('-completenames');
			functionLocation = functionLocation(1).file;
			[functionDir,~,~] = fileparts(functionLocation);
			[functionDir,~,~] = fileparts(functionDir);
			obj.defaultObjDir = functionDir;
			clear functionDir functionLocation;

			% Make sure all functions are loaded
			obj.loadBatchFunctionFolders();
			disp(repmat('*',1,42))

			% Make sure defaults set
			try
				setFigureDefaults();
				obj.classVersion = ciapkg.version();
			catch
			end

			% Because the obj
			%========================
			% obj.exampleOption = '';
			% get options
			obj = ciapkg.io.getOptions(obj,varargin);
			% disp(options)
			% unpack options into current workspace
			% fn=fieldnames(options);
			% for i=1:length(fn)
			%	 eval([fn{i} '=options.' fn{i} ';']);
			% end
			%========================

			obj = initializeObj(obj);

			ciapkg.io.updatePkg('updatePackage',0);

			disp(repmat('*',1,42))
			disp(['Done initializing ' ciapkg.pkgName '!'])
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

		% calciumImagingAnalysis main class methods
		[idNumIdxArray, validFoldersIdx, ok] = ciatahMainGui(obj,fxnsToRun,inputTxt,currentIdx)
		[idNumIdxArray, ok] = pipelineListBox(obj,fxnsToRun,inputTxt,currentIdx)
		obj = computeCrossDayDistancesAlignment(obj)
		obj = computeCellDistances(obj)
		obj = resetMijiClass(obj)
		obj = runPipeline(obj,varargin)
		obj = initializeObj(obj)
		obj = loadBatchFunctionFolders(obj)
		obj = loadDependencies(obj)
		obj = removeConcurrentAnalysisFiles(obj)
		obj = setMovieInfo(obj)
		[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx)

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

		% Helper functions
		% obj = delete(obj)
		obj = setup(obj)
		obj = update(obj)
		obj = display(obj)
		obj = showVars(obj)
		obj = downloadLatestGithubVersion(obj)
		obj = showProtocolSubjectsSessions(obj)
		obj = showFolders(obj)
		[valid] = getValid(obj,validType)
		obj = changeCaxis(obj)
		obj = changeFont(obj)
		obj = checkToolboxes(obj)
		obj = GetSize(obj)
		obj = makeFolderDirs(obj)
		[flagOut] = usaflag(obj)
		obj = saveObj(obj)
		obj = modelVarsFromFilesCheck(obj,folderNo,varargin)
	end
end