
# calciumImagingAnalysis

Code and MATLAB class for analyzing one- and two-photon calcium imaging datasets. Includes code for determining animal locations (e.g. in open-field assay).

Contact Biafra Ahanonu (bahanonu [at] alum.mit.edu) for questions about code or usage.

Note:
- Covers preprocessing of calcium imaging videos, cell and activity trace extraction (with PCA-ICA), manual sorting of cell extraction outputs, cross-session alignment of cells, and more.
- This repository is code used in "An amygdalar neural ensemble encoding the unpleasantness of pain" and similar code was used to process data in `Parker, J. G., Marshall, J. D., Ahanonu, B., Wu, Y. W., Kim, T. H., Grewe, B. F., ... & Schnitzer, M. J. (2018). Diametric neural ensemble dynamics in parkinsonian and dyskinetic states. Nature, 557(7704), 177.`
- Code developed while in Prof. Mark Schnitzer's lab at Stanford University.

***
## Contents
- [Installation](#installation)
- [Data](#data)
- [Processing calcium imaging data](#processing-calcium-imaging-data)
- [Preprocessing calcium imaging movies with  `modelPreprocessMovie`](#preprocessing-calcium-imaging-movies-with-modelpreprocessmovie)
- [Manual movie cropping with  `modelModifyMovies`](#manual-movie-cropping-with-modelmodifymovies)
- [Extracting cells with  `modelExtractSignalsFromMovie`](#extracting-cells-with-modelextractsignalsfrommovie)
- [Sorting cell extraction outputs with `computeManualSortSignals`](#sorting-cell-extraction-outputs-with-computemanualsortsignals)
- [Removing cells not within brain region with  `modelModifyRegionAnalysis`](#removing-cells-not-within-brain-region-with-modelmodifyregionanalysis)
- [Cross-session cell alignment with  `computeMatchObjBtwnTrials`](#cross-session-cell-alignment-with-computematchobjbtwntrials)
- [ImageJ+MATLAB based mouse location tracking](#imagejmatlab-based-mouse-location-tracking)

***

## Installation

Download zip or clone the `calciumImagingAnalysis` repository.
- Place in folder where MATLAB will have write permissions, as it also creates a `private` subdirectory to store some user information.
- Unzip `file_exchange.zip`. This contains File Exchange functions used by `calciumImagingAnalysis`.
- In general, it is best to set the MATLAB startup directory to the `calciumImagingAnalysis` folder. This allows `java.opts` and `startup.m` to set the correct Java memory requirements and load the correct folders into the MATLAB path.

This `calciumImagingAnalysis` has been tested on Windows `MATLAB 2017a`.

### Test data

Run `example_downloadTestData.m` to download example one-photon miniature microscope test data to use for testing `calciumImagingAnalysis` preprocessing, cell extraction, and cell classification code.

### Dependencies

MATLAB dependencies (toolboxes used)

- distrib_computing_toolbox
- image_toolbox
- signal_toolbox
- statistics_toolbox
- video_and_image_blockset

ImageJ

- Download Fiji: https://fiji.sc/.
- Make sure have Miji in Fiji installation: http://bigwww.epfl.ch/sage/soft/mij/.

Saleae

- Download 1.2.26: https://support.saleae.com/logic-software/legacy-software/older-software-releases#1-2-26-download.

******************************************

## Data

The class generally operates on the principal that a single imaging session is contained within a single folder or directory. Thus, even if a single imaging session contains multiple trials (e.g. the imaging data is split across multiple movies) this is fine as the class will concatenate them during the preprocessing step.

The naming convention in general is below. Both TIF and AVI raw files are converted to HDF5 after processing since that format offers more flexibility during cell extraction and other steps.

### Input and output files
- Raw: `concat_.*.(h5|tif)`
- Processed: `folderName_(processing steps).h5`, where `folderName` is the directory name where the calcium imaging movies are located.
- HDF5
- Main files output by `calciumImagingAnalysis`. Below, `.*` normally indicates the folder name prefixed to the filename.
- `.*_pcaicaAnalysis.mat`: Where PCA-ICA outputs are stored.
- `.*_ICdecisions_.*.mat`: Where decisions for cell (=1) and not cell (=0) are stored in a `valid` variable.
- `.*_regionModSelectUser.mat`: A mask of the region (=1) to include in further analyses.
- `.*_turboreg_crop_dfof_1.h5`: Processed movie, in this case motion corrected, cropped, and Δ_F/F_.
- `processing_info`: a folder containing preprocessing information.

### Preferred folder naming format

Folders should following the format `YYYY_MM_DD_pXXX_mXXX_assayXX_trialXX` where:
-   `YYYY_MM_DD` = normal year/month/day scheme.
-   `pXXX` = protocol number, e.g. p162, for the set of experiments performed for the same set of animals.
-   `mXXX` = subject ID/number, e.g. m805 or animal ID.
-   `assayXX` = assay ID and session number, e.g. vonfrey01 is the 1st von Frey assay session.
-   `trialXX` = the trial number of the current assay session, only applicable if multiple trials in the same assay session.

### Videos
- HDF5: `[x y t]` matrix
	 - x and y being height/width of video, t = number of frames
	 - `/1` as the name for directory containing movie data
	 - HDF can be read in using Fiji, see http://lmb.informatik.uni-freiburg.de/resources/opensource/imagej_plugins/hdf5.html
	 - 	Each HDF5 file should contain imaging data in a dataset name, e.g. `/1` is the default datasetname for `[x y frames]` 2D calcium imaging movies in this repository.
	- Most functions have a `inputDatasetName` option to specify the dataset name.
 - TIF
	- Normal `[x y frames]` tif.
- AVI
	- Raw uncompressed grayscale `[x y frames]` avi.

### Cell images
- PC/IC filters: [x y n] matrix
 - x and y being height/width of video and n = number of PCs/ICs output

### Cell traces
- PC/IC traces: [n f] matrix
 - n = number of PCs/ICs output and f = frames (of the movie)




******************************************

## Processing calcium imaging data

The general pipeline for processing calcium imaging data is below. This repository includes code to do nearly every step.

![image](https://user-images.githubusercontent.com/5241605/49833336-03ede980-fd4e-11e8-8022-9aa3dedfd5ab.png)


To start using the `calciumImagingAnalysis` class, enter the following into the MATLAB command window.

```Matlab
% Load the class into an object
obj = calciumImagingAnalysis;

% Open the class menu
obj % then hit enter, no semicolon!
% Alternatively
obj.runPipeline % then hit enter, no semicolon!
```

The general order of functions that users should run is:

- `modelDownsampleRawMovies`
	- If users have raw calcium imaging data that needs to be spatially downsampled, e.g. raw data from Inscopix nVista software.
- `modelAddNewFolders`
	- Users should always use this method first, used to add folders to the current class object.
	- For example, if users ran `example_downloadTestData.m`, then add the folder `[githubRepoPath]\data\2014_04_01_p203_m19_check01_raw` where `githubRepoPath` is the absolute path to the current `calciumImagingAnalysis` repository.
- `viewMovie`
	- Users should check that calciumImagingAnalysis loads their movies correctly and that Miji is working.
- `modelPreprocessMovie`
	- Main processing method for calciumImagingAnalysis. Performs motion correction, spatial filtering, cropping, down-sampling, and relative fluorescence calculations. If using Inscopix nVista 1.0 or 2.0, also will correct for dropped frames.
- `modelModifyMovies`
	- GUI that allows users to remove movie regions not relevant to cell extraction.
- `modelExtractSignalsFromMovie`
	- Performs cell extraction, currently PCA-ICA with the ability to run more recent algorithms (e.g. CNMF) upon request.
- `modelVarsFromFiles`
	- Run after `modelExtractSignalsFromMovie` to load cell image and trace information into the current class object.
- `computeManualSortSignals`
	- A GUI to allow users to classify cells and not cells in cell extraction outputs.
- `modelModifyRegionAnalysis`
	- Users are able to select specific cells from cell extraction manual sorting to include in further analyses.
- `computeMatchObjBtwnTrials`
	- Method to register cells across imaging sessions. Also includes visual check GUI in `viewMatchObjBtwnSessions` method.

******************************************

## Preprocessing calcium imaging movies with `modelPreprocessMovie`

After users instantiate an object of the `calciumImagingAnalysis` class and enter a folder, they can start preprocessing of their calcium imaging data with `modelPreprocessMovie`.

- See below for a series of windows to get started, the options for motion correction, cropping unneeded regions, Δ_F/F_, and temporal downsampling were selected for use in the study associated with this repository.
- If users have not specified the path to Miji, a window appears asking them to select the path to Miji's `scripts` folder.
- If users are using the test dataset, it is recommended that they do not use temporal downsampling.


![image](https://user-images.githubusercontent.com/5241605/49827992-93d86700-fd3f-11e8-9936-d7143bbec3db.png)

Next the user is presented with a series of options for motion correction, image registration, and cropping.:

- The options highlighted in green are those that should be considered by users.
- In particular, make sure that `inputDatasetName` is correct for HDF5 files and that `fileFilterRegexp` matches the form of the calcium imaging movie files to be analyzed.
- After this, the user is asked to let the algorithm know how many frames of the movie to analyze (defaults to all frames).
- Then the user is asked to select a region to use for motion correction. In general, it is best to select areas with high contrast and static markers such as blood vessels. Stay away from the edge of the movie or areas outside the brain (e.g. the edge of microendoscope GRIN lens in one-photon miniature microscope movies).

![image](https://user-images.githubusercontent.com/5241605/49828665-4ceb7100-fd41-11e8-9da6-9f5a510f1c13.png)

The algorithm will then run all the requested preprocessing steps and presented the user with the option of viewing a slice of the processed file. Users have now completed pre-processing.

![image](https://user-images.githubusercontent.com/5241605/49829599-b53b5200-fd43-11e8-82eb-1e94fd7950e7.png)

******************************************

## Manual movie cropping with `modelModifyMovies`

If users need to eliminate specific regions of their movie before running cell extraction, that option is provided.

![image](https://user-images.githubusercontent.com/5241605/49829899-8f627d00-fd44-11e8-96fb-2e909b4f0d78.png)

******************************************

## Extracting cells with `modelExtractSignalsFromMovie`

Users can run PCA-ICA by following the below set of option screens. We normally estimate the number of PCs and ICs on the high end, manually sort to get an estimate of the number of cells, then run PCA-ICA again with IC 1.5-3x the number of cells and PCs 1-1.5x number of ICs.

![image](https://user-images.githubusercontent.com/5241605/49830421-fa608380-fd45-11e8-8d9a-47a3d2921111.png)

The resulting output at the end should look something like:

![image](https://user-images.githubusercontent.com/5241605/49832877-c0df4680-fd4c-11e8-9d22-e5d2dff3409f.png)

******************************************

## Sorting cell extraction outputs with `computeManualSortSignals`
Outputs from PCA-ICA (and most other common cell extraction algorithms like CNMF, etc.) output signal sources that are not cells and thus must be manually removed from the output. The repository contains a GUI for sorting cells from not cells. Below users can see a list of options that are given before running the code, those highlighted in green

![image](https://user-images.githubusercontent.com/5241605/49845107-43322f80-fd7a-11e8-96b9-3f870d4b9009.png)

### Usage

Below are two examples of the interface and code to run.

Usage instructions below for `signalSorter.m`:

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

#### BLA one-photon imaging data signal sorting GUI

![out-1](https://user-images.githubusercontent.com/5241605/34796712-3868cb3a-f60b-11e7-830e-8eec5b2c76d7.gif)

#### mPFC one-photon imaging data signal sorting GUI (from `example_downloadTestData.m`)

![image](https://user-images.githubusercontent.com/5241605/46322488-04c00d80-c59e-11e8-9e8a-18b3b8e4567d.png)

******************************************

## Removing cells not within brain region with `modelModifyRegionAnalysis`

If the imaging field-of-view includes cells from other brain regions, they can be removed using `modelModifyRegionAnalysis`

![image](https://user-images.githubusercontent.com/5241605/49834696-e9b60a80-fd51-11e8-90bb-9854b7ccaeb8.png)

******************************************

## Cross-session cell alignment with `computeMatchObjBtwnTrials`

- Users run `computeMatchObjBtwnTrials` to do cross-day alignment (first row in pictures below).
- Users then run `viewMatchObjBtwnSessions` to get a sense for how well the alignment ran.
- `computeCellDistances` and `computeCrossDayDistancesAlignment` allow users to compute the within session pairwise Euclidean centroid distance for all cells and the cross-session pairwise distance for all global matched cells, respectively.

![image](https://user-images.githubusercontent.com/5241605/49835713-eec88900-fd54-11e8-8d24-f7c426802297.png)

# ImageJ+MATLAB based mouse location tracking

Functions needed (have entire `calciumImagingAnalysis` loaded anyways):
- `mm_tracking.ijm` is the tracking function for use in ImageJ, place in
`plugins` folder.
- `removeIncorrectObjs.m` is a function to clean-up the ImageJ output.
- `createTrackingOverlayVideo` is a way to check the output from the
tracking by overlaying mouse tracker onto the video.

## Instructions for ImageJ and Matlab
Example screen after running `mm_tracking` within ImageJ, click to expand.
<a href="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" target="_blank">![image](https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png)</a>

Once ImageJ is finished, within Matlab run the following code (cleans up the ImageJ tracking by removing small objects and adding NaNs for missing frames along with making a movie to check output). Modify to point toward paths specific for your data.

```Matlab
% CSV file from imageJ and AVI movie path used in ImageJ
moviePath = 'PATH_TO_AVI_USED_IN_IMAEJ';
csvPath = 'PATH_TO_CSV_OUTPUT_BY_IMAGEJ';
% clean up tracking
[trackingTableFilteredCell] = removeIncorrectObjs(csvPath,'inputMovie',{moviePath});
% make tracking video
% frames to use as example check
nFrames=1500:2500;
inputMovie = loadMovieList(moviePath,'frameList',nFrames);
[inputTrackingVideo] = createTrackingOverlayVideo(inputMovie,movmean(trackingTableFilteredCell.XM(nFrames),5),movmean(trackingTableFilteredCell.YM(nFrames),5));
playMovie(inputTrackingVideo);
```

### Example output from 2017_09_11_p540_m381_openfield01_091112017
![image](https://user-images.githubusercontent.com/5241605/34800547-2a10a3b0-f619-11e7-9c88-88750c9875cd.png)

Using `createTrackingOverlayVideo` to verify tracking matches animal position on a per frame basis.
![image](https://user-images.githubusercontent.com/5241605/34800536-19eefcf2-f619-11e7-954f-dba59f4fd427.png)