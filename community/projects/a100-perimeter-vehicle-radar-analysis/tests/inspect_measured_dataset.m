clear;
clc;

% Locate project root automatically
thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

% Add project functions to MATLAB path
addpath(genpath(fullfile(projectRoot, 'functions')));

% Measured data root
dataRoot = fullfile(projectRoot, 'data', 'measured');

sceneDirs = {
    'empty'
    'vehicle_approaching'
    'vehicle_receding'
};

ioOpts.allow_zero_pad = false;

fprintf('CTSAI-A100 Issue #13 measured dataset inspection\n\n');

totalFiles = 0;

for iScene = 1:numel(sceneDirs)

    sceneName = sceneDirs{iScene};
    scenePath = fullfile(dataRoot, sceneName);

    files = dir(fullfile(scenePath, '*.txt'));

    fprintf('Scene: %s\n', sceneName);
    fprintf('Files: %d\n', numel(files));

    for iFile = 1:numel(files)

        filePath = fullfile(files(iFile).folder, files(iFile).name);

        [~, header, trailer] = read_adc_txt(filePath, ioOpts);

        fprintf(['  %-35s RX=%d samples/chirp=%d ' ...
                 'chirps=%d trailer=%d\n'], ...
            files(iFile).name, ...
            header.rx_index, ...
            header.samples_per_chirp, ...
            header.chirp_count, ...
            numel(trailer));

        totalFiles = totalFiles + 1;
    end

    fprintf('\n');
end

fprintf('Total TXT files: %d\n', totalFiles);