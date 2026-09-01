function out = process_radar_cube(adc, cfg)
%PROCESS_RADAR_CUBE Range FFT, Doppler FFT and noncoherent integration.

rangeWindow = local_hann(cfg.numAdcSamples);
dopplerWindow = local_hann(cfg.numChirps).';

windowed = adc .* reshape(rangeWindow, [], 1, 1);
rangeFftFull = fft(windowed, cfg.rangeNfft, 1);
rangeFft = rangeFftFull(1:cfg.rangeNfft/2, :, :);

% Do not remove the slow-time mean while DDMA coding is unresolved. DDMA
% modulation shifts each TX response, so the physical zero-velocity response
% cannot be assumed to occupy the center bin of the combined raw spectrum.
dopplerInput = rangeFft .* reshape(dopplerWindow, 1, [], 1);
rdCube = fftshift(fft(dopplerInput, cfg.dopplerNfft, 2), 2);

rdPower = mean(abs(rdCube).^2, 3);
rdPowerDb = 10 * log10(rdPower + eps);

rangeAxis = (0:size(rangeFft,1)-1).' * cfg.rangeBinM;
dopplerBins = (-cfg.dopplerNfft/2:cfg.dopplerNfft/2-1);
nominalTdmVelocityAxis = dopplerBins * cfg.nominalTdmVelocityResolutionMps;

valid = rangeAxis >= cfg.cfar.minRangeM & rangeAxis <= cfg.cfar.maxRangeM;

out.adc = adc;
out.rangeFft = rangeFft;
out.rdCube = rdCube;
out.rdPower = rdPower;
out.rdPowerDb = rdPowerDb;
out.rangeAxis = rangeAxis;
out.dopplerBinAxis = dopplerBins;
out.nominalTdmVelocityAxis = nominalTdmVelocityAxis;
out.validRangeMask = valid;
end

function w = local_hann(n)
% Toolbox-independent symmetric Hann window.
if n == 1
    w = 1;
else
    k = (0:n-1).';
    w = 0.5 - 0.5*cos(2*pi*k/(n-1));
end
end
