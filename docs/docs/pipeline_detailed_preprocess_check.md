---
title: Check movie registration before pre-processing
---

# Check movie registration before pre-processing with `viewMovieRegistrationTest`

Users should spatially filter one-photon or other data with background noise (e.g. neuropil). To get a feel for how the different spatial filtering affects SNR/movie data before running the full processing pipeline, run `viewMovieRegistrationTest` module. Then select either `matlab divide by lowpass before registering` or `matlab bandpass before registering` then change `filterBeforeRegFreqLow` and `filterBeforeRegFreqHigh` settings, see below.

Within each folder will be a sub-folder called `preprocRunTest` inside of which is a series of sub-folders called `preprocRun##` that will contain a file called `settings.mat` that can be loaded into `modelPreprocessMovie` so the same settings that worked during the test can be used during the actual pre-processing run.

![image](https://user-images.githubusercontent.com/5241605/52497447-f3f65880-2b8a-11e9-8875-c6b408e5c011.png)

- You'll get an output like the below:
  - __A__: The top left is without any filtering while the other 3 are with different bandpass filtering options.
  - __B__: Cell ΔF/F intensity profile from the raw movie. Obtain by selecting `Analyze->Plot profile` from Fiji menu after selecting a square segment running through a cell.
  - __C__: Same cell ΔF/F intensity profile from the bottom/left movie (note the y-axis is the same as above). Obtained in same manner as __B__.

![image](https://user-images.githubusercontent.com/5241605/59561146-695ab580-8fd1-11e9-892b-ce1f5fc7800e.png)

<!-- ****************************************** -->