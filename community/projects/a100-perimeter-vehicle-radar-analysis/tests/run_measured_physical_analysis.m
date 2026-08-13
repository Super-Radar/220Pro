clear;
clc;
close all;

%% ============================================================
% CTSAI-A100 Issue #13
% Representative measured-data physical-axis analysis
%
% Three representative cases:
%   1. Empty environment
%   2. Vehicle approaching
%   3. Vehicle receding
%
% Processing:
%   ADC -> Range FFT -> Doppler FFT
%       -> MTI2 / MTI3
%       -> Physical range / velocity axes
%       -> Zero-Doppler clutter suppression metric
%% ============================================================

%% Locate project root

thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));

dataRoot = fullfile(projectRoot, 'data', 'measured');
resultRoot = fullfile(projectRoot, 'results', 'measured');

%% Load real CTSAI-A100 acquisition configuration

configFile = fullfile( ...
    projectRoot, ...
    'config', ...
    'sensor_config_init0.hxx');

cfg = load_ctsaia100_config(configFile);

%% Processing options

ioOpts.allow_zero_pad = false;

% Display dynamic range for all Range-Doppler maps.
dynamicRangeDb = 60;

% Zero-Doppler analysis region:
% center bin +/- 2 Doppler bins.
zeroHalfWidthBins = 2;

%% Representative measured samples

samples = {
    'empty',                'run_001_Pf0_Rx0.txt';
    'vehicle_approaching',  'run_001_Pf0_Rx0.txt';
    'vehicle_receding',     'run_001_Pf0_Rx0.txt'
};

numCases = size(samples, 1);

%% Summary storage

summaryScene = cell(numCases, 1);

summaryZeroBefore = zeros(numCases, 1);
summaryZeroMti2   = zeros(numCases, 1);
summaryZeroMti3   = zeros(numCases, 1);

summaryMti2SuppressionDb = zeros(numCases, 1);
summaryMti3SuppressionDb = zeros(numCases, 1);

%% Header

fprintf('\n');
fprintf('=====================================================\n');
fprintf(' CTSAI-A100 Issue #13 Physical Measured Analysis\n');
fprintf('=====================================================\n\n');

%% Process each representative scene

