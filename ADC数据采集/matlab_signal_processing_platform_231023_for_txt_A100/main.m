%% CTSAI-A100 MATLAB Signal Processing Example
% Unified entry point:
% ADC parsing -> Range FFT -> clutter suppression -> Doppler FFT ->
% adaptive CFAR -> sub-bin estimation -> DOA -> visualization.
clear; clc; close all;

projectRoot = fileparts(mfilename('fullpath'));
if isempty(projectRoot)
    projectRoot = pwd;
end
addpath(genpath(fullfile(projectRoot, 'functions')));
addpath(fullfile(projectRoot, 'config'));

opts = default_processing_options();
resultsDir = fullfile(projectRoot, 'results');
ensure_directory(resultsDir);

fprintf('CTSAI-A100 signal processing example\n');
fprintf('Project root: %s\n', projectRoot);
fprintf('Selected profile: %d\n', opts.profile_id);
fprintf('Clutter method: %s\n', opts.clutter.method);
fprintf('CFAR algorithm: %s\n', opts.cfar.algorithm);

%% 1. Load waveform/radar configuration
configPath = fullfile(projectRoot, 'config', ...
    sprintf('sensor_config_init%d.hxx', opts.profile_id));
radarCfg = load_ctsaia100_config(configPath);
radarCfg = derive_radar_parameters(radarCfg);
print_profile_summary(radarCfg);

%% 2. Discover and parse ADC files
profileTag = sprintf('Pf%d', opts.profile_id);
dataFiles = discover_adc_files(fullfile(projectRoot, 'data'), profileTag);
[adcRxCube, adcMeta] = load_adc_dataset(dataFiles, radarCfg, opts.io);

% Raw RX cube: [sample, raw chirp, RX]. Convert to virtual array cube when
% a TDM-MIMO waveform contains more than one transmit chirp group.
adcCube = organize_virtual_array(adcRxCube, radarCfg, opts.io.tx_chirp_layout);
fprintf('ADC cube: samples=%d, slow-time chirps=%d, channels=%d\n', ...
    size(adcCube, 1), size(adcCube, 2), size(adcCube, 3));

%% 3. Range FFT and advanced clutter suppression
[rangeCube, rangePower] = range_fft(adcCube, radarCfg, opts.range_fft);
% Keep a baseline RD map so the suppression gain can be visualized.
[~, rdPowerBeforeClutter] = doppler_fft(rangeCube, radarCfg, opts.doppler_fft);
[rangeCubeProcessed, clutterDiagnostics] = suppress_clutter( ...
    rangeCube, opts.clutter);
[rdCube, rdPower] = doppler_fft(rangeCubeProcessed, radarCfg, opts.doppler_fft);
zeroDopplerIndex = floor(size(rdPower,2)/2) + 1;
zeroDopplerBand = max(1,zeroDopplerIndex-1):min(size(rdPower,2),zeroDopplerIndex+1);
zeroPowerBeforePatch = rdPowerBeforeClutter(:,zeroDopplerBand);
zeroPowerAfterPatch = rdPower(:,zeroDopplerBand);
zeroPowerBefore = mean(zeroPowerBeforePatch(:));
zeroPowerAfter = mean(zeroPowerAfterPatch(:));
clutterDiagnostics.zero_doppler_suppression_db = 10*log10( ...
    (zeroPowerBefore+eps)/(zeroPowerAfter+eps));
fprintf(['Clutter suppression: %s, removed rank=%d, total power change=%.2f dB, ' ...
    'zero-Doppler suppression=%.2f dB\n'], ...
    clutterDiagnostics.method, clutterDiagnostics.removed_rank, ...
    clutterDiagnostics.total_power_change_db, ...
    clutterDiagnostics.zero_doppler_suppression_db);

%% 4. Adaptive CFAR detection and peak extraction
cfarResult = cfar_2d(rdPower, opts.cfar);
detections = extract_detections(cfarResult, radarCfg, opts.detection);

%% 5. Sub-bin range and velocity refinement
detections = refine_detections_subbin( ...
    detections, rdPower, radarCfg, opts.subbin);

%% 6. Angle estimation: Angle FFT, DML, MUSIC and OMP
[detections, angleDiagnostics] = estimate_angles_for_detections( ...
    rdCube, detections, radarCfg, opts.angle);

%% 7. Save tabular and MAT outputs
detectionCsv = fullfile(resultsDir, 'detections.csv');
writetable(detections, detectionCsv);

if opts.output.write_mat
    save(fullfile(resultsDir, 'processing_result.mat'), ...
        'radarCfg', 'opts', 'adcMeta', 'rangePower', ...
        'rdPowerBeforeClutter', 'rdPower', 'clutterDiagnostics', ...
        'cfarResult', 'detections', 'angleDiagnostics', '-v7.3');
end

%% 8. Visualization
plot_adc_overview(adcCube, opts.figures, resultsDir);
plot_range_spectrum(rangePower, radarCfg, opts.figures, resultsDir);
plot_clutter_suppression(rdPowerBeforeClutter, rdPower, radarCfg, ...
    clutterDiagnostics, opts.figures, resultsDir);
plot_range_doppler(rdPower, radarCfg, opts.figures, resultsDir);
plot_cfar_detections(rdPower, detections, radarCfg, opts.figures, resultsDir);
plot_cfar_diagnostics(cfarResult, radarCfg, opts.figures, resultsDir);
plot_subbin_refinement(rdPower, detections, radarCfg, opts.figures, resultsDir);
plot_angle_spectra(angleDiagnostics, opts.figures, resultsDir);
plot_target_point_cloud(detections, opts.figures, resultsDir);

fprintf('\nDetection results: %d target candidates\n', height(detections));
if ~isempty(detections)
    displayColumns = {'DetectionID','Range_m','RangeRefined_m', ...
        'Velocity_mps','VelocityRefined_mps','SNR_dB','CFARMethod', ...
        'SelectedAngle_deg'};
    disp(detections(:, displayColumns));
end
fprintf('Results saved to: %s\n', resultsDir);
