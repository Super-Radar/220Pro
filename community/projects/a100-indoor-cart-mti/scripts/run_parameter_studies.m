function rows = run_parameter_studies(project_root)
%RUN_PARAMETER_STUDIES Analyze six requested LFMCW/MTI parameter families.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end
addpath(fullfile(project_root, 'src'));
env = prepare_environment(project_root);
base = default_simulation_config();
base.generate_reference_waveforms = false;

rows = {};

bandwidths = [0.5e9, 1.0e9, 1.5e9];
band_eval = cell(size(bandwidths));
for idx = 1:numel(bandwidths)
    cfg = base; cfg.bandwidth_hz = bandwidths(idx);
    band_eval{idx} = evaluate_simulation_case(cfg, 1);
    rows(end + 1, :) = make_row('bandwidth', bandwidths(idx), 'Hz', band_eval{idx}); %#ok<AGROW>
end
plot_bandwidth(bandwidths, band_eval, env.figures_dir);

durations = [40e-6, 60e-6, 80e-6];
duration_eval = cell(size(durations));
fixed_sample_rate_hz = base.num_samples / base.chirp_duration_s;
for idx = 1:numel(durations)
    cfg = base;
    cfg.chirp_duration_s = durations(idx);
    cfg.chirp_repetition_s = durations(idx) + 10e-6;
    cfg.num_samples = 2 * round(fixed_sample_rate_hz * durations(idx) / 2);
    cfg.sample_rate_hz = cfg.num_samples / cfg.chirp_duration_s;
    duration_eval{idx} = evaluate_simulation_case(cfg, 1);
    rows(end + 1, :) = make_row('chirp_duration', durations(idx), 's', duration_eval{idx}); %#ok<AGROW>
end
plot_duration(durations, duration_eval, env.figures_dir);

prfs_hz = [8e3, 12e3, 1 / base.chirp_repetition_s];
prf_eval = cell(size(prfs_hz));
for idx = 1:numel(prfs_hz)
    cfg = base; cfg.chirp_repetition_s = 1 / prfs_hz(idx);
    prf_eval{idx} = evaluate_simulation_case(cfg, 1);
    rows(end + 1, :) = make_row('prf', prfs_hz(idx), 'Hz', prf_eval{idx}); %#ok<AGROW>
end
plot_prf(prfs_hz, prf_eval, env.figures_dir);

velocities = [-0.15, -0.35, -0.70];
velocity_eval = cell(size(velocities));
for idx = 1:numel(velocities)
    cfg = base; cfg.targets(1).velocity_mps = velocities(idx);
    velocity_eval{idx} = evaluate_simulation_case(cfg, 1);
    rows(end + 1, :) = make_row('target_velocity', velocities(idx), 'm/s', velocity_eval{idx}); %#ok<AGROW>
end
plot_velocity(velocities, velocity_eval, env.figures_dir);

target_counts = [1, 2, 4];
count_eval = cell(size(target_counts));
for idx = 1:numel(target_counts)
    cfg = base; cfg.targets = base.targets(1:target_counts(idx));
    count_eval{idx} = evaluate_simulation_case(cfg, 1);
    rows(end + 1, :) = make_row('target_count', target_counts(idx), 'count', count_eval{idx}); %#ok<AGROW>
end
plot_target_count(target_counts, count_eval, env.figures_dir);

mti_orders = [0, 1, 2, 3];
mti_eval = cell(size(mti_orders));
for idx = 1:numel(mti_orders)
    mti_eval{idx} = evaluate_simulation_case(base, mti_orders(idx));
    rows(end + 1, :) = make_row('mti_order', mti_orders(idx), 'order', mti_eval{idx}); %#ok<AGROW>
end
plot_mti_order(mti_orders, mti_eval, env.figures_dir);

write_summary(fullfile(env.results_dir, 'parameter_studies.csv'), rows);
fprintf('Parameter studies: %d deterministic cases across six parameter families.\n', size(rows, 1));
end
function row = make_row(parameter, value, unit, evaluation)
row = {parameter, value, unit, evaluation.range_resolution_m, ...
       evaluation.velocity_resolution_mps, evaluation.max_unambiguous_velocity_mps, ...
       evaluation.max_unambiguous_range_m, evaluation.cart_beat_frequency_hz, ...
       evaluation.detected_range_m, evaluation.detected_velocity_mps, ...
       evaluation.moving_retention_db, evaluation.static_suppression_db, ...
       evaluation.target_count, evaluation.mti_order};
end

function write_summary(file_path, rows)
fid = fopen(file_path, 'w');
if fid < 0
    error('a100:ParameterSummaryOpenFailed', 'Could not write %s.', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['parameter,value,value_unit,range_resolution_m,velocity_resolution_mps,' ...
              'max_unambiguous_velocity_mps,max_unambiguous_range_m,cart_beat_frequency_hz,' ...
              'detected_range_m,detected_velocity_mps,moving_retention_db,' ...
              'static_suppression_db,target_count,mti_order\n']);
for idx = 1:size(rows, 1)
    fprintf(fid, '%s,%.12g,%s', rows{idx, 1}, rows{idx, 2}, rows{idx, 3});
    for column = 4:14
        fprintf(fid, ',%.12g', rows{idx, column});
    end
    fprintf(fid, '\n');
end
clear cleanup;
end

