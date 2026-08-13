function result = estimate_angle_music(snapshots, dictionary, angleGridDeg, angleOpts)
%ESTIMATE_ANGLE_MUSIC MUSIC pseudo-spectrum from local RD snapshots.
numChannels = size(snapshots, 1);
numSnapshots = size(snapshots, 2);
R = snapshots * snapshots' / max(numSnapshots, 1);
loadValue = angleOpts.music_diagonal_loading * real(trace(R)) / max(numChannels,1);
R = R + loadValue * eye(numChannels);
[eigenVectors, eigenValues] = eig(R, 'vector');
[~, order] = sort(real(eigenValues), 'descend');
eigenVectors = eigenVectors(:, order);
numSignals = min(angleOpts.music_signal_count, numChannels-1);
noiseSubspace = eigenVectors(:, numSignals+1:end);
denominator = sum(abs(noiseSubspace' * dictionary).^2, 1);
spectrum = 1 ./ max(denominator, eps);
[~, iPeak] = max(spectrum);
result.angle_deg = angleGridDeg(iPeak);
result.spectrum = spectrum;
end
