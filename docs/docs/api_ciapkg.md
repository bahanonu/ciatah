# `{{ site.name }}` functions within `{{ code.package }}` sub-package.

`{{ site.name }}` contains many functions for imaging analysis, from processing videos to wrappers for running cell extraction algorithms and GUIs for visualizing movies and evaluating cell extraction outputs. Several are detailed below. For each users can visualize options with `help FUN` or `edit FUN`. If attempting to load a non-package function (e.g. it does not start with `{{ code.package }}`), then append `{{ code.package }}.api.`, e.g. `playMovie` would become `{{ code.package }}.api.playMovie`. Alternatively, load all the functions into the workspace with `import ciapkg.api.*`.

## Visualizing movies

`playMovie`

`ciapkg.io.loadMovie` or `loadMovieList`

`createImageOutlineOnMovie`

`createSignalBasedMovie`

`ciapkg.io.readFrame`

## Get movie information

`ciapkg.io.getMovieInfo`

## Sorting cells

`signalSorter`

## Pre-processing

`ciapkg.demo.runPreprocessing`

`downsampleHdf5Movie`

`removeStripsFromMovie`

`turboregMovie`

`dfofMovie`

`downsampleMovie`

`normalizeMovie`

## Cell extraction

- _PCA-ICA_ - `ciapkg.signal_extraction.runPcaIca`.
- _CNMF_ - ``.
- _CNMF-E_ - ``.
- _EXTRACT_ - ``.
- _ROI_ - ``.

## Cross-session alignment

`matchObjBtwnTrials`

`createMatchObjBtwnTrialsMaps`