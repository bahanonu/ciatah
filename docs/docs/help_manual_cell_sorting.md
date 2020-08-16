# Manual cell sorting of cell extraction outputs

This page will go over best practices and common issues seen when sorting cells from PCA-ICA. Advice can also apply to other cell sorting algorithms (CNMF, etc.).

As a general note, it is a bad idea to bias users by using heuristics or computational models to pre-select or guess whether a cell extraction output is a cell or non-cell. This will skew results toward whatever the heuristics or model are looking for rather than reveal the true preferences of the user.

## Usage

Usage instructions below for `signalSorter.m`:

__Main inputs__

- `inputImages` - [x y N] matrix where N = number of images, x/y are dimensions.
- `inputSignals` - [N frames] _double_ matrix where N = number of signals (traces).
- `inputMovie` - [x y frames] matrix

__Main outputs__

- `choices` - [N 1] vector of 1 = cell, 0 = not a cell
- `inputImagesSorted` - [x y N] filtered by `choices'
- `inputSignalsSorted` - [N frames] filtered by `choice`


``` Matlab
iopts.inputMovie = inputMovie; % movie associated with traces
iopts.valid = 'neutralStart'; % all choices start out gray or neutral to not bias user
iopts.cropSizeLength = 20; % region, in px, around a signal source for transient cut movies (subplot 2)
iopts.cropSize = 20; % see above
iopts.medianFilterTrace = 0; % whether to subtract a rolling median from trace
iopts.subtractMean = 0; % whether to subtract the trace mean
iopts.movieMin = -0.01; % helps set contrast for subplot 2, preset movie min here or it is calculated
iopts.movieMax = 0.05; % helps set contrast for subplot 2, preset movie max here or it is calculated
iopts.backgroundGood = [208,229,180]/255;
iopts.backgroundBad = [244,166,166]/255;
iopts.backgroundNeutral = repmat(230,[1 3])/255;
[inputImagesSorted, inputSignalsSorted, choices] = signalSorter(inputImages, inputSignals, 'options',iopts);
```

### `signalSorter` use with large or remote server imaging movies

For imaging movies that are too large to fit into RAM or that are stored on remote systems, run the below commands. Remember to change `inputImages`, `inputSignals`, `iopts.inputMovie`, and `iopts.inputDatasetName` to values appropriate for your data). __Note: only HDF5 files are supported with this feature due to use of spatial chunking.__

```Matlab
% CRITICAL USER PARAMETERS
% Input images and signals, change from PCA-ICA to whatever is appropriate for input from user's cell extraction algorithm.
inputImages = pcaicaAnalysisOutput.IcaFilters; % cell array of [x y nSignals] matrices containing each set of images corresponding to inputSignals objects.
inputSignals = pcaicaAnalysisOutput.IcaTraces; % cell array of [nSignals frames] matrices containing each set of inputImages signals.
iopts.inputMovie = ['pathToImagingSessionFolder' filesep 'MOVIE_FILE_NAME.h5'];
iopts.inputDatasetName = '/1'; % HDF5 dataset name

% MAIN USER parameters: change these as needed
iopts.preComputeImageCutMovies = 0; % Binary: 0 recommended. 1 = pre-compute movies aligned to signal transients, 0 = do not pre-compute.
iopts.readMovieChunks = 1; % Binary: 1 recommended. 1 = read movie from HDD, 0 = load entire movie into RAM.
iopts.showImageCorrWithCharInputMovie = 0; % Binary: 0 recommended. 1 = show the image correlation value when input path to options.inputMovie (e.g. when not loading entire movie into RAM).
iopts.maxSignalsToShow = 9; %Int: max movie cut images to show
iopts.nSignalsLoadAsync = 30; % Int: number of signals ahead of current to asynchronously load imageCutMovies, might make the first couple signal selections slow while loading takes place
iopts.threshold = 0.3; % threshold for thresholding images
iopts.thresholdOutline = 0.3; % threshold for thresholding images

% OPTIONAL
iopts.valid = 'neutralStart'; % all choices start out gray or neutral to not bias user
iopts.cropSizeLength = 20; % region, in px, around a signal source for transient cut movies (subplot 2)
iopts.cropSize = 20; % see above
iopts.medianFilterTrace = 0; % whether to subtract a rolling median from trace
iopts.subtractMean = 0; % whether to subtract the trace mean
iopts.movieMin = -0.01; % helps set contrast for subplot 2, preset movie min here or it is calculated
iopts.movieMax = 0.05; % helps set contrast for subplot 2, preset movie max here or it is calculated
iopts.backgroundGood = [208,229,180]/255;
iopts.backgroundBad = [244,166,166]/255;
iopts.backgroundNeutral = repmat(230,[1 3])/255;

