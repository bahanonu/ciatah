---
title: Preprocessing calcium imaging movies
---

# Preprocessing calcium imaging movies with `modelPreprocessMovie`

After users instantiate an object of the `{{ site.name }}` class and enter a folder, they can start preprocessing of their calcium imaging data with `modelPreprocessMovie`.

- See below for a series of windows to get started, the options for motion correction, cropping unneeded regions, Δ_F/F_, and temporal downsampling were selected for use in the study associated with this repository.
- There is also support for various other types of movie corrections, such as detrending a movie using linear or higher-order fits to remove the effects of photobleaching.
- If users have not specified the path to Miji, a window appears asking them to select the path to Miji's `scripts` folder.
- If users are using the test dataset, it is recommended that they do not use temporal downsampling.
- Vertical and horizontal stripes in movies (e.g. CMOS camera artifacts) can be removed via `stripeRemoval` step. Remember to select correct `stripOrientationRemove`,`stripSize`, and `stripfreqLowExclude` options in the preprocessing options menu.

![image](https://user-images.githubusercontent.com/5241605/49827992-93d86700-fd3f-11e8-9936-d7143bbec3db.png)

Next the user is presented with a series of options for motion correction, image registration, and cropping.:

- The options highlighted in green are those that should be considered by users.
- Users can over their mouse over each option to get tips on what they mean.
- In particular, make sure that `inputDatasetName` is correct for HDF5 files and that `fileFilterRegexp` matches the form of the calcium imaging movie files to be analyzed.
- After this, the user is asked to let the algorithm know how many frames of the movie to analyze (defaults to all frames).
- Then the user is asked to select a region to use for motion correction. In general, it is best to select areas with high contrast and static markers such as blood vessels. Stay away from the edge of the movie or areas outside the brain (e.g. the edge of microendoscope GRIN lens in one-photon miniature microscope movies).

![image](https://user-images.githubusercontent.com/5241605/49828665-4ceb7100-fd41-11e8-9da6-9f5a510f1c13.png)

## Save/load preprocessing settings

Users can also enable saving and loading of previously selected pre-processing settings by changing the red option below.

![image](https://user-images.githubusercontent.com/5241605/70419318-10b52400-1a1a-11ea-9b43-782ac6624042.png)

Settings loaded from previous run (e.g. of `modelPreprocessMovie`) or file (e.g. from `viewMovieRegistrationTest` runs) are highlighted in orange. Settings that user has just changed are still highlighted in green.

![image](https://user-images.githubusercontent.com/5241605/70418766-e6169b80-1a18-11ea-9713-f5a8301fe1c1.png)

The algorithm will then run all the requested preprocessing steps and presented the user with the option of viewing a slice of the processed file. Users have now completed pre-processing.

![image](https://user-images.githubusercontent.com/5241605/49829599-b53b5200-fd43-11e8-82eb-1e94fd7950e7.png)

<!-- ****************************************** -->