function rd = process_simulated_range_doppler(beat, cfg)
%PROCESS_SIMULATED_RANGE_DOPPLER
% Perform Range FFT and Doppler FFT.

Ns = size(beat, 1);
Nc = size(beat, 2);

%% Fast-time window

rangeWindow = make_window('hann', Ns);

beatWindowed = ...
    beat .* repmat(rangeWindow, 1, Nc);

%% Range FFT

rangeFFT = fft( ...
    beatWindowed, ...
    Ns, ...
    1);

numRangeBins = floor(Ns / 2);

rangeFFT = ...
    rangeFFT(1:numRangeBins, :);

%% Slow-time window

dopplerWindow = make_window('hann', Nc).';

rangeFFTWindowed = ...
    rangeFFT .* ...
    repmat( ...
        dopplerWindow, ...
        numRangeBins, ...
        1);

%% Doppler FFT

rdComplex = fftshift( ...
    fft( ...
        rangeFFTWindowed, ...
        Nc, ...
        2), ...
    2);

rdPower = abs(rdComplex).^2;

%% Physical range axis

rangeResolution = ...
    cfg.c * cfg.sample_rate / ...
    (2 * cfg.slope * Ns);

rangeAxis = ...
    (0:numRangeBins-1) * ...
    rangeResolution;

%% Physical velocity axis

% fftshift 后的奇数长度频谱零频位于正中；直接使用 -Nc/2 会产生
% 半个 bin 的偏移。
dopplerBins = ...
    -floor(Nc/2) : ceil(Nc/2)-1;

dopplerFrequencyAxis = ...
    dopplerBins / (Nc * cfg.chirp_period);

velocityAxis = ...
    dopplerFrequencyAxis * ...
    cfg.lambda / 2;

%% Output

rd = struct();

rd.range_fft = rangeFFT;

rd.complex = rdComplex;
rd.power = rdPower;

rd.range_axis_m = rangeAxis;
rd.velocity_axis_mps = velocityAxis;

end
