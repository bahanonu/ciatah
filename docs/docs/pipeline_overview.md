# Processing calcium imaging data

The general pipeline for processing calcium imaging data is below. This repository includes code to do nearly every step.

<!-- ![image](https://user-images.githubusercontent.com/5241605/61981834-ab532000-afaf-11e9-97c2-4b1d7d759a30.png) -->
![ciapkg_pipeline.png](img/ciapkg_pipeline.png)

To start using the `{{ site.name }}` software package, enter the following into the MATLAB command window.

```Matlab
% Loads all directories
loadBatchFxns;

% Loads the class into an object.
obj = ciatah;

% Open the class menu
obj % then hit enter, no semicolon!
% Alternatively
obj.runPipeline; % then hit enter!
```

The general order of functions that users should run is ([optional] are those not critical for most datasets):

- `loadDependencies`
  - If user is running {{ site.name }} for the first time, this module has several options to download and load CNMF/CNMF-E code for cell extraction, Fiji for viewing/modifying videos (using Miji), and test data from a miniature microscope experiment.
- `modelDownsampleRawMovies` [optional]
  - If users have raw calcium imaging data that needs to be spatially downsampled, e.g. raw data from Inscopix nVista software.
- `modelAddNewFolders`
  - Users should always use this method first, used to add folders to the current class object.
  - For example, if users ran `example_downloadTestData.m`, then add the folder `[githubRepoPath]\data\2014_04_01_p203_m19_check01_raw` where `githubRepoPath` is the absolute path to the current `{{ site.name }}` repository.
- `viewMovie`
  - Users should check that {{ site.name }} loads their movies correctly and that Miji is working.
  - Users can view movies from disk, which allows checking of very large movies quickly.
  - Remember to check that `Imaging movie regexp:` (regular expression class uses to find user movies within given folders) setting matches name of movies currently in repository.
- `viewMovieRegistrationTest` [optional]
  - Users can check different spatial filtering and registration settings.
  - `tregRunX` folders (where `X` is a number) contain details of each run setting. Delete from analysis folder if don't need outputs later.
  - Remember to adjust contrast in resulting montage movies since different filtering will change the absolute pixel values.
- `modelPreprocessMovie`
  - Main processing method for {{ site.name }}. Performs motion correction, spatial filtering, cropping, down-sampling, and relative fluorescence calculations. If using Inscopix nVista 1.0 or 2.0, also will correct for dropped frames.
- `modelModifyMovies`
  - GUI that allows users to remove movie regions not relevant to cell extraction.
- `modelExtractSignalsFromMovie`
  - Performs cell extraction on processed movies. Currently supports PCA-ICA, CNMF, CNMF-e, ROI, and EXTRACT. Support for CELLMax will be enabled in the public repository upon release.
- `modelVarsFromFiles`
  - Run after `modelExtractSignalsFromMovie` to load cell image and trace information into the current class object.
- `viewCellExtractionOnMovie` [optional]
  - This function overlays the cell extraction outputs on snippets of the processed video, allowing users to check that cell extraction correctly identified all the cells.
- `computeManualSortSignals`
  - A GUI to allow users to classify cells and not cells in cell extraction outputs.
- `modelModifyRegionAnalysis` [optional]
  - Users are able to select specific cells from cell extraction manual sorting to include in further analyses.
- `computeMatchObjBtwnTrials`
  - Method to register cells across imaging sessions. Also includes visual check GUI in `viewMatchObjBtwnSessions` method.
  - __Note: it is heavily advised that throughout a particular animal's imaging sessions, that you keep the acquisition frame dimensions identical.__ This makes cross-session registration easier. Else you will have to crop all sessions for that animal to the same size ensuring that the area of interest is present in each.