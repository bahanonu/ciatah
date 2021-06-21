---
title: Loading cell extraction data.
---

# Loading cell-extraction output data for custom scripts

Users can load outputs from cell extraction using the below command. This will then allow users to use the images and activity traces for downstream analysis as needed.

```Matlab
[inputImages,inputSignals,infoStruct,algorithmStr,inputSignals2] = ciapkg.io.loadSignalExtraction('pathToFile');
```

Note, the outputs correspond to the below:

- `inputImages` - 3D or 4D matrix containing cells and their spatial information, format: [x y nCells].
- `inputSignals` - 2D matrix containing activity traces in [nCells nFrames] format.
- `infoStruct` - contains information about the file, e.g. the 'description' property that can contain information about the algorithm.
- `algorithmStr` - String of the algorithm name.
- `inputSignals2` - same as inputSignals but for secondary traces an algorithm outputs.

<!-- ****************************************** -->

## Loading cell-extraction output data with `modelVarsFromFiles`

In general, after running cell-extraction (`modelExtractSignalsFromMovie`) on a dataset, run the `modelVarsFromFiles` module. This allows `{{ site.name }}` to load/pre-load information about that cell-extraction run.

If you had to restart MATLAB or are just loading {{ site.name }} fresh but have previously run cell extraction, run this method before doing anything else with that cell-extraction data.

A menu will pop-up like below when `modelVarsFromFiles` is loaded, you can normally just leave the defaults as is.

![image](https://user-images.githubusercontent.com/5241605/67052600-7f00f880-f0f3-11e9-9555-96fe32b4de6d.png)


<!-- ****************************************** -->
