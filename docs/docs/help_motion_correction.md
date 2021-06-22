Scripts to register movies to remove motion.

## Calculating final transformation after multiple registration iterations.
It is possible to use the output from motion correction (often done with `turboregMovie` or `modelPreprocessMovieFunction`) to transform the movie at later times if needed. There are two ways to do this:

- iteratively perform each motion correction step (e.g. same order as in `modelPreprocessMovieFunction`) or
- create the translation/skew/rotation matrices for each step using `ResultsOutOriginal` and combine for all iterations as `totalTranformMatrix = (R2'*S2'*T2'*R1'*S1'*T1')'`. Note the order matters.
    - Where `1, 2, ...` indicate matrix for iterations `1,2,...` and `R, S, T` are rotation, skew (shear + scale) and translation matrices, respectively.
    - For 3 iterations would be `(R3'*S3'*T3'*R2'*S2'*T2'*R1'*S1'*T1')'`  or alternatively `T1*S1*R1*T3*S3*R2*T3*S3*R3`.
    - For translation/rotation matrices, use definitions in https://www.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html to construct them.

## Turboreg
### Compiling `turboreg` and `transfturboreg` mex file
* Can compile on your system using the following command
```Matlab
mex('-v', '-largeArrayDims','-I.', 'turboreg.c','.\BsplnTrf.c','.\BsplnWgt.c','.\convolve.c','.\getPut.c','.\main.c','.\phil.c','.\pyrFilt.c','.\pyrGetSz.c','.\quant.c','.\reg0.c','.\reg1.c','.\reg2.c','.\reg3.c','.\regFlt3d.c','.\svdcmp.c')

mex('-v', '-largeArrayDims','-I.', 'transfturboreg.c','.\BsplnTrf.c','.\BsplnWgt.c','.\convolve.c','.\getPut.c','.\main.c','.\phil.c','.\pyrFilt.c','.\pyrGetSz.c','.\quant.c','.\reg0.c','.\reg1.c','.\reg2.c','.\reg3.c','.\regFlt3d.c','.\svdcmp.c')
```

 * For Linux users: http://www.walkingrandomly.com/?p=2694
```Matlab
mex('-v', 'GCC="/usr/bin/gcc-4.9"', '-largeArrayDims','CFLAGS="\$CFLAGS -std=c99"','-I.', 'turboreg.c','./BsplnTrf.c','./BsplnWgt.c','./convolve.c','./getPut.c','./main.c','./phil.c','./pyrFilt.c','./pyrGetSz.c','./quant.c','./reg0.c','./reg1.c','./reg2.c','./reg3.c','./regFlt3d.c','./svdcmp.c')

mex('-v', 'GCC="/usr/bin/gcc-4.9"', '-largeArrayDims','CFLAGS="\$CFLAGS -std=c99"','-I.', 'transfturboreg.c','./BsplnTrf.c','./BsplnWgt.c','./convolve.c','./getPut.c','./main.c','./phil.c','./pyrFilt.c','./pyrGetSz.c','./quant.c','./reg0.c','./reg1.c','./reg2.c','./reg3.c','./regFlt3d.c','./svdcmp.c')
```

* Below is an example usage of `turboregMovie`.
* To use imageJ in Matlab, download Fiji (<http://fiji.sc>) and add Miji.m to your filepath, see <http://fiji.sc/Miji>.

### Running turboreg
__Note this input was from 2017.04.19 update__
```Matlab
% set turboreg options
ioptions.inputDatasetName = '/1';
ioptions.turboregRotation = 0;
ioptions.RegisType = 1;
ioptions.parallel = 1;
ioptions.meanSubtract = 1;
ioptions.normalizeType = 'bandpass'; % matlabDisk is alternative input. Done on input to turboreg but NOT on final movie.
ioptions.registrationFxn = 'transfturboreg';
ioptions.normalizeBeforeRegister = 'divideByLowpass'; % set to blank if don't want any filtering on output movie
ioptions.imagejFFTLarge = 10000;
ioptions.imagejFFTSmall = 80;
ioptions.saveNormalizeBeforeRegister = [];
ioptions.cropCoords = [];
ioptions.closeMatlabPool = 0;
ioptions.refFrame = 1;
ioptions.refFrameMatrix = [];

% load the movie and run turboreg
inputMovieMatrix = loadMovieList('data\2014_04_01_p203_m19_check01\concat_recording_20140401_180333.h5');
regMovie = turboregMovie(inputMovieMatrix,'options',ioptions);

% or run turboreg function by loading movie directly within function
regMovie = turboregMovie('pathToDir\filename.h5','options',ioptions);
```
### Old input
```Matlab
ioptions.inputDatasetName = '/1';
ioptions.turboregRotation = 1;
ioptions.RegisType = 1;
ioptions.parallel = 1;
ioptions.meanSubtract = 1;
ioptions.normalizeType = 'divideByLowpass';
ioptions.registrationFxn = 'transfturboreg';
ioptions.normalizeBeforeRegister = 'imagejFFT';
ioptions.imagejFFTLarge = 10000;
ioptions.imagejFFTSmall = 80;
ioptions.saveNormalizeBeforeRegister = [];
ioptions.cropCoords = [];
ioptions.closeMatlabPool = 0;
ioptions.refFrame = 1;
ioptions.refFrameMatrix = [];
regMovie = turboregMovie('pathToDir\filename.h5','options',ioptions);
% OR
regMovie = turboregMovie(inputMovieMatrix,'options',ioptions);
```