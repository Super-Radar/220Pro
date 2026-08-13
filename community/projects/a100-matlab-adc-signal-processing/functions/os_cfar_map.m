function [mask, noiseMap, thresholdMap, alpha, numTraining] = ...
    os_cfar_map(powerMap, trainR, trainD, guardR, guardD, rankRatio, pfa)
%OS_CFAR_MAP Reference OS-CFAR implementation without toolbox dependencies.
halfR = trainR + guardR;
halfD = trainD + guardD;
offsets = zeros((2*halfR+1)*(2*halfD+1), 2);
n = 0;
for dR = -halfR:halfR
    for dD = -halfD:halfD
        if abs(dR) <= guardR && abs(dD) <= guardD
            continue;
        end
        n = n + 1;
        offsets(n, :) = [dR, dD];
    end
end
offsets = offsets(1:n, :);
numTraining = size(offsets, 1);
rankIndex = max(1, min(numTraining, ceil(rankRatio * numTraining)));
alpha = os_cfar_alpha(numTraining, rankIndex, pfa);
noiseMap = nan(size(powerMap));
thresholdMap = nan(size(powerMap));
mask = false(size(powerMap));

for iRange = halfR+1:size(powerMap,1)-halfR
    for iDoppler = halfD+1:size(powerMap,2)-halfD
        training = zeros(numTraining, 1);
        for iCell = 1:numTraining
            training(iCell) = powerMap(iRange + offsets(iCell,1), ...
                iDoppler + offsets(iCell,2));
        end
        training = sort(training, 'ascend');
        noiseValue = training(rankIndex);
        thresholdValue = alpha * noiseValue;
        noiseMap(iRange, iDoppler) = noiseValue;
        thresholdMap(iRange, iDoppler) = thresholdValue;
        mask(iRange, iDoppler) = powerMap(iRange, iDoppler) > thresholdValue;
    end
end
end
