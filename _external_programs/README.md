# External software packages

The folder `_external_programs` is for external software packages or algorithms used by `CIAtah`. These are automatically downloaded when running `obj.setup;` after creating a `CIAtah` object by calling `obj = CIAtah;` or directly by running `ciapkg.io.loadDependencies();`.

The following programs will be found in this folder after downloading (e.g. after running  `ciapkg.io.loadDependencies`):
- GUI and display
	- `ImageJ/Fiji` - Miji to allow calling of ImageJ/Fiji, only download `mij.jar` and `ij.jar`. https://imagej.net/plugins/miji.
- Cell extraction
	- `CELLMax` - Will be made public upon publication.
	- `CNMF` - https://github.com/flatironinstitute/CaImAn-MATLAB.
	- `CNMF-E` - https://github.com/zhoupc/CNMF_E.
	- `CVX` - http://cvxr.com/cvx/download/ (e.g. http://web.cvxr.com/cvx/cvx-rd.zip).
	- `EXTRACT` - https://github.com/schnitzer-lab/EXTRACT-public.
- NWB
    - `nwb_schnitzer_lab` - https://github.com/schnitzer-lab/nwb_schnitzer_lab.
    - `yamlmatlab` - https://github.com/ewiger/yamlmatlab.
    - `matnwb` - https://github.com/NeurodataWithoutBorders/matnwb.
- File I/O
	- `Bio-Formats` - MATLAB version at https://www.openmicroscopy.org/bio-formats/downloads/.
- Motion correction
	- `Turboreg` - C and MEX function implementation of http://bigwww.epfl.ch/thevenaz/turboreg/.
	- `NoRMCorre` - https://github.com/flatironinstitute/NoRMCorre.
	- `PatchWarp` - https://github.com/ryhattori/PatchWarp.

## Direct download
Direct download links for cases in which users are having connectivity issues. Extract and place contents in folder in the `_external_programs` named as indicated:
- `cnmfe` - https://github.com/bahanonu/CNMF_E/archive/master.zip
- `cnmf_current` - https://github.com/flatironinstitute/CaImAn-MATLAB/archive/master.zip
- `extract` - https://github.com/schnitzer-lab/EXTRACT-public/archive/master.zip
- `cvx_rd` - http://web.cvxr.com/cvx/cvx-rd.zip
- `imagej`
  - http://bigwww.epfl.ch/sage/soft/mij/mij.jar
    - Backup URL: http://tiny.ucsf.edu/3wFyol
  - http://rsb.info.nih.gov/ij/upgrade/ij.jar
- `bfmatlab` - https://downloads.openmicroscopy.org/bio-formats/6.6.1/artifacts/bfmatlab.zip
- `nwbpkg` - https://github.com/schnitzer-lab/nwbpkg/archive/master.zip
- `yamlmatlab` - https://github.com/ewiger/yamlmatlab/archive/master.zip
- `matnwb` - https://github.com/NeurodataWithoutBorders/matnwb/archive/v2.2.5.3.zip
- `gramm` - https://github.com/piermorel/gramm/archive/master.zip
- `turboreg` - http://tiny.ucsf.edu/ciatahTurboreg
- `cocoapi` - https://github.com/cocodataset/cocoapi
- `patchwarp` - https://github.com/ryhattori/PatchWarp using my fork https://github.com/bahanonu/PatchWarp