function result = estimate_angle_fft(snapshot, positionsLambda, angleGridDeg, angleOpts)
%ESTIMATE_ANGLE_FFT Sparse-aperture gridding followed by spatial FFT.
[positions, order] = sort(positionsLambda(:));
snapshot = snapshot(order);
d = angleOpts.fft_grid_spacing_lambda;
gridIndex = round((positions - min(positions)) / d) + 1;
numGrid = max(gridIndex);
gridded = zeros(numGrid, 1);
counts = zeros(numGrid, 1);
for i = 1:numel(snapshot)
    gridded(gridIndex(i)) = gridded(gridIndex(i)) + snapshot(i);
    counts(gridIndex(i)) = counts(gridIndex(i)) + 1;
end
counts(counts == 0) = 1;
gridded = gridded ./ counts;
gridded = gridded .* make_window('hann', numGrid);
nfft = max(angleOpts.fft_size, 2^nextpow2(numGrid));
fftSpectrum = abs(fftshift(fft(gridded, nfft))).^2;
spatialFrequency = (-floor(nfft/2):ceil(nfft/2)-1).' / nfft;
sinTheta = spatialFrequency / d;
valid = abs(sinTheta) <= 1;
fftAngles = asind(sinTheta(valid));
fftSpectrum = fftSpectrum(valid);
spectrum = interp1(fftAngles, fftSpectrum, angleGridDeg, 'linear', 0);
[~, iPeak] = max(spectrum);
result.angle_deg = angleGridDeg(iPeak);
result.spectrum = spectrum;
end
