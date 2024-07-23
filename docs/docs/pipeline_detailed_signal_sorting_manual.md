---
title: Sorting cell extraction outputs.
---

# Sorting cell extraction outputs with `computeManualSortSignals`

<p align="center">
  <strong>{{ site.name }} cell sorting GUI</strong>
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif">
    <img src="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="100%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>


Outputs from most common cell-extraction algorithms like PCA-ICA, CNMF, etc. contain signal sources that are not cells and thus must be manually removed from the output. The repository contains a GUI for sorting cells from not cells. GUI also contains a shortcut menu that users can access by right-clicking or selecting the top-left menu.

## Resources on manual identification

![image](img/Ahanonu_Kitch_manualSort01.png)

The above figure gives an overview of the CIAtah manual sorting GUI along with examples of candidate cells that are accepted or rejected based on a variety of criteria from several cell extraction algorithms (CELLMax, PCA-ICA, and CNMF). We have discussed manual sorting previously, see the below resources:

- `3.15.1 Manual Neuron Identification` in our miniature microscope book chapter contains a guide on manual sorting: https://link.springer.com/protocol/10.1007/978-1-0716-2039-7_13#Sec20.
- `Fig. 7: Calcium imaging analysis of nociceptive ensemble.` contains example accepted and rejected cells: https://link.springer.com/protocol/10.1007/978-1-0716-2039-7_13/figures/7.

Below are several potential criteria to use for accepting or rejecting candidate cells output by a cell extraction algorithm:

- Filter shape—e.g., cell-like depending on if using one- or two-photon imaging).
- The event triggered movie activity—e.g., whether it conformed to prior expectation of one-photon neuron morphology and fluorescent indicator activity. __Note__ This criteria is critical, as some methods output candidate cells whose cell shape and activity trace look like a cell, but when the movie is checked can see that it is not a cell.
- Location within the imaging field of view—e.g., not within a blood vessel.
- The shape of the transient having characteristic fluorescent indicator dynamics, this will depending on the indicator being used, e.g. GCaMP will have a different expected waveform than other indicators.
- Whether cell is a duplicate cell, e.g. some algorithms will "split" a cell into multiple candidate cells. This can be handled by re-running the algorithm with improved parameters, rejected the lower SNR (or otherwise poorer quality) cell, or accepting both cells then conducting a merging operation later (and re-running the cell trace extraction portion of the algorithm if that feature is available).

## CIAtah manual sorting GUI

Below users can see a list of options that are given before running the code. Options highlighted in green are those that are changed from the default settings.

![image](https://user-images.githubusercontent.com/5241605/49845107-43322f80-fd7a-11e8-96b9-3f870d4b9009.png)

### Loading in prior manually sorted data

Decisions during manual sorting are stored in the `private/tmp` folder within the root CIAtah directory (find with `ciapkg.getDir`). Alternatively, previously manually sorted outputs can be re-sorted if new selection criteria are desired. When loading the `computeManualSortSignals` GUI, select one of the two options below in the `Use CIAtah auto classifications?` setting.

- `Start with TEMP manually chosen classifications (e.g. backups)` - this option will open up a GUI into `private/tmp` and request users select a MAT-file containing the most recent decisions that were being manually sorted.
- `Start with FINISHED manually chosen classifications` - will automatically load already saved manual decisions located in the same folder as the cell extraction outputs.

![image](img/manualSort_reload01.png)


## GUI usage on large imaging datasets

- To manually sort on large movies that will not fit into RAM, select the below options (highlighted in green). This will load only chunks of the movie asynchronously into the GUI as you sort cell extraction outputs.
![image](https://user-images.githubusercontent.com/5241605/59215159-5d07d000-8b6d-11e9-8dd7-0d69d5fd38b6.png)

## Cell sorting from the command line with `signalSorter`

Usage instructions below for `signalSorter`, e.g. if not using the `{{ site.name }}` GUI.

__Main inputs__

- `inputImages` - [x y N] matrix where N = number of images, x/y are dimensions.
- `inputSignals` - [N frames] _double_ matrix where N = number of signals (traces).
- `inputMovie` - [x y frames] matrix

__Main outputs__

- `choices` - [N 1] vector of 1 = cell, 0 = not a cell
- `inputImagesSorted` - [x y N] filtered by `choices`
- `inputSignalsSorted` - [N frames] filtered by `choice`

``` Matlab
iopts.inputMovie = inputMovie; % movie associated with traces
iopts.valid = 'neutralStart'; % all choices start out gray or neutral to not bias user
iopts.cropSizeLength = 20; % region, in px, around a signal source for transient cut movies (subplot 2)
iopts.cropSize = 20; % see above
iopts.medianFilterTrace = 0; % whether to subtract a rolling median from trace
iopts.subtractMean = 0; % whether to subtract the trace mean
iopts.movieMin = -0.01; % helps set contrast for subplot 2, preset movie min here or it is calculated
iopts.movieMax = 0.05; % helps set contrast for subplot 2, preset movie max here or it is calculated
iopts.backgroundGood = [208,229,180]/255;
iopts.backgroundBad = [244,166,166]/255;
iopts.backgroundNeutral = repmat(230,[1 3])/255;
[inputImagesSorted, inputSignalsSorted, choices] = signalSorter(inputImages, inputSignals, 'options',iopts);
```

Examples of the interface on two different datasets:

### BLA one-photon imaging data signal sorting GUI

![out-1](https://user-images.githubusercontent.com/5241605/34796712-3868cb3a-f60b-11e7-830e-8eec5b2c76d7.gif)

### mPFC one-photon imaging data signal sorting GUI (from `example_downloadTestData.m`)

![image](https://user-images.githubusercontent.com/5241605/46322488-04c00d80-c59e-11e8-9e8a-18b3b8e4567d.png)

### Context menu

<a href="https://user-images.githubusercontent.com/5241605/95838435-9ec30080-0cf6-11eb-981d-fc8b5d46de7b.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/95838435-9ec30080-0cf6-11eb-981d-fc8b5d46de7b.png" alt="drawing" width="900" height="auto" /></a>

<!-- ****************************************** -->