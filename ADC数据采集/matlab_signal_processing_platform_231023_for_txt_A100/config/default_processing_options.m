function opts = default_processing_options()
%DEFAULT_PROCESSING_OPTIONS User-editable processing options.

opts.profile_id = 0; % Example TXT files are profile 0 (Pf0).

opts.io.strict_header = true;
opts.io.allow_zero_pad = false;
opts.io.tx_chirp_layout = 'block'; % 'block' matches the supplied legacy loader.

opts.range_fft.window = 'hann';
opts.range_fft.remove_adc_mean = true;
opts.range_fft.normalize = 'coherent_gain';

opts.doppler_fft.window = 'hann';
opts.doppler_fft.remove_static_clutter = false;
opts.doppler_fft.normalize = 'coherent_gain';

% Fast default. Set algorithm to 'OS' to use OS-CFAR.
opts.cfar.algorithm = 'CA';
opts.cfar.training_cells = [3, 6]; % [range, Doppler] per side.
opts.cfar.guard_cells = [1, 2];
opts.cfar.pfa = 1e-4;
opts.cfar.os_rank_ratio = 0.75;

opts.detection.min_range_m = 0.5;
opts.detection.max_range_m = inf;
opts.detection.zero_doppler_exclusion_bins = 1;
opts.detection.local_peak_half_window = [1, 1];
opts.detection.min_separation_bins = [1, 2];
opts.detection.min_snr_db = 12;
opts.detection.max_detections = 16;

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
