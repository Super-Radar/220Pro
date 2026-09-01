function detections = extract_detections(cfarResult, cfg, detOpts)
%EXTRACT_DETECTIONS Local-maximum filtering and physical-unit conversion.
mask = cfarResult.mask;
powerMap = cfarResult.power;
noiseMap = cfarResult.noise;

rangeValid = cfg.range_axis_m >= detOpts.min_range_m & ...
    cfg.range_axis_m <= min(detOpts.max_range_m, cfg.max_range_m);
mask(~rangeValid, :) = false;
zeroIdx = floor(size(mask,2)/2) + 1;
zeroHalf = detOpts.zero_doppler_exclusion_bins;
mask(:, max(1,zeroIdx-zeroHalf):min(size(mask,2),zeroIdx+zeroHalf)) = false;

[rowList, colList] = find(mask);
keep = false(size(rowList));
peakHalfR = detOpts.local_peak_half_window(1);
peakHalfD = detOpts.local_peak_half_window(2);
for i = 1:numel(rowList)
    r = rowList(i); d = colList(i);
    rIdx = max(1,r-peakHalfR):min(size(powerMap,1),r+peakHalfR);
    % Doppler 首尾相邻，局部峰值窗口必须跨 FFT 端点比较。
    dIdx = mod((d-peakHalfD:d+peakHalfD)-1, size(powerMap,2)) + 1;
    patch = powerMap(rIdx, dIdx);
    keep(i) = powerMap(r,d) >= max(patch(:));
end
rowList = rowList(keep);
colList = colList(keep);

if isempty(rowList)
    detections = empty_detection_table();
    return;
end
snrDb = 10*log10((powerMap(sub2ind(size(powerMap),rowList,colList))+eps) ./ ...
    (noiseMap(sub2ind(size(noiseMap),rowList,colList))+eps));
snrKeep = snrDb >= detOpts.min_snr_db;
rowList = rowList(snrKeep); colList = colList(snrKeep); snrDb = snrDb(snrKeep);
if isempty(rowList)
    detections = empty_detection_table();
    return;
end
[~, order] = sort(snrDb, 'descend');
rowList = rowList(order); colList = colList(order); snrDb = snrDb(order);

selected = false(size(rowList));
selectedRows = [];
selectedCols = [];
for i = 1:numel(rowList)
    r = rowList(i); d = colList(i);
    accept = true;
    for j = 1:numel(selectedRows)
        rangeDistance = abs(r - selectedRows(j));
        dopplerDistance = abs(d - selectedCols(j));
        dopplerDistance = min(dopplerDistance, size(powerMap,2)-dopplerDistance);
        if rangeDistance <= detOpts.min_separation_bins(1) && ...
                dopplerDistance <= detOpts.min_separation_bins(2)
            accept = false;
            break;
        end
    end
    if accept
        selected(i) = true;
        selectedRows(end+1) = r; %#ok<AGROW>
        selectedCols(end+1) = d; %#ok<AGROW>
        if numel(selectedRows) >= detOpts.max_detections
            break;
        end
    end
end
rowList = rowList(selected); colList = colList(selected); snrDb = snrDb(selected);
idx = sub2ind(size(powerMap), rowList, colList);
numDet = numel(rowList);

methodCode = double(cfarResult.method_map(idx));
methodName = repmat({cfarResult.algorithm}, numDet, 1);
if isfield(cfarResult, 'method_names') && ~isempty(cfarResult.method_names)
    for i = 1:numDet
        codeIndex = methodCode(i) + 1;
        if codeIndex >= 1 && codeIndex <= numel(cfarResult.method_names)
            methodName{i} = cfarResult.method_names{codeIndex};
        end
    end
end

thresholdDb = 10*log10(cfarResult.threshold(idx)+eps);
variabilityIndex = cfarResult.variability_index(idx);
sectorMeanRatio = cfarResult.sector_mean_ratio(idx);

detections = table((1:numDet).', rowList, colList, ...
    cfg.range_axis_m(rowList).', cfg.velocity_axis_mps(colList).', ...
    10*log10(powerMap(idx)+eps), 10*log10(noiseMap(idx)+eps), ...
    thresholdDb, snrDb, methodCode, methodName, variabilityIndex, ...
    sectorMeanRatio, ...
    'VariableNames', {'DetectionID','RangeBin','DopplerBin','Range_m', ...
    'Velocity_mps','Power_dB','Noise_dB','Threshold_dB','SNR_dB', ...
    'CFARMethodCode','CFARMethod','VariabilityIndex','SectorMeanRatio'});
end

function t = empty_detection_table()
t = table('Size',[0,13], ...
    'VariableTypes', {'double','double','double','double','double', ...
    'double','double','double','double','double','cell','double','double'}, ...
    'VariableNames', {'DetectionID','RangeBin','DopplerBin','Range_m', ...
    'Velocity_mps','Power_dB','Noise_dB','Threshold_dB','SNR_dB', ...
    'CFARMethodCode','CFARMethod','VariabilityIndex','SectorMeanRatio'});
end
