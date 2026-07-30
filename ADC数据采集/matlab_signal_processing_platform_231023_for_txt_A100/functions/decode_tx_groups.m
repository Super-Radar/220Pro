function mimo = decode_tx_groups(cfg, numRx)
%DECODE_TX_GROUPS Decode the A100 tx_groups bit layout used by legacy code.
% cfg.tx_groups contains one 16-bit word per physical TX. Bit positions
% 1, 5, 9 and 13 select virtual chirp groups 1..4 respectively. Rows of
% mimo.tx_group_matrix are chirp groups; columns are physical TX1..TX4.

if ~isfield(cfg, 'tx_groups')
    error('Missing configuration field: tx_groups');
end
if nargin < 2 || isempty(numRx)
    numRx = 4;
end

numPhysicalTx = 4;
txWords = uint32(cfg.tx_groups(:).');
if numel(txWords) < numPhysicalTx
    txWords(end+1:numPhysicalTx) = uint32(0);
elseif numel(txWords) > numPhysicalTx
    error('tx_groups must contain at most four physical-TX words.');
end

matrix = false(4, numPhysicalTx);
for iGroup = 1:4
    bitPosition = 1 + (iGroup - 1) * 4;
    matrix(iGroup, :) = logical(bitget(txWords, bitPosition));
end

lastUsedGroup = find(any(matrix, 2), 1, 'last');
if isempty(lastUsedGroup)
    error('tx_groups does not enable any physical transmitter.');
end
matrix = matrix(1:lastUsedGroup, :);
emptyInside = find(~any(matrix, 2));
if ~isempty(emptyInside)
    error('tx_groups contains an empty chirp group before the final active group: %s', ...
        mat2str(emptyInside.'));
end

groupTxIndices = cell(size(matrix, 1), 1);
for iGroup = 1:size(matrix, 1)
    groupTxIndices{iGroup} = find(matrix(iGroup, :));
end
groupTxCount = sum(matrix, 2);
activeTx = find(any(matrix, 1));
linkCount = sum(groupTxCount);

hasSimultaneousTx = any(groupTxCount > 1);
bpmEnabled = isfield(cfg, 'bpm_mode') && any(logical(cfg.bpm_mode(:)));
[ddmaReady, phaseStepDeg, initialPhaseDeg, sourceName] = ...
    read_explicit_ddma_definition(cfg, activeTx);

if ~hasSimultaneousTx
    if linkCount == 1
        mode = 'SISO';
    else
        mode = 'TDM';
    end
elseif ddmaReady
    mode = 'DDMA';
elseif bpmEnabled
    mode = 'BPM_UNSUPPORTED';
else
    mode = 'SIMULTANEOUS_UNRESOLVED';
end

mimo = struct();
mimo.mode = mode;
mimo.num_physical_tx = numPhysicalTx;
mimo.num_rx = numRx;
mimo.tx_words = txWords;
mimo.tx_group_matrix = matrix;
mimo.group_tx_indices = groupTxIndices;
mimo.group_tx_count = groupTxCount;
mimo.group_count = size(matrix, 1);
mimo.active_tx_indices = activeTx;
mimo.virtual_tx_link_count = linkCount;
mimo.has_simultaneous_tx = hasSimultaneousTx;
mimo.ddma_ready = ddmaReady;
mimo.ddma_definition_source = sourceName;
mimo.ddma_phase_step_deg_by_tx = phaseStepDeg;
mimo.ddma_initial_phase_deg_by_tx = initialPhaseDeg;
end

function [ready, phaseStepDeg, initialPhaseDeg, sourceName] = ...
    read_explicit_ddma_definition(cfg, activeTx)
% Do not infer DDMA from tx_phase_value. In the supplied files that field is
% static and its firmware semantics are not defined. DDMA is enabled only by
% an explicit per-TX phase-increment or Doppler-offset field.

phaseStepDeg = nan(1, 4);
initialPhaseDeg = zeros(1, 4);
sourceName = '';

phaseFields = {'ddma_phase_increment_deg', 'ddma_phase_step_deg', ...
    'ddma_tx_phase_step_deg'};
for iField = 1:numel(phaseFields)
    if isfield(cfg, phaseFields{iField})
        values = double(cfg.(phaseFields{iField})(:).');
        phaseStepDeg = expand_tx_vector(values, activeTx, phaseFields{iField});
        sourceName = phaseFields{iField};
        break;
    end
end

if isempty(sourceName)
    offsetFields = {'ddma_doppler_offsets_bins', 'ddma_doppler_offset_bins'};
    for iField = 1:numel(offsetFields)
        if isfield(cfg, offsetFields{iField})
            if ~isfield(cfg, 'vel_nfft')
                error('%s requires vel_nfft.', offsetFields{iField});
            end
            offsets = double(cfg.(offsetFields{iField})(:).');
            offsets = expand_tx_vector(offsets, activeTx, offsetFields{iField});
            phaseStepDeg = offsets / double(cfg.vel_nfft) * 360;
            sourceName = offsetFields{iField};
            break;
        end
    end
end

initialFields = {'ddma_initial_phase_deg', 'ddma_tx_initial_phase_deg'};
for iField = 1:numel(initialFields)
    if isfield(cfg, initialFields{iField})
        values = double(cfg.(initialFields{iField})(:).');
        initialPhaseDeg = expand_tx_vector(values, activeTx, initialFields{iField});
        break;
    end
end

ready = ~isempty(sourceName);
if ready
    activeSteps = mod(phaseStepDeg(activeTx), 360);
    if any(isnan(activeSteps) | isinf(activeSteps))
        error('Explicit DDMA phase definition is missing an active TX value.');
    end
    if numel(unique(round(activeSteps * 1e9) / 1e9)) ~= numel(activeSteps)
        error('Active DDMA transmitters must have unique phase increments.');
    end
end
end

function expanded = expand_tx_vector(values, activeTx, fieldName)
expanded = nan(1, 4);
if numel(values) == 4
    expanded = values;
elseif numel(values) == numel(activeTx)
    expanded(activeTx) = values;
else
    error('%s must contain four values or one value per active TX.', fieldName);
end
end
