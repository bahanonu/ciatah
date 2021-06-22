---
title: Spatially downsample raw movies or convert to HDF5
---

# Spatially downsample raw movies or convert to HDF5 with `modelDownsampleRawMovies`

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


## Converting Inscopix ISXD files to HDF5

To convert from Inscopix ISXD file format (output by nVista v3+ and nVoke) to HDF5 run `modelDownsampleRawMovies` without changing the regular expression or make sure it looks for `.*.isxd` or similar. Users will need the latest version of the [Inscopix Data Processing Software](https://www.inscopix.com/nVista#Data_Analysis) as these functions take advantage of their API. If {{ site.name }} cannot automatically find the API, it will ask the user to direct it to the _root_ location of the Inscopix Data Processing Software (see below).

![image](https://user-images.githubusercontent.com/5241605/67715327-df5f2800-f986-11e9-9f91-eeabe7688fed.png)

<!-- ****************************************** -->