function [positionsLambda, phaseErrorDeg] = get_array_geometry(cfg, numChannels)
%GET_ARRAY_GEOMETRY Return azimuth positions and calibration phases.
if isfield(cfg, 'ant_pos') && size(cfg.ant_pos,1) >= numChannels
    positionsLambda = cfg.ant_pos(1:numChannels, 1).';
else
    positionsLambda = (0:numChannels-1) * 0.5;
    warning('Antenna positions are missing; using a 0.5-lambda ULA.');
end
if isfield(cfg, 'ant_comps') && numel(cfg.ant_comps) >= numChannels
    phaseErrorDeg = cfg.ant_comps(1:numChannels).';
else
    phaseErrorDeg = zeros(1, numChannels);
end
end
