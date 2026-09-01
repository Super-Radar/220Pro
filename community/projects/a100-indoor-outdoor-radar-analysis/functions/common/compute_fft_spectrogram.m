function [powerDb, timeAxisS, frequencyAxisHz] = compute_fft_spectrogram( ...
    signal, windowLength, overlapLength, nfft, sampleRateHz)
%COMPUTE_FFT_SPECTROGRAM 使用基础 FFT 计算居中的双边时频图。
% 该实现避免依赖 Signal Processing Toolbox，窗口与项目其余流程一致。

if windowLength < 1 || overlapLength < 0 || ...
        overlapLength >= windowLength || nfft < windowLength || ...
        sampleRateHz <= 0
    error('compute_fft_spectrogram:InvalidParameters', ...
        'Window, overlap, FFT length, or sample rate is invalid.');
end

signal = signal(:);
hopLength = windowLength - overlapLength;
numFrames = 1 + floor((numel(signal) - windowLength) / hopLength);
if numFrames < 1
    error('compute_fft_spectrogram:SignalTooShort', ...
        'Signal length must be at least the window length.');
end

window = make_window('hamming', windowLength);
spectrum = complex(zeros(nfft, numFrames));
for iFrame = 1:numFrames
    firstSample = (iFrame - 1) * hopLength + 1;
    frame = signal(firstSample:firstSample + windowLength - 1) .* window;
    spectrum(:, iFrame) = fftshift(fft(frame, nfft));
end

reference = max(abs(spectrum(:)));
powerDb = 20 * log10((abs(spectrum) + eps) / (reference + eps));
timeAxisS = ((0:numFrames-1) * hopLength + (windowLength-1)/2) / sampleRateHz;
frequencyBins = (-floor(nfft/2):ceil(nfft/2)-1).';
frequencyAxisHz = frequencyBins * sampleRateHz / nfft;

end
