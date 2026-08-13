function win = make_window(windowName, n, parameter)
%MAKE_WINDOW Toolbox-light window generator.
if nargin < 3
    parameter = 80;
end
if n <= 1
    win = ones(n, 1);
    return;
end
switch lower(strrep(windowName, 'ing', ''))
    case {'hann', 'han'}
        idx = (0:n-1)';
        win = 0.5 - 0.5 * cos(2*pi*idx/(n-1));
    case 'hamm'
        idx = (0:n-1)';
        win = 0.54 - 0.46 * cos(2*pi*idx/(n-1));
    case {'cheb', 'chebyshev'}
        if exist('chebwin', 'file') == 2
            win = chebwin(n, parameter);
        else
            warning('chebwin is unavailable; using Hann window instead.');
            idx = (0:n-1)';
            win = 0.5 - 0.5 * cos(2*pi*idx/(n-1));
        end
    otherwise
        win = ones(n, 1);
end
end
