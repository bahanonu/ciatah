---
title: Cross-session cell alignment.
---

# Cross-session cell alignment with `computeMatchObjBtwnTrials`

This step allows users to align cells across imaging sessions (e.g. those taken on different days). See the [Cross session cell alignment help page](help_cross_session_alignment.md) for more details and notes on cross-session alignment. See below sections for notes on options.

- Users run `computeMatchObjBtwnTrials` to do cross-day alignment (first row in pictures below).
- Users then run `viewMatchObjBtwnSessions` to get a sense for how well the alignment ran.
- `computeCellDistances` and `computeCrossDayDistancesAlignment` allow users to compute the within session pairwise Euclidean centroid distance for all cells and the cross-session pairwise distance for all global matched cells, respectively.

![image](https://user-images.githubusercontent.com/5241605/49835713-eec88900-fd54-11e8-8d24-f7c426802297.png)


## Output of `computeMatchObjBtwnTrials`

The output for cross-session alignment for each animal is stored in a structure within the current `{{ code.mainclass }}` object: `obj.globalIDStruct.ANIMAL_ID` where `ANIMAL_ID` is the animal identification automatically pulled from folder names (if none is found, defaults to `m0`). Users can then get the matrix that gives the session IDs from the `{{ code.mainclass }}` class:

```Matlab
% Grab the cross session alignment structure from the current `{{ code.mainclass }}` object. 
alignmentStruct = obj.globalIDStruct.ANIMAL_ID

% Global IDs is a matrix of [globalID sessionID].
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID.
globalIDs = alignmentStruct.globalIDs;

```

Below is an example of what that `globalIDs` matrix looks like when visualized. Each column is an imaging session and each row is an individual global cell with the color indicating that global cell's within-session number. Any black cells indicate where no match was found for that global cell in that imaging day.

<a href="https://user-images.githubusercontent.com/5241605/126750867-1ea1bcff-b3d1-493f-aac9-b7b7c7292796.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/126750867-1ea1bcff-b3d1-493f-aac9-b7b7c7292796.png" alt="Global cell output" width="70%"/></a>

## Notes on `computeMatchObjBtwnTrials` options

After starting `computeMatchObjBtwnTrials`, the below options screen will appear:   
<a href="https://user-images.githubusercontent.com/5241605/126746771-c0486ab8-aec1-429d-b982-88f638a400a8.png" target="_blank"><img src="https://user-images.githubusercontent.com/5241605/126746771-c0486ab8-aec1-429d-b982-88f638a400a8.png" alt="Cross session options screen" width="100%"/></a>

An explanation of each option is as follows:

- `Number of rounds to register images (integer)`
  - This determines the number of rounds to register all the sessions to the "base" session used for alignment. Additional rounds of registration (e.g. we at times use up to 5 rounds) can often improve results especially in cases where there might be large lateral displacements across sessions.
- `Distance threshold to match cells cross-session (in pixels)`
  - This determine the maximum distance that the algorithm should use to match cells across sessions. Ideally this value should be _below_ the within-session distance between cells to minimize false positives (e.g. matching nearby cells across sessions that are actually different cells).
- `Image binarization threshold (0 to 1, fraction each image''s max value)`
  - This threshold is used to remove parts of the cell filter that are not necessarily useful for cross-session alignment, such as faint dendrites or axons along with noise produced by some algorithms in their filters (e.g. as is the case with PCA-ICA).
- `Session to align to (leave blank to auto-calculate middle session to use for alignment)`
  - Leaving blank automatically selects the middle session, as this session is often a compromise between changes (e.g. drift in the field of view) that occurred between the 1st and last session.
- `Registration type (3 = rotation and iso scaling, 2 = rotation no iso scaling)`
  - This is the type of _Turboreg_ registration used to align the sessions during cross-session motion correction. Avoid using iso scaling enabled (e.g. `3` or projective) unless you know in advance that you have warping in your field of view across days, else this option can lead to less optimal results compared to iso scaling disabled (e.g. `2` or affine).
  - See https://www.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html.
- `Run image correlation threshold? (1 = yes, 0 = no)`
  - This determines whether a secondary measure will be used to match cells across sessions and decreases the probability of false positives. It does this by correlating the putative matched cell to others that have been already matched to be the same cells and adds it to the "global cell" group for that cell if it passes a pre-defined threshold as below. In general this should be enabled unless you know the imaging quality varies across sessions that would lead to a distortion in cell shapes or you are using a cell-extraction algorithm that does not produce high-quality filters.
- `Image correlation type (e.g. "corr2","jaccard")`
  - This is the type of correlation measure, where `corr2` is [2-D correlation coefficient](https://www.mathworks.com/help/images/ref/corr2.html) and `jaccard` is the [Jaccard distance](https://en.wikipedia.org/wiki/Jaccard_index). The [Ochiai similarity](https://en.wikipedia.org/wiki/Cosine_similarity) is also supported.
  - A list of all possible measures can be found at https://www.mathworks.com/matlabcentral/fileexchange/55190-simbin-mat1-mat2-type-mask. Note, some might not be valid and in general the above three should work for most users.
- `Image correlation threshold for matched cells (0 to 1)`
  - How high the image correlation needs to be for it to be considered a match, e.g. accept the match if it has an image correlation above this amount _and_ a distance below that specified above.
- `Image correlation binarization threshold (0 to 1, fraction each image''s max value)`
  - This is the threshold used for calculated image correlations. __Note__ this is different that the threshold used for cross-session cell alignment as sometimes the cross-session threshold needs to be a different value to improve alignment compared to a more relaxed threshold to improve estimation of cell shape (e.g. too high of a threshold can make all cells look similar depending on the algorithm).
- `Threshold below which registered image values set to zero`
  - During registration zero values can sometimes take on very small numerical values that can cause problems for downstream analysis. This threshold sets all pixels below this value to zero to correct for this. For the most part do not change this value.
- `Visually compare image correlation values and matched images (1 = yes, 0 = no)`
  - This will pop-up a GUI after running cross-session alignment to show matches that users can scroll through.
- `View full results after [viewMatchObjBtwnSessions] (1 = yes, 0 = no)`
  - This will pop-up several figures showing example cells matched across sessions along with graphs that show cross-session matches with each cell colored by its global identification to help determine accuracy of results. If users go to `obj.picsSavePath` and look under the folders `matchObjColorMap`, they will find AVI and picture files with outputs related to these figures.

<!-- ### Check within-session -->

## View cross-session cell alignment with `viewMatchObjBtwnSessions`

To evaluate how well cross-session alignment works, `computeMatchObjBtwnTrials` will automatically run `viewMatchObjBtwnSessions` at the end, but users can also run it separately after alignment. The left are raw dorsal striatum cell maps from a single animal. The right shows after cross-session alignment; color is used to indicate a global ID cell (e.g. the same cell matched across multiple days). Thus, same color cell = same cell across sessions.

<a href="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" alt="2017_05_02_p545_m121_p215_raw" width="auto" height="400"/></a>
<a href="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" alt="2017_05_02_p545_m121_p215_corrected_biafraalgorithm2" width="auto" height="400"/></a>

## Save cross-session cell alignment with `modelSaveMatchObjBtwnTrials`

Users can save out the alignment structure by running `modelSaveMatchObjBtwnTrials`. This will allow users to select a folder where `{{ site.name }}` will save a MAT-file with the alignment structure information for each animal.