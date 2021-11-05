function [success] = createMatchObjBtwnTrialsMaps(inputImages,matchStruct,varargin)
	% Creates obj maps that are color coded by the objects global ID across imaging sessions to check quality of cross-session alignment.
	% Biafra Ahanonu
	% started: 2020.04.08 [11:36:38]
	% inputs
		% inputImages - cell array of [x y nFilters] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}, that should ALREADY be properly translated.
		% matchStruct - output structure from matchObjBtwnTrials.
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		% Allow user to interactively switch between maps via a callback figure

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Str: path to save output AVI and related files.
	options.picsSavePath = ['private' filesep '_tmpFiles'];
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
		success = 0;
		thisFigNo = 42;
		thisFigNo
		globalIDs = matchStruct.globalIDs;
		globalIDsTmp = globalIDs;
		nSessions = length(inputImages);
		nMatchGlobalIDs = sum(globalIDs~=0,2);
		nGlobalIDs = size(globalIDsTmp,1);

		for sessionNo = 1:nSessions
			globalToSessionIDs{sessionNo} = zeros([size(inputImages{sessionNo},3) 1]);
		end
		for sessionNo = 1:nSessions
			for globalNo = 1:nGlobalIDs
				sessionIdx = globalIDsTmp(globalNo,sessionNo);
				if sessionIdx~=0
					globalToSessionIDs{sessionNo}(sessionIdx) = globalNo;
				end
			end
		end

		for matchingNumbers = [1 2 3]
			folderSaveName = {'matchObjColorMapAllMatched','matchObjColorMap70percentMatched','matchObjColorMap50percentMatched'};
			fractionShow = [1 0.7 0.5];
			for sessionNo = 1:nSessions
				try
					thisFileID = num2str(sessionNo);
					globalToSessionIDsTmp = globalToSessionIDs{sessionNo};
					keepIDIdx = globalIDs(nMatchGlobalIDs>=round(nSessions*fractionShow(matchingNumbers)),sessionNo);
					keepIDIdx(keepIDIdx<1) = [];
					keepIDIdx(keepIDIdx>length(globalToSessionIDsTmp)) = [];
					if isempty(keepIDIdx)
						keepIDIdx = 1;
					end
					display('++++++++')
					globalToSessionIDsTmp(setdiff(1:length(globalToSessionIDsTmp),keepIDIdx)) = 1;
					globalToSessionIDsTmp(keepIDIdx) = globalToSessionIDsTmp(keepIDIdx)+10;
					[groupedImagesRates] = groupImagesByColor(inputImages{sessionNo},globalToSessionIDsTmp);
					thisCellmap = createObjMap(groupedImagesRates);
					thisCellmap(1,1) = 1;
					thisCellmap(1,2) = nGlobalIDs;
					setCmapHere = @(nGlobalIDs) colormap([0 0 0; [1 1 1]*0.3; hsv(nGlobalIDs)]);
					[~, ~] = openFigure(sessionNo, '');
						clf
						imagesc(thisCellmap+1);box off;axis off
						% colormap([1 1 1; 0.9 0.9 0.9; hsv(nGlobalIDs)]);
						setCmapHere(nGlobalIDs);
						set(sessionNo,'PaperUnits','inches','PaperPosition',[0 0 9 9])
						drawnow;
					[~, ~] = openFigure(thisFigNo, '');
					subplot(1,nSessions,sessionNo)
						imagesc(thisCellmap+1);box off;axis off;
						% colormap([1 1 1; 0.9 0.9 0.9; hsv(nGlobalIDs)]);
						setCmapHere(nGlobalIDs);
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end

			if ~exist(options.picsSavePath,'dir');mkdir(options.picsSavePath);fprintf('Creating directory: %s\n',options.picsSavePath);end
			% saveVideoFile = [options.picsSavePath filesep folderSaveName{matchingNumbers} 'Session' filesep thisSubjectStr '_matchedCells.avi'];
			saveVideoFile = [options.picsSavePath filesep folderSaveName{matchingNumbers} 'Session_matchedCells.avi'];
			display(['save video: ' saveVideoFile])
			writerObj = VideoWriter(saveVideoFile,'Motion JPEG AVI');
			writerObj.FrameRate = 4;
			writerObj.Quality = 100;
			% writerObj.LosslessCompression = true;
			open(writerObj);
			for sessionNo = 1:nSessions
				% obj.fileNum = validFoldersIdx(sessionNo);
				% thisFileID = obj.fileIDArray{obj.fileNum};
				% obj.modelSaveImgToFile([],['matchObjColorMapSession' filesep thisSubjectStr],sessionNo,strcat(thisFileID));
				% set(sessionNo,'PaperUnits','inches','PaperPosition',[0 0 9 9])

				frame = getframe(sessionNo);
				[frameImg,map] = frame2im(frame);
				frameImg = imresize(frameImg,[1000 1000],'bilinear');
				writeVideo(writerObj,frameImg);
			end
			close(writerObj);
		end

		display('finished making global maps')
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
