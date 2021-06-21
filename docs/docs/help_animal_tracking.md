# Animal tracking

Code for ImageJ- and Matlab-based image tracking.

# ImageJ based tracking

Functions needed (have entire `{{ site.name }}` pipeline loaded anyways to ensure all dependencies are met):

- `mm_tracking.ijm` is the tracking function for use in ImageJ, place in
`plugins` folder. It is found in the `ciapkg\tracking` folder of the repository.
- `removeIncorrectObjs()` is a function to clean-up the ImageJ output.
- `createTrackingOverlayVideo()` is a function that allows users to check the output from the tracking by overlaying the mouse tracker onto the video.

## Instructions for ImageJ and Matlab
Run `mm_tracking` from the `Plugins` menu of ImageJ. Several settings to check:

- `number of session folders to analyze` - this will indicate how many movies you want to analyze. Depending on `analyze movies from a list file` setting, a GUI will appear asking you to select movies to analyze (preferably AVIs) or a text file with a list of movies.
- `pixel to cm conversion, distance (cm)` - Make sure pixel to cm conversion indicates a measurable distance in the video, e.g. from one side of the box to another. The program will ask you to draw this distance to estimate pixels/cm.
- `crop stack?` - keep this selected, as allow removal of parts of movie where the animal will not go, improving results.
- `erode and dilate` - likely keep this selected, as it essentially makes sure the mouse is a solid object and smooths the tracking.
- `analyze movies from a list file` - select this option if you have a text file with the location of each movie to be analyzed on a new line. Use this to analyze many movies in batch.
- `hide loaded movie` - uncheck this to be able to visualize as ImageJ completes each step in the processing. Leave checked to improve speed of analysis.

Example screen after running `mm_tracking` within ImageJ, click to expand.

<!-- <a href="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" target="_blank">![image](https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png)</a> -->
<a href="https://user-images.githubusercontent.com/5241605/113023298-554a5e80-913a-11eb-88ed-181c133184f1.png" target="_blank">![image](https://user-images.githubusercontent.com/5241605/113023298-554a5e80-913a-11eb-88ed-181c133184f1.png)</a>

Once ImageJ is finished, within `MATLAB` run the following code (cleans up the ImageJ tracking by removing small objects and adding NaNs for missing frames along with making a movie to check output). Modify to point toward paths specific for your data.
```Matlab
% CSV file from imageJ and AVI movie path used in ImageJ
moviePath = 'PATH_TO_AVI_USED_IN_IMAEJ';
csvPath = 'PATH_TO_CSV_OUTPUT_BY_IMAGEJ';
% clean up tracking
[trackingTableFilteredCell] = removeIncorrectObjs(csvPath,'inputMovie',{moviePath});
```

## Example output from animal in open field during miniature microscope imaging
<!-- 2017_09_11_p540_m381_openfield01_091112017 -->

Tracking of an animal over time (green = early in session, red = late in session).
![image](https://user-images.githubusercontent.com/5241605/34800547-2a10a3b0-f619-11e7-9c88-88750c9875cd.png)

## Tracking video

The tracking video can be used to quickly validate that the animal is being correctly tracked.

```Matlab
% make tracking video
% frames to use as example check
nFrames=1500:2500;
inputMovie = loadMovieList(moviePath,'frameList',nFrames);
[inputTrackingVideo] = createTrackingOverlayVideo(inputMovie,movmean(trackingTableFilteredCell.XM(nFrames),5),movmean(trackingTableFilteredCell.YM(nFrames),5));
playMovie(inputTrackingVideo);
```

Overlay of tracking (red circle) on the mouse in a specific frame.
![image](https://user-images.githubusercontent.com/5241605/34800536-19eefcf2-f619-11e7-954f-dba59f4fd427.png)

<!-- # Matlab based tracking

```Matlab


```

* Refer to https://github.com/schnitzer-lab/miniscope_analysis/issues/21 for additional details about testing this function.

![image](https://cloud.githubusercontent.com/assets/5241605/10858250/c899794e-7f10-11e5-9a01-5f3c31606be9.png) -->
