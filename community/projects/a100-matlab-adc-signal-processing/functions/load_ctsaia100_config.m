function cfg = load_ctsaia100_config(configFile)
%LOAD_CTSAIA100_CONFIG Parse CTSAI-A100 sensor_config_init*.hxx safely.
% Supports numeric scalars/vectors, hexadecimal values, booleans, quoted
% strings, and nested numeric matrices such as ant_pos. Duplicate fields are
% accepted because several supplied profiles contain them; the last value
% wins and the duplicate names are recorded in cfg.parse_metadata.

if ~isfile(configFile)
    error('Configuration file not found: %s', configFile);
end

text = fileread(configFile);
text = regexprep(text, '/\*.*?\*/', '', 'dotall');
lines = regexp(text, '\r\n|\n|\r', 'split');
cfg = struct();
duplicateFields = {};
parsedFields = {};

for iLine = 1:numel(lines)
    line = strtrim(regexprep(lines{iLine}, '//.*$', ''));
    if isempty(line) || ~startsWith(line, '.')
        continue;
    end

    token = regexp(line, '^\.(\w+)\s*=\s*(.*?)\s*,?\s*$', ...
        'tokens', 'once');
    if isempty(token)
        warning('Ignoring unrecognized configuration line %d: %s', ...
            iLine, line);
        continue;
    end

    fieldName = token{1};
    if isfield(cfg, fieldName)
        duplicateFields{end+1} = fieldName; %#ok<AGROW>
    end
    cfg.(fieldName) = parse_hxx_value(token{2}, fieldName);
    parsedFields{end+1} = fieldName; %#ok<AGROW>
end

if isempty(parsedFields)
    error('No configuration assignments were parsed from: %s', configFile);
end

cfg.source_file = configFile;
cfg.parse_metadata = struct();
cfg.parse_metadata.parsed_field_count = numel(parsedFields);
cfg.parse_metadata.duplicate_fields = unique(duplicateFields, 'stable');
if ~isempty(cfg.parse_metadata.duplicate_fields)
    warning('Configuration %s contains duplicate field(s); last assignment wins: %s', ...
        configFile, strjoin(cfg.parse_metadata.duplicate_fields, ', '));
end
end

function value = parse_hxx_value(rawValue, fieldName)
rawValue = strtrim(rawValue);
if isempty(rawValue)
    value = [];
    return;
end

isDoubleQuoted = numel(rawValue) >= 2 && ...
    rawValue(1) == char(34) && rawValue(end) == char(34);
isSingleQuoted = numel(rawValue) >= 2 && ...
    rawValue(1) == char(39) && rawValue(end) == char(39);
if isDoubleQuoted || isSingleQuoted
    value = rawValue(2:end-1);
    return;
end

if startsWith(rawValue, '{{')
    rowTokens = regexp(rawValue, '\{([^{}]+)\}', 'tokens');
    if isempty(rowTokens)
        error('Cannot parse nested array for field %s: %s', fieldName, rawValue);
    end
    rows = cell(numel(rowTokens), 1);
    rowWidth = [];
    for iRow = 1:numel(rowTokens)
        rows{iRow} = parse_flat_numeric_list(rowTokens{iRow}{1}, fieldName);
        if isempty(rowWidth)
            rowWidth = numel(rows{iRow});
        elseif numel(rows{iRow}) ~= rowWidth
            error('Inconsistent nested-array row width for field %s.', fieldName);
        end
    end
    value = vertcat(rows{:});
    return;
end

if rawValue(1) == '{' && rawValue(end) == '}'
    value = parse_flat_numeric_list(rawValue(2:end-1), fieldName);
    return;
end

[value, ok] = parse_scalar_token(rawValue);
if ~ok
    error('Unsupported value for field %s: %s', fieldName, rawValue);
end
end

function value = parse_flat_numeric_list(listText, fieldName)
parts = regexp(listText, '\s*,\s*', 'split');
if numel(parts) == 1 && isempty(strtrim(parts{1}))
    value = [];
    return;
end

numericValues = zeros(1, numel(parts));
logicalMask = false(1, numel(parts));
for iPart = 1:numel(parts)
    token = strtrim(parts{iPart});
    [numericValues(iPart), ok, isLogical] = parse_scalar_token(token);
    if ~ok
        error('Unsupported array token for field %s: %s', fieldName, token);
    end
    logicalMask(iPart) = isLogical;
end
if all(logicalMask)
    value = logical(numericValues);
else
    value = numericValues;
end
end

function [value, ok, isLogical] = parse_scalar_token(token)
token = strtrim(token);
ok = true;
isLogical = false;

if strcmpi(token, 'true')
    value = 1;
    isLogical = true;
    return;
elseif strcmpi(token, 'false')
    value = 0;
    isLogical = true;
    return;
end

hexToken = regexp(token, '^0[xX]([0-9A-Fa-f]+)[uUlL]*$', 'tokens', 'once');
if ~isempty(hexToken)
    value = hex2dec(hexToken{1});
    return;
end

% Accept common C/C++ numeric suffixes while rejecting expressions.
token = regexprep(token, '([fFuUlL]+)$', '');
if isempty(regexp(token, ...
        '^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$', 'once'))
    value = NaN;
    ok = false;
    return;
end
value = str2double(token);
ok = ~isnan(value) && ~isinf(value);
end
