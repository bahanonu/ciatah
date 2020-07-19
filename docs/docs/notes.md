## Repository notes
- Covers preprocessing of calcium imaging videos, cell and activity trace extraction (supports the following methods: PCA-ICA, CELLMax, EXTRACT, CNMF, CNMF-E, and ROI), manual and automated sorting of cell extraction outputs, cross-session alignment of cells, and more.
- Supports `PCA-ICA`, `CNMF`, `CNMF-E`, and `ROI` cell extraction methods publicly along with `CELLMax` and `EXTRACT` for Schnitzer Lab collaborators. Additional methods can be integrated upon request.
- Most extensively tested on Windows MATLAB `2018b` and `2019a`. Moderate testing on Windows MATLAB `2015b`, `2017a`, `2017b`, and `2018b` along with OSX (10.10.5) `2017b` and `2018b`. Individual functions and `calciumImagingAnalysis` class should work on other MATLAB versions after `2015b`, but submit an issue if errors occur. Newer MATLAB version preferred.
- This repository consists of code used in and released with
  - G. Corder*, __B. Ahanonu*__, B. F. Grewe, D. Wang, M. J. Schnitzer, and G. Scherrer (2019). An amygdalar neural ensemble encoding the unpleasantness of painful experiences. _Science_, 363, 276-281. http://science.sciencemag.org/content/363/6424/276.
  - and similar code helped process imaging or behavioral data in:
    - J.G. Parker*, J.D. Marshall*, __B. Ahanonu__, Y.W. Wu, T.H. Kim, B.F. Grewe, Y. Zhang, J.Z. Li, J.B. Ding, M.D. Ehlers, and M.J. Schnitzer (2018). Diametric neural ensemble dynamics in parkinsonian and dyskinetic states. _Nature_, 557, 177–182. https://doi.org/10.1038/s41586-018-0090-6.
    - Y. Li, A. Mathis, B.F. Grewe, J.A. Osterhout, B. Ahanonu, M.J. Schnitzer, V.N. Murthy, and C. Dulac (2017). Neuronal representation of social information in the medial amygdala of awake behaving mice. Cell, 171(5), 1176-1190. https://doi.org/10.1016/j.cell.2017.10.015.
- Code mostly developed while in [Prof. Mark Schnitzer's lab](http://pyramidal.stanford.edu/) at Stanford University. Credit to those who helped in [Acknowledgments](#acknowledgments).
- Please check the 'Wiki' for further instructions on specific processing/analysis steps and additional information of software used by this package.
- When issues are encountered, first check the `Common issues and fixes` Wiki page to see if a solution is there. Else, submit a new issue.

![image](https://user-images.githubusercontent.com/5241605/61981834-ab532000-afaf-11e9-97c2-4b1d7d759a30.png)