function output = apply_mti(input, order)
%APPLY_MTI Apply an ORDER-stage pulse-to-pulse canceller along dimension 2.
%   ORDER=1 is a two-pulse canceller; ORDER=2 is a three-pulse canceller.

if nargin < 2 || isempty(order)
    order = 1;
end
if order < 0 || order ~= floor(order)
    error('a100:InvalidMtiOrder', 'MTI order must be a non-negative integer.');
end
if size(input, 2) <= order
    error('a100:TooFewPulses', ...
        'MTI order %d requires more than %d pulses.', order, order);
end
output = input;
for idx = 1:order
    output = diff(output, 1, 2);
end
end
