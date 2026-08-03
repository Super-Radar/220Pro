function result = compute_range_doppler(beat, cfg, mti_order, display_reference_peak)
%COMPUTE_RANGE_DOPPLER Windowed range FFT and centered Doppler FFT.

if nargin < 3 || isempty(mti_order)
    mti_order = 0;
end
if nargin < 4
    display_reference_peak = [];
end
[num_samples, num_chirps] = size(beat);
if num_samples ~= cfg.num_samples || num_chirps ~= cfg.num_chirps
    error('a100:SimulationDimensionMismatch', ...
        'Beat matrix is %dx%d but config declares %dx%d.', ...
        num_samples, num_chirps, cfg.num_samples, cfg.num_chirps);
end
processed = apply_mti(beat, mti_order);
remaining_chirps = size(processed, 2);
range_window = hann(num_samples);
doppler_window = hann(remaining_chirps).';
windowed = processed .* (range_window * doppler_window);

range_fft_full = fft(windowed, num_samples, 1);
positive_bins = 1:(num_samples / 2);
range_fft = range_fft_full(positive_bins, :);
doppler_fft = fftshift(fft(range_fft, num_chirps, 2), 2);
if isempty(display_reference_peak)
    display_reference_peak = max(abs(doppler_fft(:)));
end

slope_hz_per_s = cfg.bandwidth_hz / cfg.chirp_duration_s;
sample_rate_hz = cfg.num_samples / cfg.chirp_duration_s;
beat_frequency_hz = (positive_bins - 1).' * sample_rate_hz / num_samples;
range_axis_m = cfg.c * beat_frequency_hz / (2 * slope_hz_per_s);

doppler_bins = (-floor(num_chirps / 2)):(ceil(num_chirps / 2) - 1);
doppler_frequency_hz = doppler_bins / ...
                       (num_chirps * cfg.chirp_repetition_s);
velocity_axis_mps = doppler_frequency_hz * (cfg.c / cfg.fc_hz) / 2;

result = struct('mti_order', mti_order, ...
                'range_axis_m', range_axis_m, ...
                'velocity_axis_mps', velocity_axis_mps, ...
                'range_fft', range_fft, ...
                'range_profile', mean(abs(range_fft), 2), ...
                'rd_complex', doppler_fft, ...
                'rd_db', db_normalize(doppler_fft, -80, display_reference_peak), ...
                'display_reference_peak', display_reference_peak);
end
