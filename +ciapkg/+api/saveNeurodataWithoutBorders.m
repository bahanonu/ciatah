function [success] = saveNeurodataWithoutBorders(image_masks,roi_response_data,algorithm,outputFilePath,varargin)
	% Takes cell extraction outputs and saves then in NWB format per format in https://github.com/schnitzer-lab/nwb_schnitzer_lab.
	% Biafra Ahanonu
	% started: 2020.04.03 [16:01:45]
	% Based on mat2nwb in https://github.com/schnitzer-lab/nwb_schnitzer_lab.
	% inputs
		% image_masks - [x y z] matrix
		% roi_response_data - {1 N} cell with N = number of different signal traces for that algorithm. Make sure each signal trace matrix is in form of [nSignals nFrames].
		% algorithm - Name of the algorithm.
		% outputFilePath - file path to save NWB file to.
	% outputs
		%

	% changelog
		% 2020.07.01 [09:40:20] - Convert roi_response_data to cell if user inputs only a matrix.
		% 2020.09.15 [20:30:32] - Automatically creates directory where file is to be stored if it is not present.
		% 2021.02.01 [?‎15:14:40] - Function checks that yaml, matnwb, and nwb_schnitzer_lab loaded, else tries to load to make sure all dependencies are present and active.
		% 2021.02.01 [15:19:40] - Update `_external_programs` to call ciapkg.getDirExternalPrograms() to standardize call across all functions.
		% 2021.02.03 [12:34:06] - Added a check for inputs with a single signal and function returns as it is not supported.
		% 2021.03.20 [19:35:28] - Update to checking if only a single signal input.
	% TODO
		%

	[success] = ciapkg.io.saveNeurodataWithoutBorders(image_masks,roi_response_data,algorithm,outputFilePath,'passArgs', varargin);
end