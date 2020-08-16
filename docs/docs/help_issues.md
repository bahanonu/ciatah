# Common issues and fixes

Page outlines some common issues and fixes to them that may be encountered while using `calciumImagingAnalysis`. These are mostly due to quirks specific to MATLAB, Fiji, or the computing environment `calciumImagingAnalysis` is used on.

***
## Contents
* [PCA-ICA, CNMF-E, or other cell extraction algorithm's don't produce sensible output.](#pca-ica-cnmf-e-or-other-cell-extraction-algorithms-dont-produce-sensible-output)
* [Out of memory using Miji](#out-of-memory-using-miji)
* [Selecting scripts folder in Fiji.app on Mac OS X](#selecting-scripts-folder-in-fijiapp-on-mac-os-x)
* [Fiji won't start using Miji or MIJ.start](#fiji-wont-start-using-miji-or-mijstart)
* [downloadCnmfGithubRepositories.m not downloading correctly](#downloadcnmfgithubrepositoriesm-not-downloading-correctly)
* [modelPreprocessMovie analysis options list not showing](#modelpreprocessmovie-analysis-options-list-not-showing)
* [Miji not loading correctly](#miji-not-loading-correctly)
* [viewMovie or other functions where movies need to be loaded end without executing](#viewmovie-or-other-functions-where-movies-need-to-be-loaded-end-without-executing)
* [Contrast is low on cell transient ΔF/F movies using computeManualSortSignals](#contrast-is-low-on-cell-transient-Δff-movies-using-computemanualsortsignals)
* [Traces in computeManualSortSignals GUI are flat.](#traces-in-computemanualsortsignals-gui-are-flat)
   * [Can't see transients.](#cant-see-transients)
   * [Change the min/max.](#change-the-minmax)
   * [Can now see transients.](#can-now-see-transients)
* [Blank frames or entire frames have baseline shifted after motion correction in modelPreprocessMovie](#blank-frames-or-entire-frames-have-baseline-shifted-after-motion-correction-in-modelpreprocessmovie)
* [File or folder dialog box with no instructions](#file-or-folder-dialog-box-with-no-instructions)
***

## PCA-ICA, CNMF-E, or other cell extraction algorithm's don't produce sensible output.

- When running `modelPreprocessMovie` a dialog box appears showing the available analysis steps. Certain combinations of these steps make sense while others should be avoided.
- For example, normally users want `turboreg->crop->dfof->downsampleTime`.
- An invalid input would be `turboreg->crop->dfof->dfstd->downsampleTime`. Since calculating the dF/F then dF/std is problematic.
- For two photon data, it is sometimes desired to have `medianFilter->turboreg->crop->dfstd (or dfof)->downsampleTime`.
- In general, `fft_highpass` and `fft_lowpass` should be avoided since they are meant to be run on stand-alone movies for specific purposes rather than included in the general pipeline.

![image](https://user-images.githubusercontent.com/5241605/51938177-54cea580-23c1-11e9-9d5d-2e7cf6170c5b.png)

- Remember at the options screen (see below) to select a spatial filtering there under the option `filterBeforeRegister` instead of selecting the `spatialFilter` option before the `turboreg` option in the analysis steps screen.

![image](https://user-images.githubusercontent.com/5241605/51938312-9fe8b880-23c1-11e9-9592-54d29160f8e6.png)

## Out of memory using `Miji`

-  If you get a `java.lang.OutOfMemoryError: GC overhead limit exceeded` style error (see below code) when trying to open a movie with `Miji`, make sure that you initialize MATLAB in the `calciumImagingAnalysis` path or place the `java.opts` file in your MATLAB start-up folder.
```Matlab
java.lang.OutOfMemoryError: GC overhead limit exceeded
	at java.lang.AbstractStringBuilder.<init>(Unknown Source)
	at java.lang.StringBuilder.<init>(Unknown Source)
```

- On Windows, you can change the start-up folder as below or in general see https://www.mathworks.com/help/matlab/matlab_env/matlab-startup-folder.html.
![image](https://user-images.githubusercontent.com/5241605/64047075-94f63200-cb22-11e9-890b-6b43db669412.png)

- `java.opts` increases the amount of memory allocated so that Java doesn't run out when using Miji to load movies. To change the amount of memory allocated (calciumImagingAnalysis sets to 7 Gb by default), change the below to a higher or lower number, e.g. 9 Gb would be `-Xmx9000m`.
```Java
-Xmx7000m
```

## Selecting `scripts` folder in `Fiji.app` on Mac OS X
Navigate to the applications folder and select `Fiji.app` and `Show Package Contents`.
![screen shot 2019-02-12 at 6 46 45 pm](https://user-images.githubusercontent.com/5241605/52684369-e2021600-2efa-11e9-90ec-83d861841182.png)

Then navigate to `/Fiji.app/scripts` and select `Miji.m` then `Get Info`. Select and copy the path as below.
![screen shot 2019-02-12 at 6 49 11 pm](https://user-images.githubusercontent.com/5241605/52684378-e4fd0680-2efa-11e9-9240-825f5d7824af.png)

When Matlab ask for the Fiji path, press `command + shift + G` in the dialog box to enter the full path manually, press enter, then select open.
![screen shot 2019-02-12 at 6 52 42 pm](https://user-images.githubusercontent.com/5241605/52684381-ea5a5100-2efa-11e9-9652-30f7b220117c.png)

## Fiji won't start using `Miji` or `MIJ.start`

- If calling `Miji` or `MIJ.start` does not lead to a Fiji GUI appearing (e.g. the below output is seen in the command window), this is likely because the last Fiji/ImageJ instance was closed improperly (e.g. by closing ImageJ with `File->Quit` or pressing the close button instead of `MIJ.exit` in the Matlab command window), leading to a headless Fiji that cannot be properly closed by Miji/Matlab.
```Matlab
--------------------------------------------------------------
Status> ImageJ is already started.
--------------------------------------------------------------
```

If this occurs, run the following commands one at a time:
```Matlab
resetMiji
% An instance of Miji should appear.
currP=pwd;Miji;cd(currP);
MIJ.exit
```

## `downloadCnmfGithubRepositories.m` not downloading correctly

- If when trying to download using `downloadCnmfGithubRepositories.m` the below error is encountered, try to run `downloadCnmfGithubRepositories` several more times as `websave` (MATLAB built-in function) sometimes momentarily does not obtain the correct write permissions and fails.
```Matlab
@@@@@@@
Error using websave (line 104)
Unable to open output file: 'signal_extraction\cnmfe.zip' for writing. Common reasons include that the file exists and does not have write permission or the folder does not have write permissions.
```

## `modelPreprocessMovie` analysis options list not showing

- MATLAB changed `uitables` internal implementation, hence `findjobj` (File Exchange function) broke causing `reorderableListbox` (File Exchange function) to also break. An updated `findjobj` has been added to the `calciumImagingAnalysis` repository and this error (see below) should no longer occur.

```Matlab
Error in reorderableListbox (line 127)
jScrollPane = jScrollPane(1);
```

## `Miji` not loading correctly

- The below error occurs when the wrong version of `Fiji` is downloaded. Please __2015 December 22__ version download from https://imagej.net/Fiji/Downloads as that implementation of `Miji.m` appears to work correctly with MATLAB.

```Matlab
@@@@@@@
Error using javaObject
No class MIJ can be located on the Java class path
```

## `viewMovie` or other functions where movies need to be loaded end without executing

- It is likely that the regular expression given to `calciumImagingAnalysis` does not match any of the files in the folder being analyzed.
- For example, in `viewMovie`, the below `Image movie regexp` setting should be changed to `concat` correspond to the demo raw imaging data's name.

![image](https://user-images.githubusercontent.com/5241605/51725501-63ab0600-2017-11e9-94e3-182fcd55fa22.png)

## Contrast is low on cell transient ΔF/F movies using `computeManualSortSignals`

- The contrast (e.g. min/max) are estimated automatically from movie data, but will not always be the optimal display for manual human sorting of data. To improve the contrast, press `q` while in the interface and adjust the min/max values until you are in a satisfactory range. See below.

Default contrast:

![image](https://user-images.githubusercontent.com/5241605/51729221-9e1c9f00-2027-11e9-9b78-1a49420b717a.png)

Contrast after user editing:

![image](https://user-images.githubusercontent.com/5241605/51729256-c0162180-2027-11e9-9966-605d114591d0.png)

## Traces in `computeManualSortSignals` GUI are flat.

- Likely this is due to one of the traces having values that are very high, throwing off the estimate used set the y-axis in the GUI (which is constant across all candidate cells). This can be changed by pressing `w`, see below.

### Can't see transients.

![image](https://user-images.githubusercontent.com/5241605/51950315-d84dbe00-23e4-11e9-9a5d-5d34e7c6ed39.png)

### Change the min/max.
![image](https://user-images.githubusercontent.com/5241605/51950356-07fcc600-23e5-11e9-9166-71282d774cea.png)

### Can now see transients.
![image](https://user-images.githubusercontent.com/5241605/51950282-bb18ef80-23e4-11e9-8c52-5649175fb0fb.png)


## Blank frames or entire frames have baseline shifted after motion correction in `modelPreprocessMovie`

- This normally occurs when `transfturboreg` is selected as the `registrationFxn`, in some Windows editions and OSX versions this leads to random baseline shifts. If this occurs change `registrationFxn` to `imtransform`. See below (green selected option).

![image](https://user-images.githubusercontent.com/5241605/51861116-3f3d7b00-22f0-11e9-8998-3a3224152214.png)

## File or folder dialog box with no instructions

- This is mainly on `OS X`, where in some versions the dialog boxes are not styled with title bars (see below). This is outside of MATLAB's control. If this occurs, check the command window as the instructions should also be provided there (e.g. with `Dialog box: [TITLE]` style text).

![image](https://user-images.githubusercontent.com/5241605/51950743-8d34aa80-23e6-11e9-892a-1138ace4f655.png)