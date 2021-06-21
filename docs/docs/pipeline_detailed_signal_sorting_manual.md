---
title: Sorting cell extraction outputs.
---

# Sorting cell extraction outputs with `computeManualSortSignals`

<p align="center">
  <strong>{{ site.name }} cell sorting GUI</strong>
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif">
    <img src="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="75%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>


Outputs from most common cell-extraction algorithms like PCA-ICA, CNMF, etc. contain signal sources that are not cells and thus must be manually removed from the output. The repository contains a GUI for sorting cells from not cells. GUI also contains a shortcut menu that users can access by right-clicking or selecting the top-left menu.

Below users can see a list of options that are given before running the code, those highlighted in green

![image](https://user-images.githubusercontent.com/5241605/49845107-43322f80-fd7a-11e8-96b9-3f870d4b9009.png)

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