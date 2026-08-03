function metrics = run_target_analysis(project_root)
%RUN_TARGET_ANALYSIS Parse real RadarTools point and track CSV captures.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end
addpath(fullfile(project_root, 'src'));
env = prepare_environment(project_root);
data_root = fullfile(project_root, 'data', 'targets');

scenes = { ...
    'static_box', '16_19_35', 'static', 'plastic_target'; ...
    'empty_background', '16_23_49', 'static', 'none'; ...
    'approaching_box', '16_27_16', 'approaching', 'cart_box'; ...
    'receding_box', '16_34_07', 'receding', 'cart_box'; ...
    'empty_room_person_session', '19_13_58', 'static', 'none'; ...
    'stationary_person_3m', '21_35_30', 'static', 'human'; ...
    'receding_person_short', '21_39_26', 'receding', 'human'};

parsed = struct();
metrics = cell(size(scenes, 1), 23);
trajectory_rows = {};
for idx = 1:size(scenes, 1)
    scene = scenes{idx, 1};
    prefix = scenes{idx, 2};
    raw_file = single_match(data_root, ['*' prefix '*RawTarget.csv']);
    tracked_file = single_match(data_root, ['*' prefix '*TraTarget.csv']);
    raw = read_radartools_targets(raw_file);
    tracked = read_radartools_targets(tracked_file);
    parsed.(scene) = struct('raw', raw, 'tracked', tracked);

    direction = scenes{idx, 3};
    if strcmp(direction, 'static')
        motion = empty_motion();
        direction_matches_expected = NaN;
    else
        motion = extract_motion_track(raw);
        direction_matches_expected = double(strcmp(motion.inferred_direction, direction));
        parsed.(scene).motion = motion;
        for point_idx = 1:motion.point_count
            trajectory_rows(end + 1, :) = {scene, motion.elapsed_s(point_idx), ... %#ok<AGROW>
                motion.range_m(point_idx), motion.speed_mps(point_idx), ...
                motion.angle_deg(point_idx), motion.x_m(point_idx), motion.y_m(point_idx), ...
                motion.snr_db(point_idx)};
        end
    end

    if any(strcmp(scene, {'empty_room_person_session', 'stationary_person_3m'}))
        roi = stationary_person_roi(raw);
        parsed.(scene).stationary_roi = roi;
    else
        roi = empty_roi();
    end

    metrics(idx, :) = {scene, scenes{idx, 4}, ...
        raw.meta.record_count, raw.meta.frame_count, ...
        tracked.meta.record_count, tracked.meta.frame_count, motion.point_count, ...
        motion.start_range_m, motion.end_range_m, motion.range_slope_mps, ...
        motion.median_radial_speed_mps, min_or_nan(raw.range_m), ...
        max_or_nan(raw.range_m), tracked.meta.record_count < 10, ...
        roi.record_count, roi.frame_count, roi.detection_fraction, ...
        roi.median_range_m, roi.median_angle_deg, roi.median_snr_db, ...
        direction, motion.inferred_direction, direction_matches_expected};
end

cart_scenes = scenes(1:4, 1);
plot_point_clouds(parsed, cart_scenes, env.figures_dir);
plot_motion_trends(parsed.approaching_box.motion, parsed.receding_box.motion, ...
    parsed.receding_person_short.motion, env.figures_dir);
plot_tracked_outputs(parsed, cart_scenes, env.figures_dir);
plot_person_validation(parsed.empty_room_person_session, ...
    parsed.stationary_person_3m, env.figures_dir);
write_target_metrics(fullfile(env.results_dir, 'target_metrics.csv'), metrics);
write_trajectories(fullfile(env.results_dir, 'motion_trajectory.csv'), trajectory_rows);

approach = parsed.approaching_box.motion;
recede = parsed.receding_box.motion;
fprintf(['Measured targets: approach %.2f -> %.2f m (%d points); ' ...
         'cart recede %.2f -> %.2f m (%d points); ' ...
         'person recede %.2f -> %.2f m (%d points).\n'], ...
    approach.start_range_m, approach.end_range_m, approach.point_count, ...
    recede.start_range_m, recede.end_range_m, recede.point_count, ...
    parsed.receding_person_short.motion.start_range_m, ...
    parsed.receding_person_short.motion.end_range_m, ...
    parsed.receding_person_short.motion.point_count);
end

