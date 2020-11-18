# Inscopix

Documentation related to Inscopix-specific functions on the repository.

## Visualizing ISXD files

ISXD files can be directly visualized from disk by running `playMovie` from MATLAB command line:

```Matlab
playMovie('path\to\youMovie.isxd');
```

## Converting ISXD files to HDF5

To convert ISXD files to HDF5, see `convertInscopixIsxdToHdf5` function in the `inscopix` folder or `modelDownsampleRawMovies` module in calciumImagingAnalysis.

__Note__: By default the Inscopix API gives out a frame full of 0s for dropped frames. So those 0s frames are maintained after converting/downsampling to HDF5 or you will also get a frame with 0s if you use `loadMovieList` to read frames that were dropped from isxd files. Adjust analysis accordingly.

To use this function call it as below:
```Matlab
moviePath = 'PATH_TO_ISXD';
opts.maxChunkSize = 5000; % Max chunk size in Mb to load into RAM.
opts.downsampleFactor = 4; % How much to downsample original movie, set to 1 for no downsampling.
convertInscopixIsxdToHdf5(moviePath,'options',opts);
```

If you want to save to a custom folder, use `saveFolder` input.
```Matlab
moviePath = 'PATH_TO_ISXD';
opts.maxChunkSize = 5000; % Max chunk size in Mb to load into RAM.
opts.downsampleFactor = 4; % How much to downsample original movie, set to 1 for no downsampling.
opts.saveFolder = 'ALT_FOLDER_PATH'; % Char: alternative file path
convertInscopixIsxdToHdf5(moviePath,'options',opts);
```

The same functionality can be achieved by loading a `calciumImagingAnalysis` module using the below commands. By default `modelDownsampleRawMovies` module will see `.isxd` files and call `convertInscopixIsxdToHdf5`. This can be done on multiple folders by separating them with commas in the `modelDownsampleRawMovies` menu.

```Matlab
obj = calciumImagingAnalysis;
obj.modelDownsampleRawMovies;
```