### Repository organization
Below are a list of the top-level directories and what types of functions or files are within.

- __@calciumImagingAnalysis__ - Contains `calciumImagingAnalysis` class and associated methods for calcium imaging analysis.
- ___external_programs___ - External software packages (e.g. CNMF, CELLMax, and others) are stored here.
- ___overloaded___ - Functions that overload core MATLAB functions to add functionality or fix display issues.
- __behavior__ - Processing of behavior files (e.g. accelerometer data, Saleae files, etc.).
- __classification__ - Classification of cells, e.g. manual classification of cell extraction outputs or cross-session grouping of cells.
- __data__ - Location of test data.
- __download__ - Functions that help download external code packages or data.
- __file\_exchange__ - Contains any outside code from MATLAB's File Exchange that are dependencies in repository functions.
- __hdf5__ - Functions concerned with HDF5 input/output.
- __image__ - Functions concerned with processing images (or [x y] matrices).
- __inscopix__ - Functions concerned with Inscopix-specific data processing (e.g. using the ISX MATLAB API).
- __io__ - Contains functions concerned with file or function input-output.
- __motion_correction__ - Functions concerned with motion correction.
- __movie_processing__ - Functions concerned with preprocessing calcium imaging videos, e.g. spatial filtering, downsampling, etc.
- __neighbor__ - Detection and display of neighboring cell information.
- ___private___ - This directory contains various user settings, output pictures/data/logs from `calciumImagingAnalysis` modules, and more. This directory is NOT included in the MATLAB path, hence is good for storing related scripts without interfering with `calciumImagingAnalysis`.
- __python__ - Python code, e.g. for processing Saleae data.
- __serial__ - Code for saving and processing serial port data, e.g. Arduino streaming data.
- __settings__ - Functions concerned with settings for other functions.
- __signal\_extraction__ - Functions related to cell extraction, e.g. running PCA-ICA.
- __signal\_processing__ - Functions to process cell activity traces.
- __tracking__ - ImageJ and MATLAB functions to track animal location in behavior movies.
- __unit_tests__ [optional] - Functions to validate specific repository functions.
- __video__ - Functions to manipulate or process videos, e.g. making movie montages or adding dropped frames.
- __view__ - Functions concerned with displaying data or information to the user, normally do not process data.