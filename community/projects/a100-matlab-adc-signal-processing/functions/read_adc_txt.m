function [packedWords, header, trailer] = read_adc_txt(filePath, ioOpts)
%READ_ADC_TXT Read one CTSAI-A100 RX export file.
% Format: rx_index, samples_per_chirp, chirp_count, packed_uint32...

fid = fopen(filePath, 'r');
if fid < 0
    error('Cannot open ADC file: %s', filePath);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
dataCell = textscan(fid, '%f', 'Delimiter', ',', 'CollectOutput', true);
values = dataCell{1};
if numel(values) < 4
    error('ADC file is too short: %s', filePath);
end

header.rx_index = round(values(1));
header.samples_per_chirp = round(values(2));
header.chirp_count = round(values(3));
header.file = filePath;
if mod(header.samples_per_chirp, 2) ~= 0
    error('samples_per_chirp must be even because two int16 samples share one uint32.');
end

expectedWords = header.samples_per_chirp / 2 * header.chirp_count;
payload = values(4:end);
if numel(payload) < expectedWords
    if ioOpts.allow_zero_pad
        warning('ADC payload is short in %s; zero padding %d words.', ...
            filePath, expectedWords - numel(payload));
        payload(end+1:expectedWords, 1) = 0;
    else
        error('ADC payload is short in %s: expected %d words, got %d.', ...
            filePath, expectedWords, numel(payload));
    end
end
trailer = payload(expectedWords+1:end);
if ~isempty(trailer)
    fprintf('  %s: ignored %d trailing value(s).\n', ...
        char(filePath), numel(trailer));
end
packedWords = uint32(payload(1:expectedWords));
end
