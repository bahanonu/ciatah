function x = z1(y)
% linear normalize between 0 and 1
x = (y-min(y(:)))/(max(y(:))-min(y(:)))+eps;

% for multidimensional stuff, this normalizes each column to between 0 and
% 1 independent of other columns

% T=length(y);
% y=y';
% miny=min(y);
% x = (y-repmat(miny,T,1))./repmat(max(y)-min(y),T,1);