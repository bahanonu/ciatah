# Imaging analysis methods and code
Outline of outside code, software packages, or techniques relevant to calcium imaging analysis. Also includes links to papers or GitHub code repositories.

Find an overview of calcium imaging analysis methods at https://bahanonu.com/brain/#c20181209. Or see below.
![image](https://user-images.githubusercontent.com/5241605/51403860-954b3b00-1b06-11e9-8b36-78c7d5420c1d.png)

## Image Registration
- Turboreg
  - http://bigwww.epfl.ch/thevenaz/turboreg/

- NoRMCorre
  - https://github.com/simonsfoundation/NoRMCorre

- moco
  - https://github.com/NTCColumbia/moco

## Cross-day alignment
- CellReg (Ziv lab)
  - https://github.com/zivlab/CellReg/issues/1

## Cell segmentation (static image)
- NeuroSeg: automated cell detection and segmentation for in vivo two-photon Ca2+ imaging data
  - https://link.springer.com/article/10.1007/s00429-017-1545-5
  - https://github.com/baidatong/NeuroSeg

## Cell extraction (dynamic movie)
- PCA-ICA (Schnitzer)
  - https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3282191/
  - https://github.com/schnitzer-lab/miniscope_analysis/tree/master/signal_extraction/pca_ica

- CELLMax (Schnitzer)
  - https://github.com/schnitzer-lab/CELLMax

- CNMF (Paninski)
  - https://github.com/epnev/ca_source_extraction
  - https://github.com/flatironinstitute/CaImAn-MATLAB

- CNMF-E (Paninski) - for miniscope data
  - https://github.com/zhoupc/CNMF_E

- CNMF-E+ (Fukai)
  - Automatic sorting system for large calcium imaging data
  - https://www.biorxiv.org/content/early/2017/11/09/215145

- Automatic Neuron Detection in Calcium Imaging Data Using Convolutional Networks
  - http://papers.nips.cc/paper/6137-automatic-neuron-detection-in-calcium-imaging-data-using-convolutional-networks

- SCALPEL: Extracting Neurons from Calcium Imaging Data
  - https://arxiv.org/abs/1703.06946

- HNCcorr: A Novel Combinatorial Approach for Cell Identification in Calcium-Imaging Movies
  - https://arxiv.org/abs/1703.01999

- Seeds Cleansing CNMF for Spatiotemporal Neural Signals Extraction of Miniscope Imaging Data (Simon email this one out recently)
  - https://arxiv.org/abs/1704.00793

- ABLE: An Activity-Based Level Set Segmentation Algorithm for Two-Photon Calcium Imaging Data
  - http://www.eneuro.org/content/4/5/ENEURO.0012-17.2017
  - https://github.com/StephanieRey/ABLE.

- STNeuroNet: Fast and robust active neuron segmentation in two-photon calcium imaging using spatiotemporal deep learning
  - https://www.pnas.org/content/116/17/8554.short

## Cell-extraction correction

- NAOMi (Neural Anatomy and Optical Microscopy)
  - https://www.biorxiv.org/content/10.1101/726174v1.full

## Full packages
- Suite2P
  - https://github.com/cortex-lab/Suite2P

- OnACID — OnACID: Online Analysis of Calcium Imaging Data in Real Time
  - https://www.biorxiv.org/content/early/2017/10/02/193383

- CaImAn (Computational toolbox for large scale Calcium Imaging Analysis)
  - https://github.com/simonsfoundation/CaImAn

- CALIMA: The Semi-automated open-source Calcium imaging analyzer
  - https://doi.org/10.1016/j.cmpb.2019.104991
  - https://aethelraed.nl/calciumimaginganalyser/index.html

- NETCAL: An interactive platform for large-scale, NETwork and population dynamics analysis of CALcium imaging recordings
  - https://zenodo.org/record/1119026#.XT9GdxSYVds
  - http://www.itsnetcal.com/

- Minian: An open-source miniscope analysis pipeline
  - https://www.biorxiv.org/content/10.1101/2021.05.03.442492v1.abstract
  - https://github.com/DeniseCaiLab/minian


## Standards
- https://github.com/NeurodataWithoutBorders/api-matlab