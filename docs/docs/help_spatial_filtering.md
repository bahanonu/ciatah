# Movie Filtering

This page documents different features and functions in the {{ site.name }} repository variable for filtering (spatial high/low/bandpass) movies to remove neuropil, cells, or other features.

![2014_04_01_p203_m19_check01_spatialFilter](https://user-images.githubusercontent.com/5241605/111711340-af792480-8808-11eb-85d1-8c76479995bb.gif)


## Filtering movies with `normalizeMovie`

Users can quickly filter movies using the `normalizeMovie` function. See below for usage.

```Matlab 
% Load the movie (be in TIF, HDF5, AVI, etc.). Change HDF5 input dataset name as needed.
inputMovie = loadMovieList('pathToMovie','inputDatasetName','/1'); 

% Set options for dividing movie by lowpass version of the movie
options.freqLow = 1;
options.freqHigh = 4;
options.normalizationType = 'lowpassFFTDivisive';
options.waitbarOn = 1;
options.bandpassMask = 'gaussian';

% Options for normal bandpass filter
options.freqLow = 10;
options.freqHigh = 50;
options.normalizationType = 'fft';
options.waitbarOn = 1;
options.bandpassMask = 'gaussian';

% Set additional common options
options.showImages = 0; % Set to 1 if you want to view

% Run analysis
inputMovie = normalizeMovie(single(inputMovie),'options',options);
```

If users set `options.showImages = 0;`, then `normalizeMovie` will update a figure containing both real and frequency space before and after the filter has been applied along with an example of the filter in frequency space. This allows users to get a sense of what their filter is doing.

![image](https://user-images.githubusercontent.com/5241605/111677991-049f4100-87dd-11eb-9bb6-1ba46894ea70.png)

## Why conduct spatial filtering?

Spatial filtering can have a large impact on the resulting cell activity traces extracted from the movies. 

For example, below are the correlations  between all cell-extraction outputs from PCA-ICA, ROI back-application of ICA filters, and CNMF-e on a miniature microscope one-photon movie. As can be seen, especially in the case of ROI analysis, the correlation between the activity traces is rendered artificially high due to the correlated background noise. This is greatly reduced in many instances after proper spatial filtering.

![image](https://user-images.githubusercontent.com/5241605/111710928-e864c980-8807-11eb-9d29-81341290d108.png)

<!-- (Chebychev clustering, n = 5 clusters) -->

<!-- <hr> -->

## Images from unit test
### Main filtering functions.
Below is a screen grab from a random frame using all the filtering functions. A nice way to quickly see the many differences between each functions filtering.
![image](https://user-images.githubusercontent.com/5241605/32477562-18b7d9d4-c334-11e7-988f-accdf99a22f2.png)

### Test function filtering
This function will take a movie and This is currently only for the Matlab fft, but I'll see about expanding to others.

```Matlab
unitNormalizeMovie;
```

![image](https://user-images.githubusercontent.com/5241605/32477571-26620546-c334-11e7-8ce0-aa5269fcb5f3.png)

### Matlab test function
* I've also added the ability to test the parameter space of the Matlab fft, use the below command.
```Matlab
testMovieFFT = normalizeMovie(testMovie,'normalizationType','matlabFFT_test','secondaryNormalizationType','lowpassFFTDivisive','bandpassMask','gaussian','bandpassType','lowpass');
```
* Should get a movie output similar to the below, where there is the original movie, the FFT movie, the original/FFT movie, and the dfof of original/FFT movie.
![image](https://cloud.githubusercontent.com/assets/5241605/11490967/559152e2-9792-11e5-839b-a93811df70ce.png)

### Matlab test function movie output

Similar to above, showing results when using `lowpassFFTDivisive` normalization (using the `matlab divide by lowpass before registering` option in `modelPreprocessMovie` and `viewMovieRegistrationTest` functions) with `freqLow = 0` and `freqHigh` set to `1`, `4`, and `20`. This corresponds to removing increasingly smaller features from the movie.

![2014_04_01_p203_m19_check01_fft_example-3](https://user-images.githubusercontent.com/5241605/71422606-aec30400-2640-11ea-8ffb-41cdeea771c1.gif)

### ImageJ test function
To test the ImageJ FFT and determine the best parameters for a given set of movies, run the following function on a test movie matrix:
```Matlab
inputMovieTest = normalizeMovie(inputMovie,'normalizationType','imagejFFT_test');
```

The output should look like the below:
![image](https://cloud.githubusercontent.com/assets/5241605/11154743/14dd385a-89f6-11e5-8d56-c349e8c4f3f8.png)

<!-- <hr> -->

## Common Issues
A list of some common issues.

### Dark halos around cells

If the spatial filter is not properly configured then dark halos will appear around high SNR cells, potentially obscuring nearby, low SNR cells.
![image](https://cloud.githubusercontent.com/assets/5241605/11329062/1232a886-914b-11e5-9cca-85ec6162319b.png)


https://github.com/schnitzer-lab/miniscope_analysis/pull/30
* FYI, for 4x downsampled movies, `highFreq` parameter of 4 (which corresponds to a `fspecial` gaussian with std of 4) produces the closest results to ImageJ `Process->FFT->Bandpass Filter...` with inputs of `filter_large=10000 filter_small=80 suppress=None tolerance=5` (the current default in `normalizeMovie`).

* Example frame from ImageJ and Matlab FFTs.
![image](https://cloud.githubusercontent.com/assets/5241605/11519196/fbcd561e-984c-11e5-95b9-3a23085c2e44.png)

* Distribution of pixel differences between ImageJ and Matlab FFT movies.
![image](https://cloud.githubusercontent.com/assets/5241605/11519037/8bcae88c-984b-11e5-84dd-097c61ccd756.png)

* This matches the filter that ImageJ says it uses, which is fairly close to the Matlab filter.
![image](https://cloud.githubusercontent.com/assets/5241605/11519329/22b3af8e-984e-11e5-9379-5b5d4092cee0.png)

__Example video: 2015_11_25_p384_m610_openfield01__
* Below is an example comparison using the following Matlab commands to produce the filtered inputs:
```Matlab
testMovieFFT = normalizeMovie(testMovie,'normalizationType','lowpassFFTDivisive','freqHigh',7);
testMovieFFTImageJ = normalizeMovie(testMovie,'normalizationType','imagejFFT');
diffMovie = testMovieFFT-testMovieFFTImageJ ;
```

* With some tweaking of the `freqHigh` and other parameters, should hopefully be able to get closer to macheps and say that the two are identical for our purposes.

![image](https://cloud.githubusercontent.com/assets/5241605/11490643/618983b0-978f-11e5-944c-14c049d9d17e.png)

* This is the histogram of the difference movie (Matlab - ImageJ). Notice most of the values are centered around zero with stdev ~0.2% df/f.
![image](https://cloud.githubusercontent.com/assets/5241605/11490647/68fbc8a6-978f-11e5-985d-1f07101840de.png)
