function [adc, meta] = load_a100_adc(file_path, expected_channel, expected_samples, expected_chirps)
%LOAD_A100_ADC Strictly load a CTSAI-A100 packed text capture.
%   The file format used by the 2026-08-02 captures is:
%     channel, samples_per_chirp, chirp_count, packed_uint32_words..., padding
%   Each uint32 word contains the earlier int16 sample in its high half and
%   the later int16 sample in its low half. Extra values are removed only if
%   every extra value is verified to be zero padding.

if nargin < 2
    expected_channel = [];
end
if nargin < 3 || isempty(expected_samples)
    expected_samples = 1024;
end
if nargin < 4 || isempty(expected_chirps)
    expected_chirps = 256;
end

if mod(expected_samples, 2) ~= 0
    error('a100:OddSampleCount', 'The packed format requires an even sample count.');
end
if ~exist(file_path, 'file')
    error('a100:FileNotFound', 'ADC file not found: %s', file_path);
end

tokens = dlmread(file_path, ',');
tokens = double(tokens(:));
if numel(tokens) < 3
    error('a100:MissingHeader', 'ADC file must start with three header fields.');
end
if any(~isfinite(tokens))
    error('a100:NonFiniteToken', 'ADC file contains a non-finite numeric token.');
end

header = tokens(1:3).';
channel = header(1);
samples_per_chirp = header(2);
chirp_count = header(3);
if channel ~= floor(channel) || channel < 0
    error('a100:InvalidChannel', 'Header channel must be a non-negative integer.');
end
if ~isempty(expected_channel) && channel ~= expected_channel
    error('a100:ChannelMismatch', ...
        'Expected Rx%d but header declares Rx%d.', expected_channel, channel);
end
if samples_per_chirp ~= expected_samples || chirp_count ~= expected_chirps
    error('a100:DimensionHeaderMismatch', ...
        'Expected header [%d, %d] samples/chirps; found [%d, %d].', ...
        expected_samples, expected_chirps, samples_per_chirp, chirp_count);
end

expected_words = expected_samples * expected_chirps / 2;
words_and_padding = tokens(4:end);
if numel(words_and_padding) < expected_words
    error('a100:TruncatedCapture', ...
        'Capture has %d packed words; %d are required.', ...
        numel(words_and_padding), expected_words);
end

padding = words_and_padding(expected_words + 1:end);
if any(padding ~= 0)
    error('a100:NonZeroExcessData', ...
        'Capture has %d excess value(s), and at least one is non-zero.', ...
        numel(padding));
end
words = words_and_padding(1:expected_words);
samples = unpack_a100_words(words);
adc = reshape(samples, expected_samples, expected_chirps);

meta = struct('file', file_path, ...
              'channel', channel, ...
              'samples_per_chirp', expected_samples, ...
              'chirp_count', expected_chirps, ...
              'packed_word_count', expected_words, ...
              'padding_count', numel(padding), ...
              'padding_verified_zero', isempty(padding) || all(padding == 0));
end