for iCase = 1:numCases

    sceneName = samples{iCase, 1};
    fileName  = samples{iCase, 2};

    fprintf('-----------------------------------------------------\n');
    fprintf('Processing scene: %s\n', sceneName);
    fprintf('-----------------------------------------------------\n');

    filePath = fullfile( ...
        dataRoot, ...
        sceneName, ...
        fileName);

    if ~isfile(filePath)
        error('Measured ADC file not found: %s', filePath);
    end

    outputDir = fullfile(resultRoot, sceneName);

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    %% ---------------------------------------------------------
    % 1. Read packed CTSAI-A100 ADC TXT
    %% ---------------------------------------------------------

    [packedWords, header, trailer] = ...
        read_adc_txt(filePath, ioOpts);

    fprintf('RX index          : %d\n', ...
        header.rx_index);

    fprintf('Samples per chirp : %d\n', ...
        header.samples_per_chirp);

    fprintf('Chirp count       : %d\n', ...
        header.chirp_count);

    fprintf('Trailer values    : %d\n', ...
        numel(trailer));

    %% ---------------------------------------------------------
    % 2. Unpack ADC
    %% ---------------------------------------------------------

    adc = unpack_uint32_adc( ...
        packedWords, ...
        header.samples_per_chirp, ...
        header.chirp_count);

    adc = double(adc);

    numSamples = size(adc, 1);
    numChirps  = size(adc, 2);

    fprintf('ADC matrix        : %d x %d\n', ...
        numSamples, numChirps);

    %% ---------------------------------------------------------
    % 3. Generate physical axes from real radar configuration
    %% ---------------------------------------------------------

    axesInfo = derive_measured_axes( ...
        cfg, ...
        numSamples, ...
        numChirps);

    rangeAxisM = axesInfo.range_axis_m;
    velocityAxisMps = axesInfo.velocity_axis_mps;

    numRangeBins = numel(rangeAxisM);

    fprintf('Range resolution  : %.4f m/bin\n', ...
        axesInfo.range_resolution_m);

    fprintf('Velocity resolution: %.4f m/s/bin\n', ...
        axesInfo.velocity_resolution_mps);

    %% ---------------------------------------------------------
    % 4. Plot first chirp ADC waveform
    %% ---------------------------------------------------------

    fig = figure('Name', [sceneName ' ADC']);

    plot( ...
        0:numSamples-1, ...
        adc(:, 1), ...
        'LineWidth', 1);

    grid on;

    xlabel('ADC Sample Index');
    ylabel('ADC Amplitude');

    title(sprintf( ...
        '%s - Rx0 - First Chirp ADC', ...
        strrep(sceneName, '_', ' ')));

    saveas(fig, fullfile( ...
        outputDir, ...
        'adc_first_chirp_physical.png'));

    close(fig);

    %% ---------------------------------------------------------
    % 5. Remove fast-time DC
    %% ---------------------------------------------------------

    adcProcessed = ...
        adc - mean(adc, 1);

    %% ---------------------------------------------------------
    % 6. Range FFT
    %% ---------------------------------------------------------

    rangeWindow = ...
        make_window('hann', numSamples);

    adcWindowed = ...
        adcProcessed .* ...
        repmat(rangeWindow, 1, numChirps);

    rangeFftFull = ...
        fft(adcWindowed, numSamples, 1);

    rangeCube = ...
        rangeFftFull(1:numRangeBins, :);

    %% ---------------------------------------------------------
    % 7. Average range spectrum
    %% ---------------------------------------------------------

    rangePower = ...
        mean(abs(rangeCube).^2, 2);

    rangeReference = ...
        max(rangePower);

    rangePowerDb = ...
        10 * log10( ...
        (rangePower + eps) / ...
        (rangeReference + eps));

    fig = figure( ...
        'Name', ...
        [sceneName ' Physical Range Spectrum']);

    plot( ...
        rangeAxisM, ...
        rangePowerDb, ...
        'LineWidth', 1);

    grid on;

    xlabel('Range (m)');
    ylabel('Normalized Power (dB)');

    title(sprintf( ...
        '%s - Rx0 - Range Spectrum', ...
        strrep(sceneName, '_', ' ')));

    ylim([-dynamicRangeDb 0]);

    xlim([ ...
        rangeAxisM(1), ...
        rangeAxisM(end)]);

    saveas(fig, fullfile( ...
        outputDir, ...
        'range_spectrum_physical.png'));

    close(fig);

    %% ---------------------------------------------------------
    % 8. Doppler FFT before MTI
    %% ---------------------------------------------------------

    dopplerWindow = ...
        make_window('hann', numChirps).';

    rangeWindowed = ...
        rangeCube .* ...
        repmat( ...
        dopplerWindow, ...
        numRangeBins, ...
        1);

    rdBefore = ...
        fftshift( ...
        fft( ...
        rangeWindowed, ...
        numChirps, ...
        2), ...
        2);

    rdBeforePower = ...
        abs(rdBefore).^2;

    %% ---------------------------------------------------------
    % 9. MTI2
    %% ---------------------------------------------------------

    rangeCube3D = reshape( ...
        rangeCube, ...
        numRangeBins, ...
        numChirps, ...
        1);

    clutterOpts = struct();

    clutterOpts.method = 'MTI2';
    clutterOpts.normalize_output_power = false;

    [rangeMti2, ~] = ...
        suppress_clutter( ...
        rangeCube3D, ...
        clutterOpts);

    rangeMti2 = reshape( ...
        rangeMti2, ...
        numRangeBins, ...
        numChirps);

    rangeMti2Windowed = ...
        rangeMti2 .* ...
        repmat( ...
        dopplerWindow, ...
        numRangeBins, ...
        1);

    rdMti2 = ...
        fftshift( ...
        fft( ...
        rangeMti2Windowed, ...
        numChirps, ...
        2), ...
        2);

    rdMti2Power = ...
        abs(rdMti2).^2;

    %% ---------------------------------------------------------
    % 10. MTI3
    %% ---------------------------------------------------------

    clutterOpts.method = 'MTI3';

    [rangeMti3, ~] = ...
        suppress_clutter( ...
        rangeCube3D, ...
        clutterOpts);

    rangeMti3 = reshape( ...
        rangeMti3, ...
        numRangeBins, ...
        numChirps);

    rangeMti3Windowed = ...
        rangeMti3 .* ...
        repmat( ...
        dopplerWindow, ...
        numRangeBins, ...
        1);

    rdMti3 = ...
        fftshift( ...
        fft( ...
        rangeMti3Windowed, ...
        numChirps, ...
        2), ...
        2);

    rdMti3Power = ...
        abs(rdMti3).^2;

    %% ---------------------------------------------------------
    % 11. IMPORTANT:
    %
    % Use one shared reference for Before / MTI2 / MTI3.
    %
    % Do NOT independently normalize each map, otherwise MTI
    % suppression cannot be visually compared.
    %% ---------------------------------------------------------

    sharedReferencePower = max([ ...
        rdBeforePower(:);
        rdMti2Power(:);
        rdMti3Power(:)]);

    rdBeforeDb = ...
        10 * log10( ...
        (rdBeforePower + eps) / ...
        (sharedReferencePower + eps));

    rdMti2Db = ...
        10 * log10( ...
        (rdMti2Power + eps) / ...
        (sharedReferencePower + eps));

    rdMti3Db = ...
        10 * log10( ...
        (rdMti3Power + eps) / ...
        (sharedReferencePower + eps));

    %% ---------------------------------------------------------
    % 12. Physical Range-Doppler map BEFORE MTI
    %% ---------------------------------------------------------

    fig = figure( ...
        'Name', ...
        [sceneName ' RD Before MTI Physical']);

    imagesc( ...
        velocityAxisMps, ...
        rangeAxisM, ...
        rdBeforeDb);

    axis xy;

    colorbar;

    xlabel('Radial Velocity (m/s)');
    ylabel('Range (m)');

    title(sprintf( ...
        '%s - Rx0 - Range-Doppler Before MTI', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, ...
        'range_doppler_before_mti_physical.png'));

    close(fig);

    %% ---------------------------------------------------------
    % 13. Physical Range-Doppler map AFTER MTI2
    %% ---------------------------------------------------------

    fig = figure( ...
        'Name', ...
        [sceneName ' RD MTI2 Physical']);

    imagesc( ...
        velocityAxisMps, ...
        rangeAxisM, ...
        rdMti2Db);

    axis xy;

    colorbar;

    xlabel('Radial Velocity (m/s)');
    ylabel('Range (m)');

    title(sprintf( ...
        '%s - Rx0 - Range-Doppler After MTI2', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, ...
        'range_doppler_after_mti2_physical.png'));

    close(fig);

    %% ---------------------------------------------------------
    % 14. Physical Range-Doppler map AFTER MTI3
    %% ---------------------------------------------------------

    fig = figure( ...
        'Name', ...
        [sceneName ' RD MTI3 Physical']);

    imagesc( ...
        velocityAxisMps, ...
        rangeAxisM, ...
        rdMti3Db);

    axis xy;

    colorbar;

    xlabel('Radial Velocity (m/s)');
    ylabel('Range (m)');

    title(sprintf( ...
        '%s - Rx0 - Range-Doppler After MTI3', ...
        strrep(sceneName, '_', ' ')));

    caxis([-dynamicRangeDb 0]);

    saveas(fig, fullfile( ...
        outputDir, ...
        'range_doppler_after_mti3_physical.png'));

    close(fig);

    %% ---------------------------------------------------------
    % 15. Zero-Doppler clutter suppression metric
    %
    % Analyze center Doppler bin +/- 2 bins.
    %
    % Positive suppression dB means the low-Doppler energy
    % decreased after MTI.
    %% ---------------------------------------------------------

    zeroBin = ...
        floor(numChirps / 2) + 1;

    firstZeroBin = max( ...
        1, ...
        zeroBin - zeroHalfWidthBins);

    lastZeroBin = min( ...
        numChirps, ...
        zeroBin + zeroHalfWidthBins);

    zeroBand = ...
        firstZeroBin:lastZeroBin;

    zeroBefore = ...
        sum(sum( ...
        rdBeforePower(:, zeroBand)));

    zeroMti2 = ...
        sum(sum( ...
        rdMti2Power(:, zeroBand)));

    zeroMti3 = ...
        sum(sum( ...
        rdMti3Power(:, zeroBand)));

    mti2SuppressionDb = ...
        10 * log10( ...
        (zeroBefore + eps) / ...
        (zeroMti2 + eps));

    mti3SuppressionDb = ...
        10 * log10( ...
        (zeroBefore + eps) / ...
        (zeroMti3 + eps));

    zeroVelocityMin = ...
        velocityAxisMps(firstZeroBin);

    zeroVelocityMax = ...
        velocityAxisMps(lastZeroBin);

    %% Print proper MTI result

    fprintf('\n');

    fprintf( ...
        'Zero-Doppler analysis band : %.3f to %.3f m/s\n', ...
        zeroVelocityMin, ...
        zeroVelocityMax);

    fprintf( ...
        'MTI2 zero-Doppler suppression: %.2f dB\n', ...
        mti2SuppressionDb);

    fprintf( ...
        'MTI3 zero-Doppler suppression: %.2f dB\n', ...
        mti3SuppressionDb);

    %% Save summary values

    summaryScene{iCase} = sceneName;

    summaryZeroBefore(iCase) = zeroBefore;
    summaryZeroMti2(iCase) = zeroMti2;
    summaryZeroMti3(iCase) = zeroMti3;

    summaryMti2SuppressionDb(iCase) = ...
        mti2SuppressionDb;

    summaryMti3SuppressionDb(iCase) = ...
        mti3SuppressionDb;

    fprintf('\nFinished: %s\n\n', sceneName);

