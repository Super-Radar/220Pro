function [adcData] = load_adc_data(file, Cfg)
%LOAD_ADC_DATA Load CTSAI-A100 packed ADC text captures.
%   Each file starts with three fields:
%     receive_channel, samples_per_chirp, chirp_count
%   The remaining uint32 words each contain two signed int16 ADC samples.
%   Captures may include trailing zero padding. Padding is removed only
%   after it is verified; non-zero excess data and truncated files fail.

nfiles = numel(file);
expected_samples = Cfg.rng_nfft;
expected_chirps = Cfg.nchirp;
if mod(expected_samples, 2) ~= 0
    error('a100:OddSampleCount', ...
        'Cfg.rng_nfft must be even for the packed A100 ADC format.');
end
expected_words = expected_samples * expected_chirps / 2;
target_dim = [expected_samples / 2, expected_chirps];

adcTemp2 = zeros(expected_chirps, expected_samples / 2, nfiles);
for ifile = 1:nfiles
    tokens = csvread(file{ifile});
    tokens = double(tokens(:));
    if numel(tokens) < 3
        error('a100:MissingHeader', ...
            'ADC file must start with channel, sample-count, and chirp-count fields.');
    end
    if any(~isfinite(tokens))
        error('a100:NonFiniteToken', 'ADC file contains a non-finite numeric token.');
    end

    channel = tokens(1);
    samples_per_chirp = tokens(2);
    chirp_count = tokens(3);
    if channel < 0 || channel ~= floor(channel)
        error('a100:InvalidChannel', 'ADC channel header must be a non-negative integer.');
    end
    if samples_per_chirp ~= expected_samples || chirp_count ~= expected_chirps
        error('a100:DimensionHeaderMismatch', ...
            'Expected header dimensions %d x %d; found %d x %d.', ...
            expected_samples, expected_chirps, samples_per_chirp, chirp_count);
    end

    rx_token = regexp(file{ifile}, 'Rx([0-9]+)', 'tokens', 'once');
    if ~isempty(rx_token)
        expected_channel = str2double(rx_token{1});
        if channel ~= expected_channel
            error('a100:ChannelMismatch', ...
                'File name declares Rx%d but header declares Rx%d.', ...
                expected_channel, channel);
        end
    end

    words_and_padding = tokens(4:end);
    if numel(words_and_padding) < expected_words
        error('a100:TruncatedCapture', ...
            'ADC file contains %d packed words; %d are required.', ...
            numel(words_and_padding), expected_words);
    end
    padding = words_and_padding(expected_words + 1:end);
    if any(padding ~= 0)
        error('a100:NonZeroExcessData', ...
            'ADC file has %d excess value(s), including non-zero data.', numel(padding));
    end
    packed_words = words_and_padding(1:expected_words);

    fprintf('Rx%d: header %d x %d, packed words %d, zero padding %d\n', ...
        channel, samples_per_chirp, chirp_count, expected_words, numel(padding));
    packed_matrix = reshape(packed_words, target_dim);
    adcTemp2(:, :, ifile) = packed_matrix.';
end

if Cfg.nvirtual_chirp == 1
    for iArray = 1:Cfg.nvirtual_array
        adcData(:, :, iArray) = permute( ...
            adc_mem_2_real_fixed(adcTemp2(:, :, iArray)), [2, 1]);
    end
else
    for iArray = 1:Cfg.nvirtual_array / Cfg.nvirtual_chirp
        adcTx1 = adcTemp2(1:Cfg.vel_nfft, :, iArray);
        adcTx2 = adcTemp2(Cfg.vel_nfft + 1:end, :, iArray);
        adcData(:, :, iArray * 2 - 1) = permute( ...
            adc_mem_2_real_fixed(adcTx1), [2, 1]);
        adcData(:, :, iArray * 2) = permute( ...
            adc_mem_2_real_fixed(adcTx2), [2, 1]);
    end
end
end
