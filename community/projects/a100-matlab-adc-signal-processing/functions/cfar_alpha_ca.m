function alpha = cfar_alpha_ca(numTraining, pfa)
%CFAR_ALPHA_CA Exponential-noise CA-CFAR scale factor, scalar or array N.
numTraining = max(double(numTraining), 1);
alpha = numTraining .* (pfa.^(-1 ./ numTraining) - 1);
end
