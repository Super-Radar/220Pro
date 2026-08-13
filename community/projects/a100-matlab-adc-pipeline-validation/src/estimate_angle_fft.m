function angleDeg = estimate_angle_fft(snapshot, spacingLambda, nfft)
%ESTIMATE_ANGLE_FFT Generic ULA Angle FFT for validated array metadata only.

spectrum = abs(fftshift(fft(snapshot, nfft)));
[~, peak] = max(spectrum);
spatial = ((peak - 1) - nfft/2) / nfft;
sinTheta = spatial / spacingLambda;
angleDeg = asind(max(-1, min(1, sinTheta)));
end
