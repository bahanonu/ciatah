function ica_input = compute_spatiotemporal_ica_input(pca_filters, pca_traces, mu)

	num_PCs = size(pca_traces,1);

	% Create concatenated input for spatio-temporal ICA
	if (mu == 1) % Pure temporal
	    ica_input = pca_traces;
	elseif (mu == 0) % Pure spatial
	    ica_input = pca_filters;
	else % Spatio-temporal
	    ica_input = [(1-mu)*pca_filters, mu*pca_traces];
	    for pc_idx = 1:num_PCs % Renormalize
	        ica_input_row = ica_input(pc_idx,:);
	        ica_input(pc_idx,:) = ica_input_row / sqrt(norm(ica_input_row));
	    end
	end
end