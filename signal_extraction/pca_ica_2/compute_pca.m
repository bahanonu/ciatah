function [spatial, temporal, S] = compute_pca(M, num_PCs)
	% Computes the PCA factorization of the provided movie. Note that the
	%   movie is expected to be a 2-D matrix ([num_pixels x num_frames])!
	%

	[num_pixels, num_frames] = size(M);

	% Compute the covariance matrix [time x time]
	cov_mat_size = num_frames^2 * 4 / 1024^3; % Memory size in GB
	fprintf('%s: Computing covariance matrix (%.1f GB)...\n',...
	    datestr(now), cov_mat_size);
	C = cov(M, 1);    % Normalized by num_pixels
	C = num_pixels*C; % Undo the normalization

	fprintf('%s: Computing temporal PCs...\n', datestr(now));
	options.issym = 'true';
	C = double(C); % Conversion needed for 'eigs'
	[temporal, cov_eigs] = eigs(C, num_PCs, 'LM', options);

	cov_eigs = diag(cov_eigs)'; % Don't need the matrix

	% Keep only positive eigenvalues. Just a safeguard, should not have
	% non-positive eigenvalues, unless the covariance matrix is pathological
	sieve = cov_eigs > 0;
	temporal = temporal(:, sieve);
	cov_eigs = cov_eigs(:, sieve);
	num_PCs = sum(sieve);
	clear sieve;

	% Singular values
	S = diag(cov_eigs.^(1/2));

	% Compute the corresponding spatial PCs
	fprintf('%s: Computing corresponding PC filters...\n', datestr(now));
	% M = M - repmat(mean(M,1), num_pixels, 1); % Space normalized
	spatial = (M * temporal) / S;

	% Perform explicit normalization of the PCA filters
	for pc_idx = 1:num_PCs
	    pca_filter = spatial(:,pc_idx);
	    spatial(:,pc_idx) = pca_filter / norm(pca_filter);
	end

	% Output formatting
	temporal  = temporal';  % [num_PCs x time]
	spatial = spatial'; % [num_PCs x space]
end