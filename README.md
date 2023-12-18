# `CIAtah`
<!-- # `CIAtah` (calciumImagingAnalysis [ciapkg]) -->
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square)](https://github.com/bahanonu/calciumImagingAnalysis/graphs/commit-activity?style=flat-square&logo=appveyor)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)](https://github.com/bahanonu/calciumImagingAnalysis/releases/latest?style=flat-square&logo=appveyor)
![GitHub top language](https://img.shields.io/github/languages/top/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
![GitHub license](https://img.shields.io/github/license/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
![visitors](https://vbr.wocr.tk/badge?page_id=bahanonu.ciatah)
<!-- <img src="https://visitor-badge.glitch.me/badge?page_id=bahanonu.calciumImagingAnalysis" onerror="this.style.display='none'" alt='visitors' style='display:inline'> -->
<!-- ![Hits](https://hitcounter.pythonanywhere.com/count/tag.svg?url=https%3A%2F%2Fgithub.com%2Fbahanonu%2FcalciumImagingAnalysis) -->
<!-- <img src="https://hitcounter.pythonanywhere.com/count/tag.svg?url=https%3A%2F%2Fgithub.com%2Fbahanonu%2FcalciumImagingAnalysis" onerror="this.style.display='none'" alt=''> -->

<img src="https://user-images.githubusercontent.com/5241605/117930569-03593480-b2b3-11eb-87f2-314e8ed77e94.png" align="center" onerror="this.style.display='none'" alt=''>
<br>

`CIAtah` (pronounced cheetah; formerly <ins>c</ins>alcium<ins>I</ins>maging<ins>A</ins>nalysis [ciapkg]) is a software package for analyzing one- and two-photon calcium imaging datasets. It can also be used to process other imaging datasets (e.g. from non-calcium indicators and dyes).

<img src="https://user-images.githubusercontent.com/5241605/99499485-d6dce500-292d-11eb-8c68-b089fe1985c8.png" width="42%" align="right" alt="ciatah_logo">

`CIAtah` currently requires `MATLAB` and runs on all major operating systems (Windows, Linux [e.g. Ubuntu], and macOS).
- Note: `CIAtah` version `v4` moves the remaining (i.e. all except external packages and software) CIAtah functions into the `ciapkg` package to improve namespace handling and requires MATLAB R2019b or above ([due to package import changes](https://www.mathworks.com/help/matlab/matlab_prog/upgrade-code-for-r2019b-changes-to-function-precedence-order.html#mw_2934c766-e115-4d22-9abf-eb46a1415f2c)).


## Full documentation at https://bahanonu.github.io/ciatah/.

Below are recordings and additional documents for users who want to learn more about calcium imaging analysis/experiments and the CIAtah pipeline.

<ins> __Book chapter__ </ins> — We have a book chapter that goes over all steps of miniscope imaging: viral injections, GRIN lens probe implant, pain experimental design, data processing and neural/behavioral analysis, and more.
- See [Ahanonu, B., Corder, G. (2022). _Recording Pain-Related Brain Activity in Behaving Animals Using Calcium Imaging and Miniature Microscopes_](https://doi.org/10.1007/978-1-0716-2039-7_13) (https://doi.org/10.1007/978-1-0716-2039-7_13).

<ins>__Webinar__</ins> — This webinar gives an overview of calcium imaging analysis (with a focus on CIAtah) along with tips for improving experiments and analysis: https://info.inscopix.com/inscopix-inspire-view-webinarbiafra-ahanonu-signal-in-the-noise-distinguishing-relevant-neural-activity-in-calcium-imaging.

<ins>__Workshop tutorial__</ins> — This recording gives an overview of setting up and using CIAtah: https://www.youtube.com/watch?v=I6abW3uuJJw.

<ins>__Imaging analysis tools__</ins> My table with many current imaging analysis tools: https://github.com/bahanonu/imaging_tools.

<ins>__GRINjector__</ins> — A surgical device to help with implanting gradient-refractive index (GRIN) lens probes into the brain or other regions: https://github.com/bahanonu/GRINjector.

<ins>__Upcoming motion correction methods__</ins> — Methods for motion correction of spinal imaging data using feature identification (e.g. with DeepLabCut), control point registration, and other methods. Additional updates on integration into CIAtah in the future.
- Preprint: Ahanonu and Crowther, _et al_. (2023). _Long-term optical imaging of the spinal cord in awake, behaving animals_. bioRxiv (https://www.biorxiv.org/content/10.1101/2023.05.22.541477v1.full).
<!-- <hr> -->

<!-- <img src="https://user-images.githubusercontent.com/5241605/81605697-b9c7c800-9386-11ea-9e9f-569c743b24b9.png" width="42%" align="right" alt="calciumImagingAnalysis_logo"> -->
<!-- https://user-images.githubusercontent.com/5241605/99430025-a2c9db80-28bd-11eb-8508-d1c63dea6fcf.png -->
<!-- https://user-images.githubusercontent.com/5241605/99237853-e2a19d80-27ad-11eb-996f-3869db0c2238.png -->
<!-- https://user-images.githubusercontent.com/5241605/99477838-332d0e00-2908-11eb-887b-9205a305cf5d.png -->
<!-- <p align="center"> -->
  
<!-- </p> -->

## Contents

- [CIAtah features](#ciatah-features)
- [CIAtah example features](#ciatah-example-features)
- [Quick start guide](#quick-start-guide)
- [Quick start (command-line)](#quick-start-command-line)
- [`CIAtah` main GUI notes](#ciatah-main-gui-notes)
- [Acknowledgments](#acknowledgments)
- [References](#references)
- [Questions](#questions)
- [License](#license)

Contact: __Biafra Ahanonu, PhD (github [at] bahanonu [dot] com)__.

Made in USA.<br>
<img src="https://user-images.githubusercontent.com/5241605/71493809-322a5400-27ff-11ea-9b2d-52ff20b5f332.png" align="center" title="USA" alt="USA" width="auto" height="50">

***
## CIAtah features
- `CIAtah` package-enclosed functions (in `+ciapkg` sub-folders) can be used to create GUI-less, command line-ready analysis pipelines. As all functions are within the `ciapkg` package for improve namespace handling to allow incorporating into other programs.
- A GUI, via `ciatah` class, with different modules for large-scale batch analysis.
- Includes all major calcium imaging analysis steps:
  - movie visualization (including reading from disk, for fast viewing of large movies);
  - pre-processing (motion correction [e.g. TurboReg, NoRMCorre] , spatiotemporal downsampling, spatial filtering, relative fluorescence calculation, etc.);
   <!-- - Pre-processing supports read-from-disk based analysis for movies that are too large to fit into RAM. -->
  - support for multiple cell-extraction methods:
    - <a href='https://github.com/mukamel-lab/CellSort'>PCA-ICA</a>
    - <a href='https://searchworks.stanford.edu/view/11513617'>CELLMax</a> (<a href='https://searchworks.stanford.edu/view/12854822'>additional</a>)
    - <a href='https://github.com/flatironinstitute/CaImAn-MATLAB' target='_blank'>CNMF</a>
    - <a href='https://github.com/zhoupc/CNMF_E'>CNMF-E</a>
    - <a href='https://github.com/schnitzer-lab/EXTRACT-public' target='_blank'>EXTRACT</a>
    - etc.
  - manual classification of cells via GUIs;
  - automated cell classification (i.e. CLEAN algorithm, coming soon!);
  - cross-session cell alignment;
  - and more.
- Includes example one- and two-photon calcium imaging datasets for testing `CIAtah`.
- Supports a plethora of major imaging movie file formats: HDF5, NWB, AVI, MP4, ISXD [Inscopix], TIFF, BigTIFF, SLD [SlideBook], and [Bio-Formats](https://www.openmicroscopy.org/bio-formats/) compatible formats (Olympus [OIR] and Zeiss [CZI and LSM] currently, additional support to be added or upon request).
- Supports [Neurodata Without Borders](https://www.nwb.org/) data standard (see [calcium imaging tutorial](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html)) for reading/writing cell-extraction and imaging movie files.
- Animal position tracking (e.g. in open-field assay) via ImageJ plugin.
- Requires `MATLAB` and runs on all major operating systems (Windows, Linux [e.g. Ubuntu], and macOS).
<!-- <hr> -->

## CIAtah example features

<p align="center">
  <strong>Support for entire calcium imaging pipeline.</strong>
</p>
<!-- ![ciapkg_pipeline](https://user-images.githubusercontent.com/5241605/105438231-6c8b3e00-5c17-11eb-8dd0-8510fa204fa2.png) -->
<!-- ![ciapkg_pipeline_v2-01](https://github.com/bahanonu/ciatah/assets/5241605/9236ec16-38a9-40da-8545-ad40d0ea83c3) -->
<p align="center">
  <a href="https://github.com/bahanonu/ciatah/assets/5241605/9236ec16-38a9-40da-8545-ad40d0ea83c3">
    <img src="https://github.com/bahanonu/ciatah/assets/5241605/9236ec16-38a9-40da-8545-ad40d0ea83c3" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="100%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>

<p align="center">
  <strong>Movie processing, cell extraction, and analysis validation.</strong>
</p>
<p align="center">
 • Press play if auto-play disabled.
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/94530890-9c3db280-01f0-11eb-99f0-e977f5edb304.gif">
    <img src="https://user-images.githubusercontent.com/5241605/94530890-9c3db280-01f0-11eb-99f0-e977f5edb304.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="60%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>

<p align="center">
  <strong>Cell sorting GUI.</strong>
</p>
<p align="center">
 • Press play if auto-play disabled.
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif">
    <img src="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="60%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>

<p align="center">
  <strong>Stable cell alignment across imaging sessions.</strong>
</p>
<p align="center">
 • Press play if auto-play disabled.
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/105437652-4ca74a80-5c16-11eb-893a-87ea6d53e964.gif">
    <img src="https://user-images.githubusercontent.com/5241605/105437652-4ca74a80-5c16-11eb-893a-87ea6d53e964.gif" align="center" title="m121_matchedCells" alt="m121_matchedCells" width="20%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>

<!-- <p align="center">
  <strong>Stable cell alignment across imaging sessions.</strong>
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/105437652-4ca74a80-5c16-11eb-893a-87ea6d53e964.gif">
    <img src="https://user-images.githubusercontent.com/5241605/105437652-4ca74a80-5c16-11eb-893a-87ea6d53e964.gif" align="center" title="m121_matchedCells" alt="m121_matchedCells" width="20%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p> -->


***

## Quick start guide

Below are steps needed to quickly get started using the `CIAtah` software package in MATLAB.

### Download and install `CIAtah`

- Clone the `CIAtah` repository (using [GitHub desktop](https://desktop.github.com/) or command line) or download the repository zip and unzip (e.g. run below MATLAB command).
  - Point the MATLAB path to the `CIAtah` root folder (*NOT* `@CIAtah` sub-folder in the repository).
  - Alternatively (not recommended since lags GitHub repository), download the package from `File Exchange` using the Add-Ons explorer in MATLAB. See `CIAtah` entry at:
 [![View CIAtah on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/75466-ciatah) or https://www.mathworks.com/matlabcentral/fileexchange/75466-ciatah.

 ```Matlab
 % Optional: this will set MATLAB working folder to the default user path. Make sure you have read/write permissions.
 try; cd(userpath); catch; end;

 % Download and unzip current repository
 unzip('https://github.com/bahanonu/ciatah/archive/master.zip');

 % Make CIAtah the working folder
 cd('ciatah-master')
 ```

### Check required toolboxes are installed

`CIAtah` depends on several MATLAB toolboxes to run properly. Run the below command to have `CIAtah` check whether dependencies have been installed properly. If not, use the `Add-Ons` (https://www.mathworks.com/help/matlab/matlab_env/get-add-ons.html) explorer to install each toolbox.

```Matlab
ciapkg.io.matlabToolboxCheck();
```

### Setup `CIAtah`

- Download and install `CIAtah` dependencies. These will all be located in the `_external_programs` sub-folder within the CIAtah main code directory.

```MATLAB
ciapkg.io.loadDependencies;
```

- Run `CIAtah` using the below MATLAB commands. Call `obj;` in the MATLAB command window each time you want to go back to the main GUI. 
  - __Note: `calciumImagingAnalysis` class is now called `ciatah`, all functionality is the same.__

```MATLAB
% Loads the class into an object for use in this session
obj = ciatah();

% Runs routines to check dependencies and help user get setup.
obj.setup();

% Open the class menu (always type `obj` then enter load the class/modules menu)
obj % then hit enter, no semicolon!
```

- Afterwards, run the `modelAddNewFolders` module to add data folders the current `CIAtah` class object.
- Run `obj;` in the command window to see the main GUI.
- Full documentation at https://bahanonu.github.io/ciatah/.
- __[Optional]__ Users on Windows systems can download `Everything` (https://www.voidtools.com/). It is a very useful and extremely fast search engine for files and folders that allows users to quickly obtain lists of full folder paths for analysis in `CIAtah`.
- __[Optional]__ If run into issues opening certain AVI files (e.g. due to codec issues) with CIAtah/MATLAB, install `K-Lite Codec Pack` (https://codecguide.com/download_kl.htm) or similar for added support.
<!-- - __[Optional]__ Users who want to analyze data via the command line can run `edit ciapkg.demo.cmdLinePipeline` and run each segment of code there to see what commands are needed to perform each step. It assumes you have already run `example_downloadTestData`. -->

### Visualize movies quickly using read from disk

Users can quickly visualize movies in any of the supported formats (HDF5, NWB, AVI, TIFF, ISXD, etc.) using the `playMovie` function. This will read directly from disk, allowing users to scroll through frames to visually check movies before or after processing. 

Users can run via the command-line:

```MATLAB
% Use the absolute path to the movie file or a valid relative path.
ciapkg.api.playMovie('ABSOLUTE\PATH\TO\MOVIE');
```

When using HDF5 files, check the dataset name containing movie with `h5disp` then input the full dataset name (e.g. below is for a standard NWB-formatted HDF5 file):
```MATLAB
ciapkg.api.playMovie('ABSOLUTE\PATH\TO\MOVIE','inputDatasetName','/acquisition/TwoPhotonSeries/data');
```

Alternatively, using the `ciatah` GUI class, users can select loaded folders and change the regular expression to match the name of the files in the movie, both for the raw data and for any processed movies in the folder. See below:

<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/140582378-d7c797e8-9099-43a7-b1cd-29ae04a36056.png">
    <img src="https://user-images.githubusercontent.com/5241605/140582378-d7c797e8-9099-43a7-b1cd-29ae04a36056.png" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="100%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>
<!-- https://user-images.githubusercontent.com/5241605/124651957-6a790c80-de50-11eb-8a6d-0197a9f484c1.png -->


## Quick start (command line or GUI-less batch analysis)

After downloading `CIAtah` and running the setup as above, users interested in command-line processing can open up the example M-file by running the below command. By running individual code-block cells, users are guided from pre-processing through cell-extraction to cross-session analysis.
```MATLAB
edit ciapkg.demo.cmdLinePipeline
```

Users can import the CIAtah `ciapkg` that contains the command-line functions using the below command at the beginning of their functions. This will import all `ciapkg` functions into the functions workspace such that `ciapkg.api.loadMovieList()` (an alias for `ciapkg.io.loadMovieList()`) can be called as `loadMovieList()`.
```MATLAB
import ciapkg.api.* % import CIAtah functions in ciapkg package API.

```

***

## Acknowledgments

Thanks to Jones G. Parker, PhD (<https://parker-laboratory.com/>) for providing extensive user feedback during the development of the `CIAtah` software package.

Additional thanks to Drs. Jesse Marshall, Jérôme Lecoq, Tony H. Kim, Hakan Inan, Lacey Kitch, Maggie Larkin, Elizabeth Otto Hamel, Laurie Burns, and Claudia Schmuckermair for providing feedback, specific functions, or helping develop aspects of the code used in `CIAtah`.

## References

Please cite [Corder*, Ahanonu*, et al. 2019](http://science.sciencemag.org/content/363/6424/276.full) _Science_ publication or the [Ahanonu, 2018](https://doi.org/10.5281/zenodo.2222294) _Zenodo_ release if you used the software package or code from this repository to advance/help your research:

```bibtex
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

Please cite the [Ahanonu and Corder, 2022](https://doi.org/10.1007/978-1-0716-2039-7_13) book chapter if you used procedures detailed therein.

```bibtex
@incollection{ahanonu2022recording,
  title={Recording Pain-Related Brain Activity in Behaving Animals Using Calcium Imaging and Miniature Microscopes},
  author={Ahanonu, Biafra and Corder, Gregory},
  booktitle={Contemporary Approaches to the Study of Pain},
  pages={217--276},
  year={2022},
  publisher={Springer}
}
```

Please see https://bahanonu.github.io/ciatah/references/ for additional references depending on processing steps undertaken.

<!-- 
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
 -->

## Questions?
Please email any additional questions not covered in the repository to `github [at] bahanonu [dot] com` or open an issue.

Users with versions of MATLAB earlier than R2019b can download `CIAtah` version `v3` (see [Releases](https://github.com/bahanonu/ciatah/releases)) until pre-R2019b MATLAB support is fully integrated into v4.

## License

Copyright (C) 2013-2023 Biafra Ahanonu

This project is licensed under the terms of the MIT license. See LICENSE file for details.

## Repository stats
Statistics on total hits on the main repository and documentation pages. Several badges are present as certain services have gone offline or count page hits differently.

- ![visitors](https://visitor-badge.glitch.me/badge?page_id=bahanonu.calciumImagingAnalysis) (starting 2020.09.22)
- ![Hits](https://hitcounter.pythonanywhere.com/count/tag.svg?url=https%3A%2F%2Fgithub.com%2Fbahanonu%2FcalciumImagingAnalysis) (starting 2020.09.16)
- ![visitors](https://page-views.glitch.me/badge?page_id=bahanonu.ciatah) (starting 2022.03.02, backup)
- ![visitors](https://visitor-badge.deta.dev/badge?page_id=bahanonu.ciatah&left_color=gray&right_color=red) (starting 2022.03.02, backup)
- ![visitors](https://visitor-badge.glitch.me/badge?page_id=bahanonu.calciumImagingAnalysis)
- [![Visits Badge](https://badges.pufler.dev/visits/bahanonu/ciatah?cacheSeconds=3600)](https://badges.pufler.dev) (starting 2023.12.17) <!-- Potentially more unique visitors -->
- ![visitors](https://vbr.wocr.tk/badge?page_id=bahanonu_ciatah&cache=on) (starting 2023.12.17) <!-- Potentially more unique visitors -->
- ![visitors](https://vbr.wocr.tk/badge?page_id=bahanonu.ciatah)

<!-- - [![HitCount](http://hits.dwyl.com/bahanonu/calciumImagingAnalysis.svg)](http://hits.dwyl.com/bahanonu/calciumImagingAnalysis) (starting 2020.08.16), frozen til `dwyl` migrates to new server. -->