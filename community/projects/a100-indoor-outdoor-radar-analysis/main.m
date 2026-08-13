function main()
%MAIN CTSAI-A100 Issue #8 indoor/outdoor radar analysis.

fprintf('\n');
fprintf('=========================================================\n');
fprintf(' CTSAI-A100 Indoor / Outdoor Radar Analysis\n');
fprintf('=========================================================\n\n');

projectRoot = fileparts(mfilename('fullpath'));

%% Part 1 - Measured data

fprintf('PART 1 - Measured indoor/outdoor ADC analysis\n');
fprintf('=========================================================\n');

run(fullfile( ...
    projectRoot, ...
    'tests', ...
    'run_measured_scene_analysis.m'));

projectRoot = fileparts(mfilename('fullpath'));

%% Part 2 - LFMCW simulation

fprintf('\n');
fprintf('PART 2 - MATLAB LFMCW simulation\n');
fprintf('=========================================================\n');

run(fullfile( ...
    projectRoot, ...
    'tests', ...
    'run_lfmcw_simulation.m'));

projectRoot = fileparts(mfilename('fullpath'));

%% Part 3 - Parameter studies

fprintf('\n');
fprintf('PART 3 - Radar parameter studies\n');
fprintf('=========================================================\n');

run(fullfile( ...
    projectRoot, ...
    'tests', ...
    'run_parameter_studies.m'));

fprintf('\n');
fprintf('=========================================================\n');
fprintf(' All Issue #8 experiments completed successfully.\n');
fprintf('=========================================================\n\n');

end