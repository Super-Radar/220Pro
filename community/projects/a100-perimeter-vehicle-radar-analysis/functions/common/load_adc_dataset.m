function [adcCube, metadata] = load_adc_dataset(files, cfg, ioOpts)
%LOAD_ADC_DATASET Load four RX files into [sample, chirp, RX].
numFiles = numel(files);
if numFiles < cfg.num_rx
    error('Expected %d RX files, found %d.', cfg.num_rx, numFiles);
end
adcCube = zeros(cfg.rng_nfft, cfg.nchirp, cfg.num_rx);
seen = false(1, cfg.num_rx);
metaStruct = repmat(struct('RxIndex',0,'SamplesPerChirp',0, ...
    'ChirpCount',0,'TrailingValues',0,'File',""), cfg.num_rx, 1);

for iFile = 1:numFiles
    [packed, header, trailer] = read_adc_txt(files{iFile}, ioOpts);
    if ioOpts.strict_header
        if header.samples_per_chirp ~= cfg.rng_nfft
            error('Header/config sample mismatch in %s: %d vs %d.', ...
                files{iFile}, header.samples_per_chirp, cfg.rng_nfft);
        end
        if header.chirp_count ~= cfg.nchirp
            error('Header/config chirp mismatch in %s: %d vs %d.', ...
                files{iFile}, header.chirp_count, cfg.nchirp);
        end
    end
    rxSlot = header.rx_index + 1;
    if rxSlot < 1 || rxSlot > cfg.num_rx
        error('Unexpected RX index %d in %s.', header.rx_index, files{iFile});
    end
    if seen(rxSlot)
        error('Duplicate RX index %d.', header.rx_index);
    end
    adcCube(:, :, rxSlot) = unpack_uint32_adc(packed, ...
        header.samples_per_chirp, header.chirp_count);
    seen(rxSlot) = true;
    metaStruct(rxSlot).RxIndex = header.rx_index;
    metaStruct(rxSlot).SamplesPerChirp = header.samples_per_chirp;
    metaStruct(rxSlot).ChirpCount = header.chirp_count;
    metaStruct(rxSlot).TrailingValues = numel(trailer);
    metaStruct(rxSlot).File = string(files{iFile});
end
if ~all(seen)
    error('Missing RX channel(s): %s', mat2str(find(~seen)-1));
end
metadata = struct2table(metaStruct);
end
