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
    % TODO
        %

    %========================
    options.inputDatasetName = '/1';
    options.dfofType = 'dfof';
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

    stdList = {'slidingZscore','binnedZscore','dfstd'};

    inputMovieClass = class(inputMovie);
    if strcmp(inputMovieClass,'char')
        inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
        % [pathstr,name,ext] = fileparts(inputFilePath);
        % options.newFilename = [pathstr '\concat_' name '.h5'];
    end
    inputMovieClass = class(inputMovie);

    % get the movie F0, do by row to reduce potential memory errors on some versions of Matlab
    display('getting F0...')
    inputMovieF0 = zeros([size(inputMovie,1) size(inputMovie,2)]);
    inputMovieStd = zeros([size(inputMovie,1) size(inputMovie,2)]);
    reverseStr = '';
    nRows = size(inputMovie,1);
    for rowNo=1:nRows
        % inputMovieF0 = nanmean(inputMovie,3);
        rowFrame = single(squeeze(inputMovie(rowNo,:,:)));
        inputMovieF0(rowNo,:) = nanmean(rowFrame,2);
        if sum(strcmp(dfofType,stdList))>0
            inputMovieStd(rowNo,:) = nanstd(rowFrame,[],2);
        else
        end
        reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','calculating mean...','waitbarOn',1,'displayEvery',5);
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
            display('F(t)/F0...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
        case 'dfof'
            display('F(t)/F0 - 1...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
            dfofMatrix = dfofMatrix-1;
        case 'slidingZscore'
            display('sliding (F(t)-F0)/std..')

            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            % dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
            % dfofMatrix = dfofMatrix-1;
        case 'binnedZscore'
            display('sliding (F(t)-F0)/std..')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
            dfofMatrix = dfofMatrix-1;
        case 'dfstd'
            display('(F(t)-F0)/std...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
            dfofMatrix = bsxfun(@ldivide,inputMovieStd,dfofMatrix);
            % dfofMatrix = dfofMatrix-1;
        case 'minus'
            display('F(t)-F0...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
        otherwise
            return;
    end
end