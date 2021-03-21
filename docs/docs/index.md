# {{ site.name }} (calciumImagingAnalysis [`CIAPKG`])
![GitHub top language](https://img.shields.io/github/languages/top/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
![GitHub license](https://img.shields.io/github/license/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)](https://github.com/bahanonu/calciumImagingAnalysis/releases/latest?style=flat-square&logo=appveyor)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/bahanonu/calciumImagingAnalysis?style=flat-square&logo=appveyor)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square)](https://github.com/bahanonu/calciumImagingAnalysis/graphs/commit-activity?style=flat-square&logo=appveyor)

<img src="https://user-images.githubusercontent.com/5241605/51068051-78c27680-15cd-11e9-9434-9d181b00ef8e.png" align="center">

<hr>

Created by __Biafra Ahanonu, PhD__.

`{{ site.name }}` (pronounced cheetah) or `calciumImagingAnalysis` (`CIAPKG`) is a software package for analysis of one- and two-photon calcium imaging datasets.

__Download the software at [https://github.com/bahanonu/calciumImagingAnalysis](https://github.com/bahanonu/calciumImagingAnalysis).__

<img src="https://user-images.githubusercontent.com/5241605/99499485-d6dce500-292d-11eb-8c68-b089fe1985c8.png" width="42%" align="center" alt="CIAtah_logo" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">

- This user guide contains instructions to setup, run, and troubleshoot `{{ site.name }}`.
- Note: `{{ site.name }}` is a class (`{{ site.namelow }}` or `calciumImagingAnalysis` within MATLAB) with various GUIs to allow processing of calcium imaging data. In addition, users can access the underlying `{{ site.name }}` functions to make custom workflows. See [Custom command-line pipelines](api_example_pipeline.md).
- Read my overview of calcium imaging analysis methods at [Calcium imaging cell identification and fluorescence activity trace reconstruction, part 1](https://bahanonu.com/brain/#c20181209).

<img src="https://user-images.githubusercontent.com/5241605/94530890-9c3db280-01f0-11eb-99f0-e977f5edb304.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="75%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">

<p align="center">
  <strong>{{ site.name }} cell sorting GUI</strong>
</p>
<p align="center">
  <a href="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif">
    <img src="https://user-images.githubusercontent.com/5241605/100851700-64dec280-343a-11eb-974c-d6d29faf9eb2.gif" align="center" title="ciapkgMovie" alt="ciapkgMovie" width="75%" style="margin-left:auto;margin-right:auto;display:block;margin-bottom: 1%;">
  </a>
</p>

`{{ site.name }}` features:

- Includes a GUI to allow users to do large-scale batch analysis, accessed via the repository's `calciumImagingAnalysis` class.
- The underlying functions can also be used to create GUI-less, command line-ready analysis pipelines. Functions located in `ciapkg` and `+ciapkg` sub-folders.
- Includes all major calcium imaging analysis steps: pre-processing (motion correction, spatiotemporal downsampling, spatial filtering, relative fluorescence calculation, etc.), support for multiple cell-extraction methods, automated cell classification (coming soon!), cross-session cell alignment, and more.
- Has several example one- and two-photon calcium imaging datasets that it will automatically download to help users test out the package.
- Includes code for determining animal position (e.g. in open-field assay).
- Supports [Neurodata Without Borders](https://www.nwb.org/) data standard (see [calcium imaging tutorial](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html)) for reading/writing cell-extraction (e.g. outputs of PCA-ICA, CELLMax, CNMF, CNMF-E, etc.). Supports reading and writing NWB movie files with continued integration with NWB planned.
- Requires `MATLAB`.

![ciapkg_pipeline.png](img/ciapkg_pipeline.png)

## Navigation

The main sections of the site:

- `Setup` - installation of `{{ site.name }}`.
- `Repository` - notes about the software package and data formats.
- `Processing data` - sections related to processing calcium imaging movies using the `{{ site.name }}` class.
- `API` - details how to run `{{ site.name }}` from the command line. Will include more details on the many underlying functions in the future.
- `Help` - several section that provide hints and help for processing calcium imaging.
- `Misc` - miscellaneous information about the repository.

## References

Please cite our [Corder*, Ahanonu*, et al. _Science_, 2019](http://science.sciencemag.org/content/363/6424/276.full) publication if you used the software package or code from this repository to advance or help your research.

## Questions?

Please [open an issue on GitHub](https://github.com/bahanonu/calciumImagingAnalysis/issues) or email any additional questions not covered in the repository to `bahanonu [at] alum.mit.edu`.

Made in USA.<br>
<img src="https://user-images.githubusercontent.com/5241605/71493809-322a5400-27ff-11ea-9b2d-52ff20b5f332.png" align="center" title="USA" alt="USA" width="100px">

- ![Hits](https://hitcounter.pythonanywhere.com/count/tag.svg?url=https%3A%2F%2Fgithub.com%2Fbahanonu%2FcalciumImagingAnalysis) (starting 2020.09.16)
- ![visitors](https://visitor-badge.glitch.me/badge?page_id=bahanonu.calciumImagingAnalysis) (starting 2020.09.22)
<!-- - [![HitCount](http://hits.dwyl.com/bahanonu/calciumImagingAnalysis.svg)](http://hits.dwyl.com/bahanonu/calciumImagingAnalysis) (starting 2020.08.16), frozen til `dwyl` migrates to new server. -->