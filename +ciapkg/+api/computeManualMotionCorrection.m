function [inputImagesTranslated, outputStruct] = computeManualMotionCorrection(inputImages,varargin)
	% Translates a marker image relative to a cell map and then allows the user to click for marker positive cells or runs automated market detection and alignment to actual cells
	% Biafra Ahanonu
	% started: 2017.12.05 [17:02:58] - branched from getMarkerLocations.m
	% inputs
		% inputImages - [x y z] where z = individual frames with image to register. By default the first frame is used as the "reference" image in green.
	% outputs
		% outputStruct.registeredMarkerImage
		% outputStruct.translationVector = {1 z} cell array containing inputs for imtranslate so users can manually correct if needed.
		% outputStruct.rotationVector = {1 z} cell array containing inputs for imrotate so users can manually correct if needed.
		% outputStruct.gammaCorrection
		% outputStruct.inputImagesCorrected
		% outputStruct.inputImagesOriginal

	[inputImagesTranslated, outputStruct] = ciapkg.motion_correction.computeManualMotionCorrection(inputImages,'passArgs', varargin);
end