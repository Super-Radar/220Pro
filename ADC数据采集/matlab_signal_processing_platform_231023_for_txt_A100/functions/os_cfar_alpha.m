function alpha = os_cfar_alpha(numTraining, rankIndex, pfa)
%OS_CFAR_ALPHA Solve exponential-noise OS-CFAR threshold multiplier.
% Pfa = product_{i=0}^{k-1} (N-i)/(N-i+alpha).
probability = @(a) prod(((numTraining-(0:rankIndex-1))) ./ ...
    ((numTraining-(0:rankIndex-1)) + a));
low = 0;
high = 1;
while probability(high) > pfa
    high = high * 2;
end
for i = 1:80
    mid = (low + high) / 2;
    if probability(mid) > pfa
        low = mid;
    else
        high = mid;
    end
end
alpha = (low + high) / 2;
end
