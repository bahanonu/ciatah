# ImageJ+MATLAB based mouse location tracking

Functions needed (have entire `calciumImagingAnalysis` loaded anyways):
- `mm_tracking.ijm` is the tracking function for use in ImageJ, place in
`plugins` folder. If already had `calciumImagingAnalysis` download Fiji, place in the `_external_programs/[Fiji directory]/Fiji.app/plugins` folder.
- `removeIncorrectObjs.m` is a function to clean-up the ImageJ output.
- `createTrackingOverlayVideo` is a way to check the output from the
tracking by overlaying mouse tracker onto the video.

## Instructions for ImageJ and Matlab
Example screen after running `mm_tracking` within ImageJ, click to expand.

<a href="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" alt="image" width="600" height="auto"/></a>

<!-- <a href="https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png" target="_blank">![image](https://user-images.githubusercontent.com/5241605/34800762-1fa35480-f61a-11e7-91fb-65a260436725.png)</a> -->

After the above screen, there will be multiple other screens culminating in one where a threshold is chosen that is used to remove non-animal pixels from analysis. The threshold matters quite a bit and the script ignores anything that isn't red (i.e. larger than threshold) OR not within the range specified by the parameters below.

![image](https://user-images.githubusercontent.com/5241605/71494852-8c2f1780-2807-11ea-93b7-8c51e21116b3.png)

The script opens the AVI as a virtual stack and asks for the threshold is so that I can quickly scan through the entire movie to make sure the set threshold works even with slight/major changes in illumination, e.g. the below threshold will work across many frames

![image](https://user-images.githubusercontent.com/5241605/71494077-7f0f2a00-2801-11ea-9144-f1fc6b04c27a.png)

If the threshold is set to low, certain frames will not have the animal detected, e.g. if the lighting changes.
![image](https://user-images.githubusercontent.com/5241605/71494720-7e2cc700-2806-11ea-976e-3e9b70b00861.png)

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

### Example output from 2017_09_11_p540_m381_openfield01_091112017
<!-- ![image](https://user-images.githubusercontent.com/5241605/34800547-2a10a3b0-f619-11e7-9c88-88750c9875cd.png) -->
<img src="https://user-images.githubusercontent.com/5241605/34800547-2a10a3b0-f619-11e7-9c88-88750c9875cd.png" alt="image" width="400" height="auto"/>

Using `createTrackingOverlayVideo` to verify tracking matches animal position on a per frame basis.
<!-- ![image](https://user-images.githubusercontent.com/5241605/34800536-19eefcf2-f619-11e7-954f-dba59f4fd427.png) -->
<img src="https://user-images.githubusercontent.com/5241605/34800536-19eefcf2-f619-11e7-954f-dba59f4fd427.png" alt="image" width="400" height="auto"/>
