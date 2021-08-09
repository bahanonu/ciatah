DataHigh readme:


DataHigh website:
www.ece.cmu.edu/~byronyu/software/DataHigh/datahigh.html


For examples:
Go to /examples/ folder.  Try any of the example.m scripts (ex1_dimreduce.m, etc.)
to try DataHigh on example data.  Corresponding tutorials and videos are on the
website and in the User Guide.



To get started with your own data:
Format a D struct, such that D(itrial).data (num_neurons x num_1ms_timebins)
contains the spike trains for the ith trial.
Run 'DataHigh(D, 'DimReduce')' in the Matlab command line.


Please see the website and User Guide for more advanced features.