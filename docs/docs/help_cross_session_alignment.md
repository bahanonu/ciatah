# Cross-day or -session cell alignment alignment

Find the main function at https://github.com/bahanonu/calciumImagingAnalysis/blob/master/classification/matchObjBtwnTrials.m

## Algorithm overview

For details, see __Cross-day analysis of BLA neuronal activity__ methods section in the associated _Science_ paper: http://science.sciencemag.org/content/sci/suppl/2019/01/16/363.6424.276.DC1/aap8586_Corder_SM.pdf#page=10.

![image](https://user-images.githubusercontent.com/5241605/51709763-21b09e80-1fdc-11e9-9332-1d52c9ed6bd5.png)

- Example output on several mPFC animals across multiple sessions. Color is used to indicate a global ID cell (e.g. the same cell matched across multiple days).
<img src="https://user-images.githubusercontent.com/5241605/51710281-7a346b80-1fdd-11e9-8cad-3b3657038375.gif" width=600/>
<!-- ![2016_08_22_mpfcfear_allanimals_crossdayalignment](https://user-images.githubusercontent.com/5241605/51710281-7a346b80-1fdd-11e9-8cad-3b3657038375.gif) -->

## Usage

The below commands in MATLAB can be used to align sessions across days.

```Matlab
% Create input images, cell array of [x y nCells] matrices
inputImages = {day1Images,day2Images,day3Images};

% options to change
opts.maxDistance = 5; % distance in pixels between centroids for them to be grouped
opts.trialToAlign = 1; % which session to start alignment on
opts.nCorrections = 1; %number of rounds to register session cell maps.
opts.RegisTypeFinal = 2 % 3 = rotation/translation and iso scaling; 2 = rotation/translation, no iso scaling

% Run alignment code
[alignmentStruct] = matchObjBtwnTrials(inputImages,'options',opts);

% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

% View the cross-session matched cells, saved to `private\_tmpFiles` sub-folder.
[success] = createMatchObjBtwnTrialsMaps(inputImages,alignmentStruct);
```

In certain cases, you want to run analysis on the registered images, see below.
```Matlab
% Get registered images, cell array of [x y nCells] matrices
registeredImagesCell = alignmentStruct.inputImages;
% Get registered cell maps, cell array of [x y] matrices
registeredCellmaps = alignmentStruct.objectMapTurboreg;

% OR another method below.

% Get the registration coordinates
globalRegCoords = alignmentStruct.registrationCoords;
globalRegCoords = globalRegCoords{folderNo};

% Re-register input images for particular imaging session for later analysis.
for iterationNo = 1:length(globalRegCoords)
	fn=fieldnames(globalRegCoords{iterationNo});
	for i=1:length(fn)
		localCoords = globalRegCoords{iterationNo}.(fn{i});
		[inputImages, localCoords] = turboregMovie(inputImages,'precomputedRegistrationCooords',localCoords);
	end
end
```

## Algorithm results

### Cross-session metrics and results on cross-session amygdala response to pain
![image](https://user-images.githubusercontent.com/5241605/51709887-794f0a00-1fdc-11e9-921a-926fdcb48e4b.png)

### PFC cross-session alignment.
<img src="https://user-images.githubusercontent.com/5241605/51710282-7a346b80-1fdd-11e9-9848-8ef84c0cfc2a.gif" width=600/>

<!--![2015_10_27_mpfc_aligned_acrossday_colored-1](https://user-images.githubusercontent.com/5241605/51710282-7a346b80-1fdd-11e9-9848-8ef84c0cfc2a.gif)-->

### Dorsal striatum cross-session algorithm comparison

- Original dorsal striatum cell maps from ICA with no motion correction applied.

![2017_05_02_p545_m121_p215_raw](https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif)

- `{{ site.name }}` (Biafra's) registration algorithm
  - Color is used to indicate a global ID cell (e.g. the same cell matched across multiple days). Thus, same color cell = same cell across sessions under the quick iteration parameters used in the below run.

![2017_05_02_p545_m121_p215_corrected_biafraalgorithm2](https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif)

- `CellReg` registration algorithm
Using older code at https://github.com/zivlab/CellReg.

![2017_05_02_p545_m121_p215_corrected](https://cloud.githubusercontent.com/assets/5241605/25643113/a4445584-2f52-11e7-9ce8-5c5554ec9a5f.gif)


