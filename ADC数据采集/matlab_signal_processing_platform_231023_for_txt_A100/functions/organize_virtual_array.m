function virtualCube = organize_virtual_array(adcRxCube, cfg, layout)
%ORGANIZE_VIRTUAL_ARRAY Convert [sample, raw chirp, RX] to virtual channels.
% For one TX this is a no-op. For TDM-MIMO, 'block' expects all chirps for
% TX1 followed by all chirps for TX2; 'interleaved' expects TX order to
% alternate chirp by chirp.

nTx = cfg.nvirtual_chirp;
if nTx == 1
    virtualCube = adcRxCube;
    return;
end
nSlow = cfg.slow_time_chirp_num;
nRx = size(adcRxCube, 3);
virtualCube = zeros(size(adcRxCube, 1), nSlow, nRx * nTx);
for iTx = 1:nTx
    switch lower(layout)
        case 'block'
            chirpIdx = (iTx-1)*nSlow + (1:nSlow);
        case 'interleaved'
            chirpIdx = iTx:nTx:(iTx + (nSlow-1)*nTx);
        otherwise
            error('Unknown TX chirp layout: %s', layout);
    end
    channelIdx = (iTx-1)*nRx + (1:nRx);
    virtualCube(:, :, channelIdx) = adcRxCube(:, chirpIdx, :);
end
end
