---
title: Manual movie cropping.
---

# Manual movie cropping with `modelModifyMovies`

If users need to eliminate specific regions of their movie before running cell extraction, that option is provided. Users select a region using an ImageJ interface and select `done` when they want to move onto the next movie or start the cropping. Movies have `NaNs` or `0s` added in the cropped region rather than changing the dimensions of the movie.

This is generally advised for movies such as miniature microscope movies imaged through a GRIN lens probe where the outside or edge or the GRIN lens are visible. This can lead to large fluctuations that can throw off some algorithms (e.g. PCA-ICA can end up assigning many components to these "signals").

![image](https://user-images.githubusercontent.com/5241605/49829899-8f627d00-fd44-11e8-96fb-2e909b4f0d78.png)

<!-- ****************************************** -->