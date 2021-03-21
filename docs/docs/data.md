# Data

The class generally operates on the principal that a single imaging session is contained within a single folder or directory. Thus, even if a single imaging session contains multiple trials (e.g. the imaging data is split across multiple movies) this is fine as the class will concatenate them during the preprocessing step should the user request that.

The naming convention in general is below. Both TIF and AVI raw files are supported and are converted to HDF5 after processing since that format offers more flexibility during cell extraction and other analysis steps.

### Input and output files
- Default raw imaging data filename: `concat_.*.(h5|tif)`.
- Default raw processed data filename: `folderName_(processing steps).h5`, where `folderName` is the directory name where the calcium imaging movies are located.
- Main files output by `{{ site.name }}`. Below, `.*` normally indicates the folder name prefixed to the filename.
  - `.*_pcaicaAnalysis.mat`: Where PCA-ICA outputs are stored.
  - `.*_ICdecisions_.*.mat`: Where decisions for cell (=1) and not cell (=0) are stored in a `valid` variable.
  - `.*_regionModSelectUser.mat`: A mask of the region (=1) to include in further analyses.
  - `.*_turboreg_crop_dfof_1.h5`: Processed movie, in this case motion corrected, cropped, and Δ_F/F_.
  - `processing_info`: a folder containing preprocessing information.

### Loading data

Users can load data from any NWB or {{ site.name }}-style MAT files containing cell-extraction outputs using the `ciapkg.io.loadSignalExtraction` function as below.

```Matlab
[inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = ciapkg.io.loadSignalExtraction(fileName);
```

### NWB Support
{{ site.name }} supports NWB format and by default will output cell-extraction analysis as {{ site.name }} format unless user specifies otherwise. NWB files are by default stored in the `nwbFiles` sub-folder. This can be changed by setting the `obj.nwbFileFolder` property to a different folder name. Learn more about saving and loading

- Default image mask HDF5 dataset name: `/processing/ophys/ImageSegmentation/PlaneSegmentation`.
- Default fluorescence activity HDF5 dataset name: `/processing/ophys/Fluorescence/RoiResponseSeries`.

### Preferred folder naming format

Folders should following the format `YYYY_MM_DD_pXXX_mXXX_assayXX_trialXX` where:

- `YYYY_MM_DD` = normal year/month/day scheme.
-   `pXXX` = protocol number, e.g. p162, for the set of experiments performed for the same set of animals.
-   `mXXX` = subject ID/number, e.g. m805 or animal ID.
-   `assayXX` = assay ID and session number, e.g. vonfrey01 is the 1st von Frey assay session.
-   `trialXX` = the trial number of the current assay session, only applicable if multiple trials in the same assay session.

### Videos
- HDF5:
  - Saved as a `[x y t]` 3D matrix where `x` and `y` are the height and width of video while `t` is number of frames.
  - `/1` as the name for directory containing movie data.
  - HDF can be read in using Fiji, see http://lmb.informatik.uni-freiburg.de/resources/opensource/imagej_plugins/hdf5.html.
  - Each HDF5 file should contain imaging data in a dataset name, e.g. `/1` is the default datasetname for `[x y frames]` 2D calcium imaging movies in this repository.
  - Most functions have a `inputDatasetName` option to specify the dataset name if different from `/1`.
 - TIF
  - Normal `[x y frames]` tif.
- AVI
  - Raw uncompressed grayscale `[x y frames]` avi.

### Cell images
- IC filters from PCA-ICA and images from CNMF(-E).
  - `[x y n]` matrix
  - `x` and `y` being height/width of video and `n` is number of ICs output.

### Cell traces
- IC traces from PCA-ICA and images from CNMF(-E).
  - `[n f]` matrix.
  - `n` is number of ICs output and `f` is number of movie frames.