function test_signal_processing()
%TEST_SIGNAL_PROCESSING Verify FFT peak localization and static cancellation.

cfg = default_simulation_config();
cfg.num_samples = 256;
cfg.num_chirps = 128;
cfg.bandwidth_hz = 500e6;
cfg.chirp_duration_s = 80e-6;
cfg.chirp_repetition_s = 100e-6;
cfg.sample_rate_hz = cfg.num_samples / cfg.chirp_duration_s;
cfg.noise_snr_db = 80;
cfg.generate_reference_waveforms = false;
cfg.targets = struct('range_m', 5.1, 'velocity_mps', 0.65, ...
                     'amplitude', 1.0, 'label', 'test target');
scene = simulate_lfmcw_scene(cfg);
result = compute_range_doppler(scene.beat, cfg, 0);
[~, peak_idx] = max(abs(result.rd_complex(:)));
[range_idx, velocity_idx] = ind2sub(size(result.rd_complex), peak_idx);
range_resolution = cfg.c / (2 * cfg.bandwidth_hz);
velocity_resolution = (cfg.c / cfg.fc_hz) / ...
                      (2 * cfg.num_chirps * cfg.chirp_repetition_s);
assert(abs(result.range_axis_m(range_idx) - cfg.targets.range_m) <= 1.5 * range_resolution);
assert(abs(result.velocity_axis_mps(velocity_idx) - cfg.targets.velocity_mps) <= 1.5 * velocity_resolution);

static_data = repmat((1:32).', 1, 16);
cancelled = apply_mti(static_data, 1);
assert(all(cancelled(:) == 0));
assert(isequal(size(cancelled), [32, 15]));
assert_error_id(@() apply_mti(static_data, -1), 'a100:InvalidMtiOrder');

measured_static = repmat(sin((0:1023).' * 2 * pi / 64), 1, 256);
measured = process_measured_adc(measured_static, 1);
assert(isequal(size(measured.rd_before), [512, 256]));
assert(isequal(size(measured.rd_after), [512, 256]));
assert(measured.zero_doppler_suppression_db > 100);
end
