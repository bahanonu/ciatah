---
title: Automated cell extraction.
---

# Extracting cells with `modelExtractSignalsFromMovie`

Users can run PCA-ICA, <a href='https://github.com/schnitzer-lab/EXTRACT-public' target='_blank'>EXTRACT</a>, CNMF, CNMF-E, and ROI cell extraction by following the below set of option screens. Details on running the new Schnitzer lab cell-extraction methods (e.g. CELLMax) will be added here after they are released.

We normally estimate the number of PCs and ICs on the high end, manually sort to get an estimate of the number of cells, then run PCA-ICA again with IC 1.5-3x the number of cells and PCs 1-1.5x number of ICs.

To run CNMF or CNMF-E, run `loadDependencies` module (e.g. `obj.loadDependencies`) after {{ site.name }} class is loaded. CVX (a CNMF dependency) will also be downloaded and `cvx_setup` run to automatically set it up.

![image](https://user-images.githubusercontent.com/5241605/49830421-fa608380-fd45-11e8-8d9a-47a3d2921111.png)

The resulting output (on _Figure 45+_) at the end should look something like:

![image](https://user-images.githubusercontent.com/5241605/67053021-fe42fc00-f0f4-11e9-980c-88f463cb5043.png)

<!-- ![image](https://user-images.githubusercontent.com/5241605/51728907-c2c44700-2026-11e9-9614-1a57c3a60f5f.png) -->

<!-- ****************************************** -->
