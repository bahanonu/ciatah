# Preprocessing: Temporal downsampling

Example code to run the downsample test function with the following commands:
```Matlab
loadRepoFunctions;
testMovie = loadMovieList('pathToMovieFile');
unitTestDownsampleMovie(testMovie,'interp1Method','linear','cropSize',5);
```

Below is an example pixel from a cell in a BLA animal. Note...
- ImageJ `Scale...`+bilinear+averaging (blue) and Matlab `imresize`+bilinear (red) both produce pretty much identical results.
- `imresize` using bilinear and bicubic produce similar results with bicubic having slower runtimes (e.g. on my machine 3.46 vs. 4.31 sec if set `cropSize` to 100).
- The number next to each name is the vector's variance.
![image](https://cloud.githubusercontent.com/assets/5241605/13099409/b85b119c-d4e6-11e5-91d4-f6f7c74fed18.png)