[~, ~, choices] = signalSorter(inputImages, inputSignals, 'options',iopts);
```

## Interface
<a href="https://user-images.githubusercontent.com/5241605/47396409-68da7b00-d6df-11e8-8c91-e85c3af356b5.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/47396409-68da7b00-d6df-11e8-8c91-e85c3af356b5.png" alt="drawing" width="900" height="auto" /></a>

__Example good cell extraction output__

<a href="https://user-images.githubusercontent.com/5241605/58501425-3db67f00-8139-11e9-9c16-c7efc8a74144.gif" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/58501425-3db67f00-8139-11e9-9c16-c7efc8a74144.gif" alt="drawing" width="600" height="auto"/></a>

__Example bad cell extraction output__

<a href="https://user-images.githubusercontent.com/5241605/58501420-3c855200-8139-11e9-8d1a-faea051ce2ea.gif" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/58501420-3c855200-8139-11e9-8d1a-faea051ce2ea.gif" alt="drawing" width="600" height="auto"/></a>

<!-- ![2016_01_20_p460_m19_lineartrack01_s_bad_cellmax_517_1_32](https://user-images.githubusercontent.com/5241605/51698178-6a595f00-1fbe-11e9-940f-5dbcb08d4018.gif) -->

__Jump to arbitrary cells__
- Click the cell map window or press `V` and a orange cross hair will appear, this will take the user to the clicked upon cell.
![image](https://user-images.githubusercontent.com/5241605/68536470-1549c800-0308-11ea-84fa-be12deadb329.png)
- Or select the full cellmap, will obtain the same result.
![image](https://user-images.githubusercontent.com/5241605/68536494-9ef99580-0308-11ea-9040-618d6d836440.png)
- This cell can be viewed like normal.
![image](https://user-images.githubusercontent.com/5241605/68536471-21358a00-0308-11ea-804b-b831d236cb4d.png)
- Users can then press `Y` to take them back to the last sorted cell (here #2). This function works even with the `G` go to new signal via index number command.
![image](https://user-images.githubusercontent.com/5241605/68536472-2c88b580-0308-11ea-811d-f40ad5ddf94e.png)

__Press "t" to bring up interface to compare neighboring cells__
![image](https://user-images.githubusercontent.com/5241605/58516068-9d258680-815b-11e9-95b5-683d7f9b3495.png)

- Users can zoom in on the traces to get a better sense of correlation between activity traces.
![image](https://user-images.githubusercontent.com/5241605/58516133-d9f17d80-815b-11e9-8faa-50216cb0f9c2.png)

__Press "r" to bring up different views of trace__
- ROI trace included in instances where the entire movie is already loaded into RAM.
![image](https://user-images.githubusercontent.com/5241605/58517092-0a86e680-815f-11e9-966e-4a505336afb6.png)

![image](https://user-images.githubusercontent.com/5241605/58517156-4cb02800-815f-11e9-80fb-859d55703058.png)

__Press "c" to bring up the whole movie cut to extraction output activity trace events__

![ezgif-4-5a699a41b244_v2](https://user-images.githubusercontent.com/5241605/58517956-3192e780-8162-11e9-8946-f68fb1b25eab.gif)

![image](https://user-images.githubusercontent.com/5241605/58517239-93058700-815f-11e9-9374-4ea0f2252044.png)


## Best practices

* Always sort the cells with the trace, filter, and either images or video cut to transients in the movie.
* This gets around two types of cells: those with irregular firing patterns that might be thrown out (see below) or those whose filter and traces look good, but are either fragments of a high SNR cell (see __Common issues__) or not actually a cell (e.g. a particulate in the field of view that has transient-like movement).
* Sometimes two or more cell extraction outputs are for the same cell. In these suspected cases, press `t` in the `signalSorter` interface to pull up images and activity traces of nearby cells to see which have a higher SNR or better cell shape and should be kept.

## Neighboring cells

* Sometimes two or more cell extraction outputs are for the same cell. In these suspected cases, press `t` in the `signalSorter` interface to pull up images and activity traces of nearby cells to see which have a higher SNR or better cell shape and should be kept.
* See below for an example, in which cell #3 (yellow) is a duplicate of cell #1 (blue).

![image](https://user-images.githubusercontent.com/5241605/52926738-ea3bc600-32eb-11e9-9fa1-e05087f3c05a.png)

## Common issues

* Cells with high SNR will sometimes be split into multiple cell extraction outputs. Refer to algorithm specific to notes on how to get around this problem.

## Examples

- Example of a good cell with GCaMP like rise/decay and for one-photon miniature microscope movies, has nice 2D Gaussian-like shape during transients in the movie.
<img src="https://user-images.githubusercontent.com/5241605/34796712-3868cb3a-f60b-11e7-830e-8eec5b2c76d7.gif" alt="drawing" width="600" height="auto"/>
<img src="https://user-images.githubusercontent.com/5241605/51698177-6a595f00-1fbe-11e9-9992-448881665c25.gif" alt="drawing" width="600" height="auto"/>

<!-- ![2016_01_20_p460_m19_lineartrack01_s_good_cellmax_510_1_32](https://user-images.githubusercontent.com/5241605/51698177-6a595f00-1fbe-11e9-9992-448881665c25.gif) -->
<!-- ![out-1](https://user-images.githubusercontent.com/5241605/34796712-3868cb3a-f60b-11e7-830e-8eec5b2c76d7.gif) -->

- Example of good cells on left and bad on right. Subplots: CELLMax output, mean movie frame centered on the cell and aligned to cell transients, and example CELLMax traces.
<img src="https://user-images.githubusercontent.com/5241605/35294233-e0ec1ca2-002a-11e8-837c-857c93a6c810.png" alt="drawing" width="600" height="auto"/>
<!-- ![image](https://user-images.githubusercontent.com/5241605/35294233-e0ec1ca2-002a-11e8-837c-857c93a6c810.png) -->

- Example of not-cells or borderline not-cells.
<img src="https://user-images.githubusercontent.com/5241605/51698178-6a595f00-1fbe-11e9-940f-5dbcb08d4018.gif" alt="drawing" width="600" height="auto"/>
<img src="https://user-images.githubusercontent.com/5241605/51698179-6a595f00-1fbe-11e9-9d4e-35ba75342cc4.gif" alt="drawing" width="600" height="auto"/>
<!-- ![2016_01_20_p460_m19_lineartrack01_s_bad_cellmax_517_1_32](https://user-images.githubusercontent.com/5241605/51698178-6a595f00-1fbe-11e9-940f-5dbcb08d4018.gif) -->
<!-- ![2016_01_20_p460_m19_lineartrack01_s_bad_cellmax_511](https://user-images.githubusercontent.com/5241605/51698179-6a595f00-1fbe-11e9-9d4e-35ba75342cc4.gif) -->


- Good cells with their matched movies aligned to algorithm (PCA-ICA in this case) detected transients.
<img src="https://cloud.githubusercontent.com/assets/5241605/26423683/67e85184-4083-11e7-88ff-f3bbe3600ffc.png" alt="drawing" width="600"/>
<img src="https://cloud.githubusercontent.com/assets/5241605/26423903/426a38b8-4084-11e7-93d5-f9962ea5b826.gif" alt="drawing" width="300"/>
<img src="https://cloud.githubusercontent.com/assets/5241605/26423927/52804e2c-4084-11e7-8184-f3ae240dedea.png" alt="drawing" width="600" height="auto"/>
<img src="https://cloud.githubusercontent.com/assets/5241605/26423979/7f5348fa-4084-11e7-8c62-a277ecbbd13a.gif" alt="drawing" width="300" height="auto"/>
<!-- ![image](https://cloud.githubusercontent.com/assets/5241605/26423683/67e85184-4083-11e7-88ff-f3bbe3600ffc.png) -->
<!-- ![output3](https://cloud.githubusercontent.com/assets/5241605/26423903/426a38b8-4084-11e7-93d5-f9962ea5b826.gif) -->
<!-- ![image](https://cloud.githubusercontent.com/assets/5241605/26423927/52804e2c-4084-11e7-8184-f3ae240dedea.png) -->
<!-- ![output5](https://cloud.githubusercontent.com/assets/5241605/26423979/7f5348fa-4084-11e7-8c62-a277ecbbd13a.gif) -->

- Additional examples of good cells.
<img src="https://cloud.githubusercontent.com/assets/5241605/10896133/e6c55e7a-816c-11e5-8527-f730ea0f7265.png" alt="drawing" width="600" height="auto"/>
<img src="https://cloud.githubusercontent.com/assets/5241605/11968975/bc4f24dc-a8c7-11e5-8b87-cf39eb52b62b.png" alt="drawing" width="600" height="auto"/>
<!-- ![image](https://cloud.githubusercontent.com/assets/5241605/10896133/e6c55e7a-816c-11e5-8527-f730ea0f7265.png) -->
<!-- ![image](https://cloud.githubusercontent.com/assets/5241605/11968975/bc4f24dc-a8c7-11e5-8b87-cf39eb52b62b.png) -->

- As noted, without the transient aligned movie (see above), cells with unusual traces might be discarded, e.g. all three below are actual cells when the movie is visualized.
<img src="https://cloud.githubusercontent.com/assets/5241605/11164758/4ea1c02a-8aae-11e5-90bf-b6314eebb53a.png" alt="drawing" width="600" height="auto"/>
<!-- ![image](https://cloud.githubusercontent.com/assets/5241605/11164758/4ea1c02a-8aae-11e5-90bf-b6314eebb53a.png) -->