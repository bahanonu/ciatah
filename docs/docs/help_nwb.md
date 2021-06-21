# Neurodata Without Borders (NWB)

NWB is a data standard

Some movies are larger than the available RAM on users analysis computer. Below are several ways that the underlying functions in `CIAPKG` can be used to analyze large movies.

https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html

## Saving NWB


```Matlab
% Full path to the movie
saveNeurodataWithoutBorders(cellExtractionImages,{cellExtractionSignals},cellExtractionAlgorithm,nwbFilePath);
```

Where `cellExtractionAlgorithm` is the algorithm used, consisting of:
- 

## Loading NWB


```Matlab
% Full path to the movie
[inputImages,inputTraces,infoStruct, algorithmStr] = loadNeurodataWithoutBorders(nwbFilePath);
```

Outputs mean:
- `inputImages` - 3D or 4D matrix containing cells and their spatial information.
- `inputTraces` - 2D matrix containing trace outputs.
- `infoStruct` - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
- `algorithmStr` - String of the algorithm name.

## Using NWB with `signalSorter`

For manual sorting, users can directly input path to NWB file as below:

```Matlab
[outImages, outSignals, choices] = signalSorter('pcaica.nwb',[],'inputMovie',inputMoviePath);

```