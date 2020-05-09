function [trackingTableFilteredCell] = removeIncorrectObjs(tablePath,varargin)
    % Removes incorrect objects from an ImageJ tracking CSV file
    % Biafra Ahanonu
    % started: 2014.05.01
    % inputs
        % tablePath - path to CSV file containing tracking information
    % outputs
        % trackingTableFiltered - table where each Slice (frame) only has a single associated set of column data, based on finding row with max area

    % changelog
        % updated: 2014.05.01 - improved speed by switching to more matrix operations-based filtering
		% 2020.01.27 [17:10:43] - Code clean-up and changed default cut-off values to Inf deal with NaNs rows when they should not be marked as NaNs on some datasets.
		% 2020.02.24 [20:41:44] - Updated plots to make clearer to users.
    % TODO
        % make assumption of columns NOT hardcoded as is currently
        % add parallel support

    % ========================
    % grouping row
    options.groupingVar = 'Slice';
    % variable to sort on
    options.sortingVar = 'Area';
    % rows to sort by and in what direction
    options.sortRows = {options.groupingVar,options.sortingVar};
    options.sortRowsDirection = {'ascend','descend'};
    % max size of sorting var, e.g. max area size
    options.maxSortingVar = [];
    % 'true' if want to save the file
    options.saveFile = [];
    % columns to keep (obsolete!)
    options.listOfCols = {'Area','XM','YM','Major','Minor','Angle'};
    % information table to add pxToCm
    options.subjectInfoTable = [];
    % px/frame to use as a cutoff.
    options.velocityCutoff = Inf; % 30*8
    % cm/s to use as a cutoff.
    options.velocityCutoffCm = Inf; % 90
    % analyze files by folder and group all files into a single folder
    options.groupFilesInFolder = 0;
    % whether to flip the file folder ordering
    options.flipFolderFileList = 0;
    % cell array containing [x y z] where z>=2 or cell array containing char strings to movie files
    options.inputMovie = {};
    % HDF5 input dataset name
    options.inputDatasetName = '/1';
    % conversion factor from frames to time
    options.framesPerSecond = 20;
    % override the grouping of files in folder by own color into a time color
    options.colorPlotOverride = 0;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    if strcmp(class(tablePath),'char')
        tablePath = {tablePath};
    end
    inputTablePaths = tablePath;
    nFiles = length(inputTablePaths);
    if options.groupFilesInFolder==1
        for pathNo=1:nFiles
            [inputTableParentPath{pathNo},NAME,EXT] = fileparts(inputTablePaths{pathNo});
        end
        inputTableParentPathList = unique(inputTableParentPath);
        nFiles = length(inputTableParentPathList);
        cellfun(@display,inputTableParentPath)
    end
    % for pathNo=nFiles:1
    %     [~, ~] = openFigure(pathNo, '');
    % end
    [~, ~] = openFigure(1, '');

    for pathNo=1:nFiles
        try
            tic
            if options.groupFilesInFolder==1
                % load all tables in a folder together and concatenate them
                display(repmat('=',1,7))
                display([num2str(pathNo) '/' num2str(nFiles) ': ' inputTableParentPathList{pathNo}])
                validFoldersIdx = find(strcmp(inputTableParentPathList{pathNo},inputTableParentPath));
                display(repmat('-',1,3))
                folderList = 1:length(validFoldersIdx);
                % flip the list if requested
                if options.flipFolderFileList==1
                    validFoldersIdx = flipdim(validFoldersIdx,2);
                end
                for folderNo = folderList
                    tablePath = inputTablePaths{validFoldersIdx(folderNo)};
                    display([num2str(folderNo) '/' num2str(length(validFoldersIdx)) ': ' tablePath])
                    trackingTable = readtable(tablePath,'Delimiter','comma','FileType','text');
                    repeatSize = [size(trackingTable,1) 1];
                    [inputTableParentPath{pathNo},NAME,EXT] = fileparts(tablePath);
                    trackingTable.file = repmat({NAME},repeatSize);
                    trackingTable.filePath = repmat({tablePath},repeatSize);
                    fileInfo = getFileInfo(tablePath);
                    trackingTable.subject = repmat({fileInfo.subject},repeatSize);
                    trackingTable.date = repmat({fileInfo.date},repeatSize);
                    filterInputTable()
                    if folderNo==1
                        trackingTableFilteredTmp = trackingTableFiltered;
                        % trackingTable = tmpTable;
                    else
                        trackingTableFilteredTmp = [trackingTableFilteredTmp;trackingTableFiltered];
                        % trackingTable = [trackingTable;tmpTable];
                    end
                    % clear tmpTable;
                end
                nFrames = size(trackingTableFilteredTmp,1);
                binSizeFrames = 6000;
                binGroupVector = [];
                repeatSize = [binSizeFrames 1];
                for binGroup = 1:ceil(nFrames/binSizeFrames)
                    % size(repmat(binGroup,repeatSize))
                    binGroupVector(end+1:end+binSizeFrames) = repmat(binGroup,repeatSize);
                end
                % size(binGroupVector(1:nFrames));
                trackingTableFilteredTmp.binGroupAll = binGroupVector(1:nFrames)';
                trackingTableFiltered = trackingTableFilteredTmp;
            else
                tablePath = inputTablePaths{pathNo};
                display(repmat('=',1,7))
                display([num2str(pathNo) '/' num2str(nFiles) ': ' tablePath])
                % read in the table
                trackingTable = readtable(tablePath,'Delimiter','comma','FileType','text');

                repeatSize = [size(trackingTable,1) 1];
                [inputTableParentPath{pathNo},NAME,EXT] = fileparts(tablePath);
                trackingTable.file = repmat({NAME},repeatSize);
                trackingTable.filePath = repmat({tablePath},repeatSize);
                fileInfo = getFileInfo(tablePath);
                trackingTable.subject = repmat({fileInfo.subject},repeatSize);
                trackingTable.date = repmat({fileInfo.date},repeatSize);
                tic
                filterInputTable()
            end

            % add in pixel to cm column if asked
            fileInfo = getFileInfo(tablePath);
            if ~isempty(options.subjectInfoTable)
                options.originalColumns = {'XM','YM'};
                options.newColumns = {'XM_cm','YM_cm'};
                options.modifierColumn = 'pxToCm';
                options.delimiter = ',';
                subjectInfoTable = readtable(char(options.subjectInfoTable),'Delimiter',options.delimiter,'FileType','text');
                % fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
                % subjectInfoTable
                dateIdx = strcmp(subjectInfoTable.date,strrep(fileInfo.date,'_','.'));
                subjectIdx = subjectInfoTable.subject==fileInfo.subjectNum;
                assayIdx = strcmp(subjectInfoTable.assay,fileInfo.assay);
                thisTable = subjectInfoTable(dateIdx&subjectIdx&assayIdx,:);
                thisTable = thisTable(1,:);
                for columnNo = 1:length(options.originalColumns)
                    trackingTableFiltered.(options.newColumns{columnNo}) = trackingTableFiltered.(options.originalColumns{columnNo})/thisTable.(options.modifierColumn);
                end
            else
                % options.originalColumns = {'XM','YM'};
                % options.newColumns = {'XM_cm','YM_cm'};
                % for columnNo = 1:length(options.originalColumns)
                %     trackingTableFiltered.(options.newColumns{columnNo}) = trackingTableFiltered.(options.originalColumns{columnNo});
                % end
            end

            [~, ~] = openFigure(1e3+pathNo, '');
                subfxn_plotAnimalTracks();
                colormap gray;

            [~, ~] = openFigure(pathNo, '');
            colormap gray;
            subplot(2,3,1)
                subfxn_plotAnimalTracks();
                axis equal tight;
                colormap(gca,gray)
				title(['Animal trace overlayed on arena' 10 'green = start, red = end'])
				box off;
            subplot(2,3,2)
                if ~isempty(options.inputMovie)
                    if strcmp(class(options.inputMovie{pathNo}),'char')|strcmp(class(options.inputMovie{pathNo}),'cell')
                        options.inputMovie{pathNo} = loadMovieList(options.inputMovie{pathNo},'convertToDouble',0,'frameList',50:51,'inputDatasetName',options.inputDatasetName);
                    end
                    imagesc(squeeze(options.inputMovie{pathNo}(:,:,1)))
                    hold on
                end

                yValCoords = trackingTableFiltered.YM;
                xValCoords = trackingTableFiltered.XM;
                yNan = isnan(yValCoords(:));
                xNan = isnan(xValCoords(:));
                yValCoords(yNan|xNan) = [];
                xValCoords(yNan|xNan) = [];
                % viewColorLinePlot(xValCoords,yValCoords,'nPoints',200,'colors',customColormap({[0 0 0],[0 1 0],[1 0 0]},'nPoints',200));
                ndhist(xValCoords,yValCoords,'bins',0.5);
                % figHandle = smoothhist2D([yValCoords; xValCoords]',7,[100,100],0.05,'image');
                % figHandle = smoothhist2D([trackingTableFiltered.YM(1:100); trackingTableFiltered.XM(1:100)]',7,[100,100],0.05,'image');
                hold on;
                % axis tight;
                % box off;
                % colormap(flipud(gray))
                plot(trackingTableFiltered.XM(10),trackingTableFiltered.YM(10),'.r','MarkerSize', 30);
                axis equal tight;
                colormap(gca,jet)
				title(['Animal occupancy (n = ' num2str(length(xValCoords)) ' total frames'])
				colorbar
				box off
            subplot(2,3,[4 5 6])
                nrows = size(trackingTableFiltered,1);
                timeVector = (1:nrows)/options.framesPerSecond/60;
				yyaxis left
                if options.groupFilesInFolder==1
                    if sum(strcmp('XM_cm',tableNames))
                        plotVelocity = tsmovavg(trackingTableFiltered.velocity_cm*options.framesPerSecond,'s',options.framesPerSecond,1);
                        gscatter(timeVector,plotVelocity,trackingTableFiltered.file,[],[],[],'off')
                        ylabel('cm/s');
                    else
                        plotVelocity = tsmovavg(trackingTableFiltered.velocity*options.framesPerSecond,'s',options.framesPerSecond,1);
                        gscatter(timeVector,plotVelocity,trackingTableFiltered.file,[],[],[],'off')
                        ylabel('px/s');
                    end
                    % set(gcf, 'Color', 'None')
                    legendStr = strrep(unique(strrep(trackingTableFiltered.file,'_',' ')),{'recording'},'');
                    legendStr = strrep(legendStr,'.avi','');
                    legendStr = strrep(legendStr,'.tracking','');
                    legend(sort(legendStr),'location','eastoutside')
                else
                    if sum(strcmp('XM_cm',tableNames))
                        plotVelocity = tsmovavg(trackingTableFiltered.velocity_cm*options.framesPerSecond,'s',options.framesPerSecond,1);
                        plot(timeVector,plotVelocity)
                        ylabel('cm/s');
                    else
                        plotVelocity = tsmovavg(trackingTableFiltered.velocity*options.framesPerSecond,'s',options.framesPerSecond,1);
                        plot(timeVector,plotVelocity)
                        ylabel('px/s');
                    end
				end
				xlabel(['Time (min) | total frames = ' num2str(nrows)]);
				title('Speed and cumulative distance traveled')
                axis tight
                box off;
                % hold on; plot([1 size(trackingTableFiltered,1)],[2 2],'r');
                % hold on; plot([1 size(trackingTableFiltered,1)],[options.velocityCutoff options.velocityCutoff],'r');
                % hold on;
           
			
			subplot(2,3,3)
				yyaxis right
				plot(timeVector,cumsum(plotVelocity,'omitnan'),'-','LineWidth',4);
				if sum(strcmp('XM_cm',tableNames))
					ylabel('Cumulative distance traveled (cm)')
				else
					ylabel('Cumulative distance traveled (px)')
				end
				title('Cumulative distance traveled')
				xlabel('Time (min)')
				axis tight;axis square
                box off;
				
            subplot(2,3,[4 5 6])
				yyaxis right
				hold on;
				if sum(strcmp('XM_cm',tableNames))
					hA = plot(timeVector,cumsum(plotVelocity,'omitnan')/100,'-','LineWidth',4);
					ylabel('Cumulative distance traveled (m)')
				else
					hA = plot(timeVector,cumsum(plotVelocity,'omitnan'),'-','LineWidth',4);
					ylabel('Cumulative distance traveled (px)')
				end
				%uistack(hA,'bottom')
				
			drawnow
			changeFont(14)
            disp('=====')

            % subplot(2,1,1)
            %     plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm,'r','LineWidth',0.1)
            %     viewColorLinePlot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm,'nPoints',200,'colors',customColormap({[0 0 0],[1 0 0]},'nPoints',200));
            %     axis tight
            % subplot(2,1,2)
            %     xdiff = [0; diff(trackingTableFiltered.XM)];
            %     ydiff = [0; diff(trackingTableFiltered.YM)];
            %     trackingTableFiltered.velocity = sqrt(xdiff.^2 + ydiff.^2);
                % plot(trackingTableFiltered.velocity,'r')
                % hold on; plot([1 size(trackingTableFiltered,1)],[2 2],'r');
                % hold on; plot([1 size(trackingTableFiltered,1)],[options.velocityCutoff options.velocityCutoff],'r');
                % hold off
                % hist(trackingTableFiltered.velocity,100)
                % hold on; plot([2 2],[1 1000],'r');
                % figure(pathNo+100)
                % plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm)
            fileInfoSaveStr = [strrep(strrep(fileInfo.date,'\','/'),'_','.') ' ' fileInfo.protocol ' ' fileInfo.subject ' ' fileInfo.assay];
            suptitle(fileInfoSaveStr);
            % suptitle(strrep(strrep(tablePath,'\','/'),'_','.'))

            % ===============
            % save file
            % save filtered table if user ask
            if ~isempty(options.saveFile)
                [pathstr,name,ext] = fileparts(tablePath);
                options.newFilename = [pathstr '\' name '_cleaned.csv'];
                display(['saving: ' options.newFilename])
                writetable(trackingTableFiltered,options.newFilename,'FileType','text','Delimiter',',');
            end
            % trackingTableFilteredCell{pathNo} = trackingTableFiltered;
            if pathNo==1
                trackingTableFilteredCell = trackingTableFiltered;
            else
                trackingTableFilteredCell = [trackingTableFilteredCell;trackingTableFiltered];
            end

            clear tmpTable trackingTableFiltered

            toc
            drawnow
        catch err
            display(repmat('@',1,7))
            disp(getReport(err,'extended','hyperlinks','on'));
            display(repmat('@',1,7))
        end
    end
    % old way of doing it, much slower
    % trackingTableFiltered = rowfun(@keepMaxArea,trackingTable,...
        % 'InputVariables',options.listOfCols,...
        % 'GroupingVariable','Slice',...
        % 'OutputVariableName',options.listOfCols);
    % nSlices = trackingTableFiltered.Slice(end);

    function filterInputTable()
        % make sure sort rows is updated
        options.sortRows = {options.groupingVar,options.sortingVar};
        % sort the rows, largest obj is first for each grouping variable value
        [trackingTableFiltered,index] = sortrows(trackingTable,options.sortRows,options.sortRowsDirection);
        % get the diff, allow index of first row in each slice, i.e. the max obj
        maxIdx = diff(trackingTableFiltered.(options.groupingVar));
        % first row should be indexed and offset corrected
        maxIdx = [1; maxIdx];
        % filter for largest objs
        trackingTableFiltered = trackingTableFiltered(logical(maxIdx),:);
        % toc;tic
        % if remove maxSortingVar
        if ~isempty(options.maxSortingVar)
            maxIdx = trackingTableFiltered.(options.sortingVar)>options.maxSortingVar;
            trackingTableFiltered = trackingTableFiltered(~maxIdx,:);
        end

        % add NaN rows for missing grouping var
        groupingVarTmp = trackingTableFiltered.(options.groupingVar);
        nGroups = groupingVarTmp(end);
        completeGroupingVarSet = 1:nGroups;
        missingIdx = setdiff(completeGroupingVarSet,groupingVarTmp);
        % if missing idx, add NaN rows
        if ~isempty(missingIdx)
            disp('adding missing data')
            tableNames = fieldnames(trackingTableFiltered);
            tableNames = setdiff(tableNames,{'Properties','Row','Variables',options.groupingVar});
            tmpTable.(options.groupingVar) = missingIdx';
            nMissing = length(missingIdx);
            % setfield(tmpTable,{1,1},tableNames,{1:nMissing},nan)
            % for each field name, add NaNs
            for i=1:length(tableNames)
                % trackingTableFiltered.(tableNames{i})(1)
                % determine whether the cell array contains strings
                if iscellstr(trackingTableFiltered.(tableNames{i}))
                    disp('adding characters')
                    repeatSize = [nMissing 1];
                    tmpTable.(tableNames{i}) = repmat({NAME},repeatSize);
                else
                    disp('adding numbers')
                    tmpTable.(tableNames{i}) = nan([1 nMissing])';
                end
                % tmpTable.(tableNames{i})(1)
            end
            % add NaNs to output table
            trackingTableFiltered = [trackingTableFiltered;struct2table(tmpTable)];
            [trackingTableFiltered,index] = sortrows(trackingTableFiltered,options.sortRows,options.sortRowsDirection);
        end

        xdiff = [0; diff(trackingTableFiltered.XM)];
        ydiff = [0; diff(trackingTableFiltered.YM)];
        trackingTableFiltered.velocity = sqrt(xdiff.^2 + ydiff.^2);
        tableNames = fieldnames(trackingTableFiltered);
        if sum(strcmp('XM_cm',tableNames))
            xdiff = [0; diff(trackingTableFiltered.XM_cm)];
            ydiff = [0; diff(trackingTableFiltered.YM_cm)];
            trackingTableFiltered.velocity_cm = sqrt(xdiff.^2 + ydiff.^2);
        end

        if sum(strcmp('XM_cm',tableNames))
            velocityFilterIdx = trackingTableFiltered.velocity_cm*options.framesPerSecond>=options.velocityCutoffCm;
        else
            velocityFilterIdx = trackingTableFiltered.velocity>=options.velocityCutoff;
        end
        velocityFilterIdx = find(velocityFilterIdx);
        velocityFilterIdx = [find(isnan(trackingTableFiltered.velocity(:)))' velocityFilterIdx(:)'];
        % trackingTableFiltered = trackingTableFiltered(velocityFilterIdx,:);
        % velocity = velocity(velocityFilterIdx);
        if ~isempty(velocityFilterIdx)
            disp('removing incorrect velocity rows')
            tableNames = fieldnames(trackingTableFiltered);
            tableNames = setdiff(tableNames,{'Properties','Row','Variables',options.groupingVar});
            tmpTable.(options.groupingVar) = velocityFilterIdx(:);
            nMissing = length(velocityFilterIdx);
            % setfield(tmpTable,{1,1},tableNames,{1:nMissing},nan)
            % for each field name, add NaNs
            nanVector = nan([1 nMissing]);
            % for i=1:length(tableNames)
            %     tmpTable.(tableNames{i}) = nanVector(:);
            % end
            for i=1:length(tableNames)
                % trackingTableFiltered.(tableNames{i})(1)
                % class(trackingTableFiltered.(tableNames{i})(1))
                % trackingTableFiltered.(tableNames{i})(1)
                if iscell(trackingTableFiltered.(tableNames{i})(1))
                    repeatSize = [nMissing 1];
                    tmpTable.(tableNames{i}) = repmat({NAME},repeatSize);
                else
                    tmpTable.(tableNames{i}) = nan([1 nMissing])';
                end
                % tmpTable.(tableNames{i})(1)
            end
            % tmpTable
            % struct2table(tmpTable)
            % trackingTableFiltered(1:2,:)
            % add NaNs to output table

            if sum(strcmp('XM_cm',tableNames))
                trackingTableFiltered = trackingTableFiltered(trackingTableFiltered.velocity_cm*options.framesPerSecond<options.velocityCutoffCm,:);
            else
                trackingTableFiltered = trackingTableFiltered(trackingTableFiltered.velocity<options.velocityCutoff,:);
            end

            trackingTableFiltered = [trackingTableFiltered;struct2table(tmpTable)];
            [trackingTableFiltered,index] = sortrows(trackingTableFiltered,options.sortRows,options.sortRowsDirection);
        end

        nFrames = size(trackingTableFiltered,1);
        binSizeFrames = 6000;
        binGroupVector = [];
        repeatSize = [binSizeFrames 1];
        for binGroup = 1:ceil(nFrames/binSizeFrames)
            % size(repmat(binGroup,repeatSize))
            binGroupVector(end+1:end+binSizeFrames) = repmat(binGroup,repeatSize);
        end
        % size(binGroupVector(1:nFrames));
        trackingTableFiltered.binGroup = binGroupVector(1:nFrames)';
    end
    %% functionname: function description
    function subfxn_plotAnimalTracks()
        % plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm,'LineWidth',0.1)
        % gplotmatrix(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm,trackingTableFiltered.file);
        if ~isempty(options.inputMovie)
            if strcmp(class(options.inputMovie{pathNo}),'char')|strcmp(class(options.inputMovie{pathNo}),'cell')
                options.inputMovie{pathNo} = loadMovieList(options.inputMovie{pathNo},'convertToDouble',0,'frameList',50:51,'inputDatasetName',options.inputDatasetName);
            end
            imagesc(squeeze(options.inputMovie{pathNo}(:,:,1)))
            hold on
        end
        if options.groupFilesInFolder==1&options.colorPlotOverride==0
            gscatter(trackingTableFiltered.XM_cm-nanmin(trackingTableFiltered.XM_cm),trackingTableFiltered.YM_cm-nanmin(trackingTableFiltered.YM_cm),trackingTableFiltered.file,[],[],[],'off')
            xlabel('cm'); ylabel('cm')
            % axis tight
            hold off
        else
            viewColorLinePlot(trackingTableFiltered.XM,trackingTableFiltered.YM,'nPoints',200,'colors',customColormap({[0 0 0],[0 1 0],[1 0 0]},'nPoints',200));
            % axis tight
            xlabel('px'); ylabel('px')
            hold on
            plot(trackingTableFiltered.XM(10),trackingTableFiltered.YM(10),'.r','MarkerSize', 30);
            % axis tight;
        end
        axis equal tight;
        hold off
    end
end

function [Area,XM,YM,Major,Minor,Angle] = keepMaxArea(Area,XM,YM,Major,Minor,Angle)
    idx = find(max(Area)==Area);
    Area = Area(idx);
    XM = XM(idx);
    YM = YM(idx);
    Major = Major(idx);
    Minor = Minor(idx);
    Angle = Angle(idx);
end