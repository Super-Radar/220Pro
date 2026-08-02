function run_all()
%RUN_ALL Reproduce every simulation and measured-data result in this case study.

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'scripts'));

env = prepare_environment(project_root);
fprintf('A100 indoor-cart MTI case study\n');
fprintf('  Octave/MATLAB: %s\n', env.runtime);
fprintf('  Project root:  %s\n', project_root);

run_simulation(project_root);
run_parameter_studies(project_root);
run_measured_adc_analysis(project_root);
run_target_analysis(project_root);

fprintf('All analyses completed. Results: %s\n', env.results_dir);
end

