clear;
clc;
close all;

%% ============================================================
% CTSAI-A100 Issue #8
% LFMCW comprehensive simulation
%% ============================================================

thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));
addpath(fullfile(projectRoot, 'config'));

resultDir = fullfile( ...
    projectRoot, ...
    'results', ...
    'simulation');

if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

%% Configuration

cfg = simulation_config();

fprintf('\n');
fprintf('=============================================\n');
fprintf(' CTSAI-A100 Issue #8 LFMCW Simulation\n');
fprintf('=============================================\n\n');

fprintf('Carrier frequency : %.3f GHz\n', ...
    cfg.fc / 1e9);

fprintf('Bandwidth         : %.1f MHz\n', ...
    cfg.bandwidth / 1e6);

fprintf('Chirp duration    : %.1f us\n', ...
    cfg.chirp_duration * 1e6);

fprintf('Target range      : %.2f m\n', ...
    cfg.target.range_m);

fprintf('Target velocity   : %.2f m/s\n\n', ...
    cfg.target.velocity_mps);

%% ============================================================
% 1. Waveform simulation
%% ============================================================

wave = simulate_lfmcw_waveforms(cfg);

timeUs = wave.time_s * 1e6;

%% Tx waveform

fig = figure;

plot( ...
    timeUs, ...
    real(wave.tx));

xlabel('Time (\mus)');
ylabel('Amplitude');

title('Simulated LFMCW Transmitted Chirp');

grid on;

saveas(fig, fullfile( ...
    resultDir, ...
    'lfmcw_tx_waveform.png'));

close(fig);

%% Target echo

fig = figure;

plot( ...
    timeUs, ...
    real(wave.rx));

xlabel('Time (\mus)');
ylabel('Amplitude');

title('Simulated Moving-Target Echo');

grid on;

saveas(fig, fullfile( ...
    resultDir, ...
    'lfmcw_target_echo.png'));

close(fig);

%% Beat signal

fig = figure;

plot( ...
    timeUs, ...
    real(wave.beat));

xlabel('Time (\mus)');
ylabel('Amplitude');

title('Simulated LFMCW Beat Signal');

grid on;

saveas(fig, fullfile( ...
    resultDir, ...
    'lfmcw_beat_signal.png'));

close(fig);

%% ============================================================
% 2. Time-frequency plot
%% ============================================================

fig = figure;

[spectrogramDb, spectrogramTimeS, spectrogramFrequencyHz] = ...
    compute_fft_spectrogram( ...
    wave.tx, ...
    512, ...
    384, ...
    1024, ...
    wave.sample_rate_hz);

imagesc( ...
    spectrogramTimeS * 1e6, ...
    spectrogramFrequencyHz / 1e6, ...
    spectrogramDb);
axis xy;
xlabel('Time (\mus)');
ylabel('Frequency (MHz)');
colorbar;

title('LFMCW Transmitted Signal Time-Frequency Plot');

saveas(fig, fullfile( ...
    resultDir, ...
    'lfmcw_tx_spectrogram.png'));

close(fig);

%% ============================================================
% 3. Simulate full radar frame
%% ============================================================

sim = simulate_lfmcw_frame(cfg);

%% ============================================================
% 4. 2D FFT BEFORE MTI
%% ============================================================

rdBefore = ...
    process_simulated_range_doppler( ...
        sim.beat, ...
        cfg);

referencePower = ...
    max(rdBefore.power(:));

rdBeforeDb = ...
    10 * log10( ...
        (rdBefore.power + eps) / ...
        (referencePower + eps));

fig = figure;

imagesc( ...
    rdBefore.velocity_axis_mps, ...
    rdBefore.range_axis_m, ...
    rdBeforeDb);

axis xy;

xlabel('Radial Velocity (m/s)');
ylabel('Range (m)');

title('Simulated Range-Doppler Map Before MTI');

colorbar;
caxis([-60 0]);

ylim([0 80]);

saveas(fig, fullfile( ...
    resultDir, ...
    'simulation_range_doppler_before_mti.png'));

close(fig);

%% ============================================================
% 5. MTI2
%% ============================================================

rangeCube = ...
    rdBefore.range_fft;

numRangeBins = size(rangeCube, 1);
numChirps = size(rangeCube, 2);

rangeCube3D = reshape( ...
    rangeCube, ...
    numRangeBins, ...
    numChirps, ...
    1);

mtiOpts = struct();

mtiOpts.method = 'MTI2';
mtiOpts.normalize_output_power = false;

[rangeAfterMti, ~] = ...
    suppress_clutter( ...
        rangeCube3D, ...
        mtiOpts);

rangeAfterMti = reshape( ...
    rangeAfterMti, ...
    numRangeBins, ...
    numChirps);

%% Doppler FFT after MTI

dopplerWindow = make_window('hann', numChirps).';

rangeAfterMti = ...
    rangeAfterMti .* ...
    repmat( ...
        dopplerWindow, ...
        numRangeBins, ...
        1);

rdAfterMti = fftshift( ...
    fft( ...
        rangeAfterMti, ...
        numChirps, ...
        2), ...
    2);

rdAfterMtiPower = ...
    abs(rdAfterMti).^2;

% IMPORTANT:
% Same reference as BEFORE MTI.

rdAfterMtiDb = ...
    10 * log10( ...
        (rdAfterMtiPower + eps) / ...
        (referencePower + eps));

fig = figure;

imagesc( ...
    rdBefore.velocity_axis_mps, ...
    rdBefore.range_axis_m, ...
    rdAfterMtiDb);

axis xy;

xlabel('Radial Velocity (m/s)');
ylabel('Range (m)');

title('Simulated Range-Doppler Map After MTI2');

colorbar;
caxis([-60 0]);

ylim([0 80]);

saveas(fig, fullfile( ...
    resultDir, ...
    'simulation_range_doppler_after_mti.png'));

close(fig);

fprintf('Simulation completed.\n');
fprintf('Results saved to:\n%s\n\n', resultDir);
