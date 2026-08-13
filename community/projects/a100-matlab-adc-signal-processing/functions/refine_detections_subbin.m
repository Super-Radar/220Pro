function detections = refine_detections_subbin( ...
    detections, powerMap, cfg, subbinOpts)
%REFINE_DETECTIONS_SUBBIN Refine range and Doppler with a local quadratic.
% A two-dimensional quadratic surface is fitted to the 3x3 log-power patch
% around every coarse FFT peak. The cross term captures local coupling. If
% the fitted Hessian is not a valid local maximum, separable parabolic
% interpolation is used as a robust fallback.

numDetections = height(detections);
detections.RangeOffset_bin = zeros(numDetections,1);
detections.DopplerOffset_bin = zeros(numDetections,1);
detections.RangeRefined_m = zeros(numDetections,1);
detections.VelocityRefined_mps = zeros(numDetections,1);
detections.SubbinFitR2 = nan(numDetections,1);
detections.SubbinFitValid = false(numDetections,1);
detections.SubbinMethod = repmat({''}, numDetections,1);

if numDetections == 0
    return;
end

if isfield(subbinOpts, 'method') && ...
        ~strcmpi(subbinOpts.method, 'QUADRATIC_2D_LOG')
    error('Unsupported sub-bin method: %s', subbinOpts.method);
end

if ~isfield(subbinOpts, 'enable') || ~subbinOpts.enable
    detections.RangeRefined_m = detections.Range_m;
    detections.VelocityRefined_mps = detections.Velocity_mps;
    detections.SubbinMethod(:) = {'DISABLED'};
    return;
end

logPowerMap = 10*log10(double(powerMap) + eps);
numRange = size(powerMap,1);
numDoppler = size(powerMap,2);
[deltaDGrid, deltaRGrid] = meshgrid(-1:1, -1:1);
designMatrix = [deltaRGrid(:).^2, deltaDGrid(:).^2, ...
    deltaRGrid(:).*deltaDGrid(:), deltaRGrid(:), ...
    deltaDGrid(:), ones(9,1)];

for iDetection = 1:numDetections
    r = detections.RangeBin(iDetection);
    d = detections.DopplerBin(iDetection);
    deltaR = 0;
    deltaD = 0;
    fitR2 = NaN;
    fitValid = false;
    methodName = 'COARSE';

    if r > 1 && r < numRange
        rIdx = r-1:r+1;
        dIdx = mod((d-1:d+1)-1, numDoppler) + 1;
        patch = logPowerMap(rIdx, dIdx);
        coefficients = designMatrix \ patch(:);
        hessian = [2*coefficients(1), coefficients(3); ...
            coefficients(3), 2*coefficients(2)];
        gradient = coefficients(4:5);
        predicted = designMatrix * coefficients;
        residualEnergy = sum((patch(:)-predicted).^2);
        totalEnergy = sum((patch(:)-mean(patch(:))).^2);
        fitR2 = 1 - residualEnergy/max(totalEnergy, eps);

        eigenvalues = eig(hessian);
        validMaximum = all_finite(coefficients) && ...
            all(eigenvalues < -subbinOpts.min_negative_curvature) && ...
            rcond(hessian) > 1e-10;
        if validMaximum
            offset = -hessian \ gradient;
            if all_finite(offset) && ...
                    all(abs(offset) <= subbinOpts.max_abs_offset_bins)
                deltaR = offset(1);
                deltaD = offset(2);
                fitValid = true;
                methodName = 'QUADRATIC_2D_LOG';
            end
        end

        if ~fitValid && subbinOpts.use_separable_fallback
            deltaR = parabolic_offset(logPowerMap(r-1,d), ...
                logPowerMap(r,d), logPowerMap(r+1,d));
            dLeft = mod(d-2, numDoppler) + 1;
            dRight = mod(d, numDoppler) + 1;
            deltaD = parabolic_offset(logPowerMap(r,dLeft), ...
                logPowerMap(r,d), logPowerMap(r,dRight));
            deltaR = clamp_offset(deltaR, subbinOpts.max_abs_offset_bins);
            deltaD = clamp_offset(deltaD, subbinOpts.max_abs_offset_bins);
            fitValid = all_finite([deltaR; deltaD]);
            methodName = 'SEPARABLE_LOG';
        end
    end

    detections.RangeOffset_bin(iDetection) = deltaR;
    detections.DopplerOffset_bin(iDetection) = deltaD;
    detections.RangeRefined_m(iDetection) = max(0, ...
        (r-1+deltaR) * cfg.range_resolution_m);
    refinedVelocity = cfg.velocity_axis_mps(d) + ...
        deltaD * cfg.velocity_resolution_mps;
    velocityPeriod = numDoppler * cfg.velocity_resolution_mps;
    velocityMin = cfg.velocity_axis_mps(1);
    refinedVelocity = velocityMin + mod(refinedVelocity-velocityMin, velocityPeriod);
    detections.VelocityRefined_mps(iDetection) = refinedVelocity;
    detections.SubbinFitR2(iDetection) = fitR2;
    detections.SubbinFitValid(iDetection) = fitValid;
    detections.SubbinMethod{iDetection} = methodName;
end
end

function delta = parabolic_offset(leftValue, centerValue, rightValue)
denominator = leftValue - 2*centerValue + rightValue;
if abs(denominator) < eps
    delta = 0;
else
    delta = 0.5 * (leftValue-rightValue) / denominator;
end
end

function value = clamp_offset(value, maxAbsValue)
if ~all_finite(value)
    value = 0;
else
    value = max(-maxAbsValue, min(maxAbsValue, value));
end
end

function tf = all_finite(value)
tf = all(~isnan(value(:)) & ~isinf(value(:)));
end
