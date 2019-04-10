function obj = modelModifyMovies(obj)
	% Either modify an existing movie (e.g. to remove edges) or store a temporary file to be loaded later for other files
	% Biafra Ahanonu
	% started: 2016.02.19
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	try
		% get user input
		movieSettings = inputdlg({...
				'start:end frames for preview (blank = all frames)',...
				'start:end frames for saving (blank = all frames)',...
				'file regexp:',...
				'replacement file regexp:',...
				'analyze specific folder (leave blank to copy to same folder)',...
				'input HDF5 dataset name',...
				'output HDF5 dataset name',...
				'load movie in equal parts (0 = disable feature):'...
				'alt file regexp:',...
				'alt replacement file regexp:',...
			},...
			'copy files to /archive/ folder',1,...
			{...
				'1:25',...
				'',...
				obj.fileFilterRegexp,...
				'manualCut',...
				'',...
				obj.inputDatasetName,...
				obj.inputDatasetName,...
				'10'...
				obj.fileFilterRegexpAlt,...
				'manualAltCut',...
			}...
		);
		setNo = 1;
		frameList = str2num(movieSettings{setNo});setNo = setNo+1;
		frameListSave = str2num(movieSettings{setNo});setNo = setNo+1;
		fileFilterRegexp = movieSettings{setNo};setNo = setNo+1;
		replaceFileFilterRegexp = movieSettings{setNo};setNo = setNo+1;
		saveSpecificFolder = movieSettings{setNo};setNo = setNo+1;
		inputDatasetName =  movieSettings{setNo};setNo = setNo+1;
		outputDatasetName =  movieSettings{setNo};setNo = setNo+1;
		loadMovieInEqualParts = str2num(movieSettings{setNo});setNo = setNo+1;

		fileFilterRegexpAlt = movieSettings{setNo};setNo = setNo+1;
		replaceFileFilterRegexpAlt = movieSettings{setNo};setNo = setNo+1;

		% analyzeMovieFiles =  str2num(movieSettings{6});
		obj.fileFilterRegexp = replaceFileFilterRegexp;
		obj.fileFilterRegexpAlt = replaceFileFilterRegexpAlt;


        % get files to analyze
		[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

		% start Miji
		modelAddOutsideDependencies('miji');
		% Miji;
		% MIJ.start;
		manageMiji('startStop','start');

		% loop over all directories, get masks from user first then batch
		% cropping whole movies
        movieMaskArray = cell([1 5]);
		for thisFileNumIdx = 1:nFilesToAnalyze
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			try
				maskNo = 1;
				movieDecision = 'tmp';

				movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				moviePath = movieList{1};
				[frameListTmp] = subfxnVerifyFrameList(frameList,moviePath,inputDatasetName,loadMovieInEqualParts);
				[primaryMovie] = loadMovieList(moviePath,'convertToDouble',0,'frameList',frameListTmp(:),'inputDatasetName',inputDatasetName);

				while ~strcmp(movieDecision,'done')
					% ranMovie = rand([1000 1000 20]);

					try
						[movieMask] = subfxnCreateMask(movieMaskArray{thisFileNumIdx});
						if ~isempty(movieMask)
							primaryMovie = bsxfun(@times,primaryMovie,movieMask);
						end
					catch
						display('No mask')
					end

					MIJ.createImage(obj.folderBaseSaveStr{obj.fileNum}, primaryMovie, true);
		            for foobar=1:2; MIJ.run('In [+]'); end
		        	for foobar=1:2; MIJ.run('Enhance Contrast','saturated=0.35'); end
					% uiwait(msgbox('select region of movie to keep','Success','modal'));
		            movieDecision = questdlg('Should movie be cropped? YES (draw ROI of area to keep then request to draw another), NO (skips this movie), DONE (end ROI drawing, move onto cropping or next movie).', ...
							'Movie decision', ...
							'yes','no','done','yes');
		            if strcmp(movieDecision,'yes')|strcmp(movieDecision,'done')
		                try
		                    MIJ.run('Set Slice...', 'slice=1');
		                    MIJ.run('Set...', 'value=1');
		                    MIJ.run('Make Inverse');
		                    MIJ.run('Set...', 'value=0');
		                    MIJ.run('Select None');
		                    MIJ.run('Make Substack...', 'delete slices=1');
		                    movieMaskArray{thisFileNumIdx}{maskNo} = MIJ.getCurrentImage;
		                    % Ensure that it is a binary mask, sometimes ImageJ would give out negative values
		                    movieMaskArray{thisFileNumIdx}{maskNo} = movieMaskArray{thisFileNumIdx}{maskNo}>0;
		                    MIJ.run('Close All Without Saving');
		                catch err
		                    movieMaskArray{thisFileNumIdx}{maskNo} = [];
		                    try
		                        MIJ.run('Close All Without Saving');
		                    catch
		                    end
		                    display(repmat('@',1,7))
		                    disp(getReport(err,'extended','hyperlinks','on'));
		                    display(repmat('@',1,7))
		                end
		            else
		                MIJ.run('Close All Without Saving');
		                movieMaskArray{thisFileNumIdx}{maskNo} = [];
		            end
		            maskNo = maskNo + 1;
	            end
	       catch err
	           movieMaskArray{thisFileNumIdx}{maskNo} = [];
	           display(repmat('@',1,7))
	           disp(getReport(err,'extended','hyperlinks','on'));
	           display(repmat('@',1,7))
	       end
        end

        % obj.sumStats.movieMaskArray = movieMaskArray;
        % return

		% MIJ.exit;
		manageMiji('startStop','exit');

        % go through and crop each movie then save
        display(repmat('*',1,21))
        display(repmat('*',1,21))
        display('CROPPING THE MOVIES!');
		for thisFileNumIdx = 1:nFilesToAnalyze
			try
				thisFileNum = fileIdxArray(thisFileNumIdx);
				obj.fileNum = thisFileNum;
				display(repmat('=',1,21))
				display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);

	            % get previously stored mask
	            movieMask = movieMaskArray{thisFileNumIdx};
	            movieMask = cat(3,movieMask{:});
	            if isempty(movieMask)
	               continue;
	            end
	            movieMask = sum(movieMask,3);
	            maxVal = nanmax(movieMask(:));
	            figure;
	            	subplot(2,2,1);imagesc(movieMask);title(obj.folderBaseDisplayStr{obj.fileNum});axis equal tight;colorbar;
	            		colormap(gca,parula)
	            movieMask = movieMask==maxVal;
	            movieMask(isnan(movieMask)) = 1;
	            movieMask = logical(movieMask);
	            % figure;
	            	subplot(2,2,2);imagesc(movieMask);title(obj.folderBaseDisplayStr{obj.fileNum});axis equal tight;colorbar;

	            subfxnEditMovies(obj.inputFolders{obj.fileNum},fileFilterRegexp,replaceFileFilterRegexp,frameListSave,inputDatasetName,outputDatasetName,loadMovieInEqualParts,movieMask,obj.folderBaseDisplayStr{obj.fileNum},3);

	            subfxnEditMovies(obj.inputFolders{obj.fileNum},fileFilterRegexpAlt,replaceFileFilterRegexpAlt,frameListSave,inputDatasetName,outputDatasetName,loadMovieInEqualParts,movieMask,obj.folderBaseDisplayStr{obj.fileNum},4);
	   %          % load entire movie and crop
	   %          movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
				% moviePath = movieList{1};
				% [frameListSaveTmp] = subfxnVerifyFrameList(frameListSave,moviePath,inputDatasetName,loadMovieInEqualParts);
				% [primaryMovie] = loadMovieList(moviePath,'convertToDouble',0,'frameList',frameListSaveTmp,'inputDatasetName',inputDatasetName,'largeMovieLoad',1);
				% primaryMovie = bsxfun(@times,primaryMovie,movieMask);

				% 	subplot(2,2,3);imagesc(primaryMovie(:,:,round(end/2)));title(obj.folderBaseDisplayStr{obj.fileNum});axis equal tight;colorbar; colormap gray;
				% 	% colormap(customColormap([]))

				% % save the file in the new location
				% [PATHSTR,NAME,EXT] = fileparts(moviePath);
				% % newPathFile = [PATHSTR filesep NAME '_manualCrop' EXT];
				% newPathFile = [PATHSTR filesep strrep(NAME,fileFilterRegexp,replaceFileFilterRegexp) EXT];
				% % [output] = writeHDF5Data(primaryMovie,newPathFile,'datasetname',				outputDatasetName);
				% % make a copy of the file then append the modified movie inside, preserved movie setting information
				% copyfile(moviePath,newPathFile);
				% [output] = writeHDF5Data(primaryMovie,newPathFile,'datasetname',outputDatasetName,'writeMode','append');
			catch err
			    movieMaskArray{thisFileNumIdx} = [];
			    display(repmat('@',1,7))
			    disp(getReport(err,'extended','hyperlinks','on'));
			    display(repmat('@',1,7))
			end
        end

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end
function subfxnEditMovies(inputFolderHere,fileFilterRegexp,replaceFileFilterRegexp,frameListSave,inputDatasetName,outputDatasetName,loadMovieInEqualParts,movieMask,folderBaseDisplayStr,subplotNo)
	% load entire movie and crop
	movieList = getFileList(inputFolderHere, fileFilterRegexp);
	moviePath = movieList{1};
	[frameListSaveTmp] = subfxnVerifyFrameList(frameListSave,moviePath,inputDatasetName,loadMovieInEqualParts);
	[primaryMovie] = loadMovieList(moviePath,'convertToDouble',0,'frameList',frameListSaveTmp,'inputDatasetName',inputDatasetName,'largeMovieLoad',1);
	primaryMovie = bsxfun(@times,primaryMovie,movieMask);

		subplot(2,2,subplotNo);imagesc(primaryMovie(:,:,round(end/2)));title(folderBaseDisplayStr);axis equal tight;colorbar; colormap gray;
		% colormap(customColormap([]))

	% save the file in the new location
	[PATHSTR,NAME,EXT] = fileparts(moviePath);
	% newPathFile = [PATHSTR filesep NAME '_manualCrop' EXT];
	newPathFile = [PATHSTR filesep strrep(NAME,fileFilterRegexp,replaceFileFilterRegexp) EXT];
	% [output] = writeHDF5Data(primaryMovie,newPathFile,'datasetname',				outputDatasetName);
	% make a copy of the file then append the modified movie inside, preserved movie setting information
	copyfile(moviePath,newPathFile);
	[output] = writeHDF5Data(primaryMovie,newPathFile,'datasetname',outputDatasetName,'writeMode','append');
