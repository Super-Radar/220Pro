clear;
clc;

% 验证空 range 或 Doppler 搜索域会明确失败，而不是返回 -Inf 伪峰值。
thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);
addpath(genpath(fullfile(projectRoot, 'functions')));

configFile = fullfile(projectRoot, 'config', 'sensor_config_init0.hxx');
sampleFile = fullfile(projectRoot, 'data', 'measured', 'empty', ...
    'run_001_Pf0_Rx0.txt');
cfg = load_ctsaia100_config(configFile);

opts = struct('zero_half_width_bins', 2, ...
    'range_guard_bins', 100000, 'allow_zero_pad', false);
expect_error(@() analyze_measured_rx_file(sampleFile, cfg, opts), ...
    'a100:EmptyPeakSearchRange');

opts.range_guard_bins = 2;
opts.zero_half_width_bins = 100000;
expect_error(@() analyze_measured_rx_file(sampleFile, cfg, opts), ...
    'a100:EmptyPeakSearchDoppler');

fprintf('Peak-search guard checks passed.\n');

function expect_error(callback, expectedIdentifier)
try
    callback();
catch errorInfo
    assert(strcmp(errorInfo.identifier, expectedIdentifier), ...
        'Expected %s, received %s.', expectedIdentifier, errorInfo.identifier);
    return;
end
error('Expected error %s was not raised.', expectedIdentifier);
end
