%% CTSAI-A100 reproducible ADC signal-processing demo
% Run this file from any working directory. Results are written to results/.
clear; clc; close all;

projectDir = fileparts(mfilename('fullpath'));
addpath(fullfile(projectDir, 'functions'));

profileName = 'near';       % 'near' or 'far'
maxDetections = 32;
cfg = ctsai_config(profileName, projectDir);

fprintf('CTSAI-A100 profile: %s\n', cfg.name);
fprintf('Loading four public ADC channels...\n');
adc = load_ctsai_adc(cfg.dataFiles, cfg);

fprintf('Running range/Doppler processing...\n');
out = process_radar_cube(adc, cfg);

fprintf('Running 2-D CA-CFAR...\n');
[cfarMask, thresholdDb] = ca_cfar_2d(out.rdPower, cfg.cfar);
detections = build_detection_table(cfarMask, out.rdPowerDb, ...
    out.rangeAxis, out.velocityAxis, out.rdCube, cfg, maxDetections);

if ~exist(cfg.resultsDir, 'dir')
    mkdir(cfg.resultsDir);
end
writetable(detections, fullfile(cfg.resultsDir, 'detections.csv'));
save(fullfile(cfg.resultsDir, 'processing_result.mat'), ...
    'cfg', 'out', 'cfarMask', 'thresholdDb', 'detections', '-v7.3');

plot_results(out, cfarMask, detections, cfg);

fprintf('\nDetected %d targets (limited to %d strongest).\n', ...
    height(detections), maxDetections);
disp(detections);
fprintf('Results: %s\n', cfg.resultsDir);
