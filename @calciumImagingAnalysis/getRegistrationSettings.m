function [preprocessSettingStruct, preprocessingSettingsAll] = getRegistrationSettings(obj,inputTitleStr,varargin)
	% Internal function to get user imaging preprocessing settings.
	% Biafra Ahanonu
	% started: 2016.05.31 [14:53:00]
	% inputs
		% inputTitleStr - string title to show user.
	% outputs
		% preprocessSettingStruct - structure containing user settings.
		% preprocessingSettingsAll - structure of the final pre-processing settings.

	% changelog
		% 2019.12.07 [16:23:36] - Added tooltips. Made options list easier on the eyes with improved spacing. Added a callback for user selecting the reference turboreg frame and or adding arbitrary values to a number of other options.
		% 2019.12.07 [17:46:03] - Change how settings are initialized, should make easier to maintain and add new settings.
		% 2019.12.08 [22:34:38] - Added additional tooltips and checks to make sure user inputs correct data type/size.
		% 2019.12.08 [22:49:48] - Allow users to input previous preprocessing settings.
	% TODO
		% DONE: Allow user to input prior settings, indicate those changed from default by orange or similar color.

	%========================
	% Struct: Empty = no previous settings, else a structure of preprocessingSettingsAll from previous run.
	options.inputSettings = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% Initialize constants
	nWorkersDefault = java.lang.Runtime.getRuntime().availableProcessors-1;
	userSelectStr = 'User selects specific value.';
	userSelectVal = 0;
	defaultTooltips = 'NO TIPS FOR YOU';

	% Options that allow users to manually set the value
	userOptionsAllowManualSelect = {...
	'numTurboregIterations',...
	'turboregNumFramesSubset',...
	'pxToCrop',...
	'motionCorrectionRefFrame',...
	'SmoothX',...
	'SmoothY',...
	'filterBeforeRegFreqLow',...
	'filterBeforeRegFreqHigh',...
	'medianFilterSize',...
	'downsampleFactorTime',...
	'downsampleFactorSpace',...
	'stripSize',...
	'stripfreqLowExclude',...
	'stripfreqHighExclude',...
	'filterBeforeRegImagejFFTLarge',...
	'filterBeforeRegImagejFFTSmall',...
	'loadMovieInEqualParts',...
	'nParallelWorkers'...
	};

	% Create structure with options.
	tS = [];
	tS.MAIN______________ = [];
		tS.MAIN______________.val = {{'====================='}};
		tS.MAIN______________.str = {{'====================='}};
		tS.MAIN______________.tooltip =  {{'====================='}};
	tS.checkConcurrentAnalysis = [];
		tS.checkConcurrentAnalysis.val = {{0,1}};
		tS.checkConcurrentAnalysis.str = {{'DO NOT check for analysis across workstations','DO check for analysis across workstations'}};
		tS.checkConcurrentAnalysis.tooltip =  {{'Select to allow multiple workstations to analyze several of the same imaging sessions WITHOUT duplicating analysis.'}};
	tS.resetParallelPool = [];
		tS.resetParallelPool.val = {{0,1}};
		tS.resetParallelPool.str = {{'DO NOT restart parallel pool after each folder is analyzed','DO restart parallel pool after each folder is analyzed'}};
		tS.resetParallelPool.tooltip =  {{['Parallel workers sometimes start to use a lot of memory.' 10 'Restart them to reset to lower memory usage.']}};
	tS.analyzeFromDisk = [];
		tS.analyzeFromDisk.val = {{0,1}};
		tS.analyzeFromDisk.str = {{'Load entire movie into RAM','Use disk, load part of movie into RAM'}};
		tS.analyzeFromDisk.tooltip =  {{defaultTooltips}};
	tS.REGISTRATION______________ = [];
		tS.REGISTRATION______________.val = {{'====================='}};
		tS.REGISTRATION______________.str = {{'====================='}};
		tS.REGISTRATION______________.tooltip =  {{'====================='}};
	tS.parallel = [];
		tS.parallel.val = {{1,0}};
		tS.parallel.str = {{'parallel processing','NO parallel processing'}};
		tS.parallel.tooltip =  {{'Use parallel processing during motion correction.'}};
	tS.registrationFxn = [];
		tS.registrationFxn.val = {{'transfturboreg','imtransform'}};
		tS.registrationFxn.str = {{'transfturboreg','imtransform'}};
		tS.registrationFxn.tooltip =  {{'Keep default unless have issues with transfturboreg (e.g. random frames look dim).'}};
	tS.turboregRotation = [];
		tS.turboregRotation.val = {{0,1}};
		tS.turboregRotation.str = {{'DO NOT turboreg rotation','DO turboreg rotation'}};
		tS.turboregRotation.tooltip =  {{'Unless you have rotation in your movie, leave OFF. Produces better results.'}};
	tS.RegisType = [];
		tS.RegisType.val = {{1,3}};
		tS.RegisType.str = {{'affine (parallelism maintained)','projective (parallelism not guaranteed)'}};
		tS.RegisType.tooltip =  {{'"affine" is good for most rigid cases, use "projective" if movie has complex motion'}};
	tS.numTurboregIterations = [];
		tS.numTurboregIterations.val = {{1,userSelectVal,2,3,4,5}};
		tS.numTurboregIterations.str = {{1,userSelectStr,2,3,4,5}};
		tS.numTurboregIterations.tooltip =  {{defaultTooltips}};
	tS.turboregNumFramesSubset = [];
		tS.turboregNumFramesSubset.val = {{5000,userSelectVal,1,5,10,50,100,250,500,1000,2000,3000,5000,10000,15000}};
		tS.turboregNumFramesSubset.str = {{5000,userSelectStr,1,5,10,50,100,250,500,1000,2000,3000,5000,10000,15000}};
		tS.turboregNumFramesSubset.tooltip =  {{'To save memory, motion correction is run on the indicated # of frames from the data.'}};
	tS.pxToCrop = [];
		tS.pxToCrop.val = {{14,userSelectVal,15,16,17,18,19,20,21,22,23,24,25}};
		tS.pxToCrop.str = {{14,userSelectStr,15,16,17,18,19,20,21,22,23,24,25}};
		tS.pxToCrop.tooltip =  {{'Maximum # of pixels to convert to NaNs around the border after motion correction.'}};
	tS.motionCorrectionRefFrame = [];
		tS.motionCorrectionRefFrame.val = {{100,userSelectVal,1,10,100,1000}};
		tS.motionCorrectionRefFrame.str = {{100,userSelectStr,1,10,100,1000}};
		tS.motionCorrectionRefFrame.tooltip =  {{['The reference frame for motion correction.' 10 'Avoid selecting 1st couple of movie frames or one that has issues.']}};
	tS.REGISTRATION_NORMALIZATION______________ = [];
		tS.REGISTRATION_NORMALIZATION______________.val = {{'====================='}};
		tS.REGISTRATION_NORMALIZATION______________.str = {{'====================='}};
		tS.REGISTRATION_NORMALIZATION______________.tooltip =  {{'====================='}};
	tS.normalizeMeanSubtract = [];
		tS.normalizeMeanSubtract.val = {{1,0}};
		tS.normalizeMeanSubtract.str = {{'normalize movie before turboreg','do not normalize movie before turboreg'}};
		tS.normalizeMeanSubtract.tooltip = {{['Critical for most movies, normalizes each frame to improve motion correction.' 10 'DO NOT CHANGE unless you know what you are doing.']}};
	tS.normalizeMeanSubtractNormalize = [];
		tS.normalizeMeanSubtractNormalize.val = {{1,0}};
		tS.normalizeMeanSubtractNormalize.str = {{'subtract mean per frame','do not subtract mean per frame'}};
		tS.normalizeMeanSubtractNormalize.tooltip = {{'This subtracts the mean of each frame. Keep enabled is nearly all cases.'}};
	tS.normalizeComplementMatrix = [];
		tS.normalizeComplementMatrix.val = {{1,0}};
		tS.normalizeComplementMatrix.str = {{'invert movie before turboreg','DO NOT invert movie before turboreg'}};
		tS.normalizeComplementMatrix.tooltip = {{'Inverts all movie values to give more weight to dark features (e.g. blood vessels).'}};
	tS.normalizeType = [];
		tS.normalizeType.val = {{'bandpass','divideByLowpass','imagejFFT','highpass','matlabDisk'}};
		tS.normalizeType.str = {{'bandpass','divideByLowpass','imagejFFT','highpass','matlabDisk'}};
		tS.normalizeType.tooltip = {{['Spatial filtering applied before getting spatial translation coordinates.' 10 'Try "matlabDisk" if default does not work.']}};
	tS.normalizeFreqLow = [];
		tS.normalizeFreqLow.val = {{70,10,20,30,40,50,60,70,80,90}};
		tS.normalizeFreqLow.str = {{70,10,20,30,40,50,60,70,80,90}};
		tS.normalizeFreqLow.tooltip = {{'For any "normalizeType" FFT options selected, the lower frequency.'}};
	tS.normalizeFreqHigh = [];
		tS.normalizeFreqHigh.val = {{100,80,90,100,110}};
		tS.normalizeFreqHigh.str = {{100,80,90,100,110}};
		tS.normalizeFreqHigh.tooltip = {{'For any "normalizeType" FFT options selected, the higher frequency.'}};
	tS.normalizeBandpassType = [];
		tS.normalizeBandpassType.val = {{'bandpass','lowpass','highpass'}};
		tS.normalizeBandpassType.str = {{'bandpass','lowpass','highpass'}};
		tS.normalizeBandpassType.tooltip = {{'If "normalizeType" is an FFT, the type'}};
	tS.normalizeBandpassMask = [];
		tS.normalizeBandpassMask.val = {{'gaussian','binary'}};
		tS.normalizeBandpassMask.str = {{'gaussian','binary'}};
		tS.normalizeBandpassMask.tooltip = {{['If "normalizeType" is an FFT, how "normalizeBandpassType" is applied.' 10 '"binary" option will produce ringing.']}};
	tS.SmoothX = [];
		tS.SmoothX.val = {{10,userSelectVal,1,5,10,20,30,40,50,60,70,80,90}};
		tS.SmoothX.str = {{10,userSelectStr,1,5,10,20,30,40,50,60,70,80,90}};
		tS.SmoothX.tooltip = {{'Turboreg''s x smoothing size in pixels.'}};
	tS.SmoothY = [];
		tS.SmoothY.val = {{10,userSelectVal,1,5,10,20,30,40,50,60,70,80,90}};
		tS.SmoothY.str = {{10,userSelectStr,1,5,10,20,30,40,50,60,70,80,90}};
		tS.SmoothY.tooltip = {{'Turboreg''s y smoothing size in pixels.'}};
	tS.zapMean = [];
		tS.zapMean.val = {{0,1}};
		tS.zapMean.str = {{0,1}};
		tS.zapMean.tooltip = {{'Turboreg''s function to remove the mean. Leave disabled since this is already done outside turboreg.'}};
	tS.MOVIE_NORMALIZATION______________ = [];
		tS.MOVIE_NORMALIZATION______________.val = {{'====================='}};
		tS.MOVIE_NORMALIZATION______________.str = {{'====================='}};
		tS.MOVIE_NORMALIZATION______________.tooltip =  {{'====================='}};
	tS.filterBeforeRegister = [];
		tS.filterBeforeRegister.val = {{[],'divideByLowpass','imagejFFT','bandpass'}};
		tS.filterBeforeRegister.str = {{'NO filtering before registering','matlab divide by lowpass before registering','imageJ divide by lowpass (requires Miji!)','matlab bandpass before registering'}};
		tS.filterBeforeRegister.tooltip = {{'IMPORTANT: type of spatial filtering applied after getting spatial transformation coordinates but BEFORE actually motion correcting the movie.'}};
	tS.saveBeforeFilterRegister = [];
		tS.saveBeforeFilterRegister.val = {{0,1}};
		tS.saveBeforeFilterRegister.str = {{'DO NOT SAVE registered movie sans spatial filtering','DO SAVE registered movie sans spatial filtering'}};
		tS.saveBeforeFilterRegister.tooltip = {{['Save registered movie before spatial filtering applied.' 10 'This is a good way to check the correlation of all frames to mean frame to show improvement with motion correction.']}};
	tS.saveFilterBeforeRegister = [];
		tS.saveFilterBeforeRegister.val = {{[],'save'}};
		tS.saveFilterBeforeRegister.str = {{'DO NOT save lowpass movie.','DO save lowpass movie.'}};
		tS.saveFilterBeforeRegister.tooltip = {{'Save a low-pass version of the movie, e.g. if looking at neuropil activity.'}};
	tS.filterBeforeRegFreqLow = [];
		tS.filterBeforeRegFreqLow.val = {{0,userSelectVal,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400,500,600}};
		tS.filterBeforeRegFreqLow.str = {{0,userSelectStr,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400,500,600}};
		tS.filterBeforeRegFreqLow.tooltip = {{['Value is in cycles per movie x-y dimensions.' 10 'If divideByLowpass, leave this alone.' 10 'If "matlab bandpass" then set to the lowest spatial frequency to keep (e.g. large objects).']}};
	tS.filterBeforeRegFreqHigh = [];
		tS.filterBeforeRegFreqHigh.val = {{20,userSelectVal,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400,500,600}};
		tS.filterBeforeRegFreqHigh.str = {{20,userSelectStr,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400,500,600}};
		tS.filterBeforeRegFreqHigh.tooltip = {{['Value is in cycles per movie x-y dimensions.' 10 'If divideByLowpass, set to the highest spatial frequency to exclude.' 10 'If "matlab bandpass" then set to the highest spatial frequency to keep (e.g. small ibjects).']}};
	tS.filterBeforeRegImagejFFTLarge = [];
		tS.filterBeforeRegImagejFFTLarge.val = {{10000,userSelectVal,100,500,1000,5000,8000}};
		tS.filterBeforeRegImagejFFTLarge.str = {{10000,userSelectStr,100,500,1000,5000,8000}};
		tS.filterBeforeRegImagejFFTLarge.tooltip = {{'Generally ignore since ImageJ isn''t needed for spatial filtering anymore'}};
	tS.filterBeforeRegImagejFFTSmall = [];
		tS.filterBeforeRegImagejFFTSmall.val = {{80,userSelectVal,10,20,30,40,50,60,70,90,100}};
		tS.filterBeforeRegImagejFFTSmall.str = {{80,userSelectStr,10,20,30,40,50,60,70,90,100}};
		tS.filterBeforeRegImagejFFTSmall.tooltip = {{'Generally ignore since ImageJ isn''t needed for spatial filtering anymore'}};
	tS.medianFilterSize = [];
		tS.medianFilterSize.val = {{3,userSelectVal,5,7,9,11,13,15}};
		tS.medianFilterSize.str = {{3,userSelectStr,5,7,9,11,13,15}};
		tS.medianFilterSize.tooltip = {{['The size in pixels of the median filter.' 10 'If "medianFilter" is selected for preprocessing.']}};
	tS.MOVIE_DOWNSAMPLING______________ = [];
		tS.MOVIE_DOWNSAMPLING______________.val = {{'====================='}};
		tS.MOVIE_DOWNSAMPLING______________.str = {{'====================='}};
		tS.MOVIE_DOWNSAMPLING______________.tooltip =  {{'====================='}};
	tS.downsampleFactorTime = [];
		tS.downsampleFactorTime.val = {{4,userSelectVal,1,2,4,6,8,10,20}};
		tS.downsampleFactorTime.str = {{4,userSelectStr,1,2,4,6,8,10,20}};
		tS.downsampleFactorTime.tooltip = {{'By what factor to downsample movie in time.'}};
	tS.downsampleFactorSpace = [];
		tS.downsampleFactorSpace.val = {{2,userSelectVal,1,2,4,6,8,10,20}};
		tS.downsampleFactorSpace.str = {{2,userSelectStr,1,2,4,6,8,10,20}};
		tS.downsampleFactorSpace.tooltip = {{'By what factor to downsample movie in space.'}};
	tS.IO_and_MOVIE_IDENTIFICATION______________ = [];
		tS.IO_and_MOVIE_IDENTIFICATION______________.val = {{'====================='}};
		tS.IO_and_MOVIE_IDENTIFICATION______________.str = {{'====================='}};
		tS.IO_and_MOVIE_IDENTIFICATION______________.tooltip =  {{'====================='}};
	tS.inputDatasetName = [];
		tS.inputDatasetName.val = {{obj.inputDatasetName,'/1','/Movie','/movie','/images','/Data/Images','/data'}};
		tS.inputDatasetName.str = {{obj.inputDatasetName,'/1','/Movie','/movie','/images','/Data/Images','/data'}};
		tS.inputDatasetName.tooltip = {{'HDF5 dataset name of input data.'}};
	tS.outputDatasetName = [];
		tS.outputDatasetName.val = {{obj.outputDatasetName,'/1','/Movie','/movie','/images'}};
		tS.outputDatasetName.str = {{obj.outputDatasetName,'/1','/Movie','/movie','/images'}};
		tS.outputDatasetName.tooltip = {{'HDF5 dataset name of output data.'}};
	tS.fileFilterRegexp = [];
		tS.fileFilterRegexp.val = {{obj.fileFilterRegexpRaw,'concat_.*.h5','concatenated_.*.h5','crop.*.h5','recording.*.tif','concat.*.tif','dfstd_.*.h5','dfof_.*.h5','concat'}};
		tS.fileFilterRegexp.str = {{obj.fileFilterRegexpRaw,'concat_.*.h5','concatenated_.*.h5','crop.*.h5','recording.*.tif','concat.*.tif','dfstd_.*.h5','dfof_.*.h5','concat'}};
		tS.fileFilterRegexp.tooltip = {{'Regular expression used to find movie data files in each folder.'}};
	tS.processMoviesSeparately = [];
		tS.processMoviesSeparately.val = {{0,1}};
		tS.processMoviesSeparately.str = {{'No','Yes'}};
		tS.processMoviesSeparately.tooltip = {{['"No", all files in folder concatenated in natural sort order.' 10 'If "Yes" then if folder contains multiple movie files, they will be processed separately instead of concatenated together.']}};
	tS.loadMoviesFrameByFrame = [];
		tS.loadMoviesFrameByFrame.val = {{0,1}};
		tS.loadMoviesFrameByFrame.str = {{'No','Yes'}};
		tS.loadMoviesFrameByFrame.tooltip = {{['"No" allows movies to be loaded in one chunk.' 10 '"Yes" loads movies frame-by-frame, which can potentially improve memory usage.']}};
	tS.treatMoviesAsContinuousSwitch = [];
		tS.treatMoviesAsContinuousSwitch.val = {{1,0}};
		tS.treatMoviesAsContinuousSwitch.str = {{'Yes','No'}};
		tS.treatMoviesAsContinuousSwitch.tooltip = {{['"Yes" treats multiple movie files in a folder as one continuous movie.' 10 '"No" treats each movie file in a folder as separate movies.']}};
	tS.loadMovieInEqualParts = [];
		tS.loadMovieInEqualParts.val = {{0,userSelectVal,1,2,3,4,5,6,7,8,9,10}};
		tS.loadMovieInEqualParts.str = {{0,userSelectStr,1,2,3,4,5,6,7,8,9,10}};
		tS.loadMovieInEqualParts.tooltip = {{'Number of 50-frame segments evenly spaced in time to load.'}};
	tS.useParallel = [];
		tS.useParallel.val = {{1,0}};
		tS.useParallel.str = {{'Yes','No'}};
		tS.useParallel.tooltip = {{'Whether to use parallelization in processing steps.'}};
	tS.nParallelWorkers = [];
		% tS.nParallelWorkers.val = {[nWorkersDefault, userSelectVal, mat2cell([1:(nWorkersDefault*2)],1,ones(1,2*nWorkersDefault))]'};
		% tS.nParallelWorkers.str = {[nWorkersDefault, userSelectStr, mat2cell([1:(nWorkersDefault*2)],1,ones(1,2*nWorkersDefault))]'};
		tS.nParallelWorkers.val = {{nWorkersDefault, userSelectVal, nWorkersDefault*2}};
		tS.nParallelWorkers.str = {{nWorkersDefault, userSelectStr, nWorkersDefault*2}};
		tS.nParallelWorkers.tooltip = {{defaultTooltips}};
	tS.STRIPE_REMOVAL______________ = [];
		tS.STRIPE_REMOVAL______________.val = {{'====================='}};
		tS.STRIPE_REMOVAL______________.str = {{'====================='}};
		tS.STRIPE_REMOVAL______________.tooltip =  {{'====================='}};
	tS.stripOrientationRemove = [];
		tS.stripOrientationRemove.val = {{'none','vertical','horizontal','both'}};
		tS.stripOrientationRemove.str = {{'none','vertical','horizontal','both'}};
		tS.stripOrientationRemove.tooltip = {{'Direction of stripes to remove from movie.'}};
	tS.stripSize = [];
		tS.stripSize.val = {{7,userSelectVal,1,3,5,7,9,11,13,15}};
		tS.stripSize.str = {{7,userSelectStr,1,3,5,7,9,11,13,15}};
		tS.stripSize.tooltip = {{['Width in pixels in FFT domain of filter.' 10 'Higher values allow more tolerance for strips that are not exactly vertical or horizontal.']}};
	tS.stripfreqLowExclude = [];
		tS.stripfreqLowExclude.val = {{20,userSelectVal,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400}};
		tS.stripfreqLowExclude.str = {{20,userSelectStr,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400}};
		tS.stripfreqLowExclude.tooltip = {{'Lowest frequency of stripe to exclude from strip filter.'}};
	tS.stripfreqHighExclude = [];
		tS.stripfreqHighExclude.val = {{20,userSelectVal,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400}};
		tS.stripfreqHighExclude.str = {{20,userSelectStr,1,2,3,4,5,7,10,15,20,25,30,35,40,45,50,60,70,80,100,150,200,250,300,350,400}};
		tS.stripfreqHighExclude.tooltip = {{'Highest frequency of stripe to exclude from strip filter.'}};
	tS.stripfreqBandpassType = [];
		tS.stripfreqBandpassType.val = {{'highpass','bandpass','lowpass'}};
		tS.stripfreqBandpassType.str = {{'highpass','bandpass','lowpass'}};
		tS.stripfreqBandpassType.tooltip = {{'Type of stripe bandpass to use.'}};

	if ~isempty(options.inputSettings)
		try
			nonDefaultProperties = {};
			propertyListTmp = fieldnames(tS);
			nProperties = size(propertyListTmp,1);
			for propertyNo = 1:nProperties
				property = char(propertyListTmp(propertyNo));

				% Check if value had been modified from default, if so then add that as the 1st, default option.
				% if isequal(options.inputSettings.(property).val{1},tS.(property).val{1})
				if isfield(options.inputSettings.(property),'modified')
					nonDefaultProperties{end+1} = property;
					tS.(property).val = {[options.inputSettings.(property).modified.val,tS.(property).val{1}]};
					tS.(property).str = {[options.inputSettings.(property).modified.str,tS.(property).str{1}]};
				end
			end
			options.inputSettings
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	else
		nonDefaultProperties = {};
	end

	% propertySettings = turboregSettingDefaults;
	preprocessingSettingsAll = tS;

	propertyList = fieldnames(preprocessingSettingsAll);
	nPropertiesToChange = size(propertyList,1);

	% add current property to the top of the list
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		% propertyOptions = turboregSettingStr.(property);
		propertyOptions = preprocessingSettingsAll.(property).str{1};
		propertySettingsStr.(property) = propertyOptions;
		% propertySettingsStr.(property);
	end

	figNoDefault = 1337;
	uiListHandles = {};
	uiTextHandles = {};
	uiXIncrement = 0.025;
	uiXOffset = 0.02;
	uiYOffset = 0.90;
	uiTxtSize = 0.4;
	uiBoxSize = 0.55;
	uiFontSize = 11;
	nGuiSubsets = 3;
	% subsetList = round(linspace(1,nPropertiesToChange,nGuiSubsets));
	subsetList = [1 35 nPropertiesToChange];
	% subsetList
	% for subsetNo = 1:nGuiSubsets
	nGuiSubsetsTrue = (nGuiSubsets-1);
	figure(figNoDefault);
	for thisSet = 1:nGuiSubsetsTrue
		% 1:nPropertiesToChange
		% subsetStartTime = tic;
		subsetStartIdx = subsetList(thisSet);
		subsetEndIdx = subsetList(thisSet+1);
		if thisSet==nGuiSubsetsTrue
			propertySubsetList = subsetStartIdx:(subsetEndIdx);
		else
			propertySubsetList = subsetStartIdx:(subsetEndIdx-1);
		end

		[figHandle figNo] = openFigure(figNoDefault, '');
		clf
		uicontrol('Style','Text','String',inputTitleStr,'Units','normalized','Position',[uiXOffset uiYOffset+0.05 0.8 0.05],'BackgroundColor','white','HorizontalAlignment','Left','FontSize',uiFontSize);
		uicontrol('Style','Text','String',sprintf('Options page %d/%d: Mouse over each options for tips. To continue, press enter. Orange = previous non-default settings.\n>>>On older MATLAB versions, select the command window before pressing enter.',thisSet,nGuiSubsets-1),'Units','normalized','Position',[uiXOffset uiYOffset+0.02 uiTxtSize+uiBoxSize 0.05],'BackgroundColor','white','HorizontalAlignment','Left','FontSize',uiFontSize);

		propertyNoDisp = 1;
		for propertyNo = propertySubsetList
			property = char(propertyList(propertyNo));
			% propertyTooltip = turboregSettingTooltips.(property);
			propertyTooltip = char(preprocessingSettingsAll.(property).tooltip{1});
			% disp([num2str(propertyNo) ' | ' property])
			if propertyNo~=1
				if isempty(regexp(property,'______________'))
					spaceMod = 0.00;
				else
					spaceMod = 0.02;
					uiYOffset = uiYOffset-spaceMod;
				end
			end
			uiTextHandles{propertyNo} = uicontrol('Style','text','String',[property '' 10],'Units','normalized','Position',[uiXOffset uiYOffset-uiXIncrement*propertyNoDisp+0.027 uiTxtSize 0.0225],'BackgroundColor',[0.9 0.9 0.9],'ForegroundColor','black','HorizontalAlignment','Left','FontSize',uiFontSize,'ToolTip',propertyTooltip);
			% jEdit = findjobj(uiTextHandles{propertyNo});
			% lineColor = java.awt.Color(1,0,0);  % =red
			% thickness = 3;  % pixels
			% roundedCorners = true;
			% newBorder = javax.swing.border.LineBorder(lineColor,thickness,roundedCorners);
			% jEdit.Border = newBorder;
			% jEdit.repaint;  % redraw the modified control
			% uiTextHandles{propertyNo}.Enable = 'Inactive';
			% optionCallback = ['set(uiListHandles{propertyNo}, ''Backgroundcolor'', ''g'')'];
			% uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiXOffset+uiTxtSize uiYOffset-uiXIncrement*propertyNoDisp uiBoxSize 0.05],'Callback',@(hObject,callbackdata){set(hObject, 'Backgroundcolor', [208,229,180]/255);},'FontSize',uiFontSize);
			uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiXOffset+uiTxtSize uiYOffset-uiXIncrement*propertyNoDisp uiBoxSize 0.05],'Callback',@subfxnInterfaceCallback,'FontSize',uiFontSize,'Tag',property);
			% ,'ToolTip',propertyTooltip

			% If property is non-default, set to orange to alert user.
			if any(ismember(nonDefaultProperties,property))
				set(uiListHandles{propertyNo},'Backgroundcolor',[254 216 177]/255);
			end

			propertyNoDisp = propertyNoDisp+1;
		end
		pause
		uiYOffset = 0.90;

		for propertyNo = propertySubsetList
			property = char(propertyList(propertyNo));
			uiListHandleData = get(uiListHandles{propertyNo});
			if isempty(regexp(property,'______________'))
				preprocessSettingStruct.(property) = preprocessingSettingsAll.(property).val{1}{uiListHandleData.Value};
			else
				preprocessSettingStruct.(property) = preprocessingSettingsAll.(property).val{1};
			end
			% preprocessSettingStruct.(property) = turboregSettingDefaults.(property){uiListHandleData.Value};
		end
	end
	close(1337)

	% ensure rotation setting matches appropriate registration type
	if preprocessSettingStruct.turboregRotation==1
		preprocessSettingStruct.RegisType = 3;
	end

	preprocessSettingStruct.refCropFrame = preprocessSettingStruct.motionCorrectionRefFrame;

	% if preprocessSettingStruct.refCropFrame==0
	% 	movieSettings = inputdlg({...
	% 			'frame to reference to: '...
	% 		},...
	% 		'view movie settings',1,...
	% 		{...
	% 			'100'...
	% 		}...
	% 	);
	% 	preprocessSettingStruct.refCropFrame = str2num(movieSettings{1});
	% end
	function subfxnInterfaceCallback(hObject,callbackdata)
		set(hObject, 'Backgroundcolor', [208,229,180]/255);

		% De-select the current option, allows user to press enter to continue.
		set(hObject, 'Enable', 'off');
		drawnow;
		set(hObject, 'Enable', 'on');

		% If user asks to manually specify motion correction frame
		if any(strcmp(userOptionsAllowManualSelect,get(hObject,'Tag')))==1
			thisProperty = userOptionsAllowManualSelect{strcmp(userOptionsAllowManualSelect,get(hObject,'Tag'))};
			gValue = get(hObject,'Value');
			gString = get(hObject,'String');
			gTooltip = char(get(hObject,'ToolTip'));
			gProperty = get(hObject,'Tag');
			if strcmp(thisProperty,'motionCorrectionRefFrame')==1
				defVal = num2str(obj.motionCorrectionRefFrame);
			else
				defVal = char(gString{1});
			end
			if strcmp(gString{gValue},userSelectStr)==1
				inputCheck = 'Americans love a winner.';
				while isnan(str2double(inputCheck))==1|length(str2num(inputCheck))~=1
					movieSettings = inputdlg({...
							gTooltip...
						},...
						[thisProperty ' settings'],[1 70],...
						{...
							defVal...
						}...
					);

					% Check users has input correct, else ask again.
					inputCheck = movieSettings{1};
					if isnan(str2double(inputCheck))==1|length(str2num(inputCheck))~=1
						uiwait(msgbox('Please input a SINGLE numeric value (no strings or vectors).'));
					end
				end
				gStringNew = [movieSettings{1};gString];
				set(hObject,'String',gStringNew);
				set(hObject,'Value',1);
				% preprocessingSettingsAll.(gProperty).val = [str2num(movieSettings{1}),preprocessingSettingsAll.(gProperty).val];
				preprocessingSettingsAll.(gProperty).val = {[str2num(movieSettings{1}),preprocessingSettingsAll.(gProperty).val{1}]};
				preprocessingSettingsAll.(gProperty).str = {gStringNew};
				% turboregSettingDefaults.(thisProperty) = [str2num(movieSettings{1}),turboregSettingDefaults.(thisProperty)];
				% turboregSettingStr.(thisProperty) = gStringNew;
			end
		end

		% Indicate value was modified for later input of previous settings.
		gProperty = get(hObject,'Tag');
		gValue = get(hObject,'Value');
		gString = get(hObject,'String');
		preprocessingSettingsAll.(gProperty).modified = [];
		preprocessingSettingsAll.(gProperty).modified.val = preprocessingSettingsAll.(gProperty).val{1}{gValue};
		preprocessingSettingsAll.(gProperty).modified.str = gString{gValue};

	end
end