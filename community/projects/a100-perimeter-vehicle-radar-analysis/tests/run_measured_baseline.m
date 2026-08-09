clear;
clc;
close all;

%% Locate project root
thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));

dataRoot = fullfile(projectRoot, 'data', 'measured');
resultRoot = fullfile(projectRoot, 'results', 'measured');

%% Processing options
ioOpts.allow_zero_pad = false;

dynamicRangeDb = 60;

%% Representative measured samples
samples = {
    'empty',                'run_001_Pf0_Rx0.txt';
    'vehicle_approaching',  'run_001_Pf0_Rx0.txt';
    'vehicle_receding',     'run_001_Pf0_Rx0.txt'
};

fprintf('\n');
fprintf('=============================================\n');
fprintf(' CTSAI-A100 Issue #13 Measured Baseline\n');
fprintf('=============================================\n\n');

for iCase = 1:size(samples, 1)

    sceneName = samples{iCase, 1};
    fileName  = samples{iCase, 2};

    fprintf('Processing scene: %s\n', sceneName);

    filePath = fullfile(dataRoot, sceneName, fileName);

    if ~isfile(filePath)
        error('Measured ADC file not found: %s', filePath);
    end

    outputDir = fullfile(resultRoot, sceneName);

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    %% ------------------------------------------------------------
    % 1. Read packed ADC TXT
    % -------------------------------------------------------------

    [packedWords, header, trailer] = read_adc_txt(filePath, ioOpts);

    fprintf('  RX index          : %d\n', header.rx_index);
    fprintf('  Samples per chirp : %d\n', header.samples_per_chirp);
    fprintf('  Chirp count       : %d\n', header.chirp_count);
    fprintf('  Trailer values    : %d\n', numel(trailer));

    %% ------------------------------------------------------------
    % 2. Unpack uint32 -> signed ADC samples
    % adc dimensions:
    %
    %   [fast-time samples, slow-time chirps]
    %
    % expected:
    %
    %   [1024, 256]
    % -------------------------------------------------------------

    adc = unpack_uint32_adc( ...
        packedWords, ...
        header.samples_per_chirp, ...
        header.chirp_count);

    adc = double(adc);

    fprintf('  ADC matrix        : %d x %d\n', ...
        size(adc, 1), size(adc, 2));

    numSamples = size(adc, 1);
    numChirps  = size(adc, 2);

    %% ------------------------------------------------------------
    % 3. Raw ADC waveform
    % -------------------------------------------------------------

    fig = figure('Name', [sceneName ' ADC']);

    plot(0:numSamples-1, adc(:, 1), 'LineWidth', 1);

    grid on;

    xlabel('ADC Sample Index');
    ylabel('ADC Amplitude');
    title(sprintf('%s - Rx0 - First Chirp ADC', ...
        strrep(sceneName, '_', ' ')));

    saveas(fig, fullfile(outputDir, 'adc_first_chirp.png'));

    close(fig);

    %% ------------------------------------------------------------
    % 4. Remove fast-time DC for every chirp
    % -------------------------------------------------------------

    adcProcessed = adc - mean(adc, 1);

    %% ------------------------------------------------------------
    % 5. Range FFT
    % -------------------------------------------------------------

    rangeWindow = make_window('hann', numSamples);

    adcWindowed = adcProcessed .* ...
        repmat(rangeWindow, 1, numChirps);

    rangeFftFull = fft(adcWindowed, numSamples, 1);

    numRangeBins = floor(numSamples / 2);

    rangeCube = rangeFftFull(1:numRangeBins, :);

    rangePower = mean(abs(rangeCube).^2, 2);

    rangePowerDb = 10 * log10( ...
        rangePower / max(rangePower) + eps);

    rangeBins = 0:numRangeBins-1;

    fig = figure('Name', [sceneName ' Range Spectrum']);

    plot(rangeBins, rangePowerDb, 'LineWidth', 1);

    grid on;

    xlabel('Range Bin');
    ylabel('Normalized Power (dB)');
    title(sprintf('%s - Rx0 - Range Spectrum', ...
        strrep(sceneName, '_', ' ')));

    ylim([-dynamicRangeDb 0]);

    saveas(fig, fullfile(outputDir, 'range_spectrum.png'));

    close(fig);

    %% ------------------------------------------------------------
    % 6. Doppler FFT BEFORE MTI
    % -------------------------------------------------------------

    dopplerWindow = make_window('hann', numChirps).';

    rangeWindowed = rangeCube .* ...
        repmat(dopplerWindow, numRangeBins, 1);

    rdBefore = fftshift( ...
        fft(rangeWindowed, numChirps, 2), 2);

    rdBeforePower = abs(rdBefore).^2;

    rdBeforeDb = 10 * log10( ...
        rdBeforePower / max(rdBeforePower(:)) + eps);

    if mod(numChirps, 2) == 0
        dopplerBins = -numChirps/2 : numChirps/2-1;
    else
        dopplerBins = -(numChirps-1)/2 : (numChirps-1)/2;
    end

    fig = figure('Name', [sceneName ' RD Before MTI']);

    imagesc(dopplerBins, rangeBins, rdBeforeDb);

    axis xy;
    colorbar;

    xlabel('Doppler Bin');
    ylabel('Range Bin');

    title(sprintf('%s - Rx0 - Range-Doppler Before MTI', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, 'range_doppler_before_mti.png'));

    close(fig);

    %% ------------------------------------------------------------
    % 7. MTI2 - Two-pulse canceller
    % -------------------------------------------------------------

    rangeCube3D = reshape( ...
        rangeCube, numRangeBins, numChirps, 1);

    clutterOpts.method = 'MTI2';
    clutterOpts.normalize_output_power = false;

    [rangeMti2, diagnosticsMti2] = ...
        suppress_clutter(rangeCube3D, clutterOpts);

    rangeMti2 = reshape( ...
        rangeMti2, numRangeBins, numChirps);

    rangeMti2Windowed = rangeMti2 .* ...
        repmat(dopplerWindow, numRangeBins, 1);

    rdMti2 = fftshift( ...
        fft(rangeMti2Windowed, numChirps, 2), 2);

    rdMti2Power = abs(rdMti2).^2;

    rdMti2Db = 10 * log10( ...
        rdMti2Power / max(rdMti2Power(:)) + eps);

    fig = figure('Name', [sceneName ' RD MTI2']);

    imagesc(dopplerBins, rangeBins, rdMti2Db);

    axis xy;
    colorbar;

    xlabel('Doppler Bin');
    ylabel('Range Bin');

    title(sprintf('%s - Rx0 - Range-Doppler After MTI2', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, 'range_doppler_after_mti2.png'));

    close(fig);

    %% ------------------------------------------------------------
    % 8. MTI3 - Three-pulse canceller
    % -------------------------------------------------------------

    clutterOpts.method = 'MTI3';

    [rangeMti3, diagnosticsMti3] = ...
        suppress_clutter(rangeCube3D, clutterOpts);

    rangeMti3 = reshape( ...
        rangeMti3, numRangeBins, numChirps);

    rangeMti3Windowed = rangeMti3 .* ...
        repmat(dopplerWindow, numRangeBins, 1);

    rdMti3 = fftshift( ...
        fft(rangeMti3Windowed, numChirps, 2), 2);

    rdMti3Power = abs(rdMti3).^2;

    rdMti3Db = 10 * log10( ...
        rdMti3Power / max(rdMti3Power(:)) + eps);

    fig = figure('Name', [sceneName ' RD MTI3']);

    imagesc(dopplerBins, rangeBins, rdMti3Db);

    axis xy;
    colorbar;

    xlabel('Doppler Bin');
    ylabel('Range Bin');

    title(sprintf('%s - Rx0 - Range-Doppler After MTI3', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, 'range_doppler_after_mti3.png'));

    close(fig);

    %% ------------------------------------------------------------
    % 9. Print MTI diagnostic information
    % -------------------------------------------------------------

    fprintf('  MTI2 power change : %.2f dB\n', ...
        diagnosticsMti2.total_power_change_db);

    fprintf('  MTI3 power change : %.2f dB\n', ...
        diagnosticsMti3.total_power_change_db);

    fprintf('  Finished: %s\n\n', sceneName);
end

fprintf('=============================================\n');
fprintf(' All representative measured cases completed.\n');
fprintf('=============================================\n');