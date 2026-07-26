function detections = build_detection_table(mask, powerDb, rangeAxis, ...
    dopplerBinAxis, nominalVelocityAxis, rdCube, cfg, maxDetections)
%BUILD_DETECTION_TABLE Export valid measurements without inventing DDMA data.

[r, d] = find(mask);
if isempty(r)
    detections = table([], [], [], [], [], false(0,1), cell(0,1), ...
        'VariableNames', {'range_m','doppler_bin','velocity_mps', ...
        'angle_deg','power_db','kinematics_valid','processing_status'});
    return;
end

linear = sub2ind(size(powerDb), r, d);
[~, order] = sort(powerDb(linear), 'descend');
order = order(1:min(maxDetections, numel(order)));
r = r(order); d = d(order); linear = linear(order);

dopplerBins = dopplerBinAxis(d).';
velocity = nan(numel(r), 1);
angles = nan(numel(r), 1);
status = repmat({'raw_ddma_not_decoded'}, numel(r), 1);
valid = false(numel(r), 1);

if cfg.mimo.velocityValid
    velocity = nominalVelocityAxis(d).';
end
if cfg.mimo.angleValid
    for k = 1:numel(r)
        snapshot = squeeze(rdCube(r(k), d(k), :));
        angles(k) = estimate_angle_fft(snapshot, ...
            cfg.mimo.rxSpacingLambda, cfg.angleNfft);
    end
end
if cfg.mimo.velocityValid && cfg.mimo.angleValid
    valid(:) = true;
    status(:) = {'decoded_and_calibrated'};
end

detections = table(rangeAxis(r), dopplerBins, velocity, angles, ...
    powerDb(linear), valid, status, ...
    'VariableNames', {'range_m','doppler_bin','velocity_mps', ...
    'angle_deg','power_db','kinematics_valid','processing_status'});
end
