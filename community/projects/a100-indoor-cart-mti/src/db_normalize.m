function values_db = db_normalize(values, floor_db, reference_peak)
%DB_NORMALIZE Convert magnitude to decibels against a shared reference.

if nargin < 2 || isempty(floor_db)
    floor_db = -80;
end
magnitude = abs(values);
if nargin < 3 || isempty(reference_peak)
    reference_peak = max(magnitude(:));
end
if ~isscalar(reference_peak) || ~isfinite(reference_peak) || reference_peak < 0
    error('a100:InvalidDbReference', ...
        'The dB reference peak must be one finite non-negative scalar.');
end
if isempty(reference_peak) || reference_peak <= 0
    values_db = floor_db * ones(size(magnitude));
    return;
end
values_db = 20 * log10(magnitude / reference_peak + eps);
values_db(values_db < floor_db) = floor_db;
end
