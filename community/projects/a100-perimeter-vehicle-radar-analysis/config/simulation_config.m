function cfg = simulation_config()
%SIMULATION_CONFIG Configuration for Issue #13 LFMCW simulation.
%
% Velocity convention used in the simulation:
%   v > 0 : receding
%   v < 0 : approaching

cfg = struct();

%% Physical constants
cfg.c = 299792458;

%% Radar waveform
cfg.fc = 76.3e9;
cfg.bandwidth = 300e6;
cfg.chirp_duration = 43e-6;
cfg.chirp_period = 48e-6;

cfg.sample_rate = 25e6;

cfg.num_samples = 1024;
cfg.num_chirps = 256;

cfg.slope = ...
    cfg.bandwidth / cfg.chirp_duration;

cfg.lambda = ...
    cfg.c / cfg.fc;

%% Main moving target

cfg.target.range_m = 30;
cfg.target.velocity_mps = -5;
cfg.target.amplitude = 1.0;

%% Static clutter

cfg.clutter(1).range_m = 10;
cfg.clutter(1).amplitude = 2.0;

cfg.clutter(2).range_m = 18;
cfg.clutter(2).amplitude = 1.5;

cfg.clutter(3).range_m = 45;
cfg.clutter(3).amplitude = 0.8;

%% Noise

cfg.noise_sigma = 0.03;

end