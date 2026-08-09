function run_configuration_tests()
%RUN_CONFIGURATION_TESTS Configuration, geometry, TDM and DDMA smoke tests.

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(genpath(fullfile(projectRoot, 'functions')));
addpath(fullfile(projectRoot, 'config'));

expectedTx = [3, 1, 3, 1];
expectedAntStart = [9, 1, 9, 1];
for profileId = 0:3
    file = fullfile(projectRoot, 'config', ...
        sprintf('sensor_config_init%d.hxx', profileId));
    cfg = derive_radar_parameters(load_ctsaia100_config(file));
    assert(strcmp(cfg.mimo.mode, 'SISO'));
    assert(isequal(cfg.mimo.active_tx_indices, expectedTx(profileId+1)));
    assert(cfg.nvirtual_array == 4);
    expectedIndices = expectedAntStart(profileId+1) + (0:3);
    assert(isequal(cfg.virtual_array.source_antenna_index.', expectedIndices));
end

% Synthetic two-group TDM: TX1 in group 1, TX2 in group 2.
cfg = derive_radar_parameters(load_ctsaia100_config(fullfile( ...
    projectRoot, 'config', 'sensor_config_init0.hxx')));
cfg.tx_groups = [hex2dec('0001'), hex2dec('0010'), 0, 0];
cfg = derive_radar_parameters(cfg);
assert(strcmp(cfg.mimo.mode, 'TDM'));
assert(cfg.mimo.group_count == 2);
assert(cfg.nvirtual_array == 8);
raw = zeros(1, cfg.nchirp, cfg.num_rx);
raw(:,1:cfg.slow_time_chirp_num,:) = 11;
raw(:,cfg.slow_time_chirp_num+1:end,:) = 22;
virtual = organize_virtual_array(raw, cfg, 'block');
assert(all(reshape(virtual(:,:,1:4) == 11, [], 1)));
assert(all(reshape(virtual(:,:,5:8) == 22, [], 1)));

% Synthetic two-TX DDMA. Explicit phase increments are required.
cfg = load_ctsaia100_config(fullfile(projectRoot, 'config', ...
    'sensor_config_init0.hxx'));
cfg.tx_groups = [1, 1, 0, 0];
cfg.nchirp = 8;
cfg.vel_nfft = 8;
cfg.ddma_phase_increment_deg = [0, 90, 0, 0];
cfg = derive_radar_parameters(cfg);
assert(strcmp(cfg.mimo.mode, 'DDMA'));
n = 0:cfg.nchirp-1;
a1 = 2;
a2 = 3;
mixture = a1 + a2 * exp(1i * deg2rad(90*n));
raw = repmat(reshape(mixture, 1, [], 1), 1, 1, cfg.num_rx);
virtual = organize_virtual_array(raw, cfg, 'block');
tx1Spectrum = fft(virtual(:,:,1), [], 2);
tx2Spectrum = fft(virtual(:,:,5), [], 2);
assert(abs(tx1Spectrum(1)) > abs(a1*cfg.nchirp) - 1e-9);
assert(abs(tx2Spectrum(1)) > abs(a2*cfg.nchirp) - 1e-9);

% Simultaneous TX without an explicit code must be rejected.
cfg = rmfield(cfg, 'ddma_phase_increment_deg');
cfg = derive_radar_parameters(cfg);
assert(strcmp(cfg.mimo.mode, 'SIMULTANEOUS_UNRESOLVED'));
rejected = false;
try
    organize_virtual_array(raw, cfg, 'block');
catch
    rejected = true;
end
assert(rejected);

fprintf('All CTSAI-A100 configuration/MIMO tests passed.\n');
end
