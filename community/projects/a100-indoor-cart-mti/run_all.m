function run_all()
%RUN_ALL Reproduce every simulation and measured-data result in this case study.

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'scripts'));

env = prepare_environment(project_root);
fprintf('A100 indoor-cart MTI case study\n');
fprintf('  Octave/MATLAB: %s\n', env.runtime);
fprintf('  Project root:  %s\n', project_root);
manifest = verify_data_manifest(project_root);
fprintf('  Data manifest: %d files, %d bytes, SHA-256 verified\n', ...
    manifest.entry_count, manifest.total_bytes);

simulation_metrics = run_simulation(project_root);
run_parameter_studies(project_root);
adc_metrics = run_measured_adc_analysis(project_root);
target_metrics = run_target_analysis(project_root);
write_headline_metrics(env.results_dir, simulation_metrics, adc_metrics, target_metrics);

fprintf('All analyses completed. Results: %s\n', env.results_dir);
end

function write_headline_metrics(results_dir, simulation, adc_rows, target_rows)
approach_adc = row_by_name(adc_rows, 'approaching_box');
recede_adc = row_by_name(adc_rows, 'receding_box');
stationary_person = row_by_name(target_rows, 'stationary_person_3m');
approaching_cart = row_by_name(target_rows, 'approaching_box');
receding_cart = row_by_name(target_rows, 'receding_box');
receding_person = row_by_name(target_rows, 'receding_person_short');

rows = { ...
    'simulation_range_resolution', simulation.range_resolution_m, 'm', 'teaching_simulation'; ...
    'simulation_velocity_resolution', simulation.velocity_resolution_mps, 'm/s', 'teaching_simulation'; ...
    'simulation_cart_range_error', simulation.cart_range_error_m, 'm', 'teaching_simulation'; ...
    'simulation_cart_velocity_error', simulation.cart_velocity_error_mps, 'm/s', 'teaching_simulation'; ...
    'simulation_static_suppression', simulation.static_suppression_db, 'dB', 'teaching_simulation'; ...
    'measured_adc_approaching_zero_bin_suppression', approach_adc{9}, 'dB', 'real_adc_bin_domain'; ...
    'measured_adc_receding_zero_bin_suppression', recede_adc{9}, 'dB', 'real_adc_bin_domain'; ...
    'measured_stationary_person_roi_detection_fraction', stationary_person{17}, 'fraction', 'real_point_output'; ...
    'measured_stationary_person_median_range', stationary_person{18}, 'm', 'real_point_output'; ...
    'measured_cart_approach_range_slope', approaching_cart{10}, 'm/s', 'real_detection_envelope'; ...
    'measured_cart_recede_range_slope', receding_cart{10}, 'm/s', 'real_detection_envelope'; ...
    'measured_person_recede_range_slope', receding_person{10}, 'm/s', 'real_detection_envelope'};

file_path = fullfile(results_dir, 'metrics.csv');
fid = fopen(file_path, 'w');
if fid < 0
    error('a100:HeadlineMetricsOpenFailed', 'Could not write %s.', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'metric,value,unit,source\n');
for idx = 1:size(rows, 1)
    fprintf(fid, '%s,%.12g,%s,%s\n', rows{idx, :});
end
clear cleanup;
end

function row = row_by_name(rows, name)
matches = find(strcmp(rows(:, 1), name));
if numel(matches) ~= 1
    error('a100:SummaryRowMatch', ...
        'Expected one metrics row named %s; found %d.', name, numel(matches));
end
row = rows(matches(1), :);
end
