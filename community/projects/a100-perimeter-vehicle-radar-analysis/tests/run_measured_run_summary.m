clear;
clc;

%% ============================================================
% CTSAI-A100 Issue #13
% Batch summary of all measured Rx0 acquisition samples.
%
% IMPORTANT:
%
% run_001 ... run_005 are treated as DISCRETE acquisition
% samples, NOT as a continuous uniformly sampled trajectory.
%% ============================================================

%% Project root

thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));

dataRoot = fullfile( ...
    projectRoot, ...
    'data', ...
    'measured');

resultRoot = fullfile( ...
    projectRoot, ...
    'results', ...
    'measured');

if ~exist(resultRoot, 'dir')
    mkdir(resultRoot);
end

%% Radar configuration

configFile = fullfile( ...
    projectRoot, ...
    'config', ...
    'sensor_config_init0.hxx');

cfg = load_ctsaia100_config(configFile);

%% Analysis options

analysisOpts = struct();

analysisOpts.zero_half_width_bins = 2;

% Ignore first two range bins when searching for the
% strongest non-zero-Doppler moving-target peak.
analysisOpts.range_guard_bins = 2;

analysisOpts.allow_zero_pad = false;

%% Scene list

sceneNames = {
    'empty'
    'vehicle_approaching'
    'vehicle_receding'
};

%% Result structure

rows = struct([]);

rowIndex = 0;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' CTSAI-A100 Issue #13 - All Measured Rx0 Samples\n');
fprintf('============================================================\n\n');

%% Process scenes

for iScene = 1:numel(sceneNames)

    sceneName = sceneNames{iScene};

    sceneDir = fullfile( ...
        dataRoot, ...
        sceneName);

    files = dir(fullfile( ...
        sceneDir, ...
        'run_*_Pf0_Rx0.txt'));

    if isempty(files)
        warning( ...
            'No Rx0 files found for scene: %s', ...
            sceneName);

        continue;
    end

    % Filename order is already suitable for run_001 ... run_005,
    % but explicitly sort for reproducibility.

    [~, sortIndex] = sort({files.name});

    files = files(sortIndex);

    fprintf('Scene: %s\n', sceneName);
    fprintf('Samples: %d\n\n', numel(files));

    for iFile = 1:numel(files)

        fileName = files(iFile).name;

        filePath = fullfile( ...
            files(iFile).folder, ...
            fileName);

        metrics = analyze_measured_rx_file( ...
            filePath, ...
            cfg, ...
            analysisOpts);

        rowIndex = rowIndex + 1;

        %% Extract run number

        token = regexp( ...
            fileName, ...
            'run_(\d+)_', ...
            'tokens', ...
            'once');

        if isempty(token)
            runNumber = iFile;
        else
            runNumber = str2double(token{1});
        end

        %% Store result

        rows(rowIndex).scene = ...
            sceneName;

        rows(rowIndex).run = ...
            runNumber;

        rows(rowIndex).rx = ...
            metrics.rx_index;

        rows(rowIndex).peak_range_m = ...
            metrics.peak_range_m;

        rows(rowIndex).peak_velocity_mps = ...
            metrics.peak_velocity_mps;

        rows(rowIndex).peak_power_db = ...
            metrics.peak_power_db;

        rows(rowIndex).mti2_zero_doppler_suppression_db = ...
            metrics.mti2_zero_doppler_suppression_db;

        rows(rowIndex).positive_moving_energy_db = ...
            metrics.positive_moving_energy_db;

        rows(rowIndex).negative_moving_energy_db = ...
            metrics.negative_moving_energy_db;

        rows(rowIndex).positive_minus_negative_db = ...
            metrics.positive_minus_negative_db;

        %% Print

        fprintf( ...
            '  run_%03d | peak R = %8.3f m | v = %+8.3f m/s | ', ...
            runNumber, ...
            metrics.peak_range_m, ...
            metrics.peak_velocity_mps);

        fprintf( ...
            'Pos-Neg = %+7.2f dB | MTI2 = %6.2f dB\n', ...
            metrics.positive_minus_negative_db, ...
            metrics.mti2_zero_doppler_suppression_db);

    end

    fprintf('\n');

end

%% Convert to table

if isempty(rows)
    error('No measured results were generated.');
end

summaryTable = struct2table(rows);

%% Save CSV

summaryFile = fullfile( ...
    resultRoot, ...
    'measured_run_summary.csv');

writetable( ...
    summaryTable, ...
    summaryFile);

%% Display table

fprintf('============================================================\n');
fprintf(' Measured discrete-sample summary\n');
fprintf('============================================================\n\n');

disp(summaryTable);

fprintf('\nSummary CSV:\n%s\n', summaryFile);

%% Explain the Doppler-energy metric

fprintf('\n');
fprintf('Interpretation of Pos-Neg metric:\n');
fprintf('---------------------------------------------\n');

fprintf([ ...
    'Positive value: more MTI2 moving energy is on the ' ...
    'positive Doppler side.\n']);

fprintf([ ...
    'Negative value: more MTI2 moving energy is on the ' ...
    'negative Doppler side.\n']);

fprintf([ ...
    'The physical approaching/receding sign convention should ' ...
    'be inferred only after comparing the measured scenes.\n']);

fprintf('\n');

fprintf([ ...
    'IMPORTANT: run numbers are discrete acquisitions and must ' ...
    'not be interpreted as a continuous vehicle trajectory.\n']);

fprintf('\n');