function plot_bandwidth(values, evaluations, figures_dir)
fig = figure('position', [100 100 1150 650]);
subplot(1, 2, 1); hold on;
colors = {'b', 'r', 'k'};
for idx = 1:numel(values)
    plot(evaluations{idx}.range_axis_m, evaluations{idx}.range_profile_db, colors{idx});
end
hold off; grid on; xlim([4.5 7.5]); ylim([-65 2]);
xlabel('Range (m)'); ylabel('Normalized magnitude (dB)'); title('Range peaks versus bandwidth');
legend('0.5 GHz', '1.0 GHz', '1.5 GHz', 'location', 'southwest');
subplot(1, 2, 2);
plot(values / 1e9, collect(evaluations, 'range_resolution_m'), '-ob', 'linewidth', 1.3);
grid on; xlabel('Bandwidth (GHz)'); ylabel('c/(2B) resolution (m)');
title('Wider bandwidth improves range resolution');
save_png(fig, fullfile(figures_dir, 'parameter_bandwidth.png'));
end

function plot_duration(values, evaluations, figures_dir)
fig = figure('position', [100 100 1150 650]);
subplot(1, 2, 1);
plot(values * 1e6, collect(evaluations, 'cart_beat_frequency_hz') / 1e6, '-or', 'linewidth', 1.3);
grid on; xlabel('Chirp duration (\mus)'); ylabel('Cart beat frequency (MHz)');
title('Longer chirp lowers slope and beat frequency');
subplot(1, 2, 2);
plot(values * 1e6, collect(evaluations, 'max_unambiguous_range_m'), '-ob', 'linewidth', 1.3);
grid on; xlabel('Chirp duration (\mus)'); ylabel('ADC-limited unambiguous range (m)');
title('At fixed ADC rate, longer chirp extends range');
save_png(fig, fullfile(figures_dir, 'parameter_chirp_duration.png'));
end

function plot_prf(values, evaluations, figures_dir)
fig = figure('position', [100 100 1150 650]);
subplot(1, 2, 1);
plot(values / 1e3, collect(evaluations, 'max_unambiguous_velocity_mps'), '-ob', 'linewidth', 1.3);
grid on; xlabel('PRF (kHz)'); ylabel('Unambiguous velocity (m/s)');
title('Higher PRF expands velocity interval');
subplot(1, 2, 2);
plot(values / 1e3, collect(evaluations, 'velocity_resolution_mps'), '-or', 'linewidth', 1.3);
grid on; xlabel('PRF (kHz)'); ylabel('Velocity-bin spacing (m/s)');
title('With fixed chirp count, higher PRF coarsens bins');
save_png(fig, fullfile(figures_dir, 'parameter_prf.png'));
end

function plot_velocity(values, evaluations, figures_dir)
fig = figure('position', [100 100 1100 650]);
subplot(1, 2, 1);
plot(abs(values), collect(evaluations, 'moving_retention_db'), '-ob', 'linewidth', 1.3);
grid on; xlabel('Target speed magnitude (m/s)'); ylabel('MTI gain relative to input (dB)');
title('Slow targets lie nearer the MTI notch');
subplot(1, 2, 2);
plot(values, collect(evaluations, 'detected_velocity_mps'), 'ok', 'markersize', 8);
hold on; plot(values, values, '--b'); hold off; grid on;
xlabel('True velocity (m/s)'); ylabel('Detected velocity (m/s)'); title('Doppler-bin quantization');
save_png(fig, fullfile(figures_dir, 'parameter_target_velocity.png'));
end

function plot_target_count(values, evaluations, figures_dir)
fig = figure('position', [100 100 1100 650]);
subplot(1, 2, 1); hold on;
colors = {'b', 'r', 'k'};
for idx = 1:numel(values)
    plot(evaluations{idx}.range_axis_m, evaluations{idx}.range_profile_db, colors{idx});
end
hold off; grid on; xlim([0 10]); ylim([-65 2]);
xlabel('Range (m)'); ylabel('Normalized magnitude (dB)'); title('Superposed targets in range FFT');
legend('1 target', '2 targets', '4 targets', 'location', 'southwest');
subplot(1, 2, 2);
bar(values, collect(evaluations, 'range_error_m')); grid on;
xlabel('Target count'); ylabel('Moving-cart range error (m)');
title('Moving-target estimate remains identifiable');
save_png(fig, fullfile(figures_dir, 'parameter_target_count.png'));
end

function plot_mti_order(values, evaluations, figures_dir)
suppression = collect(evaluations, 'static_suppression_db');
suppression(~isfinite(suppression)) = 0;
fig = figure('position', [100 100 1100 650]);
subplot(1, 2, 1);
bar(values, suppression); grid on;
xlabel('MTI difference order'); ylabel('Static-bin suppression (dB)');
title('More cascaded cancellers deepen zero-Doppler notch');
subplot(1, 2, 2);
bar(values, collect(evaluations, 'moving_retention_db')); grid on;
xlabel('MTI difference order'); ylabel('Moving-target gain (dB)');
title('Higher order also changes slow-target amplitude');
save_png(fig, fullfile(figures_dir, 'parameter_mti_order.png'));
end

function values = collect(evaluations, field_name)
values = zeros(1, numel(evaluations));
for idx = 1:numel(evaluations)
    values(idx) = evaluations{idx}.(field_name);
end
end