end

%% ============================================================
% 16. Write measured MTI summary CSV
%% ============================================================

summaryFile = fullfile( ...
    resultRoot, ...
    'mti_zero_doppler_summary.csv');

fid = fopen(summaryFile, 'w');

if fid < 0
    error('Could not create summary CSV: %s', summaryFile);
end

fprintf(fid, [ ...
    'scene,' ...
    'zero_doppler_before,' ...
    'zero_doppler_after_mti2,' ...
    'zero_doppler_after_mti3,' ...
    'mti2_suppression_db,' ...
    'mti3_suppression_db\n']);

for iCase = 1:numCases

    fprintf(fid, ...
        '%s,%.12g,%.12g,%.12g,%.6f,%.6f\n', ...
        summaryScene{iCase}, ...
        summaryZeroBefore(iCase), ...
        summaryZeroMti2(iCase), ...
        summaryZeroMti3(iCase), ...
        summaryMti2SuppressionDb(iCase), ...
        summaryMti3SuppressionDb(iCase));

end

fclose(fid);

%% Final summary

fprintf('=====================================================\n');
fprintf(' Representative measured analysis completed\n');
fprintf('=====================================================\n\n');

fprintf('MTI zero-Doppler suppression summary\n');
fprintf('-----------------------------------------------------\n');

for iCase = 1:numCases

    fprintf( ...
        '%-22s MTI2 = %8.2f dB   MTI3 = %8.2f dB\n', ...
        summaryScene{iCase}, ...
        summaryMti2SuppressionDb(iCase), ...
        summaryMti3SuppressionDb(iCase));

end

fprintf('\nSummary CSV:\n%s\n', summaryFile);

fprintf('\n');