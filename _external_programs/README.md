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