function file_path = single_match(root, pattern)
files = dir(fullfile(root, pattern));
if numel(files) ~= 1
    error('a100:TargetFileMatch', ...
        'Expected one file for %s; found %d.', pattern, numel(files));
end
file_path = fullfile(files(1).folder, files(1).name);
end

function motion = empty_motion()
motion = struct('elapsed_s', [], 'range_m', [], 'speed_mps', [], ...
    'angle_deg', [], 'snr_db', [], 'x_m', [], 'y_m', [], 'point_count', 0, ...
    'start_range_m', NaN, 'end_range_m', NaN, 'range_slope_mps', NaN, ...
    'median_radial_speed_mps', NaN, 'inferred_direction', 'unknown', ...
    'inference_score', -Inf, 'approaching_hypothesis_points', 0, ...
    'receding_hypothesis_points', 0);
end

function value = min_or_nan(values)
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = max_or_nan(values)
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function roi = stationary_person_roi(raw)
% Fixed from the measured 3 m marker and used unchanged for both captures.
mask = raw.range_m >= 2.5 & raw.range_m <= 3.1 & ...
       raw.angle_deg >= -20 & raw.angle_deg <= 5;
roi = struct('record_count', sum(mask), ...
    'frame_count', numel(unique(raw.frame_sequence(mask))), ...
    'detection_fraction', 0, 'median_range_m', NaN, ...
    'median_angle_deg', NaN, 'median_snr_db', NaN, 'mask', mask);
if raw.meta.frame_count > 0
    roi.detection_fraction = roi.frame_count / raw.meta.frame_count;
end
if any(mask)
    roi.median_range_m = median(raw.range_m(mask));
    roi.median_angle_deg = median(raw.angle_deg(mask));
    roi.median_snr_db = median(raw.snr_db(mask));
end
end

function roi = empty_roi()
roi = struct('record_count', NaN, 'frame_count', NaN, ...
    'detection_fraction', NaN, 'median_range_m', NaN, ...
    'median_angle_deg', NaN, 'median_snr_db', NaN, 'mask', []);
end

function plot_point_clouds(parsed, scene_names, figures_dir)
titles = {'Static box', 'Empty background', 'Approaching cart/box', 'Receding cart/box'};
fig = figure('position', [100 100 1250 950]);
for idx = 1:numel(scene_names)
    raw = parsed.(scene_names{idx}).raw;
    stride = max(1, ceil(raw.meta.record_count / 5000));
    points = 1:stride:raw.meta.record_count;
    subplot(2, 2, idx);
    plot(raw.polar_x_m(points), raw.polar_y_m(points), '.', 'markersize', 2);
    grid on; axis equal; xlim([-12 12]); ylim([0 22]);
    xlabel('Lateral X (m)'); ylabel('Forward Y (m)');
    title(sprintf('%s RawTarget cloud (%d points)', titles{idx}, raw.meta.record_count));
end
save_png(fig, fullfile(figures_dir, 'measured_target_pointclouds.png'));
end

function plot_motion_trends(approach, recede, person_recede, figures_dir)
fig = figure('position', [100 100 1250 900]);
subplot(2, 2, 1);
plot(approach.elapsed_s, approach.range_m, '.-b'); grid on;
xlabel('Elapsed capture time (s)'); ylabel('Measured range (m)');
title(sprintf('Approaching detections: %.2f -> %.2f m', ...
    approach.start_range_m, approach.end_range_m));
subplot(2, 2, 2);
plot(recede.elapsed_s, recede.range_m, '.-r'); grid on;
hold on;
plot(person_recede.elapsed_s, person_recede.range_m, '.-m');
hold off;
xlabel('Elapsed capture time (s)'); ylabel('Measured range (m)');
title('Receding detection envelopes');
legend('cart/box', 'person (short path)', 'location', 'northwest');
subplot(2, 2, 3);
plot(approach.x_m, approach.y_m, '.b'); grid on; axis equal;
xlabel('Lateral X (m)'); ylabel('Forward Y (m)'); title('Approaching XY detections');
subplot(2, 2, 4);
plot(recede.x_m, recede.y_m, '.r'); hold on;
plot(person_recede.x_m, person_recede.y_m, '.m'); hold off;
grid on; axis equal;
xlabel('Lateral X (m)'); ylabel('Forward Y (m)');
title('Receding XY detections (not identity tracks)');
legend('cart/box', 'person', 'location', 'northeast');
save_png(fig, fullfile(figures_dir, 'measured_target_motion_trends.png'));
end

