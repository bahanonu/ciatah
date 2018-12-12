#include "mex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void		message			(char				*str)
{
    
    if (NULL != strstr(str, "ERROR"))
    {
        mexErrMsgTxt(str);
    }
//     else
//     {
//         mexWarnMsgTxt(str);
//     }
        
    return;
}
