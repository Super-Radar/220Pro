function write_adc_fixture(file_path, header, words, padding)
%WRITE_ADC_FIXTURE Write a compact test capture without production dependencies.

fid = fopen(file_path, 'w');
if fid < 0
    error('a100:FixtureOpenFailed', 'Could not create fixture: %s', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%.0f,%.0f,%.0f', header(1), header(2), header(3));
fprintf(fid, ',%.0f', words(:));
fprintf(fid, ',%.0f', padding(:));
fprintf(fid, '\n');
clear cleanup;
end

