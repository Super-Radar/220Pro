function valueDb = figure_db(value, dynamicRangeDb)
%FIGURE_DB Convert positive power to dB and clamp display dynamic range.
valueDb = 10*log10(value + eps);
if nargin >= 2 && ~isempty(dynamicRangeDb)
    valueDb = max(valueDb, max(valueDb(:)) - dynamicRangeDb);
end
end
