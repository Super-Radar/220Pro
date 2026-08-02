function scene = simulate_lfmcw_scene(cfg)
%SIMULATE_LFMCW_SCENE Generate reference LFM waveforms and dechirped IF data.
%   Full-band reference waveforms are generated for one chirp at a high
%   sample rate. The multi-chirp IF matrix is generated analytically at the
%   lower ADC rate because only beat and Doppler frequencies remain after
%   dechirping.

required = {'c', 'fc_hz', 'bandwidth_hz', 'chirp_duration_s', ...
            'chirp_repetition_s', 'num_samples', 'num_chirps', ...
            'noise_snr_db', 'targets'};
for idx = 1:numel(required)
    if ~isfield(cfg, required{idx})
        error('a100:MissingSimulationField', ...
            'Simulation configuration is missing "%s".', required{idx});
    end
end
if isfield(cfg, 'random_seed')
    rand('state', cfg.random_seed); %#ok<RAND>
    randn('state', cfg.random_seed); %#ok<RAND>
end

slope_hz_per_s = cfg.bandwidth_hz / cfg.chirp_duration_s;
lambda_m = cfg.c / cfg.fc_hz;
fast_time_s = (0:cfg.num_samples - 1).' * ...
              (cfg.chirp_duration_s / cfg.num_samples);
slow_time_s = (0:cfg.num_chirps - 1) * cfg.chirp_repetition_s;

beat_clean = complex(zeros(cfg.num_samples, cfg.num_chirps));
for target_idx = 1:numel(cfg.targets)
    target = cfg.targets(target_idx);
    ranges_m = target.range_m + target.velocity_mps * slow_time_s;
    beat_hz = 2 * slope_hz_per_s * ranges_m / cfg.c;
    doppler_hz = 2 * target.velocity_mps / lambda_m;
    phase = 2 * pi * (fast_time_s * beat_hz + ...
            ones(cfg.num_samples, 1) * (doppler_hz * slow_time_s));
    beat_clean = beat_clean + target.amplitude * exp(1i * phase);
end

signal_rms = sqrt(mean(abs(beat_clean(:)).^2));
noise_rms = signal_rms / (10^(cfg.noise_snr_db / 20));
noise = noise_rms / sqrt(2) * ...
        (randn(size(beat_clean)) + 1i * randn(size(beat_clean)));
beat = beat_clean + noise;

generate_waveforms = ~isfield(cfg, 'generate_reference_waveforms') || ...
                     cfg.generate_reference_waveforms;
reference = struct('time_s', [], 'sample_rate_hz', [], ...
                   'transmit', [], 'echo', [], 'beat', []);
if generate_waveforms
    oversample = 2.5;
    if isfield(cfg, 'waveform_oversample')
        oversample = cfg.waveform_oversample;
    end
    waveform_fs_hz = oversample * cfg.bandwidth_hz;
    waveform_count = ceil(cfg.chirp_duration_s * waveform_fs_hz);
    waveform_time_s = (0:waveform_count - 1).' / waveform_fs_hz;
    transmit = exp(1i * pi * slope_hz_per_s * waveform_time_s.^2);
    echo = complex(zeros(size(transmit)));
    for target_idx = 1:numel(cfg.targets)
        target = cfg.targets(target_idx);
        delay_s = 2 * target.range_m / cfg.c;
        valid = waveform_time_s >= delay_s;
        delayed_time_s = waveform_time_s(valid) - delay_s;
        physical_doppler_hz = -2 * target.velocity_mps / lambda_m;
        echo(valid) = echo(valid) + target.amplitude * ...
            exp(1i * pi * slope_hz_per_s * delayed_time_s.^2) .* ...
            exp(1i * 2 * pi * physical_doppler_hz * waveform_time_s(valid));
    end
    reference = struct('time_s', waveform_time_s, ...
                       'sample_rate_hz', waveform_fs_hz, ...
                       'transmit', transmit, ...
                       'echo', echo, ...
                       'beat', transmit .* conj(echo));
end

scene = struct('config', cfg, ...
               'slope_hz_per_s', slope_hz_per_s, ...
               'lambda_m', lambda_m, ...
               'fast_time_s', fast_time_s, ...
               'slow_time_s', slow_time_s, ...
               'beat_clean', beat_clean, ...
               'beat', beat, ...
               'reference', reference);
end
