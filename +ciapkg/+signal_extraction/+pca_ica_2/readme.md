The PCA-ICA process has been broken down into substeps, for readability and modularity (for example, given a common PCA factorization of a movie, an ICA weight transformation matrix is sufficient to produce ICA pairs).

### PCA

`run_pca` will perform PCA on a movie, and save the result:
- `compute_pca`: Carries out the actual PCA computation

### ICA

`run_ica` will perform ICA on PCA filter-trace pairs, and save the result:
- `compute_spatiotemporal_ica_input`: Mixes the PCA filter-trace pairs according to the "spatiotemporal parameter" mu
- `compute_ica_weights`: Generates the ICA transformation matrix via FastICA
- `compute_ica_pairs`: Applies the ICA transformation matrix to the PCA pairs, to produce ICA pairs
