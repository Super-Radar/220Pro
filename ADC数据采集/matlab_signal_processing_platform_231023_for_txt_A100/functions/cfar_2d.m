function result = cfar_2d(powerMap, cfarOpts)
%CFAR_2D Two-dimensional CA-CFAR or OS-CFAR.
trainR = cfarOpts.training_cells(1);
trainD = cfarOpts.training_cells(2);
guardR = cfarOpts.guard_cells(1);
guardD = cfarOpts.guard_cells(2);
halfR = trainR + guardR;
halfD = trainD + guardD;

switch upper(cfarOpts.algorithm)
    case 'CA'
        kernel = ones(2*halfR+1, 2*halfD+1);
        kernel(halfR-guardR+1:halfR+guardR+1, ...
            halfD-guardD+1:halfD+guardD+1) = 0;
        numTraining = sum(kernel(:));
        noiseMap = conv2(powerMap, kernel, 'same') / numTraining;
        alpha = numTraining * (cfarOpts.pfa^(-1/numTraining) - 1);
        thresholdMap = alpha * noiseMap;
        mask = powerMap > thresholdMap;
    case 'OS'
        [mask, noiseMap, thresholdMap, alpha, numTraining] = ...
            os_cfar_map(powerMap, trainR, trainD, guardR, guardD, ...
            cfarOpts.os_rank_ratio, cfarOpts.pfa);
    otherwise
        error('Unsupported CFAR algorithm: %s', cfarOpts.algorithm);
end

valid = false(size(powerMap));
valid(halfR+1:end-halfR, halfD+1:end-halfD) = true;
mask = mask & valid;

result.algorithm = upper(cfarOpts.algorithm);
result.mask = mask;
result.power = powerMap;
result.noise = noiseMap;
result.threshold = thresholdMap;
result.snr_db = 10 * log10((powerMap + eps) ./ (noiseMap + eps));
result.alpha = alpha;
result.num_training_cells = numTraining;
result.edge_margin = [halfR, halfD];
end
