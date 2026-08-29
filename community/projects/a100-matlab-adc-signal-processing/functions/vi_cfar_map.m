function result = vi_cfar_map(powerMap, trainR, trainD, guardR, guardD, opts)
%VI_CFAR_MAP Practical two-dimensional variability-index adaptive CFAR.
%
% The training ring is partitioned into four disjoint sectors. Each sector
% is classified as homogeneous using CV^2 = variance/mean^2. The detector:
%   1) uses CA when all sectors are homogeneous and have similar means;
%   2) uses GOCA at a clear clutter edge;
%   3) averages only homogeneous sectors when interference contaminates a
%      subset of the training ring;
%   4) falls back to GOCA when no sector is trustworthy.

[fullKernel, sectorKernels, sectorCounts] = ...
    build_cfar_kernels(trainR, trainD, guardR, guardD);
numTraining = sum(fullKernel(:));
numSectors = size(sectorKernels,3);

sectorMeans = zeros([size(powerMap), numSectors]);
sectorVariability = zeros([size(powerMap), numSectors]);
sectorSums = zeros([size(powerMap), numSectors]);
for iSector = 1:numSectors
    localSum = conv2_doppler_periodic(powerMap, ...
        sectorKernels(:,:,iSector));
    localSumSq = conv2_doppler_periodic(powerMap.^2, ...
        sectorKernels(:,:,iSector));
    localMean = localSum / sectorCounts(iSector);
    localVar = max(localSumSq / sectorCounts(iSector) - localMean.^2, 0);
    sectorSums(:,:,iSector) = localSum;
    sectorMeans(:,:,iSector) = localMean;
    sectorVariability(:,:,iSector) = localVar ./ (localMean.^2 + eps);
end

fullSum = conv2_doppler_periodic(powerMap, fullKernel);
fullSumSq = conv2_doppler_periodic(powerMap.^2, fullKernel);
fullMean = fullSum / numTraining;
fullVar = max(fullSumSq / numTraining - fullMean.^2, 0);
variabilityIndex = fullVar ./ (fullMean.^2 + eps);
sectorMeanRatio = max(sectorMeans,[],3) ./ ...
    max(min(sectorMeans,[],3), eps);

homogeneous = sectorVariability <= opts.vi_threshold;
numHomogeneous = sum(homogeneous, 3);
allHomogeneous = numHomogeneous == numSectors;
useCA = allHomogeneous & sectorMeanRatio <= opts.mean_ratio_threshold;
useGOCA = allHomogeneous & sectorMeanRatio > opts.mean_ratio_threshold;
useSelected = ~allHomogeneous & ...
    numHomogeneous >= opts.min_homogeneous_sectors;
useFallback = ~(useCA | useGOCA | useSelected);

selectedSum = zeros(size(powerMap));
selectedCount = zeros(size(powerMap));
for iSector = 1:numSectors
    isSelected = homogeneous(:,:,iSector);
    selectedSum = selectedSum + sectorSums(:,:,iSector) .* isSelected;
    selectedCount = selectedCount + sectorCounts(iSector) .* isSelected;
end
selectedMean = selectedSum ./ max(selectedCount, 1);

[maxSectorMean, maxSector] = max(sectorMeans, [], 3);
maxSectorCount = zeros(size(powerMap));
for iSector = 1:numSectors
    maxSectorCount(maxSector == iSector) = sectorCounts(iSector);
end

noiseMap = zeros(size(powerMap));
numTrainingMap = zeros(size(powerMap));
methodMap = zeros(size(powerMap), 'uint8');

noiseMap(useCA) = fullMean(useCA);
numTrainingMap(useCA) = numTraining;
methodMap(useCA) = 1; % CA

noiseMap(useGOCA) = maxSectorMean(useGOCA);
numTrainingMap(useGOCA) = maxSectorCount(useGOCA);
methodMap(useGOCA) = 2; % GOCA clutter edge

noiseMap(useSelected) = selectedMean(useSelected);
numTrainingMap(useSelected) = selectedCount(useSelected);
methodMap(useSelected) = 3; % Homogeneous-sector selection

noiseMap(useFallback) = maxSectorMean(useFallback);
numTrainingMap(useFallback) = maxSectorCount(useFallback);
methodMap(useFallback) = 4; % Conservative fallback

alphaMap = cfar_alpha_ca(numTrainingMap, opts.pfa);
thresholdMap = alphaMap .* noiseMap;
mask = powerMap > thresholdMap;

result.mask = mask;
result.noise = noiseMap;
result.threshold = thresholdMap;
result.alpha = alphaMap;
result.num_training_cells = numTrainingMap;
result.method_map = methodMap;
result.method_names = {'INVALID','CA','GOCA','VI_SELECTED','GOCA_FALLBACK'};
result.variability_index = variabilityIndex;
result.sector_mean_ratio = sectorMeanRatio;
result.sector_variability = sectorVariability;
result.sector_means = sectorMeans;
end
