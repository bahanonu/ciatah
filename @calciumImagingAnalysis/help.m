function obj = help(obj)
	% Display information on various functions.
	% Biafra Ahanonu
	% started: 2014.10.08
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	scnsize = get(0,'ScreenSize');
	[idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','stimuli to analyze?');

	obj = computeDiscreteAlignedSignal(obj)
	obj = computeSpatioTemporalClustMetric(obj)
	obj = computeSignalPeaksFxn(obj)
	obj = computeMatchObjBtwnTrials(obj)
	obj = computeAcrossTrialSignalStimMetric(obj)
	%
	obj = computeContinuousAlignedSignal(obj)

	%
	obj = computeClassifyTrainSignals(obj)
	obj = computeManualSortSignals(obj)
	%
	obj = computeTestFxn(obj)

	% view methods, for displaying charts
	% no prior computation
	obj = viewStimTrigTraces(obj)
	obj = viewCorr(obj)
	obj = viewCreateObjmaps(obj)
	% require pre-computation, individual
	obj = viewStimTrig(obj)
	obj = viewObjmapStimTrig(obj)
	obj = viewChartsPieStimTrig(obj)
	obj = viewObjmapSignificant(obj)
	obj = viewSpatioTemporalMetric(obj)
	% require pre-computation, group
	obj = viewPlotSignificantPairwise(obj)
	obj = viewObjmapSignificantPairwise(obj)
	obj = viewObjmapSignificantAllStims(obj)
	% movies
	obj = viewMovieCreateSignalBasedStimTrig(obj)
	% require pre-computation and behavior metrics, individual
	obj = viewSignalBehaviorCompare(obj)

	% model methods, usually for input-output like saving information to files
	obj = modelReadTable(obj,varargin)
	obj = modelTableToStimArray(obj,varargin)
	obj = modelGetFileInfo(obj)
	obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID)
	obj = modelSaveSummaryStats(obj)
	obj = modelSaveDetailedStats(obj)
	obj = modelVarsFromFiles(obj)
	% helper
	[inputSignals inputImages signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj)

	% set methods, for IO to specific variables in a controlled manner
	obj = setMainSettings(obj)
end