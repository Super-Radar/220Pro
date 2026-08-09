function files = discover_adc_files(dataDir, profileTag)
%DISCOVER_ADC_FILES Find RX files for one waveform profile.
pattern = sprintf('*_%s_Rx*.txt', profileTag);
listing = dir(fullfile(dataDir, pattern));
if isempty(listing)
    error('No ADC files found with pattern %s in %s.', pattern, dataDir);
end
[~, order] = sort({listing.name});
listing = listing(order);
files = arrayfun(@(x) fullfile(x.folder, x.name), listing, ...
    'UniformOutput', false);
end
