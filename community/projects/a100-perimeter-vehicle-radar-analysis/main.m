function main()
%MAIN CTSAI-A100 perimeter vehicle radar analysis.
%
% Main entry point for Issue #13 Community Project.
%
% The program runs:
%   1. measured ADC analysis
%   2. LFMCW comprehensive simulation
%   3. LFMCW parameter studies

fprintf('\n');
fprintf('=========================================================\n');
fprintf(' CTSAI-A100 Perimeter Vehicle Radar Analysis\n');
fprintf('=========================================================\n\n');

projectRoot = fileparts(mfilename('fullpath'));

%% Part 1 - Measured CTSAI-A100 data

fprintf('\n');
fprintf('PART 1 - Measured CTSAI-A100 ADC analysis\n');
fprintf('=========================================================\n');

run(fullfile( ...
    projectRoot, ...
    'tests', ...
    'run_measured_physical_analysis.m'));

%% Rebuild path because the test script contains clear

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
fprintf(' All Issue #13 experiments completed successfully.\n');
fprintf('=========================================================\n\n');

end