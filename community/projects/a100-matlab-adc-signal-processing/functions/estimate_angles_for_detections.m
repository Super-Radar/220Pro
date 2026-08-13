function [detections, diagnostics] = estimate_angles_for_detections( ...
    rdCube, detections, cfg, angleOpts)
%ESTIMATE_ANGLES_FOR_DETECTIONS Run four DOA methods for every detection.
diagnostics = [];
if isempty(detections)
    detections.AngleFFT_deg = zeros(0,1);
    detections.DML_deg = zeros(0,1);
    detections.MUSIC_deg = zeros(0,1);
    detections.OMP_deg = zeros(0,1);
    detections.SelectedAngle_deg = zeros(0,1);
    return;
end

if isempty(angleOpts.grid_deg)
    left = -75; right = 75;
    if isfield(cfg, 'bfm_az_left'), left = cfg.bfm_az_left; end
    if isfield(cfg, 'bfm_az_right'), right = cfg.bfm_az_right; end
    angleGrid = left:angleOpts.grid_step_deg:right;
else
    angleGrid = angleOpts.grid_deg;
end
numChannels = size(rdCube, 3);
[positionsLambda, phaseErrorDeg] = get_array_geometry(cfg, numChannels);
dictionary = steering_dictionary(positionsLambda, angleGrid);

angleFFT = zeros(height(detections),1);
angleDML = zeros(height(detections),1);
angleMUSIC = zeros(height(detections),1);
angleOMP = zeros(height(detections),1);

for iDetection = 1:height(detections)
    r = detections.RangeBin(iDetection);
    d = detections.DopplerBin(iDetection);
    snapshot = squeeze(rdCube(r,d,:));
    snapshot = calibrate_angle_snapshots(snapshot, phaseErrorDeg, ...
        angleOpts.apply_phase_calibration);

    rHalf = angleOpts.music_snapshot_half_window(1);
    dHalf = angleOpts.music_snapshot_half_window(2);
    rIdx = max(1,r-rHalf):min(size(rdCube,1),r+rHalf);
    dIdx = max(1,d-dHalf):min(size(rdCube,2),d+dHalf);
    localData = permute(rdCube(rIdx,dIdx,:), [3,1,2]);
    localSnapshots = reshape(localData, numChannels, []);
    localSnapshots = calibrate_angle_snapshots(localSnapshots, ...
        phaseErrorDeg, angleOpts.apply_phase_calibration);

    fftResult = estimate_angle_fft(snapshot, positionsLambda, angleGrid, angleOpts);
    dmlResult = estimate_angle_dml(snapshot, dictionary, angleGrid);
    musicResult = estimate_angle_music(localSnapshots, dictionary, angleGrid, angleOpts);
    ompResult = estimate_angle_omp(snapshot, dictionary, angleGrid, angleOpts);

    angleFFT(iDetection) = fftResult.angle_deg;
    angleDML(iDetection) = dmlResult.angle_deg;
    angleMUSIC(iDetection) = musicResult.angle_deg;
    angleOMP(iDetection) = ompResult.angle_deg;

    if iDetection == 1
        diagnostics.angle_grid_deg = angleGrid;
        diagnostics.angle_fft_spectrum = fftResult.spectrum;
        diagnostics.dml_spectrum = dmlResult.spectrum;
        diagnostics.music_spectrum = musicResult.spectrum;
        diagnostics.omp_spectrum = ompResult.spectrum;
        if ismember('RangeRefined_m', detections.Properties.VariableNames)
            diagnostics.range_m = detections.RangeRefined_m(iDetection);
            diagnostics.velocity_mps = detections.VelocityRefined_mps(iDetection);
        else
            diagnostics.range_m = detections.Range_m(iDetection);
            diagnostics.velocity_mps = detections.Velocity_mps(iDetection);
        end
    end
end

detections.AngleFFT_deg = angleFFT;
detections.DML_deg = angleDML;
detections.MUSIC_deg = angleMUSIC;
detections.OMP_deg = angleOMP;
switch upper(angleOpts.selected_method)
    case 'ANGLE_FFT'
        detections.SelectedAngle_deg = angleFFT;
    case 'DML'
        detections.SelectedAngle_deg = angleDML;
    case 'MUSIC'
        detections.SelectedAngle_deg = angleMUSIC;
    case 'OMP'
        detections.SelectedAngle_deg = angleOMP;
    otherwise
        error('Unknown selected angle method: %s', angleOpts.selected_method);
end
end
