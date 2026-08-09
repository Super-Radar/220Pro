function [rangeCube, rangePower] = range_fft(adcCube, cfg, fftOpts)
%RANGE_FFT Range processing on dimension 1.
numValidSamples = min(cfg.adc_sample_num, size(adcCube, 1));
adc = double(adcCube(1:numValidSamples, :, :));
if fftOpts.remove_adc_mean
    adc = adc - mean(adc, 1);
end
win = make_window(fftOpts.window, numValidSamples);
adc = adc .* reshape(win, [], 1, 1);
rangeCubeFull = fft(adc, cfg.rng_nfft, 1);
rangeCube = rangeCubeFull(1:cfg.range_bin_num, :, :);
if strcmpi(fftOpts.normalize, 'coherent_gain')
    rangeCube = rangeCube / max(sum(win), eps);
end
rangePower = squeeze(mean(mean(abs(rangeCube).^2, 3), 2));
end
