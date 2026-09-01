function result = cfar_2d(powerMap, cfarOpts)
%CFAR_2D Two-dimensional CA/OS/GOCA/SOCA/VI-CFAR.
trainR = cfarOpts.training_cells(1);
trainD = cfarOpts.training_cells(2);
guardR = cfarOpts.guard_cells(1);
guardD = cfarOpts.guard_cells(2);
halfR = trainR + guardR;
algorithm = upper(strtrim(cfarOpts.algorithm));

switch algorithm
    case 'CA'
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        numTraining = sum(kernel(:));
        noiseMap = conv2_doppler_periodic(powerMap, kernel) / numTraining;
        alpha = cfar_alpha_ca(numTraining, cfarOpts.pfa);
        thresholdMap = alpha * noiseMap;
        mask = powerMap > thresholdMap;
        methodMap = ones(size(powerMap), 'uint8');
        methodNames = {'INVALID','CA'};
        numTrainingMap = numTraining * ones(size(powerMap));
        alphaMap = alpha * ones(size(powerMap));
        variabilityIndex = local_variability_index(powerMap, kernel, numTraining);
        sectorMeanRatio = ones(size(powerMap));

    case 'OS'
        [mask, noiseMap, thresholdMap, alpha, numTraining] = ...
            os_cfar_map(powerMap, trainR, trainD, guardR, guardD, ...
            cfarOpts.os_rank_ratio, cfarOpts.pfa);
        methodMap = repmat(uint8(5), size(powerMap));
        methodNames = {'INVALID','CA','GOCA','VI_SELECTED', ...
            'GOCA_FALLBACK','OS'};
        numTrainingMap = numTraining * ones(size(powerMap));
        alphaMap = alpha * ones(size(powerMap));
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        variabilityIndex = local_variability_index(powerMap, kernel, numTraining);
        sectorMeanRatio = ones(size(powerMap));

    case {'GOCA','SOCA'}
        [mask, noiseMap, thresholdMap, alphaMap, numTrainingMap, ~, ...
            sectorMeanRatio] = sector_cfar_map(powerMap, trainR, trainD, ...
            guardR, guardD, cfarOpts.pfa, algorithm);
        if strcmp(algorithm, 'GOCA')
            methodMap = repmat(uint8(2), size(powerMap));
            methodNames = {'INVALID','CA','GOCA'};
        else
            methodMap = repmat(uint8(6), size(powerMap));
            methodNames = {'INVALID','CA','GOCA','VI_SELECTED', ...
                'GOCA_FALLBACK','OS','SOCA'};
        end
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        variabilityIndex = local_variability_index(powerMap, kernel, sum(kernel(:)));
        alpha = alphaMap;

    case {'VI','ADAPTIVE','VI-CFAR'}
        viResult = vi_cfar_map(powerMap, trainR, trainD, guardR, guardD, cfarOpts);
        mask = viResult.mask;
        noiseMap = viResult.noise;
        thresholdMap = viResult.threshold;
        alphaMap = viResult.alpha;
        alpha = alphaMap;
        numTrainingMap = viResult.num_training_cells;
        methodMap = viResult.method_map;
        methodNames = viResult.method_names;
        variabilityIndex = viResult.variability_index;
        sectorMeanRatio = viResult.sector_mean_ratio;

    otherwise
        error('Unsupported CFAR algorithm: %s', cfarOpts.algorithm);
end

% Doppler FFT 栅格是周期域；仅 Range 边界缺少完整训练窗。
valid = false(size(powerMap));
valid(halfR+1:end-halfR, :) = true;
mask = mask & valid;
methodMap(~valid) = 0;

result.algorithm = algorithm;
result.mask = mask;
result.power = powerMap;
result.noise = noiseMap;
result.threshold = thresholdMap;
result.snr_db = 10 * log10((powerMap + eps) ./ (noiseMap + eps));
result.alpha = alpha;
result.alpha_map = alphaMap;
result.num_training_cells = numTrainingMap;
result.edge_margin = [halfR, 0];
result.method_map = methodMap;
result.method_names = methodNames;
result.variability_index = variabilityIndex;
result.sector_mean_ratio = sectorMeanRatio;
end

function variabilityIndex = local_variability_index(powerMap, kernel, numTraining)
localSum = conv2_doppler_periodic(powerMap, kernel);
localSumSq = conv2_doppler_periodic(powerMap.^2, kernel);
localMean = localSum / numTraining;
localVariance = max(localSumSq / numTraining - localMean.^2, 0);
variabilityIndex = localVariance ./ (localMean.^2 + eps);
end
