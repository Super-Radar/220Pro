function cfg = load_ctsaia100_config(configFile)
%LOAD_CTSAIA100_CONFIG Parse CTSAI-A100 sensor_config_init*.hxx.
% The parser supports numeric scalars/vectors, hexadecimal values, boolean
% values, quoted strings and nested antenna-position arrays.

if ~isfile(configFile)
    error('Configuration file not found: %s', configFile);
end
text = fileread(configFile);
text = regexprep(text, '/\*.*?\*/', '', 'dotall');
lines = regexp(text, '\r\n|\n|\r', 'split');
cfg = struct();

for iLine = 1:numel(lines)
    line = strtrim(regexprep(lines{iLine}, '//.*$', ''));
    if isempty(line) || ~startsWith(line, '.')
        continue;
    end
    token = regexp(line, '^\.(\w+)\s*=\s*(.*?)\s*,?\s*$', ...
        'tokens', 'once');
    if isempty(token)
        continue;
    end
    fieldName = token{1};
    cfg.(fieldName) = parse_hxx_value(token{2});
end

cfg.source_file = configFile;
end

function value = parse_hxx_value(rawValue)
rawValue = strtrim(rawValue);
if isempty(rawValue)
    value = [];
    return;
end

isDoubleQuoted = numel(rawValue) >= 2 && rawValue(1) == char(34) && rawValue(end) == char(34);
isSingleQuoted = numel(rawValue) >= 2 && rawValue(1) == char(39) && rawValue(end) == char(39);
if isDoubleQuoted || isSingleQuoted
    value = rawValue(2:end-1);
    return;
end

% Replace boolean tokens and hexadecimal values before numeric evaluation.
rawValue = regexprep(rawValue, '\<true\>', '1');
rawValue = regexprep(rawValue, '\<false\>', '0');
hexTokens = regexp(rawValue, '0[xX][0-9A-Fa-f]+', 'match');
for iToken = 1:numel(hexTokens)
    decimalText = sprintf('%.0f', hex2dec(hexTokens{iToken}(3:end)));
    rawValue = strrep(rawValue, hexTokens{iToken}, decimalText);
end

if startsWith(rawValue, '{{')
    % {{x1,y1},{x2,y2}} -> [x1,y1;x2,y2]
    rawValue = regexprep(rawValue, '}\s*,\s*{', ';');
end
rawValue = strrep(rawValue, '{{', '[');
rawValue = strrep(rawValue, '}}', ']');
rawValue = strrep(rawValue, '{', '[');
rawValue = strrep(rawValue, '}', ']');

value = str2num(rawValue); %#ok<ST2NM> Configuration is a local project file.
if isempty(value)
    scalarValue = str2double(rawValue);
    if isnan(scalarValue)
        value = rawValue;
    else
        value = scalarValue;
    end
end
end
