function metrics = run_simulation(project_root)
%RUN_SIMULATION Generate the required LFMCW, FFT, and MTI result figures.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end
addpath(fullfile(project_root, 'src'));
env = prepare_environment(project_root);
cfg = default_simulation_config();
scene = simulate_lfmcw_scene(cfg);
before = compute_range_doppler(scene.beat, cfg, 0);
after = compute_range_doppler(scene.beat, cfg, cfg.mti_order);

plot_reference_waveforms(scene, env.figures_dir);
plot_time_frequency(scene, env.figures_dir);
plot_range_fft(scene, before, env.figures_dir);
plot_range_doppler(scene, before, after, env.figures_dir);

[cart_range_error_m, cart_velocity_error_mps] = target_peak_error(before, cfg.targets(1));
zero_velocity = abs(before.velocity_axis_mps) == min(abs(before.velocity_axis_mps));
static_before = max(abs(before.rd_complex(:, zero_velocity))(:));
static_after = max(abs(after.rd_complex(:, zero_velocity))(:));
static_suppression_db = 20 * log10((static_before + eps) / (static_after + eps));

metrics = struct('range_resolution_m', cfg.c / (2 * cfg.bandwidth_hz), ...
                 'velocity_resolution_mps', ...
                    (cfg.c / cfg.fc_hz) / (2 * cfg.num_chirps * cfg.chirp_repetition_s), ...
                 'cart_range_error_m', cart_range_error_m, ...
                 'cart_velocity_error_mps', cart_velocity_error_mps, ...
                 'static_suppression_db', static_suppression_db);

metrics_path = fullfile(env.results_dir, 'simulation_metrics.csv');
fid = fopen(metrics_path, 'w');
if fid < 0
    error('a100:MetricsOpenFailed', 'Could not write %s.', metrics_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'metric,value,unit\n');
fprintf(fid, 'range_resolution,%.9g,m\n', metrics.range_resolution_m);
fprintf(fid, 'velocity_resolution,%.9g,m/s\n', metrics.velocity_resolution_mps);
fprintf(fid, 'cart_range_error,%.9g,m\n', metrics.cart_range_error_m);
fprintf(fid, 'cart_velocity_error,%.9g,m/s\n', metrics.cart_velocity_error_mps);
fprintf(fid, 'static_suppression,%.9g,dB\n', metrics.static_suppression_db);
clear cleanup;

fprintf('Simulation: range error %.3f m, velocity error %.3f m/s, MTI static suppression %.1f dB.\n', ...
    cart_range_error_m, cart_velocity_error_mps, static_suppression_db);
end

function plot_reference_waveforms(scene, figures_dir)
ref = scene.reference;
if isempty(ref.time_s)
    return;
end
max_points = min(numel(ref.time_s), round(2e-6 * ref.sample_rate_hz));
indices = 1:max_points;
time_us = ref.time_s(indices) * 1e6;
fig = figure('position', [100 100 1100 800]);
subplot(3, 1, 1);
plot(time_us, real(ref.transmit(indices)), 'b'); grid on;
xlabel('Fast time (\mus)'); ylabel('Amplitude'); title('Complex-baseband LFM transmit signal (real part)');
subplot(3, 1, 2);
plot(time_us, real(ref.echo(indices)), 'r'); grid on;
xlabel('Fast time (\mus)'); ylabel('Amplitude'); title('Multi-target delayed echo (real part)');
subplot(3, 1, 3);
plot(time_us, real(ref.beat(indices)), 'k'); grid on;
xlabel('Fast time (\mus)'); ylabel('Amplitude'); title('Dechirped beat signal (real part)');
save_png(fig, fullfile(figures_dir, 'simulation_waveforms.png'));
end

function plot_time_frequency(scene, figures_dir)
ref = scene.reference;
if isempty(ref.time_s)
    return;
end
window_length = 2048;
overlap = 1536;
nfft = 4096;
if exist('spectrogram', 'file') == 2
    [spectrum, frequency_hz, time_s] = spectrogram(ref.transmit, ...
        hann(window_length), overlap, nfft, ref.sample_rate_hz);
else
    [spectrum, frequency_hz, time_s] = specgram(ref.transmit, nfft, ...
        ref.sample_rate_hz, hann(window_length), overlap);
end
fig = figure('position', [100 100 1100 650]);
imagesc(time_s * 1e6, frequency_hz / 1e6, db_normalize(spectrum, -60));
axis xy; colormap(jet); colorbar; caxis([-60 0]);
xlabel('Fast time (\mus)'); ylabel('Baseband frequency (MHz)');
title('LFM transmit-signal time-frequency representation');
save_png(fig, fullfile(figures_dir, 'simulation_time_frequency.png'));
end

function plot_range_fft(scene, before, figures_dir)
cfg = scene.config;
fig = figure('position', [100 100 1100 650]);
plot(before.range_axis_m, db_normalize(before.range_profile, -70), 'b', 'linewidth', 1.2);
grid on; xlim([0 12]); ylim([-70 2]);
xlabel('Range (m)'); ylabel('Normalized magnitude (dB)');
title('Range FFT averaged across chirps');
hold on;
for idx = 1:numel(cfg.targets)
    plot([cfg.targets(idx).range_m cfg.targets(idx).range_m], [-70 0], '--k');
end
hold off;
save_png(fig, fullfile(figures_dir, 'simulation_range_fft.png'));
end

function plot_range_doppler(scene, before, after, figures_dir)
cfg = scene.config;
fig = figure('position', [100 100 1300 600]);
subplot(1, 2, 1);
imagesc(before.velocity_axis_mps, before.range_axis_m, before.rd_db);
axis xy; ylim([0 12]); xlim([-1.5 1.5]); caxis([-60 0]); colormap(jet); colorbar;
xlabel('Velocity (m/s; + receding)'); ylabel('Range (m)'); title('Before MTI');
subplot(1, 2, 2);
imagesc(after.velocity_axis_mps, after.range_axis_m, after.rd_db);
axis xy; ylim([0 12]); xlim([-1.5 1.5]); caxis([-60 0]); colormap(jet); colorbar;
xlabel('Velocity (m/s; + receding)'); ylabel('Range (m)');
title(sprintf('After %d-stage MTI', cfg.mti_order));
save_png(fig, fullfile(figures_dir, 'simulation_range_doppler_mti.png'));
end

function [range_error_m, velocity_error_mps] = target_peak_error(result, target)
range_mask = abs(result.range_axis_m - target.range_m) <= 0.8;
velocity_mask = abs(result.velocity_axis_mps - target.velocity_mps) <= 0.5;
local = abs(result.rd_complex(range_mask, velocity_mask));
[~, linear_idx] = max(local(:));
[range_local_idx, velocity_local_idx] = ind2sub(size(local), linear_idx);
range_indices = find(range_mask);
velocity_indices = find(velocity_mask);
estimated_range = result.range_axis_m(range_indices(range_local_idx));
estimated_velocity = result.velocity_axis_mps(velocity_indices(velocity_local_idx));
range_error_m = abs(estimated_range - target.range_m);
velocity_error_mps = abs(estimated_velocity - target.velocity_mps);
end
