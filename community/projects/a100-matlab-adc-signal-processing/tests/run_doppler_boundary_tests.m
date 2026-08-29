function run_doppler_boundary_tests()
%RUN_DOPPLER_BOUNDARY_TESTS 验证 Doppler 周期边界在检测链中的一致语义。
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(genpath(fullfile(projectRoot, 'functions')));

% 卷积仅环绕 Doppler；Range 端点仍使用零填充。
assert(isequal(conv2_doppler_periodic([1,2,3,4], [1,0,1]), ...
    [6,4,6,4]));
assert(isequal(conv2_doppler_periodic([1;2;3], [1;0;1]), ...
    [2;4;2]));

test_cfar_shift_equivariance();
test_local_peak_wraps();
test_music_snapshots_wrap();
fprintf('All Doppler boundary tests passed.\n');
end

function test_cfar_shift_equivariance()
powerMap = reshape(mod((1:13*12) * 17, 101) + 1, 13, 12);
opts.training_cells = [1, 2];
opts.guard_cells = [1, 1];
opts.pfa = 1e-3;
opts.os_rank_ratio = 0.75;
opts.vi_threshold = 2.5;
opts.mean_ratio_threshold = 2.8;
opts.min_homogeneous_sectors = 1;
algorithms = {'CA','OS','GOCA','SOCA','VI'};
shift = 3;
fields = {'mask','noise','threshold','snr_db','alpha_map', ...
    'num_training_cells','method_map','variability_index', ...
    'sector_mean_ratio'};

for iAlgorithm = 1:numel(algorithms)
    opts.algorithm = algorithms{iAlgorithm};
    original = cfar_2d(powerMap, opts);
    shifted = cfar_2d(circshift(powerMap, [0, shift]), opts);
    assert(isequal(original.edge_margin, [2, 0]));
    edgeMethods = original.method_map(3:end-2, [1,end]);
    assert(all(edgeMethods(:) > 0));
    for iField = 1:numel(fields)
        expected = circshift(original.(fields{iField}), [0, shift]);
        assert_close(shifted.(fields{iField}), expected);
    end
end
end

function test_local_peak_wraps()
numRange = 5;
numDoppler = 8;
powerMap = ones(numRange, numDoppler);
powerMap(3,1) = 10;
powerMap(3,end) = 20;
cfarResult.mask = false(numRange, numDoppler);
cfarResult.mask(3,[1,end]) = true;
cfarResult.power = powerMap;
cfarResult.noise = ones(size(powerMap));
cfarResult.threshold = ones(size(powerMap));
cfarResult.algorithm = 'CA';
cfarResult.method_map = ones(size(powerMap), 'uint8');
cfarResult.method_names = {'INVALID','CA'};
cfarResult.variability_index = zeros(size(powerMap));
cfarResult.sector_mean_ratio = ones(size(powerMap));

cfg.range_axis_m = 0:numRange-1;
cfg.velocity_axis_mps = 1:numDoppler;
cfg.max_range_m = cfg.range_axis_m(end);
opts.min_range_m = 0;
opts.max_range_m = inf;
opts.zero_doppler_exclusion_bins = 0;
opts.local_peak_half_window = [0, 1];
opts.min_separation_bins = [0, 0];
opts.min_snr_db = -inf;
opts.max_detections = 8;
detections = extract_detections(cfarResult, cfg, opts);
assert(height(detections) == 1);
assert(detections.DopplerBin == numDoppler);
end

function test_music_snapshots_wrap()
numRange = 3;
numDoppler = 8;
numChannels = 4;
rdCube = complex(zeros(numRange, numDoppler, numChannels));
for iRange = 1:numRange
    for iDoppler = 1:numDoppler
        for iChannel = 1:numChannels
            phase = 0.13*iRange + 0.31*iDoppler*iChannel;
            rdCube(iRange,iDoppler,iChannel) = ...
                (iRange + iDoppler/10) * exp(1i*phase);
        end
    end
end

cfg.virtual_array.positions_lambda = (0:numChannels-1).' * 0.5;
cfg.virtual_array.phase_error_deg = zeros(numChannels,1);
opts.grid_deg = -60:2:60;
opts.grid_step_deg = 2;
opts.apply_phase_calibration = true;
opts.fft_size = 64;
opts.fft_grid_spacing_lambda = 0.5;
opts.music_signal_count = 1;
opts.music_snapshot_half_window = [1, 1];
opts.music_diagonal_loading = 1e-3;
opts.omp_max_sources = 1;
opts.selected_method = 'MUSIC';

detection = table(2, 1, 1, 0, ...
    'VariableNames', {'RangeBin','DopplerBin','Range_m','Velocity_mps'});
[anglesAtEdge, edgeDiagnostics] = estimate_angles_for_detections( ...
    rdCube, detection, cfg, opts);
shift = 3;
detection.DopplerBin = 1 + shift;
[anglesInside, insideDiagnostics] = estimate_angles_for_detections( ...
    circshift(rdCube, [0, shift, 0]), detection, cfg, opts);

angleFields = {'AngleFFT_deg','DML_deg','MUSIC_deg','OMP_deg', ...
    'SelectedAngle_deg'};
for iField = 1:numel(angleFields)
    assert_close(anglesAtEdge.(angleFields{iField}), ...
        anglesInside.(angleFields{iField}));
end
assert_close(edgeDiagnostics.music_spectrum, ...
    insideDiagnostics.music_spectrum);
end

function assert_close(actual, expected)
assert(isequal(size(actual), size(expected)));
assert(isequal(isnan(actual), isnan(expected)));
finite = ~isnan(actual) & ~isinf(actual) & ...
    ~isnan(expected) & ~isinf(expected);
if any(finite(:))
    scale = max(1, max(abs(expected(finite))));
    assert(max(abs(double(actual(finite)) - double(expected(finite)))) ...
        <= 1e-10 * scale);
end
assert(isequal(isinf(actual), isinf(expected)));
end
