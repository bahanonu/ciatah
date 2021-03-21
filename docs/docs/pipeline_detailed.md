# Detailed {{ site.name }} processing pipeline

The following detailed pipeline assumes you have started a {{ site.name }} object using the below command:

```Matlab
obj = ciatah;
```

## Spatially downsample raw movies or convert to HDF5 with `modelDownsampleRawMovies`

Users have the ability to spatially downsample raw movies, often necessary to denoise the data, save storage space, and improve runtimes of later processing steps. For most data, users can downsample 2 or 4 times in each spatial dimension while still retaining sufficient pixels per cell to facilitate cell-extraction.

To run, either select `modelDownsampleRawMovies` in the GUI menu or type the below command after initializing a {{ site.name }} obj.

```Matlab
obj.modelDownsampleRawMovies;
```

This will pop-up the following screen. Users can
- input several folders where ISXD files are by separating each folder path with a comma (`Folder(s) where raw HDF5s are located`),
- specify a common root folder to save files to (`Folder to save downsampled HDF5s to:`),
- and input a root directory that contains the sub-folders with the raw data (`Decompression source root folder(s)`).
The function will automatically put each file in its corresponding folder, __make sure folder names are unique__ (this should be done anyways for data analysis reasons).

![image](https://user-images.githubusercontent.com/5241605/67715130-71b2fc00-f986-11e9-970e-9d1252c25db8.png)


### Converting Inscopix ISXD files to HDF5

To convert from Inscopix ISXD file format (output by nVista v3+ and nVoke) to HDF5 run `modelDownsampleRawMovies` without changing the regular expression or make sure it looks for `.*.isxd` or similar. Users will need the latest version of the [Inscopix Data Processing Software](https://www.inscopix.com/nVista#Data_Analysis) as these functions take advantage of their API. If {{ site.name }} cannot automatically find the API, it will ask the user to direct it to the _root_ location of the Inscopix Data Processing Software (see below).

![image](https://user-images.githubusercontent.com/5241605/67715327-df5f2800-f986-11e9-9f91-eeabe7688fed.png)

## Check movie registration before pre-processing with `viewMovieRegistrationTest`

Users should spatially filter one-photon or other data with background noise (e.g. neuropil). To get a feel for how the different spatial filtering affects SNR/movie data before running the full processing pipeline, run `viewMovieRegistrationTest` module. Then select either `matlab divide by lowpass before registering` or `matlab bandpass before registering` then change `filterBeforeRegFreqLow` and `filterBeforeRegFreqHigh` settings, see below.

Within each folder will be a sub-folder called `preprocRunTest` inside of which is a series of sub-folders called `preprocRun##` that will contain a file called `settings.mat` that can be loaded into `modelPreprocessMovie` so the same settings that worked during the test can be used during the actual pre-processing run.

![image](https://user-images.githubusercontent.com/5241605/52497447-f3f65880-2b8a-11e9-8875-c6b408e5c011.png)

- You'll get an output like the below:
  - __A__: The top left is without any filtering while the other 3 are with different bandpass filtering options.
  - __B__: Cell ΔF/F intensity profile from the raw movie. Obtain by selecting `Analyze->Plot profile` from Fiji menu after selecting a square segment running through a cell.
  - __C__: Same cell ΔF/F intensity profile from the bottom/left movie (note the y-axis is the same as above). Obtained in same manner as __B__.

![image](https://user-images.githubusercontent.com/5241605/59561146-695ab580-8fd1-11e9-892b-ce1f5fc7800e.png)

## Preprocessing calcium imaging movies with `modelPreprocessMovie`

After users instantiate an object of the `{{ site.name }}` class and enter a folder, they can start preprocessing of their calcium imaging data with `modelPreprocessMovie`.

- See below for a series of windows to get started, the options for motion correction, cropping unneeded regions, Δ_F/F_, and temporal downsampling were selected for use in the study associated with this repository.
- If users have not specified the path to Miji, a window appears asking them to select the path to Miji's `scripts` folder.
- If users are using the test dataset, it is recommended that they do not use temporal downsampling.
- Vertical and horizontal stripes in movies (e.g. CMOS camera artifacts) can be removed via `stripeRemoval` step. Remember to select correct `stripOrientationRemove`,`stripSize`, and `stripfreqLowExclude` options in the preprocessing options menu.

![image](https://user-images.githubusercontent.com/5241605/49827992-93d86700-fd3f-11e8-9936-d7143bbec3db.png)

Next the user is presented with a series of options for motion correction, image registration, and cropping.:

- The options highlighted in green are those that should be considered by users.
- Users can over their mouse over each option to get tips on what they mean.
- In particular, make sure that `inputDatasetName` is correct for HDF5 files and that `fileFilterRegexp` matches the form of the calcium imaging movie files to be analyzed.
- After this, the user is asked to let the algorithm know how many frames of the movie to analyze (defaults to all frames).
- Then the user is asked to select a region to use for motion correction. In general, it is best to select areas with high contrast and static markers such as blood vessels. Stay away from the edge of the movie or areas outside the brain (e.g. the edge of microendoscope GRIN lens in one-photon miniature microscope movies).

![image](https://user-images.githubusercontent.com/5241605/49828665-4ceb7100-fd41-11e8-9da6-9f5a510f1c13.png)

### Save/load preprocessing settings

Users can also enable saving and loading of previously selected pre-processing settings by changing the red option below.

![image](https://user-images.githubusercontent.com/5241605/70419318-10b52400-1a1a-11ea-9b43-782ac6624042.png)

Settings loaded from previous run (e.g. of `modelPreprocessMovie`) or file (e.g. from `viewMovieRegistrationTest` runs) are highlighted in orange. Settings that user has just changed are still highlighted in green.

![image](https://user-images.githubusercontent.com/5241605/70418766-e6169b80-1a18-11ea-9713-f5a8301fe1c1.png)

The algorithm will then run all the requested preprocessing steps and presented the user with the option of viewing a slice of the processed file. Users have now completed pre-processing.

![image](https://user-images.githubusercontent.com/5241605/49829599-b53b5200-fd43-11e8-82eb-1e94fd7950e7.png)

<!-- ****************************************** -->

## Manual movie cropping with `modelModifyMovies`

If users need to eliminate specific regions of their movie before running cell extraction, that option is provided. Users select a region using an ImageJ interface and select `done` when they want to move onto the next movie or start the cropping. Movies have `NaNs` or `0s` added in the cropped region rather than changing the dimensions of the movie.

![image](https://user-images.githubusercontent.com/5241605/49829899-8f627d00-fd44-11e8-96fb-2e909b4f0d78.png)

<!-- ****************************************** -->

## Extracting cells with `modelExtractSignalsFromMovie`

Users can run PCA-ICA, CNMF, CNMF-E, and ROI cell extraction by following the below set of option screens. Details on running the new Schnitzer lab cell-extraction methods will be added here after they are released.

We normally estimate the number of PCs and ICs on the high end, manually sort to get an estimate of the number of cells, then run PCA-ICA again with IC 1.5-3x the number of cells and PCs 1-1.5x number of ICs.

To run CNMF or CNMF-E, run `loadDependencies` module (e.g. `obj.loadDependencies`) after {{ site.name }} class is loaded. CVX (a CNMF dependency) will also be downloaded and `cvx_setup` run to automatically set it up.

![image](https://user-images.githubusercontent.com/5241605/49830421-fa608380-fd45-11e8-8d9a-47a3d2921111.png)

The resulting output (on _Figure 45+_) at the end should look something like:

![image](https://user-images.githubusercontent.com/5241605/67053021-fe42fc00-f0f4-11e9-980c-88f463cb5043.png)

<!-- ![image](https://user-images.githubusercontent.com/5241605/51728907-c2c44700-2026-11e9-9614-1a57c3a60f5f.png) -->

<!-- ****************************************** -->

## Loading cell-extraction output data for custom scripts

Users can load outputs from cell extraction using the below command. This will then allow users to use the images and activity traces for downstream analysis as needed.

```Matlab
[inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = ciapkg.io.loadSignalExtraction('pathToFile');
```

Note, the outputs correspond to the below:

- `inputImages` - 3D or 4D matrix containing cells and their spatial information, format: [x y nCells].
- `inputSignals` - 2D matrix containing activity traces in [nCells nFrames] format.
- `infoStruct` - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
- `algorithmStr` - String of the algorithm name.
- `inputSignals2` - same as inputSignals but for secondary traces an algorithm outputs.

<!-- ****************************************** -->

## Loading cell-extraction output data with `modelVarsFromFiles`

In general, after running cell-extraction (`modelExtractSignalsFromMovie`) on a dataset, run the `modelVarsFromFiles` module. This allows `{{ site.name }}` to load/pre-load information about that cell-extraction run.

If you had to restart MATLAB or are just loading {{ site.name }} fresh but have previously run cell extraction, run this method before doing anything else with that cell-extraction data.

A menu will pop-up like below when `modelVarsFromFiles` is loaded, you can normally just leave the defaults as is.

![image](https://user-images.githubusercontent.com/5241605/67052600-7f00f880-f0f3-11e9-9555-96fe32b4de6d.png)


<!-- ****************************************** -->

## Validating cell extraction with `viewCellExtractionOnMovie`

After users have run cell extraction, they should check that cells are not being missed during the process. Running the method `viewCellExtractionOnMovie` will create a movie with outlines of cell extraction outputs overlaid on the movie.

Below is an example, with black outlines indicating location of cell extraction outputs. If users see active cells (red flashes) that are not outlined, that indicates either exclusion or other parameters should be altered in the previous `modelExtractSignalsFromMovie` cell extraction step.

![2014_04_01_p203_m19_check01_raw_viewCellExtractionOnMovie_ezgif-4-57913bcfdf3f_2](https://user-images.githubusercontent.com/5241605/59560798-50033a80-8fcc-11e9-8228-f9a3d83ca591.gif)

<!-- ****************************************** -->

## Sorting cell extraction outputs with `computeManualSortSignals`

<p align="center">
  <strong>{{ site.name }} cell sorting GUI</strong>
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif">
    <img src="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="75%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>


Outputs from most common cell-extraction algorithms like PCA-ICA, CNMF, etc. contain signal sources that are not cells and thus must be manually removed from the output. The repository contains a GUI for sorting cells from not cells. GUI also contains a shortcut menu that users can access by right-clicking or selecting the top-left menu.

Below users can see a list of options that are given before running the code, those highlighted in green

![image](https://user-images.githubusercontent.com/5241605/49845107-43322f80-fd7a-11e8-96b9-3f870d4b9009.png)

### GUI usage on large imaging datasets

- To manually sort on large movies that will not fit into RAM, select the below options (highlighted in green). This will load only chunks of the movie asynchronously into the GUI as you sort cell extraction outputs.
![image](https://user-images.githubusercontent.com/5241605/59215159-5d07d000-8b6d-11e9-8dd7-0d69d5fd38b6.png)

### Cell sorting from the command line with `signalSorter`

Usage instructions below for `signalSorter`, e.g. if not using the `{{ site.name }}` GUI.

__Main inputs__

- `inputImages` - [x y N] matrix where N = number of images, x/y are dimensions.
- `inputSignals` - [N frames] _double_ matrix where N = number of signals (traces).
- `inputMovie` - [x y frames] matrix

__Main outputs__

- `choices` - [N 1] vector of 1 = cell, 0 = not a cell
- `inputImagesSorted` - [x y N] filtered by `choices`
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

Examples of the interface on two different datasets:

#### BLA one-photon imaging data signal sorting GUI

![out-1](https://user-images.githubusercontent.com/5241605/34796712-3868cb3a-f60b-11e7-830e-8eec5b2c76d7.gif)

#### mPFC one-photon imaging data signal sorting GUI (from `example_downloadTestData.m`)

![image](https://user-images.githubusercontent.com/5241605/46322488-04c00d80-c59e-11e8-9e8a-18b3b8e4567d.png)

#### Context menu

<a href="https://user-images.githubusercontent.com/5241605/95838435-9ec30080-0cf6-11eb-981d-fc8b5d46de7b.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/95838435-9ec30080-0cf6-11eb-981d-fc8b5d46de7b.png" alt="drawing" width="900" height="auto" /></a>

<!-- ****************************************** -->

## Removing cells not within brain region with `modelModifyRegionAnalysis`

If the imaging field-of-view includes cells from other brain regions, they can be removed using `modelModifyRegionAnalysis`

![image](https://user-images.githubusercontent.com/5241605/49834696-e9b60a80-fd51-11e8-90bb-9854b7ccaeb8.png)

<!-- ****************************************** -->

## Cross-session cell alignment with `computeMatchObjBtwnTrials`

This step allows users to align cells across imaging sessions (e.g. those taken on different days). See the `Cross session cell alignment` wiki page for more details and notes on cross-session alignment.

- Users run `computeMatchObjBtwnTrials` to do cross-day alignment (first row in pictures below).
- Users then run `viewMatchObjBtwnSessions` to get a sense for how well the alignment ran.
- `computeCellDistances` and `computeCrossDayDistancesAlignment` allow users to compute the within session pairwise Euclidean centroid distance for all cells and the cross-session pairwise distance for all global matched cells, respectively.

![image](https://user-images.githubusercontent.com/5241605/49835713-eec88900-fd54-11e8-8d24-f7c426802297.png)

Users can then get the matrix that gives the session IDs

```Matlab
% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

```

### View cross-session cell alignment with `viewMatchObjBtwnSessions`

To evaluate how well cross-session alignment works, `computeMatchObjBtwnTrials` will automatically run `viewMatchObjBtwnSessions` at the end, but users can also run it separately after alignment. The left are raw dorsal striatum cell maps from a single animal. The right shows after cross-session alignment; color is used to indicate a global ID cell (e.g. the same cell matched across multiple days). Thus, same color cell = same cell across sessions.

<a href="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" alt="2017_05_02_p545_m121_p215_raw" width="auto" height="400"/></a>
<a href="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" alt="2017_05_02_p545_m121_p215_corrected_biafraalgorithm2" width="auto" height="400"/></a>

### Save cross-session cell alignment with `modelSaveMatchObjBtwnTrials`

Users can save out the alignment structure by running `modelSaveMatchObjBtwnTrials`. This will allow users to select a folder where `{{ site.name }}` will save a MAT-file with the alignment structure information for each animal.