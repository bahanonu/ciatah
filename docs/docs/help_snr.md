# Preprocessing: Improving SNR

This relates to methods within the `calciumImagingAnalysis` class for checking ΔF/F during cell sorting and ways to improve SNR (esp. in miniscope movies), also see [Preprocessing:-Spatial-filtering](../Preprocessing:-Spatial-filtering).

## Movie cell ROI trace during cell sorting
- If users press `r` while in the interface, it will show users a ROI calculated trace (which will contain more cross-talk, but will give you a direct measure of ΔF/F from your movie compared to ICA/CNMF-E/etc. traces.
![image](https://user-images.githubusercontent.com/5241605/52152675-0ffa7700-262c-11e9-9800-e53517cde869.png)
![image](https://user-images.githubusercontent.com/5241605/52152685-1a1c7580-262c-11e9-9beb-e47fa5ffeac9.png)

## Spatial filtering during `modelPreprocessMovie` preprocessing
- The other is that in the `modelPreprocessMovie` preprocessing module, when you are on the 1st page of the options, in the `filterBeforeRegister` setting select `matlab divide by lowpass before registering` or `matlab bandpass before registering`.
- See also the spatial filtering wiki page: https://github.com/bahanonu/calciumImagingAnalysis/wiki/Preprocessing:-Spatial-filtering#dark-halos-around-cells.

![image](https://user-images.githubusercontent.com/5241605/52152666-06710f00-262c-11e9-89fe-6f517632f384.png)

## viewMovieRegistrationTest
- To get a feel for how the different filtering affects SNR/movie data, run `viewMovieRegistrationTest` module and select either `matlab divide by lowpass before registering` or `matlab bandpass before registering` then change `filterBeforeRegFreqLow` and `filterBeforeRegFreqHigh` settings, see below.

![image](https://user-images.githubusercontent.com/5241605/52153165-cb6fdb00-262d-11e9-8c9f-8e7953c02eee.png)

![image](https://user-images.githubusercontent.com/5241605/52152814-a62e9d00-262c-11e9-99da-981377a4b7b9.png)

- You'll get an output like the below (top left is without any filtering, other 3 are with different bandpass filtering options).

![image](https://user-images.githubusercontent.com/5241605/52153455-f3137300-262e-11e9-9858-45445f44e7f5.png)

![image](https://user-images.githubusercontent.com/5241605/52153507-2d7d1000-262f-11e9-9662-182331b555c0.png)

- Cell ΔF/F intensity profile from the raw movie

![image](https://user-images.githubusercontent.com/5241605/52153427-d7a86800-262e-11e9-983f-fa3879adca9a.png)

- Same cell ΔF/F intensity profile from the bottom/left movie (not the y-axis is the same as above):

![image](https://user-images.githubusercontent.com/5241605/52153392-ba739980-262e-11e9-8750-04ef2c11861b.png)