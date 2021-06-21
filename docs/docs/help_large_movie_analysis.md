# Analyzing large movies

Some movies are larger than the available RAM on users analysis computer. Below are several ways that the underlying functions in `CIAPKG` can be used to analyze large movies.

## Playing large movies from disk

To directly and quickly visualize large or long movies from disk, directly input the movie path into `playMovie` as below.

```Matlab
% Full path to the movie
inputMoviePath = 'path/to/movie.h5';

playMovie(inputMoviePath);
```

Which will produce a GUI as below that will play the movie back.

![image](https://user-images.githubusercontent.com/5241605/97789968-fdef9480-1b81-11eb-938c-863fa5159fb5.png)

## ROI signal extraction
The below code is an example ROI signal extraction for large movie in chunks from disk after analyzing a small chunk with PCA-ICA to obtain reference masks. Modify `inputMoviePath` to a full path to your movie (HDF5, TIF, AVI, and ISXD supported).

```MATLAB
% Full path to the movie
inputMoviePath = 'path/to/movie.h5';

%% =======PCA-ICA
% Run PCA-ICA on only a subset of frames.
% OPTIONS
    % Vector of frames to analyze for PCA-ICA
    framesToAnalyzePcaIca = 1:300;
    % Number of PCs and ICs to request
    nPCs = 250; nICs = 200;
[pcaicaAnalysisOutput] = ciapkg.signal_extraction.runPcaIca(inputMoviePath,nPCs,nICs,'frameList',framesToAnalyzePcaIca,'mu',0.1,'max_iter',1e3);

%% =======ROI extraction new version
% OPTIONS
    % Number of frames to chunk from movie when doing ROI estimation, to reduce RAM usage.
    movieChunks = 100;
% Normal PCA-ICA, binary masks
[roiSignals, ~] = ciapkg.signal_extraction.computeSignalsFromImages(pcaicaAnalysisOutput.IcaFilters,inputMoviePath,'frameList',[],'readMovieChunks',1,'threshold',0.4,'nFramesPerChunk',movieChunks,'weightSignalByImage',0);
% Weighted PCA-ICA, trace based on weighted pixel values of eahc ROI
[roiSignalsWeighted, ~] = ciapkg.signal_extraction.computeSignalsFromImages(pcaicaAnalysisOutput.IcaFilters,inputMoviePath,'frameList',[],'readMovieChunks',1,'threshold',0.4,'nFramesPerChunk',movieChunks,'weightSignalByImage',1);
```