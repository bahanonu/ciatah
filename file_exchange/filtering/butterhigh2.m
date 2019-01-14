%%%
function [b,a]=butterhigh2(f)
% [b,a] = BUTTERHIGH2(wn) creates a second order high-pass Butterworth filter
% with cutoff at WN. (WN=1 corresponds to the sample frequency, not half!)
%
% Filter coefficients lifted from http://www.apicsllc.com/apics/Sr_3/Sr_3.htm
% by Brian T. Boulter

c = cot(f*pi);

n0=c^2;
n1=-2*c^2;
n2=c^2;
d0=c^2+sqrt(2)*c+1;
d1=-2*(c^2-1);
d2=c^2-sqrt(2)*c+1;

a=[1 d1/d0 d2/d0];
b=[n0/d0 n1/d0 n2/d0];