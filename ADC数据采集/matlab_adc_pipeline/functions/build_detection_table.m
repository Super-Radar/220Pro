function detections = build_detection_table(mask, powerDb, rangeAxis, ...
    velocityAxis, rdCube, cfg, maxDetections)
%BUILD_DETECTION_TABLE Convert CFAR cells into range/velocity/angle rows.

[r, d] = find(mask);
if isempty(r)
    detections = table([], [], [], [], ...
        'VariableNames', {'range_m','velocity_mps','angle_deg','power_db'});
    return;
end

linear = sub2ind(size(powerDb), r, d);
[~, order] = sort(powerDb(linear), 'descend');
order = order(1:min(maxDetections, numel(order)));
r = r(order); d = d(order); linear = linear(order);

angles = zeros(numel(r),1);
for k = 1:numel(r)
    phaseSnapshot = squeeze(rdCube(r(k), d(k), :));
    angleSpectrum = abs(fftshift(fft(phaseSnapshot, cfg.angleNfft)));
    [~, peak] = max(angleSpectrum);
    spatial = ((peak-1) - cfg.angleNfft/2) / cfg.angleNfft;
    sinTheta = spatial / cfg.rxSpacingLambda;
    angles(k) = asind(max(-1, min(1, sinTheta)));
end

detections = table(rangeAxis(r), velocityAxis(d).', angles, powerDb(linear), ...
    'VariableNames', {'range_m','velocity_mps','angle_deg','power_db'});
end
