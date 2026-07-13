function cfg = ctsai_config(profileName, projectDir)
%CTSAI_CONFIG Public CTSAI-A100 profile parameters used by this demo.

arguments
    profileName (1,:) char {mustBeMember(profileName, {'near','far'})}
    projectDir (1,:) char
end

c = 299792458;
cfg.c = c;
cfg.numRx = 4;
cfg.fcHz = 76.3e9;
cfg.adcSampleRateHz = 25e6;

switch lower(profileName)
    case 'near'
        cfg.name = 'near';
        cfg.bandwidthHz = 750e6;
        cfg.rampTimeSec = 104.65e-6;
        cfg.chirpPeriodSec = 108.5e-6;
        cfg.numChirps = 128;
        cfg.numPackedSamples = 1024;
        cfg.rangeNfft = 2048;
        cfg.dopplerNfft = 128;
        prefix = 'adc_近波_20260512141857_f1_';
        suffixes = {'0_14_19_05_965.txt','1_14_19_14_570.txt', ...
            '2_14_19_23_170.txt','3_14_19_31_788.txt'};
    case 'far'
        cfg.name = 'far';
        cfg.bandwidthHz = 300e6;
        cfg.rampTimeSec = 43e-6;
        cfg.chirpPeriodSec = 48e-6;
        cfg.numChirps = 256;
        cfg.numPackedSamples = 512;
        cfg.rangeNfft = 1024;
        cfg.dopplerNfft = 256;
        prefix = 'adc_远波_20260512135827_f0_';
        suffixes = {'0_13_58_36_748.txt','1_13_58_45_367.txt', ...
            '2_13_58_53_977.txt','3_13_59_02_596.txt'};
end

cfg.numAdcSamples = 2 * cfg.numPackedSamples;
cfg.slopeHzPerSec = cfg.bandwidthHz / cfg.rampTimeSec;
cfg.lambda = c / cfg.fcHz;
cfg.rangeResolutionM = c / (2 * cfg.bandwidthHz);
cfg.rangeBinM = c * cfg.adcSampleRateHz / ...
    (2 * cfg.slopeHzPerSec * cfg.rangeNfft);
cfg.velocityResolutionMps = cfg.lambda / ...
    (2 * cfg.numChirps * cfg.chirpPeriodSec);

repoRoot = fileparts(fileparts(projectDir));
dataDir = fullfile(repoRoot, 'ADC数据采集', '示例adc数据和结果');
cfg.dataFiles = cellfun(@(s) fullfile(dataDir, [prefix s]), ...
    suffixes, 'UniformOutput', false);
cfg.resultsDir = fullfile(projectDir, 'results', cfg.name);

% Conservative educational defaults; tune for a particular scene.
cfg.cfar.training = [8 6];      % [range Doppler] cells on each side
cfg.cfar.guard = [2 2];
cfg.cfar.pfa = 1e-4;
cfg.cfar.minRangeM = 0.5;
cfg.cfar.maxRangeM = 0.90 * cfg.rangeBinM * (cfg.rangeNfft/2 - 1);
cfg.angleNfft = 128;
cfg.rxSpacingLambda = 0.5;      % Assumption for the four-RX teaching estimate
end
