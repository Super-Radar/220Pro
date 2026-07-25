function opts = default_processing_options()
%DEFAULT_PROCESSING_OPTIONS User-editable processing options.

opts.profile_id = 0; % Example TXT files are profile 0 (Pf0).

opts.io.strict_header = true;
opts.io.allow_zero_pad = false;
opts.io.tx_chirp_layout = 'block'; % 'block' matches the supplied legacy loader.

opts.range_fft.window = 'hann';
opts.range_fft.remove_adc_mean = true;
opts.range_fft.normalize = 'coherent_gain';

% Advanced slow-time clutter suppression. Supported methods:
% 'NONE', 'MEAN', 'MTI2', 'MTI3', 'SVD', 'SVD_MEAN', 'SVD_MTI2'.
% SVD is the competition-oriented default; set to MEAN for a fast baseline.
opts.clutter.method = 'SVD';
opts.clutter.svd_rank = 1;
opts.clutter.svd_energy_fraction = []; % Empty uses svd_rank.
opts.clutter.svd_max_rank = 3;
opts.clutter.svd_center_rows = false;
opts.clutter.normalize_output_power = false;

opts.doppler_fft.window = 'hann';
% Kept for backward compatibility. Normally leave false because the
% dedicated clutter stage runs before Doppler FFT.
opts.doppler_fft.remove_static_clutter = false;
opts.doppler_fft.normalize = 'coherent_gain';

% CFAR algorithms: 'CA', 'OS', 'GOCA', 'SOCA', or 'VI'.
% VI is a practical two-dimensional variability-index adaptive CFAR. It
% switches among CA, GOCA and homogeneous-sector selection.
opts.cfar.algorithm = 'VI';
opts.cfar.training_cells = [3, 6]; % [range, Doppler] per side.
opts.cfar.guard_cells = [1, 2];
opts.cfar.pfa = 1e-4;
opts.cfar.os_rank_ratio = 0.75;
opts.cfar.vi_threshold = 2.5;          % Local variance / mean^2 threshold.
opts.cfar.mean_ratio_threshold = 2.8;  % Max/min sector mean ratio.
opts.cfar.min_homogeneous_sectors = 1;

opts.detection.min_range_m = 0.5;
opts.detection.max_range_m = inf;
opts.detection.zero_doppler_exclusion_bins = 1;
opts.detection.local_peak_half_window = [1, 1];
opts.detection.min_separation_bins = [1, 2];
opts.detection.min_snr_db = 12;
opts.detection.max_detections = 16;

% Two-dimensional quadratic interpolation of the log-power 3x3 patch.
% Coarse FFT-grid results remain in Range_m/Velocity_mps; refined values
% are written to RangeRefined_m/VelocityRefined_mps.
opts.subbin.enable = true;
opts.subbin.method = 'QUADRATIC_2D_LOG';
opts.subbin.max_abs_offset_bins = 0.5;
opts.subbin.min_negative_curvature = 1e-6;
opts.subbin.use_separable_fallback = true;

% All four methods are always evaluated. selected_method controls the angle
% used in the final point cloud and SelectedAngle_deg column.
opts.angle.selected_method = 'MUSIC'; % 'ANGLE_FFT', 'DML', 'MUSIC', 'OMP'
opts.angle.grid_deg = [];              % Empty: use bfm_az_left/right.
opts.angle.grid_step_deg = 0.25;
opts.angle.apply_phase_calibration = true;
opts.angle.fft_size = 512;
opts.angle.fft_grid_spacing_lambda = 0.5;
opts.angle.music_signal_count = 1;
opts.angle.music_snapshot_half_window = [1, 1];
opts.angle.music_diagonal_loading = 1e-3;
opts.angle.omp_max_sources = 1;

opts.figures.visible = 'on';
opts.figures.save_png = true;
opts.figures.close_after_save = false;
opts.figures.dynamic_range_db = 55;

opts.output.write_mat = true;
end
