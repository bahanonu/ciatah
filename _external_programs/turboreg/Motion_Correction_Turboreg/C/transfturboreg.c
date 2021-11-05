#include "mex.h"
#include <stdio.h>
#include <stdlib.h>
#include "phil.h"
#include "register.h"
#include "regFlt3d.h"
#include "matrix.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    struct	fitRec		fit;
    struct	rParam		reg;
    float	*imgReg, *imgOut, *imgOutMask, *imgRegMask;
    mxArray *field_value;
    int nx, ny, nz;
    double *skew, *translation, *origin;
    mwSize *dims;

    const char *output_field_names[] = {"Translation", "Rotation", "Origin", "Skew"};
    
    /* We only handle singles */
    if (!mxIsClass(prhs[0], "single"))
    {
        mexErrMsgTxt("Input image should be single.\n");
    }
    if (!mxIsClass(prhs[1], "single"))
    {
        mexErrMsgTxt("Input image should be single.\n");
    }
    
    if (!mxIsStruct (prhs[2]))
    {
         mexErrMsgTxt("Expects transf struct.\n");
    }

    imgReg	= (float *)mxGetData(prhs[0]);
    imgRegMask	= (float *)mxGetData(prhs[1]);

     // We get the variables options from the provided structure
    field_value=mxGetField(prhs[2], 0,"Translation");
    translation=mxGetPr(field_value);
    
    fit.dx[0]=*translation;
    fit.dx[1]=*(translation+1);
    fit.dx[2]=*(translation+2);

    field_value=mxGetField(prhs[2], 0,"Origin");
    origin=mxGetPr(field_value);
    
    fit.origin[0]=*origin;
    fit.origin[1]=*(origin+1);
    fit.origin[2]=*(origin+2);
    
    field_value=mxGetField(prhs[2], 0,"Skew");
    skew=mxGetPr(field_value);
    
    fit.skew[0][0]=*(skew);
    fit.skew[0][1]=*(skew+1);
    fit.skew[0][2]=*(skew+2);
    fit.skew[1][0]=*(skew+3);
    fit.skew[1][1]=*(skew+4);
    fit.skew[1][2]=*(skew+5);
    fit.skew[2][0]=*(skew+6);
    fit.skew[2][1]=*(skew+7);
    fit.skew[2][2]=*(skew+8);
        
    nx = mxGetM(prhs[0]);
    ny = mxGetN(prhs[0]);
    nz = 1;
    
    dims = (mwSize *) mxMalloc (2 * sizeof(mwSize));
    dims[0] = nx;
    dims[1] = ny;

    plhs[0]=mxCreateNumericArray (2, dims, mxSINGLE_CLASS, mxREAL); 
    imgOut = (float *)mxGetData(plhs[0]);
   
    imgOutMask = (float *)mxGetData(mxCreateNumericArray (2, dims, mxSINGLE_CLASS, mxREAL));
   
    /* directives.interpolation
     * The interpolation 'zero' means nearest neighbors. Can be used only when registering
     * the center of gravity of the test and the reference data.
     * 'one' means tri-linear interpolation.
     * 'three' means tri-cubic interpolation.
     */
    reg.directives.interpolation = three;   /* Strongly recommended choice */

    /* directives.greyRendering
     * After the registration has converged, the output volume can be rendered with or without
     * making use of the gray-level scaling parameter, irrespective of its optimization. If
     * 'greyRendering' is set to 'FALSE', no scaling is used (log(1.0) == 0.0), whatever the
     * initial condition was. If 'greyRendering' is set to 'TRUE', the scaling found through
     * optimization (matchGrey == TRUE) or the initial scaling (matchGrey == FALSE) is used for
     * rendering.
     */
    reg.directives.greyRendering = FALSE; /* Recommended choice */   
    
    
    /* Actual call to the procedure */
    if (dirMskTransform(&fit, imgReg, imgOut, imgRegMask, imgOutMask, nx, ny, nz,
            reg.directives.greyRendering, reg.directives.interpolation) == ERROR) {
        message("ERROR - Final transformation of test image failed");
        return;
    }
        
    
    return;
}
