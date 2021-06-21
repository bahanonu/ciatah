---
title: Cross-session cell alignment.
---

# Cross-session cell alignment with `computeMatchObjBtwnTrials`

This step allows users to align cells across imaging sessions (e.g. those taken on different days). See the `Cross session cell alignment` wiki page for more details and notes on cross-session alignment.

- Users run `computeMatchObjBtwnTrials` to do cross-day alignment (first row in pictures below).
- Users then run `viewMatchObjBtwnSessions` to get a sense for how well the alignment ran.
- `computeCellDistances` and `computeCrossDayDistancesAlignment` allow users to compute the within session pairwise Euclidean centroid distance for all cells and the cross-session pairwise distance for all global matched cells, respectively.

![image](https://user-images.githubusercontent.com/5241605/49835713-eec88900-fd54-11e8-8d24-f7c426802297.png)

Users can then get the matrix that gives the session IDs

```Matlab
% Global IDs is a matrix of [globalID sessionID]
% Each (globalID, sessionID) pair gives the within session ID for that particular global ID
globalIDs = alignmentStruct.globalIDs;

```

## View cross-session cell alignment with `viewMatchObjBtwnSessions`

To evaluate how well cross-session alignment works, `computeMatchObjBtwnTrials` will automatically run `viewMatchObjBtwnSessions` at the end, but users can also run it separately after alignment. The left are raw dorsal striatum cell maps from a single animal. The right shows after cross-session alignment; color is used to indicate a global ID cell (e.g. the same cell matched across multiple days). Thus, same color cell = same cell across sessions.

<a href="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643108/9bcfccda-2f52-11e7-8514-31968752bd95.gif" alt="2017_05_02_p545_m121_p215_raw" width="auto" height="400"/></a>
<a href="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" target="_blank"><img src="https://cloud.githubusercontent.com/assets/5241605/25643473/dd7b11ce-2f54-11e7-8d84-eb98c5ef801c.gif" alt="2017_05_02_p545_m121_p215_corrected_biafraalgorithm2" width="auto" height="400"/></a>

## Save cross-session cell alignment with `modelSaveMatchObjBtwnTrials`

Users can save out the alignment structure by running `modelSaveMatchObjBtwnTrials`. This will allow users to select a folder where `{{ site.name }}` will save a MAT-file with the alignment structure information for each animal.