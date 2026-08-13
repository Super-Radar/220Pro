function [outputCube, diagnostics] = suppress_clutter(inputCube, clutterOpts)
%SUPPRESS_CLUTTER Slow-time clutter suppression for a range FFT cube.
% Input/output dimensions are [range, slow-time chirp, channel].
%
% Supported methods:
%   NONE      : no processing
%   MEAN      : remove the slow-time mean at every range/channel cell
%   MTI2      : two-pulse canceller, y[n] = x[n] - x[n-1]
%   MTI3      : three-pulse canceller, y[n] = x[n]-2x[n-1]+x[n-2]
%   SVD       : remove dominant low-rank components from the global
%               range-channel by slow-time matrix
%   SVD_MEAN  : SVD suppression followed by slow-time mean removal
%   SVD_MTI2  : SVD suppression followed by a two-pulse canceller

if nargin < 2 || ~isfield(clutterOpts, 'method')
    error('clutterOpts.method is required.');
end

method = upper(strtrim(clutterOpts.method));
inputCube = double(inputCube);
inputPower = mean(abs(inputCube(:)).^2);
outputCube = inputCube;
removedRank = 0;
singularValues = [];

switch method
    case 'NONE'
        % No processing.

    case 'MEAN'
        outputCube = remove_slow_time_mean(outputCube);

    case 'MTI2'
        outputCube = apply_mti(outputCube, 2);

    case 'MTI3'
        outputCube = apply_mti(outputCube, 3);

    case {'SVD', 'SVD_MEAN', 'SVD_MTI2'}
        [outputCube, singularValues, removedRank] = ...
            remove_low_rank_svd(outputCube, clutterOpts);
        if strcmp(method, 'SVD_MEAN')
            outputCube = remove_slow_time_mean(outputCube);
        elseif strcmp(method, 'SVD_MTI2')
            outputCube = apply_mti(outputCube, 2);
        end

    otherwise
        error('Unsupported clutter suppression method: %s', method);
end

outputPower = mean(abs(outputCube(:)).^2);
if isfield(clutterOpts, 'normalize_output_power') && ...
        clutterOpts.normalize_output_power && outputPower > 0
    outputCube = outputCube * sqrt(inputPower / outputPower);
    outputPower = mean(abs(outputCube(:)).^2);
end

diagnostics.method = method;
diagnostics.input_power = inputPower;
diagnostics.output_power = outputPower;
diagnostics.total_power_change_db = 10*log10((outputPower + eps) / ...
    (inputPower + eps));
diagnostics.removed_rank = removedRank;
diagnostics.singular_values = singularValues(:);
if isempty(singularValues)
    diagnostics.removed_energy_ratio = 0;
else
    singularEnergy = abs(singularValues).^2;
    diagnostics.removed_energy_ratio = sum(singularEnergy(1:removedRank)) / ...
        max(sum(singularEnergy), eps);
end
end

function outputCube = remove_slow_time_mean(inputCube)
outputCube = inputCube - mean(inputCube, 2);
end

function outputCube = apply_mti(inputCube, order)
outputCube = zeros(size(inputCube), 'like', inputCube);
switch order
    case 2
        outputCube(:,2:end,:) = inputCube(:,2:end,:) - inputCube(:,1:end-1,:);
    case 3
        outputCube(:,3:end,:) = inputCube(:,3:end,:) - ...
            2*inputCube(:,2:end-1,:) + inputCube(:,1:end-2,:);
    otherwise
        error('MTI order must be 2 or 3.');
end
end

function [outputCube, singularValues, removedRank] = ...
    remove_low_rank_svd(inputCube, clutterOpts)
[numRange, numChirps, numChannels] = size(inputCube);
% Arrange all range/channel cells as observations and chirps as snapshots.
matrixData = reshape(permute(inputCube, [1,3,2]), ...
    numRange*numChannels, numChirps);

rowMean = zeros(size(matrixData,1),1);
if isfield(clutterOpts, 'svd_center_rows') && clutterOpts.svd_center_rows
    rowMean = mean(matrixData, 2);
    matrixData = matrixData - rowMean;
end

[U,S,V] = svd(matrixData, 'econ');
singularValues = diag(S);
maxAvailableRank = numel(singularValues);
maxRank = maxAvailableRank;
if isfield(clutterOpts, 'svd_max_rank') && ~isempty(clutterOpts.svd_max_rank)
    maxRank = min(maxRank, max(0, round(clutterOpts.svd_max_rank)));
end

removedRank = 0;
if isfield(clutterOpts, 'svd_energy_fraction') && ...
        ~isempty(clutterOpts.svd_energy_fraction)
    targetFraction = min(max(clutterOpts.svd_energy_fraction, 0), 1);
    cumulativeEnergy = cumsum(abs(singularValues).^2) / ...
        max(sum(abs(singularValues).^2), eps);
    rankCandidate = find(cumulativeEnergy >= targetFraction, 1, 'first');
    if isempty(rankCandidate)
        rankCandidate = maxRank;
    end
    removedRank = min(rankCandidate, maxRank);
elseif isfield(clutterOpts, 'svd_rank')
    removedRank = min(max(0, round(clutterOpts.svd_rank)), maxRank);
end

if removedRank > 0
    clutterMatrix = U(:,1:removedRank) * S(1:removedRank,1:removedRank) * ...
        V(:,1:removedRank)';
    matrixData = matrixData - clutterMatrix;
end

% A centered SVD is intended to remove low-rank fluctuations while keeping
% the original row mean. The common competition setting leaves centering
% disabled, so the static mean itself is included in the removed subspace.
if isfield(clutterOpts, 'svd_center_rows') && clutterOpts.svd_center_rows
    matrixData = matrixData + rowMean;
end

outputCube = permute(reshape(matrixData, ...
    [numRange, numChannels, numChirps]), [1,3,2]);
end
