function wave = simulate_lfmcw_waveforms(cfg)
%SIMULATE_LFMCW_WAVEFORMS
%
% Generate one high-rate LFM chirp for waveform visualization.
%
% This function is intended for:
%   - transmitted chirp
%   - delayed target echo
%   - dechirped beat signal
%   - time-frequency visualization
%
% It is separate from the ADC-rate Range-Doppler simulation.

%% High-rate waveform sampling

fsWave = 1e9;

T = cfg.chirp_duration;

t = (0:1/fsWave:T-1/fsWave).';

slope = cfg.slope;

%% Transmitted complex-baseband LFM

tx = exp( ...
    1j * pi * slope * t.^2);

%% Target

R = cfg.target.range_m;
v = cfg.target.velocity_mps;

tau = 2 * R / cfg.c;

fd = 2 * v / cfg.lambda;

%% Delayed time

delayedTime = t - tau;

valid = delayedTime >= 0;

rx = complex(zeros(size(t)));

rx(valid) = ...
    cfg.target.amplitude .* ...
    exp( ...
        1j * pi * slope .* ...
        delayedTime(valid).^2) .* ...
    exp( ...
        1j * 2*pi*fd .* ...
        t(valid));

%% Dechirp

beat = tx .* conj(rx);

%% Output

wave = struct();

wave.time_s = t;

wave.tx = tx;
wave.rx = rx;
wave.beat = beat;

wave.sample_rate_hz = fsWave;

wave.delay_s = tau;
wave.doppler_hz = fd;

end