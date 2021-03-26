## Installation

Note, this is an alternative method of installation to that outlined in [Quick Start](install.md).

Clone the `{{ site.name }}` repository or download the repository zip and unzip.

- Point the MATLAB path to the `{{ site.name }}` folder.
- Run `loadBatchFxns.m` before using functions in the directory. This adds all needed directories and sub-directories to the MATLAB path.
- Type `obj = {{ code.mainclass }};` into MATLAB command window and follow instructions that appear after to add data and run analysis.
- Run the `{{ code.mainclass }}` class method `loadDependencies` or type `obj.loadDependencies` after initializing a `{{ code.mainclass }}` object into the command window to download and add Fiji to path, download CNMF/CNMF-E repositories, download/setup CVX (for CNMF/CNMF-E), and download example data.

Note

- Place `{{ site.name }}` in a folder where MATLAB will have write permissions, as it also creates a `private` subdirectory to store some user information along with downloading required external software packages.
- `file_exchange` folder contains File Exchange functions used by `{{ site.name }}`.
- In general, it is best to set the MATLAB startup directory to the `{{ site.name }}` folder. This allows `java.opts` and `startup.m` to set the correct Java memory requirements and load the correct folders into the MATLAB path.
- If `{{ site.name }}` IS NOT the startup folder, place `java.opts` wherever the MATLAB startup folder is so the correct Java memory requirements are set (important for using ImageJ/Miji in MATLAB).
- If it appears an old `{{ site.name }}` repository is loaded after pulling a new version, run `restoredefaultpath` and check that old `{{ site.name }}` folders are not in the MATLAB path.
<!-- - This version of `{{ site.name }}` has been tested on Windows MATLAB `2015b`, `2017a`, and `2018b`. Moderate testing on Windows and OSX (10.10.5) `2017b` and `2018b`. -->