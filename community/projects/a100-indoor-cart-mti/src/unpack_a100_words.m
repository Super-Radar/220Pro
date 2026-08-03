function samples = unpack_a100_words(words)
%UNPACK_A100_WORDS Convert packed uint32 words to high-then-low int16 samples.

words = double(words(:));
max_uint32 = 2^32 - 1;
if any(~isfinite(words)) || any(words < 0) || any(words > max_uint32) || ...
        any(words ~= floor(words))
    error('a100:InvalidPackedWord', ...
        'Packed ADC words must be finite integer values in the uint32 range.');
end

high = floor(words / 2^16);
low = mod(words, 2^16);
high(high >= 2^15) = high(high >= 2^15) - 2^16;
low(low >= 2^15) = low(low >= 2^15) - 2^16;

samples = zeros(numel(words) * 2, 1);
samples(1:2:end) = high;
samples(2:2:end) = low;
end

