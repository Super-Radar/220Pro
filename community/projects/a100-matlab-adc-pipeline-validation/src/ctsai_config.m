function cfg = ctsai_config(profileName, projectDir)
%CTSAI_CONFIG Load public CTSAI-A100 profile parameters from official HXX.

arguments
    profileName (1,:) char {mustBeMember(profileName, {'near','far'})}
    projectDir (1,:) char
end

repoRoot = fileparts(fileparts(fileparts(projectDir)));
officialRoot = fullfile(repoRoot, 'ADC数据采集', ...
    'matlab_signal_processing_platform_231023_for_txt_A100');

switch lower(profileName)
    case 'near'
        cfg.name = 'near';
        marker = 'f1';
        configName = 'sensor_config_init1.hxx';
    case 'far'
        cfg.name = 'far';
        marker = 'f0';
        configName = 'sensor_config_init0.hxx';
end

cfg.sourceConfigFile = fullfile(officialRoot, 'cfg', ...
    'CTASI-A100配置', configName);
profile = load_hxx_profile(cfg.sourceConfigFile);

cfg.c = 299792458;
cfg.numRx = 4;
cfg.fcHz = profile.fmcw_startfreq * 1e9;
cfg.bandwidthHz = profile.fmcw_bandwidth * 1e6;
cfg.rampTimeSec = profile.fmcw_chirp_rampup * 1e-6;
cfg.chirpPeriodSec = profile.fmcw_chirp_period * 1e-6;
cfg.adcSampleRateHz = profile.adc_freq * 1e6;
cfg.numChirps = profile.nchirp;
cfg.rangeNfft = profile.rng_nfft;
cfg.dopplerNfft = profile.vel_nfft;
cfg.numPackedSamples = cfg.rangeNfft / 2;
cfg.numAdcSamples = 2 * cfg.numPackedSamples;
cfg.txGroups = profile.tx_groups;
cfg.antPos = profile.ant_pos;
cfg.antCompsDeg = profile.ant_comps;

cfg.slopeHzPerSec = cfg.bandwidthHz / cfg.rampTimeSec;
cfg.lambda = cfg.c / cfg.fcHz;
cfg.rangeResolutionM = cfg.c / (2 * cfg.bandwidthHz);
cfg.rangeBinM = cfg.c * cfg.adcSampleRateHz / ...
    (2 * cfg.slopeHzPerSec * cfg.rangeNfft);
cfg.nominalTdmVelocityResolutionMps = cfg.lambda / ...
    (2 * cfg.numChirps * cfg.chirpPeriodSec);

dataDir = fullfile(repoRoot, 'ADC数据采集', '示例adc数据和结果');
matches = dir(fullfile(dataDir, ['*_' marker '_*.txt']));
if numel(matches) ~= cfg.numRx
    error('CTSAI:ProfileFiles', ...
        'Profile %s requires %d RX files, but %d were found in %s.', ...
        cfg.name, cfg.numRx, numel(matches), dataDir);
end
[~, order] = sort({matches.name});
matches = matches(order);
cfg.dataFiles = arrayfun(@(x) fullfile(x.folder, x.name), ...
    matches, 'UniformOutput', false);
cfg.resultsDir = fullfile(projectDir, 'results', cfg.name);

% Review feedback identified DDMA structure in the public captures while the
% published HXX files expose TDM-style tx_groups. Without the metadata below,
% physical velocity and virtual-array angle must not be reported.
cfg.mimo.mode = 'unresolved_ddma';
cfg.mimo.metadataComplete = false;
cfg.mimo.velocityValid = false;
cfg.mimo.angleValid = false;
cfg.mimo.missingMetadata = { ...
    'TX enable mask', ...
    'per-TX per-chirp phase code or phase increment', ...
    'DDMA Doppler-bin offset', ...
    'initial phase', ...
    'chirp repetition interval definition for DDMA decoding', ...
    'integer/non-integer Doppler-bin coding flag', ...
    'velocity ambiguity resolution design', ...
    'TX/RX coordinates and virtual-channel order', ...
    'TX/DDMA phase calibration status'};

cfg.cfar.training = [8 6];
cfg.cfar.guard = [2 2];
cfg.cfar.pfa = 1e-4;
cfg.cfar.minRangeM = 0.5;
cfg.cfar.maxRangeM = 0.90 * cfg.rangeBinM * (cfg.rangeNfft/2 - 1);
cfg.angleNfft = 128;
end