end
function [frameListTmp] = subfxnVerifyFrameList(frameList,moviePath,inputDatasetName,loadMovieInEqualParts)
	if isempty(frameList)
		frameListTmp = frameList;
	else
		movieDims = loadMovieList(moviePath,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single','getMovieDims',1);
		frameListTmp = frameList;

		% loadMovieInEqualParts = 8;
		movieDims = loadMovieList(moviePath,'convertToDouble',0,'frameList',[],'inputDatasetName',inputDatasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single','getMovieDims',1);
		tmpList = round(linspace(1,sum(movieDims.z)-length(frameListTmp),loadMovieInEqualParts));
		display(['tmpList' num2str(tmpList)])
		tmpList = bsxfun(@plus,tmpList,frameListTmp(:));
		frameListTmp = tmpList(:);
		frameListTmp(frameListTmp<1) = [];
		frameListTmp(frameListTmp>sum(movieDims.z)) = [];

		% remove frames that are too large
		frameListTmp(frameListTmp>=movieDims.z) = [];
	end
end

function [movieMask] = subfxnCreateMask(movieMask)
	% get previously stored mask
	% movieMask = movieMaskArray{thisFileNumIdx};
	movieMask = cat(3,movieMask{:});
	% if isempty(movieMask)
	   % continue;
	% end
	movieMask = sum(movieMask,3);
	maxVal = nanmax(movieMask(:));
	movieMask = movieMask==maxVal;
	movieMask(isnan(movieMask)) = 1;
	movieMask = logical(movieMask);
end