function [k] = createStimCutMovieMontage(inputMovie,nAlignPts,timeVector,varargin)
	% Creates a montage movie aligned to specific timepoints.
	% Biafra Ahanonu
	% fxn started: 2014.08.13 - broke off from controllerAnalysis script from ~2014.03
	% inputs
		% inputMovie - path to movie file, in cell array, e.g. {'path.h5'}
		% inputAlignPts - vector containing the frames to align to
		% savePathName - path to save output movie, exclude the extension.
	% outputs
		% 2015.11.05

	%========================
	%
	options.postOffset = [];
	options.preOffset = [];
	%
	options.montageSuffix = [];
	%
	options.savePathName =  [];
	% if want the montage to be in a row
	options.saveFile = 0;
	% if want a square
	options.squareMontage = 1;
	%
	options.addStimMovie = 1;
	% Vector of linearized coordinates
	options.boundaryOutlines = [];
	% which tiles to add outlines to
	options.boundaryOutlineNum = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% display('creating montage...');
	% =======================
	% SAVE AN ARRAY of the movie cut to the alignment pt
	% this is super hacky at the moment, but it WORKs, so don't whine. Basically trying to make a square matrix of the primary movie cut to the stimulus. Convert to cell array, add a fake movie that blips at stimulus, line up all movies horizontally then cut into rows determined by the number of stimuli...
	[m n t] = size(inputMovie);
	nStims = nAlignPts;
	stimLength = length(timeVector(:));
	k = mat2cell(inputMovie,m,n,stimLength*ones([1 nStims]));
	if options.addStimMovie==1
		tmpMovie = NaN([m n stimLength]);
		if ~isempty(options.preOffset)
			tmpMovie(:,:,options.preOffset+1) = 1e5;
		end
		tmpMovie(:,:,1) = nanmean(inputMovie(:));
		tmpMovie(:,:,round(stimLength/2)) = nanmax(inputMovie(:));
		% tmpMovie(:,:,ceil(stimLength/2)) = 1;
		k{end+1} = tmpMovie;
		[xPlot yPlot] = getSubplotDimensions(nStims+1);
	else
		[xPlot yPlot] = getSubplotDimensions(nStims);
	end
	%playMovie([k{:}])
	squareNeed = xPlot*yPlot;
	% length(k);
	if options.squareMontage==1
		dimDiff = squareNeed-length(k);
		diffDiffMatrix = NaN([m n stimLength]);
		% diffDiffMatrix(:,:,1) = nanmax(inputMovie(:));
		% diffDiffMatrix(:,:,1) = nanmean(inputMovie(:));
		% diffDiffMatrix(:,:,round(stimLength/2)) = nanmax(inputMovie(:));
		for ii=1:dimDiff
			k{end+1} = diffDiffMatrix;
		end
	end
	% size(k);
	% line up all movies horizontally and then cut into rows
	k = [k{:}];
	[m2 n2 t2] = size(k);
	if options.squareMontage==1
		nRows = yPlot+1;
	else
		nRows = yPlot;
	end
	splitIdx = diff(ceil(linspace(1,n2,nRows)));
	splitIdx(end) = splitIdx(end)+1;
	% convert each row to a cell then vertically concat
	k = mat2cell(k,m2,splitIdx,t2);
	% Use vercat to make the tiling of all the outlines.
	k = vertcat(k{:});

	if options.saveFile==1
		saveDir = [options.savePathName options.montageSuffix];
		[pathstr,name,ext] = fileparts(saveDir);
		saveDir = [pathstr filesep 'montage' filesep name ext];
		writeHDF5Data(k,saveDir);
	end
	% ======================
end