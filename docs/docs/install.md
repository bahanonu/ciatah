# Quick start guide

Below are steps needed to quickly get started using the `{{ site.name }}` software package in MATLAB.

## Install
- Clone the `{{ site.name }}` repository (using [GitHub desktop](https://desktop.github.com/) or command line) or download the repository zip and unzip  (e.g. run below MATLAB command).
- Point the MATLAB path to the `{{ site.name }}` root folder (*NOT* `@{{ code.mainclass }}` sub-folder in the repository).
  - Alternatively, download the package from `File Exchange` using the Add-Ons explorer in MATLAB. See `{{ site.name }}` entry at:
 [![View {{ site.name }} on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/75466-calciumimaginganalysis) or https://www.mathworks.com/matlabcentral/fileexchange/75466-calciumimaginganalysis.

 ```Matlab
 % Optional: this will set MATLAB working folder to the default user path. Make sure you have read/write permissions.
 try; cd(userpath); catch; end;

 % Download and unzip current repository
 unzip('https://github.com/bahanonu/{{ code.mainclass }}/archive/master.zip');

 % Make CIAtah the working folder
 cd('{{ code.mainclass }}-master')
 ```

## Check required toolboxes installed

`{{ site.name }}` depends on several MATLAB toolboxes to run properly. Run the below command to have `{{ site.name }}` check whether dependencies have been installed properly. If not use the `Add-Ons` (https://www.mathworks.com/help/matlab/matlab_env/get-add-ons.html) explorer to install each toolbox.

```Matlab
ciapkg.io.matlabToolboxCheck;`
```

## Setup `{{ site.name }}`

- Run `{{ site.name }}` using the below MATLAB commands. Call `obj;` in the MATLAB command window each time you want to go back to the main GUI. __Note: `calciumImagingAnalysis` class is now called `ciatah`, all functionality is the same.__

```MATLAB
% Run these commands in MATLAB to get started.

% Loads the class into an object for use in this session
obj = {{ code.mainclass }};

% Runs routines to check dependencies and help user get setup.
obj.setup;

% Open the class menu (always type `obj` then enter load the class/modules menu)
obj % then hit enter, no semicolon!
```

- Afterwards, likely want to run `modelAddNewFolders` module first in order to add folders containing imaging data to the current class object.
- [Optional] Users on Windows systems should download `Everything` (https://www.voidtools.com/). It is a very useful and extremely fast search engine for files and folders on a computer that can allow users to quickly get lists of folders then need to analyze in `{{ site.name }}`.
- [Optional] Users who want to run analysis via the command line can run `edit ciapkg.demo.cmdLinePipeline` and run each segment of code there to see what commands are needed to perform each step. It assumes you have already run `example_downloadTestData`.

## `{{ site.name }}` main GUI notes
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


## Additional quick start notes

- See additional details in [Processing calcium imaging data](#processing-calcium-imaging-data) for running the full processing pipeline.
- Settings used to pre-process imaging movies (`modelPreprocessMovie` module) are stored inside the HDF5 file to allow `{{ site.name }}` to load them again later.
- To force load all directories, including most external software packages (in `_external_programs` folder), type `ciapkg.loadAllDirs;` into MATLAB command line. This is most relevant when you need to access specific functions in an outside repository that are normally hidden until needed.
- When issues are encountered, first check the `*Common issues and fixes` Wiki page to see if a solution is there. Else, submit a new issue or email Biafra (bahanonu [at] alum.mit.edu).
- Notes:
  - There are two sets of test data that are downloaded:
    - __Single session analysis__: `data\2014_04_01_p203_m19_check01_raw` can be used to test the pipeline until the cross-session alignment step.
    - __Batch analysis__: `data\batch` contains three imaging sessions that should be processed and can then be used for the cross-session alignment step. Users should try these sessions to get used to batched analysis.
  - For Fiji dependency, when path to `Miji.m` (e.g. `\Fiji.app\scripts` folder) is requested, likely in `\_external_programs\FIJI_FOLDER\Fiji.app\scripts` where `FIJI_FOLDER` varies depending on OS, unless the user requested a custom path or on OSX (in which case, find Fiji the install directory).
    - If you run into Java heap space memory errors when Miji tries to load Fiji in MATLAB, make sure "java.opts" file is in MATLAB start-up folder or that `{{ site.name }}` folder is the MATLAB start-up folder ([instructions on changing](https://www.mathworks.com/help/matlab/matlab_env/matlab-startup-folder.html)).
  - `{{ site.name }}` often uses [regular expressions](https://www.cheatography.com/davechild/cheat-sheets/regular-expressions/) to find relevant movie and other files in folders to analyze.
    - For example, by default it looks for any movie files in a folder containing `concat`, e.g. `concat_recording_20140401_180333.h5` (test data). If you have a file called `rawData_2019_01_01_myInterestingExperiment.avi` and all your raw data files start with `rawData_` then change the regular expression to `rawData_` when requested by the repository. See `setMovieInfo` module to change after adding new folders.
  - `{{ site.name }}` generally assumes users have imaging data associated with *one* imaging session and animal in a given folder. Follow folder naming conventions in [Data](#data) for best experience.
  - External software packages are downloaded into `_external_programs` folder and should be placed there if done manually.

Users can alternatively run setup as below.
```MATLAB
% Run these commands in MATLAB to get started.

% Loads all directories
loadBatchFxns;

% Loads the class into an object for use in this session
obj = {{ code.mainclass }};

% Download and load dependent software packages into "_external_programs" folder.
% Also download test data into "data" folder.
% Normally only need to one once after first downloading {{ site.name }} package.
obj.loadDependencies;

% Add folders containing imaging data.
obj.modelAddNewFolders;

% [optional] Set the names {{ site.name }} will look for in each folder
obj.setMovieInfo;

% Open class menu to pick module to run.
obj.runPipeline; % then hit enter!
```