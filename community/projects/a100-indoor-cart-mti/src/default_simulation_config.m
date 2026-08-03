function cfg = default_simulation_config()
%DEFAULT_SIMULATION_CONFIG Teaching parameters, not claimed A100 waveform values.

cfg.c = 299792458;
cfg.fc_hz = 77e9;
cfg.bandwidth_hz = 1e9;
cfg.chirp_duration_s = 60e-6;
cfg.chirp_repetition_s = 70e-6;
cfg.num_samples = 1024;
cfg.num_chirps = 256;
cfg.sample_rate_hz = cfg.num_samples / cfg.chirp_duration_s;
cfg.noise_snr_db = 24;
cfg.mti_order = 1;
cfg.random_seed = 20260802;
cfg.generate_reference_waveforms = true;
cfg.waveform_oversample = 2.5;

% Positive velocity is receding; negative velocity is approaching.
cfg.targets = struct( ...
    'range_m', {6.0, 2.2, 4.5, 8.0}, ...
    'velocity_mps', {-0.35, 0.0, 0.0, 0.0}, ...
    'amplitude', {1.0, 3.8, 2.7, 1.8}, ...
    'label', {'cart', 'door frame', 'wall', 'far wall'});
end
