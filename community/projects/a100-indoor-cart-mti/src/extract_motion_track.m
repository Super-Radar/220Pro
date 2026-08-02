function track = extract_motion_track(targets, direction)
%EXTRACT_MOTION_TRACK Build a conservative envelope of moving RawTarget points.
%   This is not an identity tracker. It selects expected-sign radial-speed
%   detections in the observed near-field cart corridor and links one point
%   per frame using range continuity and SNR. It is used only to visualize
%   the measured motion trend when TraTarget output is sparse.

if ~any(strcmp(direction, {'approaching', 'receding'}))
    error('a100:InvalidMotionDirection', ...
        'Direction must be "approaching" or "receding".');
end
if strcmp(direction, 'approaching')
    sign_mask = targets.speed_mps <= -0.05;
else
    sign_mask = targets.speed_mps >= 0.05;
end
candidate = sign_mask & abs(targets.speed_mps) <= 1.5 & ...
            targets.range_m >= 0.8 & targets.range_m <= 4.5 & ...
            abs(targets.angle_deg) <= 50 & targets.snr_db >= 14 & ...
            isfinite(targets.elapsed_s);

indices = find(candidate);
selected = [];
previous_range = NaN;
frame_values = unique(targets.frame_sequence(indices));
for frame_idx = 1:numel(frame_values)
    frame_candidates = indices(targets.frame_sequence(indices) == frame_values(frame_idx));
    if isempty(frame_candidates)
        continue;
    end
    if isnan(previous_range)
        if strcmp(direction, 'approaching')
            [~, local_idx] = max(targets.range_m(frame_candidates) + ...
                                 0.005 * targets.snr_db(frame_candidates));
        else
            [~, local_idx] = min(targets.range_m(frame_candidates) - ...
                                 0.005 * targets.snr_db(frame_candidates));
        end
    else
        cost = abs(targets.range_m(frame_candidates) - previous_range) - ...
               0.005 * targets.snr_db(frame_candidates);
        [~, local_idx] = min(cost);
        if abs(targets.range_m(frame_candidates(local_idx)) - previous_range) > 0.75
            continue;
        end
    end
    selected(end + 1, 1) = frame_candidates(local_idx); %#ok<AGROW>
    previous_range = targets.range_m(selected(end));
end
track = struct('elapsed_s', [], 'range_m', [], 'speed_mps', [], ...
               'angle_deg', [], 'snr_db', [], 'x_m', [], 'y_m', [], ...
               'point_count', 0, 'start_range_m', NaN, 'end_range_m', NaN, ...
               'range_slope_mps', NaN, 'median_radial_speed_mps', NaN);
if isempty(selected)
    return;
end

track.elapsed_s = targets.elapsed_s(selected);
track.range_m = targets.range_m(selected);
track.speed_mps = targets.speed_mps(selected);
track.angle_deg = targets.angle_deg(selected);
track.snr_db = targets.snr_db(selected);
track.x_m = targets.polar_x_m(selected);
track.y_m = targets.polar_y_m(selected);
track.point_count = numel(selected);
track.start_range_m = track.range_m(1);
track.end_range_m = track.range_m(end);
track.median_radial_speed_mps = median(track.speed_mps);
if numel(selected) >= 2 && max(track.elapsed_s) > min(track.elapsed_s)
    coefficients = polyfit(track.elapsed_s - track.elapsed_s(1), track.range_m, 1);
    track.range_slope_mps = coefficients(1);
end
end
