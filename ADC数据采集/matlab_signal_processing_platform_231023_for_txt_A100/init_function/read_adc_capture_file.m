function [samples, metadata] = read_adc_capture_file(file_name, Cfg)
%READ_ADC_CAPTURE_FILE Read one legacy or session-style RadarTools ADC file.

required_fields = {'rng_nfft', 'nchirp'};
for ifield = 1:numel(required_fields)
    field_name = required_fields{ifield};
    if ~isfield(Cfg, field_name)
        error('CTSAI:A100:MissingConfig', ...
            'ADC configuration is missing field "%s".', field_name);
    end
end

if Cfg.rng_nfft <= 0 || mod(Cfg.rng_nfft, 2) ~= 0 || Cfg.nchirp <= 0
    error('CTSAI:A100:InvalidConfig', ...
        'rng_nfft must be a positive even number and nchirp must be positive.');
end

raw_values = csvread(file_name);
raw_values = raw_values(:);

expected_count = (Cfg.rng_nfft / 2) * Cfg.nchirp;
raw_count = numel(raw_values);
metadata = struct( ...
    'has_header', false, ...
    'rx_channel', NaN, ...
    'sample_count', Cfg.rng_nfft, ...
    'chirp_count', Cfg.nchirp, ...
    'has_trailing_zero', false);

% Session-style files add: Rx channel, ADC sample count, chirp count.
if raw_count == expected_count + 3 || raw_count == expected_count + 4
    metadata.has_header = true;
    metadata.rx_channel = raw_values(1);
    metadata.sample_count = raw_values(2);
    metadata.chirp_count = raw_values(3);

    if metadata.rx_channel < 0 || metadata.rx_channel ~= fix(metadata.rx_channel)
        error('CTSAI:A100:InvalidHeader', ...
            'ADC file "%s" contains an invalid Rx channel: %g.', ...
            file_name, metadata.rx_channel);
    end

    if metadata.sample_count ~= Cfg.rng_nfft || ...
            metadata.chirp_count ~= Cfg.nchirp
        error('CTSAI:A100:HeaderConfigMismatch', ...
            ['ADC file "%s" declares %d samples and %d chirps, but the ' ...
             'selected configuration expects %d samples and %d chirps.'], ...
            file_name, metadata.sample_count, metadata.chirp_count, ...
            Cfg.rng_nfft, Cfg.nchirp);
    end

    raw_values = raw_values(4:end);
elseif raw_count ~= expected_count && raw_count ~= expected_count + 1
    error('CTSAI:A100:UnexpectedSampleCount', ...
        ['ADC file "%s" contains %d values; expected %d samples, with an ' ...
         'optional three-value header and optional trailing zero.'], ...
        file_name, raw_count, expected_count);
end

% Both legacy and session-style exports may append one zero sentinel.
if numel(raw_values) == expected_count + 1
    if raw_values(end) ~= 0
        error('CTSAI:A100:UnexpectedTrailingValue', ...
            'ADC file "%s" has an unexpected trailing value: %g.', ...
            file_name, raw_values(end));
    end
    metadata.has_trailing_zero = true;
    raw_values = raw_values(1:end-1);
end

if numel(raw_values) ~= expected_count
    error('CTSAI:A100:UnexpectedSampleCount', ...
        'ADC file "%s" contains %d samples after metadata removal; expected %d.', ...
        file_name, numel(raw_values), expected_count);
end

samples = raw_values;
end
