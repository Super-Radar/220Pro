function SensorConfig = get_radar_paramete(fid)
%GET_RADAR_PARAMETE Legacy-compatible safe configuration loader.
% This wrapper replaces the original eval-based parser. It uses the same
% parser and MIMO derivation as main.m, including exact tx_groups decoding
% and physical-TX antenna-block selection.

if nargin < 1 || isempty(fid) || fid < 0
    error('A valid open configuration file identifier is required.');
end
[configFile, ~, ~, ~] = fopen(fid);
if isempty(configFile)
    error('Cannot resolve the file name for the supplied identifier.');
end
SensorConfig = load_ctsaia100_config(configFile);
SensorConfig = derive_radar_parameters(SensorConfig);
end
