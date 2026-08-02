function values_db = db_normalize(values, floor_db)
%DB_NORMALIZE Convert magnitude to peak-normalized decibels.

if nargin < 2 || isempty(floor_db)
    floor_db = -80;
end
magnitude = abs(values);
peak = max(magnitude(:));
if isempty(peak) || peak <= 0
    values_db = floor_db * ones(size(magnitude));
    return;
end
values_db = 20 * log10(magnitude / peak + eps);
values_db(values_db < floor_db) = floor_db;
end
