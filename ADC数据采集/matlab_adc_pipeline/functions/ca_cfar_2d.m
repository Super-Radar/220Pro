function [mask, thresholdDb] = ca_cfar_2d(powerMap, p)
%CA_CFAR_2D Toolbox-independent two-dimensional cell-averaging CFAR.

tr = p.training(1); td = p.training(2);
gr = p.guard(1); gd = p.guard(2);
outer = ones(2*(tr+gr)+1, 2*(td+gd)+1);
guard = zeros(size(outer));
guard(tr+1:tr+2*gr+1, td+1:td+2*gd+1) = 1;
kernel = outer - guard;
numTraining = sum(kernel(:));

noise = conv2(powerMap, kernel / numTraining, 'same');
alpha = numTraining * (p.pfa^(-1/numTraining) - 1);
threshold = alpha * noise;
mask = powerMap > threshold;

borderR = tr + gr;
borderD = td + gd;
mask(1:borderR,:) = false;
mask(end-borderR+1:end,:) = false;
mask(:,1:borderD) = false;
mask(:,end-borderD+1:end) = false;

% Toolbox-independent 3-by-3 local maxima.
localMax = true(size(powerMap));
for dr = -1:1
    for dd = -1:1
        if dr == 0 && dd == 0
            continue;
        end
        shifted = circshift(powerMap, [dr dd]);
        localMax = localMax & powerMap >= shifted;
    end
end
localMax([1 end],:) = false;
localMax(:,[1 end]) = false;
mask = mask & localMax;
thresholdDb = 10 * log10(threshold + eps);
end
