function track = extract_motion_track(targets)
%EXTRACT_MOTION_TRACK Infer a conservative moving-target detection envelope.
%   Approaching and receding hypotheses are built independently from measured
%   radial-speed signs. The scene label is not an input. Each hypothesis is
%   split across long time gaps or discontinuous range jumps, and only a
%   segment whose fitted range slope agrees with its speed sign is eligible.
%   This remains a detection envelope, not an identity tracker.

directions = {'approaching', 'receding'};
hypotheses = cell(1, numel(directions));
scores = -Inf(1, numel(directions));
for idx = 1:numel(directions)
    hypotheses{idx} = build_hypothesis(targets, directions{idx});
    if direction_is_consistent(hypotheses{idx}, directions{idx})
        duration_s = max(hypotheses{idx}.elapsed_s) - min(hypotheses{idx}.elapsed_s);
        scores(idx) = hypotheses{idx}.point_count + min(duration_s, 100) / 1000;
    end
end

[best_score, best_idx] = max(scores);
if ~isfinite(best_score)
    track = empty_track();
    track.approaching_hypothesis_points = hypotheses{1}.point_count;
    track.receding_hypothesis_points = hypotheses{2}.point_count;
    return;
end

track = hypotheses{best_idx};
track.inferred_direction = directions{best_idx};
track.inference_score = best_score;
track.approaching_hypothesis_points = hypotheses{1}.point_count;
track.receding_hypothesis_points = hypotheses{2}.point_count;
end

function track = build_hypothesis(targets, direction)
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
if isempty(indices)
    track = empty_track();
    return;
end

segments = {};
current = [];
frame_values = unique(targets.frame_sequence(indices));
for frame_idx = 1:numel(frame_values)
    frame_candidates = indices(targets.frame_sequence(indices) == frame_values(frame_idx));
    if isempty(current)
        current = seed_candidate(targets, frame_candidates, direction);
        continue;
    end

    previous = current(end);
    cost = abs(targets.range_m(frame_candidates) - targets.range_m(previous)) - ...
           0.005 * targets.snr_db(frame_candidates);
    [~, local_idx] = min(cost);
    selected = frame_candidates(local_idx);
    elapsed_gap_s = targets.elapsed_s(selected) - targets.elapsed_s(previous);
    range_step_m = targets.range_m(selected) - targets.range_m(previous);
    continuous = elapsed_gap_s >= 0 && elapsed_gap_s <= 2.0 && ...
                 abs(range_step_m) <= 0.75;
    if strcmp(direction, 'approaching')
        directionally_plausible = range_step_m <= 0.35;
    else
        directionally_plausible = range_step_m >= -0.35;
    end

    if continuous && directionally_plausible
        current(end + 1, 1) = selected; %#ok<AGROW>
    else
        segments{end + 1} = current; %#ok<AGROW>
        current = seed_candidate(targets, frame_candidates, direction);
    end
end
if ~isempty(current)
    segments{end + 1} = current;
end

best = [];
best_score = -Inf;
for idx = 1:numel(segments)
    candidate_track = populate_track(targets, segments{idx});
    if direction_is_consistent(candidate_track, direction)
        duration_s = max(candidate_track.elapsed_s) - min(candidate_track.elapsed_s);
        score = candidate_track.point_count + min(duration_s, 100) / 1000;
        if score > best_score
            best = segments{idx};
            best_score = score;
        end
    end
end
if isempty(best)
    track = empty_track();
else
    track = populate_track(targets, best);
end
end

function selected = seed_candidate(targets, frame_candidates, direction)
if strcmp(direction, 'approaching')
    [~, local_idx] = max(targets.range_m(frame_candidates) + ...
                         0.005 * targets.snr_db(frame_candidates));
else
    [~, local_idx] = min(targets.range_m(frame_candidates) - ...
                         0.005 * targets.snr_db(frame_candidates));
end
selected = frame_candidates(local_idx);
end

function consistent = direction_is_consistent(track, direction)
consistent = track.point_count >= 2 && isfinite(track.range_slope_mps);
if ~consistent
    return;
end
if strcmp(direction, 'approaching')
    consistent = track.range_slope_mps < -0.01;
else
    consistent = track.range_slope_mps > 0.01;
end
end

function track = populate_track(targets, selected)
track = empty_track();
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

function track = empty_track()
track = struct('elapsed_s', [], 'range_m', [], 'speed_mps', [], ...
               'angle_deg', [], 'snr_db', [], 'x_m', [], 'y_m', [], ...
               'point_count', 0, 'start_range_m', NaN, 'end_range_m', NaN, ...
               'range_slope_mps', NaN, 'median_radial_speed_mps', NaN, ...
               'inferred_direction', 'unknown', 'inference_score', -Inf, ...
               'approaching_hypothesis_points', 0, ...
               'receding_hypothesis_points', 0);
end
