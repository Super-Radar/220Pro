function calibrated = calibrate_angle_snapshots(snapshots, phaseErrorDeg, enabled)
%CALIBRATE_ANGLE_SNAPSHOTS Remove configured per-channel phase errors.
calibrated = snapshots;
if enabled
    calibrated = snapshots .* exp(-1i * deg2rad(phaseErrorDeg(:)));
end
end
