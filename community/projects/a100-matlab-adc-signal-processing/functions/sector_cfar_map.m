function [mask, noiseMap, thresholdMap, alphaMap, numTrainingMap, ...
    sectorMeans, sectorMeanRatio] = sector_cfar_map( ...
    powerMap, trainR, trainD, guardR, guardD, pfa, mode)
%SECTOR_CFAR_MAP Four-sector GOCA/SOCA CFAR without toolbox dependencies.
[~, sectorKernels, sectorCounts] = ...
    build_cfar_kernels(trainR, trainD, guardR, guardD);
numSectors = size(sectorKernels,3);
sectorMeans = zeros([size(powerMap), numSectors]);
for iSector = 1:numSectors
    sectorMeans(:,:,iSector) = conv2_doppler_periodic(powerMap, ...
        sectorKernels(:,:,iSector)) / sectorCounts(iSector);
end

switch upper(mode)
    case 'GOCA'
        [noiseMap, selectedSector] = max(sectorMeans, [], 3);
    case 'SOCA'
        [noiseMap, selectedSector] = min(sectorMeans, [], 3);
    otherwise
        error('mode must be GOCA or SOCA.');
end

numTrainingMap = zeros(size(powerMap));
for iSector = 1:numSectors
    numTrainingMap(selectedSector == iSector) = sectorCounts(iSector);
end
alphaMap = cfar_alpha_ca(numTrainingMap, pfa);
thresholdMap = alphaMap .* noiseMap;
mask = powerMap > thresholdMap;
sectorMeanRatio = max(sectorMeans,[],3) ./ ...
    max(min(sectorMeans,[],3), eps);
end
