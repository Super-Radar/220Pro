clear;
clc;

thisFile = mfilename('fullpath');
testDir = fileparts(thisFile);
projectRoot = fileparts(testDir);

addpath(genpath(fullfile(projectRoot, 'functions')));

dataRoot = fullfile(projectRoot, 'data', 'measured');

sceneDirs = {
    'indoor_case_01'
    'indoor_case_02'
    'indoor_case_03'
    'outdoor_case_01'
};

ioOpts.allow_zero_pad = false;

fprintf('\n');
fprintf('CTSAI-A100 Issue #8 measured dataset inspection\n\n');

totalFiles = 0;

for iScene = 1:numel(sceneDirs)

    sceneName = sceneDirs{iScene};
    scenePath = fullfile(dataRoot, sceneName);

    files = dir(fullfile(scenePath, '*.txt'));

    sampleCounts = [];
    chirpCounts = [];
    rxIndices = [];

    fprintf('Scene: %s\n', sceneName);
    fprintf('TXT files: %d\n', numel(files));

    for iFile = 1:numel(files)

        filePath = fullfile( ...
            files(iFile).folder, ...
            files(iFile).name);

        [~, header, ~] = ...
            read_adc_txt(filePath, ioOpts);

        sampleCounts(end+1) = ...
            header.samples_per_chirp;

        chirpCounts(end+1) = ...
            header.chirp_count;

        rxIndices(end+1) = ...
            header.rx_index;

        totalFiles = totalFiles + 1;
    end

    fprintf('RX indices       : %s\n', ...
        mat2str(unique(rxIndices)));

    fprintf('Samples/chirp    : %s\n', ...
        mat2str(unique(sampleCounts)));

    fprintf('Chirps/frame     : %s\n\n', ...
        mat2str(unique(chirpCounts)));

end

fprintf('Total repository sample TXT files: %d\n', totalFiles);