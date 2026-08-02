function test_upstream_loader(project_root)
%TEST_UPSTREAM_LOADER Verify the repaired official loader uses the same format.

repository_root = fileparts(fileparts(fileparts(project_root)));
init_dir = fullfile(repository_root, 'ADC数据采集', ...
    'matlab_signal_processing_platform_231023_for_txt_A100', 'init_function');
addpath(init_dir);
path_cleanup = onCleanup(@() rmpath(init_dir));

fixture_dir = tempname;
mkdir(fixture_dir);
fixture = fullfile(fixture_dir, 'fixture_Rx0.txt');
cleanup = onCleanup(@() remove_fixture(fixture_dir));
packed = repmat(pack_pair(321, -654), 1024 * 256 / 2, 1);
write_adc_fixture(fixture, [0, 1024, 256], packed, 0);

cfg = struct('rng_nfft', 1024, 'nchirp', 256, ...
             'nvirtual_chirp', 1, 'nvirtual_array', 1, 'vel_nfft', 256);
adc = load_adc_data({fixture}, cfg);
assert(isequal(size(adc), [1024, 256]));
assert(adc(1, 1) == 321);
assert(adc(2, 1) == -654);

write_adc_fixture(fixture, [0, 1024, 256], packed, [0; 9]);
assert_error_id(@() load_adc_data({fixture}, cfg), 'a100:NonZeroExcessData');

clear cleanup path_cleanup;
end

function word = pack_pair(high_sample, low_sample)
word = mod(double(high_sample), 2^16) * 2^16 + mod(double(low_sample), 2^16);
end

function remove_fixture(directory)
if exist(directory, 'dir')
    files = dir(fullfile(directory, '*'));
    for idx = 1:numel(files)
        if ~files(idx).isdir
            delete(fullfile(files(idx).folder, files(idx).name));
        end
    end
    rmdir(directory);
end
end
