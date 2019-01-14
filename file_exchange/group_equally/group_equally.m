function g = group_equally(x, n)
%group_equally: assign data to roughly equally sized groups
%
% Usage: g = group_equally(x, n)
%
%  x - vector of data
%  n - number of groups (or vector of pre-computed cut-points)
%
%  g - group indicator vector, such that x(g==G) gives elements of x in the
%      Gth group, for G in [1, 2, ..., n].
%
% Example:
%  x = [randn(1000, 1); randn(10, 1) + 100];
%  g = group_equally(x, 4);
%  m = mean(x) % influenced by 10 outliers
%  m = mean(x(g == 2 | g == 3)) % robust (50pc trimmed) mean, nearer 0
%
% Reference:
%  Altman & Bland (1994) http://www.bmj.com/content/309/6960/996.full

% Copyright 2010 Ged Ridgway
% http://www.mathworks.com/matlabcentral/fileexchange/authors/27434

x = x(:);
N = length(x);

if isscalar(n)
    p = quantiles(x, n);
else
    p = n;
    n = numel(p);
end

g = n * ones(N, 1);
for i = 1:n-1
    g(x < p(i)) = i;
    x(x < p(i)) = inf;
end

% if exist('nominal', 'class')
%     g = nominal(g);
% end


function p = quantiles(x, n)
% find n+1 quantiles splitting data into n groups, using percentiles
% formula as defined by Altman & Bland (1994)
s = sort(x);
k = linspace(0, 100, n + 1);
k = k(2:end-1);
p = zeros(n - 1, 1);
for i = 1:n-1
    q = k(i) * (length(x) + 1) / 100;
    w = floor(q);
    f = q - w;
    p(i) = (1 - f) * s(w)  +  f * s(w + 1);
end
