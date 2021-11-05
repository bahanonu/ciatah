function [inputMovie] = addDroppedFramesToMovie(inputMovie,droppedFrames,varargin)
	% Fixes movie by adding dropped frames with the mean of the movie (to reduce impact on cell extraction algorithms).
	% Biafra Ahanonu
	% started: 2016.10.04 [20:31:15]
	% inputs
		% inputMovie - matrix dims are [X Y t] - where t = number of time points
		% path to inscopix file or list of dropped frames
	% outputs
		% inputMovie with dropped frames added back in.

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.pathToInscopixFiles = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		if isempty(droppedFrames)
			if isempty(options.pathToInscopixFiles)
				return
			else
				% get information about number of frames and dropped frames from recording files
				listLogFiles = options.pathToInscopixFiles;
				cellfun(@display,listLogFiles);
				folderLogInfoList = cellfun(@(x) {getLogInfo(x)},listLogFiles,'UniformOutput',false);
				folderFrameNumList = {};
				droppedCountList = {};
				for cellNo = 1:length(folderLogInfoList)
					logInfo = folderLogInfoList{cellNo}{1};
					fileType = logInfo.fileType;
					switch fileType
						case 'inscopix'
							movieFrames = logInfo.FRAMES;
							droppedCount = logInfo.DROPPED;
						case 'inscopixXML'
							movieFrames = logInfo.frames;
							droppedCount = logInfo.dropped;
						otherwise
							% do nothing
					end
					% ensure that it is a string so numbers don't get added incorrectly
					if ischar(droppedCount)
						display(['converting droppedCount str2num: ' logInfo.filename])
					    droppedCount = str2num(droppedCount);
					end
					if ischar(movieFrames)
						display(['converting movieFrames str2num: ' logInfo.filename])
					    movieFrames = str2num(movieFrames);
					end
					folderFrameNumList{cellNo} = movieFrames;
					droppedCountList{cellNo} = droppedCount;
				end

			end

		end
		% TODO: to make this proper, need to verify that the log file names match those of movie files
		display(repmat('-',1,7));

		% if ~isempty(options.frameList)
		% 	display('Full movie needs to be loaded to add dropped frames')
		% 	return;
		% end

		display('adding in dropped frames if any')
		% listLogFiles = getFileList(thisDir,'recording.*.(txt|xml)');

		if isempty(listLogFiles)
			display('Add log files to folder in order to add back dropped frames')
			return;
		end


		% Add back in dropped frames as the mean of the movie, NaN would be *correct* but causes issues with some of the downstream downsampling algorithms
		% make the dropped frames and original num movie frames based on global across all movies, so dropped frames should match the CORRECTED global/concatenated movie's frame values
		originalNumMovieFrames = sum([folderFrameNumList{:}]);
		nMoviesDropped = length(folderLogInfoList);
		for movieDroppedNo = 1:nMoviesDropped
			folderFrameNumList{movieDroppedNo} = folderFrameNumList{movieDroppedNo}+ length(droppedCountList{movieDroppedNo});
		end
		droppedFramesTotal = droppedCountList{1};
		for movieDroppedNo = 2:nMoviesDropped
			droppedFramesTmp = droppedCountList{movieDroppedNo} + sum([folderFrameNumList{1:(movieDroppedNo-1)}]);
			droppedFramesTotal = [droppedFramesTotal(:); droppedFramesTmp(:)];
		end
		droppedFrames = droppedFramesTotal;

		if isempty(droppedFrames)
			display('No dropped frames!')
			return;
		end

		% framesToAdd = originalNumMovieFrames-size(inputMovie,3);
		% extend the movie, adding in the mean
		inputMovieDroppedF0 = zeros([size(inputMovie,1) size(inputMovie,2)]);
		nRows = size(inputMovie,1);
		reverseStr = '';
		for rowNo=1:nRows
		    inputMovieDroppedF0(rowNo,:) = nanmean(squeeze(inputMovie(rowNo,:,:)),2);
		    if rowNo==1||mod(rowNo,5)==0
		    	reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);
		    end
		end
		% movieMean = nanmean(inputMovieTmp(:));
		display([num2str(length(droppedFrames)) ' dropped frames: ' num2str(droppedFrames(:)')])
		display(['pre-corrected movie size: ' num2str(size(inputMovie))])
		inputMovie(:,:,(end+1):(end+length(droppedFrames))) = 0;
		display(['post-corrected movie size: ' num2str(size(inputMovie))])

		% vectorized way: get the setdiff(dropped,totalFrames), use this corrected frame indexes and map onto the actual frames in raw movie, shift all frames in original matrix to new position then add in mean to dropped frame indexes
		display('adding in dropped frames to matrix...')
		correctFrameIdx = setdiff(1:size(inputMovie,3),droppedFrames);
		inputMovie(:,:,correctFrameIdx) = inputMovie(:,:,1:originalNumMovieFrames);
		nDroppedFrames = length(droppedFrames);
		reverseStr = '';
		for droppedFrameNo = 1:nDroppedFrames
			inputMovie(:,:,droppedFrames(droppedFrameNo)) = inputMovieDroppedF0;
			if droppedFrameNo==1||mod(droppedFrameNo,5)==0
				reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','adding in dropped frames...','waitbarOn',1,'displayEvery',5);
			end
		end

		% loop over each dropped count and shift movie contents
		% nDroppedFrames = length(droppedFrames);
		% reverseStr = '';
		% for droppedFrameNo = 1:nDroppedFrames
		% 	inputMovie(:,:,(droppedFrames(droppedFrameNo)+1):(end)) = inputMovie(:,:,droppedFrames(droppedFrameNo):(end-1));
		% 	inputMovie(:,:,droppedFrames(droppedFrameNo)) = movieMean;
		% 	reverseStr = cmdWaitbar(droppedFrameNo,nDroppedFrames,reverseStr,'inputStr','adding back dropped frames...','waitbarOn',1,'displayEvery',5);
		% end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end