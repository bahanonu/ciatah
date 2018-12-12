function ica_A = compute_ica_weights(data, num_ICs, term_tol, max_iter)
    % Reference: Hyvarinen (1999), FastICA (look it up!)

    num_sources = size(data,1);
    num_samples = size(data,2);

    ica_A = orth(randn(num_sources, num_ICs)); % Random seed
    BOld = zeros(size(ica_A));
    min_abs_cos = 0;

    iter = 0;
    while ((1-min_abs_cos) >  term_tol)
        iter = iter + 1;
        if (iter > max_iter)
            fprintf('  compute_ica_weights: Maximum iteration (%d) reached! Exiting...\n',...
                max_iter);
            break;
        end

        if (iter > 1)
            interm = data'*ica_A;
            interm = interm.^2;
            ica_A = data*interm/num_samples;
        end

        % Symmetric orthogonalization
        ica_A = ica_A * real(inv(ica_A' * ica_A)^(1/2));

        min_abs_cos = min(abs(diag(ica_A' * BOld)));
        BOld = ica_A;
    end
end