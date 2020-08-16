### Dependencies

By default external MATLAB-based software packages are stored in `_external_programs`.

#### MATLAB Toolbox dependencies

- Primary toolboxes
  - distrib_computing_toolbox
  - image_toolbox
  - signal_toolbox
  - statistics_toolbox
- Secondary toolboxes (not required for main pre-processing pipeline)
  - video_and_image_blockset
  - bioinformatics_toolbox
  - financial_toolbox
  - neural_network_toolbox

#### Parallel Computing Toolbox (PCT)

By default both `calciumImagingAnalysis` and PCT auto-start a parallel pool for functions that use parallelization (e.g. or calls to `parfor`). For some users this may not be desired, in that case go to MATLAB preferences and uncheck the below.

![image](https://user-images.githubusercontent.com/5241605/67807212-99bb6180-fa51-11e9-81e1-9ab0fac8847a.png)

Or enter the following commands into the MATLAB command window:

```Matlab
parSet = parallel.Settings;
parSet.Pool.AutoCreate = false;
```

#### ImageJ

- Run `downloadMiji` from `downloads\downloadMiji.m` or `obj.loadDependencies` (when class initialized) to download Fiji version appropriate to your platform.
- Else download Fiji (preferably __2015 December 22__ version): https://imagej.net/Fiji/Downloads.
- Make sure have Miji in Fiji installation: http://bigwww.epfl.ch/sage/soft/mij/.
- This is used as an alternative to the `calciumImagingAnalysis` `playMovie.m` function for viewing movies and is needed for some movie modification steps.

#### Saleae

- *Only download* if doing behavior and imaging experiments that use this DAQ device to collect data.
- Download 1.2.26: https://support.saleae.com/logic-software/legacy-software/older-software-releases#1-2-26-download.

#### CNMF and CNMF-E

- Download repositories by running `downloadCnmfGithubRepositories.m` or `obj.loadDependencies` (when class is initialized).
- CNMF: https://github.com/flatironinstitute/CaImAn-MATLAB.
- CNMF-E: https://github.com/bahanonu/CNMF_E
  - forked from https://github.com/zhoupc/CNMF_E to fix HDF5, movies with NaNs, and other related compatibility issues.
- CVX: http://cvxr.com/cvx/download/.
  - Download `All platforms` (_Redistributable: free solvers only_), e.g. http://web.cvxr.com/cvx/cvx-rd.zip.

#### Neurodata Without Borders
Neurodata Without Borders (NWB) file support requires the following GitHub repositories be present in the `_external_programs` folder. These are downloaded automatically when running `obj.setup`.
- https://github.com/schnitzer-lab/nwb_schnitzer_lab.
- https://github.com/ewiger/yamlmatlab.
- https://github.com/NeurodataWithoutBorders/matnwb.