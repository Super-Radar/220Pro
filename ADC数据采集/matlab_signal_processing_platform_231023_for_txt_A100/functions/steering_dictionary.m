function dictionary = steering_dictionary(positionsLambda, angleGridDeg)
%STEERING_DICTIONARY Far-field azimuth steering vectors.
dictionary = exp(1i * 2*pi * positionsLambda(:) * sind(angleGridDeg(:).'));
columnNorm = sqrt(sum(abs(dictionary).^2, 1));
dictionary = dictionary ./ max(columnNorm, eps);
end
