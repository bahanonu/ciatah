function obj = help(obj)
	% Display information on various functions.
	% Biafra Ahanonu
	% started: 2014.10.08
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.07 [17:48:52] - Added more information to the help section.
		% 2020.05.11 [08:57:09] - Added additional help and display on command line.
	% TODO
		%

	javaHelpUrl = "https://www.mathworks.com/help/matlab/matlab_external/java-heap-memory-preferences.html";
	javaTmpStr = sprintf('\n\nSee how to change Java heap memory online at:<a href="%s">Java Heap Memory Preferences</a> (<a href="%s">%s</a>).',javaHelpUrl,javaHelpUrl,javaHelpUrl);
	helpText = ['calciumImagingAnalysis help' 10 ...
		'The usually problems are:' 10 ...
		'1) calciumImagingAnalysis is not the current path in MATLAB.' 10 ...
		'2) calciumImagingAnalysis repository is located in a directory that MATLAB cannot write to.' 10 ...
		'3) the folders given to calciumImagingAnalysis do not point to valid folders on the system.' 10 ...
		'4) the regular expressions for TIFF/HDF5/NWB/AVI/etc. movie files are not correct and thus calciumImagingAnalysis cannot find movies in each folder.' 10 ...
		'5) ImageJ/Fiji fails to load due to memory issues, increase Java Heap Memory, see https://www.mathworks.com/help/matlab/matlab_external/java-heap-memory-preferences.html.' 10 10 ...
		'Help section will have more information soon!' 10 10 ...
		'Press OK to continue.'];

	disp(helpText);
	disp(javaTmpStr);
	uiwait(msgbox(helpText,'Note to user','modal'));

	% scnsize = get(0,'ScreenSize');
	% [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','stimuli to analyze?');

	% obj = computeDiscreteAlignedSignal(obj)
	% obj = computeSpatioTemporalClustMetric(obj)
	% obj = computeSignalPeaksFxn(obj)
	% obj = computeMatchObjBtwnTrials(obj)
	% obj = computeAcrossTrialSignalStimMetric(obj)
	% %
	% obj = computeContinuousAlignedSignal(obj)

	% %
	% obj = computeClassifyTrainSignals(obj)
	% obj = computeManualSortSignals(obj)
	% %
	% obj = computeTestFxn(obj)

	% % view methods, for displaying charts
	% % no prior computation
	% obj = viewStimTrigTraces(obj)
	% obj = viewCorr(obj)
	% obj = viewCreateObjmaps(obj)
	% % require pre-computation, individual
	% obj = viewStimTrig(obj)
	% obj = viewObjmapStimTrig(obj)
	% obj = viewChartsPieStimTrig(obj)
	% obj = viewObjmapSignificant(obj)
	% obj = viewSpatioTemporalMetric(obj)
	% % require pre-computation, group
	% obj = viewPlotSignificantPairwise(obj)
	% obj = viewObjmapSignificantPairwise(obj)
	% obj = viewObjmapSignificantAllStims(obj)
	% % movies
	% obj = viewMovieCreateSignalBasedStimTrig(obj)
	% % require pre-computation and behavior metrics, individual
	% obj = viewSignalBehaviorCompare(obj)

	% % model methods, usually for input-output like saving information to files
	% obj = modelReadTable(obj,varargin)
	% obj = modelTableToStimArray(obj,varargin)
	% obj = modelGetFileInfo(obj)
	% obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID)
	% obj = modelSaveSummaryStats(obj)
	% obj = modelSaveDetailedStats(obj)
	% obj = modelVarsFromFiles(obj)
	% % helper
	% [inputSignals inputImages signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj)

	% % set methods, for IO to specific variables in a controlled manner
	% obj = setMainSettings(obj)
end