function profile = load_hxx_profile(configFile)
%LOAD_HXX_PROFILE Parse the public scalar, TX and antenna HXX fields.

if ~isfile(configFile)
    error('CTSAI:MissingConfig', 'Configuration file not found: %s', configFile);
end
text = fileread(configFile);

scalarNames = {'fmcw_startfreq','fmcw_bandwidth','fmcw_chirp_rampup', ...
    'fmcw_chirp_period','nchirp','adc_freq','rng_nfft','vel_nfft'};
for k = 1:numel(scalarNames)
    name = scalarNames{k};
    token = regexp(text, ['\.' name '\s*=\s*([-+0-9.eE]+)\s*,'], ...
        'tokens', 'once');
    if isempty(token)
        error('CTSAI:ConfigField', 'Missing field %s in %s.', name, configFile);
    end
    profile.(name) = str2double(token{1});
end

txBlock = regexp(text, '\.tx_groups\s*=\s*\{([^}]*)\}', 'tokens', 'once');
hexTokens = regexp(txBlock{1}, '0x([0-9a-fA-F]+)', 'tokens');
profile.tx_groups = cellfun(@(x) hex2dec(x{1}), hexTokens);

compBlock = regexp(text, '\.ant_comps\s*=\s*\{([^}]*)\}', 'tokens', 'once');
profile.ant_comps = parse_numbers(compBlock{1});

posBlock = regexp(text, '(?s)\.ant_pos\s*=\s*\{\{(.*?)\}\}\s*,', ...
    'tokens', 'once');
posValues = parse_numbers(posBlock{1});
if mod(numel(posValues), 2) ~= 0
    error('CTSAI:ConfigField', 'ant_pos must contain coordinate pairs.');
end
profile.ant_pos = reshape(posValues, 2, []).';
end

function values = parse_numbers(block)
tokens = regexp(block, '[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', 'match');
values = cellfun(@str2double, tokens);
end
