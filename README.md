# calciumImagingAnalysis

<img src="https://user-images.githubusercontent.com/5241605/51068051-78c27680-15cd-11e9-9434-9d181b00ef8e.png" align="center">

<hr>

Software package for calcium imaging analysis of one- and two-photon imaging datasets.

<img src="https://user-images.githubusercontent.com/5241605/81605697-b9c7c800-9386-11ea-9e9f-569c743b24b9.png" width="42%" align="right" alt="calciumImagingAnalysis_logo">

Full documentation at __[https://bahanonu.github.io/calciumImagingAnalysis/](https://bahanonu.github.io/calciumImagingAnalysis/)__.

Features:
- Includes a GUI to allow users to do large-scale batch analysis, accessed via the repository's `calciumImagingAnalysis` class.
- The underlying functions can also be used to create GUI-less, command line-ready analysis pipelines. Functions located in `ciapkg` and `+ciapkg` sub-folders.
- Includes all major calcium imaging analysis steps: pre-processing (motion correction, spatiotemporal downsampling, spatial filtering, relative fluorescence calculation, etc.), support for multiple cell-extraction methods, automated cell classification (coming soon!), cross-session cell alignment, and more.
- Has several example calcium imaging datasets that it will automatically download to help users test out the package.
- Includes code for determining animal position (e.g. in open-field assay).
- Supports [Neurodata Without Borders](https://www.nwb.org/) data standard (see [calcium imaging tutorial](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html)) for reading/writing cell-extraction (e.g. outputs of PCA-ICA, CELLMax, CNMF, CNMF-E, etc.). Supports reading NWB movie files (write support coming soon).
- Requires `MATLAB`.
<!-- <hr> -->

Contact: __Biafra Ahanonu, PhD (bahanonu [at] alum [dot] mit [dot] edu)__.

Made in USA.<br>
<img src="https://user-images.githubusercontent.com/5241605/71493809-322a5400-27ff-11ea-9b2d-52ff20b5f332.png" align="center" title="USA" alt="USA" width="auto" height="50">

***
## Contents

- [Quick start guide](#quick-start-guide)
- [Acknowledgments](#acknowledgments)
- [References](#references)
- [Questions](#questions)

__Detailed README__
- [Repository notes](#repository-notes)
- [Installation](#installation)
- [Data](#data)
- [Processing calcium imaging data](#processing-calcium-imaging-data)
	- [Check movie registration before pre-processing with `viewMovieRegistrationTest`](#check-movie-registration-before-pre-processing-with-viewmovieregistrationtest)
	- [Preprocessing calcium imaging movies with  `modelPreprocessMovie`](#preprocessing-calcium-imaging-movies-with-modelpreprocessmovie)
	- [Manual movie cropping with  `modelModifyMovies`](#manual-movie-cropping-with-modelmodifymovies)
	- [Extracting cells with  `modelExtractSignalsFromMovie`](#extracting-cells-with-modelextractsignalsfrommovie)
	- [Loading cell-extraction output data with `modelVarsFromFiles`](#loading-cell-extraction-output-data-with-modelvarsfromfiles)
	- [Validating cell extraction with  `viewCellExtractionOnMovie`](#validating-cell-extraction-with--viewcellextractiononmovie)
	- [Sorting cell extraction outputs with `computeManualSortSignals`](#sorting-cell-extraction-outputs-with-computemanualsortsignals)
	- [Removing cells not within brain region with  `modelModifyRegionAnalysis`](#removing-cells-not-within-brain-region-with-modelmodifyregionanalysis)
	- [Cross-session cell alignment with  `computeMatchObjBtwnTrials`](#cross-session-cell-alignment-with-computematchobjbtwntrials)
- [ImageJ+MATLAB based mouse location tracking](#imagejmatlab-based-mouse-location-tracking)
- [License](#license)

***

## Quick start guide

Below are steps needed to quickly get started using the `calciumImagingAnalysis` software package in MATLAB.
- Clone the `calciumImagingAnalysis` repository (using [GitHub desktop](https://desktop.github.com/) or command line) or download the repository zip and unzip.
- Point the MATLAB path to the `calciumImagingAnalysis` root folder (*NOT* `@calciumImagingAnalysis` sub-folder in the repository).
  - Alternatively, download the package from `File Exchange` using the Add-Ons explorer in MATLAB. See `calciumImagingAnalysis` entry at:
 [![View calciumImagingAnalysis on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/75466-calciumimaginganalysis) or https://www.mathworks.com/matlabcentral/fileexchange/75466-calciumimaginganalysis.
- Run the below MATLAB commands.
- Afterwards, likely want to run `modelAddNewFolders` module first in order to add folders containing imaging data to the current class object.
- [Optional] Users on Windows systems should download `Everything` (https://www.voidtools.com/). It is a very useful and extremely fast search engine for files and folders on a computer that can allow users to quickly get lists of folders then need to analyze in `calciumImagingAnalysis`.
- [Optional] Users who want to run analysis via the command line can run `edit ciapkg.demo.cmdLinePipeline` and run each segment of code there to see what commands are needed to perform each step. It assumes you have already run `example_downloadTestData`.

```MATLAB
% Run these commands in MATLAB to get started.

% Loads the class into an object for use in this session
obj = calciumImagingAnalysis;

% Runs routines to check dependencies and help user get setup.
obj.setup;

% Open the class menu (always type `obj` then enter load the class/modules menu)
obj % then hit enter, no semicolon!

```

### `calciumImagingAnalysis` main GUI notes
- All main decisions for choosing a method/procedure to run, cell-extraction algorithm, and which folders to analyze are in a single window.
- The GUI will real-time update the selected folders based on the selections in the subject, assay, and folder filter areas.
- Sections not relevant for a specific method are grayed out.
- Tab to cycle through selection areas. Green background is the currently selected area, dark gray background is area that had previously been selected but is not the active area, and white background is for areas that have not been selected yet.
- Hover mouse over method names for tooltip that gives additional information.

__For example, selecting middle two assays automatically changes selection in `Loaded folders` section.__

<a href="https://user-images.githubusercontent.com/5241605/79494880-96ed0280-7fd8-11ea-85e1-05a13dc26e90.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/79494880-96ed0280-7fd8-11ea-85e1-05a13dc26e90.png" alt="image" width="45%" height="auto"/></a>
<a href="https://user-images.githubusercontent.com/5241605/79494959-b97f1b80-7fd8-11ea-8197-7be457d24638.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/79494959-b97f1b80-7fd8-11ea-8197-7be457d24638.png" alt="image" width="45%" height="auto"/></a>

__Certain sections become available when user selects the appropriate method (e.g. cell-extraction method available when selecting `modelExtractSignalsFromMovie`).__

<a href="https://user-images.githubusercontent.com/5241605/79495026-d4ea2680-7fd8-11ea-8d4d-02164e1af1d6.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/79495026-d4ea2680-7fd8-11ea-8d4d-02164e1af1d6.png" alt="image" width="50%" height="auto"/></a>

### Additional quick start notes

- See additional details in [Processing calcium imaging data](#processing-calcium-imaging-data) for running the full processing pipeline.
- Settings used to pre-process imaging movies (`modelPreprocessMovie` module) are stored inside the HDF5 file to allow `calciumImagingAnalysis` to load them again later.
- To force load all directories, including most external software packages (in `_external_programs` folder), type `ciapkg.loadAllDirs;` into MATLAB command line. This is most relevant when you need to access specific functions in an outside repository that are normally hidden until needed.
- When issues are encountered, first check the `*Common issues and fixes` Wiki page to see if a solution is there. Else, submit a new issue or email Biafra (bahanonu [at] alum.mit.edu).
- Notes:
  - There are two sets of test data that are downloaded:
    - __Single session analysis__: `data\2014_04_01_p203_m19_check01_raw` can be used to test the pipeline until the cross-session alignment step.
    - __Batch analysis__: `data\batch` contains three imaging sessions that should be processed and can then be used for the cross-session alignment step. Users should try these sessions to get used to batched analysis.
  - For Fiji dependency, when path to `Miji.m` (e.g. `\Fiji.app\scripts` folder) is requested, likely in `calciumImagingAnalysis\_external_programs\FIJI_FOLDER\Fiji.app\scripts` where `FIJI_FOLDER` varies depending on OS, unless the user requested a custom path or on OSX (in which case, find Fiji the install directory).
    - If you run into Java heap space memory errors when Miji tries to load Fiji in MATLAB, make sure "java.opts" file is in MATLAB start-up folder or that `calciumImagingAnalysis` folder is the MATLAB start-up folder ([instructions on changing](https://www.mathworks.com/help/matlab/matlab_env/matlab-startup-folder.html)).
  - `calciumImagingAnalysis` often uses [regular expressions](https://www.cheatography.com/davechild/cheat-sheets/regular-expressions/) to find relevant movie and other files in folders to analyze.
    - For example, by default it looks for any movie files in a folder containing `concat`, e.g. `concat_recording_20140401_180333.h5` (test data). If you have a file called `rawData_2019_01_01_myInterestingExperiment.avi` and all your raw data files start with `rawData_` then change the regular expression to `rawData_` when requested by the repository. See `setMovieInfo` module to change after adding new folders.
  - `calciumImagingAnalysis` generally assumes users have imaging data associated with *one* imaging session and animal in a given folder. Follow folder naming conventions in [Data](#data) for best experience.
  - External software packages are downloaded into `_external_programs` folder and should be placed there if done manually.

Users can alternatively run setup as below.
```MATLAB
% Run these commands in MATLAB to get started.

% Loads all directories
loadBatchFxns;

% Loads the class into an object for use in this session
obj = calciumImagingAnalysis;

% Download and load dependent software packages into "_external_programs" folder.
% Also download test data into "data" folder.
% Normally only need to one once after first downloading calciumImagingAnalysis package.
obj.loadDependencies;

% Add folders containing imaging data.
obj.modelAddNewFolders;

% [optional] Set the names calciumImagingAnalysis will look for in each folder
obj.setMovieInfo;

% Open class menu to pick module to run.
obj.runPipeline; % then hit enter!
```

***

## Acknowledgments

Thanks to Jones G. Parker, PhD (<https://parker-laboratory.com/>) for providing extensive user feedback during development of the `calciumImagingAnalysis` software package.

Additional thanks to Drs. Jesse Marshall, Jérôme Lecoq, Tony H. Kim, Hakan Inan, Lacey Kitch, Maggie Larkin, Elizabeth Otto Hamel, Laurie Burns, and Claudia Schmuckermair for providing feedback, specific functions, or helping develop aspects of the code used in the `calciumImagingAnalysis` software package.

## References

Please cite [Corder*, Ahanonu*, et al. 2019](http://science.sciencemag.org/content/363/6424/276.full) _Science_ publication or the [Ahanonu, 2018](https://doi.org/10.5281/zenodo.2222294) _Zenodo_ release if you used the software package or code from this repository to advance/help your research:

```Latex
@article{corderahanonu2019amygdalar,
  title={An amygdalar neural ensemble that encodes the unpleasantness of pain},
  author={Corder, Gregory and Ahanonu, Biafra and Grewe, Benjamin F and Wang, Dong and Schnitzer, Mark J and Scherrer, Gr{\'e}gory},
  journal={Science},
  volume={363},
  number={6424},
  pages={276--281},
  year={2019},
  publisher={American Association for the Advancement of Science}
}
```

```Latex
@misc{biafra_ahanonu_2018_2222295,
  author       = {Biafra Ahanonu},
  title        = {{calciumImagingAnalysis: a software package for
                   analyzing one- and two-photon calcium imaging
                   datasets.}},
  month        = December,
  year         = 2018,
  doi          = {10.5281/zenodo.2222295},
  url          = {https://doi.org/10.5281/zenodo.2222295}
}
```

## Questions?
Please email any additional questions not covered in the repository to `bahanonu [at] alum.mit.edu` or open an issue.

***

## License

Copyright (C) 2013-2020 Biafra Ahanonu

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.