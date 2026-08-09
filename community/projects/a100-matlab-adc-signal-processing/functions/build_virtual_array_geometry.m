function geometry = build_virtual_array_geometry(cfg)
%BUILD_VIRTUAL_ARRAY_GEOMETRY Map enabled physical TX/RX pairs to channels.
% ant_pos and ant_comps are arranged in four blocks of num_rx entries, one
% block per physical TX, as used by the legacy get_radar_paramete code.

mimo = cfg.mimo;
numRx = cfg.num_rx;
numVirtual = mimo.virtual_tx_link_count * numRx;

positions = nan(numVirtual, 2);
phaseError = zeros(numVirtual, 1);
txIndex = zeros(numVirtual, 1);
rxIndex = zeros(numVirtual, 1);
groupIndex = zeros(numVirtual, 1);
sourceAntennaIndex = zeros(numVirtual, 1);

hasPhysicalGeometry = isfield(cfg, 'ant_pos') && ...
    size(cfg.ant_pos, 2) >= 2 && ...
    size(cfg.ant_pos, 1) >= mimo.num_physical_tx * numRx;
hasPhysicalPhase = isfield(cfg, 'ant_comps') && ...
    numel(cfg.ant_comps) >= mimo.num_physical_tx * numRx;

channel = 0;
for iGroup = 1:mimo.group_count
    txList = mimo.group_tx_indices{iGroup};
    for iTxList = 1:numel(txList)
        physicalTx = txList(iTxList);
        antennaIndices = (physicalTx - 1) * numRx + (1:numRx);
        for iRx = 1:numRx
            channel = channel + 1;
            txIndex(channel) = physicalTx;
            rxIndex(channel) = iRx;
            groupIndex(channel) = iGroup;
            sourceAntennaIndex(channel) = antennaIndices(iRx);
        end
        if hasPhysicalGeometry
            positions(channel-numRx+1:channel, :) = ...
                cfg.ant_pos(antennaIndices, 1:2);
        end
        if hasPhysicalPhase
            phaseValues = cfg.ant_comps(antennaIndices);
            phaseError(channel-numRx+1:channel) = phaseValues(:);
        end
    end
end

if any(isnan(positions(:)) | isinf(positions(:)))
    if isfield(cfg, 'ant_pos') && size(cfg.ant_pos, 1) >= numVirtual
        positions = cfg.ant_pos(1:numVirtual, 1:2);
        warning(['Physical-TX antenna blocks could not be confirmed; using the ' ...
            'first %d ant_pos entries.'], numVirtual);
    else
        positions(:, 1) = (0:numVirtual-1).' * 0.5;
        positions(:, 2) = 0;
        warning('Antenna positions are incomplete; using a 0.5-lambda ULA.');
    end
end
if ~hasPhysicalPhase
    if isfield(cfg, 'ant_comps') && numel(cfg.ant_comps) >= numVirtual
        phaseValues = cfg.ant_comps(1:numVirtual);
        phaseError = phaseValues(:);
    else
        phaseError(:) = 0;
    end
end

geometry = struct();
geometry.positions_lambda = positions;
geometry.phase_error_deg = phaseError;
geometry.tx_index = txIndex;
geometry.rx_index = rxIndex;
geometry.group_index = groupIndex;
geometry.source_antenna_index = sourceAntennaIndex;
geometry.channel_count = numVirtual;
end
