---
title: Validating cell extraction data.
---

# Validating cell extraction with `viewCellExtractionOnMovie`

After users have run cell extraction, they should check that cells are not being missed during the process. Running the method `viewCellExtractionOnMovie` will create a movie with outlines of cell extraction outputs overlaid on the movie.

Below is an example, with black outlines indicating location of cell extraction outputs. If users see active cells (red flashes) that are not outlined, that indicates either exclusion or other parameters should be altered in the previous `modelExtractSignalsFromMovie` cell extraction step.

![2014_04_01_p203_m19_check01_raw_viewCellExtractionOnMovie_ezgif-4-57913bcfdf3f_2](https://user-images.githubusercontent.com/5241605/59560798-50033a80-8fcc-11e9-8228-f9a3d83ca591.gif)

<!-- ****************************************** -->