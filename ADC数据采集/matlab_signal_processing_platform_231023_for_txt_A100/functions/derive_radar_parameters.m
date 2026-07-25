function cfg = derive_radar_parameters(cfg)
%DERIVE_RADAR_PARAMETERS Add physical axes and data-shape parameters.
required = {'fmcw_startfreq','fmcw_bandwidth','fmcw_chirp_rampup', ...
    'fmcw_chirp_period','nchirp','adc_freq','dec_factor', ...
    'adc_sample_start','adc_sample_end','rng_nfft','vel_nfft','tx_groups'};
for iField = 1:numel(required)
    if ~isfield(cfg, required{iField})
        error('Missing configuration field: %s', required{iField});
    end
end

% Preserve the transmit-group interpretation used by the supplied example.
maxTxGroup = uint32(max(cfg.tx_groups(:)));
nVirtualChirp = 1;
for iTx = 4:-1:1
    if bitget(maxTxGroup, 1 + (iTx - 1) * 4)
        nVirtualChirp = iTx;
        break;
    end
end
cfg.nvirtual_chirp = nVirtualChirp;
cfg.num_rx = 4;
cfg.nvirtual_array = cfg.num_rx * cfg.nvirtual_chirp;

if cfg.dec_factor > 1
    nAdc = round((cfg.adc_sample_end - cfg.adc_sample_start) * ...
        cfg.adc_freq / cfg.dec_factor) + 1;
else
    nAdc = round((cfg.adc_sample_end - cfg.adc_sample_start) * ...
        cfg.adc_freq / cfg.dec_factor);
end
cfg.adc_sample_num = min(nAdc, cfg.rng_nfft);

c0 = 299792458;
cfg.carrier_hz = cfg.fmcw_startfreq * 1e9;
cfg.lambda_m = c0 / cfg.carrier_hz;
cfg.adc_sample_rate_hz = cfg.adc_freq * 1e6 / cfg.dec_factor;
cfg.chirp_slope_hz_per_s = cfg.fmcw_bandwidth * 1e6 / ...
    (cfg.fmcw_chirp_rampup * 1e-6);

cfg.range_bin_num = cfg.rng_nfft / 2;
cfg.range_resolution_m = c0 * cfg.adc_sample_rate_hz / ...
    (2 * cfg.chirp_slope_hz_per_s * cfg.rng_nfft);
cfg.range_axis_m = (0:cfg.range_bin_num-1) * cfg.range_resolution_m;
cfg.max_range_m = cfg.range_axis_m(end);

cfg.slow_time_chirp_num = cfg.nchirp / cfg.nvirtual_chirp;
if abs(cfg.slow_time_chirp_num - round(cfg.slow_time_chirp_num)) > eps
    error('nchirp must be divisible by nvirtual_chirp.');
end
cfg.same_tx_chirp_period_s = cfg.fmcw_chirp_period * 1e-6 * ...
    cfg.nvirtual_chirp;
cfg.velocity_resolution_mps = cfg.lambda_m / ...
    (2 * cfg.same_tx_chirp_period_s * cfg.vel_nfft);
if mod(cfg.vel_nfft, 2) == 0
    dopplerBins = -cfg.vel_nfft/2:cfg.vel_nfft/2-1;
else
    dopplerBins = -(cfg.vel_nfft-1)/2:(cfg.vel_nfft-1)/2;
end
cfg.velocity_axis_mps = dopplerBins * cfg.velocity_resolution_mps;
cfg.max_unambiguous_velocity_mps = cfg.lambda_m / ...
    (4 * cfg.same_tx_chirp_period_s);
end
