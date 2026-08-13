function axesInfo = derive_measured_axes(cfg, numSamples, numChirps)
%DERIVE_MEASURED_AXES Build physical range and velocity axes.
%
% This helper is used by the CTSAI-A100 Issue #8 measured-data analysis.
%
% Inputs:
%   cfg         Parsed CTSAI-A100 sensor configuration.
%   numSamples  Number of fast-time ADC samples.
%   numChirps   Number of slow-time chirps used for Doppler FFT.
%
% Output:
%   axesInfo    Structure containing range and velocity axes.

requiredFields = {
    'fmcw_startfreq'
    'fmcw_bandwidth'
    'fmcw_chirp_rampup'
    'fmcw_chirp_period'
    'adc_freq'
    'dec_factor'
    'rng_nfft'
    'vel_nfft'
    'nchirp'
    'tx_groups'
};

for iField = 1:numel(requiredFields)
    fieldName = requiredFields{iField};

    if ~isfield(cfg, fieldName)
        error('Missing configuration field: %s', fieldName);
    end
end

%% Check FFT dimensions

if round(cfg.rng_nfft) ~= numSamples
    error(['Range FFT size mismatch: config rng_nfft=%d, ' ...
           'measured samples/chirp=%d.'], ...
        round(cfg.rng_nfft), numSamples);
end

if round(cfg.vel_nfft) ~= numChirps
    error(['Velocity FFT size mismatch: config vel_nfft=%d, ' ...
           'measured chirps=%d.'], ...
        round(cfg.vel_nfft), numChirps);
end

%% Decode TX mode

mimo = decode_tx_groups(cfg, 4);

% The current Issue #8 baseline directly Doppler-processes all 256
% chirps of one RX file. This is valid for the current SISO profile.
if mimo.group_count ~= 1
    error(['This measured-data baseline currently expects one TX chirp ' ...
           'group, but the configuration contains %d groups.'], ...
        mimo.group_count);
end

%% Physical constants

c0 = 299792458;

carrierHz = cfg.fmcw_startfreq * 1e9;

lambdaM = c0 / carrierHz;

adcSampleRateHz = ...
    cfg.adc_freq * 1e6 / cfg.dec_factor;

chirpSlopeHzPerS = ...
    cfg.fmcw_bandwidth * 1e6 / ...
    (cfg.fmcw_chirp_rampup * 1e-6);

%% Range axis

numRangeBins = floor(numSamples / 2);

rangeResolutionM = ...
    c0 * adcSampleRateHz / ...
    (2 * chirpSlopeHzPerS * numSamples);

rangeAxisM = ...
    (0:numRangeBins-1) * rangeResolutionM;

%% Doppler / velocity axis

slowTimePeriodS = ...
    cfg.fmcw_chirp_period * 1e-6 * mimo.group_count;

velocityResolutionMps = ...
    lambdaM / ...
    (2 * slowTimePeriodS * numChirps);

if mod(numChirps, 2) == 0
    dopplerBins = ...
        -numChirps/2 : numChirps/2-1;
else
    dopplerBins = ...
        -(numChirps-1)/2 : (numChirps-1)/2;
end

velocityAxisMps = ...
    dopplerBins * velocityResolutionMps;

maxUnambiguousVelocityMps = ...
    lambdaM / (4 * slowTimePeriodS);

%% Output

axesInfo = struct();

axesInfo.carrier_hz = carrierHz;
axesInfo.lambda_m = lambdaM;

axesInfo.adc_sample_rate_hz = adcSampleRateHz;
axesInfo.chirp_slope_hz_per_s = chirpSlopeHzPerS;

axesInfo.range_resolution_m = rangeResolutionM;
axesInfo.range_axis_m = rangeAxisM;
axesInfo.max_range_m = rangeAxisM(end);

axesInfo.velocity_resolution_mps = velocityResolutionMps;
axesInfo.velocity_axis_mps = velocityAxisMps;
axesInfo.max_unambiguous_velocity_mps = ...
    maxUnambiguousVelocityMps;

axesInfo.tx_mode = mimo.mode;
axesInfo.tx_group_count = mimo.group_count;

end