function test_read_adc_capture_file()
%TEST_READ_ADC_CAPTURE_FILE Regression tests for RadarTools ADC file parsing.

test_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(test_dir);
addpath(fullfile(project_dir, 'init_function'));

Cfg = struct('rng_nfft', 8, 'nchirp', 2);
expected = (101:108).';
temp_dir = tempname;
mkdir(temp_dir);
cleanup = onCleanup(@() rmdir(temp_dir, 's'));

session_file = fullfile(temp_dir, 'run_001_Pf0_Rx0.txt');
write_values(session_file, [0, 8, 2, expected.', 0]);
[samples, metadata] = read_adc_capture_file(session_file, Cfg);
assert(isequal(samples, expected));
assert(metadata.has_header);
assert(metadata.rx_channel == 0);
assert(metadata.has_trailing_zero);

legacy_file = fullfile(temp_dir, 'adc_rx0.txt');
write_values(legacy_file, [expected.', 0]);
[samples, metadata] = read_adc_capture_file(legacy_file, Cfg);
assert(isequal(samples, expected));
assert(~metadata.has_header);
assert(metadata.has_trailing_zero);

plain_file = fullfile(temp_dir, 'adc_without_sentinel.txt');
write_values(plain_file, expected.');
[samples, metadata] = read_adc_capture_file(plain_file, Cfg);
assert(isequal(samples, expected));
assert(~metadata.has_header);
assert(~metadata.has_trailing_zero);

mismatch_file = fullfile(temp_dir, 'header_mismatch.txt');
write_values(mismatch_file, [0, 16, 2, expected.', 0]);
assert_error(@() read_adc_capture_file(mismatch_file, Cfg), ...
    'CTSAI:A100:HeaderConfigMismatch');

trailing_file = fullfile(temp_dir, 'unexpected_trailing_value.txt');
write_values(trailing_file, [expected.', 99]);
assert_error(@() read_adc_capture_file(trailing_file, Cfg), ...
    'CTSAI:A100:UnexpectedTrailingValue');

short_file = fullfile(temp_dir, 'short_capture.txt');
write_values(short_file, expected(1:end-1).');
assert_error(@() read_adc_capture_file(short_file, Cfg), ...
    'CTSAI:A100:UnexpectedSampleCount');

clear cleanup;
fprintf('PASS test_read_adc_capture_file\n');
end

function write_values(file_name, values)
dlmwrite(file_name, values, 'delimiter', ',', 'precision', '%.0f');
end

function assert_error(callback, expected_identifier)
caught = false;
try
    callback();
catch exception
    caught = true;
    assert(strcmp(exception.identifier, expected_identifier), ...
        'Expected error "%s", received "%s".', ...
        expected_identifier, exception.identifier);
end
assert(caught, 'Expected error "%s" was not raised.', expected_identifier);
end
