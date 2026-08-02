function rows = run_measured_adc_analysis(project_root)
%RUN_MEASURED_ADC_ANALYSIS Validate and visualize all effective ADC captures.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end
addpath(fullfile(project_root, 'src'));
env = prepare_environment(project_root);
adc_root = fullfile(project_root, 'data', 'adc');

datasets = { ...
    'static_box', 'adc_test_20260802162041191'; ...
    'empty_background', 'adc_empty_background_20260802162429496'; ...
    'approaching_box', 'adc_approaching_box_rx0_20260802163233093'; ...
    'receding_box', 'adc_receding_box_rx0_retry3_20260802164502658'};

captures = struct();
rows = {};
for dataset_idx = 1:size(datasets, 1)
    scenario = datasets{dataset_idx, 1};
    directory = fullfile(adc_root, datasets{dataset_idx, 2});
    files = dir(fullfile(directory, '*.txt'));
    if isempty(files)
        error('a100:MissingAdcDataset', 'No ADC files found in %s.', directory);
    end
    for file_idx = 1:numel(files)
        channel = channel_from_name(files(file_idx).name);
        file_path = fullfile(files(file_idx).folder, files(file_idx).name);
        [adc, meta] = load_a100_adc(file_path, channel);
        processed = process_measured_adc(adc, 1);
        field = sprintf('rx%d', channel);
        captures.(scenario).(field) = processed;
        rows(end + 1, :) = {scenario, channel, meta.samples_per_chirp, ... %#ok<AGROW>
            meta.chirp_count, meta.packed_word_count, meta.padding_count, ...
            double(meta.padding_verified_zero), processed.adc_rms, ...
            processed.zero_doppler_suppression_db, ...
            relative_path(file_path, project_root)};
    end
end

plot_range_profiles(captures, env.figures_dir);
plot_motion_map(captures.approaching_box.rx0, 'Approaching cart/box', ...
    fullfile(env.figures_dir, 'measured_adc_approaching_mti.png'));
plot_motion_map(captures.receding_box.rx0, 'Receding cart/box', ...
    fullfile(env.figures_dir, 'measured_adc_receding_mti.png'));
plot_static_background(captures, env.figures_dir);
write_metrics(fullfile(env.results_dir, 'measured_adc_metrics.csv'), rows);

fprintf('Measured ADC: %d channels validated and processed in bin domain.\n', size(rows, 1));
end

function channel = channel_from_name(file_name)
token = regexp(file_name, 'Rx([0-9]+)', 'tokens', 'once');
if isempty(token)
    error('a100:MissingRxInFileName', 'Cannot determine Rx channel from %s.', file_name);
end
channel = str2double(token{1});
end

function path = relative_path(file_path, project_root)
normalized_file = strrep(file_path, '\', '/');
normalized_root = strrep(project_root, '\', '/');
prefix = [normalized_root '/'];
if strncmpi(normalized_file, prefix, numel(prefix))
    path = normalized_file(numel(prefix) + 1:end);
else
    path = normalized_file;
end
end

function plot_range_profiles(captures, figures_dir)
fig = figure('position', [100 100 1250 850]);
for channel = 0:3
    field = sprintf('rx%d', channel);
    box = captures.static_box.(field);
    empty = captures.empty_background.(field);
    subplot(2, 2, channel + 1);
    plot(box.range_bin, box.range_profile_db, 'r', 'linewidth', 1.0);
    hold on;
    plot(empty.range_bin, empty.range_profile_db, 'b', 'linewidth', 1.0);
    hold off; grid on; xlim([0 256]); ylim([-80 2]);
    xlabel('Range bin (not calibrated to metres)'); ylabel('Normalized magnitude (dB)');
    title(sprintf('Rx%d static box versus empty background', channel));
    legend('static box', 'empty background', 'location', 'southwest');
end
save_png(fig, fullfile(figures_dir, 'measured_adc_range_profiles.png'));
end

function plot_motion_map(result, scene_title, file_path)
fig = figure('position', [100 100 1300 600]);
subplot(1, 2, 1);
imagesc(result.normalized_doppler, result.range_bin, result.rd_before_db);
axis xy; ylim([0 256]); caxis([-70 0]); colormap(jet); colorbar;
xlabel('Normalized Doppler (cycles/chirp)'); ylabel('Range bin');
title([scene_title ' - before MTI']);
subplot(1, 2, 2);
imagesc(result.normalized_doppler, result.range_bin, result.rd_after_db);
axis xy; ylim([0 256]); caxis([-70 0]); colormap(jet); colorbar;
xlabel('Normalized Doppler (cycles/chirp)'); ylabel('Range bin');
title(sprintf('%s - after MTI (zero-bin %.1f dB)', ...
    scene_title, result.zero_doppler_suppression_db));
save_png(fig, file_path);
end

function plot_static_background(captures, figures_dir)
box = captures.static_box.rx0;
empty = captures.empty_background.rx0;
fig = figure('position', [100 100 1300 950]);
subplot(2, 2, 1);
imagesc(box.normalized_doppler, box.range_bin, box.rd_before_db);
axis xy; ylim([0 256]); caxis([-70 0]); title('Static box - before MTI');
xlabel('Normalized Doppler'); ylabel('Range bin');
subplot(2, 2, 2);
imagesc(box.normalized_doppler, box.range_bin, box.rd_after_db);
axis xy; ylim([0 256]); caxis([-70 0]); title('Static box - after MTI');
xlabel('Normalized Doppler'); ylabel('Range bin');
subplot(2, 2, 3);
imagesc(empty.normalized_doppler, empty.range_bin, empty.rd_before_db);
axis xy; ylim([0 256]); caxis([-70 0]); title('Empty background - before MTI');
xlabel('Normalized Doppler'); ylabel('Range bin');
subplot(2, 2, 4);
imagesc(empty.normalized_doppler, empty.range_bin, empty.rd_after_db);
axis xy; ylim([0 256]); caxis([-70 0]); title('Empty background - after MTI');
xlabel('Normalized Doppler'); ylabel('Range bin');
colormap(jet);
save_png(fig, fullfile(figures_dir, 'measured_adc_static_background_mti.png'));
end

function write_metrics(file_path, rows)
fid = fopen(file_path, 'w');
if fid < 0
    error('a100:MeasuredMetricsOpenFailed', 'Could not write %s.', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['scenario,rx,samples_per_chirp,chirps,packed_words,padding_count,padding_verified_zero,' ...
              'adc_rms,zero_doppler_suppression_db,file\n']);
for idx = 1:size(rows, 1)
    fprintf(fid, '%s,%d,%d,%d,%d,%d,%d,%.12g,%.12g,%s\n', rows{idx, :});
end
clear cleanup;
end
