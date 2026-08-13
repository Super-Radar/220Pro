function cfg = derive_radar_parameters(cfg)
%DERIVE_RADAR_PARAMETERS Add physical axes, MIMO mode and channel geometry.
required = {'fmcw_startfreq','fmcw_bandwidth','fmcw_chirp_rampup', ...
    'fmcw_chirp_period','nchirp','adc_freq','dec_factor', ...
    'adc_sample_start','adc_sample_end','rng_nfft','vel_nfft','tx_groups'};
for iField = 1:numel(required)
    if ~isfield(cfg, required{iField})
        error('Missing configuration field: %s', required{iField});
    end
end

if isfield(cfg, 'num_rx')
    cfg.num_rx = round(double(cfg.num_rx));
else
    cfg.num_rx = 4;
end
if cfg.num_rx <= 0
    error('num_rx must be positive.');
end

cfg.mimo = decode_tx_groups(cfg, cfg.num_rx);
cfg.nvirtual_chirp = cfg.mimo.group_count; % Legacy-compatible group count.
cfg.nvirtual_array = cfg.mimo.virtual_tx_link_count * cfg.num_rx;

if cfg.dec_factor <= 0
    error('dec_factor must be positive.');
end
if cfg.dec_factor > 1
    nAdc = round((cfg.adc_sample_end - cfg.adc_sample_start) * ...
        cfg.adc_freq / cfg.dec_factor) + 1;
else
    nAdc = round((cfg.adc_sample_end - cfg.adc_sample_start) * ...
        cfg.adc_freq / cfg.dec_factor);
end
cfg.adc_sample_num = min(nAdc, cfg.rng_nfft);
if cfg.adc_sample_num <= 0
    error('Derived ADC sample count is not positive.');
end

c0 = 299792458;
cfg.carrier_hz = cfg.fmcw_startfreq * 1e9;
cfg.lambda_m = c0 / cfg.carrier_hz;
cfg.adc_sample_rate_hz = cfg.adc_freq * 1e6 / cfg.dec_factor;
cfg.chirp_slope_hz_per_s = cfg.fmcw_bandwidth * 1e6 / ...
    (cfg.fmcw_chirp_rampup * 1e-6);

cfg.range_bin_num = floor(cfg.rng_nfft / 2);
cfg.range_resolution_m = c0 * cfg.adc_sample_rate_hz / ...
    (2 * cfg.chirp_slope_hz_per_s * cfg.rng_nfft);
cfg.range_axis_m = (0:cfg.range_bin_num-1) * cfg.range_resolution_m;
cfg.max_range_m = cfg.range_axis_m(end);

cfg.slow_time_chirp_num = cfg.nchirp / cfg.mimo.group_count;
if abs(cfg.slow_time_chirp_num - round(cfg.slow_time_chirp_num)) > ...
        100 * eps(max(1, abs(cfg.slow_time_chirp_num)))
    error('nchirp must be divisible by the active TX chirp-group count.');
end
cfg.slow_time_chirp_num = round(cfg.slow_time_chirp_num);
cfg.same_tx_chirp_period_s = cfg.fmcw_chirp_period * 1e-6 * ...
    cfg.mimo.group_count;
cfg.velocity_resolution_mps = cfg.lambda_m / ...
    (2 * cfg.same_tx_chirp_period_s * cfg.vel_nfft);
if mod(cfg.vel_nfft, 2) == 0
    dopplerBins = -cfg.vel_nfft/2:cfg.vel_nfft/2-1;
else
    dopplerBins = -(cfg.vel_nfft-1)/2:(cfg.vel_nfft-1)/2;
end
cfg.doppler_bin_axis = dopplerBins;
cfg.velocity_axis_mps = dopplerBins * cfg.velocity_resolution_mps;
cfg.max_unambiguous_velocity_mps = cfg.lambda_m / ...
    (4 * cfg.same_tx_chirp_period_s);

if cfg.mimo.ddma_ready
    cfg.mimo.ddma_offset_bins_by_tx = ...
        cfg.mimo.ddma_phase_step_deg_by_tx / 360 * cfg.vel_nfft;
else
    cfg.mimo.ddma_offset_bins_by_tx = nan(1, cfg.mimo.num_physical_tx);
end
cfg.virtual_array = build_virtual_array_geometry(cfg);
% Legacy aliases used by init_function/doa_init.m.
cfg.antena_position = cfg.virtual_array.positions_lambda.';
cfg.antena_phase = cfg.virtual_array.phase_error_deg.';
end
