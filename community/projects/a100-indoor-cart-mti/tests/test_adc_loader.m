function test_adc_loader()
%TEST_ADC_LOADER Unit tests for header validation and packed-word decoding.

fixture = [tempname '.txt'];
cleanup = onCleanup(@() delete_if_exists(fixture));

sample_pair = [1234; -2345];
packed = pack_pair(sample_pair(1), sample_pair(2));
words = repmat(packed, 1024 * 256 / 2, 1);
write_adc_fixture(fixture, [2, 1024, 256], words, 0);
[adc, meta] = load_a100_adc(fixture, 2);
assert(isequal(size(adc), [1024, 256]));
assert(adc(1, 1) == sample_pair(1));
assert(adc(2, 1) == sample_pair(2));
assert(meta.padding_count == 1);
assert(meta.padding_verified_zero);

assert_error_id(@() load_a100_adc(fixture, 1), 'a100:ChannelMismatch');

write_adc_fixture(fixture, [2, 512, 256], words, 0);
assert_error_id(@() load_a100_adc(fixture, 2), 'a100:DimensionHeaderMismatch');

write_adc_fixture(fixture, [2, 1024, 256], words(1:end-1), []);
assert_error_id(@() load_a100_adc(fixture, 2), 'a100:TruncatedCapture');

write_adc_fixture(fixture, [2, 1024, 256], words, [0; 7]);
assert_error_id(@() load_a100_adc(fixture, 2), 'a100:NonZeroExcessData');

clear cleanup;
delete_if_exists(fixture);
end

function word = pack_pair(high_sample, low_sample)
high_u16 = mod(double(high_sample), 2^16);
low_u16 = mod(double(low_sample), 2^16);
word = high_u16 * 2^16 + low_u16;
end

function delete_if_exists(file_path)
if exist(file_path, 'file')
    delete(file_path);
end
end

