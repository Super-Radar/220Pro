function result = process_measured_adc(adc, mti_order)
%PROCESS_MEASURED_ADC Compute bin-domain FFT and MTI without hardware claims.
%   No physical range or velocity axes are returned because verified A100
%   waveform, timing, and DDMA parameters are not part of the text capture.

if nargin < 2 || isempty(mti_order)
    mti_order = 1;
end
[num_samples, num_chirps] = size(adc);
if num_samples ~= 1024 || num_chirps ~= 256
    error('a100:MeasuredAdcDimensionMismatch', ...
        'Measured ADC must be 1024x256 after unpacking; found %dx%d.', ...
        num_samples, num_chirps);
end
adc = double(adc);
adc_centered = adc - ones(num_samples, 1) * mean(adc, 1);
[range_fft_before, rd_before] = transform(adc_centered, num_chirps);

adc_after_mti = apply_mti(adc_centered, mti_order);
[range_fft_after, rd_after] = transform(adc_after_mti, num_chirps);

common_peak = max(abs(rd_before(:)));
if common_peak <= 0
    common_peak = 1;
end
rd_before_db = 20 * log10(abs(rd_before) / common_peak + eps);
rd_after_db = 20 * log10(abs(rd_after) / common_peak + eps);
rd_before_db(rd_before_db < -90) = -90;
rd_after_db(rd_after_db < -90) = -90;

center_index = floor(num_chirps / 2) + 1;
center_bins = max(1, center_index - 1):min(num_chirps, center_index + 1);
zero_before = sqrt(mean(abs(rd_before(:, center_bins)).^2, 'all'));
zero_after = sqrt(mean(abs(rd_after(:, center_bins)).^2, 'all'));
zero_suppression_db = 20 * log10((zero_before + eps) / (zero_after + eps));
range_profile = mean(abs(range_fft_before), 2);

result = struct( ...
    'range_bin', (0:(num_samples / 2 - 1)).', ...
    'normalized_doppler', (-floor(num_chirps / 2):(ceil(num_chirps / 2) - 1)) / num_chirps, ...
    'range_profile', range_profile, ...
    'range_profile_db', db_normalize(range_profile, -80), ...
    'range_fft_before', range_fft_before, ...
    'range_fft_after', range_fft_after, ...
    'rd_before', rd_before, ...
    'rd_after', rd_after, ...
    'rd_before_db', rd_before_db, ...
    'rd_after_db', rd_after_db, ...
    'adc_rms', sqrt(mean(adc(:).^2)), ...
    'zero_doppler_suppression_db', zero_suppression_db, ...
    'mti_order', mti_order);
end

function [range_fft, rd] = transform(adc, output_doppler_bins)
[num_samples, num_chirps] = size(adc);
range_window = hann(num_samples);
doppler_window = hann(num_chirps).';
windowed = adc .* (range_window * doppler_window);
range_fft_full = fft(windowed, num_samples, 1);
range_fft = range_fft_full(1:(num_samples / 2), :);
rd = fftshift(fft(range_fft, output_doppler_bins, 2), 2);
end
