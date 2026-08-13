function detections = run_ctsai_a100_demo(profileName)
%RUN_CTSAI_A100_DEMO Reproducible ADC signal-processing entry point.
%   run_ctsai_a100_demo() processes the near profile.
%   run_ctsai_a100_demo('far') processes the far profile.

if nargin < 1
    profileName = 'near';
end
clc; close all;

projectDir = fileparts(mfilename('fullpath'));
addpath(fullfile(projectDir, 'src'));

maxDetections = 32;
cfg = ctsai_config(profileName, projectDir);

fprintf('CTSAI-A100 profile: %s\n', cfg.name);
fprintf('Official configuration: %s\n', cfg.sourceConfigFile);
if ~cfg.mimo.metadataComplete
    warning('CTSAI:UnresolvedDDMA', ...
        ['DDMA metadata is incomplete. Range and raw Doppler-bin results ' ...
        'will be exported; physical velocity and angle will remain NaN.']);
end
fprintf('Loading four public ADC channels...\n');
adc = load_ctsai_adc(cfg.dataFiles, cfg);

fprintf('Running range/Doppler processing...\n');
out = process_radar_cube(adc, cfg);

fprintf('Running 2-D CA-CFAR...\n');
[cfarMask, thresholdDb] = ca_cfar_2d(out.rdPower, cfg.cfar);
detections = build_detection_table(cfarMask, out.rdPowerDb, ...
    out.rangeAxis, out.dopplerBinAxis, out.nominalTdmVelocityAxis, ...
    out.rdCube, cfg, maxDetections);

if ~exist(cfg.resultsDir, 'dir')
    mkdir(cfg.resultsDir);
end
writetable(detections, fullfile(cfg.resultsDir, 'detections.csv'));
write_configuration_report(cfg, fullfile(cfg.resultsDir, ...
    'configuration_report.txt'));
save(fullfile(cfg.resultsDir, 'processing_result.mat'), ...
    'cfg', 'out', 'cfarMask', 'thresholdDb', 'detections', '-v7.3');

plot_results(out, cfarMask, detections, cfg);

fprintf('\nDetected %d targets (limited to %d strongest).\n', ...
    height(detections), maxDetections);
disp(detections);
fprintf('Results: %s\n', cfg.resultsDir);
end

function write_configuration_report(cfg, outputFile)
fid = fopen(outputFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'profile=%s\n', cfg.name);
fprintf(fid, 'source_config=%s\n', cfg.sourceConfigFile);
fprintf(fid, 'tx_groups=%s\n', mat2str(cfg.txGroups));
fprintf(fid, 'mimo_mode=%s\n', cfg.mimo.mode);
fprintf(fid, 'metadata_complete=%d\n', cfg.mimo.metadataComplete);
fprintf(fid, 'physical_velocity_valid=%d\n', cfg.mimo.velocityValid);
fprintf(fid, 'angle_valid=%d\n', cfg.mimo.angleValid);
fprintf(fid, 'missing_metadata:\n');
for k = 1:numel(cfg.mimo.missingMetadata)
    fprintf(fid, '- %s\n', cfg.mimo.missingMetadata{k});
end
end
