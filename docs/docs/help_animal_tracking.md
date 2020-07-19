# Tracking

Code for ImageJ and Matlab based image tracking.

# ImageJ based tracking

Functions needed (have entire `miniscope_analysis` loaded anyways):
- `mm_tracking.ijm` is the tracking function for use in ImageJ, place in
`plugins` folder.
- `removeIncorrectObjs.m` is a function to clean-up the ImageJ output.
- `createTrackingOverlayVideo` is a way to check the output from the
tracking by overlaying mouse tracker onto the video.

## Instructions for ImageJ and Matlab
Example screen after running `mm_tracking` within ImageJ, click to expand.
<a href="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" target="_blank">![image](https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png)</a>

Once ImageJ is finished, within Matlab run the following code (cleans up the ImageJ tracking by removing small objects and adding NaNs for missing frames along with making a movie to check output). Modify to point toward paths specific for your data.
```Matlab
% CSV file from imageJ and AVI movie path used in ImageJ
moviePath = 'PATH_TO_AVI_USED_IN_IMAEJ';
csvPath = 'PATH_TO_CSV_OUTPUT_BY_IMAGEJ';
% clean up tracking
[trackingTableFilteredCell] = removeIncorrectObjs(csvPath,'inputMovie',{moviePath});
% make tracking video
% frames to use as example check
nFrames=1500:2500;
inputMovie = loadMovieList(moviePath,'frameList',nFrames);
[inputTrackingVideo] = createTrackingOverlayVideo(inputMovie,movmean(trackingTableFilteredCell.XM(nFrames),5),movmean(trackingTableFilteredCell.YM(nFrames),5));
playMovie(inputTrackingVideo);
```

## Example output from 2017_09_11_p540_m381_openfield01_091112017
![image](https://user-images.githubusercontent.com/5241605/34800547-2a10a3b0-f619-11e7-9c88-88750c9875cd.png)

![image](https://user-images.githubusercontent.com/5241605/34800536-19eefcf2-f619-11e7-954f-dba59f4fd427.png)


# Matlab based tracking

```Matlab


```

* Refer to https://github.com/schnitzer-lab/miniscope_analysis/issues/21 for additional details about testing this function.

![image](https://cloud.githubusercontent.com/assets/5241605/10858250/c899794e-7f10-11e5-9a01-5f3c31606be9.png)
