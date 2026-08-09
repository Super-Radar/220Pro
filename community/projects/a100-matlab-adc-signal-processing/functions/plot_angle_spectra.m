function plot_angle_spectra(diagnostics, figureOpts, resultsDir)
%PLOT_ANGLE_SPECTRA Compare four DOA spectra for strongest detection.
if isempty(diagnostics)
    return;
end
fig = figure('Name','Angle Estimation','Visible',figureOpts.visible);
angleGrid = diagnostics.angle_grid_deg;
plot(angleGrid, normalize_spectrum_db(diagnostics.angle_fft_spectrum), ...
    'LineWidth',1.1); hold on;
plot(angleGrid, normalize_spectrum_db(diagnostics.dml_spectrum), ...
    'LineWidth',1.1);
plot(angleGrid, normalize_spectrum_db(diagnostics.music_spectrum), ...
    'LineWidth',1.1);
plot(angleGrid, normalize_spectrum_db(diagnostics.omp_spectrum), ...
    'LineWidth',1.1);
grid on; xlabel('Azimuth angle (deg)'); ylabel('Normalized spectrum (dB)');
title(sprintf('DOA spectra at R=%.2f m, v=%.2f m/s', ...
    diagnostics.range_m, diagnostics.velocity_mps));
legend('Angle FFT','DML','MUSIC','OMP','Location','best');
ylim([-40, 1]);
save_result_figure(fig, fullfile(resultsDir,'angle_spectra.png'), figureOpts);
end

function spectrumDb = normalize_spectrum_db(spectrum)
spectrum = abs(spectrum(:).');
spectrumDb = 10*log10(spectrum/max(spectrum+eps) + eps);
end
