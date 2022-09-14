---
title: Automated cell extraction.
---

# Extracting cells with `modelExtractSignalsFromMovie`

Users can run the following cell-extraction algorithms:
    - <a href='https://searchworks.stanford.edu/view/11513617'>CELLMax</a>
    - <a href='https://github.com/mukamel-lab/CellSort'>PCA-ICA</a>
    - <a href='https://github.com/flatironinstitute/CaImAn-MATLAB' target='_blank'>CNMF</a>
    - <a href='https://github.com/zhoupc/CNMF_E'>CNMF-E</a>
    - <a href='https://github.com/schnitzer-lab/EXTRACT-public' target='_blank'>EXTRACT</a>
    - etc.
by following the below set of option screens. Details on running the new Schnitzer lab cell-extraction methods (e.g. CELLMax) will be added here after they are released.

We normally estimate the number of PCs and ICs on the high end, manually sort to get an estimate of the number of cells, then run PCA-ICA again with IC 1.5-3x the number of cells and PCs 1-1.5x number of ICs.

To run CNMF or CNMF-E, run `loadDependencies` module (e.g. `obj.loadDependencies`) after {{ site.name }} class is loaded. CVX (a CNMF dependency) will also be downloaded and `cvx_setup` run to automatically set it up.

![image](https://user-images.githubusercontent.com/5241605/49830421-fa608380-fd45-11e8-8d9a-47a3d2921111.png)

The resulting output (on _Figure 45+_) at the end should look something like:

![image](https://user-images.githubusercontent.com/5241605/67053021-fe42fc00-f0f4-11e9-980c-88f463cb5043.png)

<!-- ![image](https://user-images.githubusercontent.com/5241605/51728907-c2c44700-2026-11e9-9614-1a57c3a60f5f.png) -->

<!-- ****************************************** -->

## PCA-ICA (Mukamel, 2009)

There are several parameters for PCA-ICA that users can input, these are `µ`, `term_tol`, `max_iter`, and the number of PCs and ICs to request.

### Mukamel, 2009 (`µ`)
The original Mukamel, 2009 (https://doi.org/10.1016/j.neuron.2009.08.009) paper describing PCA-ICA gives an explanation of `µ`:

![image](https://user-images.githubusercontent.com/5241605/180803955-55367e92-d1f6-494c-a78d-a1165da1b70a.png)

`Fig. S3` also provides some information on the effects that varying `µ` from 0 to 1 have on cell extraction quality (we have often found lower values, e.g. 0.1, to work well in most cases):

![image](https://user-images.githubusercontent.com/5241605/180803154-be738669-b90c-4cf3-850b-71441359bb25.png)

### Ahanonu, 2022 (`µ` and # of PCs/ICs)

We also describe `µ` in our recent calcium imaging experiments and analysis book chapter, see section `3.15 Extraction of Neuron Shapes, Locations, and Activity Traces`: https://link.springer.com/protocol/10.1007/978-1-0716-2039-7_13#Sec19. 

Further, we make a note about choosing the number

![image](https://user-images.githubusercontent.com/5241605/180802392-b134fed1-c8ab-45b5-9ee6-814100e410ed.png)

### term_tol

The `term_tol` parameter is the ICA termination tolerance, e.g. when min difference between ICA iterations is below this value, the algorithm will exit (if it has not already reached `max_iter`).

### max_iter

The `max_iter` parameter determines how many iterations ICA will run before terminating.

## CNMF (Pnevmatikakis et al. 2016)

CNMF (Constrained Nonnegative Matrix Factorization) uses a modified version of NMF to reduce crosstalk between signals and also outputs model-based traces with reduced noise. It is recommended that users compare both the model-based, smoothed traces and the more noisy dF/F traces extracted from the movie as each can be useful for different types of analyses.

A description of many of the parameters can be found at https://caiman.readthedocs.io/en/master/Getting_Started.html#parameters.

## CNMF-e (Zhou et al. 2018)

Use CNMF-e primarily on one-photon datasets or those with large background fluctuations, it will generally perform better than CNMF in those situations.

- An overview of the CNMF-e model can be found at https://github.com/zhoupc/CNMF_E/wiki/Model-overview.
- Inscopix provides a good description of parameters at: https://github.com/inscopix/inscopix-cnmfe/blob/main/docs/parameter_tuning.md.

## EXTRACT (Inan et al. 2021)

EXTRACT improves signal estimation via robust estimation to reduce contamination from surrounding noise sources (be they nearby cells or background activity).

A description of EXTRACT parameters can be found at https://github.com/schnitzer-lab/EXTRACT-public#advanced-aspects.