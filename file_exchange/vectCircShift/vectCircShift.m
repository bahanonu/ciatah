function  [outMat] =  vectCircShift(vectToShift,shiftVector)
%This function generates a matrix where each row is a circshift of the
%original vector from the specified interval in the shiftVector;
%
%Inputs
%vectToShift:   is the original vector you want to circshift multiple times
%shiftVector:   is the vector of the circshift sizes;
%
%Outputs
%outMat:        is a matrix were every row is circshift by the amount in the
%               shiftVector

[n,m]=size(vectToShift);
if n>m
inds=(1:n)';
i=toeplitz(flipud(inds),circshift(inds,[1 0]));
outMat=vectToShift(i(shiftVector,:));
else
inds=1:m;
i=toeplitz(fliplr(inds),circshift(inds,[0 1]));
outMat=vectToShift(i(shiftVector,:));
end
end