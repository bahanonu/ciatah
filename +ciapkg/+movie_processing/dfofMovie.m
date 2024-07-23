function [dfofMatrix, inputMovieF0, inputMovieStd] = dfofMovie(inputMovie, varargin)
	% Does deltaF/F and other relative fluorescence changes calculations for a movie using bsxfun for faster processing.
	% Biafra Ahanonu
	% started 2013.11.09 [09:12:36]
	% inputs
		% inputMovie - either a [x y t] matrix or a char string specifying a HDF5 movie.
	% outputs
		%
	% changelog
		% 2013.11.22 [17:49:34]
		% 2021.06.29 [12:11:43] - Add support for minimum and soft minimum dF/F calculation.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2024.04.3 [12:40:35] - Updated to allow users to adjust movies with negative values.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Char: hierarchy name in hdf5 where movie is
	options.inputDatasetName = '/1';
	% Char: divide, dfof, slidingZscore, binnedZscore, dfstd, minus
	options.dfofType = 'dfof';
	% String: 'soft' calculates based on percentile (to avoid outliers), 'min' calculates the normal minimum.
	options.minType = 'soft';
	% Float: Calculates the X percentile for minimum F0.
	options.minSoftPct = 0.1/100;
	% Binary: 1 = waitbar on
	options.waitbarOn = 1;
	% Float: Number >1.0 indicating how much to adjust
	options.minAdjust = 1.1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%   eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% check that input is not empty
	if isempty(inputMovie)
		return;
	end
	%========================
	% old way of saving, only temporary until full switch
	options.normalizationType = 'NA';
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	% Adjust for problems with movies that have negative pixel values before dfof.
	if isempty(options.minAdjust)
		minMovie = min(inputMovie,[],[1 2 3],'omitnan');
		if minMovie<0
			inputMovie = inputMovie + options.minAdjust*abs(minMovie);
		end
	end

	stdList = {'slidingZscore','binnedZscore','dfstd'};

	inputMovieClass = class(inputMovie);
	if strcmp(inputMovieClass,'char')
		inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
		% [pathstr,name,ext] = fileparts(inputFilePath);
		% options.newFilename = [pathstr '\concat_' name '.h5'];
	end
	inputMovieClass = class(inputMovie);

	% get the movie F0, do by row to reduce potential memory errors on some versions of Matlab
	if sum(strcmp(dfofType,stdList))>0
		disp('Getting F0 and F_std...')
	else
		disp('Getting F0...')
	end
	inputMovieF0 = zeros([size(inputMovie,1) size(inputMovie,2)]);
	inputMovieStd = zeros([size(inputMovie,1) size(inputMovie,2)]);
	% reverseStr = '';
	nRows = size(inputMovie,1);
	nInterval = round(nRows/10);%10

	% Determine the type of F0 calculation to perform.
	switch dfofType
		case 'dfof'
			F0fxn = @(x,y) nanmean(x,y);
		case 'dfofMin'
			switch options.minType
				case 'min'
					F0fxn = @(x,y) nanmin(x,y);
				case 'soft'
					F0fxn = @(x,y) prctile(x,options.minSoftPct,y);
				otherwise
					F0fxn = @(x,y) nanmin(x,y);
			end
		otherwise
			F0fxn = @(x,y) nanmean(x,y);
	end

	for rowNo=1:nRows
		% inputMovieF0 = nanmean(inputMovie,3);
		rowFrame = single(squeeze(inputMovie(rowNo,:,:)));
		% inputMovieF0(rowNo,:) = nanmean(rowFrame,2);
		inputMovieF0(rowNo,:) = F0fxn(rowFrame,2);
		if sum(strcmp(dfofType,stdList))>0
			inputMovieStd(rowNo,:) = nanstd(rowFrame,[],2);
		else
		end

		if (mod(rowNo,nInterval)==0||rowNo==1||rowNo==nRows)&&options.waitbarOn==1
			if rowNo==nRows
				fprintf('%d%%\n',round(rowNo/nRows*100))
			elseif rowNo==1
				fprintf('%d%%|',round(rowNo/nRows*100))
			else
				fprintf('%d|',round(rowNo/nRows*100))
			end
		end
		% reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);
	end

	% convert to single
	if ~strcmp(inputMovieClass,'single')
		inputMovieF0 = cast(inputMovieF0,'single');
		if sum(strcmp(dfofType,stdList))>0
			inputMovieStd = cast(inputMovieStd,'single');
		else
		end
		inputMovie = cast(inputMovie,'single');
	end
	% bsxfun for fast matrix divide
	switch dfofType
		case 'divide'
			disp('Calculating: F(t)/F0...')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
		case 'dfof'
			disp('Calculating: F(t)/F0 - 1...')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
			dfofMatrix = dfofMatrix-1;
		case 'dfofMin'
			disp('Calculating: F(t)/F0 - 1...')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
			dfofMatrix = dfofMatrix-1;
		case 'slidingZscore'
			disp('Calculating: sliding (F(t)-F0)/std..')

			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			% dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
			% dfofMatrix = dfofMatrix-1;
		case 'binnedZscore'
			disp('Calculating: sliding (F(t)-F0)/std..')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
			dfofMatrix = dfofMatrix-1;
		case 'dfstd'
			disp('Calculating: (F(t)-F0)/std...')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
			dfofMatrix = bsxfun(@ldivide,inputMovieStd,dfofMatrix);
			% dfofMatrix = dfofMatrix-1;
		case 'minus'
			disp('Calculating: F(t)-F0...')
			% dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
			dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
		otherwise
			return;
	end
end