%% CTSAI-A100 MATLAB Signal Processing Example
% Unified entry point: ADC parsing -> Range FFT -> Doppler FFT -> CFAR -> DOA.
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

%% 3. Range FFT and Doppler FFT
[rangeCube, rangePower] = range_fft(adcCube, radarCfg, opts.range_fft);
[rdCube, rdPower] = doppler_fft(rangeCube, radarCfg, opts.doppler_fft);

%% 4. CFAR detection and peak extraction
cfarResult = cfar_2d(rdPower, opts.cfar);
detections = extract_detections(cfarResult, radarCfg, opts.detection);

%% 5. Angle estimation: Angle FFT, DML, MUSIC and OMP
[detections, angleDiagnostics] = estimate_angles_for_detections( ...
    rdCube, detections, radarCfg, opts.angle);

%% 6. Save tabular and MAT outputs
detectionCsv = fullfile(resultsDir, 'detections.csv');
writetable(detections, detectionCsv);

if opts.output.write_mat
    save(fullfile(resultsDir, 'processing_result.mat'), ...
        'radarCfg', 'opts', 'adcMeta', 'rangePower', 'rdPower', ...
        'cfarResult', 'detections', 'angleDiagnostics', '-v7.3');
end

%% 7. Visualization
plot_adc_overview(adcCube, opts.figures, resultsDir);
plot_range_spectrum(rangePower, radarCfg, opts.figures, resultsDir);
plot_range_doppler(rdPower, radarCfg, opts.figures, resultsDir);
plot_cfar_detections(rdPower, detections, radarCfg, opts.figures, resultsDir);
plot_angle_spectra(angleDiagnostics, opts.figures, resultsDir);
plot_target_point_cloud(detections, opts.figures, resultsDir);

fprintf('\nDetection results: %d target candidates\n', height(detections));
if ~isempty(detections)
    disp(detections);
end
fprintf('Results saved to: %s\n', resultsDir);