function plot_person_validation(empty_capture, person_capture, figures_dir)
empty = empty_capture.raw;
person = person_capture.raw;
empty_roi_data = empty_capture.stationary_roi;
person_roi_data = person_capture.stationary_roi;

fig = figure('position', [100 100 1250 900]);
subplot(2, 2, 1);
plot(empty.polar_x_m, empty.polar_y_m, '.', 'markersize', 2);
grid on; axis equal; xlim([-4 4]); ylim([0 6]);
xlabel('Lateral X (m)'); ylabel('Forward Y (m)');
title(sprintf('Empty room (%d RawTarget records)', empty.meta.record_count));
subplot(2, 2, 2);
plot(person.polar_x_m, person.polar_y_m, '.', 'markersize', 2);
grid on; axis equal; xlim([-4 4]); ylim([0 6]);
xlabel('Lateral X (m)'); ylabel('Forward Y (m)');
title(sprintf('Stationary person at 3 m (%d records)', person.meta.record_count));
subplot(2, 2, 3);
if any(person_roi_data.mask)
    plot(person.elapsed_s(person_roi_data.mask), ...
        person.range_m(person_roi_data.mask), '.b');
end
grid on; ylim([2.4 3.2]);
xlabel('Elapsed capture time (s)'); ylabel('ROI range (m)');
title(sprintf('Person ROI median %.2f m, %.1f dB SNR', ...
    person_roi_data.median_range_m, person_roi_data.median_snr_db));
subplot(2, 2, 4);
bar([empty_roi_data.detection_fraction, person_roi_data.detection_fraction]);
grid on; ylim([0 1]);
set(gca, 'xtick', [1 2], 'xticklabel', {'empty', 'person'});
ylabel('Fraction of frames with ROI detection');
title(sprintf('Fixed 2.5-3.1 m ROI: %d versus %d frames', ...
    empty_roi_data.frame_count, person_roi_data.frame_count));
save_png(fig, fullfile(figures_dir, 'measured_stationary_person.png'));
end

function plot_tracked_outputs(parsed, scene_names, figures_dir)
titles = {'Static box', 'Empty background', 'Approaching cart/box', 'Receding cart/box'};
fig = figure('position', [100 100 1250 950]);
for idx = 1:numel(scene_names)
    tracked = parsed.(scene_names{idx}).tracked;
    subplot(2, 2, idx);
    if tracked.meta.record_count > 0
        plot(tracked.x_m, tracked.y_m, '.', 'markersize', 3);
    end
    grid on; axis equal; xlim([-12 12]); ylim([0 22]);
    xlabel('Tracked X (m)'); ylabel('Tracked Y (m)');
    title(sprintf('%s TraTarget (%d records, %d frames)', ...
        titles{idx}, tracked.meta.record_count, tracked.meta.frame_count));
end
save_png(fig, fullfile(figures_dir, 'measured_tracked_targets.png'));
end

function write_target_metrics(file_path, metrics)
fid = fopen(file_path, 'w');
if fid < 0
    error('a100:TargetMetricsOpenFailed', 'Could not write %s.', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['scenario,target_type,raw_records,raw_frames,tracked_records,tracked_frames,' ...
              'motion_points,start_range_m,end_range_m,range_slope_mps,' ...
              'median_radial_speed_mps,min_raw_range_m,max_raw_range_m,' ...
              'tracked_output_sparse,roi_records,roi_frames,roi_detection_fraction,' ...
              'roi_median_range_m,roi_median_angle_deg,roi_median_snr_db,' ...
              'expected_direction,inferred_direction,direction_matches_expected\n']);
for idx = 1:size(metrics, 1)
    fprintf(fid, ['%s,%s,%d,%d,%d,%d,%d,%.12g,%.12g,%.12g,%.12g,' ...
        '%.12g,%.12g,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g'], ...
        metrics{idx, 1:20});
    fprintf(fid, ',%s,%s,%.12g\n', metrics{idx, 21:23});
end
clear cleanup;
end

function write_trajectories(file_path, rows)
fid = fopen(file_path, 'w');
if fid < 0
    error('a100:TrajectoryOpenFailed', 'Could not write %s.', file_path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'scenario,elapsed_s,range_m,radial_speed_mps,angle_deg,x_m,y_m,snr_db\n');
for idx = 1:size(rows, 1)
    fprintf(fid, '%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', rows{idx, :});
end
clear cleanup;
end
