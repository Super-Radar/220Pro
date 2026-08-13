clear;
clc;

%% Locate project root

thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));

%% Configuration

configFile = fullfile( ...
    projectRoot, ...
    'config', ...
    'sensor_config_init0.hxx');

fprintf('\n');
fprintf('=============================================\n');
fprintf(' CTSAI-A100 Measured Physical Axis Check\n');
fprintf('=============================================\n\n');

fprintf('Configuration:\n%s\n\n', configFile);

cfg = load_ctsaia100_config(configFile);

%% Use dimensions confirmed by measured dataset inspection

numSamples = 1024;
numChirps = 256;

axesInfo = derive_measured_axes( ...
    cfg, ...
    numSamples, ...
    numChirps);

%% Print configuration

fprintf('Radar configuration\n');
fprintf('---------------------------------------------\n');

fprintf('Start frequency       : %.3f GHz\n', ...
    cfg.fmcw_startfreq);

fprintf('FMCW bandwidth        : %.3f MHz\n', ...
    cfg.fmcw_bandwidth);

fprintf('Chirp ramp-up         : %.3f us\n', ...
    cfg.fmcw_chirp_rampup);

fprintf('Chirp period          : %.3f us\n', ...
    cfg.fmcw_chirp_period);

fprintf('ADC frequency         : %.3f MHz\n', ...
    cfg.adc_freq);

fprintf('Range FFT size        : %d\n', ...
    round(cfg.rng_nfft));

fprintf('Velocity FFT size     : %d\n', ...
    round(cfg.vel_nfft));

fprintf('TX mode               : %s\n', ...
    axesInfo.tx_mode);

fprintf('TX chirp groups       : %d\n\n', ...
    axesInfo.tx_group_count);

%% Physical axes

fprintf('Derived physical axes\n');
fprintf('---------------------------------------------\n');

fprintf('Wavelength            : %.6f m\n', ...
    axesInfo.lambda_m);

fprintf('Range resolution      : %.6f m/bin\n', ...
    axesInfo.range_resolution_m);

fprintf('Maximum plotted range : %.3f m\n', ...
    axesInfo.max_range_m);

fprintf('Velocity resolution   : %.6f m/s/bin\n', ...
    axesInfo.velocity_resolution_mps);

fprintf('Unambiguous velocity  : +/- %.3f m/s\n', ...
    axesInfo.max_unambiguous_velocity_mps);

fprintf('\n');

fprintf('Range axis:\n');
fprintf('  first = %.3f m\n', ...
    axesInfo.range_axis_m(1));

fprintf('  last  = %.3f m\n', ...
    axesInfo.range_axis_m(end));

fprintf('\n');

fprintf('Velocity axis:\n');
fprintf('  first = %.3f m/s\n', ...
    axesInfo.velocity_axis_mps(1));

fprintf('  zero  = %.3f m/s\n', ...
    axesInfo.velocity_axis_mps( ...
        floor(numel(axesInfo.velocity_axis_mps)/2)+1));

fprintf('  last  = %.3f m/s\n', ...
    axesInfo.velocity_axis_mps(end));

fprintf('\n');
fprintf('Physical axis check completed.\n');
fprintf('=============================================\n');