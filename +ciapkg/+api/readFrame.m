function [thisFrame,movieFileID,inputMovieDims] = readFrame(inputMoviePath,frameNo,varargin)
	% Fast reading of frame from files on disk. This is an alternative to loadMovieList that is much faster when only a single frame needs to be read.
	% Biafra Ahanonu
	% started: 2020.10.19 [11:45:24]
	% inputs
		% inputMoviePath | Str: path to a movie. Supports TIFF, AVI, HDF5, NWB, or Inscopix ISXD.
		% frameNo | Int: frame number.
	% outputs
		%
	% Usage
		% For non-HDF5 file types, need to open a link to the 
			% [thisFrame,movieFileID,inputMovieDims] = ciapkg.io.readFrame(inputMoviePath,frameNo);
			% Then for the second call, feed in movieFileID and inputMovieDims to improve read speed.
			% [thisFrame] = ciapkg.io.readFrame(inputMoviePath,frameNo,'movieFileID',movieFileID,'inputMovieDims',inputMovieDims);

	% changelog
		% 2021.06.30 [01:26:29] - Updated handling of no file path character input.
		% 2021.07.03 [09:02:14] - Updated to have backup read method for different tiff styles.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	
	[thisFrame,movieFileID,inputMovieDims] = ciapkg.io.readFrame(inputMoviePath,frameNo,'passArgs', varargin);
end