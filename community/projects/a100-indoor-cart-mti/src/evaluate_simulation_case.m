function evaluation = evaluate_simulation_case(cfg, mti_order)
%EVALUATE_SIMULATION_CASE Run one deterministic case and collect metrics.

if nargin < 2 || isempty(mti_order)
    mti_order = cfg.mti_order;
end
cfg.generate_reference_waveforms = false;
scene = simulate_lfmcw_scene(cfg);
before = compute_range_doppler(scene.beat, cfg, 0);
after = compute_range_doppler(scene.beat, cfg, mti_order);

target = cfg.targets(1);
[before_peak, before_range, before_velocity] = local_peak(before, target, cfg);
[after_peak, after_range, after_velocity] = local_peak(after, target, cfg);
moving_retention_db = 20 * log10((after_peak + eps) / (before_peak + eps));

zero_mask = abs(before.velocity_axis_mps) == min(abs(before.velocity_axis_mps));
static_range_mask = false(size(before.range_axis_m));
for idx = 1:numel(cfg.targets)
    if cfg.targets(idx).velocity_mps == 0
        static_range_mask = static_range_mask | ...
            abs(before.range_axis_m - cfg.targets(idx).range_m) <= 0.5;
    end
end
if any(static_range_mask)
    static_before = max(abs(before.rd_complex(static_range_mask, zero_mask))(:));
    static_after = max(abs(after.rd_complex(static_range_mask, zero_mask))(:));
    static_suppression_db = 20 * log10((static_before + eps) / (static_after + eps));
else
    static_suppression_db = NaN;
end
lambda_m = cfg.c / cfg.fc_hz;
sample_rate_hz = cfg.num_samples / cfg.chirp_duration_s;
slope_hz_per_s = cfg.bandwidth_hz / cfg.chirp_duration_s;
evaluation = struct( ...
    'range_resolution_m', cfg.c / (2 * cfg.bandwidth_hz), ...
    'velocity_resolution_mps', lambda_m / ...
        (2 * cfg.num_chirps * cfg.chirp_repetition_s), ...
    'max_unambiguous_velocity_mps', lambda_m / (4 * cfg.chirp_repetition_s), ...
    'max_unambiguous_range_m', cfg.c * sample_rate_hz / (4 * slope_hz_per_s), ...
    'cart_beat_frequency_hz', 2 * slope_hz_per_s * target.range_m / cfg.c, ...
    'detected_range_m', after_range, ...
    'detected_velocity_mps', after_velocity, ...
    'range_error_m', abs(after_range - target.range_m), ...
    'velocity_error_mps', abs(after_velocity - target.velocity_mps), ...
    'moving_retention_db', moving_retention_db, ...
    'static_suppression_db', static_suppression_db, ...
    'target_count', numel(cfg.targets), ...
    'mti_order', mti_order, ...
    'range_axis_m', before.range_axis_m, ...
    'range_profile_db', db_normalize(before.range_profile, -70));
end

function [peak, range_m, velocity_mps] = local_peak(result, target, cfg)
range_resolution = cfg.c / (2 * cfg.bandwidth_hz);
velocity_resolution = (cfg.c / cfg.fc_hz) / ...
                      (2 * cfg.num_chirps * cfg.chirp_repetition_s);
range_mask = abs(result.range_axis_m - target.range_m) <= max(0.6, 3 * range_resolution);
velocity_mask = abs(result.velocity_axis_mps - target.velocity_mps) <= ...
                max(0.35, 3 * velocity_resolution);
local = abs(result.rd_complex(range_mask, velocity_mask));
[peak, linear_idx] = max(local(:));
[range_local_idx, velocity_local_idx] = ind2sub(size(local), linear_idx);
range_indices = find(range_mask);
velocity_indices = find(velocity_mask);
range_m = result.range_axis_m(range_indices(range_local_idx));
velocity_mps = result.velocity_axis_mps(velocity_indices(velocity_local_idx));
end
