# Interpreting displayed movies

It may appear at times that `{{ site.name }}` has introduced noise into movies after processing. However, normally that noise is already there in the movie. In the case of one-photon miniature microscope movies that noise is often small relative to the baseline background fluorescence, hence not noticeable. However, after dF/F0 or spatial filtering users will be able to see the noise more easily as it will have a relatively greater magnitude compared to the signal now present in the movie.

Further, in many cases the contrast is automatically adjusted in `{{ site.name }}` GUIs to boost likelihood users will see cells and other biologically relevant features (even though underlying matrix values are not changed), which can sometimes lead to the perception that noise is being added depending on viewing raw vs. dF/F0 or other preprocessed movies.

## Example

For example of what this looks like, take one of the example movies in the {{ site.name }} repository: `2014_04_01_p203_m19_check01`.

### Raw movie

A frame from the raw movie looks like:

![image](https://user-images.githubusercontent.com/5241605/104547545-a9d24900-55e3-11eb-8a91-5f4ee00b9813.png)

Applying a simple bandpass or highpass filter (to remove the low frequency background) leads to the below (keeping contrast/brightness the same as the raw movie image):

![image](https://user-images.githubusercontent.com/5241605/104547910-852aa100-55e4-11eb-8528-5b4f29052ec2.png)

However, if we adjust the contrast, we can now see some of the noise present in the higher frequency components of the raw movie that was otherwise obscured or would be hard to see in the raw movie with the high baseline present:

![image](https://user-images.githubusercontent.com/5241605/104547900-7c39cf80-55e4-11eb-86d8-9e6e80758d01.png)

### dF/F0
Now compare to dF/F0 of that same raw movie without any motion correction, etc. we see the below:

![image](https://user-images.githubusercontent.com/5241605/104547830-5280a880-55e4-11eb-8b35-ad114d12a2ff.png)

However, if you adjust the contrast, you get the below image, where the noise is much more pronounced:

![image](https://user-images.githubusercontent.com/5241605/104547778-37159d80-55e4-11eb-8b06-643508cb38ad.png)